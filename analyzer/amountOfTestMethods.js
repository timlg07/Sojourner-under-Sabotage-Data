const fs = require('fs');
/** @type {Map<string, Map<string, string>>} */
const data = require('../codeAtActivation.json');
/** @type {string[]} */
const usernames = require('../usernames.json');

function stripComments(src) {
    return src.replace(/\/\*[\s\S]*?\*\/|\/\/.*/g, '');
}

function countTestMethods(src) {
    let count = 0;
    for (const line of src.split('\n')) {
        if (/^\s*@Test\s*/.test(line)) {
            count++;
        }
    }
    return count;
}

const amountOfTestMethods = Object.entries(data).reduce((acc, item) => {
    acc[item[0]] = Object.entries(item[1]).reduce((acc, item) => {
        acc[item[0]] = countTestMethods(stripComments(item[1]));
        return acc;
    }, {});
    return acc;
}, {});

fs.writeFileSync('../amountOfTestMethods.json', JSON.stringify(amountOfTestMethods, null, 4), 'utf8');
