#!/home/limjihoon/.nix-profile/bin/expect -f
# Set a timeout (in seconds)
log_user 1
set timeout -1

# Replace with your actual password or read it from a secure source
set vpn_password "thisHAMA12!@"

# Start OpenVPN with your config file
spawn openvpn --config lonelynight1026.ovpn

# Wait for the prompt that asks for the private key password
expect "Enter Private Key Password:"
# Send the password followed by a newline character
send -- "$vpn_password\r"

# Interact allows you to maintain the connection interactively afterwards
interact
