-- Person 3 owns these tables: sessions and swipe_actions

-- Tracks each cleanup session a user initiates
create table sessions (
  id           uuid    primary key default gen_random_uuid(),
  started_at   bigint  not null,
  ended_at     bigint,
  reviewed     int     not null default 0,
  deleted      int     not null default 0,
  kept         int     not null default 0,
  storage_saved bigint not null default 0,
  created_at   timestamp not null default now()
);

-- Records every keep/delete decision made during a session
create table swipe_actions (
  id         uuid  primary key default gen_random_uuid(),
  session_id uuid  not null references sessions(id) on delete cascade,
  photo_id   text  not null,
  action     text  not null check (action in ('keep', 'delete')),
  timestamp  bigint not null
);

-- RLS
alter table sessions     enable row level security;
alter table swipe_actions enable row level security;

-- Permissive policies (tighten once auth is added)
create policy "allow_all_sessions"
  on sessions for all using (true) with check (true);

create policy "allow_all_swipe_actions"
  on swipe_actions for all using (true) with check (true);

-- Indexes
create index idx_sessions_started_at      on sessions(started_at);
create index idx_swipe_actions_session_id on swipe_actions(session_id);
create index idx_swipe_actions_photo_id   on swipe_actions(photo_id);
