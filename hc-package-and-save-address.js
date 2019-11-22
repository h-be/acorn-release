const spawn = require('child_process').spawn
const fs = require('fs')
const path = require('path')

// call with `which hc`
const hcPackagePath = process.argv[2]

const dnaFileName = 'dna_address'

const run = spawn(hcPackagePath, ["package"], {
  cwd: path.join(__dirname, 'acorn-hc'),
})
run.stdout.on('data', data => {
  if (data.toString().indexOf("DNA hash: ") > -1) {
    const dnaAddress = data.toString().replace('DNA hash: ', '')
    fs.writeFileSync(path.join(__dirname, dnaFileName), dnaAddress)
  }
})
