const save = require('../utils/save');

const flatten = x => Object.entries(x).reduce((acc, [user, item]) => {
    Object.entries(item).forEach(([component, item]) => {
        acc.push({user, component, ...item});
    });
    return acc;
}, []);

const attemptsUntilActivation = require('../attemptsUntilActivation.json');
const attemptsUntilActivation_r = flatten(attemptsUntilActivation);
save('attemptsUntilActivation_r.json', attemptsUntilActivation_r);
