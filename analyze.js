const {chdir} = require('process');
const path = require('path');
const glob = require('glob');
const exec = file => require(path.resolve(file));

chdir('./analyzer');

glob.sync('_*.js').forEach(exec);
glob.sync('[^_]*.js').forEach(exec);

chdir('..');
