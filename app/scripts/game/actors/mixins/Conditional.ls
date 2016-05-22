require! 'lib/channels'

module.exports = do
  initialize: ({condition, condition-trigger}) ->
    condition ?= @$el.attr \data-condition
    if typeof condition is \string
      condition = new Function \eak, \store, \areaView, condition

    if not condition then return

    @condition = condition
    @condition-trigger = condition-trigger or @$el.attr \data-condition-trigger
    console.log @{condition, condition-trigger}
    unless @condition-trigger then throw new Error "Missing condition-trigger"

    @_condition-trigger-sub = channels.parse @condition-trigger .subscribe @condition-update.bind this
    @condition-update!

  condition-update: ->
    res = @condition window.eak, @store, @area-view
    if res then @turn-on! else @turn-off!

  remove: ->
    if @_condition-trigger-sub then @_condition-trigger-sub.unsubscribe!
