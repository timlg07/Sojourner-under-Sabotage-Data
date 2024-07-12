const save = require('../utils/save');
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

save('../levelReached.json', highestLevelReachedPerUser);


const reachedAtLeastLevel3 = Object.entries(highestLevelReachedPerUser).filter((k) => k[1] >= 3).reduce((acc, item) => {
    acc[item[0]] = item[1];
    return acc;
}, {});

save('../reachedAtLeastLevel3.json', reachedAtLeastLevel3);
