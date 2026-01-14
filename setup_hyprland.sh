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

#################### FLAGS ####################

ENABLE_DEBUG=false

#################### CONSTANTS ####################

HOME_CONFIG_DIR=$HOME/.config
HYPRLAND_CONFIG_DIR=$HOME_CONFIG_DIR/hypr
LOCAL_SHARE_DIR=$HOME/.local/share
LOCAL_FONTS_DIR=$LOCAL_SHARE_DIR/fonts
LOCAL_YAZI_CONFIG_DIR=$HOME_CONFIG_DIR/yazi
LOCAL_WAYBAR_CONFIG_DIR=$HOME_CONFIG_DIR/waybar
LOCAL_WOFI_CONFIG_DIR=$HOME_CONFIG_DIR/wofi
LOCAL_WALLPAPERS_DIR=$LOCAL_SHARE_DIR/wallpapers

# Custom configurations
CUSTOM_CONFIGS_DIR=$(pwd)/configs

# Vim configuration
CUSTOM_VIM_CONFIG_DIR=$CUSTOM_CONFIGS_DIR/vim
CUSTOM_VIM_CONFIG_FILE=$CUSTOM_VIM_CONFIG_DIR/.vimrc

# Shell configurations
CUSTOM_SHELL_CONFIG_DIR=$CUSTOM_CONFIGS_DIR/shell
CUSTOM_BASH_CONFIG_FILE=$CUSTOM_SHELL_CONFIG_DIR/.bashrc
CUSTOM_ZSH_CONFIG_FILE=$CUSTOM_SHELL_CONFIG_DIR/.zshrc

# Yazi configuration
CUSTOM_YAZI_CONFIG_DIR=$CUSTOM_CONFIGS_DIR/yazi
CUSTOM_YAZI_TOML_FILE=$CUSTOM_YAZI_CONFIG_DIR/yazi.toml

# Hyprland configurations
CUSTOM_HYPRLAND_CONFIG_DIR=$CUSTOM_CONFIGS_DIR/hyprland
CUSTOM_HYPRLAND_CONFIG_FILE=$CUSTOM_HYPRLAND_CONFIG_DIR/hyprland.conf
CUSTOM_HYPRLOCK_CONFIG_FILE=$CUSTOM_HYPRLAND_CONFIG_DIR/hyprlock.conf
CUSTOM_HYPRIDLE_CONFIG_FILE=$CUSTOM_HYPRLAND_CONFIG_DIR/hypridle.conf
CUSTOM_HYPRPAPER_CONFIG_FILE=$CUSTOM_HYPRLAND_CONFIG_DIR/hyprpaper.conf

# Waybar configuration
CUSTOM_WAYBAR_CONFIG_DIR=$CUSTOM_CONFIGS_DIR/waybar
CUSTOM_WAYBAR_CONFIG_JSONC_FILE=$CUSTOM_WAYBAR_CONFIG_DIR/config.jsonc
CUSTOM_WAYBAR_CONFIG_STYLE_CSS_FILE=$CUSTOM_WAYBAR_CONFIG_DIR/style.css

# wofi configuration
CUSTOM_WOFI_CONFIG_DIR=$CUSTOM_CONFIGS_DIR/wofi
CUSTOM_WOFI_CONFIG_FILE=$CUSTOM_WOFI_CONFIG_DIR/config
CUSTOM_WOFI_STYLE_CSS_FILE=$CUSTOM_WOFI_CONFIG_DIR/style.css

# Custom fonts
CUSTOM_FONTS_DIR=$(pwd)/fonts

# Custom wallpapers
CUSTOM_WALLPAPERS_DIR=$(pwd)/wallpapers
CUSTOM_WALLPAPERS_FILE=$CUSTOM_WALLPAPERS_DIR/wallpaper.png

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
	if [[ "$ENABLE_DEBUG" = true ]]; then
		echo -e "\e[36mDEBUG: $1\e[0m"
	fi
}

log()
{
    echo -e "\e[34m$1\e[0m"
}

#################### UTILITY FUNCTIONS ####################

make_directory()
{
	local dir_path="$1"
	local user_name="$2"
	local perms="$3"
	log_debug "Making directory '$dir_path' owned by '$user_name' with permissions '$perms'"

	if [[ -z "$dir_path" ]]; then
		log_error "Directory path is required. Unable to create directory '$dir_path'"
		return 1
	fi

	if [[ -z "$user_name" ]]; then
		log_error "Username is required. Unable to create directory '$dir_path'"
		return 1
	fi

	if [[ -z "$perms" ]]; then
		log_error "Permissions are required. Unable to create directory '$dir_path'"
		return 1
	fi

	# Check if user exists
	if  ! id "$user_name" >/dev/null 2>&1; then
		log_error "User '$user_name' does not exist. Unable to create directory '$dir_path'"
		return 1
	fi

	# Validate octal permissions (exactly 3 digits, 000–777)
	if [[ ! "$perms" =~ ^[0-7]{3}$ ]]; then
		log_error "Invalid octal permissions given '$perms'. Unable to create directory '$dir_path'"
		return 1
	fi

	if [[ ! -d "$dir_path" ]]; then
		mkdir -p "$dir_path"
		if [[ $? -ne 0 ]]; then
			log_error "Failed to create directory '$dir_path'"
			return 1
		fi
	fi

	chown "$user_name":"$user_name" "$dir_path"
	if [[ $? -ne 0 ]]; then
		log_error "Failed to set ownership to '$user_name' on '$dir_path'"
		return 1
	fi

	chmod "$perms" "$dir_path"
	if [[ $? -ne 0 ]]; then
		log_error "Failed to set permissions ('$perms') on '$dir_path'"
		return 1
	fi

	log_debug "Successfully created directory '$dir_path'"
	return 0
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
	if [[ -d $CUSTOM_CONFIGS_DIR ]]; then
		log_success "Found custom configurations directory"
		return 0
	else
		log_error "Could not find custom configurations directory"
		return 1
	fi
}

check_build_dependencies()
{
	install_pacman_package "base-devel"
	install_pacman_package "git"
}

check_prerequisites()
{
	log "Checking prerequisites..."
	check_root
	check_os
	check_hyprland
	check_build_dependencies
	check_configs
	log_success "Checked all prerequisites. Proceeding with custom Hyprland setup"
}

#################### INSTALL FUNCTIONS ####################

is_installed_by_pacman()
{
	if pacman -Q $1 >/dev/null 2>&1; then
		log_success "$1 is already installed"
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
			log_error "Failed to install $1 using pacman"
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
		man-db
    	zsh
		pavucontrol
		brightnessctl
    	curl
		p7zip
		yazi
    	vim
    	gvim
    	gedit
    	code
    	openssh
    	docker
		waybar
		wofi
		firefox
		strace
	)

	for pkg in "${PACKAGES[@]}"; do
    	install_pacman_package "$pkg"
	done

	log_success "Installed all pacman packages"
}

is_installed()
{
	command -v "$1" >/dev/null 2>&1
}

install_yay()
{
	log "Installing yay..."

	if is_installed "yay"; then
		log_success "yay is already installed"
		return 0
	fi

	YAY_BUILD_DIR=$(mktemp -d)
	if [ $? -ne 0 ]; then
		log_error "mktemp failed to make temp directory for installing yay"
		return 1
	fi

	log_debug "Cloning yay repository into $YAY_BUILD_DIR"
	git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR"
	if [ $? -ne 0 ]; then
		log_error "Failed to clone yay repository"
		rm -rf $YAY_BUILD_DIR
		return 1
	fi

	log_debug "Building and installing yay"
	cd $YAY_BUILD_DIR/yay
	runuser -l "$SUDO_USER" -c "makepkg -si --noconfirm"
	YAY_INSTALL_RC=$?
	rm -rf $YAY_BUILD_DIR

	if [[ $YAY_INSTALL_RC -ne 0 ]] && is_installed "yay"; then
		log_success "Installed yay"
		return 0
	else
		log_error "Failed to install yay"
		return 1
	fi
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
		log_debug "Custom config file $1 was set successfully in directory $2"
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

	if ! is_installed "zsh"; then
		log_warning "zsh is not installed. Skipping changing shell to zsh"
		return 0
	else
		ZSH_PATH="$(command -v zsh)"
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

	log_success "Default shell is already zsh"
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

	if [[ $? -ne 0 ]]; then
		log_error "Failed to update HandleLidSwitch in $LOGIND_CONF (sed exit code: $SED_RC)"
		return 1
	else
		log_success "Updated HandleLidSwitch to lock in $LOGIND_CONF"
		return 0
	fi
}

set_up_waybar_config()
{
	log_debug "Setting up custom waybar configuration"

	if [[ ! -d $LOCAL_WAYBAR_CONFIG_DIR ]]; then
		log_debug "Local waybar configuration directory does not exist. Creating..."
		make_directory "$LOCAL_WAYBAR_CONFIG_DIR" "$SUDO_USER" "755"
	fi

	set_up_config_file $CUSTOM_WAYBAR_CONFIG_JSONC_FILE $LOCAL_WAYBAR_CONFIG_DIR
	set_up_config_file $CUSTOM_WAYBAR_CONFIG_STYLE_CSS_FILE $LOCAL_WAYBAR_CONFIG_DIR

	log_success "Set up custom waybar configuration"
}

set_up_wofi_config()
{
	log_debug "Setting up custom wofi configuration"

	if [[ ! -d $LOCAL_WOFI_CONFIG_DIR ]]; then
		log_debug "Local wofi configuration directory does not exist. Creating..."
		make_directory "$LOCAL_WOFI_CONFIG_DIR" "$SUDO_USER" "755"
	fi

	set_up_config_file $CUSTOM_WOFI_CONFIG_FILE $LOCAL_WOFI_CONFIG_DIR
	set_up_config_file $CUSTOM_WOFI_STYLE_CSS_FILE $LOCAL_WOFI_CONFIG_DIR

	log_success "Set up custom wofi configuration"
}

set_up_yazi_config()
{
	log_debug "Setting up custom yazi configuration"

	if [[ ! -d $LOCAL_YAZI_CONFIG_DIR ]]; then
		log_debug "Local yazi configuration directory does not exist. Creating..."
		make_directory "$LOCAL_YAZI_CONFIG_DIR" "$SUDO_USER" "755"
	fi

	set_up_config_file $CUSTOM_YAZI_TOML_FILE $LOCAL_YAZI_CONFIG_DIR

	log_success "Set up custom yazi configuration"
}

set_up_configurations()
{
	log "Setting up custom configurations..."
	
	# vimrc
	set_up_config_file $CUSTOM_VIM_CONFIG_FILE $HOME
	log_success "Set up custom vim config"

	# bashrc
	set_up_config_file $CUSTOM_BASH_CONFIG_FILE $HOME
	log_success "Set up custom bash config"

	# zshrc
	set_up_config_file $CUSTOM_ZSH_CONFIG_FILE $HOME
	log_success "Set up custom zsh config"

	change_shell_to_zsh

	log "Setting up custom hyprland configurations..."
	# hyprland conf
	set_up_config_file $CUSTOM_HYPRLAND_CONFIG_FILE $HYPRLAND_CONFIG_DIR
	log_success "Set up hyprland config"

	# hyprlock conf
	set_up_config_file $CUSTOM_HYPRLOCK_CONFIG_FILE $HYPRLAND_CONFIG_DIR
	log_success "Set up hyprlock config"
	set_up_lock_handle_lid_switch

	# hypridle conf
	set_up_config_file $CUSTOM_HYPRIDLE_CONFIG_FILE $HYPRLAND_CONFIG_DIR
	log_success "Set up hypridle config"

	# hyprpaper conf
	set_up_config_file $CUSTOM_HYPRPAPER_CONFIG_FILE $HYPRLAND_CONFIG_DIR
	log_success "Set up hyprpaper config"

	# waybar
	set_up_waybar_config

	# wofi
	set_up_wofi_config

	# yazi
	set_up_yazi_config

	log_success "Set up custom configurations"
}

#################### FONTS ####################

install_fonts()
{
	log "Installing custom fonts..."
	if [[ ! -d $CUSTOM_FONTS_DIR ]]; then
		log_warning "Cannot find custom fonts directory. Skipping custom installation of fonts"
		return 0
	fi

	if [[ ! -d $LOCAL_FONTS_DIR ]]; then
		log_warning "Cannot find local fonts directory. Skipping custom installation of fonts"
		return 0
	fi

	cp -r $CUSTOM_FONTS_DIR/* $LOCAL_FONTS_DIR

	if [[ $? -eq 0 ]]; then
		log_debug "Successfully copied custom fonts to $LOCAL_FONTS_DIR"
	else
		log_warning "Failed to copy custom fonts to $LOCAL_FONTS_DIR. Skipping custom installation of fonts"
		return 0
	fi

	# Update fonts cache
	if [[ "$ENABLE_DEBUG" = true ]]; then
		fc-cache -fv
	else
		fc-cache -f
	fi

	if [[ $? -eq 0 ]]; then
		log_success "Installed custom fonts"
		return 0
	else
		log_error "Failed to install custom fonts"
		return 1
	fi
}

#################### WALLPAPERS ####################

add_wallpapers()
{
	log "Adding custom wallpapers..."

	if [[ ! -d $LOCAL_WALLPAPERS_DIR ]]; then
		log_debug "Local wallpapers directory does not exist. Creating..."
		make_directory "$LOCAL_WALLPAPERS_DIR" "$SUDO_USER" "755"
	fi

	cp $CUSTOM_WALLPAPERS_FILE $LOCAL_WALLPAPERS_DIR

	if [[ $? -eq 0 ]]; then
		log_success "Added custom wallpapers"
		return 0
	else
		log_error "Failed to add custom wallpapers"
		return 1
	fi
}

#################### SERVICES ####################

enable_service()
{
	local service="$1"
	service="${service,,}"  # case-insensitive

	log_debug "Enabling service: $service"

	if systemctl enable $service; then
		log_success "$service service enabled"
	else
		log_warning "Failed to enable service $service"
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

parse_flags()
{
	OPTIND=1
	while getopts ":d" opt; do
		case $opt in
			d)
				ENABLE_DEBUG=true
				log_debug "Debug mode was enabled"
				;;
			\?)
				log_error "Invalid option provided: -$OPTARG"
				exit 1
				;;
		esac
	done
	shift $((OPTIND - 1))
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
	parse_flags "$@"
	prompt_start
	check_prerequisites
	install_pacman_packages
	install_yay
	add_wallpapers
	set_up_configurations
	install_fonts
	enable_services
	prompt_reboot
}

# run as sudo -E ./setup_hyprland.sh
main "$@"
