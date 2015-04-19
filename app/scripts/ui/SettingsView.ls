require! {
  'ui/templates/settings': template
  'lib/channels'
  'game/event-loop'
  'logger'
  'translations'
}

$body = $ document.body

module.exports = class SettingsView extends Backbone.View
  initialize: ->
    @$el.html template!
    @model.on 'change:lang' @render
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

    @render!

  events:
    'slide .range': 'changeSlider'
    'set .range': 'changeSlider'
    'click .lang': 'changeLanguage'

  render: ~>
    @$lang-buttons.remove-class 'disabled'
    @$ ".lang[data-lang=#{@model.get 'lang'}]" .add-class 'disabled'

  change-slider: (e, v) ~>
    prop = $ e.current-target .data 'prop'
    value = (parse-int v) / 100
    @model.set prop, value

  change-language: (e) ~>
    $button = $ e.current-target
    lang = $button.data 'lang'

    if confirm translations.settings.language-warn
      @model.set 'lang' lang
