require('process').chdir('./analyzer');
const path = require('path');
require('glob').sync('*.js').forEach((file) => {
    require(path.resolve(file));
});
