### README:

* Upload YAML files to your account with [right_st](https://github.com/rightscale/right_st)

### IMPORTANT INPUTS:

#### Jenkins Related:

* `MASTER_IP`: Reachable address for the Jenkins slaves to contact and add themselves to the cluster. Usually the private IP address of the Jenkins Master host.

* `SWARM_PLUGIN_VERSION`: Version of the Jenkins Swarm plugin to install which allows for slave / master discovery. Currently defaults to `3.4`.

* `DESCRIPTION`: Text name of jenkins slave instances.

* `AUTO_DISCOVERY_ADDRESS`: Enable this if using UDP based discovery. Not required. Current defaults allow Jenkins slaves to discover master via Swarm plugin and connecting to `MASTER_IP`.

* `MASTER_PORT`: Default port Jenkins listens on. Defaults to `8080`.

#### Storage Related:

* `BACKUP_KEEP_DAILIES`: Number of daily backups to keep. Defaults to `14`.

* `BACKUP_KEEP_LAST`: Number of snapshots to keep. Defaults to `60`.

* `BACKUP_KEEP_MONTHLIES`: Number of monthly backups to keep. Defaults to `12`.

* `BACKUP_KEEP_WEEKLIES`: Number of weekly backups to keep. Defaults to `6`.

* `BACKUP_KEEP_YEARLIES`: Number of yearly backups to keep. Defaults to `2`.

* `STOR_BACKUP_LINEAGE`: Name of backup lineage to use for snapshots.

* `DEVICE_MOUNT_POINT`: Mount point of data volume. Defaults to `/var/lib/jenkins`, which is the Jenkins home / work directory.

* `DEVICE_NICKNAME`: Name of the LVM device to be created. Defaults to `data_storage`.

* `DEVICE_COUNT`: Number of devices to create which will make up the underlying LVM volume.

* `DEVICE_DESTROY_ON_DECOMMISSION`: If set to true, the devices will be destroyed on decommission. Defaults to `false`.

* `STOR_RESTORE_LINEAGE`: If set, restore from the supplied backup name.

* `STOR_RESTORE_TIMESTAMP`: The filesystem to be used on the data volume. Defaults to `ext4`.