#!/bin/bash

set -e

get_ca_cert_path() {
    local ca_cert_path

    while true; do
        read -rp "Enter the full path to your CA certificate file for MITM: " ca_cert_path

        if [ -f "$ca_cert_path" ]; then
            echo "[+] Using CA certificate: $ca_cert_path"
            break
        else
            echo "[!] File not found. Please enter a valid path."
        fi
    done

    # Export or return the value if needed
    CA_CERT_PATH="$ca_cert_path"
}

main( ) {
    waydroid first-launch &

    cd waydroid_script
    sudo venv/bin/python3 main.py install gapps libhoudini
    touch .gapps

    get_ca_cert_path
    sudo venv/bin/python3 main.py install mitm --ca-cert $CA_CERT_PATH

    adb shell settings put global http_proxy "192.168.240.1:8080"
}

main