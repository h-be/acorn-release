const spawn = require('child_process').spawn
const fs = require('fs')
const path = require('path')

// call with `which hc`
const hcPackagePath = process.argv[2]

const { DNA_ADDRESS_FILE } = require('./dna-address-config')

const run = spawn(hcPackagePath, ["package"], {
  cwd: path.join(__dirname, 'acorn-hc'),
})
run.stdout.on('data', data => {
  if (data.toString().indexOf("DNA hash: ") > -1) {
    // trim cuts off any whitespace or newlines
    const dnaAddressPath = path.join(__dirname, DNA_ADDRESS_FILE)
    const dnaAddress = data.toString().replace('DNA hash: ', '').trim()
    fs.writeFileSync(dnaAddressPath, dnaAddress)
  }
})
