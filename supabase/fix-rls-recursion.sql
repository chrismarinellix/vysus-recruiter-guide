-- Fix RLS Infinite Recursion on recruiter_profiles
-- Run this in Supabase SQL Editor
-- Created: 2026-01-29

-- ========================================
-- 1. Create SECURITY DEFINER function to check admin status
--    This bypasses RLS so it won't cause recursion
-- ========================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.recruiter_profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ========================================
-- 2. Drop existing policies that cause recursion
-- ========================================

-- recruiter_profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON recruiter_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON recruiter_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON recruiter_profiles;

-- activity_log policies
DROP POLICY IF EXISTS "Users can insert own activity" ON activity_log;
DROP POLICY IF EXISTS "Users can view own activity" ON activity_log;
DROP POLICY IF EXISTS "Admins can view all activity" ON activity_log;

-- resume_analyses policies
DROP POLICY IF EXISTS "Users can view own resume analyses" ON resume_analyses;
DROP POLICY IF EXISTS "Users can insert resume analyses" ON resume_analyses;
DROP POLICY IF EXISTS "Users can update own resume analyses" ON resume_analyses;
DROP POLICY IF EXISTS "Admins can view all resume analyses" ON resume_analyses;

-- interviewed_candidates policies
DROP POLICY IF EXISTS "Authenticated users can view candidates" ON interviewed_candidates;
DROP POLICY IF EXISTS "Admins can manage candidates" ON interviewed_candidates;

-- ========================================
-- 3. Recreate policies using is_admin() function
-- ========================================

-- RECRUITER_PROFILES: Users can view own profile
CREATE POLICY "Users can view own profile" ON recruiter_profiles
  FOR SELECT USING (auth.uid() = id);

-- RECRUITER_PROFILES: Users can update own profile
CREATE POLICY "Users can update own profile" ON recruiter_profiles
  FOR UPDATE USING (auth.uid() = id);

-- RECRUITER_PROFILES: Admins can view ALL profiles (uses function)
CREATE POLICY "Admins can view all profiles" ON recruiter_profiles
  FOR SELECT USING (public.is_admin());

-- ACTIVITY_LOG: Anyone can insert activity (anonymous or authenticated)
CREATE POLICY "Anyone can insert activity" ON activity_log
  FOR INSERT WITH CHECK (true);

-- ACTIVITY_LOG: Users can view their own activity
CREATE POLICY "Users can view own activity" ON activity_log
  FOR SELECT USING (user_id = auth.uid());

-- ACTIVITY_LOG: Admins can view ALL activity (uses function)
CREATE POLICY "Admins can view all activity" ON activity_log
  FOR SELECT USING (public.is_admin());

-- RESUME_ANALYSES: Users can view their own
CREATE POLICY "Users can view own resume analyses" ON resume_analyses
  FOR SELECT USING (uploaded_by = auth.uid());

-- RESUME_ANALYSES: Users can insert their own
CREATE POLICY "Users can insert resume analyses" ON resume_analyses
  FOR INSERT WITH CHECK (uploaded_by = auth.uid());

-- RESUME_ANALYSES: Users can update their own
CREATE POLICY "Users can update own resume analyses" ON resume_analyses
  FOR UPDATE USING (uploaded_by = auth.uid());

-- RESUME_ANALYSES: Admins can view ALL (uses function)
CREATE POLICY "Admins can view all resume analyses" ON resume_analyses
  FOR SELECT USING (public.is_admin());

-- INTERVIEWED_CANDIDATES: Authenticated users can view all
CREATE POLICY "Authenticated users can view candidates" ON interviewed_candidates
  FOR SELECT TO authenticated USING (true);

-- INTERVIEWED_CANDIDATES: Admins can manage (uses function)
CREATE POLICY "Admins can manage candidates" ON interviewed_candidates
  FOR ALL USING (public.is_admin());

-- ========================================
-- 4. Ensure your admin profile exists
-- ========================================

INSERT INTO recruiter_profiles (id, email, role)
SELECT id, email, 'admin'
FROM auth.users
WHERE email = 'chris.marinelli@vysusgroup.com'
ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- ========================================
-- 5. Add login_count column for tracking
-- ========================================

ALTER TABLE recruiter_profiles ADD COLUMN IF NOT EXISTS login_count INTEGER DEFAULT 0;

-- ========================================
-- 6. Create function to increment login count
-- ========================================

CREATE OR REPLACE FUNCTION public.increment_login_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.last_login IS DISTINCT FROM OLD.last_login THEN
    NEW.login_count = COALESCE(OLD.login_count, 0) + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_last_login_update ON recruiter_profiles;
CREATE TRIGGER on_last_login_update
  BEFORE UPDATE OF last_login ON recruiter_profiles
  FOR EACH ROW EXECUTE FUNCTION increment_login_count();

-- ========================================
-- 7. Add screening_results RLS policies
-- ========================================

DROP POLICY IF EXISTS "Users can insert screening results" ON screening_results;
DROP POLICY IF EXISTS "Users can view own screening results" ON screening_results;
DROP POLICY IF EXISTS "Admins can view all screening results" ON screening_results;

CREATE POLICY "Users can insert screening results" ON screening_results
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own screening results" ON screening_results
  FOR SELECT USING (screened_by = auth.uid());

CREATE POLICY "Admins can view all screening results" ON screening_results
  FOR SELECT USING (public.is_admin());

-- ========================================
-- 8. Verify the fix
-- ========================================

-- Test the is_admin function (should return true for admin users)
-- SELECT public.is_admin();

-- Check your profile
-- SELECT * FROM recruiter_profiles WHERE email = 'chris.marinelli@vysusgroup.com';

-- Check all profiles (should work for admins now)
-- SELECT id, email, role, last_login, login_count FROM recruiter_profiles ORDER BY last_login DESC NULLS LAST;
