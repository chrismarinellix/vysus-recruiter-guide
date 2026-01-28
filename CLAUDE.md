# Vysus Recruiter Guide - Claude Code Configuration

## Output Style
- Be concise - show only final results, not intermediate steps
- Don't narrate which files you're reading or commands you're running
- Just show the answer and confirm completion
- Use tables and bullet points for clarity

## Change Management
- **Only make changes explicitly requested** - do not add improvements, refactoring, or "nice to have" edits
- When editing files, change ONLY what was asked - preserve all other content exactly
- Do not add comments, documentation, or formatting changes unless specifically requested

## Project Context
This is **Vysus Recruiter Guide** - a pre-screening tool for recruiters at Vysus Group, deployed on Netlify.

| Page | Purpose |
|------|---------|
| `index.html` | Main screening guide with role requirements and quiz |
| `candidates.html` | Interviewed candidates tracker with filters/stats |
| `resume-analyzer.html` | CV/resume analysis tool (uses Groq API via Netlify Function) |
| `admin.html` | Admin dashboard (restricted to admin users) |
| `login.html` | Authentication page (Supabase magic link + password) |
| `candidate-brief.html` | Candidate brief generator |

## Tech Stack
- **Frontend**: Static HTML/CSS/JS (no build step)
- **Auth**: Supabase Auth (magic link + email/password)
- **Database**: Supabase (PostgreSQL)
- **Hosting**: Netlify (site: `vysus-recruiter-guide`)
- **Serverless**: Netlify Functions (`netlify/functions/`)
- **AI**: Groq API for resume analysis (`analyze-resume.js`)

## Key Files

| File | Purpose |
|------|---------|
| `js/supabase-client.js` | Supabase client, auth helpers, all DB query functions |
| `js/role-requirements.js` | Role definitions and screening criteria |
| `netlify/functions/analyze-resume.js` | Serverless resume analysis via Groq |
| `netlify.toml` | Netlify config (publish dir, functions, headers, redirects) |
| `supabase-schema.sql` | Database schema reference |
| `supabase/` | Supabase config and migrations |

## Authentication
- Supabase Auth with email/password signup and sign-in
- Password reset via `sb.auth.resetPasswordForEmail()` with recovery callback on login.html
- Email whitelist: @vysusgroup.com auto-allowed, external emails checked against `allowed_external_emails` table
- Admin check: `session.user.email === 'chris.marinelli@vysusgroup.com'`
- Dev session: `localStorage.getItem('vysus_dev_session')` - bypasses auth on localhost
- Admin gear icon (&#9881;) shown on all pages for admin email or dev sessions
- Auth functions in `supabase-client.js`: `signUpWithPassword()`, `sendPasswordReset()`, `updatePassword()`

## Resume Assessment
- `assessment-guide.md` - LLM assessment criteria for power systems engineer roles
- Embedded in `analyze-resume.js` as system prompt context for Groq (llama-3.3-70b-versatile)
- Three role levels: Senior (8 skills), Lead (9 skills), Principal (8 skills)
- Strict scoring: strong/partial/none based on explicit resume evidence only

## Supabase Tables
- `recruiter_profiles` - User profiles with roles
- `interviewed_candidates` - Past candidate records
- `resume_analyses` - Saved resume analysis results
- `quiz_submissions` - Screening quiz results
- `activity_log` - User activity tracking
- `screening_results` - Screening outcomes

## Design System
Vysus Group brand colours:
- `--vysus-stockholm-neon: #00E3A9` (accent/links)
- `--vysus-malmo-green: #005454` (primary/headers)
- `--vysus-trondheim-night: #1D1D1B` (dark text)
- `--vysus-scandinavia-rock: #485559` (secondary text)
- `--vysus-oslo-snow: #F8F8F8` (backgrounds)
- `--vysus-stavanger-ice: #EDEDED` (borders)
- `--vysus-bergen-rain: #DADADA` (dividers)

## Deployment
- **Site URL**: https://vysus-recruiter-guide.netlify.app
- **Deploy from**: `C:\Code\projects\vysus-recruiter-guide`
- Publishes root directory (no build step)
- API routes redirect `/api/*` to `/.netlify/functions/:splat`

## Environment Variables (Netlify Dashboard)
- `GROQ_API_KEY` - Required for resume analysis function

## Coding Standards
- No build tools - plain HTML/CSS/JS
- Shared client library in `js/supabase-client.js`
- Consistent Vysus brand styling across all pages
- Security headers set in `netlify.toml`
