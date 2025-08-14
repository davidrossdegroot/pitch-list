import React from 'react';

const PitchDetail: React.FC<{ pitch: any }> = ({ pitch }) => {
    return (
        <div className="p-4">
            <h2 className="text-2xl font-bold">{pitch.title}</h2>
            <h3 className="text-xl mt-2">Problem Context</h3>
            <p>{pitch.problemContext}</p>
            <h3 className="text-xl mt-2">Proposed Solution</h3>
            <p>{pitch.proposedSolution}</p>
            <h3 className="text-xl mt-2">Impact Estimate</h3>
            <p>{pitch.impactEstimate}</p>
            <h3 className="text-xl mt-2">Level of Effort Estimate</h3>
            <p>{pitch.levelOfEffortEstimate}</p>
            <h3 className="text-xl mt-2">Why This Could Work</h3>
            <p>{pitch.whyThisCouldWork}</p>
            <h3 className="text-xl mt-2">Success Metrics</h3>
            <p>{pitch.successMetrics}</p>
            <h3 className="text-xl mt-2">Related Opportunities</h3>
            <ul>
                {pitch.relatedOpportunities.map((opportunity: string, index: number) => (
                    <li key={index}>{opportunity}</li>
                ))}
            </ul>
        </div>
    );
};

export default PitchDetail;