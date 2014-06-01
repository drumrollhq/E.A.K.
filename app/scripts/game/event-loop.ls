require! 'channels'

raf = window.request-animation-frame or window.moz-request-animation-frame or
  window.webkit-request-animation-frame or window.ms-request-animation-frame or
  (fn) -> set-timeout fn, 16ms
window.request-animation-frame = raf

module.exports = event-loop = {
  init: ->
    event-loop.last = window.performance.now!
    window.request-animation-frame event-loop.frame-driver

  frame-driver: ->
    now = window.performance.now!
    diff = now - event-loop.last
    event-loop.last = now

    channels.pre-frame.publish t: diff
    channels.frame.publish t: diff
    channels.post-frame.publish t: diff

    window.request-animation-frame event-loop.frame-driver
}

