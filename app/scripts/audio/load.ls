require! {
  'audio/context'
  'assets'
}

decoded = {}

module.exports = function fetch-audio-data url
  if decoded[url] then return that
  buffer = assets.load-asset "#{url}.#{context.format}", \buffer
  console.log {buffer}
  context.decode-audio-data-async buffer
    .tap (audio) -> decoded[url] = audio

