#!/bin/zsh
#                                    
#         _ _        _       _       
#        (_) |      | |     | |      
#  __   ___| |_ __ _| |  ___| |__    
#  \ \ / / | __/ _` | | / __| '_ \   
#   \ V /| | || (_| | |_\__ \ | | |  
#    \_/ |_|\__\__,_|_(_)___/_| |_|  
#                                    
#  

# PLATFORM is the environment variable that
# retrieves the name of the running platform
export PLATFORM

_TAB="$(printf "\t")"
_SPACE=' '
_BLANK="${_SPACE_}${_TAB}"
_IFS_="$IFS#

vitalize() {
  return 0
}

# General utilities
# $- : シェルに設定されているオプションを保持
is_interactive() {
  if [ "${-/i/}" != "$-" ]; then
    return 0
  fi
  return 1
}

is_bash() {
  [ -n "$BASH_VERSION" ]
}

is_zsh() {
  [ -n "$ZSH_VERSION" ]
} 

is_at_least() {
  if [ -z "$1" ]; then
    return 1
  fi

  # for Z shell
  if is_zsh; then
    # autoload : シェル関数を自動読み込みするシェルの組み込み関数
    # -U : 展開される関数の内部でaliasの展開をしないためのオプション
    autoload -Uz is-at-least
    # ${1:-} : if not $1, default -
    is-at-least "${1:-}"
    # $? : 直前のコマンドの終了値を参照 (0:成功、1:失敗）
    return $?
  fi
  
  # sed -e 's/[置換前の文字]/[後の文字]/g'
  atleast="$(echo $1 | sed -e 's/\.//g')"
  #${param : -[デフォルト値]}
  version="$(echo ${BASH_VERSION:-0.0.0} | sed -e 's/^\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\).*/\1/' | sed -e 's/\.//g')"
  
  # zero padding
  # $# : 指定した引数の数のこと
  # しかし、 ${#atleast}　はなにを示している
  echo "#atleast : ${#atleast}"
  while [ ${#atleast} -ne 6 ]
  do
    atleast="${atleast}0"
  done
  
  #zero padding
  while [ ${#version} -ne 6 ]
  do
    version="${version}0"
  done

  # verbose
  # echo "$atleast < $version"
  if [ "$atleast" -le "$version" ]; then
    return 0
  else
    return 1
  fi
}

# os_detect export the PLATFORM variable as you see fit
os_detect() {
  export PLATFORM
  case "$(ostype)" in
    *'linux'*)  PLATFORM='linux'    ;;
    *'darwin'*) PLATFORM='osx'      ;;
    *'bsd'*)    PLATFORM='bsd'      ;;
    *)          PLATFORM='unknown'  ;;
  esac
}

# is_osx returns true if running OS is Mac
is_osx() {
  os_detect
  if [ "$PLATFORM" = "osx" ]; then
    return 0
  else
    return 1
  fi
}
alias is_mac=is_osx

# is_linux returns true if running OS is GNU/Linux
is_linux(){
  os_detect
  if [ "$PLATFORM" = "linux" ]; then
    return 0
  else
    return 1
  fi
}

# is_bsd returns true if running OS is FreeBSD
is_bsd() {
  os_detect
  if [ "$PLATFORM" = "bsd" ]; then
    return 0
  else
    return 1
  fi
}

# get_os returns OS name of the platform that is running
git_os() {
  local os
  for os in osx linux bsd; do
    if is_$os; then
      echo $os
    fi
  done
}

e_newline() {
    printf "\n"
}

e_header() {
    printf " \033[37;1m%s\033[m\n" "$*"
}

e_error() {
    printf " \033[31m%s\033[m\n" "✖ $*" 1>&2
}

e_warning() {
    printf " \033[31m%s\033[m\n" "$*"
}

e_done() {
    printf " \033[37;1m%s\033[m...\033[32mOK\033[m\n" "✔ $*"
}

e_arrow() {
    printf " \033[37;1m%s\033[m\n" "➜ $*"
}

e_indent() {
    for ((i=0; i<${1:-4}; i++)); do
        echon " "
    done
    if [ -n "$2" ]; then
        echo "$2"
    else
        cat <&0
    fi
}

e_success() {
    printf " \033[37;1m%s\033[m%s...\033[32mOK\033[m\n" "✔ " "$*"
}

e_failure() {
    die "${1:-$FUNCNAME}"
} 

nk() {
    if [ "$#" -eq 0 -o "$#" -gt 2 ]; then
        echo "Usage: ink <color> <text>"
        echo "Colors:"
        echo "  black, white, red, green, yellow, blue, purple, cyan, gray"
        return 1
    fi

    local open="\033["
    local close="${open}0m"
    local black="0;30m"
    local red="1;31m"
    local green="1;32m"
    local yellow="1;33m"
    local blue="1;34m"
    local purple="1;35m"
    local cyan="1;36m"
    local gray="0;37m"
    local white="$close"

    local text="$1"
    local color="$close"

    if [ "$#" -eq 2 ]; then
        text="$2"
        case "$1" in
            black | red | green | yellow | blue | purple | cyan | gray | white)
            eval color="\$$1"
            ;;
        esac
    fi

    printf "${open}${color}${text}${close}"
}

logging() {
    if [ "$#" -eq 0 -o "$#" -gt 2 ]; then
        echo "Usage: ink <fmt> <msg>"
        echo "Formatting Options:"
        echo "  TITLE, ERROR, WARN, INFO, SUCCESS"
        return 1
    fi

    local color=
    local text="$2"

    case "$1" in
        TITLE)
            color=yellow
            ;;
        ERROR | WARN)
            color=red
            ;;
        INFO)
            color=blue
            ;;
        SUCCESS)
            color=green
            ;;
        *)
            text="$1"
    esac

    timestamp() {
        ink gray "["
        ink purple "$(date +%H:%M:%S)"
        ink gray "] "
    }

    timestamp; ink "$color" "$text"; echo
}

log_pass() {
    logging SUCCESS "$1"
}

log_fail() {
    logging ERROR "$1" 1>&2
}

log_fail() {
    logging WARN "$1"
}

log_info() {
    logging INFO "$1"
}

log_echo() {
    logging TITLE "$1"
}

# is_exists returns true if executable $1 exists in $PATH
is_exists() {
    which "$1" >/dev/null 2>&1
    return $?
}

# has is wrapper function
has() {
    is_exists "$@"
}

# die returns exit code error and echo error message
die() {
    e_error "$1" 1>&2
    exit "${2:-1}"
}

# is_login_shell returns true if current shell is first shell
is_login_shell() {
    [ "$SHLVL" = 1 ]
}

# is_git_repo returns true if cwd is in git repository
is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
    return $?
}

# is_screen_running returns true if GNU screen is running
is_screen_running() {
    [ ! -z "$STY" ]
}

# is_tmux_runnning returns true if tmux is running
is_tmux_runnning() {
    [ ! -z "$TMUX" ]
}

# is_screen_or_tmux_running returns true if GNU screen or tmux is running
is_screen_or_tmux_running() {
    is_screen_running || is_tmux_runnning
}
