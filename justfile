set shell := ["bash", "-euo", "pipefail", "-c"]

OS_TYPE := `case "$(uname -s)" in
  Darwin) echo darwin ;;
  Linux)
    if [[ -d /etc/nixos ]]; then
      echo nixos
    elif grep -qiE '(Microsoft|WSL)' /proc/version 2>/dev/null; then
      echo wsl
    else
      echo linux
    fi
    ;;
  *) echo unsupported ;;
esac`
SYSTEM_ARCH := `case "$(uname -s):$(uname -m)" in
  Darwin:arm64) echo aarch64-darwin ;;
  Darwin:*) echo unsupported ;;
  Linux:aarch64) echo aarch64-linux ;;
  Linux:x86_64) echo x86_64-linux ;;
  Linux:amd64) echo x86_64-linux ;;
  *) echo unsupported ;;
esac`

import 'recipes/apply.just'
import 'recipes/setup.just'
import 'recipes/check.just'
import 'recipes/sync.just'
import 'recipes/maintenance.just'
import 'recipes/image.just'

# 기본 실행은 대상의 정적 검사를 마친 뒤 런타임 준비와 검사를 수행한다.
# 선행 recipe가 실패하면 적용을 시작하지 않는다.
[default]
default:
    just _preflight-default
    just check core
    just apply all
