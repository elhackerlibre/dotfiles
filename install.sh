#!/usr/bin/bash
# vim: ts=4 sts=4 sw=4 et ft=sh:

set -e

error () {
    printf "$(tput bold)$(tput setaf 1) -> $1$(tput sgr0)\n" >&2
}

success () {
    printf "$(tput bold)$(tput setaf 2) -> $1$(tput sgr0)\n"
}

msg() {
    printf "$(tput bold)$(tput setaf 2) $1$(tput sgr0)\n"
}

info() {
    printf "$(tput bold)$(tput setaf 4) -> $1$(tput sgr0)\n"
}

die() {
    error "$1"
    exit 1
}

bin() {
    hash $1 2> /dev/null
}

require_bin() {
    [ $# -ne 1 ] && die "${0} needs 1 argument: ${0} binary"

    bin $1 || {
        die "Required binary was not found ${1}"
    }
}

# TODO: warn if the file exists and it is NOT a link
link() {
    [ $# -lt 1 -o $# -gt 2 ] && die "link needs one or two arguments (got $#): link <file> [destination]"

    file=$1
    target=$HOME/${2:-$1}
    original=$REPO/$1

    [ ! -e "$original" ] && {
        error "File ${original} does not exists, cannot create link ${target}"
        return
    }
    [ -e "$target" -a "$FORCE" -eq 1 ] && unlink $target
    [ -e $target ] && info "${target} already exists, skipping"
    [ ! -e $target ] && {
        info "${target} created"
        ln -s "${original}" "${target}"
    }
}

repo() {
    [ $# -ne 2 ] && die "repo needs two arguments (got $#): repo [url] [directory]"

    url=$1
    directory=$2

    [ ! -d $directory ] && \git clone $url $directory
    [ -d $directory ] && (cd $directory && \git pull)
}

is_readable() {
    [ $# -ne 1 ] && die "is_readable needs one arguments (got $#): repo [path]"

    [ -r $1 ] && error "$1 is not readable"
}

arch_pacman() {
    root=''
    [ $UID = 0 ] || root='sudo'

    msg "Installing packages"
    # adobe-source-sans-pro-fonts
    # ttf-droid
    # using systemd-timesyncd instead of openntpd: timedatectl set-ntp true
    # gccfortran, lapack -> scipy
    #
    # docker:
    #   systemctl enable docker.socket
    #   gpasswd -a <user>  docker
    #
    # pacman -Qq won't know that the group was installed
    # texlive-most
    # xorg
    # gst-plugins-bad
    # gst-plugins-base
    # gst-plugins-good
    # gst-plugins-ugly
    # gstreamer0.10-plugins
    # dnsutils
    # base-devel
    #
    # network managers:
    # wicd / networkmanager
    #
    # network monitor:
    # darkstat
    packages=( \
        cantarell-fonts
        font-mathematica
        terminus-font
        ttf-dejavu
        ttf-dejavu
        ttf-fira-mono
        ttf-fira-sans
        ttf-liberation
        xorg-fonts-100dpi
        xorg-fonts-75dpi
        xorg-fonts-alias
        xorg-fonts-encodings
        xorg-fonts-misc
        adobe-source-code-pro-fonts
        adobe-source-sans-pro-fonts
        adobe-source-serif-pro-fonts
        adobe-source-han-sans-cn-fonts
        adobe-source-han-sans-jp-fonts
        adobe-source-han-sans-kr-fonts
        adobe-source-han-sans-otc-fonts
        adobe-source-han-sans-tw-fonts

        acpi
        iw
        wireless_tools
        ifplugd
        wpa_actiond

        chromium
        dialog
        evince
        feh
        firefox
        gimp
        libreoffice
        nautilus
        numlockx
        obconf
        openbox
        pass
        xclip
        xorg-xinit
        cups
        libreoffice-fresh
        hplip

        wine
        winetricks
        # winetricks corefonts

        alsa-oss
        alsa-tools
        alsa-utils
        flashplugin
        gecko-mediaplayer
        gst-libav
        lib32-flashplugin
        mplayer
        pulseaudio
        pulseaudio-alsa
        youtube-dl
        youtube-viewer

        aria2
        emacs
        expect
        fortune-mod
        gnu-netcat
        gvim
        htop
        iotop
        jq
        lib32-alsa-plugins
        lua-lpeg
        moreutils
        mosh
        ncdu
        octave
        pigz
        rxvt-unicode
        scrot
        smartmontools
        steam
        sudo
        the_silver_searcher
        tmux
        tree
        unzip
        unrar
        vis
        wget
        zip
        zsh

        abs
        arch-install-scripts

        tk # required by gitk

        rustup  # conflicts with rust and cargo
        rustfmt
        rust-racer

        apache
        android-tools
        android-udev
        boost
        bsdiff
        clang
        clang-analyzer
        clang-tools-extra
        colordiff
        ctags
        cmake
        darcs
        docker
        docker-compose
        dwdiff
        fossil
        ftjam
        gcc-fortran
        gcc-multilib
        grafana-bin
        lldb
        git
        go
        graphviz
        kdesdk-kcachegrind
        lapack
        ltrace
        lua
        luajit
        llvm
        lsof
        mono
        net-tools
        npm
        nginx
        ocaml
        openssh
        parallel
        patchutils
        perf
        pssh
        pygmentize
        pypy
        pypy3
        python
        python2
        python2-virtualenv
        python-virtualenv
        python-virtualenvwrapper
        ragel
        re2
        re2c
        seahorse
        strace
        sysstat
        siege
        tidy
        tig
        uwsgi
        uwsgi-plugin-pypy
        uwsgi-plugin-python
        uwsgi-plugin-python2
        valgrind
        virtualbox
        virtualbox-guest-iso

        gdb
        # required by my custom gdb configuration [.gdb/c/longlist.py]
        python-pygments
        python-pycparser
    )

    to_install=()
    for pack in $packages; do
        pacman -Qq $pack > /dev/null 2>&1 || to_install+=("$pack")
    done

    if [ "${#to_install}" -gt 0 ]; then
        $root pacman -Sy $to_install
    else
        info "All official packages are installed"
    fi
}

arch_aur(){
    # anything bellow needs to run unprivileged, mostly because of makepkg
    [ $UID = 0 ] && return

    if ! bin aura; then
        require_bin curl
        bash <(curl aur.sh) -S aura-bin
        $root pacman -U aura-bin/*.pkg.*
    fi

    if bin aura; then
        # ttf-google-fonts-git
        # reflector
        # terraform
        # fzf
        # fzf-extras-git
        # packer-io
        # powerpill
        # neovim-git
        # python2-neovim-git

        # to compile vim-youcompleteme-git Hans Wennborg needs to be added into
        # the keyring:
        #
        # http://llvm.org/releases/download.html#3.7.0 PGP sig (Hans Wennborg <hans@chromium.org> 0x0FC3042E345AD05D)
        # gpg --recv-keys 0fc3042e345ad05d
        aur_packages=( \
            alacritty-git
            bear
            chromium-pepper-flash-dev
            # colout-git - using pygmentize directly
            dropbox
            otf-hack
            opam
            flamegraph-git
            neovim-git
            notify-osd-customizable
            powerpill
            python2-neovim-git
            rust-src
            jdk
            rr
            secp256k1-git
            vim-youcompleteme-git
            wrk
            wrk2-git
            pup-git
            # urxvt-resize-font-git
        )

        aur_to_install=()
        for aur in $aur_packages; do
            pacman -Qq $aur > /dev/null 2>&1 || $root aura -A $aur
        done
    fi
}

FORCE=0
while getopts "f" opt; do
    case $opt in
        f)
            FORCE=1
            ;;
    esac
done
shift $(($OPTIND-1))

require_bin git
require_bin vim

REPO=${HOME}/.dotfiles

repo 'https://github.com/hackaugusto/dotfiles.git' "$REPO"

link .bash_profile
link .bashrc
link .profile
link .zprofile
link .zshrc
link .zsh

# link .gnupg/gpg.conf
# link .gnupg/gpg-agent.conf

link .xinitrc
link .xbindkeysrc
link .XCompose
link .Xresources
link .Xresources.d

# mkdir -p $HOME/.config/fontconfig/conf.d
# link /etc/fonts/conf.avail/10-sub-pixel-rgb.conf .config/fontconfig/conf.d/10-sub-pixel-rgb.conf

link .bin
link .pdbrc
link .xmonad
link .screenrc
link .tmux.conf
link .urxvt
link .urxvt/resize-font

link .gdbinit
link .gdb/config
link .gdb/c/locallist
link .gdb/c/color
link .gdb/c/longlist.py
link .gdb/py/libpython.py

# git config --global core.excludesfile '~/.gitignore_global'
link .gitignore_global

link .vim
link .vimrc
link .vim .nvim
link .vimrc .nvimrc

mkdir -p ${HOME}/.emacs.d/lisp
link .emacs.d/init.el
git clone https://github.com/ProofGeneral/PG ~/.emacs.d/lisp/PG
(cd ~/.emacs.d/lisp/PG && make)

mkdir -p ${HOME}/.config
link .config/flake8
link .config/pep8
link .config/pylintrc
link .config/user-dirs.dirs

mkdir -p ${HOME}/.config/alacritty/
link .config/alacritty/alacritty.yml

mkdir -p ${HOME}/.config/openbox
link .config/openbox/autostart.sh
link .config/openbox/multimonitor.xml
link .config/openbox/rc.xml

# Depedencies for compilation
if bin pacman; then
    arch_pacman
fi

# Anything that needs to be compiles goes after here

msg 'Vim plugins'
repo 'https://github.com/hackaugusto/Vundle.vim.git' "${HOME}/.vim/bundle/Vundle.vim"
vim -u ${HOME}/.vim/plugins.vim +PluginUpdate +qa

# TODO: use neobundle or vim-plug
find -L ${HOME}/.vim -iname Makefile | grep -v -e html5.vim -e Dockerfile -e color_coded | while read plugin; do
    info $plugin
    (
        cd $(dirname $plugin);
        make
    ) > /dev/null
done

info 'color_coded'
(
    cd ~/.vim/bundle/color_coded
    [ -d ./build ] && rm -rf ./build
    mkdir build
    cd build
    cmake ..
    make
    make install
    make clean
    make clean_clang
)

repo 'https://github.com/cask/cask.git' "${HOME}/.cask"
(cd ${HOME}/.emacs.d/; ${HOME}/.cask/bin/cask install)

if bin pacman; then
    echo
    echo
    msg 'Edit the /etc/makepkg.conf file and remove the strip option:'
    echo 'OPTIONS+=(debug !strip)'
    echo
    echo
    msg 'Add the Xyne repo into the /etc/pacman.conf'
    echo
    echo '[xyne-x86_64]'
    echo 'SigLevel = Required'
    echo 'Server = http://xyne.archlinux.ca/repos/xyne'
    echo
    echo

    arch_aur
fi

SUDO=''
[ $UID = 0 ] || SUDO='sudo'

$SUDO grep -i '^pt_br.utf-?8' /etc/locale.gen || {
    error 'Missing locale pt_br on file /etc/locale.gen'
    info 'echo "pt_BR.UTF-8" >> /etc/local.gen'
}

$SUDO grep -i '^en_us.utf-?8' /etc/locale.gen || {
    error 'Missing locale en_us on file /etc/locale.gen'
    info 'echo "en_US.UTF-8" >> /etc/local.gen'
}

[ ! -e /etc/locale.conf ] && {
    echo
    echo 'Run the following command to set the system locale'
    msg 'localectl set-locale LANG=en_US.UTF-8'
    echo
    echo
    echo 'Run the following command to set X.org keymap'
    msg 'localectl set-x11-keymap br,us abnt2,pc105 ,dvorak terminate:ctrl_alt_bksp,grp:rctrl_toggle,ctrl:nocaps,ctrl:lctrl_meta'
    echo or
    msg 'setxkbmap -layout br,us -model abnt2,pc105 -variant ,dvorak -option terminate:ctrl_alt_bksp,grp:alt_shift_toggle'
    echo
    echo
}

[ ! -e /etc/hostname ] && {
    erro 'Missing /etc/hostname file'
    info 'hostnamectl set-hostname <hostname>'
    echo
    info 'And add the hostname into the /etc/hosts file'
    echo
    echo
}

[ ! -e /etc/localtime ] && {
    erro 'Missing /etc/localtime file'
    info 'ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime'
}

is_readable /etc/hostname
is_readable /etc/locale.conf
is_readable /var
is_readable /var/lib
is_readable /var/lib/pacman/local/ALPM_DB_VERSION
is_readable /var/log
