#!/usr/bin/env -S expect -f
# ↑ portable shebang (lets env resolve the expect in PATH/Nix profile)

#---------- configuration -------------------------------------------------
set timeout -1                 ;# keep the session alive indefinitely

# Optional: allow "myscript myconfig.ovpn"
set ovpn_config [lindex $argv 0]
if {$ovpn_config eq ""} {
    set ovpn_config "lonelynight1026.ovpn"
}

#---------- secret handling ----------------------------------------------
if {![info exists env(HAMA_VPN_PW)]} {
    puts stderr "❌ Required environment variable HAMA_VPN_PW is not set"
    exit 1
}
set vpn_password $env(HAMA_VPN_PW)

# Optionally scrub the variable from this process's env so children can't inherit it
unset env(HAMA_VPN_PW)

#---------- spawn & login -------------------------------------------------
log_user 1
spawn sudo openvpn --config $ovpn_config

# Handle sudo password first
expect "Password:"
send_user "\nEnter your sudo password: "
stty -echo
expect_user -re "(.*)\n"
set sudo_password $expect_out(1,string)
send "$sudo_password\r"
stty echo

# Now wait for OpenVPN private key password
expect {
    "Enter Private Key Password:" {
        send -- "$vpn_password\r"
        exp_continue
    }
    "Initialization Sequence Completed" {
        send_user "\n✅ VPN Connected Successfully\n"
    }
    timeout {
        puts stderr "❌ Timed out waiting for connection"
        exit 1
    }
    eof {
        puts stderr "❌ openvpn exited unexpectedly"
        exit 1
    }
}

# Keep the user attached to the OpenVPN session
interact
