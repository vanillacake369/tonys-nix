# NOTE:
#   Fish는 completion 파일을 전역 경로에서 로드하므로 파일 설치 위치만으로는
#   저장소 범위를 만들 수 없다. 대신 Git root의 구조적 marker를 확인해
#   tonys-nix 후보는 이 저장소 안에서만 활성화하고, 밖에서는 Just native
#   dynamic completion으로 되돌린다.
function __tonys_nix_just_context
    set -l root (git rev-parse --show-toplevel 2>/dev/null); or return 1
    test -f "$root/flake.nix"; and \
        test -f "$root/justfile"; and \
        test -f "$root/lib/collect-user-profiles.nix"; and \
        test -d "$root/user"
end

function __tonys_nix_just_at -a position
    test (count (commandline -opc)) -eq "$position"
end

function __tonys_nix_profiles
    set -l root (git rev-parse --show-toplevel 2>/dev/null); or return 1
    for profile_file in $root/user/*.nix
        set -l profile (string replace -r '^.*/(.*)\.nix$' '$1' "$profile_file")
        printf '%s\tHome Manager profile\n' "$profile"
    end
end

function __tonys_nix_commands
    printf '%s\t%s\n' \
        apply 'Apply system and Home Manager configuration' \
        check 'Run repository quality gates' \
        image 'Build or inspect image outputs' \
        maintenance 'Run garbage collection or health checks' \
        setup 'Set up machine integrations' \
        sync 'Synchronize managed applications'
end

function __tonys_nix_apply_actions
    printf '%s\t%s\n' \
        all 'Apply system and Home Manager configuration' \
        home 'Apply Home Manager configuration only' \
        system 'Apply NixOS system configuration only'
end

function __tonys_nix_sync_domains
    printf '%s\t%s\n' \
        brew 'Manage the shared Brewfile' \
        raycast 'Show Raycast GUI migration guides'
end

function __tonys_nix_brew_actions
    printf '%s\t%s\n' \
        check 'Check target against the shared Brewfile' \
        export 'Export target packages to a candidate Brewfile' \
        import 'Install the shared Brewfile on the target'
end

function __tonys_nix_raycast_actions
    printf '%s\t%s\n' \
        guide 'Show the Raycast migration overview' \
        export 'Show the GUI export procedure' \
        import 'Show the GUI import procedure' \
        verify 'Show the manual verification checklist'
end

function __tonys_nix_setup_actions
    printf '%s\t%s\n' \
        all 'Run the complete first-time setup' \
        nix 'Install Nix and link nix.conf' \
        home 'Prepare and apply Home Manager' \
        agents 'Authenticate configured AI providers' \
        mac 'Configure local macOS integrations' \
        completions 'Install only the Fish completion file'
end

function __tonys_nix_check_actions
    printf '%s\t%s\n' \
        all 'Run lint, hook, and flake checks' \
        core 'Prepare bootstrap runtime and run fast apply-gating checks' \
        flake 'Build every flake check for this system' \
        hooks 'Run Bats hook tests' \
        lint 'Run deadnix, statix, and alejandra'
end

function __tonys_nix_maintenance_domains
    printf '%s\t%s\n' \
        gc 'Manage Nix garbage collection' \
        health 'Run the Nix environment health check'
end

function __tonys_nix_gc_actions
    printf '%s\t%s\n' \
        auto 'Collect garbage only when thresholds require it' \
        force 'Collect garbage immediately' \
        status 'Show garbage-collection state'
end

function __tonys_nix_image_actions
    printf '%s\t%s\n' \
        list 'List supported image formats' \
        build 'Build one image for the current architecture' \
        build-arch 'Build one image for an explicit architecture' \
        build-all 'Build every supported image format' \
        show 'Show local image build artifacts'
end

# Outside this repository, preserve Just's native dynamic completion. Inside it,
# provide an exact command grammar so native option/file candidates cannot bury
# domain-specific subcommands.
complete -c just -n 'not __tonys_nix_just_context' --keep-order --exclusive \
    -a '(JUST_COMPLETE=fish just -- (commandline --current-process --tokenize --cut-at-cursor) (commandline --current-token))'

complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 1' -a '(__tonys_nix_commands)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 2; and __fish_seen_subcommand_from apply' -a '(__tonys_nix_apply_actions)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 3; and __fish_seen_subcommand_from apply home all' -a '(__tonys_nix_profiles)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 2; and __fish_seen_subcommand_from sync' -a '(__tonys_nix_sync_domains)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 3; and __fish_seen_subcommand_from brew' -a '(__tonys_nix_brew_actions)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 3; and __fish_seen_subcommand_from raycast' -a '(__tonys_nix_raycast_actions)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 2; and __fish_seen_subcommand_from setup' -a '(__tonys_nix_setup_actions)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 2; and __fish_seen_subcommand_from check' -a '(__tonys_nix_check_actions)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 2; and __fish_seen_subcommand_from maintenance' -a '(__tonys_nix_maintenance_domains)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 3; and __fish_seen_subcommand_from gc' -a '(__tonys_nix_gc_actions)'
complete -c just -f -n '__tonys_nix_just_context; and __tonys_nix_just_at 2; and __fish_seen_subcommand_from image' -a '(__tonys_nix_image_actions)'
