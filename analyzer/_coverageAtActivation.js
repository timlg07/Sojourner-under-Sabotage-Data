const fs = require('fs');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
/** @type {string[]} */
const usernames = require('../usernames.json');


// Time until the tests are activated per user and component
const finalCoverage = Object.entries(data
    .filter(item => item.eventType === 'ComponentTestsActivatedEvent' || item.eventType === 'test-executed')
    .reduce((acc, item) => {
        const c = item.data.componentName;
        if (!acc[item.user][c]) {
            acc[item.user][c] = {
                endTime: Number.POSITIVE_INFINITY,
                executions: []
            }
        }
        if (item.eventType === 'ComponentTestsActivatedEvent') {
            acc[item.user][c].endTime = item.timestamp;
        } else if (acc[item.user][c].endTime > item.timestamp) {
            acc[item.user][c].executions.push(item);
        }
        return acc;
    }, usernames.map(name => ({ [name]: {} })).reduce((acc, item) => ({ ...acc, ...item }), {}))
).reduce((acc, item) => {
    const name = item[0];
    const components = item[1];
    acc[name] = Object.entries(components).reduce((acc, item) => {
        const c = item[0];
        const data = item[1];
        const execRes = data.executions.reduce((acc, item) => {
            if (data.endTime >= item.timestamp && item.timestamp >= acc.timestamp) {
                return item;
            }
            return acc;
        }, {timestamp: 0}).data.executionResult;
        const extractCurrentCompCoverage = (acc, item) => item[0].includes(c) ? item[1] : acc;
        const coveredLines = Object.entries(execRes.coveredLines).reduce(extractCurrentCompCoverage, {});
        const totalLines = Object.entries(execRes.totalLines).reduce(extractCurrentCompCoverage, {});
        acc[c] = {coveredLines, totalLines, fraction: coveredLines / totalLines};
        acc[c].wasActivated = data.endTime !== Number.POSITIVE_INFINITY;
        return acc;
    }, {});
    return acc;
}, {});
fs.writeFileSync('../finalCoverage.json', JSON.stringify(finalCoverage, null, 4), 'utf8');

const coverageAtActivation = Object.entries(finalCoverage).reduce((acc, item) => {
    const name = item[0];
    const components = item[1];
    acc[name] = Object.entries(components).reduce((acc, item) => {
        const c = item[0];
        const data = item[1];
        if (data.wasActivated) {
            delete data.wasActivated;
            acc[c] = data;
        }
        return acc;
    }, {});
    return acc;
}, {});
fs.writeFileSync('../coverageAtActivation.json', JSON.stringify(coverageAtActivation, null, 4), 'utf8');
