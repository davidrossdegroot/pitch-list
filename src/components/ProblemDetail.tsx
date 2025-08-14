import React from 'react';

const ProblemDetail: React.FC<{ problem: any }> = ({ problem }) => {
    return (
        <div className="p-4">
            <h1 className="text-2xl font-bold">{problem.title}</h1>
            <h2 className="text-xl mt-2">Overview</h2>
            <p>{problem.overview}</p>

            <h2 className="text-xl mt-4">Key Data & References</h2>
            <ul className="list-disc list-inside">
                {problem.keyData.map((data: string, index: number) => (
                    <li key={index}>{data}</li>
                ))}
            </ul>

            <h2 className="text-xl mt-4">Pitches Summary</h2>
            <table className="min-w-full border-collapse border border-gray-300">
                <thead>
                    <tr>
                        <th className="border border-gray-300 p-2">Pitch Title</th>
                        <th className="border border-gray-300 p-2">Short Description</th>
                        <th className="border border-gray-300 p-2">Impact (1–5)</th>
                        <th className="border border-gray-300 p-2">Level of Effort (1–5)</th>
                        <th className="border border-gray-300 p-2">Related Opportunities</th>
                    </tr>
                </thead>
                <tbody>
                    {problem.pitches.map((pitch: any, index: number) => (
                        <tr key={index}>
                            <td className="border border-gray-300 p-2">
                                <a href={pitch.link}>{pitch.title}</a>
                            </td>
                            <td className="border border-gray-300 p-2">{pitch.description}</td>
                            <td className="border border-gray-300 p-2">{pitch.impact}</td>
                            <td className="border border-gray-300 p-2">{pitch.effort}</td>
                            <td className="border border-gray-300 p-2">{pitch.opportunities.join(', ')}</td>
                        </tr>
                    ))}
                </tbody>
            </table>

            <h2 className="text-xl mt-4">Opportunities</h2>
            <ul className="list-disc list-inside">
                {problem.opportunities.map((opportunity: string, index: number) => (
                    <li key={index}>{opportunity}</li>
                ))}
            </ul>

            <h2 className="text-xl mt-4">Suggested Next Steps</h2>
            <ul className="list-disc list-inside">
                {problem.nextSteps.map((step: string, index: number) => (
                    <li key={index}>{step}</li>
                ))}
            </ul>

            <h2 className="text-xl mt-4">Related Problems</h2>
            <ul className="list-disc list-inside">
                {problem.relatedProblems.map((related: string, index: number) => (
                    <li key={index}>
                        <a href={related.link}>{related.title}</a>
                    </li>
                ))}
            </ul>
        </div>
    );
};

export default ProblemDetail;