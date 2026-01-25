-- Create storage bucket for resumes
INSERT INTO storage.buckets (id, name, public)
VALUES ('resumes', 'resumes', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to resumes bucket
CREATE POLICY "Authenticated users can upload resumes" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'resumes');

-- Allow authenticated users to read resumes
CREATE POLICY "Authenticated users can read resumes" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'resumes');

-- Allow public read access (for sharing resume analysis results)
CREATE POLICY "Public can read resumes" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'resumes');
