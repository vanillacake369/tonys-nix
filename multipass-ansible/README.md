# Multipass Ansible Lab Environment

A fully automated, reproducible Ansible test environment using Multipass and cloud-init. This configuration creates a complete lab with one control node and two managed nodes, all pre-configured with SSH keys and ready for Ansible automation.

## Features

- **Fully Automated Setup**: Single script creates entire environment
- **Reproducible Configuration**: Cloud-init ensures identical setup every time
- **Pre-configured SSH**: Automatic SSH key generation and distribution
- **Ready-to-Use Ansible**: Control node comes with Ansible pre-installed
- **Multi-Platform**: Works on Linux, macOS, and Windows with Multipass

## Architecture

```
┌─────────────────────────────────────────┐
│         Ansible Control Node           │
│  - Hostname: controlnode                │
│  - Ansible pre-installed                │
│  - SSH key auto-generated               │
│  - User: ansible (sudo access)          │
└─────────────┬───────────────────────────┘
              │
              │ SSH (passwordless)
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼─────────┐   ┌─────▼───────┐
│    node1    │   │    node2    │
│             │   │             │
│ Managed     │   │ Managed     │
│ Node        │   │ Node        │
└─────────────┘   └─────────────┘
```

## Quick Start

### Prerequisites

1. **Install Multipass**: https://multipass.run/install
   - macOS: `brew install multipass`
   - Ubuntu: `sudo snap install multipass`
   - Windows: Download installer from website

2. **Verify Installation**:
   ```bash
   multipass version
   ```

### Automated Setup (Recommended)

Run the automated setup script:

```bash
cd multipass-ansible
./setup-ansible-lab.sh
```

This script will:
1. Check for Multipass installation
2. Clean up any existing instances (with confirmation)
3. Launch control node with Ansible
4. Generate SSH keys automatically
5. Launch managed nodes with SSH keys pre-configured
6. Create Ansible inventory file
7. Display connection information

**Total setup time**: ~3-5 minutes

### Manual Setup (Step-by-Step)

If you prefer manual control:

#### 1. Launch Control Node

```bash
multipass launch 22.04 \
    --name controlnode \
    --cpus 2 \
    --memory 2G \
    --disk 10G \
    --cloud-init controlnode/cloud-config.yaml
```

#### 2. Get SSH Public Key

Wait for cloud-init to complete (~1-2 minutes), then:

```bash
# Connect to control node
multipass shell controlnode

# Switch to ansible user
su - ansible  # password: ansible

# Display SSH public key
cat ~/.ssh/id_rsa.pub

# Or use the helper script
./show-connection-info.sh
```

Copy the SSH public key.

#### 3. Create Node Configurations

Create cloud-init files for each managed node by replacing placeholders in `nodes/node-template.yaml`:

```bash
# For node1
sed -e 's/{NODE_NAME}/node1/g' \
    -e "s|{SSH_PUBLIC_KEY}|$(cat /path/to/public/key)|g" \
    nodes/node-template.yaml > /tmp/node1-config.yaml

# For node2
sed -e 's/{NODE_NAME}/node2/g' \
    -e "s|{SSH_PUBLIC_KEY}|$(cat /path/to/public/key)|g" \
    nodes/node-template.yaml > /tmp/node2-config.yaml
```

#### 4. Launch Managed Nodes

```bash
# Launch node1
multipass launch 22.04 \
    --name node1 \
    --cpus 2 \
    --memory 2G \
    --disk 10G \
    --cloud-init /tmp/node1-config.yaml

# Launch node2
multipass launch 22.04 \
    --name node2 \
    --cpus 2 \
    --memory 2G \
    --disk 10G \
    --cloud-init /tmp/node2-config.yaml
```

#### 5. Create Ansible Inventory

Get node IPs:
```bash
multipass list
```

Create inventory file on control node:
```bash
multipass shell controlnode
su - ansible
nano ~/ansible-lab/inventory
```

Add content:
```ini
[webservers]
node1 ansible_host=<node1-ip>
node2 ansible_host=<node2-ip>

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
```

## Usage

### Connect to Control Node

```bash
# Shell access
multipass shell controlnode

# Switch to ansible user
su - ansible  # password: ansible
```

### Test Ansible Connectivity

```bash
# Ping all nodes
ansible all -m ping

# Expected output:
# node1 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
# node2 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

### Run Ansible Commands

```bash
# Ad-hoc commands
ansible all -m shell -a "uname -a"
ansible webservers -m apt -a "name=nginx state=present" --become

# Playbook execution
ansible-playbook playbook.yml
```

### Example Playbook

Create a simple test playbook:

```yaml
# ~/ansible-lab/test-playbook.yml
---
- name: Test playbook
  hosts: all
  become: yes
  tasks:
    - name: Ensure nginx is installed
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: yes
```

Run it:
```bash
ansible-playbook ~/ansible-lab/test-playbook.yml
```

## Configuration Details

### Default Credentials

| Component | Username | Password | Notes |
|-----------|----------|----------|-------|
| Control Node | ansible | ansible | Change after first login |
| Node1 | ansible | ansible | Change after first login |
| Node2 | ansible | ansible | Change after first login |

**Security Note**: The default password is intentionally simple for lab use. Change it in production environments:
```bash
sudo passwd ansible
```

### Resource Allocation

Each VM is configured with:
- **CPUs**: 2 cores
- **Memory**: 2GB RAM
- **Disk**: 10GB storage
- **OS**: Ubuntu 22.04 LTS

Modify these in `setup-ansible-lab.sh` or in manual launch commands.

### Installed Packages

**Control Node**:
- ansible
- net-tools
- vim, git
- python3-pip
- sshpass

**Managed Nodes**:
- net-tools
- vim
- python3, python3-pip

## File Structure

```
multipass-ansible/
├── README.md                          # This file
├── setup-ansible-lab.sh              # Automated setup script
├── controlnode/
│   └── cloud-config.yaml             # Control node cloud-init
└── nodes/
    └── node-template.yaml            # Managed node template
```

## Helper Scripts

### Control Node: show-connection-info.sh

Located at `/home/ansible/show-connection-info.sh`

Displays:
- Hostname and IP address
- SSH public key
- Connection instructions
- Ansible inventory location

### Managed Nodes: show-node-info.sh

Located at `/home/ansible/show-node-info.sh`

Displays:
- Hostname and IP address
- User credentials
- SSH authorization status
- Python version

## Troubleshooting

### Cloud-init Not Completing

Check cloud-init status:
```bash
multipass exec controlnode -- cloud-init status --wait
```

View cloud-init logs:
```bash
multipass exec controlnode -- sudo cat /var/log/cloud-init-output.log
```

### SSH Key Not Generated

Manually generate on control node:
```bash
multipass shell controlnode
su - ansible
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### Ansible Ping Fails

1. **Verify SSH connectivity**:
   ```bash
   ssh <node-ip>
   ```

2. **Check inventory file**:
   ```bash
   cat ~/ansible-lab/inventory
   ansible-inventory --list
   ```

3. **Verify SSH key**:
   ```bash
   ssh-keyscan <node-ip> >> ~/.ssh/known_hosts
   ```

4. **Test with verbose output**:
   ```bash
   ansible all -m ping -vvv
   ```

### Node IP Changed After Restart

Update inventory file:
```bash
# Get new IPs
multipass list

# Update inventory
nano ~/ansible-lab/inventory
```

## Management Commands

### List All Instances

```bash
multipass list
```

### Stop/Start Instances

```bash
# Stop all
multipass stop controlnode node1 node2

# Start all
multipass start controlnode node1 node2

# Restart specific node
multipass restart node1
```

### View Instance Info

```bash
multipass info controlnode
multipass info node1
```

### Delete and Recreate

```bash
# Delete all instances
multipass delete controlnode node1 node2
multipass purge

# Recreate
./setup-ansible-lab.sh
```

### Shell Access to Nodes

```bash
# Control node
multipass shell controlnode

# Managed nodes
multipass shell node1
multipass shell node2
```

## Customization

### Add More Managed Nodes

1. Edit `setup-ansible-lab.sh`:
   ```bash
   MANAGED_NODES=("node1" "node2" "node3" "node4")
   ```

2. Re-run setup script

### Change Resource Allocation

Edit `setup-ansible-lab.sh`:
```bash
CPU=4
MEMORY="4G"
DISK="20G"
```

### Use Different Ubuntu Version

Edit `setup-ansible-lab.sh`:
```bash
UBUNTU_VERSION="24.04"  # Or any available LTS version
```

Check available versions:
```bash
multipass find
```

### Customize Ansible Configuration

Edit `controlnode/cloud-config.yaml` to add:
- Additional Ansible modules
- Custom roles
- Specific Ansible version
- Additional Python packages

## Advanced Usage

### Mount Local Directory

Share files between host and VMs:

```bash
# Mount current directory to control node
multipass mount $(pwd) controlnode:/host

# Unmount
multipass unmount controlnode
```

### Transfer Files

```bash
# Copy to instance
multipass transfer file.txt controlnode:/home/ansible/

# Copy from instance
multipass transfer controlnode:/home/ansible/output.txt ./
```

### Run Commands Remotely

```bash
# Execute command on control node
multipass exec controlnode -- ansible all -m ping

# As specific user
multipass exec controlnode -- sudo -u ansible ansible-playbook test.yml
```

## Best Practices

1. **Change Default Passwords**: Immediately after setup
2. **Use Version Control**: Store playbooks in git
3. **Test in Lab First**: Use this environment to test before production
4. **Regular Snapshots**: Use Multipass snapshots for backup
5. **Clean Shutdown**: Stop instances gracefully before host shutdown

## Integration with CI/CD

Use this environment in automated testing:

```bash
#!/bin/bash
# CI pipeline script

# Setup environment
./setup-ansible-lab.sh

# Run tests
multipass exec controlnode -- sudo -u ansible ansible-playbook tests/verify.yml

# Cleanup
multipass delete --purge controlnode node1 node2
```

## Performance Tips

- Allocate resources based on your workload
- Use SSD storage for faster I/O
- Increase memory for large inventories
- Consider using snapshots for quick reset

## Security Considerations

For production-like testing:

1. **Generate unique SSH keys** per environment
2. **Use Ansible Vault** for secrets
3. **Implement proper sudo** configuration
4. **Enable SSH key rotation**
5. **Use firewall rules** (ufw)

## Contributing

To share improvements to this configuration:

1. Fork the repository
2. Modify cloud-init files
3. Test with clean setup
4. Submit pull request

## Support

For issues:
- Multipass: https://github.com/canonical/multipass/issues
- Ansible: https://github.com/ansible/ansible/issues
- This config: Open issue in repository

## License

This configuration is provided as-is for educational and testing purposes.

## Resources

- [Multipass Documentation](https://multipass.run/docs)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)

---

**Happy Ansible Learning! 🚀**
