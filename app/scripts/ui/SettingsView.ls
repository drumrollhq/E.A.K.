module.exports = class SettingsView extends Backbone.View
  initialize: ->
    @model.on 'change' @render
    @$mute-button = @$ '.mute'
    @render!

  events:
    'click .mute': 'toggleMute'

  render: ~>
    if @model.get 'mute'
      @$mute-button.remove-class 'fa-volume-up' .add-class 'fa-volume-off'
    else
      @$mute-button.remove-class 'fa-volume-off' .add-class 'fa-volume-up'

  toggle-mute: ~>
    @model.set 'mute', not @model.get 'mute'

