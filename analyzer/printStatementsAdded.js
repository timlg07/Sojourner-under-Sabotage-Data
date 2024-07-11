const fs = require('fs');
const DiffMatchPatch = require('diff-match-patch');
const attemptsUntilFixed = require('../attemptsUntilFixed_detailed.json');

const filterPrints = str => str.match(/System\.out\.print(ln)?\((.*?)\);/g) ?? [];
const extractPrintContents = str => str.match(/System\.out\.print(?:ln)?\((.*?)\);/)[1];

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
        }
        return acc;
    }, {
        prints: 0,
        contents: []
    });
}

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
