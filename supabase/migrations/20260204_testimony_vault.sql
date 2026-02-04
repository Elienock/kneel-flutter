-- ============================================================================
-- Migration: Testimony Vault
-- Description: Tables for standalone testimonies, gratitude journal, and
--              answered prayer testimonies with full Supabase sync
-- Date: 2026-02-04
-- ============================================================================

-- Create testimonies table (unified for all testimony types)
CREATE TABLE IF NOT EXISTS public.testimonies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Type: 'standalone' (general testimony), 'gratitude', 'answered_prayer' (linked to prayer)
  type TEXT NOT NULL CHECK (type IN ('standalone', 'gratitude', 'answered_prayer')),

  -- Content
  title TEXT NOT NULL,
  story TEXT,

  -- For answered_prayer type - link to original prayer
  prayer_id UUID, -- Can't reference prayers table as it might not exist
  prayer_title TEXT, -- Cached for display
  prayer_count INT DEFAULT 0, -- How many times prayed before answered
  days_to_answer INT, -- Days from prayer creation to answer

  -- Dates
  event_date DATE, -- When the miracle/gratitude event happened
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Privacy & Sharing
  is_public BOOLEAN NOT NULL DEFAULT FALSE,
  shared_with_groups UUID[] DEFAULT '{}', -- Prayer group IDs to share with

  -- Optional media
  image_url TEXT,

  -- For gratitude entries - optional category
  category TEXT CHECK (category IN ('family', 'health', 'work', 'faith', 'provision', 'relationships', 'other') OR category IS NULL),

  -- Engagement (for public testimonies)
  celebration_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_testimonies_user_id ON public.testimonies(user_id);
CREATE INDEX IF NOT EXISTS idx_testimonies_type ON public.testimonies(type);
CREATE INDEX IF NOT EXISTS idx_testimonies_created_at ON public.testimonies(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_testimonies_is_public ON public.testimonies(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_testimonies_user_type ON public.testimonies(user_id, type);

-- Enable Row Level Security
ALTER TABLE public.testimonies ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own testimonies
CREATE POLICY "Users can view own testimonies" ON public.testimonies
  FOR SELECT USING (auth.uid() = user_id);

-- Users can view public testimonies from others
CREATE POLICY "Users can view public testimonies" ON public.testimonies
  FOR SELECT USING (is_public = true);

-- Users can insert their own testimonies
CREATE POLICY "Users can insert own testimonies" ON public.testimonies
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own testimonies
CREATE POLICY "Users can update own testimonies" ON public.testimonies
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own testimonies
CREATE POLICY "Users can delete own testimonies" ON public.testimonies
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- Testimony Stats Table (cached for performance)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.testimony_stats (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Counts by type
  total_testimonies INT NOT NULL DEFAULT 0,
  standalone_count INT NOT NULL DEFAULT 0,
  gratitude_count INT NOT NULL DEFAULT 0,
  answered_prayer_count INT NOT NULL DEFAULT 0,

  -- Public sharing stats
  public_count INT NOT NULL DEFAULT 0,
  total_celebrations INT NOT NULL DEFAULT 0,

  -- Streaks and patterns
  gratitude_streak INT NOT NULL DEFAULT 0, -- Consecutive days with gratitude entry
  longest_gratitude_streak INT NOT NULL DEFAULT 0,
  last_gratitude_date DATE,

  -- Timestamps
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on stats
ALTER TABLE public.testimony_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own testimony stats" ON public.testimony_stats
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own testimony stats" ON public.testimony_stats
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- Trigger to update stats after testimony changes
-- ============================================================================

CREATE OR REPLACE FUNCTION update_testimony_stats()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_today DATE := CURRENT_DATE;
  v_stats testimony_stats%ROWTYPE;
  v_new_streak INT;
BEGIN
  -- Get user_id from either NEW or OLD record
  v_user_id := COALESCE(NEW.user_id, OLD.user_id);

  -- Get or create stats row
  SELECT * INTO v_stats FROM testimony_stats WHERE user_id = v_user_id;

  IF NOT FOUND THEN
    INSERT INTO testimony_stats (user_id) VALUES (v_user_id);
    SELECT * INTO v_stats FROM testimony_stats WHERE user_id = v_user_id;
  END IF;

  -- Recalculate counts
  UPDATE testimony_stats SET
    total_testimonies = (SELECT COUNT(*) FROM testimonies WHERE user_id = v_user_id),
    standalone_count = (SELECT COUNT(*) FROM testimonies WHERE user_id = v_user_id AND type = 'standalone'),
    gratitude_count = (SELECT COUNT(*) FROM testimonies WHERE user_id = v_user_id AND type = 'gratitude'),
    answered_prayer_count = (SELECT COUNT(*) FROM testimonies WHERE user_id = v_user_id AND type = 'answered_prayer'),
    public_count = (SELECT COUNT(*) FROM testimonies WHERE user_id = v_user_id AND is_public = true),
    total_celebrations = (SELECT COALESCE(SUM(celebration_count), 0) FROM testimonies WHERE user_id = v_user_id),
    updated_at = NOW()
  WHERE user_id = v_user_id;

  -- Update gratitude streak if this is a gratitude entry
  IF (TG_OP = 'INSERT' AND NEW.type = 'gratitude') THEN
    IF v_stats.last_gratitude_date = v_today THEN
      -- Same day, no change to streak
      NULL;
    ELSIF v_stats.last_gratitude_date = v_today - 1 THEN
      -- Consecutive day, increment streak
      v_new_streak := v_stats.gratitude_streak + 1;
      UPDATE testimony_stats SET
        gratitude_streak = v_new_streak,
        longest_gratitude_streak = GREATEST(longest_gratitude_streak, v_new_streak),
        last_gratitude_date = v_today
      WHERE user_id = v_user_id;
    ELSE
      -- Streak broken or first entry, start new streak
      UPDATE testimony_stats SET
        gratitude_streak = 1,
        longest_gratitude_streak = GREATEST(longest_gratitude_streak, 1),
        last_gratitude_date = v_today
      WHERE user_id = v_user_id;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_testimony_stats ON public.testimonies;
CREATE TRIGGER trigger_update_testimony_stats
  AFTER INSERT OR UPDATE OR DELETE ON public.testimonies
  FOR EACH ROW
  EXECUTE FUNCTION update_testimony_stats();

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE public.testimonies IS 'Unified table for all testimony types: standalone testimonies, gratitude journal entries, and answered prayer testimonies';
COMMENT ON COLUMN public.testimonies.type IS 'Type of entry: standalone (general testimony), gratitude (thankfulness entry), answered_prayer (linked to prayer)';
COMMENT ON COLUMN public.testimonies.prayer_count IS 'For answered_prayer type: how many times the user prayed before receiving an answer';
COMMENT ON COLUMN public.testimonies.category IS 'For gratitude type: categorization of what user is grateful for';
COMMENT ON TABLE public.testimony_stats IS 'Cached statistics for testimony vault, auto-updated via trigger';
