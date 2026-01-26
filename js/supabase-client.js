// Supabase Client Configuration for Vysus Recruiter Guide

const SUPABASE_URL = 'https://ekytcurxudovqqvabmyp.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVreXRjdXJ4dWRvdnFxdmFibXlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1ODQxNDYsImV4cCI6MjA4MzE2MDE0Nn0.NZKRVJOUfe76Drmq3gTSjXbOFQVb_9XBD8qnbkZrvM8';

// Initialize Supabase client (using 'sb' to avoid conflict with CDN global)
let sb;

function initSupabase() {
  if (typeof window !== 'undefined' && window.supabase) {
    sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      }
    });

    // Listen for auth changes (handles magic link callback + token refresh)
    sb.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN' && session) {
        console.log('Session established for:', session.user.email);
      }
      if (event === 'TOKEN_REFRESHED') {
        console.log('Session token refreshed');
      }
    });

    return sb;
  }
  console.error('Supabase SDK not loaded');
  return null;
}

// Auth functions
async function signInWithEmail(email) {
  const { data, error } = await sb.auth.signInWithOtp({
    email: email,
    options: {
      emailRedirectTo: window.location.origin + '/index.html'
    }
  });
  return { data, error };
}

async function signOut() {
  const { error } = await sb.auth.signOut();
  if (!error) {
    window.location.href = '/login.html';
  }
  return { error };
}

async function getSession() {
  const { data: { session }, error } = await sb.auth.getSession();
  return { session, error };
}

async function getUser() {
  const { data: { user }, error } = await sb.auth.getUser();
  return { user, error };
}

// Check if user is authenticated
async function requireAuth() {
  const { session } = await getSession();
  if (!session) {
    window.location.href = '/login.html';
    return null;
  }
  return session;
}

// Get user profile
async function getProfile(userId) {
  const { data, error } = await sb
    .from('recruiter_profiles')
    .select('*')
    .eq('id', userId)
    .single();
  return { data, error };
}

// Update last login
async function updateLastLogin(userId) {
  const { error } = await sb
    .from('recruiter_profiles')
    .update({ last_login: new Date().toISOString() })
    .eq('id', userId);
  return { error };
}

// Log activity
async function logActivity(action, details = {}) {
  const { user } = await getUser();
  const { error } = await sb
    .from('activity_log')
    .insert({
      user_id: user?.id || null,
      user_email: user?.email || 'anonymous',
      action: action,
      details: details
    });
  return { error };
}

// Candidate functions
async function getInterviewedCandidates(filters = {}) {
  let query = sb
    .from('interviewed_candidates')
    .select('*')
    .order('last_contacted', { ascending: false });

  if (filters.status) {
    query = query.eq('status', filters.status);
  }
  if (filters.level) {
    query = query.ilike('level', `%${filters.level}%`);
  }
  if (filters.location) {
    query = query.ilike('location', `%${filters.location}%`);
  }
  if (filters.search) {
    query = query.ilike('name', `%${filters.search}%`);
  }

  const { data, error } = await query;
  return { data, error };
}

async function getCandidateStats() {
  const { data, error } = await sb
    .from('interviewed_candidates')
    .select('status, level, location');

  if (error) return { stats: null, error };

  const stats = {
    total: data.length,
    byStatus: {},
    byLevel: {},
    byLocation: {}
  };

  data.forEach(c => {
    stats.byStatus[c.status] = (stats.byStatus[c.status] || 0) + 1;
    stats.byLevel[c.level] = (stats.byLevel[c.level] || 0) + 1;
    stats.byLocation[c.location] = (stats.byLocation[c.location] || 0) + 1;
  });

  return { stats, error: null };
}

// Resume analysis functions
async function getResumeAnalyses(limit = 20) {
  const { user } = await getUser();
  const { data, error } = await sb
    .from('resume_analyses')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);
  return { data, error };
}

async function saveResumeAnalysis(analysis) {
  const { user } = await getUser();
  const { data, error } = await sb
    .from('resume_analyses')
    .insert({
      ...analysis,
      uploaded_by: user?.id
    })
    .select()
    .single();
  return { data, error };
}

// Quiz submission functions
async function saveQuizSubmission(submission) {
  const { data, error } = await sb
    .from('quiz_submissions')
    .insert(submission)
    .select()
    .single();
  return { data, error };
}

async function getQuizSubmissions(limit = 50) {
  const { data, error } = await sb
    .from('quiz_submissions')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);
  return { data, error };
}

// Activity log functions
async function getActivityLog(limit = 50) {
  const { data, error } = await sb
    .from('activity_log')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);
  return { data, error };
}

// Screening results functions
async function saveScreeningResult(result) {
  const { user } = await getUser();
  const { data, error } = await sb
    .from('screening_results')
    .insert({
      ...result,
      screened_by: user?.id,
      screened_by_email: user?.email || 'anonymous'
    })
    .select()
    .single();
  return { data, error };
}

// Check if candidate was previously interviewed
async function checkInterviewedCandidate(candidateName) {
  if (!candidateName || candidateName.trim().length < 2) return { matches: [], error: null };
  const name = candidateName.trim();
  // Search by partial name match
  const { data, error } = await sb
    .from('interviewed_candidates')
    .select('*')
    .ilike('name', `%${name}%`)
    .order('last_contacted', { ascending: false });
  return { matches: data || [], error };
}

// File upload functions
async function uploadResume(file, candidateName) {
  const timestamp = Date.now();
  const safeName = candidateName.replace(/[^a-z0-9]/gi, '_').toLowerCase();
  const filePath = `resumes/${safeName}_${timestamp}_${file.name}`;

  const { data, error } = await sb.storage
    .from('resumes')
    .upload(filePath, file);

  return { data, error, filePath };
}

async function getResumeUrl(filePath) {
  const { data } = await sb.storage
    .from('resumes')
    .getPublicUrl(filePath);
  return data?.publicUrl;
}

// Admin functions
async function isAdmin() {
  const { user } = await getUser();
  if (!user) return false;

  const { data } = await getProfile(user.id);
  return data?.role === 'admin';
}

async function getAllUsers() {
  const { data, error } = await sb
    .from('recruiter_profiles')
    .select('*')
    .order('created_at', { ascending: false });
  return { data, error };
}

// Export for use in HTML
if (typeof window !== 'undefined') {
  window.initSupabase = initSupabase;
  window.signInWithEmail = signInWithEmail;
  window.signOut = signOut;
  window.getSession = getSession;
  window.getUser = getUser;
  window.requireAuth = requireAuth;
  window.getProfile = getProfile;
  window.updateLastLogin = updateLastLogin;
  window.logActivity = logActivity;
  window.getInterviewedCandidates = getInterviewedCandidates;
  window.getCandidateStats = getCandidateStats;
  window.getResumeAnalyses = getResumeAnalyses;
  window.saveResumeAnalysis = saveResumeAnalysis;
  window.saveQuizSubmission = saveQuizSubmission;
  window.getQuizSubmissions = getQuizSubmissions;
  window.getActivityLog = getActivityLog;
  window.uploadResume = uploadResume;
  window.getResumeUrl = getResumeUrl;
  window.isAdmin = isAdmin;
  window.getAllUsers = getAllUsers;
  window.saveScreeningResult = saveScreeningResult;
  window.checkInterviewedCandidate = checkInterviewedCandidate;
}
