require('./prepareJsonForR');

const R = require('r-integration');
const config = require('./config.json');
const stdout = R.callMethod("./visualizer/index.R", "main", config);
console.log(stdout);
