available-formats = <[mp3 ogg]>
# Check which formats are available
formats = available-formats.filter (format) -> Modernizr.audio[format] is 'probably'

# If there are none, check for other potentials
if empty formats
  formats = available-formats.filter (format) -> Modernizr.audio[format] is 'maybe'

# Still none? Nothing we can do...
if empty formats then return module.exports = false

format = first formats

if AudioContext?
  module.exports = new AudioContext!
else if webkitAudioContext?
  module.exports = new webkitAudioContext!
else
  module.exports = false

module.exports.format = format

module.exports.decode-audio-data-async = (data) -> new Promise (resolve, reject) ->
  module.exports.decode-audio-data data, resolve, reject
