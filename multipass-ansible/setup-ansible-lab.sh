#!/bin/bash
# Ansible Lab Setup Script for Multipass
# This script creates a complete Ansible test environment with:
# - 1 control node (with Ansible installed)
# - 2 managed nodes (node1, node2)
# - Automatic SSH key configuration

set -e  # Exit on any error

# Configuration
CONTROL_NODE="controlnode"
MANAGED_NODES=("managed-node1" "managed-node2")
CPU=2
MEMORY="2G"
DISK="10G"
UBUNTU_VERSION="22.04"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if multipass is installed
check_multipass() {
    if ! command -v multipass &> /dev/null; then
        log_error "Multipass is not installed!"
        log_info "Please install from: https://multipass.run/install"
        exit 1
    fi
    log_success "Multipass is installed"
}

# Clean up existing instances
cleanup_existing() {
    log_info "Checking for existing instances..."

    for node in "$CONTROL_NODE" "${MANAGED_NODES[@]}"; do
        if multipass list | grep -q "^$node"; then
            log_warning "Found existing instance: $node"
            read -p "Delete $node? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "Deleting $node..."
                multipass delete "$node"
                multipass purge
                log_success "$node deleted"
            else
                log_error "Cannot proceed with existing instance. Exiting."
                exit 1
            fi
        fi
    done
}

# Launch control node
launch_controlnode() {
    log_info "Launching Ansible control node..."

    multipass launch "$UBUNTU_VERSION" \
        --name "$CONTROL_NODE" \
        --cpus "$CPU" \
        --memory "$MEMORY" \
        --disk "$DISK" \
        --cloud-init controlnode/cloud-config.yaml

    log_success "Control node launched"
}

# Wait for control node to be ready and get SSH public key
get_ssh_public_key() {
    log_info "Waiting for control node to generate SSH key..."

    # Wait for cloud-init to complete (up to 2 minutes)
    local max_attempts=24
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if multipass exec "$CONTROL_NODE" -- sudo test -f /home/ubuntu/.ssh/id_rsa.pub 2>/dev/null; then
            log_success "SSH key generated"
            break
        fi
        sleep 5
        ((attempt++))
        log_info "Waiting for SSH key generation... ($attempt/$max_attempts)"
    done

    if [ $attempt -eq $max_attempts ]; then
        log_error "Timeout waiting for SSH key generation"
        exit 1
    fi

    # Get the SSH public key
    SSH_PUBLIC_KEY=$(multipass exec "$CONTROL_NODE" -- sudo cat /home/ubuntu/.ssh/id_rsa.pub)

    if [ -z "$SSH_PUBLIC_KEY" ]; then
        log_error "Failed to retrieve SSH public key"
        exit 1
    fi

    log_success "Retrieved SSH public key from control node"
}

# Launch managed nodes with SSH key
launch_managed_nodes() {
    log_info "Launching managed nodes with SSH key configuration..."

    for node in "${MANAGED_NODES[@]}"; do
        log_info "Creating cloud-init for $node..."

        # Create node-specific cloud-init file from template
        local node_config="/tmp/${node}-cloud-config.yaml"
        sed -e "s/{NODE_NAME}/$node/g" \
            -e "s|{SSH_PUBLIC_KEY}|$SSH_PUBLIC_KEY|g" \
            nodes/node-template.yaml > "$node_config"

        log_info "Launching $node..."
        multipass launch "$UBUNTU_VERSION" \
            --name "$node" \
            --cpus "$CPU" \
            --memory "$MEMORY" \
            --disk "$DISK" \
            --cloud-init "$node_config"

        # Clean up temp file
        rm -f "$node_config"

        log_success "$node launched"
    done
}

# Create Ansible inventory file
create_inventory() {
    log_info "Creating Ansible inventory file..."

    # Get IP addresses
    local node1_ip=$(multipass info managed-node1 | grep IPv4 | awk '{print $2}')
    local node2_ip=$(multipass info managed-node2 | grep IPv4 | awk '{print $2}')

    # Write inventory file directly to control node
    multipass exec "$CONTROL_NODE" -- sudo -u ubuntu bash -c "cat > /home/ubuntu/ansible-lab/inventory" <<EOF
[webservers]
managed-node1 ansible_host=$node1_ip
managed-node2 ansible_host=$node2_ip

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
EOF

    log_success "Ansible inventory created"
}

# Display connection information
show_connection_info() {
    log_success "Ansible Lab Setup Complete!"
    echo ""
    echo "=========================================="
    echo "Ansible Lab Environment"
    echo "=========================================="
    echo ""

    # Show all instances
    multipass list
    echo ""

    echo "To get started:"
    echo "  1. Connect to control node:"
    echo "     ${GREEN}multipass shell $CONTROL_NODE${NC}"
    echo ""
    echo "  2. Test connectivity:"
    echo "     ${GREEN}ansible all -m ping${NC}"
    echo ""
    echo "  3. Run your first playbook:"
    echo "     ${GREEN}ansible-playbook your-playbook.yml${NC}"
    echo ""
    echo "Useful commands:"
    echo "  • View connection info: ${GREEN}./show-connection-info.sh${NC}"
    echo "  • Check inventory: ${GREEN}cat ~/ansible-lab/inventory${NC}"
    echo "  • Test SSH to nodes: ${GREEN}ssh <node-ip>${NC}"
    echo ""
    echo "Managed Nodes:"
    for node in "${MANAGED_NODES[@]}"; do
        local ip=$(multipass info "$node" | grep IPv4 | awk '{print $2}')
        echo "  • $node: $ip"
    done
    echo ""
    echo "=========================================="
    echo ""
    log_info "Using default 'ubuntu' user for all nodes"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "=========================================="
    echo "Ansible Lab Setup for Multipass"
    echo "=========================================="
    echo ""

    # Step 1: Check prerequisites
    check_multipass

    # Step 2: Cleanup
    cleanup_existing

    # Step 3: Launch control node
    launch_controlnode

    # Step 4: Get SSH public key
    get_ssh_public_key

    # Step 5: Launch managed nodes
    launch_managed_nodes

    # Step 6: Wait for all nodes to be ready
    log_info "Waiting for all nodes to complete initialization..."
    sleep 30

    # Step 7: Create inventory
    create_inventory

    # Step 8: Show connection info
    show_connection_info
}

# Run main function
main "$@"
