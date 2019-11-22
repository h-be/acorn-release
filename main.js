// Modules to control application life and create native browser window
const { app, BrowserWindow, Menu } = require('electron')
const spawn = require('child_process').spawn
const fs = require('fs')
const path = require('path')
const kill = require('tree-kill')
const { log } = require('./logger')
require('electron-context-menu')()
require('fix-path')()
require('electron-debug')()

// ELECTRON
// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow
let quit = false

function createWindow() {

  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      nodeIntegration: true
    }
  })

  // and load the index.html of the app.
  mainWindow.loadURL('file://' + __dirname + '/ui/index.html')

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

let run
function startConductor() {

  if (process.platform === "darwin") {
    run = spawn(path.join(__dirname, "./run-darwin.sh"))
  } else if (process.platform === "linux") {
    run = spawn(path.join(__dirname, "./run-linux.sh"))
  }
  else {
    log('error', "unsupported platform: " + process.platform)
    return
  }
  run.stdout.on('data', data => {
    log('info', data.toString())
    if (data.toString().indexOf("Done. All interfaces started.") > -1) {
      // trigger refresh once we know
      // interfaces have booted up
      mainWindow.loadURL('file://' + __dirname + '/ui/index.html')
    }
  })
  run.stderr.on('data', data => log('error', data.toString()))
  run.on('exit', (code, signal) => {
    if (signal) {
      log('info', `holochain process terminated due to receipt of signal ${signal}`)
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
  createWindow()
  // check if config and keys exist, if they don't, create
  if (fs.existsSync(path.join(__dirname, 'keystore.key'))) {
    startConductor()
    return
  }

  var setupScript
  if (process.platform === "darwin") {
    setupScript = "setup-darwin.sh"
  } else if (process.platform === "linux") {
    setupScript = "setup-linux.sh"
  } else {
    log('error', "unsupported platform: " + process.platform)
    return
  }
  const setup = spawn(path.join(__dirname, setupScript))
  setup.stdout.on('data', data => log('info', data.toString()))
  setup.on('exit', (code) => {
    log('info', code)
    if (code === 0 || code === 127) {
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

const menutemplate = [{
  label: "Application",
  submenu: [
    { label: "About Application", selector: "orderFrontStandardAboutPanel:" },
    { type: "separator" },
    { label: "Quit", accelerator: "Command+Q", click: function () { app.quit() } }
  ]
}, {
  label: "Edit",
  submenu: [
    { label: "Undo", accelerator: "CmdOrCtrl+Z", selector: "undo:" },
    { label: "Redo", accelerator: "Shift+CmdOrCtrl+Z", selector: "redo:" },
    { type: "separator" },
    { label: "Cut", accelerator: "CmdOrCtrl+X", selector: "cut:" },
    { label: "Copy", accelerator: "CmdOrCtrl+C", selector: "copy:" },
    { label: "Paste", accelerator: "CmdOrCtrl+V", selector: "paste:" },
    { label: "Select All", accelerator: "CmdOrCtrl+A", selector: "selectAll:" }
  ]
}
]

Menu.setApplicationMenu(Menu.buildFromTemplate(menutemplate))
