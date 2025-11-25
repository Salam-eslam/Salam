-- Create posts table for community feature
CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_avatar TEXT,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 2000),
    surah_number INTEGER CHECK (surah_number >= 1 AND surah_number <= 114),
    verse_number INTEGER CHECK (verse_number >= 1),
    verse_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    likes_count INTEGER NOT NULL DEFAULT 0,
    comments_count INTEGER NOT NULL DEFAULT 0,
    liked_by_user_ids TEXT[] NOT NULL DEFAULT '{}',
    is_reported BOOLEAN NOT NULL DEFAULT FALSE,
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_avatar TEXT,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    likes_count INTEGER NOT NULL DEFAULT 0,
    liked_by_user_ids TEXT[] NOT NULL DEFAULT '{}',
    is_reported BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_surah_verse ON posts(surah_number, verse_number) WHERE surah_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_pinned ON posts(is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for posts
-- Anyone can read non-reported posts
CREATE POLICY "Posts are viewable by everyone" 
    ON posts FOR SELECT 
    USING (is_reported = FALSE);

-- Users can create posts
CREATE POLICY "Users can create posts" 
    ON posts FOR INSERT 
    WITH CHECK (TRUE);

-- Users can update their own posts
CREATE POLICY "Users can update own posts" 
    ON posts FOR UPDATE 
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Users can delete their own posts
CREATE POLICY "Users can delete own posts" 
    ON posts FOR DELETE 
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- RLS Policies for comments
-- Anyone can read non-reported comments
CREATE POLICY "Comments are viewable by everyone" 
    ON comments FOR SELECT 
    USING (is_reported = FALSE);

-- Users can create comments
CREATE POLICY "Users can create comments" 
    ON comments FOR INSERT 
    WITH CHECK (TRUE);

-- Users can update their own comments
CREATE POLICY "Users can update own comments" 
    ON comments FOR UPDATE 
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments" 
    ON comments FOR DELETE 
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Function to increment comments count on posts
CREATE OR REPLACE FUNCTION increment_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts 
    SET comments_count = comments_count + 1 
    WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement comments count on posts
CREATE OR REPLACE FUNCTION decrement_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts 
    SET comments_count = comments_count - 1 
    WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic comment counting
CREATE TRIGGER trigger_increment_comments_count
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION increment_comments_count();

CREATE TRIGGER trigger_decrement_comments_count
    AFTER DELETE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION decrement_comments_count();
