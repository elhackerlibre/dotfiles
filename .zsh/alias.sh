# vim:ft=zsh:ts=4:sts=4:sw=4:

alias l=ls
alias ...='cd ../..'
alias ....='cd ../../..'

alias -s tex=vim
alias -s c=vim
alias -s cpp=vim

alias ag='ag --pager="less -R"'
alias difftree='rsync -crv --dry-run '
# disable Esc as meta in the multiplexers, otherwise evil is unusable
#     screen: maptimeout 5
#     tmux: set -g escape-time 0
alias emacs='emacs -nw'
# alias gcc='colorgcc'
alias info='info --vi-keys'
alias vi='vim -p'
alias vim='vim -p'
alias gdb='gdb --silent --nowindows'
# TODO: need to figure out how to use neovim and <alt>+letter as <esc>+letter
# alias vi='nvim -p'
# alias vim='nvim -p'

alias drop-caches='echo 3 | sudo tee /proc/sys/vm/drop_caches'

# aur.sh is currently broken for aur4
function aurdl() {
    local cwd destination package

    cwd=$(pwd)
    destination=${BUILDDIR:-$PWD}
    for package in ${@##-*}; do
        cd "$destination"
        curl "https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz" | tar xz
        cd "$package"
        makepkg ${@##[^\-]*}
    done
    cd $cwd
}

function ecask() {
    # TODO: figure out how to escape ' inside a alias
    emacs -Q -nw --eval "(require 'cask \"/home/hack/.cask/cask.el\")" -f cask-initialize $@
}
alias ecask=ecask

function sshkeygen() {
    \ssh-keygen -o $@
}
alias ssh-keygen=sshkeygen

function sshaddkey() {
    if [ -e ~/.gnupg/gpg-agent.conf ]; then
        ttl=$(grep ttl-ssh ~/.gnupg/gpg-agent.conf | head -n1 | awk '{print $2}')
        ssh-add -t $ttl $@
    else
        ssh-add $@
    fi
}
alias ssh-add=sshaddkey

function sshkey(){
    [ -z "${SSH_AUTH_SOCK}" ] && eval $(ssh-agent) >/dev/null 2>&1

    # if we are using gpg-agent this operation will fail
    \ssh-add -l > /dev/null 2>&1
    sshagent=$?

    [ $sshagent -eq 0 ] && \ssh -G $@ | grep -i identityfile | awk '{print $2}' | while read unexpanded_file; do
        file=${unexpanded_file/#\~/$HOME}

        if [ -e $file ]; then
            ssh-add -l | grep $file > /dev/null || ssh-add $file
        fi
    done

    \ssh $@
}
alias ssh=sshkey

# started using pyenv and this was cloaking the env binary
#env() {
#    [ ! $# -eq 1 ] && return
#    project=$1
#    work=${WORK:-~/work}
#    python=${PYTHON:-python3.5}
#    version=${python#python}
#    venv=$work/envs/${project}-${version}/
#
#    [ ! -d $venv ] && {
#        mkdir -p $(dirname ${venv})
#        virtualenv-${version} $venv
#    }
#
#    source ${venv}/bin/activate
#    [ -d $work/projects/$project ] && cd $work/projects/$project
#}
#
#env-2.7() {
#    PYTHON=python2.7
#    env $@
#}

#alias chromium='chromium --ignore-gpu-blacklist'
#alias grep='grep --color=auto'
#alias grep='ack --pager="less -R"'
#alias ack='ack --pager="less -R"'

if (( ! $+commands[ack] && $+commands[ack-grep] )); then
    alias ack='ack-grep';
fi

# TODO: [- or -] may happen inside a regex, needs to change the start and end for deletion
if (( $+commands[wdiff] )); then
    filter_changes='/\[-/,/-\]/; /{\+/,/\+}/'

    if (( $+commands[cwdiff] )); then
        function _diff(){ \wdiff $@ | awk $filter_changes | cwdiff -f }
    else
        function _diff(){ \wdiff $@ | awk $filter_changes }
    fi
elif (( $+commands[colordiff] && $+commands[diff] )); then
    function _diff(){ \diff $@ | colordiff }
fi

if whence _diff > /dev/null; then
    alias diff=_diff
fi

if (( $+commands[php] )); then
    function urlencode() { php -r '$s = isset($argv[1]) ? $argv[1] : fgets(STDIN); echo urlencode($s) . "\n";' $@ }
    function urldecode() { python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])" $1 }
fi

if (( $+commands[python] )); then
    if ! whence _diff > /dev/null; then
        function urlencode() { python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1])" $1 }
    fi
    function format() { python2.7 -c "import sys; print sys.argv[1].format(*(sys.argv[2:] if len(sys.argv) > 2 else sys.stdin))" $@; }
fi

# https://nicholassterling.wordpress.com/2012/03/30/a-zsh-map-function/
function mapa() {
    typeset f="\$[ $1 ]"; shift
    map "$f" "$@"
}

# arch's: /usr/lib/initcpio/functions
map() {
    local r=0
    for _ in "${@:2}"; do
        "$1" "$_" || (( $# > 255 ? r=1 : ++r ))
    done
    return $r
}

function urlencodestream() {
    mapa urlencode
}


function smart_listing(){
    # This is a "smart" ls
    # the only reason for this is because the -B flag is not overwritten by the -a/-A flags
    # this is not gonna list vim backup files on normal ls, but is gonna list them when the all flag is set
    show_all=false
    i=1
    for arg in $@; do
        if [[ $arg == '-B' ]]; then
            argv[$i]=()
        elif [[ $arg == '-a' ]]; then
            show_all=true
            argv[$i]=()
        elif [[ $arg == '-A' ]]; then
            show_all=true
            argv[$i]=()
        fi
        ((i=i+1))
    done

    if ($show_all); then
        show_all='-A'
    else
        show_all='-B'
    fi
    \ls --classify --color=auto $show_all $argv
}
alias ls=smart_listing

# this confuses pyenv and setup.py cannot be executed corretly by ptpython
# (( $+commands[ptpython] )) && alias python=ptpython

# function catwrapper(){
#     prog=$1; shift;
#     pyg_args=$1; shift;
#     $prog $@ | pygmentize $pyg_args;
# }
# alias cat='wrapper cat -g'
#

function lyrics() {
    [ $# -ne 2 ] && echo 'lyrics <bandname> <musicname>' && return 1

    UA='Mozilla/5.0 (X11; Linux x86_64; rv:35.0) Gecko/20100101 Firefox/35.0'
    curl --silent -A$UA http://www.azlyrics.com/lyrics/$1/$2.html | awk '/start of lyrics/,/end of lyrics/ { print $0 }' | sed 's/<[^>]*>//g'

    # curl --silent 'http://letras.mus.br/$1/$2/' | awk '/id="div_letra"/,/id="js-adsenseplayer"/ { print $0 }' | sed 's/<[^>]*>//g'
}

function color() {
    [ $# -ne 1 ] && echo "${0} <file>"

    source ~/work/envs/tools-2.7/bin/activate

    cat ${1} | pygmentize -l ${1/*./} -f html -O noclasses > "${1}.html"
}

function git-report() {
    [ $# -ne 1 ] && echo "${0} [author]" && return 1

    git log --author $1 --author-date-order --all --no-merges --date=relative --abbrev-commit "--pretty=format:[%ar] %an %H" --stat
}

function slugify() {
    # rely on the fact that this function is defined on my .zshrc
    [ $# -eq 0 ] && xargs -I{} zsh -ic "slugify '{}'" && return

    echo $@ | tr '[:upper:]' '[:lower:]' | sed 's,\s,_,g'
}

function cores() {
    awk '/^processor/ {cpu++} END {print cpu}' /proc/cpuinfo
}

function pxargs() {
    threads=$(cores)
    serverlist=$1
    shift 1
    xargs -a $serverlist -I"SERVER" -P${threads} -n1 sh -c "$@"
}
