-- Screening Results table for storing recruiter screening assessments
CREATE TABLE IF NOT EXISTS screening_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screened_by UUID REFERENCES recruiter_profiles(id),
  screened_by_email TEXT,
  candidate_name TEXT NOT NULL,
  confidence_score INTEGER,
  leadership_score INTEGER,
  technical_score INTEGER,
  total_score INTEGER,
  max_score INTEGER DEFAULT 45,
  percentage INTEGER,
  pass_fail TEXT,
  question_scores JSONB,
  strengths JSONB,
  concerns JSONB,
  recommended_level TEXT,
  reasoning TEXT,
  caution TEXT,
  previously_interviewed BOOLEAN DEFAULT FALSE,
  interview_history JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_screening_results_screened_by ON screening_results(screened_by);
CREATE INDEX IF NOT EXISTS idx_screening_results_candidate ON screening_results(candidate_name);
CREATE INDEX IF NOT EXISTS idx_screening_results_created_at ON screening_results(created_at DESC);

-- Enable RLS
ALTER TABLE screening_results ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can insert screening results" ON screening_results
  FOR INSERT WITH CHECK (screened_by = auth.uid());

CREATE POLICY "Users can view own screening results" ON screening_results
  FOR SELECT USING (screened_by = auth.uid());

CREATE POLICY "Admins can view all screening results" ON screening_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recruiter_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
