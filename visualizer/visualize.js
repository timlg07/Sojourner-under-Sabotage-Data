const R = require('r-integration');
let result = R.executeRScript("./index.R");
console.log(result);
