# profile zsh 
#zmodload zsh/zprof

export EDITOR="vim"

if [[ -z "$SSH_CONNECTION" && -z "$SSH_CLIENT" && -z "$SSH_TTY" && -d "$HOME/.oh-my-zsh" ]]; then
	DISABLE_AUTO_UPDATE="true"
	DISABLE_MAGIC_FUNCTIONS="true"
	DISABLE_COMPFIX="true"

	# Smarter completion initialization
	autoload -Uz compinit
	if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    	compinit
	else
    	compinit -C
	fi

	export ZSH="$HOME/.oh-my-zsh"
	ZSH_THEME="agnoster"
	ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
	ZSH_AUTOSUGGEST_USE_ASYNC=1
	plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
	source $ZSH/oh-my-zsh.sh
else
	PROMPT='[%n@%m %B%~%b]$ '
fi

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Colorized commands
alias ls='ls -la --color=auto'
alias grep='grep --color=auto'

### temp aliases ###
alias todo='vim /home/gogol/todo.txt'

# general aliases
alias vi='vim'
alias g='gedit'
alias gv='gvim'
alias eal='vim /home/gogol/.zshrc'
alias sal='source /home/gogol/.zshrc'
alias gc='google-chrome-stable >/dev/null 2>&1 &'
alias hlc='vim /home/gogol/.config/hypr/hyprland.conf'
alias cdhlc='cd /home/gogol/.config/hypr'
alias wbj='vim /home/gogol/.config/waybar/config.jsonc'
alias wbs='vim /home/gogol/.config/waybar/style.css'

# ROS2
alias ros2docker="sudo docker run -it \
  --env="DISPLAY" \
  --env="QT_X11_NO_MITSHM=1" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="$HOME/Docker/Jazzy/dev_ws:/root/dev_ws" \
  --env="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
  --device=/dev/dri:/dev/dri \
  --name ubuntu-jazzy \
  --hostname ros2-jazzy \
  --net=host \
  --ipc=host \
  osrf/ros:jazzy-desktop-full"
alias startros2docker="sudo docker start /ubuntu-jazzy"
alias attachros2docker="sudo docker attach /ubuntu-jazzy"
alias rmros2docker="sudo docker rm -f /ubuntu-jazzy"

# git aliases
alias gs="git status"
alias gr="git restore"
alias dt="git diff"
alias dtc="git diff --cached"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# profile zsh
#zprof | tee ~/test.txt
