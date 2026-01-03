#
# ~/.bashrc
#

export EDITOR="vim"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -la --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \e[1m\w\e[0m]\$ '

### temp ###
alias todo='vim /home/gogol/todo.txt'
alias vi='vim'
alias g='gedit'
alias gv='gvim'
alias eal='vim /home/gogol/.bashrc'
alias sal='source /home/gogol/.bashrc'
alias gc='google-chrome-stable >/dev/null 2>&1 &'
alias hlc='vim /home/gogol/.config/hypr/hyprland.conf'
alias cdhlc='cd /home/gogol/.config/hypr' 
alias wbj="vim /home/gogol/.config/waybar/config.jsonc"
alias wbs="vim /home/gogol/.config/waybar/style.css"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
