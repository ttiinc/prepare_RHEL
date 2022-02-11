<img src="https://raw.githubusercontent.com/ttiinc/.dotfiles/master/img/TTI_Avatar_tiny.png" align="left" width="135px" height="135px" />

### prepare_RHEL by TTI, Inc. European Infrastructure Team
> *A script for quick and easy setup/configuration*

[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)

<br />

## Motivation
To have a post-install script that automates common setup and configuration 
tasks. This project does not lay down any infrastructure, and expects you to

have the required machines provisioned prior to beginning.

The goals of this project are to:

- Create an easy automated repeatable configuration process for RHEL
- Support RHEL based distributions like CentOS, Fedora and Rocky Linux
- Require little to no pre-requisties to run the configuration script

## Setup
This script is designed to be run immediately after installing the operating
system. Just clone the repository and run setup.sh
```
git clone https://github.com/ttiinc/.prepare_RHEL.git ~/.dotfiles
~/.prepare_RHEL/setup.sh
```

## Features
Works across RedHat Enterprise Linux, Fedora 34+, CentOS and Rocky Linux.
