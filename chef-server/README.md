* This ServerTemplate will install and configure an Opscode [Chef Server](https://www.chef.io/chef/) and configure backup snapshots to either [S3](https://aws.amazon.com/s3/) or [Google Cloud Storage.](https://cloud.google.com/storage/)

* Direct link to ServerTemplate in the RightScale Marketplace is [here.](https://us-3.rightscale.com/library/server_templates/Chef-Server-for-Linux-RightLin/lineage/57238)

---

Requirements
============

* [right_st](https://github.com/rightscale/right_st) is needed to upload the ServerTemplate to your account.

* An AWS public / private keypair if using S3 for backups with S3 write permission

* If using Google Cloud Storage: A Cloud Storage Service Account with the 'Storage Admin' role. Instructions on creating the JSON credential for this can be found [here](https://cloud.google.com/iam/docs/creating-managing-service-accounts)

* Tested on CentOS-7 / RHEL-7 / Ubuntu 16.04

---

Inputs
======

* Backup
 * `AWS_ACCESS_KEY_ID`: AWS Access Key.
 * `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key.



