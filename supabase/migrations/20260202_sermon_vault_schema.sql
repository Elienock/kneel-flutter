-- ============================================================================
-- SERMON VAULT DATABASE SCHEMA
-- Digital Sanctuary - Production-Ready Schema
-- ============================================================================

-- ============================================================================
-- TABLE: sermon_series (Folders/Collections)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sermon_series (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#673AB7',
    icon TEXT DEFAULT 'folder',
    cover_image TEXT, -- URL to cover image in storage
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sermon_series_user_id ON public.sermon_series(user_id);
CREATE INDEX IF NOT EXISTS idx_sermon_series_sort_order ON public.sermon_series(sort_order);

-- ============================================================================
-- TABLE: sermon_notes (Individual Sermon Notes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sermon_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    series_id UUID REFERENCES public.sermon_series(id) ON DELETE SET NULL,
    title TEXT NOT NULL DEFAULT 'Untitled',
    preacher TEXT NOT NULL DEFAULT 'Unknown',
    verse TEXT, -- Bible reference (e.g., "John 3:16")
    content TEXT DEFAULT '',
    sermon_date DATE DEFAULT CURRENT_DATE,
    is_pinned BOOLEAN DEFAULT FALSE,
    tags TEXT[] DEFAULT '{}',
    -- Offline sync metadata
    local_id TEXT, -- Client-generated ID for offline-first
    sync_status TEXT DEFAULT 'synced', -- 'synced', 'pending', 'conflict'
    last_synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sermon_notes_user_id ON public.sermon_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_sermon_notes_series_id ON public.sermon_notes(series_id);
CREATE INDEX IF NOT EXISTS idx_sermon_notes_sermon_date ON public.sermon_notes(sermon_date DESC);
CREATE INDEX IF NOT EXISTS idx_sermon_notes_is_pinned ON public.sermon_notes(is_pinned);
CREATE INDEX IF NOT EXISTS idx_sermon_notes_local_id ON public.sermon_notes(local_id);

-- Full-text search index
CREATE INDEX IF NOT EXISTS idx_sermon_notes_fts ON public.sermon_notes
    USING GIN (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(preacher, '') || ' ' || coalesce(verse, '') || ' ' || coalesce(content, '')));

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Users can only access their own data
-- ============================================================================

-- Enable RLS on tables
ALTER TABLE public.sermon_series ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sermon_notes ENABLE ROW LEVEL SECURITY;

-- sermon_series policies
DROP POLICY IF EXISTS "Users can view own series" ON public.sermon_series;
CREATE POLICY "Users can view own series" ON public.sermon_series
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own series" ON public.sermon_series;
CREATE POLICY "Users can insert own series" ON public.sermon_series
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own series" ON public.sermon_series;
CREATE POLICY "Users can update own series" ON public.sermon_series
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own series" ON public.sermon_series;
CREATE POLICY "Users can delete own series" ON public.sermon_series
    FOR DELETE USING (auth.uid() = user_id);

-- sermon_notes policies
DROP POLICY IF EXISTS "Users can view own notes" ON public.sermon_notes;
CREATE POLICY "Users can view own notes" ON public.sermon_notes
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own notes" ON public.sermon_notes;
CREATE POLICY "Users can insert own notes" ON public.sermon_notes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notes" ON public.sermon_notes;
CREATE POLICY "Users can update own notes" ON public.sermon_notes
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own notes" ON public.sermon_notes;
CREATE POLICY "Users can delete own notes" ON public.sermon_notes
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- TRIGGER: Auto-update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_sermon_series_updated_at ON public.sermon_series;
CREATE TRIGGER update_sermon_series_updated_at
    BEFORE UPDATE ON public.sermon_series
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sermon_notes_updated_at ON public.sermon_notes;
CREATE TRIGGER update_sermon_notes_updated_at
    BEFORE UPDATE ON public.sermon_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEW: Series with note counts (for efficient folder listing)
-- ============================================================================
CREATE OR REPLACE VIEW public.sermon_series_with_counts AS
SELECT
    s.*,
    COUNT(n.id) AS note_count,
    MAX(n.updated_at) AS last_note_updated
FROM public.sermon_series s
LEFT JOIN public.sermon_notes n ON n.series_id = s.id
GROUP BY s.id
ORDER BY s.sort_order ASC;

-- ============================================================================
-- FUNCTION: Search sermon notes (full-text search)
-- ============================================================================
CREATE OR REPLACE FUNCTION search_sermon_notes(
    p_user_id UUID,
    p_query TEXT
)
RETURNS SETOF public.sermon_notes AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.sermon_notes
    WHERE user_id = p_user_id
      AND (
          title ILIKE '%' || p_query || '%'
          OR preacher ILIKE '%' || p_query || '%'
          OR verse ILIKE '%' || p_query || '%'
          OR content ILIKE '%' || p_query || '%'
      )
    ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STORAGE BUCKET: Sermon covers and attachments
-- ============================================================================
-- Note: Run this in the Supabase dashboard or via API
-- INSERT INTO storage.buckets (id, name, public) VALUES ('sermon-covers', 'sermon-covers', false);

-- Storage policies for sermon covers
-- CREATE POLICY "Users can upload own covers"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--     bucket_id = 'sermon-covers'
--     AND auth.uid()::text = (storage.foldername(name))[1]
-- );

-- CREATE POLICY "Users can view own covers"
-- ON storage.objects FOR SELECT
-- USING (
--     bucket_id = 'sermon-covers'
--     AND auth.uid()::text = (storage.foldername(name))[1]
-- );

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sermon_series TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sermon_notes TO authenticated;
GRANT SELECT ON public.sermon_series_with_counts TO authenticated;
GRANT EXECUTE ON FUNCTION search_sermon_notes TO authenticated;
