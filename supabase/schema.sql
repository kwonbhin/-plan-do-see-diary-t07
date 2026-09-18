-- ============================================================
-- 플랜두씨 다이어리 1 — Supabase 스키마
-- 과제 6 (T06) 통과 기준을 만족하도록 설계
-- 이 파일 전체를 Supabase 대시보드 > SQL Editor 에 붙여넣고 실행하세요.
-- ============================================================

create extension if not exists "pgcrypto"; -- gen_random_uuid() 사용

-- ------------------------------------------------------------
-- 1. plans (계획) — 카드1
-- T06-C04 기간 / C05 우선순위 / C06 성공 기준 / C07 예상 시간
-- ------------------------------------------------------------
create table plans (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  period_start date not null,
  period_end date not null,
  priority text not null check (priority in ('high','medium','low')),
  success_criteria text not null,
  estimated_minutes integer not null check (estimated_minutes >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2. plan_revisions (계획 수정 이력) — 카드1
-- T06-C08 계획을 고쳐도 고치기 전 계획이 그대로 남아 있다
-- update 되기 직전의 값을 스냅샷으로 저장하는 트리거
-- ------------------------------------------------------------
create table plan_revisions (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references plans(id) on delete cascade,
  title text not null,
  period_start date not null,
  period_end date not null,
  priority text not null,
  success_criteria text not null,
  estimated_minutes integer not null,
  revised_at timestamptz not null default now()
);

create or replace function fn_capture_plan_revision()
returns trigger as $$
begin
  insert into plan_revisions (
    plan_id, title, period_start, period_end,
    priority, success_criteria, estimated_minutes
  )
  values (
    old.id, old.title, old.period_start, old.period_end,
    old.priority, old.success_criteria, old.estimated_minutes
  );
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger trg_plan_revision
before update on plans
for each row
when (
  old.title is distinct from new.title or
  old.period_start is distinct from new.period_start or
  old.period_end is distinct from new.period_end or
  old.priority is distinct from new.priority or
  old.success_criteria is distinct from new.success_criteria or
  old.estimated_minutes is distinct from new.estimated_minutes
)
execute function fn_capture_plan_revision();

-- ------------------------------------------------------------
-- 3. todos (할 일) — 카드2
-- T06-C09~C17: 생성/수정/완료/되돌리기/삭제, 마감일/우선순위/태그/예상시간
-- 삭제는 소프트 삭제(deleted_at)로 처리 → See 집계의 "지우지 않은" 조건과 연결
-- ------------------------------------------------------------
create table todos (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references plans(id) on delete cascade,
  title text not null,
  content text,
  due_date date,
  priority text check (priority in ('high','medium','low')),
  tags text[] not null default '{}',
  estimated_minutes integer check (estimated_minutes >= 0),
  status text not null default 'todo' check (status in ('todo','done')),
  completed_at timestamptz,
  completion_key text unique, -- 완료 처리 중복 방지용 (아래 설명 참고)
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_todos_plan_id on todos(plan_id) where deleted_at is null;
create index idx_todos_status on todos(status) where deleted_at is null;

-- 완료 처리는 반드시 이 함수로만 호출 (앱에서 직접 UPDATE 하지 말 것)
-- T06-C21 완료 버튼을 연달아 두 번 눌러도 완료 기록은 한 건만 남는다
-- T06-C22 그때 See의 완료 수도 정확히 1만 늘어난다
--   -> status <> 'done' 조건으로 가드해서, 이미 done인 행은 다시 업데이트되지 않음
--   -> completion_key 는 클라이언트가 클릭마다 생성해 같이 보내는 고유 키.
--      혹시 같은 요청이 네트워크 재시도 등으로 두 번 들어와도 unique 제약이 막아줌
create or replace function fn_complete_todo(p_todo_id uuid, p_completion_key text)
returns todos as $$
declare
  v_row todos;
begin
  update todos
  set status = 'done', completed_at = now(), completion_key = p_completion_key
  where id = p_todo_id and status <> 'done'
  returning * into v_row;

  if v_row.id is null then
    select * into v_row from todos where id = p_todo_id;
  end if;

  return v_row;
end;
$$ language plpgsql;

create or replace function fn_reopen_todo(p_todo_id uuid)
returns todos as $$
declare
  v_row todos;
begin
  update todos
  set status = 'todo', completed_at = null, completion_key = null
  where id = p_todo_id
  returning * into v_row;
  return v_row;
end;
$$ language plpgsql;

-- ------------------------------------------------------------
-- 4. execution_logs (실행 기록) — 카드3
-- T06-C23~C26: 시작시각/끝난시각/실제시간/막힌이유
-- T06-C27: 실행 기록 저장해도 원래 계획 값은 덮어쓰지 않음
--   -> todos/plans 테이블을 건드리지 않는 완전히 별도 테이블로 분리해 자연히 만족
-- idempotency_key: 이중 제출(더블클릭, 네트워크 재시도) 방지
-- ------------------------------------------------------------
create table execution_logs (
  id uuid primary key default gen_random_uuid(),
  todo_id uuid not null references todos(id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  actual_minutes integer not null check (actual_minutes >= 0),
  blocked_reason text,
  idempotency_key text not null unique,
  created_at timestamptz not null default now(),
  constraint chk_time_order check (ended_at >= started_at)
);

create index idx_exec_logs_todo_id on execution_logs(todo_id);

-- ------------------------------------------------------------
-- 5. review_notes (돌아보기 → 다음 계획으로 넘기는 한 줄) — 카드4
-- T06-C33 돌아보기에서 정한 고칠 점 한 건이 다음 계획으로 넘어간다
-- ------------------------------------------------------------
create table review_notes (
  id uuid primary key default gen_random_uuid(),
  source_plan_id uuid references plans(id) on delete set null,
  note text not null,
  carried_to_plan_id uuid references plans(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- RLS(행 단위 보안) — 이 과제는 로그인이 없으므로 익명(anon) 키로
-- 전체 읽기/쓰기가 가능해야 합니다. 7번 과제에서 잠글 예정입니다.
-- ============================================================
alter table plans enable row level security;
alter table plan_revisions enable row level security;
alter table todos enable row level security;
alter table execution_logs enable row level security;
alter table review_notes enable row level security;

create policy "anon full access" on plans
  for all using (true) with check (true);
create policy "anon read revisions" on plan_revisions
  for select using (true);
create policy "anon full access" on todos
  for all using (true) with check (true);
create policy "anon full access" on execution_logs
  for all using (true) with check (true);
create policy "anon full access" on review_notes
  for all using (true) with check (true);

-- ============================================================
-- See 화면 집계 뷰 — 카드4
-- T06-C28~C32 계획별 계획수/완료수/지연수/막힘수/예상·실제시간·차이
-- 날짜 규칙: 모든 시각은 UTC로 저장, 화면 표시/지연 판정은
-- Asia/Seoul(UTC+9) 기준으로 변환해서 계산합니다.
-- ============================================================
create or replace view v_plan_review as
select
  p.id as plan_id,
  p.title as plan_title,
  count(t.id) filter (where t.deleted_at is null) as todo_count,
  count(t.id) filter (where t.deleted_at is null and t.status = 'done') as done_count,
  count(t.id) filter (
    where t.deleted_at is null
      and t.status <> 'done'
      and t.due_date is not null
      and t.due_date < (now() at time zone 'Asia/Seoul')::date
  ) as overdue_count,
  count(t.id) filter (
    where t.deleted_at is null
      and exists (
        select 1 from execution_logs el
        where el.todo_id = t.id and el.blocked_reason is not null and el.blocked_reason <> ''
      )
  ) as blocked_count,
  coalesce(sum(t.estimated_minutes) filter (where t.deleted_at is null), 0) as estimated_minutes_sum,
  coalesce((
    select sum(el.actual_minutes)
    from execution_logs el
    join todos t2 on t2.id = el.todo_id
    where t2.plan_id = p.id and t2.deleted_at is null
  ), 0) as actual_minutes_sum
from plans p
left join todos t on t.plan_id = p.id
group by p.id, p.title;

-- 사용 예 (앱에서 그대로 호출):
-- select *, (actual_minutes_sum - estimated_minutes_sum) as diff_minutes
-- from v_plan_review where plan_id = '...';
