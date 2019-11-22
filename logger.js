const electronLogger = require('electron-log')

// SET UP LOGGING

function log(level, message) {
  if (level === 'info') {
    console.log(message)
    electronLogger.info(message)
  } else if (level === 'warn') {
    console.warn(message)
    electronLogger.warn(message)
  } else if (level === 'error') {
    console.error(message)
    electronLogger.error(message)
  }
}
module.exports.log = log