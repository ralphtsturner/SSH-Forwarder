#!/bin/bash

# Ask for SSH credentials
read -p "Enter the remote SSH username (default: root): " SSH_USER
SSH_USER=${SSH_USER:-root}

read -p "Enter the remote SSH server (e.g., jmcnetwork.net): " SSH_HOST

# Choose forwarding type
echo "Select forwarding type:"
echo "1) Local Forwarding (-L)  [Forward a local port to remote machine]"
echo "2) Remote Forwarding (-R) [Forward a remote port to a local machine] (Default)"
echo "3) Dynamic SOCKS Proxy (-D) [Create a dynamic SOCKS proxy]"
read -p "Enter choice (1-3, default: 2): " FORWARD_TYPE
FORWARD_TYPE=${FORWARD_TYPE:-2}

# Convert input to SSH flag
case "$FORWARD_TYPE" in
    1) SSH_FLAG="-L" ;;
    2) SSH_FLAG="-R" ;;
    3) SSH_FLAG="-D" ;;
    *) echo "Invalid choice, defaulting to Remote Forwarding (-R)"; SSH_FLAG="-R" ;;
esac

# If Dynamic SOCKS Proxy is chosen, skip port selection
if [[ "$SSH_FLAG" == "-D" ]]; then
    read -p "Enter the SOCKS proxy port (default: 1080): " SOCKS_PORT
    SOCKS_PORT=${SOCKS_PORT:-1080}
    SSH_CMD="ssh -N -D $SOCKS_PORT $SSH_USER@$SSH_HOST"
    echo "Executing: $SSH_CMD"
    eval $SSH_CMD
    exit 0
fi

# Default values for local and remote IP
read -p "Enter the LOCAL machine IP (default: 192.168.1.196): " LOCAL_IP
LOCAL_IP=${LOCAL_IP:-192.168.1.196}

read -p "Enter the REMOTE bind IP (default: 0.0.0.0): " REMOTE_IP
REMOTE_IP=${REMOTE_IP:-0.0.0.0}

# Ask for ports (comma-separated)
read -p "Enter the LOCAL ports to forward (comma-separated, e.g., 25565,25575): " PORTS

# Ask if ports should be forwarded to different remote ports
read -p "Do you want to forward ports to different remote ports? (y/n, default: n): " CHANGE_PORTS
CHANGE_PORTS=${CHANGE_PORTS:-n}

# Ask for TCP or UDP
read -p "Use TCP or UDP? (tcp/udp, default: tcp): " PROTOCOL
PROTOCOL=${PROTOCOL:-tcp}

# Initialize the SSH command
SSH_CMD="ssh "

# Process each port
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
for LOCAL_PORT in "${PORT_ARRAY[@]}"; do
    LOCAL_PORT=$(echo "$LOCAL_PORT" | tr -d ' ') # Trim spaces

    # If user wants to forward to a different port, ask for remote port
    if [[ "$CHANGE_PORTS" == "y" ]]; then
        read -p "Enter the REMOTE port for local port $LOCAL_PORT (default: same as local): " REMOTE_PORT
        REMOTE_PORT=${REMOTE_PORT:-$LOCAL_PORT}
    else
        REMOTE_PORT=$LOCAL_PORT
    fi

    # Append the port forwarding rule
    if [[ "$PROTOCOL" == "tcp" ]]; then
        SSH_CMD+="$SSH_FLAG $REMOTE_IP:$REMOTE_PORT:$LOCAL_IP:$LOCAL_PORT "
    elif [[ "$PROTOCOL" == "udp" ]]; then
        SSH_CMD+="$SSH_FLAG $REMOTE_IP:$REMOTE_PORT:$LOCAL_IP:$LOCAL_PORT/udp "
    else
        echo "Invalid protocol! Skipping this entry..."
    fi
done

# Add SSH destination
SSH_CMD+="$SSH_USER@$SSH_HOST"

# Display and execute the command
echo "Executing: $SSH_CMD"
eval $SSH_CMD
