local wezterm = require("wezterm")
local config = wezterm.config_builder()

----------------------------------------------------------------
-- 폰트 및 렌더링
----------------------------------------------------------------
-- font_with_fallback을 하나로 합쳐 무시되는 설정을 방지
config.font = wezterm.font_with_fallback({
    "JetBrains Mono",
    "Roboto",
})
config.font_size = 10
-- 가장 빠르고 검증된 Harfbuzz 셰이퍼 사용 (기본값이지만 명시)
config.font_shaper = "Harfbuzz"

----------------------------------------------------------------
-- 디스플레이 최적화
----------------------------------------------------------------
-- 타이틀 바를 숨겨서 tty/pty 공간 확보
config.window_decorations = "RESIZE"
-- 탭 바를 극도로 단순화하여 tty/pty 공간 확보
config.hide_tab_bar_if_only_one_tab = true
-- 클래식 디자인 탭 바를 사용하여 tty/pty 공간 확보
config.enable_tab_bar = false
-- 창 내부 여백을 0으로 만들어 tty/pty 공간 확보
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}

----------------------------------------------------------------
-- GPU 최적화
----------------------------------------------------------------
-- 없는 글자(글리프)를 찾기 위해 시스템 전체를 뒤지는 낭비를 줄입니다.
config.warn_about_missing_glyphs = false
-- 최신 웹GPU(WebGpu) 그래픽 API를 강제하여 프레임 드랍을 막습니다.
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
-- 모니터 주사율(Hz)에 맞춰 최대 프레임을 제한해 GPU 과열을 방지
-- (144Hz 모니터라면 144로 변경 가능, 기본 대개 60~120)
config.max_fps = 120
-- 커서가 깜빡일 때 부드럽게 감속하는 계산을 꺼서 CPU 최적화
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.cursor_blink_rate = 0

return config
