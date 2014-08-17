require! {
  'game/event-loop'
  'logger'
  'translations'
}

animation-end = {
  'WebkitAnimation': 'webkitAnimationEnd'
  'MozAnimation': 'animationend'
  'OAnimation': 'oanimationend'
  'msAnimation': 'MSAnimationEnd'
  'animation': 'animationend'
}[Modernizr.prefixed 'animation']

$body = $ document.body

module.exports = class SettingsView extends Backbone.View
  initialize: ->
    @model.on 'change' @render

    @$mute-button = @$ '.mute'
    @$settings-button = @$ '.settings-button'
    @$overlay = $ '#overlay, #settings'
    @$lang-buttons = @$ '.lang'

    @$ '.range' .each (i, el) ~>
      $el = $ el
      $el.find '.slider' .no-ui-slider {
        start: @model.get $el.data 'prop'
        range: min: 0, max: 1
        step: 0.01
        serialization:
          lower: [$.Link target: $el.find '.value']
          format:
            decimals: 0
            encoder: (x) -> x * 100
            postfix: '%'
      }

    @modal-active = false

    @render!

    # <~ set-timeout _, 500
    # @toggleSettings!

  events:
    'click .mute': 'toggleMute'
    'click .settings-button': 'toggleSettings'
    'slide .range': 'changeSlider'
    'set .range': 'changeSlider'
    'click .lang': 'changeLanguage'

  render: ~>
    @$lang-buttons.remove-class 'disabled'
    @$ ".lang[data-lang=#{@model.get 'lang'}]" .add-class 'disabled'

    if @model.get 'mute'
      @$mute-button.remove-class 'fa-volume-up' .add-class 'fa-volume-off'
    else
      @$mute-button.remove-class 'fa-volume-off' .add-class 'fa-volume-up'

  toggle-mute: ~>
    @model.set 'mute', not @model.get 'mute'

  change-slider: (e, v) ~>
    prop = $ e.current-target .data 'prop'
    value = (parse-int v) / 100
    @model.set prop, value

  change-language: (e) ~>
    $button = $ e.current-target
    lang = $button.data 'lang'

    if confirm translations.settings.language-warn
      @model.set 'lang' lang

  toggle-settings: ~>
    if @modal-active
      @$settings-button.remove-class 'active'

      @$overlay.remove-class 'active' .add-class 'inactive'
      @$overlay.one animation-end, ~>
        @$overlay.remove-class 'inactive'
        unless @was-paused then event-loop.resume!
        $body.remove-class 'paused'

      @modal-active = false

      if @settings-event
        logger.stop @settings-event
        @settings-event = false

    else
      @$settings-button.add-class 'active'
      @$overlay.add-class 'active'

      $body.add-class 'paused'
      @was-paused = event-loop.paused
      event-loop.pause!

      @modal-active = true
      event <~ logger.start 'page' type: 'settings'
      unless @modal-active then logger.stop event.id
      @settings-event = event.id
