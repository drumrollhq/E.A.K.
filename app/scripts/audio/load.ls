require! 'audio/context'

cache = {}

module.exports = function fetch-audio-data url
  if cache[url]? then return Promise.resolve cache[url]

  Promise
    .resolve $.ajax {
      type: \GET
      url: "#{url}.#{context.format}?_v=#{EAKVERSION}"
      data-type: \arraybuffer
    }
    .then context.decode-audio-data-async
    .tap (audio) -> cache[url] = audio

