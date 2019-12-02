#! /usr/bin/sudo /bin/bash
# ---
# RightScript Name: Linux - Install Memcached
# Description: Installs and configures memcached. 
# Inputs:
#   MEMCACHED_MEMORY:
#     Input Type: single
#     Category: Memcached
#     Possible Values: ["text:95%", "text:90%", "text:80%", "text:70%", "text:60%"]
#     Description: The percentage from the total memory to use for memcached.
#   MEMCACHED_PORT:
#     Input Type: single
#     Category: Memcached
#     Default: text:11211
#     Description: The port for memcached to listen on.
#   MEMCACHED_USER:
#     Input Type: single
#     Category: Memcached
#     Default: text:nobody
#     Description: optional user for memcached to run as.
#   MEMCACHED_BIND_IP:
#     Input Type: single
#     Category: Memcached
#     Possible Values: ["text:Private", "text:Any"]
#     Description: The IP for memcached to listen on. "Private" uses the $RS_PRIVATE_IP env variable. "Any" configures memcache to listen on all interfaces.
#   MEMCACHED_OPTIONS:
#     Input Type: single
#     Category: Memcached
#     Description: This could be used to turn on debugging. Space separated list of memcached options (-v -vv)
#   RS_INSTANCE_UUID:
#     Input Type: single
#     Category: RightScale
#     Default: env:RS_INSTANCE_UUID
#     Description: If using collectd, the monitoring ID for this server.
#     Required: true
#     Advanced: true
#   RS_PRIVATE_IP:
#     Input Type: single
#     Category: RightScale
#     Description: RightScale Private IP
#     Default: env:PRIVATE_IP
# Attachments: []
# ...

if [ -e /usr/bin/apt-get ]; then
  apt-get install lsb-release -y
else
  yum install redhat-lsb-core -y
fi

if [ -e /usr/bin/lsb_release ]; then
  case $(lsb_release -si) in
    Ubuntu*) export rs_distro=ubuntu
             export rs_base_os=debian
             ;;
    Debian*) export rs_distro=debian
             export rs_base_os=debian
             ;;
    CentOS*) export rs_distro=centos
             export rs_base_os=redhat
             ;;
    Fedora*) export rs_distro=redhat
             export rs_base_os=redhat
             ;;
    *)       export rs_distro=redhat
             export rs_base_os=redhat
             ;;
  esac
fi

if [ -n "$MEMCACHED_BIND_IP" ]; then
  # define the listening IP
  case "$MEMCACHED_BIND_IP" in
    Private*   ) extra_opts="-l $RS_PRIVATE_IP" && fw_dest="$RS_PRIVATE_IP/0";;
    Any*   ) echo "Listening on any IP" && fw_dest="0.0.0.0/0";;
    *       ) echo "Unsupported bind ip option" && exit 1;;
  esac
fi

if [ $rs_distro = ubuntu ]; then 
	config_file="/etc/memcached.conf"
	iptables_rules="/etc/iptables.rules"

	if [ -f "$config_file" ]; then
	  echo "Memcache already installed, skipping..."
	  iptables-restore < $iptables_rules
	  exit 0
	fi

	apt-get install -y memcached

	mv "$config_file" "$config_file.old"
	touch "$config_file"
	
	echo "-d" >> $config_file
	echo "logfile /var/log/memcached.log"
	
	if [ -n "$MEMCACHED_USER" ]; then
	  echo "-u $MEMCACHED_USER" >> $config_file
	else
	  echo "-u nobody" >> $config_file
	fi
	if [ -n "$MEMCACHED_PORT" ]; then
	  echo "-p $MEMCACHED_PORT" >> $config_file
	else
	  #to be used by the iptables rule
	  MEMCACHED_PORT=11211
	fi
	if [ -n "$MEMCACHED_MEMORY" ]; then
	  #remove the %
	  MEMCACHED_MEMORY=${MEMCACHED_MEMORY/\%/}
	  if ! grep -E -q "^[0-9]+$"<<<"$MEMCACHED_MEMORY"; then
	    echo 'MEMCACHED_MEMORY must be a percentage. Ex: 70%'
	    exit 1
	  else
  	  MEMCACHED_MEMORY=$(grep 'MemTotal' /proc/meminfo | awk '{print $2 * '$MEMCACHED_MEMORY' / 102400}' | cut -f1 -d .)
      echo "Memcache Memory Size: $MEMCACHED_MEMORY"
	    echo "-m $MEMCACHED_MEMORY" >> $config_file
	  fi
	fi
	if [ -n "$MEMCACHED_OPTIONS" ]; then
	  extra_opts="$extra_opts $MEMCACHED_OPTIONS"
	fi
	echo " $extra_opts" >> $config_file
elif [ $rs_distro = centos ]; then
	config_file="/etc/sysconfig/memcached"
	iptables_rules="/etc/sysconfig/iptables"

	if [ -f "$config_file" ]; then
	  echo "Memcache already installed, skipping..."
	  exit 0
	fi

	yum install -y memcached

	cp -f "$config_file" "$config_file.old"
	touch "$config_file"
	
	if [ -n "$MEMCACHED_PORT" ]; then
	  echo "PORT=\"$MEMCACHED_PORT\"" >> $config_file
	else
	  #to be used by the iptables rule
	  MEMCACHED_PORT=11211
	fi
	if [ -n "$MEMCACHED_MEMORY" ]; then
	  #remove the %
	  MEMCACHED_MEMORY=${MEMCACHED_MEMORY/\%/}
	  if ! grep -E -q "^[0-9]+$"<<<"$MEMCACHED_MEMORY"; then
	    echo 'MEMCACHED_MEMORY must be a percentage. Ex: 70%'
	    exit 1
	  else
  	    MEMCACHED_MEMORY=$(grep 'MemTotal' /proc/meminfo | awk '{print $2 * '$MEMCACHED_MEMORY' / 102400}' | cut -f1 -d .)
	    echo "CACHESIZE=\"$MEMCACHED_MEMORY\"" >> $config_file
	  fi
	fi

	if [ -n "$MEMCACHED_OPTIONS" ]; then
	  extra_opts="$extra_opts $MEMCACHED_OPTIONS"
	fi

	echo "OPTIONS=\"$extra_opts\"" >> $config_file
	chkconfig memcached on
	chkconfig --add memcached
fi

#update iptables to allow incoming connections
iptables -I INPUT -p tcp -d $fw_dest --dport $MEMCACHED_PORT -j ACCEPT
iptables-save > $iptables_rules

service memcached restart

while [ ! $(pgrep memcached) ]; do
  echo "Sleeping 10s until memcached starts"
  sleep 10
done

if [ -e /usr/sbin/collectd ]; then
if [ ! $(grep -q $RS_INSTANCE_UUID /etc/hosts) ]; then
  cat <<EOF>> /etc/hosts
$RS_PRIVATE_IP $RS_INSTANCE_UUID
EOF
fi

cat <<EOF> /etc/collectd/plugins/memcached.conf
LoadPlugin Memcached
<Plugin "memcached">
  Host "$RS_INSTANCE_UUID"
  Port "$MEMCACHED_PORT"
</Plugin>
EOF

service collectd restart
fi
