#!/bin/bash

# Author: Anamitra Datta

# script for custom hyprland setup
# script is currently only supported for arch linux. 

# it assumes the following have already been installed:
# - hyprland
# - git
# - kitty

# please run this script within the hyprland_setup directory

set -euo pipefail

# uncomment for debugging purposes
#set -x

#################### CONSTANTS ####################

# Hyprland configurations
HOME_CONFIG_DIR=$HOME/.config
HYPRLAND_CONFIG_DIR=$HOME_CONFIG_DIR/hypr

# Custom Configurations
CONFIGS_DIR=$(pwd)/configs
VIM_CONFIG_DIR=$CONFIGS_DIR/vim
CUSTOM_VIM_CONFIG_FILE=$VIM_CONFIG_DIR/.vimrc
SHELL_CONFIG_DIR=$CONFIGS_DIR/shell
CUSTOM_BASH_CONFIG_FILE=$SHELL_CONFIG_DIR/.bashrc
CUSTOM_ZSH_CONFIG_FILE=$SHELL_CONFIG_DIR/.zshrc
CUSTOM_HYPRLAND_CONFIG_DIR=$CONFIGS_DIR/hyprland
CUSTOM_HYPRLAND_CONFIG_FILE=$CUSTOM_HYPRLAND_CONFIG_DIR/hyprland.conf
CUSTOM_HYPRLOCK_CONFIG_FILE=$CUSTOM_HYPRLAND_CONFIG_DIR/hyprlock.conf
CUSTOM_HYPRIDLE_CONFIG_FILE=$CUSTOM_HYPRLAND_CONFIG_DIR/hypridle.conf

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

check_configs()
{
	if [[ -d $CONFIGS_DIR ]]; then
		log_success "Found custom configurations directory"
		return 0
	else
		log_error "Could not find custom configurations directory"
		return 1
	fi
}

check_prerequisites()
{
	log "Checking prerequisites..."
	check_root
	check_os
	check_hyprland
	check_configs
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

#################### CONFIGURATIONS ####################

set_up_config_file()
{
	log_debug "Setting up custom config file $1 in destination directory $2"

	if [[ ! -f $1 ]]; then
		log_warning "Cannot find custom config file $1. Skipping custom config file setup"
		return 0
	fi

	if [[ ! -d $2 ]]; then
		log_warning "Cannot find custom config file destination directory $2 for file $1. Skipping custom config file setup"
		return 0
	fi

	cp $1 $2
	if [[ $? -eq 0 ]]; then
		log_success "Custom config file $1 was set successfully in directory $2"
		return 0
	else
		log_error "Custom config file $1 was not set successfully in directory $2"
		return 1
	fi
}

change_shell_to_zsh()
{
	log_debug "Changing shell to zsh"
	local ZSH_PATH

	if ! ZSH_PATH="$(command -v zsh 2>/dev/null)"; then
		log_warning "zsh is not installed. Skipping changing shell to zsh"
		return 0
	fi

	if [[ "$SHELL" != "$ZSH_PATH" ]]; then
		if chsh -s "$ZSH_PATH"; then
			log_success "Default shell changed to zsh"
			return 0
		else
			log_error "Failed to change default shell to zsh"
			return 1
		fi
	fi

	log_debug "Default shell is already zsh"
	return 0
}

set_up_lock_handle_lid_switch()
{
	log_debug "Setting up HandleLidSwitch to lock"

	LOGIND_CONF=/etc/systemd/logind.conf

	if [[ ! -f "$LOGIND_CONF" ]]; then
		log_warning "$LOGIND_CONF does not exist. Skipping setting HandleLidSwitch to lock"
		return 0
	fi

	if [[ ! -w "$LOGIND_CONF" ]]; then
		log_warning "$LOGIND_CONF is not writable. Skipping setting HandleLidSwitch to lock"
		return 0
	fi

	sed -i 's/^[[:space:]]*#\?\s*HandleLidSwitch=.*/HandleLidSwitch=lock/' $LOGIND_CONF
	SED_RC=$?

	if [[ $SED_RC -ne 0 ]]; then
		log_error "Failed to update HandleLidSwitch in $LOGIND_CONF (sed exit code: $SED_RC)"
		return 1
	else
		log_success "Updated HandleLidSwitch to lock in $LOGIND_CONF"
		return 0
	fi
}

set_up_configurations()
{
	log "Setting up custom configurations..."
	
	# vimrc
	set_up_config_file $CUSTOM_VIM_CONFIG_FILE $HOME

	# bashrc
	set_up_config_file $CUSTOM_BASH_CONFIG_FILE $HOME

	# zshrc
	set_up_config_file $CUSTOM_ZSH_CONFIG_FILE $HOME
	change_shell_to_zsh

	# hyprland conf
	set_up_config_file $CUSTOM_HYPRLAND_CONFIG_FILE $HYPRLAND_CONFIG_DIR

	# hyprlock conf
	set_up_config_file $CUSTOM_HYPRLOCK_CONFIG_FILE $HYPRLAND_CONFIG_DIR
	set_up_lock_handle_lid_switch

	# hypridle conf
	set_up_config_file $CUSTOM_HYPRIDLE_CONFIG_FILE $HYPRLAND_CONFIG_DIR
}

#################### SERVICES ####################

enable_service()
{
	local service="$1"
	service="${service,,}"  # case-insensitive

	log_debug "Enabling service: $service"

	if systemctl enable $service; then
		log_success "$service service enabled successfully"
		return 0
	else
		log_error "Failed to enable service $service"
		return 1
	fi
}

enable_services()
{
	log "Enabling services..."
	enable_service "docker"
	enable_service "sshd"
}

#################### MAIN ####################

prompt_start() 
{
	while true; do
		read -rp "Would you like to run the custom Hyprland setup script? [y/n]: " answer
		case "$answer" in
			[yY]|[yY][eE][sS])
    			log "Setting up custom Hyprland configuration"	
				break
				;;
			[nN]|[nN][oO]|"")
				log "Exiting setting up custom Hyprland configuration"
				exit 0
				;;
			*)
				log_warning "Please answer yes or no."
				;;
		esac
	done
}

prompt_reboot() 
{
	log_success "Setting up custom Hyprland configuration complete!"
	while true; do
		read -rp "Reboot system now? [y/n]: " answer
		case "$answer" in
			[yY]|[yY][eE][sS])
				log "Rebooting..."
				reboot
				break
				;;
			[nN]|[nN][oO]|"")
				log "Reboot skipped."
				break
				;;
			*)
				log_warning "Please answer yes or no."
				;;
		esac
	done
}

main()
{
	prompt_start
	check_prerequisites
	install_pacman_packages
	set_up_configurations
	enable_services
	prompt_reboot
}

# run as sudo -E ./setup_hyprland.sh
main
