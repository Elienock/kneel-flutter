-- ============================================================================
-- PRAYER SYSTEM COMPLETE SCHEMA
-- Run this single migration to set up the entire prayer persistence system
-- ============================================================================

-- ============================================================================
-- 1. PRAYERS TABLE (must be created first)
-- ============================================================================

CREATE TABLE IF NOT EXISTS prayers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  requester_name TEXT,

  -- Status tracking
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'answered', 'archived')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  is_locked BOOLEAN NOT NULL DEFAULT FALSE,

  -- Persistence tracking (Luke 18:1 - "pray and not give up")
  prayer_count INTEGER NOT NULL DEFAULT 0,
  times_prayed INTEGER NOT NULL DEFAULT 0,
  last_prayed_at TIMESTAMPTZ,

  -- Answered prayer tracking
  answered_at TIMESTAMPTZ,
  testimony TEXT,
  testimony_image_url TEXT,
  is_public_testimony BOOLEAN NOT NULL DEFAULT FALSE,

  -- Metadata
  tags TEXT[] DEFAULT '{}',
  scripture_reference TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prayers indexes
CREATE INDEX IF NOT EXISTS idx_prayers_user_id ON prayers(user_id);
CREATE INDEX IF NOT EXISTS idx_prayers_status ON prayers(status);
CREATE INDEX IF NOT EXISTS idx_prayers_user_status ON prayers(user_id, status);
CREATE INDEX IF NOT EXISTS idx_prayers_answered_at ON prayers(answered_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_prayers_created_at ON prayers(created_at DESC);

-- Enable RLS on prayers
ALTER TABLE prayers ENABLE ROW LEVEL SECURITY;

-- Prayers RLS Policies (drop if exists to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own prayers" ON prayers;
DROP POLICY IF EXISTS "Users can insert own prayers" ON prayers;
DROP POLICY IF EXISTS "Users can update own prayers" ON prayers;
DROP POLICY IF EXISTS "Users can delete own prayers" ON prayers;
DROP POLICY IF EXISTS "Users can view public testimonies" ON prayers;

CREATE POLICY "Users can view own prayers"
  ON prayers FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own prayers"
  ON prayers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own prayers"
  ON prayers FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own prayers"
  ON prayers FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view public testimonies"
  ON prayers FOR SELECT
  USING (
    is_public_testimony = TRUE
    AND status = 'answered'
    AND testimony IS NOT NULL
  );

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_prayers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_prayers_updated_at ON prayers;
CREATE TRIGGER trigger_prayers_updated_at
  BEFORE UPDATE ON prayers
  FOR EACH ROW
  EXECUTE FUNCTION update_prayers_updated_at();

-- Trigger to set answered_at when status changes to answered
CREATE OR REPLACE FUNCTION set_answered_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'answered' AND (OLD.status IS NULL OR OLD.status != 'answered') THEN
    NEW.answered_at = COALESCE(NEW.answered_at, NOW());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_answered_at ON prayers;
CREATE TRIGGER trigger_set_answered_at
  BEFORE UPDATE ON prayers
  FOR EACH ROW
  EXECUTE FUNCTION set_answered_at();

-- ============================================================================
-- 2. PRAYER LOGS TABLE (tracks individual prayer sessions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS prayer_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prayer_id UUID NOT NULL REFERENCES prayers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  duration_minutes INTEGER NOT NULL DEFAULT 1,
  actual_duration_seconds INTEGER,
  prayed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_manual BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prayer logs indexes
CREATE INDEX IF NOT EXISTS idx_prayer_logs_prayer_id ON prayer_logs(prayer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_logs_user_id ON prayer_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_prayer_logs_prayed_at ON prayer_logs(prayed_at DESC);
CREATE INDEX IF NOT EXISTS idx_prayer_logs_user_prayer ON prayer_logs(user_id, prayer_id);

-- Enable RLS on prayer_logs
ALTER TABLE prayer_logs ENABLE ROW LEVEL SECURITY;

-- Prayer logs RLS Policies
DROP POLICY IF EXISTS "Users can view own prayer logs" ON prayer_logs;
DROP POLICY IF EXISTS "Users can insert own prayer logs" ON prayer_logs;
DROP POLICY IF EXISTS "Users can update own prayer logs" ON prayer_logs;
DROP POLICY IF EXISTS "Users can delete own prayer logs" ON prayer_logs;

CREATE POLICY "Users can view own prayer logs"
  ON prayer_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own prayer logs"
  ON prayer_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own prayer logs"
  ON prayer_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own prayer logs"
  ON prayer_logs FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 3. FUNCTIONS
-- ============================================================================

-- Function to record a prayer session and update the prayer's times_prayed counter
CREATE OR REPLACE FUNCTION record_prayer_session(
  p_prayer_id UUID,
  p_user_id UUID,
  p_duration_minutes INTEGER,
  p_actual_duration_seconds INTEGER DEFAULT NULL,
  p_is_manual BOOLEAN DEFAULT FALSE,
  p_notes TEXT DEFAULT NULL,
  p_prayed_at TIMESTAMPTZ DEFAULT NOW()
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id UUID;
  v_new_count INTEGER;
  v_prayer RECORD;
BEGIN
  -- Verify the prayer exists and belongs to the user
  SELECT * INTO v_prayer
  FROM prayers
  WHERE id = p_prayer_id AND user_id = p_user_id;

  IF v_prayer IS NULL THEN
    RAISE EXCEPTION 'Prayer not found or access denied';
  END IF;

  -- Insert the prayer log
  INSERT INTO prayer_logs (
    prayer_id, user_id, duration_minutes, actual_duration_seconds,
    prayed_at, is_manual, notes
  ) VALUES (
    p_prayer_id, p_user_id, p_duration_minutes, p_actual_duration_seconds,
    p_prayed_at, p_is_manual, p_notes
  )
  RETURNING id INTO v_log_id;

  -- Increment the times_prayed counter
  UPDATE prayers
  SET
    times_prayed = times_prayed + 1,
    prayer_count = prayer_count + 1,
    last_prayed_at = p_prayed_at,
    updated_at = NOW()
  WHERE id = p_prayer_id
  RETURNING times_prayed INTO v_new_count;

  -- Also record in user_sessions for Insights integration (if table exists)
  BEGIN
    INSERT INTO user_sessions (
      user_id,
      session_type,
      duration_minutes,
      actual_duration_seconds,
      completed,
      note_id,
      created_at
    ) VALUES (
      p_user_id,
      'prayer',
      p_duration_minutes,
      p_actual_duration_seconds,
      TRUE,
      v_log_id::TEXT,
      p_prayed_at
    );
  EXCEPTION WHEN undefined_table THEN
    -- user_sessions table doesn't exist yet, skip
    NULL;
  END;

  RETURN json_build_object(
    'log_id', v_log_id,
    'times_prayed', v_new_count,
    'prayer_title', v_prayer.title
  );
END;
$$;

-- Function to get prayer session history for a specific prayer
CREATE OR REPLACE FUNCTION get_prayer_history(
  p_prayer_id UUID,
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  duration_minutes INTEGER,
  actual_duration_seconds INTEGER,
  prayed_at TIMESTAMPTZ,
  is_manual BOOLEAN,
  notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    pl.id,
    pl.duration_minutes,
    pl.actual_duration_seconds,
    pl.prayed_at,
    pl.is_manual,
    pl.notes
  FROM prayer_logs pl
  WHERE pl.prayer_id = p_prayer_id
    AND pl.user_id = p_user_id
  ORDER BY pl.prayed_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- Function to get persistence stats for a prayer
CREATE OR REPLACE FUNCTION get_prayer_persistence_stats(
  p_prayer_id UUID,
  p_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_sessions INTEGER;
  v_total_minutes INTEGER;
  v_manual_count INTEGER;
  v_first_prayed TIMESTAMPTZ;
  v_last_prayed TIMESTAMPTZ;
  v_longest_session INTEGER;
BEGIN
  SELECT
    COUNT(*)::INTEGER,
    COALESCE(SUM(duration_minutes), 0)::INTEGER,
    COUNT(*) FILTER (WHERE is_manual)::INTEGER,
    MIN(prayed_at),
    MAX(prayed_at),
    COALESCE(MAX(duration_minutes), 0)::INTEGER
  INTO
    v_total_sessions, v_total_minutes, v_manual_count,
    v_first_prayed, v_last_prayed, v_longest_session
  FROM prayer_logs
  WHERE prayer_id = p_prayer_id AND user_id = p_user_id;

  RETURN json_build_object(
    'total_sessions', v_total_sessions,
    'total_minutes', v_total_minutes,
    'manual_sessions', v_manual_count,
    'timed_sessions', v_total_sessions - v_manual_count,
    'first_prayed', v_first_prayed,
    'last_prayed', v_last_prayed,
    'longest_session_minutes', v_longest_session,
    'days_praying', CASE
      WHEN v_first_prayed IS NOT NULL AND v_last_prayed IS NOT NULL
      THEN EXTRACT(DAY FROM v_last_prayed - v_first_prayed)::INTEGER + 1
      ELSE 0
    END
  );
END;
$$;

-- ============================================================================
-- 4. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON prayers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON prayer_logs TO authenticated;
GRANT EXECUTE ON FUNCTION record_prayer_session TO authenticated;
GRANT EXECUTE ON FUNCTION get_prayer_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_prayer_persistence_stats TO authenticated;

-- ============================================================================
-- DONE! Prayer system is now ready.
-- ============================================================================
