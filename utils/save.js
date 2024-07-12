const fs = require('fs');
/**
 *
 * @param {string} location path & name of the file to save
 * @param {any} obj the object to save
 */
function save(location, obj) {
    const json = JSON.stringify(obj, null, 4)
                     .concat('\n'); // prevent premature EOF error
    fs.writeFileSync(location, json, 'utf8');
}
module.exports = save;
