import React, { useEffect, useState } from 'react';

const ProblemList = () => {
    const [problems, setProblems] = useState([]);

    useEffect(() => {
        const fetchProblems = async () => {
            const response = await fetch('/problems'); // Adjust the path as necessary
            const data = await response.json();
            setProblems(data);
        };

        fetchProblems();
    }, []);

    return (
        <div className="problem-list">
            <h2 className="text-2xl font-bold">Major Problems in DC</h2>
            <ul>
                {problems.map((problem) => (
                    <li key={problem.id} className="my-2">
                        <a href={`/problems/${problem.id}`} className="text-blue-500 hover:underline">
                            {problem.title}
                        </a>
                    </li>
                ))}
            </ul>
        </div>
    );
};

export default ProblemList;