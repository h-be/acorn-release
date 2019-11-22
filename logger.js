
// SET UP LOGGING

function log(level, message) {
  if (level === 'info') {
    console.log(message)
  } else if (level === 'warn') {
    console.warn(message)
  } else if (level === 'error') {
    console.error(message)
  }
}
module.exports.log = log