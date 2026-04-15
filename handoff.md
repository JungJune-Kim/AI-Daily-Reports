# AI Daily Reports — Handoff Notes

## 프로젝트 개요

매일 아침 9:00 KST에 최신 AI 트렌드를 자동 수집·정리하여 HTML 리포트를 생성하고, GitHub 레포에 누적 저장하는 자동화 파이프라인.

---

## 파일 구조

```
AI_Daily_reports/
├── index.html                        ← 통합 대시보드 (정적, 수정 불필요)
├── reports-list.js                   ← 리포트 매니페스트 (에이전트가 매일 업데이트)
├── YYYY-MM-DD_AI_Daily_Report.html   ← 날짜별 리포트 파일
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

## 스케줄 트리거

| 항목 | 값 |
|---|---|
| Trigger ID | `trig_01FwjuEy8a9HLG3H5VzwpEoY` |
| 관리 URL | https://claude.ai/code/scheduled/trig_01FwjuEy8a9HLG3H5VzwpEoY |
| 실행 시각 | 매일 00:00 UTC = 09:00 KST |
| Cron | `0 0 * * *` |
| 모델 | claude-sonnet-4-6 |
| Environment ID | `env_013XZkH4ZBbRzjNmudEVBTC8` |
| GitHub 레포 | https://github.com/JungJune-Kim/AI-Daily-Reports |

### 에이전트 수행 순서
1. `date +%Y-%m-%d` 로 오늘 날짜 확인
2. WebSearch 6-8 쿼리 (LLM, VLM, 영상생성, 기업, 연구, 정책)
3. 각 기사 URL에 WebFetch → og:image 수집 (403/없으면 null, 플레이스홀더 사용)
4. `YYYY-MM-DD_AI_Daily_Report.html` 생성 (썸네일 카드 디자인, 화이트 테마)
5. `reports-list.js` 읽기 → 오늘 항목 맨 앞에 추가 → 덮어쓰기
6. `git add` + `git commit -m 'feat: AI daily report YYYY-MM-DD'` + `git push origin main`

---

## HTML 리포트 디자인 스펙

### 색상 팔레트 (화이트 테마 — 현재 기준)
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

### 카드 레이아웃
- 각 섹션의 **첫 번째 카드**는 전체 너비 피처드 카드 (`grid-column: 1 / -1`)
- 썸네일 높이: 일반 카드 180px, 피처드 카드 240px
- 이미지 로드 실패 시 `onerror` → 섹션별 컬러 그라디언트 플레이스홀더 (라이트 톤)

### 섹션 구성 및 플레이스홀더 클래스
| 섹션 | 플레이스홀더 클래스 | 배경 그라디언트 (라이트) |
|---|---|---|
| LLM 업데이트 | `ph-llm` | `#eef2ff → #e0e7ff` |
| VLM & 멀티모달 | `ph-vlm` | `#eff6ff → #dbeafe` |
| 이미지/영상 생성 | `ph-video` | `#faf5ff → #ede9fe` |
| 기업 발표 | `ph-company` | `#f0fdf4 → #dcfce7` |
| 연구 하이라이트 | `ph-research` | `#f5f3ff → #ede9fe` |
| 정책 & 규제 | `ph-policy` | `#fefce8 → #fef9c3` |

### 헤더 스타일
```css
.header { background: #ffffff; border-bottom: 1px solid var(--border); }
.header h1 {
  background: linear-gradient(90deg, #4f46e5, #6366f1, #0891b2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
```

### 태그 클래스 (라이트 파스텔)
```css
.tag-llm      { background:#eef2ff; color:#4338ca; }
.tag-vlm      { background:#eff6ff; color:#1d4ed8; }
.tag-image    { background:#fdf4ff; color:#7e22ce; }
.tag-video    { background:#faf5ff; color:#6d28d9; }
.tag-openai   { background:#f0fdf4; color:#15803d; }
.tag-anthropic{ background:#fff7ed; color:#c2410c; }
.tag-google   { background:#eff6ff; color:#1d4ed8; }
.tag-meta     { background:#eff6ff; color:#1e40af; }
.tag-research { background:#f5f3ff; color:#5b21b6; }
.tag-policy   { background:#fefce8; color:#a16207; }
.tag-oss      { background:#f0fdf4; color:#166534; }
.tag-mistral  { background:#fff1f2; color:#be123c; }
```

### 카드 스타일
```css
.card {
  background: #ffffff;
  border: 1px solid var(--border);
  box-shadow: 0 1px 3px rgba(0,0,0,.05);
}
.card:hover {
  border-color: #a5b4fc;
  box-shadow: 0 10px 28px rgba(99,102,241,.12);
}
```

---

## GitHub 연동

- 로컬 `AI_Daily_reports/` 폴더의 `index.html`, `reports-list.js`를 레포에 먼저 push해야 대시보드가 작동
- 에이전트는 매일 리포트 HTML + reports-list.js 두 파일만 커밋
- `index.html`은 에이전트가 건드리지 않음 (정적)
- GitHub Pages 활성화 시 브라우저에서 바로 접근 가능

### GitHub 커넥터 인증 (미완료)
- 트리거 실행 시 `github_repo_access_denied` 오류 발생
- 해결: https://claude.ai/settings/connectors 에서 GitHub 커넥터 인증 필요
- 인증 완료 후 트리거 수동 실행으로 누락 리포트 보충 가능

---

## 트리거 업데이트 시 주의사항

`RemoteTrigger` update 액션에서 `job_config` 내 `events[].data.message.content`가 긴 문자열이면 JSON 파싱 실패로 `"body provided as string"` 에러 발생.

**해결책**: content 문자열에 백틱(`` ` ``)이나 중첩 따옴표 최소화, 불릿 기호 대신 `[1] [2]` 형식 사용.

### 트리거 비활성화 주의
트리거가 `enabled: false`로 꺼진 경우 리포트가 생성되지 않음.  
확인: `RemoteTrigger {action:"get", trigger_id:"trig_01FwjuEy8a9HLG3H5VzwpEoY"}`  
복구: `RemoteTrigger {action:"update", trigger_id:"...", body:{enabled:true}}`

---

## 현재 누적 리포트

| 날짜 | 파일 | 아이템 수 |
|---|---|---|
| 2026-04-15 | `2026-04-15_AI_Daily_Report.html` | 16 |
| 2026-04-14 | `2026-04-14_AI_Daily_Report.html` | 18 |

---

*Last updated: 2026-04-15*
