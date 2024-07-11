const fs = require('fs');
const DiffMatchPatch = require('diff-match-patch');
const attemptsUntilFixed = require('../attemptsUntilFixed_detailed.json');

/**
 * @param {string} patch Diff patch string
 * @param {string} component name of the component
 */
const getSourceForPatch = (patch, component) => {
    const cut = fs.readFileSync(`../cut/${component}.java`, 'utf8');
    const dmp = new DiffMatchPatch();
    return dmp.patch_apply(dmp.patch_fromText(patch), cut)[0];
}

const modificationHistory = Object.entries(attemptsUntilFixed).reduce((acc, [user, item]) => {
    acc[user] = Object.entries(item).reduce((acc, [component, item]) => {
        if (item === 'not fixed') return acc;

        acc[component] = item.modifications.reduce((acc, {patch}) => {
            acc.push(getSourceForPatch(patch, component));
            return acc;
        }, []);

        return acc;
    }, {});
    return acc;
}, {});

fs.writeFileSync('../modificationHistory.json', JSON.stringify(modificationHistory, null, 4), 'utf8');
