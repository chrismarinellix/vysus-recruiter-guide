// Netlify Function for Resume Analysis using Groq API

const GROQ_API_KEY = process.env.GROQ_API_KEY;

exports.handler = async (event, context) => {
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json'
  };

  // Handle preflight
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  if (!GROQ_API_KEY) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'GROQ_API_KEY not configured' })
    };
  }

  try {
    const { resumeText, candidateName, targetPosition, roleRequirements } = JSON.parse(event.body);

    if (!resumeText) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Resume text is required' })
      };
    }

    // Prepare the prompt for Groq
    const prompt = buildAnalysisPrompt(resumeText, candidateName, targetPosition, roleRequirements);

    // Call Groq API
    const groqResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'llama-3.1-70b-versatile',
        messages: [
          {
            role: 'system',
            content: `You are an expert technical recruiter specializing in power systems engineering for the renewable energy sector. You analyze resumes against specific role requirements and provide detailed skill matching analysis. Always respond with valid JSON.`
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.3,
        max_tokens: 2000,
        response_format: { type: 'json_object' }
      })
    });

    if (!groqResponse.ok) {
      const errorText = await groqResponse.text();
      console.error('Groq API error:', errorText);
      return {
        statusCode: 502,
        headers,
        body: JSON.stringify({ error: `Groq API error: ${groqResponse.status}`, details: errorText })
      };
    }

    const groqData = await groqResponse.json();
    const analysisText = groqData.choices[0]?.message?.content;

    if (!analysisText) {
      throw new Error('No analysis returned from Groq');
    }

    // Parse the JSON response
    let analysis;
    try {
      analysis = JSON.parse(analysisText);
    } catch (parseError) {
      console.error('Failed to parse Groq response:', analysisText);
      // Fallback to basic analysis
      analysis = generateFallbackAnalysis(resumeText, targetPosition, roleRequirements);
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify(analysis)
    };

  } catch (error) {
    console.error('Analysis error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: error.message || 'Analysis failed' })
    };
  }
};

function buildAnalysisPrompt(resumeText, candidateName, targetPosition, roleRequirements) {
  const seniorSkills = roleRequirements?.senior?.skills?.map(s => s.name).join(', ') ||
    'R1/R2 studies, PSCAD/PSS/E, EMT/RMS simulation, grid code compliance, model validation, technical reports';

  const leadSkills = roleRequirements?.lead?.skills?.map(s => s.name).join(', ') ||
    'mentoring engineers, project leadership, NSP/AEMO engagement, budget management, client relationships, technical review';

  const principalSkills = roleRequirements?.principal?.skills?.map(s => s.name).join(', ') ||
    'strategic oversight, business development, senior advisory, capacity planning, industry thought leadership';

  return `
Analyze this resume for a ${targetPosition} Engineer position at Vysus Group, a power systems engineering consultancy specializing in renewable energy grid connections in Australia.

CANDIDATE: ${candidateName || 'Unknown'}
TARGET POSITION: ${targetPosition} Engineer

RESUME CONTENT:
${resumeText.substring(0, 8000)}

ROLE REQUIREMENTS:

SENIOR ENGINEER (Technical Delivery):
${seniorSkills}

LEAD ENGINEER (Technical Leadership):
All Senior requirements plus: ${leadSkills}

PRINCIPAL ENGINEER (Strategic Leadership):
All Lead requirements plus: ${principalSkills}

KEY TECHNICAL KEYWORDS TO LOOK FOR:
- Software: PSCAD, PSS/E, PSSE, DIgSILENT, PowerFactory, ETAP, Python
- Studies: R1, R2, DMAT, DMNT, grid connection studies, compliance
- Technical: EMT, RMS, GFL, GFM, LVRT, HVRT, SCR, PPC, inverter, fault ride through
- Regulatory: NER, AEMO, NSP, GPS, S5.2, grid code
- Projects: solar, wind, BESS, battery, renewable, MW

Analyze the resume and return a JSON object with this exact structure:
{
  "overallScore": <number 0-100>,
  "recommendedLevel": "<Senior|Lead|Principal|Below Senior>",
  "summary": "<2-3 sentence summary of candidate's fit>",
  "roleMatches": {
    "senior": {
      "score": <number 0-100>,
      "skills": ["strong", "partial", "none", ...] // one for each senior skill in order
    },
    "lead": {
      "score": <number 0-100>,
      "skills": ["strong", "partial", "none", ...] // one for each lead skill in order
    },
    "principal": {
      "score": <number 0-100>,
      "skills": ["strong", "partial", "none", ...] // one for each principal skill in order
    }
  },
  "recommendation": "<one line recommendation>",
  "keyStrengths": ["<strength 1>", "<strength 2>", ...],
  "gaps": ["<gap 1>", "<gap 2>", ...]
}

Be honest and accurate. If the resume doesn't clearly demonstrate a skill, mark it as "none" or "partial".
`;
}

function generateFallbackAnalysis(resumeText, targetPosition, roleRequirements) {
  // Simple keyword-based fallback analysis
  const text = resumeText.toLowerCase();

  const checkKeywords = (keywords) => {
    let matches = 0;
    keywords.forEach(kw => {
      if (text.includes(kw.toLowerCase())) matches++;
    });
    return matches;
  };

  const technicalKeywords = ['pscad', 'pss/e', 'psse', 'power systems', 'grid', 'renewable', 'solar', 'wind', 'bess'];
  const leadershipKeywords = ['lead', 'manager', 'mentor', 'team', 'project lead', 'senior'];
  const strategicKeywords = ['director', 'principal', 'strategy', 'business development', 'advisory'];

  const techScore = Math.min(100, checkKeywords(technicalKeywords) * 12);
  const leadScore = Math.min(100, checkKeywords(leadershipKeywords) * 15);
  const stratScore = Math.min(100, checkKeywords(strategicKeywords) * 20);

  const overallScore = Math.round((techScore + leadScore + stratScore) / 3);

  let recommendedLevel = 'Below Senior';
  if (overallScore >= 70 && stratScore >= 40) recommendedLevel = 'Principal';
  else if (overallScore >= 60 && leadScore >= 40) recommendedLevel = 'Lead';
  else if (overallScore >= 40) recommendedLevel = 'Senior';

  return {
    overallScore,
    recommendedLevel,
    summary: `Automated analysis based on keyword matching. Manual review recommended.`,
    roleMatches: {
      senior: { score: techScore, skills: Array(8).fill(techScore > 50 ? 'partial' : 'none') },
      lead: { score: leadScore, skills: Array(10).fill(leadScore > 50 ? 'partial' : 'none') },
      principal: { score: stratScore, skills: Array(8).fill(stratScore > 50 ? 'partial' : 'none') }
    },
    recommendation: `Consider for ${recommendedLevel} role pending technical interview`,
    keyStrengths: [],
    gaps: ['Full AI analysis unavailable - manual review needed']
  };
}
