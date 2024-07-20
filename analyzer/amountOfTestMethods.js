const save = require('../utils/save');
/** @type {Map<string, Map<string, string>>} */
const data = require('../codeAtActivation.json');

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

function countAllMethods(src) {
    let count = 0;
    for (const line of src.split('\n')) {
        if (/^\s*public\s+void\s+\w+\(\s*\)\s*\{/.test(line)) {
            count++;
        }
    }
    return count;
}

const delta = {count: 0, componentNames: [], code: []};
const amountOfTestMethods = Object.entries(data).reduce((acc, item) => {
    acc[item[0]] = Object.entries(item[1]).reduce((acc, item) => {
        const src = stripComments(item[1]);
        acc[item[0]] = {
            methods: countAllMethods(src),
            testAnnotations: countTestMethods(src)
        };
        const currentDelta = acc[item[0]].methods - acc[item[0]].testAnnotations;
        if (currentDelta > 0) {
            delta.count += currentDelta;
            delta.componentNames.push(item[0]);
            delta.code.push([src]);
        }
        return acc;
    }, {});
    return acc;
}, {});

save('../amountOfTestMethods.json', amountOfTestMethods);

// console.log('Delta:', delta);
