// Modules to control application life and create native browser window
const { app, BrowserWindow, Menu, protocol } = require('electron')
const spawn = require('child_process').spawn
const fs = require('fs')
const path = require('path')
const kill = require('tree-kill')
const request = require('request')
const { log } = require('./logger')
require('electron-context-menu')()
require('fix-path')()
// enables the devtools window automatically
// require('electron-debug')({ isEnabled: true })

const {
  PROFILES_DNA_ADDRESS_FILE,
  PROJECTS_DNA_ADDRESS_FILE,
} = require('./dna-address-config')

// ELECTRON
// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow
let quit = false

const CONFIG_PATH = path.join(app.getPath('appData'), 'Acorn')
const KEYSTORE_FILE = 'keystore.key'
const CONDUCTOR_CONFIG_FILE = 'conductor-config.toml'
const DNA_CONNECTIONS_FILE = '_dna_connections.json'
const DNA_FOLDER = 'dna'
const PROJECTS_DNA_FILE = 'dna/projects.dna.json'
const STORAGE_PATH = path.join(CONFIG_PATH, 'storage')
const NEW_CONDUCTOR_CONFIG_PATH = path.join(CONFIG_PATH, CONDUCTOR_CONFIG_FILE)
const KEYSTORE_FILE_PATH = path.join(CONFIG_PATH, KEYSTORE_FILE)
const DNA_CONNECTIONS_FILE_PATH = path.join(CONFIG_PATH, DNA_CONNECTIONS_FILE)
const DNA_FOLDER_PATH = path.join(CONFIG_PATH, DNA_FOLDER)

if (!fs.existsSync(CONFIG_PATH)) {
  fs.mkdirSync(CONFIG_PATH)
}
if (!fs.existsSync(STORAGE_PATH)) {
  fs.mkdirSync(STORAGE_PATH)
}

let HC_BIN = './hc'
let HOLOCHAIN_BIN = './holochain'

const ACORN_PROTOCOL_SCHEME = 'acorn-protocol'
/// We want to be able to use localStorage/sessionStorage.
/// Chromium doesn't allow that for every source.
/// Since we are using custom URI schemes to redirect UIs' resources
/// specific URI schemes here to be privileged.
console.log('Registering scheme as privileged:', ACORN_PROTOCOL_SCHEME)
protocol.registerSchemesAsPrivileged([
  {
    scheme: ACORN_PROTOCOL_SCHEME,
    privileges: { standard: true, supportFetchAPI: true, secure: true },
  },
])

const acornFileProtocolCallback = (request, callback) => {
  let url = request.url.substr(ACORN_PROTOCOL_SCHEME.length + 3)
  // /#/ because of react router
  if (url === 'root/' || url.includes('/#/')) {
    url = 'ui/index.html'
  } else if (url.includes('root')) {
    url = url.replace('root', 'ui')
  }

  if (url === 'ui/_dna_connections.json') {
    newpath = DNA_CONNECTIONS_FILE_PATH
  } else {
    newpath = path.normalize(`${__dirname}/${url}`)
  }
  callback({ path: newpath })
}

function createWindow() {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 1000,
    webPreferences: {
      nodeIntegration: true,
    },
  })

  // and load the index.html of the app.
  mainWindow.loadURL(`${ACORN_PROTOCOL_SCHEME}://root`)

  // Open <a href='' target='_blank'> with default system browser
  mainWindow.webContents.on('new-window', function (event, url) {
    event.preventDefault()
    shell.openExternal(url)
  })

  // Open the DevTools.
  // mainWindow.webContents.openDevTools()

  // Emitted when the window is closed.
  mainWindow.on('closed', function () {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null
  })
}

// overwrite the DNA hash address in the conductor-config
// with the up to date one
function updateConductorConfig(publicAddress) {
  const profilesDnaAddress = fs.readFileSync(
    path.join(__dirname, PROFILES_DNA_ADDRESS_FILE)
  )
  // do this step of moving the projects dna over into the AppData folder
  // and naming it by its hash/address
  // for the sake of mirroring holoscape behaviour
  const projectsDnaAddress = fs.readFileSync(
    path.join(__dirname, PROJECTS_DNA_ADDRESS_FILE)
  )
  fs.mkdirSync(DNA_FOLDER_PATH)
  fs.copyFileSync(
    path.join(__dirname, PROJECTS_DNA_FILE), // source
    path.join(DNA_FOLDER_PATH, `${projectsDnaAddress}.dna.json`) // destination
  )

  // read from the local template
  const origConductorConfigPath = path.join(__dirname, CONDUCTOR_CONFIG_FILE)
  const conductorConfig = fs.readFileSync(origConductorConfigPath).toString()

  // replace persistence_dir
  let newConductorConfig = conductorConfig.replace(
    /persistence_dir = ''/g,
    `persistence_dir = "${CONFIG_PATH}"`
  )
  // replace dna
  newConductorConfig = newConductorConfig.replace(
    /hash = ''/g,
    `hash = "${profilesDnaAddress}"`
  )
  // replace agent public key
  newConductorConfig = newConductorConfig.replace(
    /public_address = ''/g,
    `public_address = "${publicAddress}"`
  )
  // replace key path
  newConductorConfig = newConductorConfig.replace(
    /keystore_file = ''/g,
    `keystore_file = "${KEYSTORE_FILE_PATH}"`
  )
  // replace pickle db storage path
  newConductorConfig = newConductorConfig.replace(
    /path = 'picklepath'/g,
    `path = "${STORAGE_PATH}"`
  )

  // write to a folder we can write to
  fs.writeFileSync(NEW_CONDUCTOR_CONFIG_PATH, newConductorConfig)
}

let run

function startConductor() {
  run = spawn(HOLOCHAIN_BIN, ['-c', NEW_CONDUCTOR_CONFIG_PATH], {
    cwd: __dirname,
    env: {
      ...process.env,
      RUST_BACKTRACE: 'full',
    },
  })
  run.stdout.on('data', (data) => {
    log('info', data.toString())
    if (data.toString().indexOf('Listening on http://127.0.0.1:3111') > -1) {
      // we need the _dna_connections.json to be a file
      // readable by the UI, over the ACORN_PROTOCOL_SCHEME
      // so we request it from the conductor
      // and write the response to a file
      request(
        'http://127.0.0.1:3111/_dna_connections.json',
        { json: true },
        (err, res, body) => {
          fs.writeFileSync(DNA_CONNECTIONS_FILE_PATH, JSON.stringify(body))
          // trigger refresh once we know
          // interfaces have booted up
          mainWindow.loadURL(`${ACORN_PROTOCOL_SCHEME}://root`)
        }
      )
    }
  })
  run.stderr.on('data', (data) => log('error', data.toString()))
  run.on('exit', (code, signal) => {
    if (signal) {
      log(
        'info',
        `holochain process terminated due to receipt of signal ${signal}`
      )
    } else {
      log('info', `holochain process terminated with exit code ${code}`)
    }
    quit = true
    app.quit()
  })
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', function () {
  protocol.registerFileProtocol(
    ACORN_PROTOCOL_SCHEME,
    acornFileProtocolCallback,
    (error) => {
      if (error) throw error
    }
  )

  createWindow()
  // check if config and keys exist, if they don't, create
  if (fs.existsSync(KEYSTORE_FILE_PATH)) {
    startConductor()
    return
  }

  log(
    'info',
    'could not find existing public key, now creating one and running setup'
  )

  let publicAddress
  const setup = spawn(
    HC_BIN,
    ['keygen', '--path', KEYSTORE_FILE_PATH, '--nullpass', '--quiet'],
    {
      cwd: __dirname,
    }
  )
  setup.stdout.once('data', (data) => {
    // first line out of two is the public address
    publicAddress = data.toString().split('\n')[0]
  })
  setup.stderr.on('data', (err) => {
    log('error', err.toString())
  })
  setup.on('exit', (code) => {
    log('info', code)
    if (code === 0 || code === 127) {
      // to avoid rebuilding key-config-gen
      // all the time, according to new DNA address
      // we can just update it after the fact this way
      updateConductorConfig(publicAddress)
      startConductor()
    } else {
      log('error', 'failed to perform setup')
    }
  })
})

app.on('will-quit', (event) => {
  if (!quit) {
    event.preventDefault()
    // SIGTERM by default
    run &&
      kill(run.pid, function (err) {
        log('info', 'killed all sub processes')
      })
  }
})

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On macOS it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', function () {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) createWindow()
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.

const menutemplate = [
  {
    label: 'Application',
    submenu: [
      { label: 'About Application', selector: 'orderFrontStandardAboutPanel:' },
      { type: 'separator' },
      {
        label: 'Quit',
        accelerator: 'Command+Q',
        click: function () {
          app.quit()
        },
      },
    ],
  },
  {
    label: 'Edit',
    submenu: [
      { label: 'Undo', accelerator: 'CmdOrCtrl+Z', selector: 'undo:' },
      { label: 'Redo', accelerator: 'Shift+CmdOrCtrl+Z', selector: 'redo:' },
      { type: 'separator' },
      { label: 'Cut', accelerator: 'CmdOrCtrl+X', selector: 'cut:' },
      { label: 'Copy', accelerator: 'CmdOrCtrl+C', selector: 'copy:' },
      { label: 'Paste', accelerator: 'CmdOrCtrl+V', selector: 'paste:' },
      {
        label: 'Select All',
        accelerator: 'CmdOrCtrl+A',
        selector: 'selectAll:',
      },
    ],
  },
]

Menu.setApplicationMenu(Menu.buildFromTemplate(menutemplate))
