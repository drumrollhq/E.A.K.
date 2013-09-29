# Needs plugins for performance.now:
require "plugins"

class Mediator extends Backbone.Model
  # Extra binding functionality
  # Most of Backbone.Event's methods start with an event name. We can use
  # coffeescript's internal representation of "super" to easily modify all of
  # them at once.
  eventModifier = (type, index = 0) ->
    ->
      event = arguments[index]
      if event is undefined
        # Internal coffeescript "super"
        Mediator.__super__[type].apply @, arguments
        return

      e = event.split ":"
      if e.length is 1
        Mediator.__super__[type].apply @, arguments
        return

      specifics = e[1].split(",")
      if specifics.length is 1
        Mediator.__super__[type].apply @, arguments
        return

      for specific in specifics
        arguments[index] = "#{e[0]}:#{specific}"
        Mediator.__super__[type].apply @, arguments

  # Assume the event name is at index 0. The second argument overrides this
  on: eventModifier "on"
  off: eventModifier "off"
  trigger: eventModifier "trigger"
  once: eventModifier "once"
  listenTo: eventModifier "listenTo", 1
  stopListening: eventModifier "stopListening", 1
  listenToOnce: eventModifier "listenToOnce", 1

mediator = new Mediator()

raf = window.requestAnimationFrame or window.mozRequestAnimationFrame or
  window.webkitRequestAnimationFrame or window.msRequestAnimationFrame or
  (fn) =>
    setTimeout fn, 16

window.rAF = raf

last = window.performance.now()

# 100 point moving average for monitoring the frame rate
intervals = (16 for [0..100])
lastWasProcess = false

msToFPS = FPSToMs = (ms) -> 1000/ms

fpsLimit = 55
limit = FPSToMs fpsLimit
runAt = [60, 30].map FPSToMs

mediator.paused = false

frameDebug = (avg, diff, type) ->
  if mediator.DEBUG_enabled
    mediator.DEBUG_el.text "Frame mode: #{type}; Actual: #{(msToFPS avg).toFixed 2}fps; Limit: #{fpsLimit}fps; Emulated: #{(msToFPS diff).toFixed 2}fps;"

frameDriver = =>
  n = performance.now()
  diff = n - last
  last = n

  unless mediator.paused
    intervals.push diff
    intervals.shift()

    avg = 0
    avg += int for int in intervals
    avg = avg / intervals.length

    if avg <= limit
      diff = runAt[0]

      mediator.trigger "frame", diff
      mediator.trigger "frame:process", diff
      mediator.trigger "frame:render", diff

      frameDebug avg, diff, "normal"
    else #if avg <= lim2
      # FIXME: proper intervals for slower frame rates
      diff = runAt[1]

      if lastWasProcess is false
        lastWasProcess = true
        mediator.trigger "frame", diff
        mediator.trigger "frame:process", diff
      else
        mediator.trigger "frame:render", diff
        lastWasProcess = false

      frameDebug avg, diff, "split"

  window.rAF frameDriver

window.rAF frameDriver

# Event links
$(document).on "tap", '[href^="event:"]', (e) ->
  e.preventDefault()
  e.stopPropagation()
  href = ($ e.target).attr "href"
  ev = href.substr "event:".length
  mediator.trigger ev

$body = $ document.body
$notificationContainer = $ "<div></div>"
$notificationContainer.addClass "notification-container"
$notificationContainer.appendTo $body

transitionEnd = {
  "WebkitAnimation": "webkitAnimationEnd"
  "MozAnimation": "animationend"
  "OAnimation": "oanimationend"
  "msAnimation": "MSAnimationEnd"
  "animation": "animationend"}[Modernizr.prefixed "animation"]

mediator.on "alert", (msg) ->
  $alert = $ "<div></div>"
  $alert.addClass "notification"

  $inner = $ "<div></div>"
  $inner.addClass "notification-inner"
  $inner.text msg
  $inner.appendTo $alert

  $alert.prependTo $notificationContainer

  setTimeout =>
    $alert.on transitionEnd, ->
      $alert.remove()
    $alert.addClass "hidden"
  , 5000

$window = $ window

$window.on "resize", =>
  mediator.trigger "resize"

  mediator.orientation = if $window.width() > $window.height() then "landscape" else "portrait"

# FIXME: Hack to find out if the browser is running Gecko. Gecko reports values
# for device orientation differently to webkit browsers, and it appears (based
# on my interpretation of the spec) that webkit has the correct implementation.
# Unfortunately, there is no way to check this without browser sniffing :(
isGecko = 'mozInnerScreenX' of window

lim = 30
snap = 5
s = Math.PI / (lim - snap)
tiltHandler = (e) ->
  t = if mediator.orientation is "portrait" then e.gamma else e.beta
  if isGecko then t = -t

  # Cosine is symmetric, we can ignore the sign and replace it later
  negative = t < 0
  t = Math.abs t

  # map t to snap < t < lim
  t = snap if t < snap
  t = lim if t > lim

  # Convert t to scaled radians (accounting for snap and limit)
  t = t - snap
  t *= s

  # Smooth out everything
  tilt = (1 - Math.cos t) / 2

  # Restore the sign
  tilt *= -1 if negative

  mediator.trigger "tilt", tilt

window.addEventListener "deviceorientation", tiltHandler, false

$doc = $ document

$doc.on "tap", (e) ->
  unless mediator.paused
    mediator.trigger "uncaughtTap"

# Debugging:
mediator.DEBUG_enabled = false
mediator.DEBUG_el = $ ".debug-data"

mediator.on "keypress:b", ->
  mediator.DEBUG_enabled = not mediator.DEBUG_enabled
  mediator.trigger "DEBUG_toggle", mediator.DEBUG_enabled

DEBUG_ignoredEvents = ["frame", "frame:process", "frame:render", "playermove"]
mediator.on "all", (type, stuff) ->
  if mediator.DEBUG_enabled and type not in DEBUG_ignoredEvents then console.log type

mediator.on "DEBUG_toggle", (dbg) ->
  mediator.DEBUG_el.css "display", if dbg then "block" else "none"

# Key events:
keydict = 8: "backspace", 9: "tab", 13: "enter", 16: "shift", 17: "ctrl",
19: "pausebreak", 18: "alt", 20: "capslock", 27: "escape", 32: "space", 33: "pageup",
34: "pagedown", 35: "end", 36: "home", 37: "left", 38: "up", 39: "right",
40: "down", 45: "insert", 46: "delete"

$window.on "keypress keyup keydown", (e) ->
  code = if keydict[e.which] isnt undefined then keydict[e.which] else
    (String.fromCharCode e.which).toLowerCase()

  unless mediator.paused
    mediator.trigger e.type
    mediator.trigger "#{e.type}:#{code}", e

mediator.store = {}

module.exports = mediator
