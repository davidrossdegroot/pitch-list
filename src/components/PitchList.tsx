import React from 'react';

const PitchList: React.FC<{ pitches: Array<{ title: string; description: string; impact: number; effort: number; opportunities: string[] }> }> = ({ pitches }) => {
    return (
        <div className="pitches-list">
            <h2 className="text-xl font-bold">Pitches Summary</h2>
            <table className="min-w-full border-collapse border border-gray-200">
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
                    {pitches.map((pitch, index) => (
                        <tr key={index}>
                            <td className="border border-gray-300 p-2">{pitch.title}</td>
                            <td className="border border-gray-300 p-2">{pitch.description}</td>
                            <td className="border border-gray-300 p-2">{pitch.impact}</td>
                            <td className="border border-gray-300 p-2">{pitch.effort}</td>
                            <td className="border border-gray-300 p-2">{pitch.opportunities.join(', ')}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
};

export default PitchList;