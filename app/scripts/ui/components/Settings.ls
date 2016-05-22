require! {
  'ui/components/NoUISlider'
}

dom = React.DOM

langs = {
  en: 'English'
  'es-419': 'Español (Latinoamérica)'
  nl: 'Nederlands'
}

slider = (name, value, {on-change = -> null} = {}) ->
  dom.label class-name: \range,
    dom.h4 class-name: \name, name
    dom.span class-name: \value, (Math.round value * 100) + '%'
    React.create-element NoUISlider, value: value, on-change: on-change

module.exports = React.create-class {
  display-name: \Settings
  mixins: [Backbone.React.Component.mixin]

  change-language: (lang) ->
    if confirm l10n \settings.languageWarn
      @get-model!.set \lang lang

  render: ->
    dom.div id: \settings, class-name: \cont,
      dom.h2 null, l10n \settings.title
      slider (l10n \settings.music), @state.model.music-volume, on-change: (value) ~>
        @get-model!.set \musicVolume value
      slider (l10n \settings.effects), @state.model.effects-volume, on-change: (value) ~>
        @get-model!.set \effectsVolume value

      dom.div class-name: \lang-select,
        dom.h4 null, l10n \settings.language
        for let code, name of langs
          dom.button {
            key: code
            class-name: (cx \btn \lang disabled: code is @state.model.lang)
            on-click: ~> @change-language code
          }, name
}
