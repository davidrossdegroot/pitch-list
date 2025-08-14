export interface Problem {
    title: string;
    overview: string;
    keyData: Array<{ stat: string; source: string }>;
    pitchesSummary: Array<PitchSummary>;
    opportunities: Array<string>;
    suggestedNextSteps: Array<string>;
    relatedProblems: Array<string>;
}

export interface Pitch {
    title: string;
    problemContext: string;
    proposedSolution: string;
    impactEstimate: number;
    impactRationale: string;
    levelOfEffortEstimate: number;
    scope: {
        appetite: string;
        boundaries: string;
        noGos: string;
    };
    whyThisCouldWork: string;
    risks: Array<string>;
    successMetrics: string;
    resources: Array<string>;
    relatedOpportunities: Array<{ name: string; link: string }>;
    contributors: Array<string>;
}

export interface PitchSummary {
    title: string;
    shortDescription: string;
    impact: number;
    levelOfEffort: number;
    relatedOpportunities: Array<string>;
}