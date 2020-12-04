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

# shell_has_started_interactively returns true if the current shell is
# running from command line
shell_has_started_interactively(){
  [ ! -z "$PS1" ]
}

# is_ssh_running returns true if the ssh deamon is available
is_ssh_running() {
  [ ! -z "$SSH_CLIENT" ]
}

# is_debug returns true if $DEBUG is set
is_debug() {
  if ["$DEBUG" = 1 ]; then
    return 0
  else
    return 1
  fi
}
alias is_int=is_number
alias is_num=is_number

# echon is a script to emulate the -n flag functionality with "echo"
echon() {
  # tr -d '\n'  :  -d(指定文字を削除）つまり'\n'を削除
  echo "$*" | tr -d '\n'
}

# noecho is the same as echon
noecho() {
  if [ "$(echo -n)" = "-n" ]; then
    # ${*:-> }  : 全ての引数(*)がないなら、デフォルト > で示す
    echo "${*:-> }\c"
  else
    echo -n "${@:-> }\c"
  fi
}

# lower returns a copy of the string with all letters mapped to their lower case
# shellcheck disable=SC2120
lower() {
  if [$# -eq 0 ]; then
    cat <&0
  elif [ $# -q 1 ]; then
    # shell if -f(通常のファイルなら)  -r(読み取り権限があるなら)
    if [ -f "$1" -a -r "$1" ]; then
      cat "$1"
    else
      echo "$1"  
  else
    return 1
  ### tr 変換対象の文字 変換文字 対象ファイル
  ### [:hoge:]は文字クラス 
  ### [:upper:]はファイル内の大文字
  ### [:lower:]はファイル内の小文字 
  fi | tr "[:upper:]" "[:lower:]"
}

# contains returns true if the specified string contains
# the specified substring, otherwise returns false
# http://stackoverflow.com/questions/2829613/how-do-you-tell-if-a-string-contains-another-string-in-unix-shell-scripting 
contains() {
  string="$1"
  substring="$2"
  if [ "${string#*$substring}" != "$string" ]; then
    return 0  # $substring is in $string
  else
    return 1
  fi
} 

# len returns the length of $1
len() {
  local length
  #echo hoge | wc -c　で結果が、space space space 語数になるのでそれを埋めるべく、regexが最後に追加されている s/ *//　は スペースをなしに置換する
  length="$(echo "$1" | wc -c | sed -e 's/ *//')"
  echo $(("$length" - 1))
}

# is_empty returns true if $1 consists of $_BLANK_
is_empty() {
  if [$# -eq 0 ]; then
    cat <&0
  else
    echo "$1"
  fi | grep -E "^[$_BLANK_]*$" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# path_remove returns new $PATH trailing $1 in $PATH removed
# It was heavily inspired by http://stackoverflow.com/a/2108540/142339
path_remove() {
  if [$# -eq 0 ]; then
    die "too few arguments"
  fi
  local arg path
  path=":$PATH:"
  # $@ は 引数のリスト
  for arg in "$@"
  do
    # オフセットと長さを指定して文字列を取得する
    # $ {パラメータ:オフセット:長さ }
    path="${path//:$arg:/:}"
  done

  # $ {hoge%:} は %によって、右端から最短で:にヒットしたものを除外
  # $ {hoge#:} は #によって、左端から最短で:にヒットしたものを除外
  path="${path%:}"
  path="${path#:}"
  
  echo "$path"
}

# Dotfiles

# Set DOTPATH as default variable
if [ -z "${DOTPATH:-}" ]; then
  DOTPATH=~/.dotfiles; export DOTPATH
fi

DOTFILES_GITHUB="https://github.com/hoge/dotfiles.git"; export DOTFILES_GITHUB

# shellcheck disable=SC1078,SC1079,SC2016
dotfiles_logo='
      | |     | |  / _(_) |           
    __| | ___ | |_| |_ _| | ___  ___  
   / _` |/ _ \| __|  _| | |/ _ \/ __| 
  | (_| | (_) | |_| | | | |  __/\__ \ 
   \__,_|\___/ \__|_| |_|_|\___||___/ 
  *** WHAT IS INSIDE? ***
  1. Download https://github.com/OnukiKazuya/dotfiles
  2. Symlinking dot files to your home directory
  3. Execute all sh files within `etc/init/` (optional)
  See the README for documentation.
  https://github.com/OnukiKazuya/dotfiles
  Copyright (c) 2020 "OnukiKazuya" aka @OnukiKazuya
  Licensed under the MIT license.
'


# if [ -p hoge ]; then
## は、-p file = fileが存在し、パイプファイルの場合はTRUE
dotfiles_download() {
  if [ -d "$DOTPATH" ]; then
    log_fail "$DOTPATH : already exists"
    exit 1
  fi

  e_newline
  e_header "Downloading dotfiles..."
  
  if is_debug; then
    :
  else
    if is_exists "git"; then
      # --recursive　は サブモジュール自動クローン（外部リポジトリを自動クローン）
      # dein.nvim等のplugin追加時、外部リポジトリを指定している時に便利
      git clone --recursive "$DOTFILES_GITHUB" "$DOTPATH"
    
    elif is_exists "curl" || is_exists "wget"; then
      # curl or wget
      local tarball="https://github.com/OnukiKazuya/dotfiles/archive/main.tar.gz"
      if is_exists "curl"; then
        curl -L "$tarball"
      elif is_exists "wget"; then 
        wget -0 - "$tarball"
      fi | tar xvf

      # ./dotfile-main　dir
      if [ ! -d dotfiles-main ]; then
        log_fail "dotfiles-main: not found"
        exit 1
      fi
      
      # commandコマンドで内部で定義したエイリアスや関数を【無視して】
      # 環境変数PATHに通っているコマンドのみを実行できるようにする
      command mv -f dotfiles-main "$DOTPATH"
    
    else
      log_fail "curl or wget required"
      exit 1
    fi
    e_newline && e_done "Download"
}

dotfiles_deploy() {
}
dotfiles_initialize() {
}
dotfiles_install(){
}
