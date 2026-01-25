-- Vysus Recruiter Guide Database Schema
-- Run this in Supabase SQL Editor

-- 1. Recruiter profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS recruiter_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'recruiter' CHECK (role IN ('admin', 'recruiter')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ
);

-- 2. Previously interviewed candidates
CREATE TABLE IF NOT EXISTS interviewed_candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  last_contacted DATE,
  months_ago INTEGER,
  location TEXT,
  level TEXT, -- PSE, Engineer, Senior, Lead, Principal, Senior/Lead, Senior/Principal, Lead/Principal
  status TEXT CHECK (status IN ('Declined Offer', 'Not Progressed', 'Withdrew', 'May Revisit')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Resume uploads and AI analysis
CREATE TABLE IF NOT EXISTS resume_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uploaded_by UUID REFERENCES recruiter_profiles(id),
  candidate_name TEXT NOT NULL,
  candidate_email TEXT,
  resume_path TEXT,
  target_position TEXT CHECK (target_position IN ('Senior', 'Lead', 'Principal')),
  groq_analysis JSONB,
  matched_skills JSONB,
  overall_score INTEGER,
  recommendation TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Quiz submissions from candidates
CREATE TABLE IF NOT EXISTS quiz_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_name TEXT NOT NULL,
  candidate_email TEXT,
  score INTEGER,
  percentage INTEGER,
  time_taken TEXT,
  category_scores JSONB,
  answers JSONB,
  location TEXT,
  experience INTEGER,
  linkedin TEXT,
  motivation TEXT,
  resume_path TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Activity log
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES recruiter_profiles(id),
  user_email TEXT,
  action TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_interviewed_candidates_status ON interviewed_candidates(status);
CREATE INDEX IF NOT EXISTS idx_interviewed_candidates_level ON interviewed_candidates(level);
CREATE INDEX IF NOT EXISTS idx_interviewed_candidates_location ON interviewed_candidates(location);
CREATE INDEX IF NOT EXISTS idx_resume_analyses_uploaded_by ON resume_analyses(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON activity_log(created_at DESC);

-- Enable RLS
ALTER TABLE recruiter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE interviewed_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE resume_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Recruiter profiles: users can read their own profile
CREATE POLICY "Users can view own profile" ON recruiter_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON recruiter_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Interviewed candidates: all authenticated users can read
CREATE POLICY "Authenticated users can view candidates" ON interviewed_candidates
  FOR SELECT TO authenticated USING (true);

-- Admins can insert/update/delete candidates
CREATE POLICY "Admins can manage candidates" ON interviewed_candidates
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM recruiter_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Resume analyses: users can manage their own uploads
CREATE POLICY "Users can view own resume analyses" ON resume_analyses
  FOR SELECT USING (uploaded_by = auth.uid());

CREATE POLICY "Users can insert resume analyses" ON resume_analyses
  FOR INSERT WITH CHECK (uploaded_by = auth.uid());

CREATE POLICY "Users can update own resume analyses" ON resume_analyses
  FOR UPDATE USING (uploaded_by = auth.uid());

-- Admins can view all resume analyses
CREATE POLICY "Admins can view all resume analyses" ON resume_analyses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recruiter_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Quiz submissions: authenticated users can view all
CREATE POLICY "Authenticated users can view quiz submissions" ON quiz_submissions
  FOR SELECT TO authenticated USING (true);

-- Anyone can insert quiz submissions (for candidates taking the quiz)
CREATE POLICY "Anyone can insert quiz submissions" ON quiz_submissions
  FOR INSERT WITH CHECK (true);

-- Activity log: users can insert their own, admins can view all
CREATE POLICY "Users can insert own activity" ON activity_log
  FOR INSERT WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can view own activity" ON activity_log
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all activity" ON activity_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recruiter_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO recruiter_profiles (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    CASE
      WHEN NEW.email IN ('chris.marinelli@vysusgroup.com', 'jasmine@designandbuild.com.au')
      THEN 'admin'
      ELSE 'recruiter'
    END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
CREATE TRIGGER update_interviewed_candidates_updated_at
  BEFORE UPDATE ON interviewed_candidates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ================================================
-- SEED DATA: 124 Interviewed Candidates
-- ================================================

INSERT INTO interviewed_candidates (name, last_contacted, months_ago, location, level, status) VALUES
-- Declined Offer
('Maan Al-Alsad', '2023-09-01', 28, 'Melbourne', 'PSE', 'Declined Offer'),
('Yugal Kishore', '2025-04-01', 9, 'Melbourne', 'Principal', 'Not Progressed'),
('Lize-Marie Van Wyk', '2025-01-01', 12, 'Melbourne', 'Senior', 'Declined Offer'),
('Michael Magpantay', '2024-04-01', 21, 'Melbourne', 'PSE', 'Declined Offer'),
('Jonas Beltran', '2024-06-01', 18, 'Melbourne', 'PSE', 'Declined Offer'),
('Arvind Raghunathan', '2024-05-01', 20, 'Melbourne', 'Senior', 'Declined Offer'),
('Yahya Naderi', '2024-05-01', 20, 'Melbourne', 'PSE', 'Declined Offer'),
('Amin Jalilian', '2024-05-01', 20, 'Melbourne', 'PSE', 'Declined Offer'),
('Duong Tran', '2025-01-01', 12, 'Melbourne', 'PSE', 'Declined Offer'),
('Vishwa Upadhyay', '2025-03-01', 10, 'Melbourne', 'Senior', 'Declined Offer'),
('Rabia Attiq', '2025-05-01', 8, 'Melbourne', 'PSE', 'Declined Offer'),
('Dilhani Liyanage', '2024-07-01', 18, 'Melbourne', 'Engineer', 'Declined Offer'),
('Tin Dang', '2024-10-01', 15, 'Melbourne', 'PSE', 'Declined Offer'),
('Lakshmi Chinnamurugan', '2024-06-01', 18, 'Melbourne', 'PSE', 'Declined Offer'),
('Aravind Bathini', '2024-09-01', 16, 'Melbourne', 'PSE', 'Declined Offer'),
('Mayank Kumar', '2024-10-01', 15, 'Melbourne', 'Senior/Lead', 'Declined Offer'),
('Harish Chandrasekaran', '2025-05-01', 8, 'Melbourne', 'Senior', 'Declined Offer'),
('Anbarasu William', '2025-03-01', 10, 'Melbourne', 'Senior', 'Declined Offer'),
('Dr Germane Athanasius', '2025-03-01', 10, 'Melbourne', 'Senior', 'Declined Offer'),
('Nikhil Pathak', '2025-11-01', 2, 'Melbourne', 'Senior', 'Declined Offer'),
('Diego Alberto Murcia Fandino', '2024-11-01', 14, 'Europe', 'Senior', 'Declined Offer'),
('Antonio Luque', '2025-01-01', 12, 'Europe', 'Senior', 'Declined Offer'),
('Vamsi Krishna Sai Padmanabuni', '2024-07-01', 18, 'India', 'PSE', 'Declined Offer'),
('Upendran Mukundarajan', '2026-01-01', 0, 'India', 'Engineer', 'Declined Offer'),
('Tushar Patil', '2024-09-01', 16, 'India', 'PSE', 'Declined Offer'),
('Rajeesh CV', '2024-11-01', 14, 'India', 'Lead', 'Declined Offer'),
('Atikah Izzati Binti Abu Kahar', '2024-09-01', 15, 'Malaysia', 'PSE', 'Declined Offer'),
('Vishnu Charan', '2024-07-01', 18, 'India', 'Senior/Lead', 'Declined Offer'),
('Md Azmat Hussain', '2024-06-01', 18, 'India', 'PSE', 'Declined Offer'),
-- Not Progressed
('Ranjan Mohapatra', '2023-08-01', 29, 'Melbourne', 'Principal', 'Not Progressed'),
('Masoud Babazadeh', '2023-06-01', 30, 'Melbourne', 'PSE', 'Not Progressed'),
('Khaleel Ahmed', '2024-09-01', 16, 'Brisbane', 'Lead/Principal', 'Not Progressed'),
('Fuji Dinh', '2024-10-01', 15, 'Melbourne', 'Principal', 'Not Progressed'),
('Shezan Arefin', '2023-07-01', 30, 'Melbourne', 'Principal', 'Not Progressed'),
('Gian Garttan', '2024-10-01', 15, 'Perth', 'Senior', 'Not Progressed'),
('Parvez Akter', '2024-10-01', 15, 'Sydney', 'Senior', 'Not Progressed'),
('Hemant Parkash', '2024-11-01', 14, 'Melbourne', 'Senior', 'Not Progressed'),
('Najam Ali Osili', '2024-11-01', 14, 'Darwin/Brisbane', 'Principal', 'Not Progressed'),
('Murtaza Latif', '2024-11-01', 14, 'Melbourne', 'Principal', 'Not Progressed'),
('Prasoon Tripathi', '2024-11-01', 14, 'Brisbane', 'Senior/Principal', 'Not Progressed'),
('Travis Kenneth Beer', '2024-12-01', 13, 'Melbourne', 'Principal', 'Not Progressed'),
('Arash Zargham', '2024-12-01', 13, 'Perth', 'Principal', 'Not Progressed'),
('Soheil Bonakdar Hashemi', '2025-02-01', 11, 'Melbourne', 'Senior', 'Not Progressed'),
('Alex Mcleod', '2025-04-01', 9, 'Melbourne', 'Senior', 'Not Progressed'),
('Hassan Alhelou', '2025-07-01', 6, 'Melbourne', 'Senior', 'Not Progressed'),
('Travis Beer', '2025-07-01', 6, 'Melbourne', 'Senior', 'Not Progressed'),
('Amit Jyoti Datta', '2025-09-01', 4, 'Melbourne', 'Principal', 'Not Progressed'),
('Hashemi Ford', '2025-09-01', 4, 'Melbourne', 'Lead', 'Not Progressed'),
('Son Ho', '2024-11-01', 14, 'Melbourne', 'Senior', 'Not Progressed'),
('Usman Tayab', '2024-12-01', 13, 'Melbourne', 'Senior', 'Not Progressed'),
('Mohsin Ali', '2024-12-01', 13, 'Melbourne', 'Senior', 'Not Progressed'),
('MUHAMMAD KHALID', '2025-02-01', 11, 'Melbourne', 'Senior', 'Not Progressed'),
('Rajvikram Madurai Elavarasan', '2025-02-01', 11, 'Melbourne', 'Senior', 'Not Progressed'),
('Mohsen Eskandari', '2025-03-01', 10, 'Melbourne', 'Senior', 'Not Progressed'),
('Dilum Hettiarachchi', '2025-03-01', 10, 'Melbourne', 'Senior', 'Not Progressed'),
('Seyedali Meghdadi', '2025-03-01', 10, 'Melbourne', 'Senior', 'Not Progressed'),
('Muslem Udem', '2025-04-01', 9, 'Melbourne', 'Senior', 'Not Progressed'),
('Ray Cabatingan', '2025-05-01', 8, 'Melbourne', 'PSE', 'Not Progressed'),
('Venkatesan Balasubramanian', '2025-05-01', 8, 'Melbourne', 'PSE', 'Not Progressed'),
('Riku Chowdhury', '2025-06-01', 7, 'Melbourne', 'PSE', 'Not Progressed'),
('Mohsen Monfared', '2025-06-01', 7, 'Melbourne', 'Senior', 'Not Progressed'),
('Saad Abdul Basit', '2025-06-01', 7, 'Melbourne', 'PSE', 'Not Progressed'),
('Morteza Motazedian', '2025-08-01', 5, 'Melbourne', 'Senior', 'Not Progressed'),
('Saleh Forouhari', '2025-08-01', 5, 'Melbourne', 'PSE', 'Not Progressed'),
('Sruthi Mavalia', '2025-08-01', 5, 'Melbourne', 'PSE', 'Not Progressed'),
('Bilal Qadir', '2025-08-01', 5, 'Melbourne', 'PSE', 'Not Progressed'),
('Seion Emmanuel', '2025-09-01', 4, 'Melbourne', 'PSE', 'Not Progressed'),
('Mahdi Khase', '2025-09-01', 4, 'Melbourne', 'PSE', 'Not Progressed'),
('Parisa Ataeian', '2025-11-01', 2, 'Melbourne', 'Senior', 'Not Progressed'),
('Samaneh Sadat Sajjadi', '2024-07-01', 18, 'Melbourne', 'Senior', 'Not Progressed'),
('Afsar Ali Shaikh', '2024-07-01', 18, 'Brisbane', 'Senior', 'Not Progressed'),
('Krunal Soni', '2024-08-01', 17, 'Melbourne', 'Engineer', 'Not Progressed'),
('Sachinthala Fernando', '2024-09-01', 16, 'Melbourne', 'Engineer', 'Not Progressed'),
('Pratic Muntakim', '2024-09-01', 16, 'Sydney', 'Engineer', 'Not Progressed'),
('Nikhil Chaudhari', '2024-09-01', 16, 'Melbourne', 'Senior', 'Not Progressed'),
('Dinith Waduge', '2024-10-01', 15, 'Melbourne', 'Engineer', 'Not Progressed'),
('Ronak Shah', '2024-10-01', 15, 'Melbourne', 'Principal', 'Not Progressed'),
('Usman Bashir', '2024-11-01', 14, 'Melbourne', 'Senior', 'Not Progressed'),
('Jixin (Jason) Wang', '2024-12-01', 13, 'Melbourne', 'PSE', 'Not Progressed'),
('Pandiyan Chinnathambi', '2024-07-01', 18, 'India', 'Senior', 'Not Progressed'),
('Ajithkumar Sivaprakasam', '2024-08-01', 17, 'India', 'Senior', 'Not Progressed'),
('Gulshan Kumar', '2024-08-01', 17, 'India', 'Senior', 'Not Progressed'),
('Dr. Ramu Srikakulapu', '2024-10-01', 15, 'India', 'Senior', 'Not Progressed'),
('Shazeb Hashim Khan', '2024-10-01', 15, 'India', 'Senior', 'Not Progressed'),
('Raja Kuthalingam', '2024-10-01', 15, 'India', 'Principal', 'Not Progressed'),
('Valeti Ramesh Babu', '2024-10-01', 15, 'India', 'Lead', 'Not Progressed'),
('Shrinivas Kulgod', '2024-11-01', 14, 'India', 'Senior', 'Not Progressed'),
('Anand Prakasha', '2024-12-01', 13, 'India', 'Senior', 'Not Progressed'),
('Saravanan Balamurugan', '2024-11-01', 14, 'India', 'Lead', 'Not Progressed'),
('Amir Fazeli', '2024-10-01', 15, 'Europe', 'Principal', 'Not Progressed'),
('Nachiappan Muthiah', '2024-11-01', 14, 'Europe', 'Principal', 'Not Progressed'),
('Pere Santanach Carbonell', '2025-01-01', 12, 'Europe', 'Senior', 'Not Progressed'),
('Mitchel Leon', '2025-06-01', 7, 'Europe', 'Senior', 'Not Progressed'),
('Wan Husna Amira', '2024-09-01', 16, 'Malaysia', 'Engineer', 'Not Progressed'),
('Neethu Davis', '2024-09-01', 16, 'Adelaide', 'Engineer', 'Not Progressed'),
('Himali Lakshika', '2024-09-01', 16, 'Melbourne', 'Engineer', 'Not Progressed'),
('Mick Darren', '2025-10-01', 3, 'Malaysia', 'PSE', 'Not Progressed'),
('Saddiq Ridzwan', '2025-10-01', 3, 'Malaysia', 'PSE', 'Not Progressed'),
('Arif Fikri Othman', '2025-11-01', 2, 'Malaysia', 'PSE', 'Not Progressed'),
('Ir. Dr. Harriezan Ahmad', '2025-05-01', 8, 'Malaysia', 'Senior', 'Not Progressed'),
('HD Gowda', '2024-10-01', 15, 'South Africa', 'PSE', 'Not Progressed'),
('Azin Kalantar', '2024-08-01', 17, 'Melbourne', 'Engineer', 'Not Progressed'),
-- Withdrew
('Alexandra Baranski', '2024-07-01', 18, 'Brisbane', 'Senior', 'Withdrew'),
('Alazar Assefa', '2024-10-01', 15, 'Sydney', 'PSE', 'Withdrew'),
('Ralph Zhang', '2024-08-01', 17, 'Sydney', 'PSE', 'Withdrew'),
('Mojtaba Jabbari Ghadi', '2025-04-01', 9, 'Melbourne', 'Principal', 'Withdrew'),
('Mollah Rezaul Alam', '2025-08-01', 5, 'Melbourne', 'PSE', 'Withdrew'),
('Sumbal Gardezi', '2023-06-01', 30, 'Melbourne', 'PSE', 'Withdrew'),
('Filip Brnadic', '2023-09-01', 28, 'Melbourne', 'Senior/Principal', 'Withdrew'),
('Kashif Shad', '2024-06-01', 18, 'Melbourne', 'PSE', 'Withdrew'),
-- May Revisit
('Eranga Kudahewa', '2024-11-01', 14, 'New Zealand', 'Senior', 'May Revisit'),
('Mostafa Barzegar Kalashani', '2025-01-01', 12, 'Melbourne', 'PSE', 'May Revisit'),
('Komal Gaikwad-Kambli', '2024-11-01', 14, 'Melbourne', 'Senior/Lead', 'May Revisit'),
('Anupam Dixit', '2024-09-01', 16, 'Brisbane', 'Senior', 'May Revisit'),
('Nathanael Sims', '2024-08-01', 17, 'Europe', 'Senior', 'May Revisit'),
('Ayesha Viduranga', '2025-07-01', 6, 'Melbourne', 'Engineer', 'May Revisit'),
('Hossein Ranjbar', '2025-07-01', 6, 'Melbourne', 'Engineer', 'May Revisit'),
('Ha Thang', '2025-07-01', 6, 'Melbourne', 'Engineer', 'May Revisit'),
('Prashanti Gona', '2025-07-01', 6, 'India', 'PSE', 'May Revisit'),
('Arjun Divakar', '2025-08-01', 5, 'India', 'PSE', 'May Revisit'),
('Hamid Khoshkhoo', '2025-07-01', 6, 'Europe', 'PSE', 'May Revisit'),
('Santiago Barbero', '2025-08-01', 5, 'Europe', 'Senior', 'May Revisit');

-- Note: Mohsen Monfared and Saleh Forouhari appear in both "Not Progressed" and "May Revisit"
-- The above INSERT uses their "Not Progressed" entry. Add May Revisit notes if needed.
