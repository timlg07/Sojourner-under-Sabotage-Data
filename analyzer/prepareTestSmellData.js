const fs = require('fs');
const {resolve} = require("path");
const {json2csv} = require('json-2-csv');
/** @type {Map<string, Map<string, string>>} */
const data = require('../codeAtActivation.json');

function prepareDataFor(username, componentName, testSrc) {
    const appName = `${username}/${componentName}`;
    const srcPath = `../cut/${componentName}.java`;
    const tstPath = `../test/${appName}Test.java`;
    const testDir = tstPath.replace(/\/[^/]+$/, '');

    if (!fs.existsSync(testDir)) {
        fs.mkdirSync(testDir, {recursive: true});
    }
    fs.writeFileSync(tstPath, testSrc, 'utf8');

    return {
        appName,
        pathToTestFile: resolve(tstPath),
        pathToProductionFile: resolve(srcPath),
    };
}

const testSmellDetectorInput = Object.entries(data).reduce((acc, item) => {
    const name = item[0];
    Object.entries(item[1]).forEach(item => {
        const componentName = item[0];
        acc.push(prepareDataFor(name, componentName, item[1]));
    });
    return acc;
}, []);

const csv = json2csv(testSmellDetectorInput, {prependHeader: false});
fs.writeFileSync('../testSmellDetectorInput.csv', csv, 'utf8');
