#!/bin/bash
# ============================================================
# AI Daily Report — 자동 생성 스크립트
# 실행 조건: 오전 9시 (LaunchAgent), 또는 수동 실행
# ============================================================

# ── 경로 설정 ──────────────────────────────────────────────
WORK_DIR="/Users/user/Desktop/Claude Works/AI_Daily_reports"
CLAUDE="/Users/user/.local/bin/claude"
LOG_DIR="$WORK_DIR/logs"
LOG_FILE="$LOG_DIR/report.log"
LOCK_FILE="$LOG_DIR/.last_run_date"

# PATH에 claude 경로 추가 (launchd는 shell profile을 로드하지 않음)
export PATH="/Users/user/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# ── 날짜 계산 ──────────────────────────────────────────────
TODAY=$(date +%Y-%m-%d)
REPORT_FILE="$WORK_DIR/${TODAY}_AI_Daily_Report.html"

# ── 로그 함수 ──────────────────────────────────────────────
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================"
log "AI Daily Report 스크립트 시작"
log "오늘 날짜: $TODAY"

# ── 중복 실행 방지 ─────────────────────────────────────────
# 오늘 날짜로 이미 실행됐는지 확인 (sleep 후 깨어났을 때 재실행 방지)
if [ -f "$LOCK_FILE" ] && [ "$(cat $LOCK_FILE)" = "$TODAY" ]; then
  log "오늘 리포트가 이미 생성됐습니다. 종료."
  exit 0
fi

# 리포트 HTML 파일이 이미 존재해도 스킵
if [ -f "$REPORT_FILE" ]; then
  log "리포트 파일이 이미 존재합니다: $REPORT_FILE"
  echo "$TODAY" > "$LOCK_FILE"
  exit 0
fi

# ── 9시 이후 실행 여부 확인 ────────────────────────────────
# Mac이 새벽에 켜진 경우 9시 이전엔 실행하지 않음
CURRENT_HOUR=$(date +%H)
CURRENT_MIN=$(date +%M)
CURRENT_TOTAL=$((CURRENT_HOUR * 60 + CURRENT_MIN))
TARGET_TOTAL=$((9 * 60))   # 09:00

if [ "$CURRENT_TOTAL" -lt "$TARGET_TOTAL" ]; then
  log "현재 시각 $(date '+%H:%M')은 실행 시각(09:00) 이전입니다. 종료."
  exit 0
fi

# ── Claude CLI 실행 ────────────────────────────────────────
log "Claude CLI 실행 시작..."

"$CLAUDE" \
  --allowedTools "Bash,Read,Write,Edit,Glob,Grep,WebSearch,WebFetch" \
  --model "claude-sonnet-4-6" \
  -p "
작업 폴더: /Users/user/Desktop/Claude Works/AI_Daily_reports

먼저 handoff.md 파일을 읽어 디자인 스펙과 파일 구조를 파악한 다음, 아래 순서대로 오늘의 AI Daily Report를 생성하고 GitHub에 푸시해줘.

[1] 오늘 날짜 확인
date +%Y-%m-%d 명령으로 오늘 날짜를 확인한다.

[2] 뉴스 수집
WebSearch로 최근 24시간 AI 뉴스를 6~8개 쿼리로 검색한다.
검색 카테고리: LLM 모델 업데이트, VLM 및 멀티모달, 이미지/영상 생성 AI, 기업 발표(OpenAI·Anthropic·Google·Meta·Microsoft·xAI), AI 연구 논문, AI 정책·규제

[3] og:image 수집
각 기사 URL에 WebFetch로 og:image URL을 수집한다. 실패(403·없음)시 null로 처리하고 thumb-placeholder를 사용한다.

[4] 리포트 HTML 생성
반드시 2026-04-16_AI_Daily_Report.html 파일의 CSS와 HTML 구조를 그대로 복사해서 사용한다. 날짜·콘텐츠만 교체한다.
절대 임의로 CSS를 변경하거나 다른 디자인을 적용하지 않는다.

필수 준수 항목 (2026-04-16 파일에서 그대로 복사):
- <style> 첫 번째 블록: :root 변수부터 @media 쿼리까지 동일하게
- font-family: -apple-system,BlinkMacSystemFont,'Segoe UI','Noto Sans KR',sans-serif (Pretendard 사용 금지)
- date-chip: background:var(--accent);color:#fff (연보라 배경 사용 금지)
- h1 gradient: linear-gradient(90deg,#4f46e5 0%,#6366f1 50%,#0891b2 100%) (135deg 사용 금지)
- ko-summary: 흰 배경 + border-left:4px solid var(--accent) + <ul> + ▶ bullet (gradient 배경·<ol> 사용 금지)
- section: class="section sec-llm" 등 sec-XXX 클래스 필수, section-header 안에 <div class="section-icon"> 필수
- cards-grid: repeat(auto-fill,minmax(290px,1fr)) (repeat(2,1fr) 사용 금지)
- card:hover: transform:translateY(-3px) 포함
- tag: border-radius:999px (6px 사용 금지)
- card-impact: padding-top:10px;border-top:1px solid var(--border) 구조
- footer: <div class="gen-time">와 <div class="sources"> 클래스 사용 (footer-date·footer-links 사용 금지)
- <script src="reports-list.js"></script> + 폰트 오버라이드 블록 + nav JS 포함
- nav JS 다음에 카드 제목 링크 JS 추가 (card-title 텍스트를 source-link URL로 연결):
  document.querySelectorAll('.card').forEach(function(c){var src=c.querySelector('.source-link');var title=c.querySelector('.card-title');if(!src||!title)return;var a=document.createElement('a');a.href=src.href;a.target='_blank';a.style.cssText='color:inherit;text-decoration:none';a.onmouseenter=function(){this.style.textDecoration='underline'};a.onmouseleave=function(){this.style.textDecoration='none'};a.innerHTML=title.innerHTML;title.innerHTML='';title.appendChild(a);});

[5] reports-list.js 업데이트
파일을 읽은 후 오늘 항목을 맨 앞에 추가(기존 항목 절대 삭제 금지).
highlights 5개, 각 40자 이내 한국어.

[6] git push
git add YYYY-MM-DD_AI_Daily_Report.html reports-list.js
git commit -m 'feat: AI daily report YYYY-MM-DD'
git push origin main
" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ "$EXIT_CODE" -eq 0 ]; then
  log "리포트 생성 완료."
  echo "$TODAY" > "$LOCK_FILE"
else
  log "오류 발생 (exit code: $EXIT_CODE). logs/report.log를 확인하세요."
fi

log "스크립트 종료."
exit "$EXIT_CODE"
