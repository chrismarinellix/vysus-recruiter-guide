-- Allowed external emails whitelist (managed by admin)
CREATE TABLE IF NOT EXISTS allowed_external_emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  added_by UUID REFERENCES recruiter_profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE allowed_external_emails ENABLE ROW LEVEL SECURITY;

-- Anon users need to check if their email is allowed (before auth)
CREATE POLICY "Anyone can check allowed emails" ON allowed_external_emails
  FOR SELECT TO anon, authenticated USING (true);

-- Only admins can insert/update/delete
CREATE POLICY "Admins can manage external emails" ON allowed_external_emails
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM recruiter_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can delete external emails" ON allowed_external_emails
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM recruiter_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Admins can view all recruiter profiles (for User Logins tab)
CREATE POLICY "Admins can view all profiles" ON recruiter_profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM recruiter_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Update the new user trigger so only Chris is admin
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO recruiter_profiles (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    CASE
      WHEN NEW.email = 'chris.marinelli@vysusgroup.com'
      THEN 'admin'
      ELSE 'recruiter'
    END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Seed Jasmine as allowed external user
INSERT INTO allowed_external_emails (email, notes)
VALUES ('jasmine@designandbuild.com.au', 'Initial external recruiter')
ON CONFLICT (email) DO NOTHING;

-- Demote Jasmine from admin to recruiter if she was previously admin
UPDATE recruiter_profiles SET role = 'recruiter'
WHERE email = 'jasmine@designandbuild.com.au' AND role = 'admin';
