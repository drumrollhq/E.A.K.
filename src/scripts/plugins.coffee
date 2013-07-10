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
