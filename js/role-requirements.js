// Role requirements for Vysus Grid Connection Engineers
// Used for Groq AI resume analysis and skill matching

const roleRequirements = {
  senior: {
    title: "Senior Engineer",
    focus: "Technical Delivery",
    skills: [
      { name: "Independent study delivery (R1/R2)", keywords: ["R1", "R2", "DMAT", "DMNT", "grid connection studies", "connection studies"] },
      { name: "Strong in 1-2 modelling tools (PSCAD, PSS/E)", keywords: ["PSCAD", "PSS/E", "PSSE", "PSS\\E", "DIgSILENT", "PowerFactory"] },
      { name: "EMT & RMS simulation execution", keywords: ["EMT", "RMS", "electromagnetic transient", "transient simulation", "dynamic simulation"] },
      { name: "Grid code compliance assessment", keywords: ["NER", "grid code", "S5.2", "compliance", "GPS", "generator performance standard"] },
      { name: "Model validation & tuning", keywords: ["model validation", "model tuning", "parameter tuning", "validation testing"] },
      { name: "Technical report writing", keywords: ["technical reports", "study reports", "documentation", "report writing"] },
      { name: "Developing client communication", keywords: ["client communication", "stakeholder", "presentation"] },
      { name: "Contributes to team knowledge", keywords: ["knowledge sharing", "mentoring", "training"] }
    ]
  },
  lead: {
    title: "Lead Engineer",
    focus: "Technical Leadership",
    includesPrevious: true,
    skills: [
      { name: "Mentors and develops engineers", keywords: ["mentor", "coaching", "developing engineers", "team development"] },
      { name: "Project leadership & oversight", keywords: ["project lead", "project manager", "leading projects", "project oversight"] },
      { name: "Direct NSP/AEMO engagement", keywords: ["NSP", "AEMO", "network service provider", "Australian Energy Market Operator", "Transgrid", "Powerlink", "ElectraNet", "AusNet"] },
      { name: "Project budget management", keywords: ["budget", "cost management", "financial", "project costing"] },
      { name: "Client relationship ownership", keywords: ["client relationship", "account management", "client management"] },
      { name: "Technical review & QA sign-off", keywords: ["technical review", "QA", "quality assurance", "peer review", "sign-off"] },
      { name: "Scope definition & proposal input", keywords: ["scope", "proposal", "tender", "bid", "quotation"] },
      { name: "Multi-project coordination", keywords: ["multi-project", "portfolio", "multiple projects", "program"] },
      { name: "Technical risk assessment", keywords: ["risk assessment", "technical risk", "risk management"] }
    ]
  },
  principal: {
    title: "Principal Engineer",
    focus: "Strategic Leadership",
    includesPrevious: true,
    skills: [
      { name: "Strategic oversight across projects", keywords: ["strategic", "oversight", "portfolio management", "program management"] },
      { name: "Business development & growth", keywords: ["business development", "BD", "sales", "growth", "new business"] },
      { name: "Senior client advisory", keywords: ["advisory", "consultant", "senior advisor", "strategic advice"] },
      { name: "Team capacity & capability planning", keywords: ["capacity planning", "capability", "resource planning", "workforce planning"] },
      { name: "Guides Leads on complex decisions", keywords: ["guidance", "decision making", "complex decisions", "technical direction"] },
      { name: "Industry thought leadership", keywords: ["thought leadership", "industry", "conference", "publication", "speaking"] },
      { name: "Proposal strategy & pricing oversight", keywords: ["pricing", "proposal strategy", "commercial", "win strategy"] },
      { name: "Market positioning & service offering", keywords: ["market", "service offering", "positioning", "competitive"] }
    ]
  }
};

// Job description keywords for additional matching
const jobDescriptionKeywords = {
  technical: [
    "power systems", "renewable energy", "solar", "wind", "BESS", "battery", "hydro",
    "grid connection", "grid integration", "inverter", "GFL", "GFM", "grid-following", "grid-forming",
    "PPC", "plant controller", "LVRT", "HVRT", "fault ride through", "FRT",
    "SCR", "system strength", "weak grid", "harmonics", "oscillation",
    "power flow", "short circuit", "stability", "transient", "voltage", "frequency",
    "Python", "scripting", "automation"
  ],
  regulatory: [
    "NER", "National Electricity Rules", "S5.2.5", "GPS", "generator performance",
    "AEMO", "NSP", "commissioning", "energisation"
  ],
  experience: [
    "utility", "developer", "OEM", "consultant", "consultancy",
    "Australia", "NEM", "National Energy Market"
  ]
};

// Export for use in other scripts
if (typeof window !== 'undefined') {
  window.roleRequirements = roleRequirements;
  window.jobDescriptionKeywords = jobDescriptionKeywords;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { roleRequirements, jobDescriptionKeywords };
}
