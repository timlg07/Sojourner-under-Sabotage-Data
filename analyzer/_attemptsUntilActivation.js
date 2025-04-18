const save = require('../utils/save');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
/** @type {string[]} */
const usernames = require('../usernames.json');


// Attempts until the test for a component passes for the first time per user and component
const _attemptsUntilActivation = data
    .filter(item => ['ComponentTestsActivatedEvent', 'test-executed', 'test-execution-failed'].includes(item.eventType))
    .reduce((acc, item) => {
        const c = item.data.componentName ?? item.data.progression.componentName;

        if (!acc[item.user][c]) {
            acc[item.user][c] = {
                fails: [],
                errors: [],
                success: [],
                activation: []
            }
        }

        if (item.eventType === 'ComponentTestsActivatedEvent') {
            acc[item.user][c].activation.push(item.timestamp);
            acc[item.user][c].fails.filter(t => t < item.timestamp)
            acc[item.user][c].success.filter(t => t < item.timestamp)
            return acc;
        }

        if (acc[item.user][c].activation.length > 0) {
            const activation = acc[item.user][c].activation[0];
            if (item.timestamp > activation) {
                return acc;
            }
        }

        if (item.eventType === 'test-execution-failed') {
            acc[item.user][c].errors.push(item.timestamp);
            return acc;
        }

        const failed = item.data.executionResult.testStatus === 'FAILED';
        if (failed) {
            acc[item.user][c].fails.push(item.timestamp);
        } else {
            acc[item.user][c].success.push(item.timestamp);
        }
        return acc;
    }, usernames.map(name => ({ [name]: {} })).reduce((acc, item) => ({ ...acc, ...item }), {}))

const attemptsUntilActivation = Object.entries(_attemptsUntilActivation).reduce((acc, k) => {
    acc[k[0]] = Object.entries(k[1]).reduce((innerAcc, component) => {
            const fails = component[1].fails.length;
            const errors = component[1].errors.length;
            const successes = component[1].success.length;
            innerAcc[component[0]] = {fails, errors, successes};
            return innerAcc;
        }, {});
    return acc;
}, {});

save('../attemptsUntilActivation.json', attemptsUntilActivation)
