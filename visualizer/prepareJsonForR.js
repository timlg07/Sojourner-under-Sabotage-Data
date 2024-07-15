const fs = require('fs');
const save = require('../utils/save');

const filesToFlatten2 = [
    'attemptsUntilActivation',
    'attemptsUntilFirstPass',
    'timeUntilActivation',
    'timeUntilFirstPass',
    'attemptsUntilFixed_summary',
    'destroyedOrAlarm',
];
const filesToFlatten = [
    'levelReached',
];

const outputDir = './visualizer/r_json';

const appendValue = (obj, value) => {
    if (typeof value === 'object' && Object.keys(value).length > 0) {
        return {...obj, ...value};
    } else {
        return {...obj, value};
    }
}

const flatten2 = x => Object.entries(x).reduce((acc, [user, item]) => {
    Object.entries(item).forEach(([componentName, item]) => {
        acc.push(appendValue({user, componentName}, item));
    });
    return acc;
}, []);

const flatten = x => Object.entries(x).map(([user, item]) => appendValue({user}, item));

const batchFlatten = (array, flattener) => array.forEach(name => {
    const json = require(`../${name}.json`);
    const json_r = flattener(json);
    save(`${outputDir}/${name}_r.json`, json_r);
});

if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
}

batchFlatten(filesToFlatten2, flatten2);
batchFlatten(filesToFlatten, flatten);
