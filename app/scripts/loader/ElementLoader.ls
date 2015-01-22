require! 'translations'

module.exports = class ElementLoader extends Backbone.Model
  defaults:
    progress: null

  initialize: ->
    m, to-load <~ @on \change:toLoad

    if to-load is 0
      @trigger \done
      @set \stage ''
      clear-interval int

  start: ~>
    $el = @get \el
    $images = $el.find \img
    to-load = 0

    $images.each (i, img) ~>
      unless img.complete
        to-load++

        img.add-event-listener \load (e) ~>
          @set \toLoad (@get \toLoad) - 1

    @set \toLoad to-load
