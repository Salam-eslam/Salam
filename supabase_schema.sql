-- Create the posts table
create table if not exists public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id text not null, -- Storing as text to support 'anonymous_user' for now
  username text not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  likes_count integer default 0,
  comments_count integer default 0,
  is_liked boolean default false -- Temporary shared state for MVP
);

-- Set up Row Level Security (RLS)
-- For development/MVP with anonymous users, we'll allow public access
alter table public.posts enable row level security;

create policy "Public posts are viewable by everyone"
on public.posts for select
using ( true );

create policy "Anyone can insert a post"
on public.posts for insert
with check ( true );

create policy "Anyone can update a post"
on public.posts for update
using ( true );

-- Optional: Create a likes table for future robust implementation
create table if not exists public.likes (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references public.posts(id) on delete cascade,
  user_id text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(post_id, user_id)
);

alter table public.likes enable row level security;

create policy "Public likes are viewable by everyone"
on public.likes for select
using ( true );

create policy "Anyone can insert a like"
on public.likes for insert
with check ( true );

create policy "Anyone can delete their own like"
on public.likes for delete
using ( true );

-- Chat History Table
-- Stores private conversation history between user and AI
create table if not exists public.chat_messages (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  content text not null,
  is_user boolean default true,
  is_error boolean default false,
  should_show_ifta_link boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  session_id uuid
);

create index if not exists chat_messages_user_id_idx on public.chat_messages(user_id);
create index if not exists chat_messages_created_at_idx on public.chat_messages(created_at);

alter table public.chat_messages enable row level security;

-- Chat History Policies
-- Relaxed policies for development/MVP
create policy "Enable access to all users"
on public.chat_messages for all
using ( true )
with check ( true );

/*
create policy "Users can view their own chat messages"
on public.chat_messages for select
using ( auth.uid()::text = user_id );

create policy "Users can insert their own chat messages"
on public.chat_messages for insert
with check ( auth.uid()::text = user_id );

create policy "Users can delete their own chat messages"
on public.chat_messages for delete
using ( auth.uid()::text = user_id );
*/
