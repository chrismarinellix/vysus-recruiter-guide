-- Add Potential Candidates Support
-- Run this in Supabase SQL Editor after fix-rls-recursion.sql
-- Created: 2026-01-29

-- ========================================
-- 1. Add new statuses for potential candidates
-- ========================================

-- Drop the existing constraint and add new one with more statuses
ALTER TABLE interviewed_candidates
DROP CONSTRAINT IF EXISTS interviewed_candidates_status_check;

ALTER TABLE interviewed_candidates
ADD CONSTRAINT interviewed_candidates_status_check
CHECK (status IN (
  'Potential',           -- New: from resume upload
  'Screening',           -- New: in screening process
  'Interview Scheduled', -- New: interview scheduled
  'Declined Offer',
  'Not Progressed',
  'Withdrew',
  'May Revisit'
));

-- ========================================
-- 2. Add source tracking column
-- ========================================

ALTER TABLE interviewed_candidates
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual'
CHECK (source IN ('manual', 'resume_upload', 'import'));

ALTER TABLE interviewed_candidates
ADD COLUMN IF NOT EXISTS email TEXT;

ALTER TABLE interviewed_candidates
ADD COLUMN IF NOT EXISTS resume_analysis_id UUID REFERENCES resume_analyses(id);

ALTER TABLE interviewed_candidates
ADD COLUMN IF NOT EXISTS target_position TEXT;

ALTER TABLE interviewed_candidates
ADD COLUMN IF NOT EXISTS analysis_score INTEGER;

-- ========================================
-- 3. Create index for faster lookups
-- ========================================

CREATE INDEX IF NOT EXISTS idx_candidates_email ON interviewed_candidates(email);
CREATE INDEX IF NOT EXISTS idx_candidates_source ON interviewed_candidates(source);

-- ========================================
-- 4. Update existing records to have source='manual'
-- ========================================

UPDATE interviewed_candidates SET source = 'manual' WHERE source IS NULL;

-- ========================================
-- 5. Function to add candidate from resume analysis
-- ========================================

CREATE OR REPLACE FUNCTION add_candidate_from_resume(
  p_name TEXT,
  p_email TEXT,
  p_location TEXT,
  p_level TEXT,
  p_resume_analysis_id UUID,
  p_analysis_score INTEGER
)
RETURNS UUID AS $$
DECLARE
  v_candidate_id UUID;
BEGIN
  -- Check if candidate already exists by name (case insensitive)
  SELECT id INTO v_candidate_id
  FROM interviewed_candidates
  WHERE LOWER(name) = LOWER(p_name)
  LIMIT 1;

  IF v_candidate_id IS NOT NULL THEN
    -- Update existing candidate with new analysis
    UPDATE interviewed_candidates SET
      email = COALESCE(p_email, email),
      resume_analysis_id = p_resume_analysis_id,
      analysis_score = p_analysis_score,
      updated_at = NOW()
    WHERE id = v_candidate_id;
  ELSE
    -- Insert new candidate
    INSERT INTO interviewed_candidates (
      name, email, location, level, status, source,
      resume_analysis_id, analysis_score, last_contacted
    ) VALUES (
      p_name, p_email, p_location, p_level, 'Potential', 'resume_upload',
      p_resume_analysis_id, p_analysis_score, CURRENT_DATE
    )
    RETURNING id INTO v_candidate_id;
  END IF;

  RETURN v_candidate_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION add_candidate_from_resume TO authenticated;

-- ========================================
-- 6. Verify
-- ========================================

-- Check table structure
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'interviewed_candidates';

-- Check constraint
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'interviewed_candidates'::regclass;
