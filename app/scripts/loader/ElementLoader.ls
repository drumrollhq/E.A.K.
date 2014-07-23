require! 'translations'

messages = translations.loading.messages

module.exports = class ElementLoader extends Backbone.Model
  defaults:
    stage: translations.loading.start
    progress: null

  initialize: ->
    int = set-interval ~>
      messages[Math.floor Math.random! * messages.length] |> @set \stage, _
    , 1500 + (Math.random! * 500)

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
