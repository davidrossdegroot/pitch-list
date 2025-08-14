import React from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import Header from '../components/Header';
import ProblemList from '../components/ProblemList';
import PitchList from '../components/PitchList';
import ProblemDetail from '../components/ProblemDetail';
import PitchDetail from '../components/PitchDetail';

const Routes = () => {
    return (
        <Router>
            <Header />
            <Switch>
                <Route path="/" exact component={ProblemList} />
                <Route path="/problems/:id" component={ProblemDetail} />
                <Route path="/pitches/:id" component={PitchDetail} />
                <Route path="/pitches" component={PitchList} />
            </Switch>
        </Router>
    );
};

export default Routes;