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

# Not exactly plugins, but expose a couple of useful globals:
window.$window = $ window
window.$doc = $ document
window.$body = $ document.body
window.$head = $ document.head
