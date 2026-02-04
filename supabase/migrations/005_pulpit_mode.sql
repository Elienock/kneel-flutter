-- ============================================
-- PULPIT MODE - Public Prayer Leadership
-- ============================================
-- For leading congregational prayer sessions
-- from the pulpit/stage with structured prayer points

-- Prayer Groups (collections of prayer points for a session)
CREATE TABLE IF NOT EXISTS pulpit_prayer_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,

    -- Timer settings
    auto_advance BOOLEAN DEFAULT FALSE,
    seconds_per_point INTEGER DEFAULT 300, -- 5 minutes default

    -- Metadata
    times_used INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prayer Points (individual items within a group)
CREATE TABLE IF NOT EXISTS pulpit_prayer_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES pulpit_prayer_groups(id) ON DELETE CASCADE,

    -- Content
    title TEXT NOT NULL,
    description TEXT,

    -- Scripture references (stored as JSON array)
    -- Format: [{"reference": "John 3:16", "text": "For God so loved..."}, ...]
    scriptures JSONB DEFAULT '[]'::jsonb,

    -- Ordering
    sort_order INTEGER NOT NULL DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_pulpit_groups_user ON pulpit_prayer_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_pulpit_points_group ON pulpit_prayer_points(group_id);
CREATE INDEX IF NOT EXISTS idx_pulpit_points_order ON pulpit_prayer_points(group_id, sort_order);

-- Row Level Security
ALTER TABLE pulpit_prayer_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE pulpit_prayer_points ENABLE ROW LEVEL SECURITY;

-- Policies for pulpit_prayer_groups
CREATE POLICY "Users can view their own prayer groups"
    ON pulpit_prayer_groups FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own prayer groups"
    ON pulpit_prayer_groups FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own prayer groups"
    ON pulpit_prayer_groups FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own prayer groups"
    ON pulpit_prayer_groups FOR DELETE
    USING (auth.uid() = user_id);

-- Policies for pulpit_prayer_points
CREATE POLICY "Users can view points in their groups"
    ON pulpit_prayer_points FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM pulpit_prayer_groups
            WHERE id = pulpit_prayer_points.group_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create points in their groups"
    ON pulpit_prayer_points FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM pulpit_prayer_groups
            WHERE id = pulpit_prayer_points.group_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update points in their groups"
    ON pulpit_prayer_points FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM pulpit_prayer_groups
            WHERE id = pulpit_prayer_points.group_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete points in their groups"
    ON pulpit_prayer_points FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM pulpit_prayer_groups
            WHERE id = pulpit_prayer_points.group_id
            AND user_id = auth.uid()
        )
    );

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_pulpit_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS trigger_pulpit_groups_updated ON pulpit_prayer_groups;
CREATE TRIGGER trigger_pulpit_groups_updated
    BEFORE UPDATE ON pulpit_prayer_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_pulpit_updated_at();

DROP TRIGGER IF EXISTS trigger_pulpit_points_updated ON pulpit_prayer_points;
CREATE TRIGGER trigger_pulpit_points_updated
    BEFORE UPDATE ON pulpit_prayer_points
    FOR EACH ROW
    EXECUTE FUNCTION update_pulpit_updated_at();
