#!/bin/bash

# Author: Anamitra Datta

# script for custom hyprland setup
# script is currently only supported for arch linux. 
# it assumes hyprland has already been installed and is currently running

set -e

#################### LOGGING FUNCTIONS ####################

log_error() 
{
    echo -e "\e[31mERROR: $1\e[0m" >&2
	return 1
}

log_success()
{
	echo -e "\e[32mSUCCESS: $1\e[0m"
}

log_debug()
{
    echo -e "\e[36mDEBUG: $1\e[0m"
}

log()
{
    echo -e "\e[34m$1\e[0m"
}

#################### PREREQUISITE CHECK FUNCTIONS ####################

check_os() 
{
	source /etc/os-release
	if [[ "$ID" != "arch" ]]; then
    	log_error "Hyprland setup only allowed on Arch Linux. Other distros have not been tested"
	else
	    log_success "Arch Linux detected. Proceeding with Hyprland custom setup..."
	fi
}

check_hyprland()
{
	if [[ "$XDG_SESSION_TYPE" == "wayland" && -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    	log_success "Running in Hyprland. Proceeding with Hyprland custom setup... "
	else
    	log_error "Not running in Hyprland. The script requires Hyprland to be installed and running"
	fi
}

check_root() 
{
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
	log_debug "Script is being run as root"
	return 0
}

check_prerequisites()
{
	log "Checking prerequisites..."
	check_root
	check_os
	check_hyprland
}

#################### INSTALL FUNCTIONS ####################

is_installed()
{
    if ! command -v $1 >/dev/null 2>&1; then
        log_debug "$1 is not installed"
        return 1
    fi

    log_debug "$1 is installed"
    return 0
}

install_package()
{
    if ! is_installed $1; then
    	log_debug "Installing $1..."
    	pacman -S --needed --noconfirm $1
		if [[ $? -ne 0 ]]; then
			log_error "Error occurred while installing $1"
    	else
	    	log_success "Installed $1"
    	fi
    fi
}

install_packages()
{
    log "Installing packages..."

    install_package vim
    install_package docker
}

#################### SETUP FUNCTIONS ####################

setup()
{
    log "Setting up hyprland configuration..."
    install_packages
}

#################### MAIN ####################

main()
{
    log "Setting up custom Hyprland configuration"	
	check_prerequisites
	setup
	log_success "Setting up custom Hyprland configuration complete. Please reboot"
}

# run as sudo -E ./setup_hyprland.sh
main
