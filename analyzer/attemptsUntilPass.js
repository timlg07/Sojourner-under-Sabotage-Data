const fs = require('fs');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
/** @type {string[]} */
const usernames = require('../usernames.json');


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
fs.writeFileSync('../attemptsUntilFirstPass.json', JSON.stringify(attemptsUntilFirstPass, null, 4), 'utf8');


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
