require! plugins

# Delay: Utility function for simulating computers that can't run EAK at 60FPS:
delay = (ms) ->
  stop = performance.now! + ms
  while performance.now! < stop => null

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

# mediator.paused stops frame and key events from being triggered when true
mediator.paused = false

# You can trigger events using hyperlinks. Use `event:` instead of `http:`
$ document .on \tap '[href^="event:"]' (e) ->
  e.prevent-default!
  e.stop-propagation!

  ev = $ e.target .attr \href .substr 'event:'.length
  mediator.trigger ev

# Trigger events for taps/clicks that aren't caught elsewhere
$doc.on \tap -> unless mediator.paused then mediator.trigger \uncaughtTap

# Debugging. The 'b' key is used to toggle debug info. When it is enabled, frame
# information is shown, and all triggered events apart from the ignored ones are
# logged to the console.
mediator.DEBUG-enabled = false
mediator.DEBUG-el = $ '.debug-data'
DEBUG-ignored-events = <[ frame postframe playermove ]>

mediator.on \all (name, data) ->
  if mediator.DEBUG-enabled and name not in DEBUG-ignored-events
    console.log name, data

mediator.on \keypress:b ->
  mediator.DEBUG-enabled = not mediator.DEBUG-enabled
  mediator.trigger \DEBUG-toggle mediator.DEBUG-enabled

mediator.on \DEBUG-toggle (dbg) ->
  mediator.DEBUG-el.css \display if dbg then \block else \none

# FPS monitor. The 'f' key turns on the fps meter:
mediator.once \keypress:f ->
  stats = mediator.stats = new Stats!
  stats.set-mode 0
  stats.dom-element.style <<< position: 'absolute', bottom: 0, right: 0
  document.body.append-child stats.dom-element

  mediator.on \preframe ->
    stats.begin!
    # Slow things right down for testing
    # delay 50

  mediator.on \postframe ->
    stats.end!

module.exports = mediator
