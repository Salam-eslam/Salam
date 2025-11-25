-- Create a table for chat messages
-- This table stores the history of conversations between the user and the AI assistant.
create table if not exists public.chat_messages (
  id uuid default gen_random_uuid() primary key,
  user_id text not null, -- Maps to auth.uid()
  content text not null,
  is_user boolean default true, -- true for user messages, false for AI responses
  is_error boolean default false, -- to track failed responses
  should_show_ifta_link boolean default false, -- specific metadata for Islamic AI
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Optional: Add session_id if we want to support multiple chat sessions in the future
  -- For now, we can treat the history as a single continuous stream per user
  session_id uuid
);

-- Add indexes for performance
-- Index on user_id is crucial for filtering messages by user
create index if not exists chat_messages_user_id_idx on public.chat_messages(user_id);
-- Index on created_at helps with sorting the history
create index if not exists chat_messages_created_at_idx on public.chat_messages(created_at);

-- Enable Row Level Security (RLS) to protect user privacy
alter table public.chat_messages enable row level security;

-- Policies

-- Relaxed policies for development/MVP to match posts table
-- This allows the app to work with device IDs or anonymous users without strict Supabase Auth
create policy "Enable access to all users"
on public.chat_messages for all
using ( true )
with check ( true );

-- STRICT POLICIES (Enable these when Supabase Auth is fully integrated)
/*
-- 1. Users can view ONLY their own messages
create policy "Users can view their own chat messages"
on public.chat_messages for select
using ( auth.uid()::text = user_id );

-- 2. Users can insert ONLY their own messages
create policy "Users can insert their own chat messages"
on public.chat_messages for insert
with check ( auth.uid()::text = user_id );

-- 3. Users can delete ONLY their own messages
create policy "Users can delete their own chat messages"
on public.chat_messages for delete
using ( auth.uid()::text = user_id );
*/

-- Note: 
-- This schema assumes you are using Supabase Auth (Email, Phone, or Anonymous).
-- If you are using a custom ID system without Supabase Auth, you would need to 
-- adjust the policies (e.g., using a shared secret or public access), 
-- but that is NOT recommended for private chat history.
