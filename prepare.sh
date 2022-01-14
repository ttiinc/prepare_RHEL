#!/usr/bin/env bash
#
# +-------------------------------------------------------------------------+
# | prepare.sh                                                              |
# +-------------------------------------------------------------------------+
# | Copyright © 2022 TTI, Inc.                                              |
# |                  euis.network(at)de.ttiinc.com                          |
# +-------------------------------------------------------------------------+

# +----- Variables ---------------------------------------------------------+
datetime="$(date "+%Y-%m-%d-%H-%M-%S")"
cdir=$(pwd)
logfile="/tmp/prepare_RHEL_${datetime}.log"
width=80

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# +----- Functions ---------------------------------------------------------+
echo_equals() {
	counter=0
	while [  $counter -lt "$1" ]; do
		printf '='
		(( counter=counter+1 ))
	done
}

echo_title() {
	title=$1
	ncols=$(tput cols)
	nequals=$(((width-${#title})/2-1))
	tput setaf 3 0 0 # 3 = yellow
	echo_equals "$nequals"
	printf " %s " "$title"
	echo_equals "$nequals"
	tput sgr0  # reset terminal
	echo
}

echo_right() {
    text=${1}
    echo
    tput cuu1
    tput cuf "${width}"
    tput cub ${#text}
    echo "${text}"
}

echo_success() {
    tput setaf 2 0 0
    echo_right "[ OK ]"
    tput sgr0
}
antwoord() {
    read -p "${1}" antwoord
        if [[ ${antwoord} == [yY] || ${antwoord} == [yY][Ee][Ss] ]]; then
            echo "yes"
        else
            echo "no"
        fi
}

display_Notice() {
    clear
    tput setaf 4
    cat ${cdir}/notice.txt
    tput sgr0
    proceed="$(antwoord "Do you want to proceed? (Yes|No) >> ")"
}

clear_Logfile () {
    if [[ -f ${logfile} ]]; then
        rm ${logfile}
    fi
}

get_User () {
    if ! [[ $(id -u) = 0 ]]; then
        printf "${RED}Error:${NORMAL} This script must be run as root.\n\n" 
        exit 1
    fi
}

get_OperatingSystem () {
    os=$(uname -s)
    kernel=$(uname -r)
    architecture=$(uname -m)
}

get_Distribution () {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        distribution=$NAME
        version=$VERSION_ID
    else
        echo -e "\nError: I need /etc/os-release to figure what distribution this is."
        exit 1    
    fi
    echo -e "\nSeems to be:"
    echo -e "  ${os} ${distribution} ${version} ${kernel} ${architecture}\n" 
}

HostName_query () {
    SetHostname="$(antwoord "Do you want to set hostname? (Yes|No) >> ")"
    if [[ "${SetHostname}" = "yes" ]]; then
        # printf "\nHostname: >> "
        read -p "Hostname: " gethostname
    fi
}

HostName_set () {
    if [[ "${SetHostname}" = "yes" ]]; then
        hostnamectl set-hostname ${gethostname}
    fi
}

GoogleChrome_query () {
    InstallGoogleChrome="$(antwoord "Do you want to get Google Chrome installed? (Yes|No) >> ")"
}

GoogleChrome_install () {
    if [[ "${InstallGoogleChrome}" = "yes" ]]; then
        echo "Installing Repository: google-chrome"
        cp ${cdir}/etc/yum.repos.d/google-chrome.repo /etc/yum.repos.d
        dnf install -y google-chrome-stable >> ${logfile} 2>&1
        echo_success
    fi
}

VirtualBox_query () {
    InstallVirtualBox="$(antwoord "Do you want to get VirtualBox installed? (Yes|No) >> ")"
}

VirtualBox_install () {
    if [[ "${InstallVirtualBox}" = "yes" ]]; then
        echo "Installing Repository: VirtualBox"
        cp ${cdir}/etc/yum.repos.d/virtualbox.repo /etc/yum.repos.d
        dnf install -y VirtualBox-6.0 >> ${logfile} 2>&1
    fi
}

SELinux_query () {
    DisableSELinux="$(antwoord "Disable SELinux? (Yes|No) >> ")"
}

SELinux_disable () {
    if [[ "${DisableSELinux}" = "yes" ]]; then
        echo "Disabling SELinux."
        sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
    fi
}

SDDM_query () {
    EnableSDDM="$(antwoord "Enable Simple Desktop Display Manager? (Yes|No) >> ")"
}

SDDM_enable () {
    if [[ "${EnableSDDM}" = "yes" ]]; then
        statusdm="$(systemctl is-active display-manager.service)"
        if [[ "${statusdm}" = "active" ]]; then
            echo "Disabling current Display Manager."
            systemctl disable display-manager.service
        fi
        echo "Enabling SDDM."
        systemctl enable sddm.service
        systemctl set-default graphical.target
    fi
}

FilesXorg_query () {
    FilesXorg="$(antwoord "Copy Xorg related files? (Yes|No) >> ")"
}

FilesXorg_copy () {
    if [[ "${FilesXorg}" = "yes" ]]; then
        printf "Copying Xorg related files."
        cp ${cdir}/etc/X11/xorg.conf.d/*.conf /etc/X11/xorg.conf.d
        cp ${cdir}/etc/sddm.conf /etc
        cp ${cdir}/X.org.files/dwm.desktop /usr/share/xsessions
        cp ${cdir}/X.org.files/xinit-compat.desktop /usr/share/xsessions
    fi
}

RHEL8_CodereadyBuilder_query () {
    EnableCodeReady="$(antwoord "Enable CodeReady Linux Builder? (Yes|No) >> ")"
}

RHEL8_CodereadyBuilder_enable () {
    if [[ "${EnableCodeReady}" = "yes" ]]; then
        printf "Enabling CodeReady Linux Builder."
        subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
    fi
}

RHEL8_EPEL_query () {
    EnableEPEL="$(antwoord "Enable Extra Packages for Enterprise Linux (EPEL)? (Yes|No) >> ")"
}

RHEL8_EPEL_enable () {
    if [[ "${EnableEPEL}" = "yes" ]]; then
        printf "Enabling CodeReady Linux Builder."
        subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
    fi
}

RHEL8_DefaultPackages_query () {
    InstallDefaultPackages="$(antwoord "Install default packages? (Yes|No) >> ")"
}

RHEL8_DefaultPackages_install () {
    if [[ "${InstallDefaultPackages}" = "yes" ]]; then
        IFS=$'\r\n' GLOBIGNORE='*' command eval  'packages=($(cat ./packages.RHEL8))'
        echo "Installing the following packages:"
        echo ${packages[@]}
        dnf install -y ${packages[@]} >> ${logfile} 2>&1
    fi
}

Fedora3x_prepare () {
    echo "Installing Repository: RPM Fusion for Fedora - Free - Updates"
    dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm >> ${logfile} 2>&1
    echo "Installing Repository: RPM Fusion for Fedora - Nonfree - Updates"
    dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm >> ${logfile} 2>&1
    IFS=$'\r\n' GLOBIGNORE='*' command eval  'packages=($(cat ./packages.Fedora3x))'
    echo "Installing the following packages:"
    echo ${packages[@]}
    dnf install -y ${packages[@]} >> ${logfile} 2>&1
    echo "Setting hostname to: ${gethostname}"
    hostnamectl set-hostname ${gethostname}
}

CentOS_7 () {
    echo "Installing Repository: Extra Packages for Enterprise Linux 7"
    yum install -y epel-release >> ${logfile} 2>&1
    echo "Installing Repository: RPM Fusion for EL 8 - Free - Updates"
    yum localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm >> ${logfile} 2>&1
    echo -e "Installing Repository: RPM Fusion for EL 8 - Nonfree - Updates"
    yum localinstall -y --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm >> ${logfile} 2>&1
    IFS=$'\r\n' GLOBIGNORE='*' command eval  'packages=($(cat ./packages.CentOS7))'
    echo "Installing the following packages:"
    echo ${packages[@]}
    yum install -y ${packages[@]} >> ${logfile} 2>&1
}

install_CentOS_8 () {
    echo "Installing Repository: CentOS-8 - PowerTools"
    dnf config-manager --enable PowerTools >> ${logfile} 2>&1
    echo "Installing Repository: Extra Packages for Enterprise Linux 8"
    dnf install -y epel-release >> ${logfile} 2>&1
    echo "Installing Repository: RPM Fusion for EL 8 - Free - Updates"
    dnf install -y --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm >> ${logfile} 2>&1
    echo "Installing Repository: RPM Fusion for EL 8 - Nonfree - Updates"
    dnf install -y --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm >> ${logfile} 2>&1
    IFS=$'\r\n' GLOBIGNORE='*' command eval  'packages=($(cat ./packages.CentOS8))'
    echo "Installing the following packages:"
    echo ${packages[@]}
    dnf install -y ${packages[@]} >> ${logfile} 2>&1
}

# +----- Main --------------------------------------------------------------+
get_User
display_Notice
if [[ "${proceed}" = "no" ]]; then
    exit 1
fi

echo_title "Choose Options"

get_OperatingSystem
get_Distribution
if [[ "${os}" = "Linux" ]]; then
    case ${distribution} in
        "Red Hat Enterprise Linux" )
            GoogleChrome_query
            VirtualBox_query
            HostName_query
            SELinux_query
            RHEL8_CodereadyBuilder_query
            RHEL8_DefaultPackages_query
            echo_title "Prepare"
            GoogleChrome_install
            VirtualBox_install
            HostName_set
            SELinux_disable
            RHEL8_CodereadyBuilder_enable
            RHEL8_DefaultPackages_install
            ;;
        "Fedora" )
            if [[ "${version}" != 3* ]]; then
                echo -e "Error: This is not a supported version of Fedora"
                exit 1
            fi
            get_GoogleChrome
            get_VirtualBox
            get_Hostname
            disable_SELINUX
            copy_Files
            install_Fedora3x
            enable_SDDM
            if [[ "${InstallGoogleChrome}" = "yes" ]]; then
                echo "Installing Google Chrome as well."
                install_GoogleChrome
            fi

            if [[ "${InstallVirtualBox}" = "yes" ]]; then
                echo "Installing VirtualBox as well."
                install_VirtualBox
            fi
            ;;
        "CentOS Linux" )
            if [[ "${version}" -ne "7" && "${version}" -ne "8" ]]; then
                echo -e "Error: This is not a supported version of CentOS"
                exit 1
            fi
            get_GoogleChrome
            get_VirtualBox
            disable_SELINUX
            copy_Files
            enable_SDDM
            if [[ "${version}" = "7" ]]; then
                install_CentOS_7
            elif [[ "${version}" = "8" ]]; then
                install_CentOS_8
            fi
            if [[ "${InstallGoogleChrome}" = "yes" ]]; then
                echo "Installing Google Chrome as well.\n"
                install_GoogleChrome
            fi

            if [[ "${InstallVirtualBox}" = "yes" ]]; then
                echo "Installing VirtualBox as well.\n"
                install_VirtualBox
            fi
            ;;
        "Arch Linux" )
            echo "Arch Linux"
            ;;
        * )
            echo "This seems to be an unsupported Linux distribution."
            exit 1
            ;;
    esac
elif [[ "${os}" = "AIX" ]]; then
    echo -e "Error: I'm so sorry, but AIX is currently not supported"
    exit 1

elif [[ "${os}" = "SunOS" ]]; then
    echo -e "Error: I'm so sorry, but SunOS/Solaris is currently not supported"
    exit 1

elif [[ "${os}" = "Darwin" ]]; then
    echo -e "Error: I'm so sorry, but Darwin is currently not supported"
    exit 1

elif [[ "${os}" = "FreeBSD" ]]; then
    echo -e "Warning: Support for FreeBSD is currently ridimentary."
    get_Distribution
fi

echo_title "I'm done."
echo -e "\n\n"
exit 0
