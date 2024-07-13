const save = require('../utils/save');

const filesToFlatten = [
    'attemptsUntilActivation',
];

const flatten = x => Object.entries(x).reduce((acc, [user, item]) => {
    Object.entries(item).forEach(([component, item]) => {
        acc.push({user, component, ...item});
    });
    return acc;
}, []);

filesToFlatten.forEach(name => {
    const json = require(`../${name}.json`);
    const json_r = flatten(json);
    save(`${name}_r.json`, json_r);
})
