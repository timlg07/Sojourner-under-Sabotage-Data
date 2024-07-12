const {chdir} = require('process');
const path = require('path');

chdir('./analyzer');

require('glob').sync('*.js').forEach((file) => {
    require(path.resolve(file));
});

chdir('..');
