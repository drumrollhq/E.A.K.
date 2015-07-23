require! {
  'game/actors/Activatable'
  'lib/channels'
}

module.exports = class Portal extends Activatable
  @from-el = ($el, [href], offset, save-level) ->
    new Portal {
      href: href
      el: $el
      offset: offset
      store: save-level
    }

  mapper-ignore: false

  initialize: (options) ->
    super options
    @href = options.href

  activate: ->
    channels.stage.publish url: @href
