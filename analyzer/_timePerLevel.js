const fs = require('fs');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
/** @type {string[]} */
const usernames = require('../usernames.json');


// Time until the tests are activated per user and component
const timePerLevel = Object.entries(data
    .filter(item => item.eventType === 'GameProgressionChangedEvent' && ['DOOR', 'TALK'].includes(item.data.progression.status))
    .reduce((acc, item) => {
        if (acc[item.user] === undefined) {
            acc[item.user] = {};
        }
        if (acc[item.user][item.data.progression.room] === undefined) {
            acc[item.user][item.data.progression.room] = {
                endTime: -1,
                startTime: -1,
            }
        }
        if (acc[item.user][String(item.data.progression.room - 1)] === undefined && item.data.progression.room !== 1) {
            acc[item.user][String(item.data.progression.room - 1)] = {
                endTime: -1,
                startTime: -1,
            }
        }
        if (item.data.progression.status === 'TALK') {
            if (item.data.progression.room === 1) {
                acc[item.user][item.data.progression.room].startTime = item.timestamp;
            }
            return acc;
        }
        acc[item.user][String(item.data.progression.room - 1)].endTime = item.timestamp;
        acc[item.user][item.data.progression.room].startTime = item.timestamp;
        return acc;
    }, usernames.map(name => ({ [name]: {} })).reduce((acc, item) => ({ ...acc, ...item }), {}))
).reduce((acc, k) => {
    acc[k[0]] = Object.entries(k[1]).reduce((acc, component) => {
            if (component[1].endTime < 0) {
                acc[component[0]] = 'not finished';
                return acc;
            }
            if (component[1].startTime < 0) {
                acc[component[0]] = 'not started';
                return acc;
            }
            const time = component[1].endTime - component[1].startTime;
            acc[component[0]] = time / 1e3 / 60;
            return acc;
        }, {});
    return acc;
}, {})
fs.writeFileSync('../timePerLevel.json', JSON.stringify(timePerLevel, null, 4), 'utf8');
