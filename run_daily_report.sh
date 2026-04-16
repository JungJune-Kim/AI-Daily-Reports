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
handoff.md의 디자인 스펙을 정확히 따른다:
- 파일명: YYYY-MM-DD_AI_Daily_Report.html
- 헤더: date-chip + 그라디언트 h1 + 부제목
- 날짜 네비게이션 바 (reports-list.js 로드 + nav JS 포함)
- ko-summary 박스 (오늘의 핵심 5개)
- 섹션: LLM / VLM / 이미지·영상생성 / 기업발표 / 연구 / 정책
- 카드: card-thumb + card-body (card-meta + card-title + card-desc + card-impact)
- 소스 링크 텍스트: '자세히 보기'
- 폰트 오버라이드 블록 포함 (+2px)
- 푸터: 날짜 + 소스 링크 목록

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
