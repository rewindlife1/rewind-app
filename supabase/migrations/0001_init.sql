-- REWIND — initial schema
-- Run once in Supabase: Dashboard → SQL Editor → paste → Run.
-- Every table uses row-level security so members can only access their own data.

create extension if not exists pgcrypto;

-- ---------- Profiles ----------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text,
  membership  text not null default 'trial'
              check (membership in ('trial', 'monthly', 'annual', 'inactive')),
  stripe_customer_id text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles: read own"   on public.profiles;
drop policy if exists "profiles: insert own" on public.profiles;
drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: read own"   on public.profiles for select using (auth.uid() = id);
create policy "profiles: insert own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles: update own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- Members may edit their name, but never their membership / billing fields
-- (those are written by the server once Stripe is connected).
create or replace function public.protect_profile_billing()
returns trigger language plpgsql as $$
begin
  if auth.role() = 'authenticated' then
    if tg_op = 'INSERT' then
      new.membership := 'trial';
      new.stripe_customer_id := null;
    else
      new.membership := old.membership;
      new.stripe_customer_id := old.stripe_customer_id;
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists protect_profile_billing on public.profiles;
create trigger protect_profile_billing
  before insert or update on public.profiles
  for each row execute function public.protect_profile_billing();

-- Create a profile automatically for every new sign-up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Assessments ----------
create table if not exists public.assessments (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  answers       jsonb not null,
  pillar_scores jsonb not null,
  overall       int  not null check (overall between 0 and 100),
  created_at    timestamptz not null default now()
);
create index if not exists assessments_user_created on public.assessments (user_id, created_at desc);

-- ---------- Daily plan ----------
create table if not exists public.tasks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  pillar     text not null check (pillar in ('biomarkers','toxins','mindset','community','nutrition','supplementation','exercise','routines')),
  title      text not null,
  detail     text,
  active     boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists tasks_user_active on public.tasks (user_id, active);

create table if not exists public.task_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  task_id    uuid not null references public.tasks (id) on delete cascade,
  day        date not null default current_date,
  created_at timestamptz not null default now(),
  unique (task_id, day)
);
create index if not exists task_logs_user_day on public.task_logs (user_id, day);

-- ---------- Score history ----------
create table if not exists public.score_snapshots (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  day           date not null,
  overall       int  not null check (overall between 0 and 100),
  pillar_scores jsonb not null,
  created_at    timestamptz not null default now(),
  unique (user_id, day)
);

-- ---------- REWIND Coach ----------
create table if not exists public.coach_messages (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  role       text not null check (role in ('user', 'coach')),
  body       text not null check (char_length(body) <= 4000),
  created_at timestamptz not null default now()
);
create index if not exists coach_messages_user_created on public.coach_messages (user_id, created_at);

-- ---------- Row-level security for member-owned tables ----------
do $$
declare t text;
begin
  foreach t in array array['assessments','tasks','task_logs','score_snapshots','coach_messages'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "%s: own rows" on public.%I', t, t);
    execute format(
      'create policy "%s: own rows" on public.%I for all using (auth.uid() = user_id) with check (auth.uid() = user_id)',
      t, t);
  end loop;
end $$;

-- A member can only log completions against their own tasks.
create or replace function public.check_task_owner()
returns trigger language plpgsql as $$
begin
  if not exists (select 1 from public.tasks where id = new.task_id and user_id = new.user_id) then
    raise exception 'task does not belong to user';
  end if;
  return new;
end $$;

drop trigger if exists task_logs_owner on public.task_logs;
create trigger task_logs_owner
  before insert or update on public.task_logs
  for each row execute function public.check_task_owner();
