$.fn.showDialogue = ->
  @addClass "active"
  @removeClass "disabled"

$.fn.hideDialogue = ->
  @removeClass "active"
  @addClass "disabled"

$.fn.toggleDialogue = ->
  if @hasClass "active"
    @hideDialogue()
  else
    @showDialogue()
  @

$.fn.switchDialogue = (to) ->
  @hideDialogue()
  setTimeout (-> to.showDialogue()), 300

first = Date.now()

# performance.now polyfill
if window.performance is undefined
  window.performance =
    now: ->
      return Date.now() - first
