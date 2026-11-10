-- DẤU ẤN TRI ÂN 20/11/2026 - Supabase setup
-- Chạy toàn bộ trong Supabase Dashboard > SQL Editor.
-- Sau khi tạo tài khoản quản trị, chạy câu UPDATE ở cuối để cấp quyền admin.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  student_code text not null unique,
  faculty text not null default '',
  class_name text not null default '',
  union_name text not null default '',
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  author_name text not null default 'Thành viên chương trình',
  author_unit text not null default '',
  activity text not null,
  teacher_name text,
  title text not null,
  message text,
  media_url text,
  media_type text check (media_type in ('image','video') or media_type is null),
  external_url text,
  status text not null default 'PENDING' check (status in ('PENDING','APPROVED','REJECTED')),
  reject_reason text,
  consent boolean not null default false,
  featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists submissions_status_idx on public.submissions(status);
create index if not exists submissions_user_idx on public.submissions(user_id);
create index if not exists submissions_activity_idx on public.submissions(activity);

-- Tạo profile tự động khi người dùng đăng ký Auth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, full_name, student_code, faculty, class_name, union_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    coalesce(new.raw_user_meta_data->>'student_code',''),
    coalesce(new.raw_user_meta_data->>'faculty',''),
    coalesce(new.raw_user_meta_data->>'class_name',''),
    coalesce(new.raw_user_meta_data->>'union_name','')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Hàm kiểm tra admin tránh policy tự tham chiếu profiles.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

alter table public.profiles enable row level security;
alter table public.submissions enable row level security;

drop policy if exists "profile read self or admin" on public.profiles;
create policy "profile read self or admin" on public.profiles
for select to authenticated using (id = auth.uid() or public.is_admin());

drop policy if exists "profile insert self" on public.profiles;
create policy "profile insert self" on public.profiles
for insert to authenticated with check (id = auth.uid() and role = 'student');

drop policy if exists "profile update self or admin" on public.profiles;
create policy "profile update self or admin" on public.profiles
for update to authenticated using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

drop policy if exists "approved submissions public read" on public.submissions;
create policy "approved submissions public read" on public.submissions
for select to anon, authenticated using (status = 'APPROVED');

drop policy if exists "owner read own submissions" on public.submissions;
create policy "owner read own submissions" on public.submissions
for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "student create own submission" on public.submissions;
create policy "student create own submission" on public.submissions
for insert to authenticated with check (
  user_id = auth.uid() and status = 'PENDING' and consent = true and featured = false
);

drop policy if exists "admin update submissions" on public.submissions;
create policy "admin update submissions" on public.submissions
for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Storage bucket công khai: chỉ URL của nội dung đã duyệt được hiển thị trên giao diện.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('tri-an-media','tri-an-media',true,52428800,array['image/jpeg','image/png','image/webp','video/mp4'])
on conflict (id) do update set public = true, file_size_limit = 52428800,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','video/mp4'];

drop policy if exists "user upload own media folder" on storage.objects;
create policy "user upload own media folder" on storage.objects
for insert to authenticated with check (
  bucket_id = 'tri-an-media' and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "public read tri an media" on storage.objects;
create policy "public read tri an media" on storage.objects
for select to anon, authenticated using (bucket_id = 'tri-an-media');

drop policy if exists "owner delete own media" on storage.objects;
create policy "owner delete own media" on storage.objects
for delete to authenticated using (
  bucket_id = 'tri-an-media' and (storage.foldername(name))[1] = auth.uid()::text
);

-- CẤP QUYỀN ADMIN:
-- 1) Đăng ký tài khoản của chính thầy trên website, xác minh email và đăng nhập ít nhất một lần.
-- 2) Lấy email tài khoản đó và chạy lệnh dưới đây (thay email).
-- update public.profiles p set role='admin'
-- from auth.users u where p.id=u.id and u.email='EMAIL_QUAN_TRI_CUA_BAN';
