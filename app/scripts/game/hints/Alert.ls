require! 'channels'

module.exports = class AlertPointer extends Backbone.View
  initialize: (hint) ~> @message = hint.content
  render: ~> channels.alert.publish msg: @message
