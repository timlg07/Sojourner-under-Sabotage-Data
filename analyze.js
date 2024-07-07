const fs = require('fs');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('./data.pretty.json');
/** @type {string[]} */
const usernames = require('./usernames.json');

const sortedComponents = [
    "CryoSleep",
    "Engine",
    "GreenHouse",
    "ReactorLog",
    "Kitchen"
];

// Attempts until the test for a component passes for the first time per user and component
const _attemptsUntilFirstPass = data.filter(item => item.eventType === 'test-executed')
    .reduce((acc, item) => {
        const failed = item.data.executionResult.testStatus === 'FAILED';
        if (!acc[item.user][item.data.componentName]) {
            acc[item.user][item.data.componentName] = {
                fails: [],
                success: [],
            }
        }
        if (failed) {
            const s = acc[item.user][item.data.componentName].success;
            if (s.length === 0 || s[s.length - 1] >= item.timestamp) {
                acc[item.user][item.data.componentName].fails.push(item.timestamp);
            }
        } else {
            const sa = acc[item.user][item.data.componentName].success;
            if (sa.length === 0 || sa[sa.length - 1] >= item.timestamp) {
                acc[item.user][item.data.componentName].success = [item.timestamp];
            }
            acc[item.user][item.data.componentName].fails =
                acc[item.user][item.data.componentName].fails.filter(fail => fail < item.timestamp)
        }
        return acc;
    }, usernames.map(name => ({ [name]: {} })).reduce((acc, item) => ({ ...acc, ...item }), {}))

//console.log(JSON.stringify(_attemptsUntilFirstPass, null, 4));

const attemptsUntilFirstPass = Object.entries(_attemptsUntilFirstPass).map((k) => {
    return {[k[0]]:Object.entries(k[1]).map(component => {
            const fails = component[1].fails.length;
            const success = component[1].success.length > 0;
            return {[component[0]]:{fails, success}}
        })}
});
//console.log(JSON.stringify(attemptsUntilFirstPass, null, 4));

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
fs.writeFileSync('./timeUntilFirstPass.json', JSON.stringify(_timeUntilFirstPass, null, 4), 'utf8');


// Time until the tests are activated per user and component
const _timeUntilActivation = Object.entries(data
    .filter(item => item.eventType === 'ComponentTestsActivatedEvent' || item.eventType === 'GameProgressionChangedEvent' && item.data.progression.status === 'TEST')
    .reduce((acc, item) => {
        const c = item.data.componentName ?? item.data.progression.componentName;
        if (!acc[item.user][c]) {
            acc[item.user][c] = {
                endTime: Number.POSITIVE_INFINITY,
                startTime: 0,
            }
        }
        if (item.eventType === 'ComponentTestsActivatedEvent') {
            const sa = acc[item.user][c].endTime;
            acc[item.user][c].endTime = Math.min(sa, item.timestamp);
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
fs.writeFileSync('./timeUntilActivation.json', JSON.stringify(_timeUntilActivation, null, 4), 'utf8');


const attemptsUntilFirstPassPerComponent = attemptsUntilFirstPass.reduce((acc, user) => {
    Object.entries(user).forEach((k) => {
        Object.entries(k[1]).forEach((c) => {
            acc.push(c[1])
        })
    });
    return acc;
}, []).reduce((acc, item) => {
    const component = Object.entries(item)[0][0];
    if (!acc?.[component]) {
        acc[component] = {
            fails: 0,
            success: 0,
            user: 0,
        }
    }
    if (item[component].success) {
        acc[component].success++;
    }
    acc[component].fails += item[component].fails;
    acc[component].user++;
    return acc;
}, {});
const attemptsUntilFirstPassPerComponent_sorted = [
    "CryoSleep",
    "Engine",
    "GreenHouse",
    "ReactorLog",
    "Kitchen"
].map(component => {
    const d = attemptsUntilFirstPassPerComponent[component];
    return {[component]: {...d, failsPerUser: d.fails / d.user}}
})
// console.log(JSON.stringify(attemptsUntilFirstPassPerComponent_sorted, null, 4));

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
fs.writeFileSync('./levelReached.json', JSON.stringify(highestLevelReachedPerUser, null, 4), 'utf8');

const reachedAtLeastLevel3 = Object.entries(highestLevelReachedPerUser).filter((k) => k[1] >= 3).reduce((acc, item) => {
    acc[item[0]] = item[1];
    return acc;
}, {});
fs.writeFileSync('./reachedAtLeastLevel3.json', JSON.stringify(reachedAtLeastLevel3, null, 4), 'utf8');
