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

module.exports = mediator