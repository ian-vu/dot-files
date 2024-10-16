#i=0; while [ $? -eq 0 ]; do i=$((i+1)); echo -n "$i. "; git rev-parse --symbolic-full-name @{-$i} 2> /dev/null; done If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

#### Functions ####

# Function to check if the system is macOS
is_mac() {
    [[ "$(uname)" == "Darwin" ]]
}

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="powerlevel9k/powerlevel9k"
# ZSH_THEME="spaceship"
# ZSH_THEME="sobole"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git, zsh-autosuggestions, zsh-syntax-highlighting, wd)
# plugins=(git zsh-syntax-highlighting zsh-autosuggestions cp wd z extract osx history web-search) #vi-mode)
plugins=(
  fzf-tab # This needs to be before zsh-autosuggestions and fast-syntax-highlighting
  fast-syntax-highlighting
  # z
  F-Sy-H
  zsh-autosuggestions
  # zsh-autocomplete
  extract
  macos
  history
  # colored-man-pages
  colorize
) #vi-mode)


source $ZSH/oh-my-zsh.sh

# Custom
# source ~/.oh-my-zsh/custom/plugins/aws_zsh_completer.sh


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias cd!='cd $OLDPWD'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias vim='nvim'
alias v='vim'

alias neo='neovide --no-tabs --frame transparent'

# Tmux things
alias ta='tmux attach'
alias tx='tmuxinator'

# Spoitify
alias pause='spotify pause'
alias play='spotify play'
alias next='spotify next'
alias back='spotify back'

alias hs='hsi'

if is_mac; then
  alias rm='trash'
  alias rmdir='trash'
  alias rm!='/bin/rm -rv'
  alias rmdir!='/bin/rmdir'
fi

alias zs='source ~/.zshrc'
alias copy='pbcopy'
alias paste='pbpaste'
alias cp='cp -Riv'
alias mv='mv -fv'
alias h='history'
alias c='cd'
alias e='exit'

alias getsize='du -sh'

alias lg='lazygit'
alias gg='lazygit'
alias gs='git status'
alias gits='git status'
alias gita='git add'
alias gitl="git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short"
alias gitc='git commit'
alias git-branch-previous='i=0; while [ $? -eq 0 ]; do i=$((i+1)); echo -n "$i. "; git rev-parse --symbolic-full-name @{-$i} 2> /dev/null; done'
alias gitb=git-branch-previous

alias tf='terraform'

alias zshrcv='vim ~/.zshrc'
alias zshrca='atom ~/.zshrc'

alias npr='npm run --silent $*'
alias chrome="open -a 'Google Chrome'"
alias arst='asdf'

alias setaws="source ~/.bin/setawsprofile $1"


# Export AWS credentials to environment variables. Uses aws-sso-util to initiate login if necessary.

setawsprofile() {
    if [ $# -ne 1 ]; then
        echo "Usage: setawsprofile <profile_name>"
        echo "Please provide exactly one argument (the profile name)."
        return 1
    fi

    export AWS_PROFILE="$1"

    # # Check if aws-sso-util is installed
    # if ! command -v aws-sso-util &> /dev/null; then
    #     echo "Error: aws-sso-util is not installed. Please install it and try again."
    #     return 1
    # fi
    #
    # # Check if the token is valid
    # if ! aws-sso-util check | grep -q "Token appears to be valid for use"; then
    #     echo "AWS SSO token is not valid. Initiating login..."
    #     aws-sso-util
    # fi

    # Export AWS credentials
    eval $(aws configure export-credentials --profile $AWS_PROFILE --format env)
    echo "AWS credentials exported to environment variables."

    echo "AWS profile set to: $AWS_PROFILE"
}

alias awssetprofile='setawsprofile'


# Function to process files recursively printing path and contents to be used with ai
print-files() {
    local dir="$1"

    # Loop through all files and directories in the current directory
    for item in "$dir"/*; do
        if [[ -f "$item" ]]; then
            # If it's a file, print its path and contents
            echo "File: $item"
            echo "Contents:"
            cat "$item"
            echo "----------------------------------------"
        elif [[ -d "$item" ]]; then
            # If it's a directory, recursively process its contents
            print-files "$item"
        fi
    done
}

bindkey '^ ' autosuggest-execute
bindkey '^[ ' autosuggest-accept

activate_venv() {
    if [ -d "venv" ]; then
        source venv/bin/activate
    elif [ -d ".venv" ]; then
        source .venv/bin/activate
    else
        echo "No virtual environment found. Create one using 'python -m venv venv' or 'python -m venv .venv'"
    fi
}
alias av='activate_venv'

alias de='pyenv deactivate'
alias activate='pyenv activate ${PWD##*/}'
alias act='activate_venv'
# alias act='activate'

alias kc=kubectl

# bindkey '^[[A' history-substring-search-up
# bindkey '^[[B' history-substring-search-down

# Unbind keys
bindkey -r "^J"

qwe() {
  cat ~/dot-files/.vim/vimrc.base > ~/.vim/vimrc
  cat ~/dot-files/.vim/vimrc.base > ~/obsidian/.obsidian.vimrc

  cat ~/.config/nvim/lua/config/keymaps-base.lua > ~/.config/nvim/lua/config/keymaps.lua

  echo "Set qwerty settings"
}
col() {
  cat ~/dot-files/.vim/vimrc.base > ~/.vim/vimrc
  cat ~/dot-files/.vim/vimrc.colemak >> ~/.vim/vimrc

  cat ~/dot-files/.vim/vimrc.base > ~/obsidian/.obsidian.vimrc
  cat ~/dot-files/.vim/vimrc.colemak >> ~/obsidian/.obsidian.vimrc

  cat ~/.config/nvim/lua/config/keymaps-base.lua > ~/.config/nvim/lua/config/keymaps.lua
  cat ~/.config/nvim/lua/config/keymaps-colemak.lua >> ~/.config/nvim/lua/config/keymaps.lua

  echo "Set colemak settings"
}

alias qwf=col

proxyOn() {
  export http_proxy=http://localhost:3128
  export https_proxy=http://localhost:3128
  export HTTP_PROXY=http://localhost:3128
  export HTTPS_PROXY=http://localhost:3128
  ln -sf ~/.ssh/config-proxy-on ~/.ssh/config
  echo "Telstra Proxy on"
}
alias on='proxyOn'

proxyOff() {
  unset http_proxy
  unset https_proxy
  unset HTTP_PROXY
  unset HTTPS_PROXY
  ln -sf ~/.ssh/config-proxy-off ~/.ssh/config
  echo "Telstra Proxy off"
}
alias off='proxyOff'

# Switch Mac Location
alias switch='networksetup -switchtolocation $1'
alias location='networksetup -getcurrentlocation'

alias wifiStatus='networksetup -getairportpower en0'
alias wifi='networksetup -setairportpower en0 $1 | echo Wifi $1'

# Open man page in preview
pman () {
    man -t "${1}" | open -f -a /Applications/Preview.app
}


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH=/usr/local/bin:$HOME/bin:$PATH
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="$PATH:/usr/local/Cellar/python/2.7.13_1/bin"
export PATH="$PATH:/usr/local/Cellar/openvpn/2.4.3/sbin"
export PATH="$PATH:/usr/local/sbin"
export PATH="$PATH:/Applications/Couchbase\ Server.app/Contents/Resources/couchbase-core/bin/cbq"
export PATH="$PATH:/Users/ivu/dev/git/git-fzf"
export PATH="$PATH:$HOME/.bin"
export PATH="$PATH:$HOME/.config/tmux/bin"


# Set up fzf-tab
# autoload -U compinit; compinit
# source $ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh


# Case insensitive tab completion for zsh
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Fuzzy finder
# https://github.com/junegunn/fzf#fuzzy-completion-for-bash-and-zsh
if is_mac; then
  eval "$(fzf --zsh)"
else
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi


# Remove fzf deplicates
setopt HIST_IGNORE_ALL_DUPS

alias f="fzf --preview 'cat {}'"

# cd to selected parent directory
fpd() {
  local declare dirs=()
  get_parent_dirs() {
    if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
    if [[ "${1}" == '/' ]]; then
      for _dir in "${dirs[@]}"; do echo $_dir; done
    else
      get_parent_dirs $(dirname "$1")
    fi
  }
  local DIR=$(get_parent_dirs $(realpath "${1:-$PWD}") | fzf-tmux --tac)
  cd "$DIR"
}
alias pd='fpd'

# checkout into a branch
fbr() {
  local tags branches target
  tags=$(
git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
  branches=$(
git branch --all | grep -v HEAD |
sed "s/.* //" | sed "s#remotes/[^/]*/##" |
sort -u | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
  target=$(
(echo "$tags"; echo "$branches") |
    fzf --no-hscroll --no-multi --delimiter="\t" -n 2 \
        --ansi --preview="git log -200 --pretty=format:%s $(echo {+2..} |  sed 's/$/../' )" ) || return
  git checkout $(echo "$target" | awk '{print $2}')
}

# fshow - git commit browser with previews
alias glNoGraph='git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$@"'
local _gitLogLineToHash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
local _viewGitLogLine="$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | diff-so-fancy'"

# fcoc_preview - checkout git commit with previews
fcoc() {
  local commit
  commit=$( glNoGraph |
    fzf --no-sort --reverse --tiebreak=index --no-multi \
        --ansi --preview $_viewGitLogLine ) &&
  git checkout $(echo "$commit" | sed "s/ .*//")
}

# fshow - git commit browser with previews
fshow() {
    glNoGraph |
        fzf --no-sort --reverse --tiebreak=index --no-multi \
            --ansi --preview $_viewGitLogLine \
                --header "enter to view, alt-y to copy hash" \
                --bind "enter:execute:$_viewGitLogLine   | less -R" \
                --bind "alt-y:execute:$_gitLogLineToHash | xclip"
}


# unalias z
# z() {
#   if [[ -z "$*" ]]; then
#     cd "$(_z -l 2>&1 | fzf +s --tac | sed 's/^[0-9,.]* *//')"
#   else
#     _last_z_args="$@"
#     _z "$@"
#   fi
# }

# zz() {
#   cd "$(_z -l 2>&1 | sed 's/^[0-9,.]* *//' | fzf -q "$_last_z_args")"
# }


# Setting fd as the default source for fzf
export FZF_DEFAULT_COMMAND="fd -I -E '*/node_modules/*' -E '*/coverage/*'"

# # default ops when calling fzf
export FZF_DEFAULT_OPTS='--pointer "➜" --info right --prompt "➜ " --color=gutter:-1 --height 20%'

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --type f"

# To apply the command to ALT-C as well
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d"

# Hide command number from results
export FZF_CTRL_R_OPTS="--with-nth 2.."

# # Set up pyenv
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
# export PYENV_VIRTUALENV_DISABLE_PROMPT=1

# Set up theme Starship
eval "$(starship init zsh)"

# Start up
export AWS_DEFAULT_REGION=ap-southeast-2
export EDITOR='nvim'

# eval $(thefuck --alias)

autoload -U +X bashcompinit && bashcompinit


# Set up z
eval "$(zoxide init zsh)"

# set up mise (coding language version manager)
eval "$(~/.local/bin/mise activate zsh)"

# Set config for lazygit
export XDG_CONFIG_HOME="$HOME/.config"

# Zsh autocompletions - https://github.com/marlonrichert/zsh-autocomplete?tab=readme-ov-file
# bindkey '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete
# bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
# bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

# Limit number of lines
# zstyle ':autocomplete:*' delay 100  # seconds (float)
# zstyle ':autocomplete:*' default-context history-incremental-search-backward

# Hide duplicates from search history
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# This should be last line in .zshrc
if [[ -f ~/.zshrc_local ]]; then
  source ~/.zshrc_local
fi
