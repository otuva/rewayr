#!/bin/bash

set -e

add_waydroid_repo() {
    if [ -e /etc/os-release ]; then
        local OS_RELEASE=/etc/os-release
    elif [ -e /usr/lib/os-release ]; then
        local OS_RELEASE=/usr/lib/os-release
    fi

    local UPSTREAM_CODENAME=$(grep "^UBUNTU_CODENAME=" ${OS_RELEASE} | cut -d'=' -f2)

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

    if [ ! -f /usr/share/keyrings/waydroid.gpg ]; then
        echo "[*] Adding Waydroid GPG key..."
        curl --progress-bar --proto '=https' --tlsv1.2 -Sf https://repo.waydro.id/waydroid.gpg --output /usr/share/keyrings/waydroid.gpg
    fi

    if ! grep -q "repo.waydro.id" /etc/apt/sources.list.d/waydroid.list 2>/dev/null; then
        echo "[*] Adding Waydroid APT repository..."
        echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ ${UPSTREAM_CODENAME} main" | tee /etc/apt/sources.list.d/waydroid.list
        apt update
    fi
}

install_required() {
    apt install -y waydroid 
    apt install -y git
    apt install -y python3-venv
    apt install -y pipx
    apt install -y adb
    apt install -y lzip
    apt install -y openjdk-17-jdk

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

install_scrcpy() {
    if command -v scrcpy >/dev/null 2>&1; then
        echo "[+] scrcpy is already installed at $(command -v scrcpy)"
        return
    fi

    local url="https://github.com/Genymobile/scrcpy/releases/download/v3.2/scrcpy-linux-x86_64-v3.2.tar.gz"
    local extract_dir="scrcpy-linux-x86_64-v3.2"
    local archive="${extract_dir}.tar.gz"
    local expected_hash="df6cf000447428fcde322022848d655ff0211d98688d0f17cbbf21be9c1272be"
    

    echo "[*] Downloading $archive..."
    curl -L -o "$archive" "$url"

    echo "[*] Verifying SHA-256 hash..."
    local downloaded_hash
    downloaded_hash=$(sha256sum "$archive" | awk '{print $1}')

    if [ "$downloaded_hash" != "$expected_hash" ]; then
        echo "[!] Hash mismatch!"
        echo "Expected: $expected_hash"
        echo "Got     : $downloaded_hash"
        rm "$archive"
        exit 1
    fi

    echo "[+] Hash verified."

    echo "[*] Extracting $archive..."
    tar -xf "$archive"

    echo "[*] Installing scrcpy to /usr/bin/..."
    install "$extract_dir/scrcpy" /usr/bin/scrcpy

    echo "[*] Cleaning up..."
    rm -rf "$archive" "$extract_dir"

    echo "[+] scrcpy installed successfully at /usr/bin/scrcpy"
}

install_vscode_ext() {
    local target_user=${SUDO_USER:-$USER}

    sudo -u "$target_user" code --install-extension LoyieKing.smalise
    sudo -u "$target_user" code --install-extension Surendrajat.apklab
}

install_quarkengine() {
    local target_user=${SUDO_USER:-$USER}

    sudo -u "$target_user" pipx ensurepath
    sudo -u "$target_user" pipx install quark-engine
}

main() {
    if [ "$EUID" -ne 0 ]; then
        echo "[!] This script must be run as root. Might want to run with sudo"
        exit 1
    fi

    apt update
    apt install -y curl

    add_waydroid_repo
    install_required
    install_waydroid_script
    install_scrcpy
    install_vscode_ext
    install_quarkengine

    waydroid init
}

main
