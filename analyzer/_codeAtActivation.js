const save = require('../utils/save');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
/** @type {string[]} */
const usernames = require('../usernames.json');


// Time until the tests are activated per user and component
const finalCode = Object.entries(data
    .filter(item => item.eventType === 'ComponentTestsActivatedEvent' || item.eventType === 'test-modified')
    .reduce((acc, item) => {
        const c = item.data.componentName;
        if (!acc[item.user][c]) {
            acc[item.user][c] = {
                endTime: Number.POSITIVE_INFINITY,
                modifications: []
            }
        }
        if (item.eventType === 'ComponentTestsActivatedEvent') {
            acc[item.user][c].endTime = item.timestamp;
        } else if (acc[item.user][c].endTime > item.timestamp) {
            acc[item.user][c].modifications.push(item);
        }
        return acc;
    }, usernames.map(name => ({ [name]: {} })).reduce((acc, item) => ({ ...acc, ...item }), {}))
).reduce((acc, item) => {
    const name = item[0];
    const components = item[1];
    acc[name] = Object.entries(components).reduce((acc, item) => {
        const c = item[0];
        const data = item[1];
        acc[c] = {sourceCode: data.modifications.reduce((acc, item) => {
            if (data.endTime >= item.timestamp && item.timestamp >= acc.timestamp) {
                return item;
            }
            return acc;
        }, {timestamp: 0}).data.sourceCode};
        acc[c].wasActivated = data.endTime !== Number.POSITIVE_INFINITY;
        return acc;
    }, {});
    return acc;
}, {});
save('../finalCode.json', finalCode);

const codeAtActivation = Object.entries(finalCode).reduce((acc, item) => {
    const name = item[0];
    const components = item[1];
    acc[name] = Object.entries(components).reduce((acc, item) => {
        const c = item[0];
        const data = item[1];
        if (data.wasActivated) {
            acc[c] = data.sourceCode;
        }
        return acc;
    }, {});
    return acc;
}, {});
save('../codeAtActivation.json', codeAtActivation);

const codeAtActivation_formatted = Object.entries(codeAtActivation).reduce((acc, item) => {
    const name = item[0];
    const components = item[1];
    acc[name] = Object.entries(components).reduce((acc, item) => {
        const c = item[0];
        acc[c] = item[1].split('\n');
        return acc;
    }, {});
    return acc;
}, {});

save('../codeAtActivation_formatted.json', codeAtActivation_formatted);
