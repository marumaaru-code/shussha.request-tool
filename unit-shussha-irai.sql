-- =====================================================================
--  別曜日 出社依頼（unit-shussha-irai.html）専用テーブル
--  Supabase の SQL Editor に貼り付けて「Run」で実行してください。
--  このツール専用のプロジェクトを想定しています（office_requests だけ作成）。
-- =====================================================================

create table if not exists office_requests (
  id             uuid primary key default gen_random_uuid(),
  unit_name      text not null,          -- 所属（例: "SNS unitH" / "LINE"）
  person_name    text not null,          -- 名前
  requested_date date not null,          -- 出社したい日付
  reason         text,                   -- 理由・備考（任意）
  status         text default 'pending', -- pending（承認待ち）/ approved / rejected
  reviewer_comment text,                 -- 確認者コメント（任意）
  client_id      text,                   -- 提出端末の識別用
  created_at     timestamptz default now()
);

-- 既にテーブルがある場合に備えて列を後から足す（あってもエラーにならない）
alter table office_requests add column if not exists reviewer_comment text;

-- 行レベルセキュリティ（RLS）＋ 社内カジュアル利用向けのポリシー
alter table office_requests enable row level security;

drop policy if exists "anyone read reqs"   on office_requests;
create policy "anyone read reqs"   on office_requests for select using (true);

drop policy if exists "anyone write reqs"  on office_requests;
create policy "anyone write reqs"  on office_requests for insert with check (true);

drop policy if exists "anyone update reqs" on office_requests;
create policy "anyone update reqs" on office_requests for update using (true) with check (true);

drop policy if exists "anyone delete reqs" on office_requests;
create policy "anyone delete reqs" on office_requests for delete using (true);

-- リアルタイム反映（提出・承認が全員の画面に即反映される）
-- ※すでに追加済みだと "already a member" のエラーになりますが、その場合は無視してOKです。
alter publication supabase_realtime add table office_requests;


-- =====================================================================
--  欠席記録（月間出社ビューで「ある週のメイン出社日に来られなかった人」を記録）
--  ※この機能を使う場合だけ実行すればOKです。
-- =====================================================================
create table if not exists absences (
  id          uuid primary key default gen_random_uuid(),
  person_name text not null,     -- 欠席した人の名前
  unit_name   text,              -- 所属（表示用）
  absent_date date not null,     -- 欠席日（メイン出社日）
  client_id   text,
  created_at  timestamptz default now(),
  unique (person_name, absent_date)
);
alter table absences enable row level security;
drop policy if exists "anyone read abs"   on absences;
create policy "anyone read abs"   on absences for select using (true);
drop policy if exists "anyone write abs"  on absences;
create policy "anyone write abs"  on absences for insert with check (true);
drop policy if exists "anyone delete abs" on absences;
create policy "anyone delete abs" on absences for delete using (true);
alter publication supabase_realtime add table absences;


-- =====================================================================
--  インターン名簿の追加分（「インターン追加」タブで登録）
--  ※この機能を使う場合だけ実行すればOKです。
-- =====================================================================
create table if not exists interns (
  id        uuid primary key default gen_random_uuid(),
  name      text not null,        -- 氏名（例: "山田 花子"）
  division  text not null,        -- 所属（例: "SNS" / "広告" / "AI" 等）
  unit      text,                 -- unit（A〜H等。無い部署は空）
  created_at timestamptz default now(),
  unique (name)
);
alter table interns enable row level security;
drop policy if exists "anyone read interns"   on interns;
create policy "anyone read interns"   on interns for select using (true);
drop policy if exists "anyone write interns"  on interns;
create policy "anyone write interns"  on interns for insert with check (true);
drop policy if exists "anyone delete interns" on interns;
create policy "anyone delete interns" on interns for delete using (true);
alter publication supabase_realtime add table interns;
