import React from 'react';
import { Link } from 'react-router-dom';

const Header: React.FC = () => {
    return (
        <header className="bg-blue-600 text-white p-4">
            <h1 className="text-2xl font-bold">DC Problems and Pitches</h1>
            <nav>
                <ul className="flex space-x-4">
                    <li>
                        <Link to="/" className="hover:underline">Home</Link>
                    </li>
                    <li>
                        <Link to="/problems" className="hover:underline">Problems</Link>
                    </li>
                    <li>
                        <Link to="/pitches" className="hover:underline">Pitches</Link>
                    </li>
                </ul>
            </nav>
        </header>
    );
};

export default Header;