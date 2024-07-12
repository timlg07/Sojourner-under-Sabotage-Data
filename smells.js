const {exec} = require('child_process');
const {glob} = require("glob");
const {csv2json} = require('json-2-csv');
const fs = require('fs');
const download = require('download');
const save = require('./utils/save');

const removeEmptySmellEntries = true;
const outputFilePattern = 'Output_TestSmellDetection_*.csv';
const ignore = ['node_modules/**', 'test/**', 'cut/**', 'analyzer**'];
const url = 'http://github.com/TestSmells/TestSmellDetector/releases/latest/download/';
const jar = 'TestSmellDetector.jar';

(async () => {
    // download the TestSmellDetector.jar from GitHub if necessary
    if (!fs.existsSync(jar)) {
        await download(url + jar, '.', {extract: false}).pipe(fs.createWriteStream(jar));
    }

    // delete previous output files
    glob.sync(outputFilePattern, {ignore}).forEach(file => {
        fs.unlinkSync(file);
    })

    // run the test smell detector
    exec(`java -jar ${jar} testSmellDetectorInput.csv`, (err, stdout, stderr) => {
        if (err) {
            console.error(err);
            return;
        }
        console.error(stderr);
        const outputFile = glob.sync(outputFilePattern, {ignore})[0];
        transformOutput(outputFile);
    });

    // transform the output to JSON
    function transformOutput(fileName) {
        const csv = fs.readFileSync(fileName, 'utf8');
        const json = csv2json(csv);
        const data = {};

        json.forEach(item => {
            const [username, componentName] = item.App.split('/');

            if (!data[username]) {
                data[username] = {};
            }

            if (item['Dependent Test\r']) {
                item['Dependent Test'] = item['Dependent Test\r'];
                delete item['Dependent Test\r'];
            }

            delete item.App;
            delete item.TestClass;
            delete item.TestFilePath;
            delete item.ProductionFilePath;
            delete item.RelativeTestFilePath;
            delete item.RelativeProductionFilePath;

            if (removeEmptySmellEntries) {
                Object.entries(item).forEach(([key, value]) => {
                    if (value === 0) delete item[key];
                });
            }

            data[username][componentName] = item;
        });

        save('testSmellDetectorOutput.json', data);
    }
})();
