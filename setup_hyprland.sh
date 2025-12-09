#!/bin/bash

# Author: Anamitra Datta

# script for custom hyprland setup
# script is currently only supported for arch linux. 

# it assumes the following have already been installed:
# - hyprland
# - git
# - kitty

set -e

#################### LOGGING FUNCTIONS ####################

log_error() 
{
    echo -e "\e[31mERROR: $1\e[0m" >&2
}

log_warning()
{
	echo -e "\e[33mWARNING: $1\e[0m"
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
		return 1
	else
	    log_success "Arch Linux detected. Proceeding with Hyprland custom setup..."
		return 0
	fi
}

check_hyprland()
{
	if [[ "$XDG_SESSION_TYPE" == "wayland" && -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    	log_success "Running in Hyprland. Proceeding with Hyprland custom setup..."
		return 0
	else
    	log_error "Not running in Hyprland. The script requires Hyprland to be installed and running"
		return 1
	fi
}

check_root() 
{
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    else
		log_debug "Script is being run as root"
		return 0
	fi
}

check_prerequisites()
{
	log "Checking prerequisites..."
	check_root
	check_os
	check_hyprland
}

#################### INSTALL FUNCTIONS ####################

is_installed_by_pacman()
{
	if pacman -Q $1 >/dev/null 2>&1; then
    	log_success "$1 is installed by pacman"
		return 0
	else
    	log_debug "$1 is not installed by pacman"
		return 1
	fi
}

install_pacman_package()
{
    log_debug "Install pacman package: $1"
    if ! is_installed_by_pacman $1; then
    	log_debug "Installing $1 with pacman..."
    	pacman -S --needed --noconfirm $1
		if [[ $? -ne 0 ]]; then
			log_error "Error occurred while installing $1 using pacman"
			return 1
    	else
	    	log_success "Installed $1 using pacman"
			return 0
    	fi
    fi
	return 0
}

install_pacman_packages()
{
    log "Installing pacman packages..."

	PACKAGES=(
    	bash-completion
    	zsh
		pavucontrol
		brightnessctl
    	curl
		p7zip
    	vim
    	gvim
    	gedit
    	code
    	openssh
    	docker
		waybar
	)

	for pkg in "${PACKAGES[@]}"; do
    	install_pacman_package "$pkg"
	done
}

#################### MAIN ####################

main()
{
    log "Setting up custom Hyprland configuration"	
	check_prerequisites
	install_pacman_packages
	log_success "Setting up custom Hyprland configuration complete!"
	log_warning "Please reboot!"
}

# run as sudo -E ./setup_hyprland.sh
main
