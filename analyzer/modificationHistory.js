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

        acc[component] = item.modifications.reduce((acc, {timestamp, patch}) => {
            acc.push({
                timestamp,
                src: getSourceForPatch(patch, component)
            });
            return acc;
        }, []);

        return acc;
    }, {});
    return acc;
}, {});

fs.writeFileSync('../modificationHistory_full.json', JSON.stringify(modificationHistory, null, 4), 'utf8');


const parseAndPrettifyPatch = (patch) => {
    const dmp = new DiffMatchPatch();
    const dmp_patch = dmp.patch_fromText(patch);
    return dmp_patch.reduce((acc, item) => {
        if (item.diffs) {
            item.diffs.forEach(([type, string]) => {
                type = type === 1 ? 'insertions' : type === -1 ? 'deletions' : 'equalities';
                acc[type].push(string);
            });
        }
        return acc;
    }, {
        insertions: [],
        deletions: [],
        equalities: []
    });
}

const modificationHistoryChanges = Object.entries(attemptsUntilFixed).reduce((acc, [user, item]) => {
    acc[user] = Object.entries(item).reduce((acc, [component, item]) => {
        if (item === 'not fixed') return acc;

        acc[component] = item.modifications.reduce((acc, {timestamp, patch}) => {
            acc.push({
                timestamp,
                changes: parseAndPrettifyPatch(patch)
            });
            return acc;
        }, []);

        return acc;
    }, {});
    return acc;
}, {});

fs.writeFileSync('../modificationHistory_changes.json', JSON.stringify(modificationHistoryChanges, null, 4), 'utf8');
