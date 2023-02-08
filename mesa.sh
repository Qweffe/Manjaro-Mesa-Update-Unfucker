#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
clear=$(tput sgr0)

language() {
    czech=("Manjaro Mesa Aktualizace Spravovač -od Qwefe" "Aktuální verze" "Vlastní verze" "Konec" "Verze: " "Verze neexistuje" "Špatná možnost" "Smazat instalační soubory?" "Zmáčkněte cokoli pro ukončení" "Pro instalaci potřebujem root" "Jazyk" "je nainstalován" "není nainstalován" "Naistalovat chybějící závislosti" "Kontrola závislostí")
    english=("MANAJARO MESA UPDATE UNFUCKER -by Qwefe" "Current version" "Custom version" "Quit" "Version: " "Version doesn't exist" "Bad option" "Delete install files?" "Press anything to quit" "We need root for installation" "Language" "is installed" "isn't installed" "Install missing dependencies" "Dependencies check")
    case $loc in
        cs)
            #echo "česky"
            echo "${czech[$1]}"
            ;;
        *)
            #echo "english"
            echo "${english[$1]}"
            ;;
    esac
}
instalace () {
    wget "ftp://ftp.freedesktop.org/pub/mesa/mesa-$ver.tar.xz"
    tar -xf "mesa-$ver.tar.xz"
    cd mesa-$ver
    mkdir build
    cd build
    meson setup        --prefix=/        -D b_ndebug=true        -D b_lto=false        -D platforms=x11,wayland        -D gallium-drivers=r300,r600,radeonsi,nouveau,virgl,svga,swrast,i915,iris,crocus,zink,d3d12        -D vulkan-drivers=amd,intel,swrast,virtio-experimental,intel_hasvk        -D vulkan-layers=device-select,overlay        -D dri3=enabled        -D egl=enabled        -D gallium-extra-hud=true        -D gallium-nine=true        -D gallium-omx=bellagio        -D gallium-opencl=icd        -D gallium-va=enabled        -D gallium-vdpau=enabled        -D gallium-xa=enabled        -D gbm=enabled        -D gles1=disabled        -D gles2=enabled        -D glvnd=true        -D glx=dri        -D libunwind=enabled        -D llvm=enabled        -D lmsensors=enabled        -D osmesa=true        -D shared-glapi=enabled        -D microsoft-clc=disabled        -D valgrind=disabled        -D tools=[]        -D zstd=enabled        -D video-codecs=vc1dec,h264dec,h264enc,h265dec,h265enc        -D buildtype=plain        --wrap-mode=nofallback        -D sysconfdir=/etc
    echo "${magenta}$(language 9)${clear}"
    sudo ninja install
}
odejdi () {
    tput rmcup
    exit 0
}
leave () {
    trap SIGINT
    rm "mesa-$ver.tar.xz"
    rm -rv "mesa-$ver"
    odejdi
}
menu () {
    time=10
    input=""
    while [ $time -gt 0 ] && [ -z "$input" ]; do
        clear
        echo "${blue}$(language 0)${clear}"
        printf '%.s─' $(seq 1 $(tput cols))
        echo ""
        echo "1) $(language 1) [$time]"
        echo "2) $(language 2)"
        echo "j) $(language 10)"
        echo "q) $(language 3)"
        read -r -n 1 -t 1 input
        (( time-- ))
    done
    if [ $time -eq 0 ]; then input=1; fi
    ver=""
    case $input in
    1)
        clear
        ver=$(curl -s https://www.mesa3d.org/ | grep -A 3 'Current release:' | awk 'NR % 3 == 0')
        ver=$(sed -e 's/^[ \t]*//' -e 's/\ *$//g'<<<"${ver}")
        instalace
        ;;
    2)
        clear
        language 4
        read -r ver
        if curl --head --silent --fail "ftp://ftp.freedesktop.org/pub/mesa/mesa-$ver.tar.xz" 2> /dev/null; then
            instalace
        else
            echo "${red}$(language 5)${clear}"
            sleep 3
            menu
        fi
        ;;
    j)
        clear
        echo "${cyan}$(language 10)${clear}"
        printf '%.s─' $(seq 1 $(tput cols))
        echo "cs - czech"
        echo "en - english"
        echo ""
        read -r loc
        menu
        ;;
    q)
        odejdi
        ;;
    *)
        clear
        echo "${red}$(language 6)${clear}"
        sleep 0.5
        menu
        ;;
    esac
}
pkgchk () {
    chybi=0
    dep=("git" "python-mako" "xorgproto" "libxml2" "libx11"  "libvdpau" "libva" "elfutils" "libxrandr" "wayland-protocols" "meson" "ninja" "glslang" "directx-headers" "libclc" "wget" "curl" "gcc" "cmake" "llvm" "bison" "flex" "clang" "polly")
    clear
    echo "${cyan}$(language 14)${clear}"
    printf '%.s─' $(seq 1 $(tput cols))
    for package in "${dep[@]}"; do
    if pacman -Q | grep -q "^$package[ ]"; then
        echo "${green}$package $(language 11)${clear}"
    else
        echo "${red}$package $(language 12)${clear}"
        install+=("$package")
        chybi=1
    fi
    sleep 0.1
    done
    if [ "$chybi" = 1 ]; then
        echo ""
        echo "$(language 13) [y/n]"
        read -r yn
        if [ "$yn" = "y" ]; then
            echo "${magenta}$(language 9)${clear}"
            sudo pacman -Sy --noconfirm "${install[@]}"
            pkgchk
        else
            odejdi
        fi
    fi
}

trap "leave" INT
tput smcup
loc=$(locale | grep -o -P "LANG=.{0,2}" | cut -c6-7)
cesta=$(pwd)
pkgchk
menu
echo ""
echo "${red}$(language 7)${clear} [y/n]"
read -r smaz
if [ "$smaz" = "y" ] ; then
    cd $cesta
    sudo rm -rv "mesa-$ver"
    rm "mesa-$ver.tar.xz"
fi
echo ""
echo "${cyan}$(language 8)${clear}"
read -r -n 1
odejdi
