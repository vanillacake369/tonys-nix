#!/usr/bin/env -S expect -f
# ↑ portable shebang (lets env resolve the expect in PATH/Nix profile)

#---------- configuration -------------------------------------------------
set timeout -1                 ;# keep the session alive indefinitely

#---------- environment validation ----------------------------------------
# Validate required environment variables
foreach var {AQUANURI_BASTION_URL AQUANURI_BASTION_PW AQUANURI_BASTION_PORT AQUANURI_LOCAL_PORT AQUANURI_TARGET_URL} {
    if {![info exists env($var)]} {
        puts stderr "❌ Required environment variable $var is not set"
        exit 1
    }
}

set bastionUrl         $env(AQUANURI_BASTION_URL)
set bastionPw          $env(AQUANURI_BASTION_PW)
set bastionPort        $env(AQUANURI_BASTION_PORT)
set bastionLocalPort   $env(AQUANURI_LOCAL_PORT)
set targetUrl          $env(AQUANURI_TARGET_URL)

# Optionally scrub the password variable from this process's env so children can't inherit it
unset env(AQUANURI_BASTION_PW)

#---------- spawn & login -------------------------------------------------
log_user 1
puts "DEBUG: About to spawn SSH with password: [string range $bastionPw 0 2]***"
spawn ssh -L $bastionLocalPort:$bastionUrl:$bastionPort ubuntu@$targetUrl -N

expect {
    -re "(?i).*Password.*:" {
        puts "DEBUG: Password prompt detected, sending password..."
        # Turn off local echo, send the password, restore echo
        stty -echo
        send -- "$bastionPw\r"
        stty echo
        exp_continue          ;# keep listening in case the prompt reappears
    }
    -re "(?i).*authenticity.*host.*yes/no.*" {
        send -- "yes\r"
        exp_continue
    }
    timeout {
        puts stderr "❌ Timed out waiting for the password prompt"
        exit 1
    }
    eof {
        puts stderr "❌ ssh exited unexpectedly"
        exit 1
    }
}

# Keep the user attached to the SSH session
interact
