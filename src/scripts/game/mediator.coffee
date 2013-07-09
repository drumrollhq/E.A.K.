mediator = new Backbone.Model()

raf = window.requestAnimationFrame or window.mozRequestAnimationFrame or
  window.webkitRequestAnimationFrame or window.msRequestAnimationFrame or
  (fn) =>
    setTimeout fn, 16

window.rAF = raf

frameDriver = =>
  mediator.trigger "frame"
  window.rAF frameDriver

window.rAF frameDriver

mediator.on "alert", (msg) ->
  # TODO: remove browser alert
  alert msg

$window.on "resize", =>
  mediator.trigger "resize"

# Debug:
mediator.on "all", (type) ->
  if type isnt "frame" then console.log arguments

module.exports = mediator