// This file adjusts the path property of HTML href and src with create-react-app so
// that they work when we use them as file based values instead

const path = require('path')
const fs = require('fs')
const package = require('./holochain-basic-chat/ui-src/package.json')

package.homepage = '.'
fs.writeFileSync(path.join(__dirname, 'holochain-basic-chat/ui-src/package.json'), JSON.stringify(package, null, 2))