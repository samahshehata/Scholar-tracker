-- Scholarship Hub community database
-- Run once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles(id,email) values(new.id,new.email)
  on conflict (id) do update set email=excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.public_scholarships (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete set null,
  is_public boolean not null default false,
  status text not null default 'private' check (status in ('private','pending','approved')),
  data jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_scholarships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  scholarship_id uuid not null references public.public_scholarships(id) on delete cascade,
  priority text not null default 'Medium',
  status text not null default 'Not Started',
  progress integer not null default 0 check(progress between 0 and 100),
  notes text not null default '',
  tasks jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, scholarship_id)
);

alter table public.profiles enable row level security;
alter table public.public_scholarships enable row level security;
alter table public.user_scholarships enable row level security;

drop policy if exists "profiles self read" on public.profiles;
create policy "profiles self read" on public.profiles for select to authenticated using(auth.uid()=id);

drop policy if exists "public scholarships read" on public.public_scholarships;
create policy "public scholarships read" on public.public_scholarships for select to anon,authenticated
using(is_public=true and status='approved' or auth.uid()=created_by or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "public scholarships insert" on public.public_scholarships;
create policy "public scholarships insert" on public.public_scholarships for insert to authenticated
with check(auth.uid()=created_by);

drop policy if exists "public scholarships update" on public.public_scholarships;
create policy "public scholarships update" on public.public_scholarships for update to authenticated
using(auth.uid()=created_by or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check(auth.uid()=created_by or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "public scholarships delete" on public.public_scholarships;
create policy "public scholarships delete" on public.public_scholarships for delete to authenticated
using(auth.uid()=created_by or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "user scholarships self" on public.user_scholarships;
create policy "user scholarships self" on public.user_scholarships for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);

create index if not exists public_scholarships_status_idx on public.public_scholarships(status,is_public);
create index if not exists public_scholarships_created_by_idx on public.public_scholarships(created_by);
create index if not exists user_scholarships_user_idx on public.user_scholarships(user_id);

-- To make yourself an admin after creating your account, replace EMAIL below:
-- update public.profiles set role='admin' where email='YOUR_EMAIL@example.com';
