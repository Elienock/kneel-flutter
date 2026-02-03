-- ============================================================================
-- Migration: User Sessions and Insights
-- Description: Adds user_sessions table for tracking Sacred Time sessions
--              and updates profiles table with streak/answered prayer fields
-- Date: 2026-02-02
-- ============================================================================

-- Add new columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS answered_prayers_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;

-- Create user_sessions table for tracking Sacred Time sessions
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('prayer', 'bibleStudy', 'meditation', 'sermonPrep')),
    duration_minutes INTEGER NOT NULL,
    actual_duration_seconds INTEGER NOT NULL DEFAULT 0,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed BOOLEAN NOT NULL DEFAULT true,
    prayer_answered BOOLEAN NOT NULL DEFAULT false,
    note_id UUID REFERENCES public.sermon_notes(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_date ON public.user_sessions(session_date);
CREATE INDEX IF NOT EXISTS idx_user_sessions_type ON public.user_sessions(type);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_date ON public.user_sessions(user_id, session_date);

-- Enable Row Level Security
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_sessions
-- Users can only see their own sessions
CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own sessions
CREATE POLICY "Users can insert own sessions" ON public.user_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own sessions
CREATE POLICY "Users can update own sessions" ON public.user_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own sessions
CREATE POLICY "Users can delete own sessions" ON public.user_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Function to calculate current streak for a user
CREATE OR REPLACE FUNCTION calculate_user_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_streak INTEGER := 0;
    v_check_date DATE := CURRENT_DATE;
    v_has_session BOOLEAN;
BEGIN
    -- Check if user has session today
    SELECT EXISTS(
        SELECT 1 FROM public.user_sessions
        WHERE user_id = p_user_id AND session_date = v_check_date
    ) INTO v_has_session;

    -- If no session today, start checking from yesterday
    IF NOT v_has_session THEN
        -- Check if there was a session yesterday
        SELECT EXISTS(
            SELECT 1 FROM public.user_sessions
            WHERE user_id = p_user_id AND session_date = v_check_date - 1
        ) INTO v_has_session;

        IF NOT v_has_session THEN
            RETURN 0;
        END IF;
        v_check_date := v_check_date - 1;
    END IF;

    -- Count consecutive days with sessions
    WHILE v_has_session LOOP
        v_streak := v_streak + 1;
        v_check_date := v_check_date - 1;

        SELECT EXISTS(
            SELECT 1 FROM public.user_sessions
            WHERE user_id = p_user_id AND session_date = v_check_date
        ) INTO v_has_session;
    END LOOP;

    RETURN v_streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update streak after session insert
CREATE OR REPLACE FUNCTION update_streak_on_session()
RETURNS TRIGGER AS $$
DECLARE
    v_new_streak INTEGER;
BEGIN
    -- Calculate new streak
    v_new_streak := calculate_user_streak(NEW.user_id);

    -- Update profile
    UPDATE public.profiles
    SET
        current_streak = v_new_streak,
        longest_streak = GREATEST(longest_streak, v_new_streak),
        updated_at = NOW()
    WHERE id = NEW.user_id;

    -- If prayer was answered, increment counter
    IF NEW.prayer_answered THEN
        UPDATE public.profiles
        SET
            answered_prayers_count = answered_prayers_count + 1,
            updated_at = NOW()
        WHERE id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_streak_on_session ON public.user_sessions;
CREATE TRIGGER trigger_update_streak_on_session
    AFTER INSERT ON public.user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_streak_on_session();

-- ============================================================================
-- Comments
-- ============================================================================
COMMENT ON TABLE public.user_sessions IS 'Tracks Sacred Time sessions for insights and streaks';
COMMENT ON COLUMN public.user_sessions.type IS 'Session type: prayer, bibleStudy, meditation, sermonPrep';
COMMENT ON COLUMN public.user_sessions.duration_minutes IS 'Intended session duration in minutes';
COMMENT ON COLUMN public.user_sessions.actual_duration_seconds IS 'Actual time spent in seconds';
COMMENT ON COLUMN public.user_sessions.completed IS 'Whether the session was completed or exited early';
COMMENT ON COLUMN public.user_sessions.prayer_answered IS 'For prayer sessions, whether marked as answered';
COMMENT ON COLUMN public.profiles.answered_prayers_count IS 'Total count of prayers marked as answered';
COMMENT ON COLUMN public.profiles.current_streak IS 'Current consecutive days with sessions';
COMMENT ON COLUMN public.profiles.longest_streak IS 'Best streak ever achieved';
