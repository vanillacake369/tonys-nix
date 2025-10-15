# 1) 타입 소스 보관
$typeSrc = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {
    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public uint dwTime; // CRITICAL FIX: Changed from 'int' to 'uint'
        }

        public static DateTime LastInput {
            get {
                // TickCount는 음수로 래핑될 수 있으므로 & int.MaxValue로 안전 처리
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-((long)Environment.TickCount & int.MaxValue));
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static uint LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

# 2) 타입 존재 여부 확인 후 없으면 Add-Type
$typeName = 'PInvoke.Win32.UserInput'
if (-not ([System.Management.Automation.PSTypeName]$typeName).Type) {
    Add-Type -TypeDefinition $typeSrc -Language CSharp
}

# 로그 파일 설정 - SYSTEM 계정에서도 접근 가능한 위치 사용
$LogFile = "$env:USERPROFILE\idle_shutdown_monitor.log"

# 로그 함수 정의
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# 대기 상태 타이머 임계값
$ShutdownIdle = 4
$ShutdownIdleTimeThreshold = New-TimeSpan -Hours $ShutdownIdle

# 모니터링 인터벌
$CheckIntervalSeconds = 360

Write-Log "--- 유휴 시간 모니터링 시작 (확인 주기: $($CheckIntervalSeconds)초, 임계값: $($ShutdownIdle)초) ---"

while ($true) {
    # 1. 현재 유휴 시간을 계산합니다. (MUST be inside the loop for continuous updates)
    $isOverIdleTime = [PInvoke.Win32.UserInput]::IdleTime

    # 2. 현재 시간과 유휴 시간을 로그에 기록합니다.
    Write-Log "현재 Windows 유휴 시간: $($isOverIdleTime.ToString('hh\:mm\:ss'))"

    # 3. 유휴 시간 임계값(4초)을 초과했는지 확인합니다.
    if ($isOverIdleTime -ge $ShutdownIdleTimeThreshold) {
        Write-Log "🚨 경고: 임계값 충족! 시스템이 $($isOverIdleTime.TotalSeconds)초 동안 유휴 상태였습니다. 종료를 시도합니다."
        $shutDownTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Log "종료 시각 : $($shutDownTime)"
        Write-Log "=========================================="

        # 실제 종료 명령
        shutdown.exe -s -f

        # 종료 명령을 실행한 후에는 루프를 빠져나갑니다.
        break

    } else {
        # 4. 다음 확인까지 지정된 시간 동안 대기합니다.
        Start-Sleep -Seconds $CheckIntervalSeconds
    }

}
