if AudioContext?
  module.exports = new AudioContext!
else if webkitAudioContext?
  module.exports = new webkitAudioContext!
else
  module.exports = false
