// Modules to control application life and create native browser window
const { app, BrowserWindow, Menu, shell } = require('electron')
const spawn = require('child_process').spawn
const fs = require('fs')
const path = require('path')
const kill = require('tree-kill')
const { log, logger } = require('./logger')
require('electron-context-menu')()
require('fix-path')()
// enables the devtools window automatically
// require('electron-debug')({ isEnabled: true })

const { AdminWebsocket } = require('@holochain/conductor-api')

// ELECTRON
// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow
let quit = false

// THESE ARE SIMILAR, but different, than the acorn-hc and development
// veresions of these same ports
const APP_PORT = 8889 // MUST MATCH ACORN_UI config
const ADMIN_PORT = 1235 // MUST MATCH ACORN_UI config
const PROFILES_APP_ID = 'profiles-app' // MUST MATCH ACORN_UI config
const MATCH_ACORN_UI_PROFILES_DNA_NICK = 'profiles.dna.gz'

// a special log from the conductor, specifying
// that the interfaces are ready to receive incoming
// connections
const MAGIC_READY_STRING = 'Conductor ready.'

const HOLOCHAIN_BIN = './holochain'
const LAIR_KEYSTORE_BIN = './lair-keystore'

// TODO: make this based on version number?
const CONFIG_PATH = path.join(app.getPath('appData'), 'AcornNew')
const STORAGE_PATH = path.join(CONFIG_PATH, 'database')
const CONDUCTOR_CONFIG_PATH = path.join(CONFIG_PATH, 'conductor-config.toml')

if (!fs.existsSync(CONFIG_PATH)) {
  fs.mkdirSync(CONFIG_PATH)
  fs.mkdirSync(STORAGE_PATH)
  fs.writeFileSync(
    CONDUCTOR_CONFIG_PATH,
    `
environment_path = "${STORAGE_PATH}"
use_dangerous_test_keystore = false

[[admin_interfaces]]
driver.type = "websocket"
driver.port = ${ADMIN_PORT}`
  )
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
  mainWindow.loadURL('file://' + __dirname + '/ui/index.html')

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

let holochain_handle
let lair_keystore_handle

async function startConductor() {
  lair_keystore_handle = spawn(LAIR_KEYSTORE_BIN, [], {
    cwd: __dirname,
  })
  lair_keystore_handle.stdout.on('data', (data) => {
    log('info', 'lair-keystore: ' + data.toString())
  })
  lair_keystore_handle.stderr.on('data', (data) => {
    log('error', 'lair-keystore> ' + data.toString())
  })
  lair_keystore_handle.on('exit', (_code, _signal) => {
    kill(holochain_handle.pid, function (err) {
      if (!err) {
        log('info', 'killed all holochain sub processes')
      } else {
        log('error', err)
      }
    })
    quit = true
    app.quit()
  })

  await sleep(100)

  holochain_handle = spawn(HOLOCHAIN_BIN, ['-c', CONDUCTOR_CONFIG_PATH], {
    cwd: __dirname,
  })
  holochain_handle.stderr.on('data', (data) => {
    log('error', 'holochain> ' + data.toString())
  })
  holochain_handle.on('exit', (_code, _signal) => {
    kill(lair_keystore_handle.pid, function (err) {
      if (!err) {
        log('info', 'killed all lair_keystore sub processes')
      } else {
        log('error', err)
      }
    })
    quit = true
    app.quit()
  })
  await new Promise((resolve, _reject) => {
    holochain_handle.stdout.on('data', (data) => {
      log('info', 'holochain: ' + data.toString())
      if (data.toString().indexOf(MAGIC_READY_STRING) > -1) {
        resolve()
      }
    })
  })
}

async function installIfFirstLaunch(adminWs) {
  const dnas = await adminWs.listDnas()
  if (dnas.length === 0) {
    let myPubKey = await adminWs.generateAgentPubKey()
    await adminWs.installApp({
      agent_key: myPubKey,
      app_id: PROFILES_APP_ID,
      dnas: [
        {
          nick: MATCH_ACORN_UI_PROFILES_DNA_NICK,
          path: './dna/profiles.dna.gz',
        },
      ],
    })
    await adminWs.activateApp({ app_id: PROFILES_APP_ID })
  }
  await adminWs.attachAppInterface({ port: APP_PORT })
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', async function () {
  createWindow()
  await startConductor()
  const adminWs = await AdminWebsocket.connect(`ws://localhost:${ADMIN_PORT}`)
  await installIfFirstLaunch(adminWs)
  // trigger refresh once we know
  // interfaces have booted up
  mainWindow.loadURL('file://' + __dirname + '/ui/index.html')
})

app.on('will-quit', (event) => {
  // prevents double quitting
  if (!quit) {
    event.preventDefault()
    // SIGTERM by default
  }
  kill(holochain_handle.pid, function (err) {
    if (!err) {
      log('info', 'killed all holochain sub processes')
    } else {
      log('error', err)
    }
  })
  kill(lair_keystore_handle.pid, function (err) {
    if (!err) {
      log('info', 'killed all lair_keystore sub processes')
    } else {
      log('error', err)
    }
  })
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
      {
        label: 'Open Config Folder',
        click: function () {
          shell.openItem(CONFIG_PATH)
        },
      },
      {
        label: 'Show Log File',
        click: function () {
          shell.showItemInFolder(logger.transports.file.file)
        },
      },
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

const sleep = (ms) => new Promise((resolve) => setTimeout(() => resolve(), ms))
