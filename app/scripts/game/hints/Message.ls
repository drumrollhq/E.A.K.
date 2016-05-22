require! 'lib/channels'

module.exports = class Message extends Backbone.View
  initialize: (hint) ~>
    @ <<< hint.{content, from, track}
    @timeout = parse-int hint.timeout if hint.timeout

  render: ~>
    channels.character-message.publish @{content, from, track, timeout}

