-- Focus Sessions Table Migration
-- Tracks all focus/meditation/prayer sessions for the Focus feature
-- Linked to Insights for heatmap and streak calculations

-- Create enum type for focus activity types
CREATE TYPE focus_type AS ENUM (
  'bible_study',
  'meditation',
  'general_prayer',
  'specific_prayer',
  'worship',
  'journaling'
);

-- Create focus_sessions table
CREATE TABLE IF NOT EXISTS focus_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Session details
  type focus_type NOT NULL,
  planned_duration_minutes INT, -- NULL for open-ended sessions
  actual_duration_seconds INT NOT NULL DEFAULT 0,
  is_open_ended BOOLEAN NOT NULL DEFAULT FALSE,
  was_completed BOOLEAN NOT NULL DEFAULT TRUE,

  -- Prayer linking (for specific_prayer type)
  prayer_id UUID REFERENCES prayers(id) ON DELETE SET NULL,
  prayer_title TEXT, -- Cached for display even if prayer deleted

  -- Session timing
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  session_date DATE NOT NULL DEFAULT CURRENT_DATE, -- For efficient date queries

  -- Optional notes
  notes TEXT,

  -- Achievements earned in this session (stored as JSON array)
  achievements_earned JSONB DEFAULT '[]'::jsonb,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create focus_achievements table for tracking all-time unlocked achievements
CREATE TABLE IF NOT EXISTS focus_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_key TEXT NOT NULL, -- e.g., 'first_session', 'twenty_minutes', 'one_hour'
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  session_id UUID REFERENCES focus_sessions(id) ON DELETE SET NULL, -- Session that unlocked it

  UNIQUE(user_id, achievement_key)
);

-- Create focus_stats table for cached statistics (updated after each session)
CREATE TABLE IF NOT EXISTS focus_stats (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Time totals
  total_minutes_all_time INT NOT NULL DEFAULT 0,
  total_minutes_today INT NOT NULL DEFAULT 0,
  total_minutes_this_week INT NOT NULL DEFAULT 0,
  total_minutes_this_month INT NOT NULL DEFAULT 0,

  -- Session counts
  total_sessions INT NOT NULL DEFAULT 0,
  sessions_today INT NOT NULL DEFAULT 0,
  sessions_this_week INT NOT NULL DEFAULT 0,

  -- Streaks
  current_streak INT NOT NULL DEFAULT 0,
  longest_streak INT NOT NULL DEFAULT 0,
  last_session_date DATE,

  -- Personal bests
  longest_session_minutes INT NOT NULL DEFAULT 0,

  -- Minutes by type (JSON object)
  minutes_by_type JSONB DEFAULT '{}'::jsonb,

  -- Minutes by day of week (JSON object: {"0": 120, "1": 45, ...})
  minutes_by_day_of_week JSONB DEFAULT '{}'::jsonb,

  -- Timestamps
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX idx_focus_sessions_user_id ON focus_sessions(user_id);
CREATE INDEX idx_focus_sessions_session_date ON focus_sessions(session_date);
CREATE INDEX idx_focus_sessions_user_date ON focus_sessions(user_id, session_date);
CREATE INDEX idx_focus_sessions_type ON focus_sessions(type);
CREATE INDEX idx_focus_sessions_completed_at ON focus_sessions(completed_at);
CREATE INDEX idx_focus_achievements_user_id ON focus_achievements(user_id);

-- Row Level Security (RLS)
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_stats ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only access their own data
CREATE POLICY "Users can view own focus sessions"
  ON focus_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own focus sessions"
  ON focus_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own focus sessions"
  ON focus_sessions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own focus sessions"
  ON focus_sessions FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own achievements"
  ON focus_achievements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements"
  ON focus_achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own stats"
  ON focus_stats FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own stats"
  ON focus_stats FOR ALL
  USING (auth.uid() = user_id);

-- Function to update focus_stats after session insert
CREATE OR REPLACE FUNCTION update_focus_stats_after_session()
RETURNS TRIGGER AS $$
DECLARE
  today_date DATE := CURRENT_DATE;
  week_start DATE := date_trunc('week', CURRENT_DATE)::DATE;
  month_start DATE := date_trunc('month', CURRENT_DATE)::DATE;
  session_minutes INT;
  type_key TEXT;
  day_of_week INT;
  existing_stats focus_stats%ROWTYPE;
  new_streak INT;
BEGIN
  -- Calculate session minutes
  session_minutes := CEIL(NEW.actual_duration_seconds / 60.0);
  type_key := NEW.type::TEXT;
  day_of_week := EXTRACT(DOW FROM NEW.completed_at);

  -- Get or create stats row
  SELECT * INTO existing_stats FROM focus_stats WHERE user_id = NEW.user_id;

  IF NOT FOUND THEN
    -- Create new stats row
    INSERT INTO focus_stats (
      user_id,
      total_minutes_all_time,
      total_minutes_today,
      total_minutes_this_week,
      total_minutes_this_month,
      total_sessions,
      sessions_today,
      sessions_this_week,
      current_streak,
      longest_streak,
      last_session_date,
      longest_session_minutes,
      minutes_by_type,
      minutes_by_day_of_week
    ) VALUES (
      NEW.user_id,
      session_minutes,
      session_minutes,
      session_minutes,
      session_minutes,
      1,
      1,
      1,
      1,
      1,
      NEW.session_date,
      session_minutes,
      jsonb_build_object(type_key, session_minutes),
      jsonb_build_object(day_of_week::TEXT, session_minutes)
    );
  ELSE
    -- Calculate new streak
    IF existing_stats.last_session_date = today_date THEN
      -- Same day, streak unchanged
      new_streak := existing_stats.current_streak;
    ELSIF existing_stats.last_session_date = today_date - 1 THEN
      -- Consecutive day, increment streak
      new_streak := existing_stats.current_streak + 1;
    ELSE
      -- Streak broken, start new
      new_streak := 1;
    END IF;

    -- Update existing stats
    UPDATE focus_stats SET
      total_minutes_all_time = total_minutes_all_time + session_minutes,
      total_minutes_today = CASE
        WHEN last_session_date = today_date THEN total_minutes_today + session_minutes
        ELSE session_minutes
      END,
      total_minutes_this_week = CASE
        WHEN last_session_date >= week_start THEN total_minutes_this_week + session_minutes
        ELSE session_minutes
      END,
      total_minutes_this_month = CASE
        WHEN last_session_date >= month_start THEN total_minutes_this_month + session_minutes
        ELSE session_minutes
      END,
      total_sessions = total_sessions + 1,
      sessions_today = CASE
        WHEN last_session_date = today_date THEN sessions_today + 1
        ELSE 1
      END,
      sessions_this_week = CASE
        WHEN last_session_date >= week_start THEN sessions_this_week + 1
        ELSE 1
      END,
      current_streak = new_streak,
      longest_streak = GREATEST(longest_streak, new_streak),
      last_session_date = NEW.session_date,
      longest_session_minutes = GREATEST(longest_session_minutes, session_minutes),
      minutes_by_type = minutes_by_type || jsonb_build_object(
        type_key,
        COALESCE((minutes_by_type->>type_key)::INT, 0) + session_minutes
      ),
      minutes_by_day_of_week = minutes_by_day_of_week || jsonb_build_object(
        day_of_week::TEXT,
        COALESCE((minutes_by_day_of_week->>day_of_week::TEXT)::INT, 0) + session_minutes
      ),
      updated_at = NOW()
    WHERE user_id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update stats
CREATE TRIGGER trigger_update_focus_stats
  AFTER INSERT ON focus_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_focus_stats_after_session();

-- Function to reset daily/weekly/monthly stats (called by cron job)
CREATE OR REPLACE FUNCTION reset_periodic_focus_stats()
RETURNS void AS $$
DECLARE
  today_date DATE := CURRENT_DATE;
  week_start DATE := date_trunc('week', CURRENT_DATE)::DATE;
  month_start DATE := date_trunc('month', CURRENT_DATE)::DATE;
BEGIN
  -- Reset daily stats for users whose last session was not today
  UPDATE focus_stats
  SET
    total_minutes_today = 0,
    sessions_today = 0
  WHERE last_session_date < today_date;

  -- Reset weekly stats for users whose last session was before this week
  UPDATE focus_stats
  SET
    total_minutes_this_week = 0,
    sessions_this_week = 0
  WHERE last_session_date < week_start;

  -- Reset monthly stats for users whose last session was before this month
  UPDATE focus_stats
  SET total_minutes_this_month = 0
  WHERE last_session_date < month_start;

  -- Break streaks for users who missed yesterday
  UPDATE focus_stats
  SET current_streak = 0
  WHERE last_session_date < today_date - 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment for documentation
COMMENT ON TABLE focus_sessions IS 'Tracks focus/meditation/prayer sessions for the Focus feature with full analytics';
COMMENT ON TABLE focus_achievements IS 'Tracks unlocked achievements for gamification';
COMMENT ON TABLE focus_stats IS 'Cached statistics for fast retrieval, auto-updated via trigger';
