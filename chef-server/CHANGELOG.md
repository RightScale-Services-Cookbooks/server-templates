v2.0.5
------
- Totally revamped backup scripts.
- Backup scripts now properly shutdown Chef and create a tar.gz.
- Backup snapshots now are storable in AWS or GCE buckets.

v2.0.4
------
- updated Chef Client download URI (www.opscode.com -> www.chef.io)

v2.0.3
------
- added VERSION for chef script.

v2.0.2
-----
- RL10_Chef_Server_Schedule_Cron_For_Backups_Via_RightScripts.sh

v2.0.2
-----
- added RESTORE input to chef server
- added RL_10_CHEF_SERVER_BACKUP_VIA_RIGHTSCRIPTS.sh
- added RL_10_CHEF_RESTORE_BACKUP_VIA_RIGHTSCRIPTS.sh

v2.0.1
------
- update to rl10.6
- update haproxy input pools to array - [21][]

v2.0.0
------
- update everything to chef 12.
- remove rightlink monitoring
- add rs-base
