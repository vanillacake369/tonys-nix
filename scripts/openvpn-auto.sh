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
spawn openvpn --config $ovpn_config

expect {
    -re "(?i)enter.*private.*key.*password.*:" {
        # Turn off local echo, send the password, restore echo
        stty -echo
        send -- "$vpn_password\r"
        stty echo
        exp_continue          ;# keep listening in case the prompt reappears
    }
    timeout {
        puts stderr "❌ Timed out waiting for the password prompt"
        exit 1
    }
    eof {
        puts stderr "❌ openvpn exited unexpectedly"
        exit 1
    }
}

# Keep the user attached to the OpenVPN session
interact
