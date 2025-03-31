# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting you-should-use)

source $ZSH/oh-my-zsh.sh

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

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias vim='nvim'
set -o vi
export EDITOR='nvim'

alias gloc="git config user.name segin-dz ; git config user.email seginipe@dozee.io"
alias jnb="jupyter notebook"
alias jlb="jupyter lab"
alias b="byobu"

## ESP-IDF aliases

alias get_idf=". $HOME/esp/esp-idf/export.sh"
alias idf_v5.0=". $HOME/esp/esp-idf-v5.0/export.sh"S
# Aliases for build and other frequently used commands
alias idf="idf.py"
alias idfb="idf.py build"

# Flash using idf.py on a specific USB port and then run HSPL monitor
function idffmp() {
    local port=${1:-0}  # Default to USB0 if no port is specified
    idf.py -p "/dev/ttyUSB${port}" flash && hspl_monitor $port
}

# Function to monitor using idf.py on a specific USB port
function idfm() {
    local port=${1:-0}  # Default to USB0 if no port is specified
    idf.py -p "/dev/ttyUSB${port}" monitor
}

# WEST aliases
set_up_west () {
    local ncs_version=${1:-2.7.0} # Default to 2.4.1 if no version is specified
    echo "Setting up west for ncs version $ncs_version"
    source ~/zephyrproject/.venv/bin/activate
    source ~/ncs/v${ncs_version}/zephyr/zephyr-env.sh && west zephyr-export
}

alias get_west="set_up_west";

function west_build() {
    local board_type=${1:-nrf5340dk_nrf5340_cpuapp}  
    command west build -d ./build -p -b "$board_type" -- -DNCS_TOOLCHAIN_VERSION=2.7.0
}

alias wb="west_build"
alias wb_nrf53="west_build nrf5340dk_nrf5340_cpuapp"
alias wb_nrf52="west_build nrf52840dk_nrf52840"
alias wb_nrf70="west_build nrf7002dk/nrf5340/cpuapp/ns"

function  west_flash () {
    command west flash -d ./build
}

alias wf="west_flash"
alias wbf="west_build && west_flash"

# Function to list all USB serial ports
function ls_a() {
    ls /dev/ttyACM* 
}

function ls_u() {
    ls /dev/ttyUSB*
}

# alias for picocom
function picu() {
    local port=${1:-0}  # Default to USB0 if no argument is passed
    picocom -b 115200 /dev/ttyUSB$port
}

function pica() {
    local port=${1:-0}  # Default to ACM0 if no argument is passed
    picocom -b 115200 /dev/ttyACM$port
}

alias pic="picu"
alias pica="pica"

function  git_commit() {
    if [ -z "$1" ]; then
        echo "No file to commit baka! :("
        return 1
    fi

    if [ -z "$2" ]; then
        echo "No commit message baka! :("
        return 1
    fi

    if [ $# -gt 2 ]; then
        echo "Too many arguments baka! :("
        return 1
    fi

    echo "Committing $1 with message $2 :)"
    git commit "$1" -m "$2"
    return 0
}

function clang_format_all() {
    # Format all the files in the folder ends with .c, .h, .cpp, .hpp
    find . -type f -name "*.[ch]" -o -name "*.[ch]pp" | xargs clang-format -i

}

alias clr="clear"
alias gcmt="git_commit"
alias upug="sudo apt-get update && sudo apt-get upgrade -y"
alias py="python3"
alias pyt="pytest"
alias gdh="git diff HEAD"
alias gct="git commit -a -m\"$1\""
alias bb="chromium"
alias grepr="grep -rin"
alias grep="grep --color=auto"
alias get_tb="export PATH=\"/home/yui/hacklab/TestBench/firmware/rpi:\$PATH\""
alias catcsv="~/code/pythonScripts/csvTabulatePrint.py"
alias bat="batcat"
alias server="~/code/pythonScripts/pythonServer.py"
alias lip="~/code/pythonScripts/lip.py"
alias ble="~/code/pythonScripts/ble_sender.py $1"
alias partition="~/code/pythonScripts/partitions_table.py $1"
alias g="lazygit"
alias env_nrf="source ~/zephyrproject/.venv/bin/activate"
alias get_nrf="source /home/seginipe/ncs/v2.4.1/zephyr/zephyr-env.sh && west zephyr-export"
alias tmux="tmux -u"
alias tsdiff="python3 ~/code/pythonScripts/python_ts_diff.py $1 $2"
alias nrfj="python3 ~/code/pythonScripts/nrfj.py $@"


#function run
run() {
    interval=${1:-1}  # Default sleep interval is 1 second if not provided

    shift
    while true; do
        "$@"
        sleep "$interval"
    done
}


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# kitty support for ssh
export TERM=xterm-256color

# the fuck
# eval $(thefuck --alias)
# eval $(thefuck --alias fk)

# nvim 
export PATH="$PATH:/opt/nvim-linux64/bin"

# cargo
#. "$HOME/.cargo/env"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
