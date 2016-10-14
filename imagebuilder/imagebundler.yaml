Name: Image Bundler For RightLink 10
Description: >
  This ServerTemplate uses Packer to create cloud images, and if needed add
  RightLink 10 to the target image.

  # Documentation

  * [Overview](https://docs.rightscale.com/st/rl10/image-bundler/)
  * [Tutorial](http://docs.rightscale.com/st/rl10/image-bundler/tutorial.html)

Inputs:
  MANAGED_LOGIN: "text:enable"
RightScripts:
  Boot:
  - Name: RL10 Linux Wait For EIP
    Revision: 5
    Publisher: RightScale
  - Name: RL10 Linux Enable Managed Login
    Revision: 7
    Publisher: RightScale
  - packer_install.sh
  - packer_install_plugins.sh
  - packer_install_azurerm.sh
  - packer_configure.sh
  - packer_build.sh
MultiCloudImages:
- Name: Ubuntu_14.04_x64
  Revision: 52
- Name: Ubuntu_14.04_x64_KVM
  Revision: 27  
Alerts: []
