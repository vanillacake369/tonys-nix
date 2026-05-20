# 🛠 Senior DevOps Analysis: tonys-nix

본 문서는 `tonys-nix` 레포지토리의 아키텍처를 분석하고, 시스템의 안정성과 확장성을 높이기 위한 개선 방향을 우선순위에 따라 제안합니다.

---

## 📊 현재 아키텍처 요약
- **멀티 플랫폼 대응**: 단일 Flake로 Darwin, NixOS, WSL을 통합 관리하는 고도의 추상화 달성.
- **모듈화**: 시스템(`nixos-modules`)과 사용자 환경(`modules`)의 역할 분리가 명확함.
- **기능 중심 구성**: 쉘 도구 및 LLM 에이전트 설정을 도메인별 모듈로 관리하여 가독성이 높음.

---

## 🚀 개선 로드맵 (우선순위 순)

### 🔴 P0: 시스템 무결성 및 보안 (System Integrity & Security)

#### 1. 하드웨어 설정의 Flake 내재화 (Reproducibility)
- **현상**: `configuration.nix`에서 Flake 외부에 존재하는 `/etc/nixos/hardware-configuration.nix`를 참조함.
- **리스크**: 새로운 장비에서 빌드 시 해당 파일이 없으면 실패하며, 장비별 하드웨어 이력이 추적되지 않음.
- **개선안**:
    - `hosts/` 디렉토리를 생성하고 장비명(hostname)별로 하드웨어 설정을 레포지토리에 포함.
    - `flake.nix`의 `nixosConfigurations`에서 각 장비에 맞는 하드웨어 모듈을 매핑.

#### 2. 시크릿 관리 솔루션 도입 (Security)
- **현상**: API Key, 자격 증명 등 민감 정보 관리에 대한 명시적 체계가 부족함.
- **리스크**: 실수로 시크릿이 Git에 커밋되거나, 환경별로 시크릿을 수동 배포해야 하는 번거로움 발생.
- **개선안**:
    - `sops-nix` 또는 `agenix` 도입.
    - 암호화된 시크릿 파일을 Git에 포함시키고, 런타임에 Nix가 안전하게 복호화하여 주입하도록 구성.

---

### 🟡 P1: 구조적 유연성 (Structural Flexibility)

#### 3. 사용자 정보의 일반화 (Scalability)
- **현상**: `limjihoon-user.nix`와 같이 특정 사용자명이 하드코딩된 모듈 존재.
- **리스크**: 다른 계정명 사용이나 다중 사용자 환경 대응 시 코드 중복 발생.
- **개선안**:
    - `modules/user.nix`로 일반화하고, `username`, `homeDirectory` 등을 인자(Args)로 전달받는 구조로 변경.

#### 4. 동적 Dotfile 템플릿 처리 (Flexibility)
- **현상**: `home.file`이 정적 파일을 그대로 심볼릭 링크함.
- **리스크**: 특정 OS나 하드웨어 특성(모니터 해상도, 테마 등)에 따른 설정값 분기가 어려움.
- **개선안**:
    - 설정 파일 내용을 Nix 문자열(`text = ''...'';`)로 관리하거나 `lib.template`을 활용하여 환경 변수에 따라 동적으로 파일 생성.

---

### 🟢 P2: 운영 효율화 (Operational Excellence)

#### 5. CI/CD 파이프라인 구축 (Validation)
- **현상**: 변경 사항이 각 플랫폼(Darwin/NixOS/WSL)에서 정상 빌드되는지 수동으로 확인해야 함.
- **리스크**: 한쪽 플랫폼의 수정이 다른 플랫폼의 빌드 에러를 유발하는 회귀(Regression) 발생.
- **개선안**:
    - GitHub Actions 도입.
    - `nix flake check` 및 각 `nixosConfigurations`, `darwinConfigurations`의 dry-run 빌드 자동화.

#### 6. Garbage Collection 및 최적화 전략 (Maintenance)
- **현상**: 장기 사용 시 `/nix/store` 비대화에 대한 관리 자동화 부족.
- **개선안**:
    - `nix.settings.auto-optimise-store = true;` 설정 및 주기적인 `nix-collect-garbage` 수행을 위한 시스템 서비스 유닛 등록.

---

## 📅 실행 우선순위 가이드

1. **Step 1 (Immediate)**: `sops-nix` 도입을 통한 보안 확보.
2. **Step 2 (Reproducibility)**: 하드웨어 설정을 `hosts/`로 이동하여 완전한 재현성 달성.
3. **Step 3 (Scalability)**: 사용자 모듈 일반화 및 CI 연동.

---
*작성자: Senior DevOps Engineer (Gemini CLI)*
