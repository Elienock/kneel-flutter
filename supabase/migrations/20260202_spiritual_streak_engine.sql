-- ============================================================================
-- Migration: Spiritual Streak Engine
-- Description: Complete streak tracking system with user_stats table
--              and update_user_streak PostgreSQL function
-- Date: 2026-02-02
-- ============================================================================

-- ============================================================================
-- USER STATS TABLE
-- ============================================================================

-- Create user_stats table for dedicated streak tracking
CREATE TABLE IF NOT EXISTS public.user_stats (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    current_streak INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_activity_date DATE,
    total_sessions INTEGER NOT NULL DEFAULT 0,
    total_minutes INTEGER NOT NULL DEFAULT 0,
    answered_prayers INTEGER NOT NULL DEFAULT 0,
    prayer_sessions INTEGER NOT NULL DEFAULT 0,
    study_sessions INTEGER NOT NULL DEFAULT 0,
    meditation_sessions INTEGER NOT NULL DEFAULT 0,
    sermon_prep_sessions INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own stats" ON public.user_stats
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own stats" ON public.user_stats
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert stats" ON public.user_stats
    FOR INSERT WITH CHECK (true);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_stats_last_activity ON public.user_stats(last_activity_date);

-- ============================================================================
-- UPDATE USER STREAK FUNCTION
-- ============================================================================

-- Main function to update user streak with proper logic
CREATE OR REPLACE FUNCTION update_user_streak(p_user_id UUID, p_session_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    new_streak INTEGER,
    previous_streak INTEGER,
    is_new_streak BOOLEAN,
    streak_increased BOOLEAN,
    streak_message TEXT
) AS $$
DECLARE
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_last_activity DATE;
    v_new_streak INTEGER;
    v_days_since_last INTEGER;
    v_is_new_streak BOOLEAN := FALSE;
    v_streak_increased BOOLEAN := FALSE;
    v_message TEXT;
BEGIN
    -- Get or create user stats
    INSERT INTO public.user_stats (user_id, current_streak, longest_streak, last_activity_date)
    VALUES (p_user_id, 0, 0, NULL)
    ON CONFLICT (user_id) DO NOTHING;

    -- Get current stats
    SELECT current_streak, longest_streak, last_activity_date
    INTO v_current_streak, v_longest_streak, v_last_activity
    FROM public.user_stats
    WHERE user_id = p_user_id;

    -- Calculate days since last activity
    IF v_last_activity IS NULL THEN
        -- First ever session
        v_new_streak := 1;
        v_is_new_streak := TRUE;
        v_streak_increased := TRUE;
        v_message := 'Your spiritual journey begins today!';
    ELSIF v_last_activity = p_session_date THEN
        -- Already had activity today - no change
        v_new_streak := v_current_streak;
        v_message := 'Keep going! Day ' || v_new_streak || ' continues.';
    ELSIF v_last_activity = p_session_date - 1 THEN
        -- Activity was yesterday - increment streak!
        v_new_streak := v_current_streak + 1;
        v_streak_increased := TRUE;
        IF v_new_streak > v_longest_streak THEN
            v_message := 'New record! Day ' || v_new_streak || '!';
        ELSE
            v_message := 'Day ' || v_new_streak || '! Keep the fire burning!';
        END IF;
    ELSE
        -- More than 24 hours gap - reset streak to 1
        v_days_since_last := p_session_date - v_last_activity;
        v_new_streak := 1;
        v_is_new_streak := TRUE;
        v_streak_increased := TRUE;
        IF v_current_streak > 0 THEN
            v_message := 'New streak started! Welcome back, warrior.';
        ELSE
            v_message := 'Day 1! A new beginning.';
        END IF;
    END IF;

    -- Update the stats
    UPDATE public.user_stats
    SET
        current_streak = v_new_streak,
        longest_streak = GREATEST(v_longest_streak, v_new_streak),
        last_activity_date = p_session_date,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Also update profiles table for backward compatibility
    UPDATE public.profiles
    SET
        current_streak = v_new_streak,
        longest_streak = GREATEST(COALESCE(longest_streak, 0), v_new_streak),
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Return results
    RETURN QUERY SELECT
        v_new_streak,
        v_current_streak,
        v_is_new_streak,
        v_streak_increased,
        v_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ENHANCED TRIGGER FOR SESSION INSERT
-- ============================================================================

-- Enhanced trigger function that updates all stats
CREATE OR REPLACE FUNCTION on_session_created()
RETURNS TRIGGER AS $$
DECLARE
    v_streak_result RECORD;
BEGIN
    -- Update streak using our function
    SELECT * INTO v_streak_result FROM update_user_streak(NEW.user_id, NEW.session_date);

    -- Update session type counts and totals
    UPDATE public.user_stats
    SET
        total_sessions = total_sessions + 1,
        total_minutes = total_minutes + NEW.duration_minutes,
        answered_prayers = answered_prayers + CASE WHEN NEW.prayer_answered THEN 1 ELSE 0 END,
        prayer_sessions = prayer_sessions + CASE WHEN NEW.type = 'prayer' THEN 1 ELSE 0 END,
        study_sessions = study_sessions + CASE WHEN NEW.type = 'bibleStudy' THEN 1 ELSE 0 END,
        meditation_sessions = meditation_sessions + CASE WHEN NEW.type = 'meditation' THEN 1 ELSE 0 END,
        sermon_prep_sessions = sermon_prep_sessions + CASE WHEN NEW.type = 'sermonPrep' THEN 1 ELSE 0 END,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;

    -- Update profile answered prayers count
    IF NEW.prayer_answered THEN
        UPDATE public.profiles
        SET
            answered_prayers_count = COALESCE(answered_prayers_count, 0) + 1,
            updated_at = NOW()
        WHERE id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old trigger and create new one
DROP TRIGGER IF EXISTS trigger_update_streak_on_session ON public.user_sessions;
DROP TRIGGER IF EXISTS trigger_on_session_created ON public.user_sessions;

CREATE TRIGGER trigger_on_session_created
    AFTER INSERT ON public.user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION on_session_created();

-- ============================================================================
-- HELPER FUNCTIONS FOR HEATMAP
-- ============================================================================

-- Get activity data for heatmap (last N days)
CREATE OR REPLACE FUNCTION get_activity_heatmap(p_user_id UUID, p_days INTEGER DEFAULT 365)
RETURNS TABLE(
    activity_date DATE,
    session_count INTEGER,
    total_minutes INTEGER,
    session_types TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        us.session_date,
        COUNT(*)::INTEGER as session_count,
        SUM(us.duration_minutes)::INTEGER as total_minutes,
        ARRAY_AGG(DISTINCT us.type) as session_types
    FROM public.user_sessions us
    WHERE us.user_id = p_user_id
      AND us.session_date >= CURRENT_DATE - p_days
    GROUP BY us.session_date
    ORDER BY us.session_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get comprehensive user stats
CREATE OR REPLACE FUNCTION get_user_insights(p_user_id UUID)
RETURNS TABLE(
    current_streak INTEGER,
    longest_streak INTEGER,
    last_activity_date DATE,
    total_sessions INTEGER,
    total_minutes INTEGER,
    answered_prayers INTEGER,
    sessions_this_week INTEGER,
    sessions_this_month INTEGER,
    avg_session_minutes NUMERIC,
    most_active_day TEXT
) AS $$
BEGIN
    -- Ensure user_stats exists
    INSERT INTO public.user_stats (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN QUERY
    SELECT
        us.current_streak,
        us.longest_streak,
        us.last_activity_date,
        us.total_sessions,
        us.total_minutes,
        us.answered_prayers,
        (SELECT COUNT(*)::INTEGER FROM public.user_sessions
         WHERE user_id = p_user_id
         AND session_date >= CURRENT_DATE - 7) as sessions_this_week,
        (SELECT COUNT(*)::INTEGER FROM public.user_sessions
         WHERE user_id = p_user_id
         AND session_date >= CURRENT_DATE - 30) as sessions_this_month,
        COALESCE(
            (SELECT AVG(duration_minutes)::NUMERIC(10,1) FROM public.user_sessions WHERE user_id = p_user_id),
            0
        ) as avg_session_minutes,
        COALESCE(
            (SELECT TO_CHAR(session_date, 'Day')
             FROM public.user_sessions
             WHERE user_id = p_user_id
             GROUP BY session_date, TO_CHAR(session_date, 'Day')
             ORDER BY COUNT(*) DESC
             LIMIT 1),
            'None yet'
        ) as most_active_day
    FROM public.user_stats us
    WHERE us.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE public.user_stats IS 'Dedicated streak and activity statistics for each user';
COMMENT ON FUNCTION update_user_streak IS 'Updates user streak based on activity date, returns streak change info';
COMMENT ON FUNCTION get_activity_heatmap IS 'Returns activity data for GitHub-style contribution heatmap';
COMMENT ON FUNCTION get_user_insights IS 'Returns comprehensive user statistics for the Insight page';
