# Local Testing Guide

## Prerequisites
- Netlify CLI installed (`npm install -g netlify-cli`)
- Already logged into Netlify CLI

## Start Local Server

```bash
cd /Users/chris/Documents/Code/vysus-recruiter-guide
netlify dev
```

This will start:
- Local server at http://localhost:8888
- Netlify Functions at http://localhost:8888/.netlify/functions/

## Test Checklist

### 1. Authentication
- [ ] Visit http://localhost:8888/login.html
- [ ] Enter email: `chris.marinelli@vysusgroup.com`
- [ ] Check email for magic link (or check Supabase Auth logs)
- [ ] Verify redirect to index.html after auth

### 2. Main Dashboard (index.html)
- [ ] Should redirect to login if not authenticated
- [ ] Navigation links visible when logged in
- [ ] Sign out button works

### 3. Candidates Page (candidates.html)
- [ ] Loads 124 interviewed candidates
- [ ] Search filter works
- [ ] Status filter works (Declined Offer, Not Progressed, etc.)
- [ ] Level filter works (PSE, Engineer, Senior, Lead, Principal)
- [ ] Location filter works
- [ ] Stats cards show correct counts

### 4. Resume Analyzer (resume-analyzer.html)
- [ ] File upload accepts PDF/DOC/DOCX
- [ ] Drag & drop works
- [ ] Position selector (Senior/Lead/Principal)
- [ ] Analyze button triggers Groq API
- [ ] Skills display with pulse animation for matches
- [ ] Analysis saves to history

### 5. Netlify Function
Test directly:
```bash
curl -X POST http://localhost:8888/api/analyze-resume \
  -H "Content-Type: application/json" \
  -d '{"resumeText": "Test engineer with PSCAD and PSS/E experience", "candidateName": "Test User", "targetPosition": "Senior"}'
```

## Supabase Dashboard
- URL: https://supabase.com/dashboard/project/ekytcurxudovqqvabmyp
- Check Tables: interviewed_candidates, resume_analyses, activity_log
- Check Auth: Users who have logged in
- Check Storage: Uploaded resumes

## Troubleshooting

### "Not authenticated" errors
- Clear localStorage: `localStorage.clear()` in browser console
- Try logging in again

### Groq API errors
- Check GROQ_API_KEY is set (hardcoded in analyze-resume.js for now)
- Check Netlify Function logs in terminal

### Supabase connection issues
- Verify keys in js/supabase-client.js match your project
- Check RLS policies in Supabase dashboard
