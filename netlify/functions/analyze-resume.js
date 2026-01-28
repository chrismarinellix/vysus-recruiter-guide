// Netlify Function for Resume Analysis using Groq API

const GROQ_API_KEY = process.env.GROQ_API_KEY;

// Assessment guide embedded for LLM context (source: assessment-guide.md)
const ASSESSMENT_GUIDE = `
Vysus Group provides specialist engineering consultancy for renewable energy grid connections in Australia's National Electricity Market (NEM). Engineers perform grid connection studies for solar, wind, and BESS projects, ensuring compliance with the National Electricity Rules (NER) and generator performance standards (GPS).

ROLE LEVEL DEFINITIONS:

SENIOR ENGINEER (Technical Delivery) — Can independently deliver R1 and R2 grid connection studies end-to-end.
Required competencies with scoring criteria:
1. Independent R1/R2 study delivery — Strong: led/completed R1/R2, DMAT, DMNT, grid connection studies. Partial: assisted on studies or related power systems analysis.
2. Proficiency in PSCAD and/or PSS/E — Strong: explicitly names PSCAD or PSS/E with project context. Partial: DIgSILENT, PowerFactory, ETAP, or generic simulation.
3. EMT & RMS simulation execution — Strong: describes running EMT or RMS simulations and interpreting results. Partial: general power systems simulation without specifying EMT/RMS.
4. Grid code compliance assessment — Strong: references NER, S5.2, GPS, generator performance standards. Partial: general compliance or regulatory work.
5. Model validation & tuning — Strong: validating/tuning generator or inverter models against test data. Partial: general model development or testing.
6. Technical report writing — Strong: writing study reports, technical documentation. Partial: general engineering report writing.
7. Client communication — Strong: presenting to or communicating with clients/stakeholders. Partial: general communication skills.
8. Team knowledge contribution — Strong: mentoring juniors, knowledge sharing, training activities. Partial: general teamwork.

LEAD ENGINEER (Technical Leadership) — All Senior competencies PLUS leads projects and develops people.
Additional competencies:
1. Mentors and develops engineers — Strong: explicitly describes mentoring, coaching, developing team. Partial: working with junior staff.
2. Project leadership & oversight — Strong: named as project lead/manager with deliverable accountability. Partial: general team lead or coordination.
3. Direct NSP/AEMO engagement — Strong: names specific NSPs (Transgrid, Powerlink, ElectraNet, AusNet) or AEMO. Partial: general utility or regulator engagement.
4. Project budget management — Strong: managing budgets, cost control, financial forecasting. Partial: commercial awareness.
5. Client relationship ownership — Strong: primary client contact, account management. Partial: regular client interaction.
6. Technical review & QA sign-off — Strong: reviews and approves others' technical work. Partial: participates in peer review.
7. Scope definition & proposal input — Strong: writes proposals, tenders, scope documents. Partial: aware of proposal processes.
8. Multi-project coordination — Strong: manages multiple concurrent projects. Partial: works on multiple projects.
9. Technical risk assessment — Strong: identifies and manages technical risks. Partial: general risk awareness.

PRINCIPAL ENGINEER (Strategic Leadership) — All Lead competencies PLUS strategic oversight and business growth.
Additional competencies:
1. Strategic oversight across projects — Strong: portfolio/program management, strategic direction. Partial: large project oversight.
2. Business development & growth — Strong: wins new work, client pipeline, revenue targets. Partial: supports BD activities.
3. Senior client advisory — Strong: strategic guidance to senior stakeholders. Partial: project-level advisory.
4. Team capacity & capability planning — Strong: plans team growth, capability gaps, recruitment. Partial: identifies skills needs.
5. Guides Leads on complex decisions — Strong: technical direction to other leads/seniors. Partial: independent complex decisions.
6. Industry thought leadership — Strong: conference presentations, publications, working groups. Partial: industry awareness.
7. Proposal strategy & pricing oversight — Strong: win strategy, pricing decisions. Partial: proposal contribution.
8. Market positioning & service offering — Strong: shapes service offerings, market opportunities. Partial: market understanding.

SCORING RULES:
- "strong": Resume explicitly demonstrates the competency with specific examples, project names, tools named, or outcomes.
- "partial": Related experience that suggests capability but does not directly confirm the exact competency.
- "none": No evidence in resume. Do NOT infer or assume. When in doubt, mark "none".
- Role score (0-100) = percentage of competencies at strong/partial. Weight "strong" more than "partial".
- Level recommendation: Senior needs majority of Senior skills (especially items 1-5). Lead needs Senior PLUS leadership skills. Principal needs Lead PLUS strategic/BD skills. Below Senior = no simulation tool or grid connection study experience.
- Power systems experience in non-renewable sectors is "partial" for renewable-specific competencies.
- International (non-Australian NEM) experience is valid but NER/AEMO/NSP knowledge may need development.
- Software tool proficiency must be explicitly named — do not assume from general simulation experience.
`;

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
        model: 'llama-3.3-70b-versatile',
        messages: [
          {
            role: 'system',
            content: `You are an expert technical recruiter specializing in power systems engineering for the renewable energy sector at Vysus Group. You analyze resumes against specific role requirements and provide detailed, consistent skill matching analysis. You must strictly follow the assessment guide provided and never infer skills not explicitly stated in the resume. Always respond with valid JSON.\n\nASSESSMENT GUIDE:\n${ASSESSMENT_GUIDE}`
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
Analyze this resume against Vysus Group's power systems engineer role requirements. Use the Assessment Guide provided in the system message for scoring criteria and competency definitions.

CANDIDATE: ${candidateName || 'Unknown'}
TARGET POSITION: ${targetPosition} Engineer

RESUME CONTENT:
${resumeText.substring(0, 8000)}

SKILL NAMES FOR EACH ROLE (match skills array to these in order):

SENIOR ENGINEER (8 skills):
${seniorSkills}

LEAD ENGINEER (9 additional skills beyond Senior):
${leadSkills}

PRINCIPAL ENGINEER (8 additional skills beyond Lead):
${principalSkills}

KEY TECHNICAL KEYWORDS TO LOOK FOR:
- Software: PSCAD, PSS/E, PSSE, DIgSILENT, PowerFactory, ETAP, Python, MATLAB
- Studies: R1, R2, DMAT, DMNT, grid connection studies, compliance, system strength
- Technical: EMT, RMS, GFL, GFM, LVRT, HVRT, SCR, PPC, inverter, fault ride through, harmonics, SSO
- Regulatory: NER, AEMO, NSP, GPS, S5.2, grid code, connection agreement
- Projects: solar, wind, BESS, battery, renewable, MW, hybrid
- Australian NSPs: Transgrid, Powerlink, ElectraNet, AusNet, Western Power, TasNetworks

Return a JSON object with this exact structure:
{
  "extractedName": "<full name from resume>",
  "extractedEmail": "<email from resume, or null>",
  "overallScore": <number 0-100>,
  "recommendedLevel": "<Senior|Lead|Principal|Below Senior>",
  "summary": "<2-3 sentence summary of candidate's fit for Vysus, referencing specific evidence from the resume>",
  "roleMatches": {
    "senior": {
      "score": <number 0-100>,
      "skills": ["strong"|"partial"|"none", ...] // exactly 8 values, one per Senior skill in order
    },
    "lead": {
      "score": <number 0-100>,
      "skills": ["strong"|"partial"|"none", ...] // exactly 9 values, one per Lead skill in order
    },
    "principal": {
      "score": <number 0-100>,
      "skills": ["strong"|"partial"|"none", ...] // exactly 8 values, one per Principal skill in order
    }
  },
  "recommendation": "<one line hiring recommendation>",
  "keyStrengths": ["<specific strength with evidence from resume>", ...],
  "gaps": ["<specific gap relevant to target position>", ...]
}

CRITICAL RULES:
- Follow the Assessment Guide scoring criteria strictly for strong/partial/none decisions.
- ONLY base analysis on information explicitly stated in the resume text.
- Do NOT infer, assume, or fabricate skills not clearly mentioned.
- Senior skills array must have exactly 8 entries, Lead exactly 9, Principal exactly 8.
- When in doubt between partial and none, mark "none".
- Reference specific resume content in the summary and strengths.
- International experience is valid but note if Australian NEM knowledge may need development.
- Software tools must be explicitly named — do not assume from general descriptions.
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
