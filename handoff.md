# AI Daily Reports — Handoff Notes

## 프로젝트 개요

매일 아침 9:00 KST에 최신 AI 트렌드를 자동 수집·정리하여 HTML 리포트를 생성하고, GitHub 레포에 누적 저장하는 자동화 파이프라인.

---

## 파일 구조

```
AI_Daily_reports/
├── index.html                        ← 통합 대시보드 (정적, 수정 불필요)
├── reports-list.js                   ← 리포트 매니페스트 (에이전트가 매일 업데이트)
├── run_daily_report.sh               ← 로컬 자동 실행 스크립트 (crontab에 등록됨)
├── YYYY-MM-DD_AI_Daily_Report.html   ← 날짜별 리포트 파일
├── logs/
│   ├── report.log                    ← 실행 로그 (stdout)
│   └── report-error.log              ← 에러 로그 (stderr)
└── handoff.md                        ← 이 파일
```

### index.html 역할
- `reports-list.js`를 `<script src>` 로 로드해 `window.AI_REPORTS` 배열을 읽음
- 로컬에서 파일로 열 수 있음 (서버 불필요, CORS 문제 없음)
- 기능: 전체/주간/월별 보기, 카테고리 필터, 검색, 히트맵, 연속 발행 streak 계산
- 디자인: 화이트 베이스 (`--bg:#f1f5f9`, 사이드바 `#ffffff`, 강조색 `#6366f1`)

### reports-list.js 형식 (에이전트가 유지해야 할 스펙)
```js
window.AI_REPORTS = [
  {
    date: "YYYY-MM-DD",                      // 필수
    file: "YYYY-MM-DD_AI_Daily_Report.html", // 필수
    highlights: [                            // 한국어 5개, 각 40자 이내
      "핵심 뉴스 1",
      "핵심 뉴스 2",
      "핵심 뉴스 3",
      "핵심 뉴스 4",
      "핵심 뉴스 5"
    ],
    categories: ["LLM", "VLM", "영상생성", "기업발표", "연구", "정책"], // 해당하는 것만
    itemCount: 18                            // 리포트 내 뉴스 아이템 총 수
  },
  // ... 이전 항목들 (절대 삭제 금지)
];
```

---

## 자동화 설정 (로컬 Mac + Claude CLI)

### 구조 요약

```
crontab (매 30분, 09:00~23:30)
  └─ run_daily_report.sh 호출
       ├─ 오늘 이미 실행됐으면? → 종료 (lock file: logs/.last_run_date)
       ├─ 09:00 이전이면? → 종료
       ├─ 오늘 리포트 파일 이미 있으면? → 종료
       └─ Claude CLI 실행 → 뉴스 수집 → HTML 생성 → git push
```

### 왜 crontab 방식인가
- GitHub 레포가 개인 계정, Claude 앱은 회사 계정 → claude.ai 원격 트리거의 GitHub 커넥터 인증 불가
- 로컬 Mac의 git 자격증명(개인)으로 push → 별도 인증 불필요
- `LaunchAgents` 폴더가 root 소유라 직접 쓰기 불가 → crontab으로 대체

### Sleep 후 깨어났을 때 동작
| 상황 | 동작 |
|---|---|
| 정확히 9시에 깨어남 | 9:00 cron tick에 즉시 실행 |
| 11시에 깨어남 | 11:00 또는 11:30 cron tick에 실행 |
| 이미 오늘 생성됐으면 | lock file 확인 후 즉시 종료 (중복 없음) |
| 자정 이후 켜진 경우 | 9시 이전 차단 로직 → 9:00 tick까지 대기 |

### 등록된 crontab
```
*/30 9-23 * * * /bin/bash "/Users/user/Desktop/Claude Works/AI_Daily_reports/run_daily_report.sh" >> "/Users/user/Desktop/Claude Works/AI_Daily_reports/logs/report.log" 2>&1
```

### 주요 명령어
```bash
# 현재 crontab 확인
crontab -l

# crontab 편집
crontab -e

# crontab 전체 삭제
crontab -r

# 수동 실행 (테스트 또는 누락 리포트 보충)
/bin/bash "/Users/user/Desktop/Claude Works/AI_Daily_reports/run_daily_report.sh"

# 실행 로그 실시간 확인
tail -f "/Users/user/Desktop/Claude Works/AI_Daily_reports/logs/report.log"
```

### run_daily_report.sh 핵심 로직
- `logs/.last_run_date` 파일에 오늘 날짜가 기록되어 있으면 즉시 종료 (중복 방지)
- 현재 시각이 09:00 이전이면 즉시 종료
- `YYYY-MM-DD_AI_Daily_Report.html`이 이미 존재하면 즉시 종료
- 위 조건 모두 통과 시 `claude -p "[프롬프트]"` 실행
- 성공 시 `logs/.last_run_date`에 오늘 날짜 기록
- claude 경로: `/Users/user/.local/bin/claude`

### 원격 트리거 (현재 미사용 — 참고용)
| 항목 | 값 |
|---|---|
| Trigger ID | `trig_01FwjuEy8a9HLG3H5VzwpEoY` |
| 관리 URL | https://claude.ai/code/scheduled/trig_01FwjuEy8a9HLG3H5VzwpEoY |
| 상태 | `enabled: false` (GitHub 커넥터 인증 문제로 비활성) |
| Cron | `0 0 * * *` (00:00 UTC = 09:00 KST) |
| 모델 | claude-sonnet-4-6 |
| Environment ID | `env_013XZkH4ZBbRzjNmudEVBTC8` |
| GitHub 레포 | https://github.com/JungJune-Kim/AI-Daily-Reports |

---

## HTML 리포트 디자인 스펙

### 색상 팔레트 (화이트 테마)
```css
:root {
  --bg: #f1f5f9;       /* 페이지 배경 */
  --surface: #ffffff;  /* 카드/헤더 배경 */
  --surface2: #f8fafc; /* 보조 배경 */
  --border: #e2e8f0;   /* 구분선 */
  --text: #0f172a;     /* 본문 텍스트 */
  --muted: #475569;    /* 보조 텍스트 */
  --muted2: #94a3b8;   /* 약한 텍스트 */
  --accent: #6366f1;   /* 강조색 (인디고) */
  --cyan: #0891b2;     /* 보조 강조색 */
}
```

### HTML 구조 (필수 준수)
```html
<head>
  <!-- 기존 <style> 블록 -->
  <script src="reports-list.js"></script>   ← 반드시 포함 (날짜 네비게이션용)
  <style>
    /* Font size overrides (+2px) */
    /* Report navigation CSS */
  </style>
</head>
<body>
  <div class="header"> ... </div>
  <div class="nav-bar">                     ← 날짜 네비게이션 바
    <div class="nav-inner" id="report-nav"> ... </div>
  </div>
  <div class="container"> ... </div>
  <div class="footer"> ... </div>
  <script> /* 네비게이션 JS */ </script>
</body>
```

### 폰트 크기 오버라이드 블록 (기존 style 뒤에 별도 추가)
```css
body{font-size:16px}
.date-chip{font-size:13px}
.header h1{font-size:2.25rem}
.header p{font-size:15px}
.ko-summary h2{font-size:13px}
.ko-summary li{font-size:15.5px}
.section-count{font-size:13px}
.section-header h2{font-size:1.175rem}
.tag{font-size:12px}
.card-title{font-size:17px}
.card-desc{font-size:15px}
.card-impact{font-size:14px}
.source-link{font-size:13px}
.thumb-placeholder span{font-size:13px}
.footer{font-size:14px}
@media(max-width:600px){.header h1{font-size:1.625rem}}
```

### 날짜 네비게이션 CSS
```css
.nav-bar{background:var(--surface);border-bottom:1px solid var(--border)}
.nav-inner{max-width:1000px;margin:0 auto;padding:10px 24px;display:flex;align-items:center;justify-content:space-between;gap:16px}
.nav-btn{display:inline-flex;align-items:center;gap:5px;font-size:13px;font-weight:600;color:var(--accent);padding:7px 16px;border-radius:8px;background:var(--surface2);border:1px solid var(--border);transition:background .15s,border-color .15s;white-space:nowrap}
.nav-btn:hover{background:#eef2ff;border-color:#a5b4fc;text-decoration:none}
.nav-btn.disabled{color:var(--muted2);cursor:default;pointer-events:none}
.nav-current{font-size:13px;font-weight:700;color:var(--text);text-align:center}
```

### 날짜 네비게이션 JS (</body> 직전)
```html
<script>
(function(){
  var reports=window.AI_REPORTS;
  if(!reports||!reports.length)return;
  var file=decodeURIComponent(location.pathname.split('/').pop()||'');
  var idx=reports.findIndex(function(r){return r.file===file;});
  if(idx===-1)return;
  var older=idx+1<reports.length?reports[idx+1]:null;
  var newer=idx-1>=0?reports[idx-1]:null;
  function fmt(d){var p=d.split('-');return p[0]+'년 '+parseInt(p[1])+'월 '+parseInt(p[2])+'일';}
  function dow(d){return['일','월','화','수','목','금','토'][new Date(d+'T12:00:00').getDay()]+'요일';}
  var nav=document.getElementById('report-nav');
  if(!nav)return;
  var h='';
  h+=older?'<a class="nav-btn" href="'+older.file+'">← 이전</a>':'<span class="nav-btn disabled">← 이전</span>';
  h+='<span class="nav-current">'+fmt(reports[idx].date)+' '+dow(reports[idx].date)+'</span>';
  h+=newer?'<a class="nav-btn" href="'+newer.file+'">다음 →</a>':'<span class="nav-btn disabled">다음 →</span>';
  nav.innerHTML=h;
})();
</script>
```
- `reports-list.js` 배열은 최신순 (index 0 = 가장 최근)
- `older` = idx+1 (이전 날짜), `newer` = idx-1 (다음 날짜)
- 맨 처음/마지막 리포트에서는 해당 방향 버튼 자동 비활성화

### 헤더 구조
```html
<div class="header">
  <div class="date-chip">YYYY · MM · DD · DayOfWeek(EN)</div>
  <h1>AI Daily Trends Report</h1>
  <p>LLM &nbsp;·&nbsp; VLM &nbsp;·&nbsp; Image / Video Gen &nbsp;·&nbsp; Company News &nbsp;·&nbsp; Research &nbsp;·&nbsp; Policy</p>
</div>
```

### 섹션 구성
| 섹션 | 섹션 클래스 | 플레이스홀더 클래스 | 그라디언트 |
|---|---|---|---|
| LLM 업데이트 | `sec-llm` | `ph-llm` | `#eef2ff → #e0e7ff` |
| VLM & 멀티모달 | `sec-vlm` | `ph-vlm` | `#e0f2fe → #bae6fd` |
| 이미지/영상 생성 | `sec-video` | `ph-video` | `#faf5ff → #ede9fe` |
| 기업 발표 | `sec-company` | `ph-company` | `#f0fdf4 → #dcfce7` |
| 연구 하이라이트 | `sec-research` | `ph-research` | `#fdf4ff → #f3e8ff` |
| 정책 & 규제 | `sec-policy` | `ph-policy` | `#fefce8 → #fef9c3` |

### 카드 구조
```html
<div class="card">
  <div class="card-thumb">
    <img src="[og:image URL]" alt="..."
         onerror="this.parentElement.innerHTML='<div class=\'thumb-placeholder ph-XXX\'>EMOJI<span>LABEL</span></div>'" />
  </div>
  <div class="card-body">
    <div class="card-meta"><span class="tag tag-XXX">TAG</span></div>
    <div class="card-title">제목</div>
    <div class="card-desc">본문. <strong>강조어</strong> 포함.</div>
    <div class="card-impact">
      <span class="impact-label">Impact</span>
      <span class="impact-text">영향 설명.</span>
      <a class="source-link" href="URL" target="_blank">자세히 보기</a>
    </div>
  </div>
</div>
```
- 각 섹션 첫 번째 카드는 전체 너비 (CSS `.cards-grid .card:first-child{grid-column:1/-1}` 자동 처리)
- 썸네일 높이: 일반 180px / 첫 번째 카드 240px
- 소스 링크 텍스트: **"자세히 보기"** ("Source ↗" 사용 금지)

### 태그 클래스
```css
.tag-llm      { background:#eef2ff; color:#4338ca; }
.tag-vlm      { background:#e0f2fe; color:#0369a1; }
.tag-image    { background:#faf5ff; color:#7c3aed; }
.tag-video    { background:#fdf4ff; color:#a21caf; }
.tag-openai   { background:#f0fdf4; color:#15803d; }
.tag-anthropic{ background:#fff7ed; color:#c2410c; }
.tag-google   { background:#eff6ff; color:#1d4ed8; }
.tag-meta     { background:#eff6ff; color:#1e40af; }
.tag-research { background:#fdf4ff; color:#7e22ce; }
.tag-policy   { background:#fefce8; color:#a16207; }
.tag-oss      { background:#f0fdf4; color:#166534; }
.tag-mistral  { background:#fdf4ff; color:#a21caf; }
.tag-microsoft{ background:#eff6ff; color:#1e40af; }
.tag-alibaba  { background:#fff7ed; color:#b45309; }
```

---

## GitHub 연동

- 에이전트는 매일 리포트 HTML + reports-list.js 두 파일만 커밋
- `index.html`은 에이전트가 건드리지 않음 (정적)
- GitHub Pages 활성화 시 브라우저에서 바로 접근 가능
- GitHub 레포: https://github.com/JungJune-Kim/AI-Daily-Reports

---

## 트리거 업데이트 시 주의사항

`RemoteTrigger` update 액션에서 `job_config` 내 `events[].data.message.content`가 긴 문자열이면 JSON 파싱 실패로 `"body provided as string"` 에러 발생.

**해결책**: content 문자열에 백틱(`` ` ``)이나 중첩 따옴표 최소화, 불릿 기호 대신 `[1] [2]` 형식 사용.

---

## 현재 누적 리포트

| 날짜 | 파일 | 아이템 수 |
|---|---|---|
| 2026-04-16 | `2026-04-16_AI_Daily_Report.html` | 18 |
| 2026-04-15 | `2026-04-15_AI_Daily_Report.html` | 16 |
| 2026-04-14 | `2026-04-14_AI_Daily_Report.html` | 18 |

---

## 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-04-16 | 로컬 자동화 설정 — crontab + run_daily_report.sh (Claude CLI 방식) |
| 2026-04-16 | 날짜 네비게이션 바 추가 (← 이전 / 날짜+요일 1줄 / 다음 →) |
| 2026-04-16 | 전체 폰트 +2px 적용 (CSS 오버라이드 블록 방식) |
| 2026-04-16 | 카드 소스 링크 텍스트 "Source ↗" → "자세히 보기" 변경 |
| 2026-04-16 | 2026-04-16 리포트 디자인을 14·15일 버전과 통일 |
| 2026-04-16 | 2026-04-16 리포트 최초 업로드 |

---

*Last updated: 2026-04-16*
