#!/bin/bash

set -e

add_waydroid_repo() {
    if [ -e /etc/os-release ]; then
        OS_RELEASE=/etc/os-release
    elif [ -e /usr/lib/os-release ]; then
        OS_RELEASE=/usr/lib/os-release
    fi

    UPSTREAM_CODENAME=$(grep "^UBUNTU_CODENAME=" ${OS_RELEASE} | cut -d'=' -f2)

    if [ -z "${UPSTREAM_CODENAME}" ]; then
        UPSTREAM_CODENAME=$(grep "^DEBIAN_CODENAME=" ${OS_RELEASE} | cut -d'=' -f2)
    fi

    if [ -z "${UPSTREAM_CODENAME}" ]; then
        UPSTREAM_CODENAME=$(grep "^VERSION_CODENAME=" ${OS_RELEASE} | cut -d'=' -f2)
    fi

    # Debian 12+
    if [ -z "${UPSTREAM_CODENAME}" ] && [ -e /etc/debian_version ]; then
        UPSTREAM_CODENAME=$(cut -d / -f 1 /etc/debian_version)
    fi

    if [ -z "${UPSTREAM_CODENAME}" ]; then
        echo "[!] Could not detect your distribution"
        exit 1
    fi

    if ! [[ "${UPSTREAM_CODENAME}" =~ ^(mantic|focal|jammy|kinetic|lunar|noble|oracular|plucky|bookworm|bullseye|trixie|sid)$ ]]; then
        echo "[!] Distribution \"${UPSTREAM_CODENAME}\" is not supported"
        exit 1
    fi

    curl --progress-bar --proto '=https' --tlsv1.2 -Sf https://repo.waydro.id/waydroid.gpg --output /usr/share/keyrings/waydroid.gpg
    echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ ${UPSTREAM_CODENAME} main" | tee /etc/apt/sources.list.d/waydroid.list

    apt update
}

install_required() {
    apt install waydroid -y
    apt install git -y
    apt install python3-venv -y

    snap install code --classic
    snap install zaproxy --classic
}

install_waydroid_script() {
    if [ ! -d "waydroid_script" ] ; then
        git clone https://github.com/casualsnek/waydroid_script
    fi
    cd waydroid_script
    python3 -m venv venv
    venv/bin/pip install -r requirements.txt
}

main() {
    apt install curl

    add_waydroid_repo
    install_required
    install_waydroid_script
}

main