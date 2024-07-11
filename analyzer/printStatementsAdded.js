const fs = require('fs');
const DiffMatchPatch = require('diff-match-patch');
const attemptsUntilFixed = require('../attemptsUntilFixed_detailed.json');

let allPrints = [];

const filterPrints = str => str.match(/System\.out\.print(ln)?\((.*?)\);/g) ?? [];
const extractPrintContents = str => str.match(/System\.out\.print(?:ln)?\((.*?)\);/)[1];
const merge = (a, b, predicate = (a, b) => a === b) => {
    const c = [...a];
    b.forEach((bItem) => (c.some((cItem) => predicate(bItem, cItem)) ? null : c.push(bItem)))
    return c;
}

/**
 * @param {string} patch Diff patch string
 */
const amountOfPrints = (patch) => {
    const dmp = new DiffMatchPatch();
    const dmp_patch = dmp.patch_fromText(patch);
    return dmp_patch.reduce((acc, item) => {
        if (item.diffs) {
            let insertions = [];
            item.diffs.forEach(([type, string]) => {
                // type: insertion (1), deletion (-1), equality (0)
                if (type === 1) {
                    insertions.push(string);
                }
                // not a single equality or deletion contains a print statement, so we can ignore them here.
            });

            insertions = insertions.flatMap(filterPrints);
            const contents = insertions.map(extractPrintContents);

            acc.prints += insertions.length;
            acc.contents.push(...contents);

            allPrints = merge(allPrints, contents);
        }
        return acc;
    }, {
        prints: 0,
        contents: []
    });
}

const printsAddedPerComponent = Object.entries(attemptsUntilFixed).reduce((acc, [user, item]) => {
    acc[user] = Object.entries(item).reduce((acc, [component, item]) => {
        if (item === 'not fixed') return acc;

        acc[component] = item.modifications.reduce((acc, {patch}) => {
            const {prints, contents} = amountOfPrints(patch);
            acc.maxPrints = Math.max(acc.maxPrints, prints);
            acc.contents = merge(acc.contents, contents);
            return acc;
        }, {
            maxPrints: 0,
            contents: []
        });
        return acc;
    }, {});
    return acc;
}, {});

fs.writeFileSync('../printsAddedPerComponent.json', JSON.stringify(printsAddedPerComponent, null, 4), 'utf8');


// todo: remove?
const printsAddedPerRun = Object.entries(attemptsUntilFixed).reduce((acc, [user, item]) => {
    acc[user] = Object.entries(item).reduce((acc, [component, item]) => {
        if (item === 'not fixed') return acc;

        acc[component] = item.modifications.reduce((acc, {patch}) => {
            acc.push(amountOfPrints(patch));
            return acc;
        }, []);
        return acc;
    }, {});
    return acc;
}, {});

fs.writeFileSync('../printsAddedPerRun.json', JSON.stringify(printsAddedPerRun, null, 4), 'utf8');


// all print contents:
fs.writeFileSync('../printContents.json', JSON.stringify(allPrints, null, 4), 'utf8');
