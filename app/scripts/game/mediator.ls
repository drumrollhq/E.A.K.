require! plugins

class Mediator extends Backbone.Model
  sc = Backbone.Model.prototype
  # Extra event bindings. This allows us to listen on 'eventname:a,b,c'
  # as an alias for 'eventname:a', 'eventname:b' and 'eventname:c',
  # for example. Type is the name of the Backbone.Events function - e.g.
  # `on` and index is the position of the event name - 0 by default,
  # set it to 1 for things like listenTo
  event-modifier = (type, index = 0) ->
    !->
      event = arguments[index]

      # If there's no event, just call super
      if event is undefined
        sc[type].apply @, arguments
        return

      # Backbone events are in the format 'event:specific'. We're interested
      # in the `specific` part
      e = event / ':'

      if e.length is 1
        sc[type].apply @, arguments
        return

      specifics = e.1 / ','

      if specifics.length is 1
        sc[type].apply @, arguments
        return

      # If we've got more than one specific, call the function for all of them
      for specific in specifics
        arguments[index] = "#{e.0}:#specific"
        sc[type].apply @, arguments

  # Override events from Backbone.Events with our modified ones
  on: event-modifier \on
  off: event-modifier \off
  trigger: event-modifier \trigger
  once: event-modifier \once
  listen-to: event-modifier \listenTo 1
  stop-listening: event-modifier \stopListening 1
  listen-to-once: event-modifier \listenToOnce 1

# Everything else is on a specific instance of mediator:
mediator = new Mediator!

# jQuery usefulness
$window = $ window
$doc = $ document
$body = $ document.body

# Yay vendor prefixes!
raf = window.request-animation-frame or window.moz-request-animation-frame or
  window.webkit-request-animation-frame or window.ms-request-animation-frame or
  (fn) -> set-timeout fn, 16ms

window.rAF = raf

animation-end = {
  'WebkitAnimation': 'webkitAnimationEnd'
  'MozAnimation': 'animationend'
  'OAnimation': 'oanimationend'
  'msAnimation': 'MSAnimationEnd'
  'animation': 'animationend'
}[Modernizr.prefixed \animation]

# mediator.paused stops frame and key events from being triggered when true
mediator.paused = false

# time monitoring stuff:
# last is the timestamp of the previous frame
last = window.performance.now!

# intervals stores the last 100 frame durations for calculating fps
intervals = [16ms] * 100

# Was the last frame event frame:process?
last-was-process = false

ms-to-fps = fps-to-ms = (ms) -> 1000 / ms

# We try to run at 60fps, triggering `frame`, `frame:process`, and `frame:render`
# on every frame. If the average frame rate drops below fps-limit, we switch to
# triggering `frame`/`frame:process` and `frame:render` on alternate frames,
# simulating 30 fps. There are probably more elegant ways of doing this.
fps-limit = 55fps
ms-limit = fps-to-ms fps-limit
run-at = [60fps 30fps].map fps-to-ms

# Frame related debug info
frame-debug = (avg, diff, type) ->
  if mediator.DEBUG-enabled
    mediator.DEBUG-el.text "Frame mode: #{type}; Actual: #{(msToFPS avg).toFixed 2}fps; Limit: #{fpsLimit}fps; Emulated: #{(msToFPS diff).toFixed 2}fps;"

# frame-driver dispatches frame events
frame-driver = ~>
  n = performance.now!
  diff = n - last
  last := n

  unless mediator.paused
    # Calculate 100-point moving average
    intervals.push diff
    intervals.shift!

    avg = 0
    for int in intervals => avg += int
    avg = avg / intervals.length

    if avg <= ms-limit
      # We're running at ~60fps
      diff = run-at.0

      mediator.trigger \frame diff
      mediator.trigger \frame:process diff
      mediator.trigger \frame:render diff

      frame-debug avg, diff, \normal

  else
    # Drop down to 30fps with alternate frame mode
    # TODO: Proper intervals, with more than 2 frame modes.

    diff = run-at.1

    # Split frames up
    if last-was-process
      mediator.trigger \frame:render diff
    else
      mediator.trigger \frame diff
      mediator.trigger \frame:render diff

    last-was-process = not last-was-process

  window.rAF frame-driver

window.rAF frame-driver

# You can trigger events using hyperlinks. Use `event:` instead of `http:`
$ document .on \tap '[href^="event:"]' (e) ->
  e.prevent-default!
  e.stop-propagation!

  ev = $ e.target .attr \href .substr 'event:'.length
  mediator.trigger ev

# The `alert` event triggers a notification. These are loosely based on OSX
# notifications. TODO: make notifications resize to fit their content.
# Animation etc. is handled all in CSS.
$notification-container = $ '<div></div>'
  ..add-class \notification-container
  ..append-to $body

mediator.on \alert (msg) ->
  $alert = $ '<div></div>'
    ..add-class \notification
    ..prepend-to $notification-container

  $inner = $ '<div></div>'
    ..add-class \notification-inner
    ..text msg
    .. append-to $alert

  # Notifications are hidden after 5 seconds
  <- set-timeout _, 5000ms
  $alert.add-class \hidden

  <- $alert.on animation-end
  $alert.remove!

# Trigger events for taps/clicks that aren't caught elsewhere
$doc.on \tap -> unless mediator.paused then mediator.trigger \uncaughtTap

# Debugging. The 'b' key is used to toggle debug info. When it is enabled, frame
# information is shown, and all triggered events apart from the ignored ones are
# logged to the console.
mediator.DEBUG-enabled = false
mediator.DEBUG-el = $ '.debug-data'
DEBUG-ignored-events = <[ frame frame:process frame:render playermove ]>

mediator.on \all (name, data) ->
  if mediator.DEBUG-enabled and name not in DEBUG-ignored-events
    console.log name, data

mediator.on \keypress:b ->
  mediator.DEBUG-enabled = not mediator.DEBUG-enabled
  mediator.trigger \DEBUG-toggle mediator.DEBUG-enabled

mediator.on \DEBUG-toggle (dbg) ->
  mediator.DEBUG-el.css \display if dbg then \block else \none

# Key events
# Us the names of non alpha-numeric keys
keydict = do
  8: \backspace, 9: \tab, 13: \enter, 16: \shift, 17: \ctrl,
  19: \pausebreak, 18: \alt, 20: \capslock, 27: \escape, 32: \space, 33: \pageup,
  34: \pagedown, 35: \end, 36: \home, 37: \left, 38: \up, 39: \right,
  40: \down, 45: \insert, 46: \delete

$window.on 'keypress keyup keydown' (e) ->
  code = keydict[e.which] or (String.from-char-code e.which .to-lower-case!)

  unless mediator.paused
    mediator.trigger e.type
    mediator.trigger "#{e.type}:#code" e

module.exports = mediator
