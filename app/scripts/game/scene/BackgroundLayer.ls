require! {
  'game/scene/WebglLayer'
}

module.exports = class BackgroundLayer extends WebglLayer
  initialize: (options) ->
    super options
    @background = options.background

  load: ->
    @_load-img @background .then (img) ~>
      @img = img
      img <<< @{width, height}
      # @$el.append img

  _load-img: (src) -> new Promise (resolve, reject) ~>
    img = document.create-element \img
    img.add-event-listener \load, (-> resolve img), false
    img.add-event-listener \error, reject, false
    img.src = src
