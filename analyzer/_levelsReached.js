const fs = require('fs');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
/** @type {string[]} */
const usernames = require('../usernames.json');

const highestLevelReachedPerUser = usernames.map(name => {
    let acc = 0;
    data
        .filter(item => item.user === name)
        .forEach((item) => {
            if (item.eventType === 'GameProgressionChangedEvent') {
                acc = Math.max(acc, item.data.progression.room);
            }
        })
    return {[name]: acc};
}).reduce((acc, item) => {
    const name = Object.keys(item)[0];
    acc[name] = item[name];
    return acc;
});
fs.writeFileSync('../levelReached.json', JSON.stringify(highestLevelReachedPerUser, null, 4), 'utf8');

const reachedAtLeastLevel3 = Object.entries(highestLevelReachedPerUser).filter((k) => k[1] >= 3).reduce((acc, item) => {
    acc[item[0]] = item[1];
    return acc;
}, {});
fs.writeFileSync('../reachedAtLeastLevel3.json', JSON.stringify(reachedAtLeastLevel3, null, 4), 'utf8');
