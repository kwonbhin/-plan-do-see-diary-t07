# 설정 가이드 — Supabase + GitHub

## 1. Supabase 프로젝트 만들기
1. https://supabase.com 접속 → GitHub 계정으로 가입/로그인
2. "New project" 클릭
3. 프로젝트 이름: 예) `pds-diary` (아무거나 괜찮아요)
4. Database Password: 자동 생성되는 값 그대로 두고 **꼭 어딘가에 복사해서 저장**해두세요 (나중에 필요할 수 있어요)
5. Region: `Northeast Asia (Seoul)` 선택하면 속도가 좀 더 좋아요
6. "Create new project" → 1~2분 정도 기다리면 생성돼요

## 2. 스키마 넣기
1. 왼쪽 메뉴에서 **SQL Editor** 클릭
2. "New query" 클릭
3. 제가 만든 `supabase/schema.sql` 파일 내용을 **전부 복사해서 붙여넣기**
4. 오른쪽 아래 "Run" 클릭
5. 에러 없이 "Success" 뜨면 완료 — 왼쪽 메뉴 **Table Editor**에서 `plans`, `todos`, `execution_logs`, `plan_revisions`, `review_notes` 테이블이 보이면 성공이에요

## 3. API 키 확인하기 (이후 화면 개발에 필요)
1. 왼쪽 메뉴 하단 **Project Settings** (톱니바퀴) → **API**
2. 여기서 아래 두 값을 저에게 알려주시면 실제 화면에 연결할게요:
   - **Project URL** (예: `https://xxxxxxxx.supabase.co`)
   - **anon public** 키 (긴 문자열)

   > 이 anon 키는 "누구나 링크로 볼 수 있게" 하기 위해 일부러 공개적으로 쓰는 키예요.
   > 비밀키(`service_role` 키)는 절대 코드에 넣거나 저에게 보내지 마세요 — 그건 관리자 권한이라 유출되면 안 됩니다.

## 4. GitHub 저장소 준비
1. https://github.com 새 저장소 생성 (예: `pds-diary`), Public으로 설정
2. 아래 구조로 파일을 올려주세요 (제가 계속 채워드릴게요):
   ```
   pds-diary/
   ├── index.html              (지금까지 만든 화면 — Start/Plan/Do/See)
   ├── contracts/
   │   └── pds-schema-v2.json  (방금 만든 스키마 계약서)
   ├── supabase/
   │   └── schema.sql          (방금 만든 스키마 — 기록용, 실제 실행은 2번에서 이미 함)
   └── README.md
   ```
3. GitHub Pages 켜기: 저장소 **Settings → Pages → Branch: main / (root)** 선택 → 저장
   - 몇 분 뒤 `https://[아이디].github.io/pds-diary/` 로 화면이 열려요 (이게 "결과물 URL"이 돼요)
4. 제출용 "소스 URL"은 **특정 커밋의 고정 링크**여야 해요 (브랜치 링크 X). 커밋 하나 올린 뒤:
   - GitHub에서 커밋 해시(초록색 커밋 목록의 7자리 코드) 클릭 → 그 페이지 URL을 쓰면 돼요

## 다음 단계
Project URL과 anon 키를 알려주시면, 지금 만든 화면에 Supabase 연결 코드를 붙여서 Plan 화면부터 실제로 저장되게 만들어볼게요.
