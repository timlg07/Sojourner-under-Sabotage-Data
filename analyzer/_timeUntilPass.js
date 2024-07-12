const save = require('../utils/save');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
/** @type {string[]} */
const usernames = require('../usernames.json');


// Time until the test for a component passes for the first time per user and component
const _timeUntilFirstPass = Object.entries(data
    .filter(item => item.eventType === 'test-executed' || item.eventType === 'GameProgressionChangedEvent' && item.data.progression.status === 'TEST')
    .reduce((acc, item) => {
        const c = item.data.componentName ?? item.data.progression.componentName;
        if (!acc[item.user][c]) {
            acc[item.user][c] = {
                endTime: Number.POSITIVE_INFINITY,
                startTime: 0,
            }
        }
        if (item.eventType === 'test-executed') {
            const failed = item.data.executionResult.testStatus === 'FAILED';
            if (!failed) {
                const sa = acc[item.user][c].endTime;
                acc[item.user][c].endTime = Math.min(sa, item.timestamp);
            }
        } else {
            acc[item.user][c].startTime = item.timestamp;
        }
        return acc;
    }, usernames.map(name => ({ [name]: {} })).reduce((acc, item) => ({ ...acc, ...item }), {}))
).map((k) => {
    return {[k[0]]:Object.entries(k[1]).map(component => {
            if (component[1].endTime === Number.POSITIVE_INFINITY) {
                return {[component[0]]:'not finished'}
            }
            const time = component[1].endTime - component[1].startTime;
            return {[component[0]]:time / 1e3 / 60}
        })}
}).map((user) => {
    return {[Object.keys(user)[0]]:(user[Object.keys(user)[0]]).reduce((acc, item) => {
            acc[Object.keys(item)[0]] = Object.values(item)[0];
            return acc;
        }, {})}
}).reduce((acc, item) => {
    acc[Object.keys(item)[0]] = item[Object.keys(item)[0]];
    return acc;
});

save('../timeUntilFirstPass.json', _timeUntilFirstPass);
