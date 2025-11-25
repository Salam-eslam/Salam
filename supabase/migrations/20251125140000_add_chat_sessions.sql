-- Create chat_sessions table
create table if not exists public.chat_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  title text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add RLS for chat_sessions
alter table public.chat_sessions enable row level security;

create policy "Enable access to all users for chat_sessions"
on public.chat_sessions for all
using ( true )
with check ( true );

-- Add session_id to chat_messages
alter table public.chat_messages 
add column if not exists session_id uuid references public.chat_sessions(id) on delete cascade;

-- Index for session_id
create index if not exists chat_messages_session_id_idx on public.chat_messages(session_id);
