-- ============================================================================
-- Migration: Add Focus Session Types
-- Description: Adds new session types for Focus feature (worship, journaling, specificPrayer)
-- Date: 2026-02-04
-- ============================================================================

-- Drop the existing constraint and add a new one with more types
ALTER TABLE public.user_sessions
DROP CONSTRAINT IF EXISTS user_sessions_type_check;

ALTER TABLE public.user_sessions
ADD CONSTRAINT user_sessions_type_check
CHECK (type IN ('prayer', 'bibleStudy', 'meditation', 'sermonPrep', 'worship', 'journaling', 'specificPrayer'));

-- Update comment
COMMENT ON COLUMN public.user_sessions.type IS 'Session type: prayer, bibleStudy, meditation, sermonPrep, worship, journaling, specificPrayer';
