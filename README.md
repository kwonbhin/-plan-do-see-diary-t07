# 플랜두씨 다이어리 1 — 내 계획과 실제를 담는 앱

SKT ALEPH 과제 6. Plan(계획) → Do(실제로 한 일) → See(돌아보기)가 하나로 이어지는 다이어리.
로그인 없이 누구나 링크로 볼 수 있으며, 모든 자료는 Supabase(Postgres) 서버 데이터베이스에 저장됩니다.

## 지금은 로그인이 없어 링크를 아는 사람은 누구나 볼 수 있습니다. 남이 봐도 괜찮은 내용만 넣으세요.

## 폴더 구조

```
.
├── index.html              # 화면 전체 (Start → Plan/Do/See)
├── contracts/
│   └── pds-schema-v2.json  # 최종 DB 스키마 계약서 (표·항목·관계·날짜 규칙)
├── supabase/
│   └── schema.sql          # Supabase에 실행한 전체 DDL (테이블/트리거/함수/RLS/뷰)
└── docs/
    └── SETUP.md            # Supabase·GitHub Pages 설정 가이드
```

## 기술 스택

- Frontend: 순수 HTML/CSS/JS (정적 파일, GitHub Pages로 배포)
- Backend/DB: Supabase (PostgreSQL) — REST API를 anon key로 직접 호출
- 인증: 없음 (7번 과제에서 도입 예정)

## 개발 상태

- [x] Start → Plan/Do/See 캐러셀 네비게이션 뼈대
- [x] Supabase DB 스키마 설계·배포
- [ ] Plan 화면 기능 연결
- [ ] Do 화면 기능 연결
- [ ] See 화면 집계 연결
- [ ] 내 실제 데이터로 채우기
- [ ] 내보내기·공개 안내·보안 점검
- [ ] 제출 문서 작성 (확인 방법 4줄 / AI 판단 3줄)

## 결과물 확인 방법

_(기능 연결 완료 후 채울 예정)_
