# Globally expose prelude-ls:
window <<< window.prelude-ls

window.$window = $ window
window.$body = $ document.body

# Prefixes:
window.prefixed = {
  animation-end: {
    'WebkitAnimation': 'webkitAnimationEnd'
    'MozAnimation': 'mozanimationend'
    'OAnimation': 'oanimationend'
    'msAnimation': 'MSAnimationEnd'
    'animation': 'animationend'}[Modernizr.prefixed 'animation']
  transition-end: {
    'WebkitTransition': 'webkitTransitionEnd'
    'MozTransition': 'transitionend'
    'transition': 'transitionend'
  }[Modernizr.prefixed 'transition']
  transform: Modernizr.prefixed 'transform'
}

window.prefixed <<< switch
  | document.hidden? => hidden: \hidden, visibility-change: \visibilitychange
  | document.moz-hidden? => hidden: \mozHidden, visibility-change: \mozvisibilitychange
  | document.ms-hidden? => hidden: \msHidden, visibility-change: \msvisibilitychange
  | document.webkit-hidden? => hidden: \webkitHidden, visibility-change: \webkitvisibilitychange
  | otherwise => hidden: false, visibility-change: false

window.animation-end = {
  'WebkitAnimation': 'webkitAnimationEnd'
  'MozAnimation': 'animationend'
  'OAnimation': 'oanimationend'
  'msAnimation': 'MSAnimationEnd'
  'animation': 'animationend'
}[Modernizr.prefixed 'animation']

# This file contains mostly boring jQuery plugins. Stuff gets a little more
# interesting near the bottom where we register some custom elements for using
# with SlowParse
$.fn.show-dialogue = -> @add-class \active .remove-class \disabled

$.fn.hide-dialogue = -> @remove-class \active .add-class \disabled

$.fn.toggle-dialogue = -> if @has-class \active then @hide-dialogue! else @show-dialogue!

d = 300
{each} = _

$.fn.switch-dialogue = (to, fn = -> void) ->
  @hide-dialogue!

  <- set-timeout _, d
  to.show-dialogue!
  fn.call!

$.fn.make-only-shown-dialogue = ->
  dialogues = $ \.dialogue.active
  if dialogues.length is 0 then @show-dialogue! else
    dialogues.each -> $ @ .hide-dialogue!
    <~ set-timeout _, d
    @show-dialogue!

$.hide-dialogues = (fn = -> void) ->
  dialogues = $ \.dialogue.active
  dialogues.each ->
    $ @ .hide-dialogue!
  set-timeout fn, d
  @

$.fn.attention-grab = ->
  @one prefixed.animation-end, ~> @remove-class 'attention-grab'
  @add-class 'attention-grab'

$.fn.serialize-object = -> {[name, value] for {name, value} in @serialize-array!}

# performance.now polyfill
first = Date.now!
unless window.performance?
  window.performance = now: -> Date.now! - first

# Prevent clicking on in-game links
$ document .on \click '.level a[href]' (e) -> e.prevent-default!

# Prevent accidentally going 'back' a page when editing with the backspace key,
# and scrolling with the space bar
$ document.body .on 'keydown' (e) ->
  if e.which is 8 and e.target.tag-name.to-lower-case! isnt 'input' then e.prevent-default!

# Custom elements for KQ levels:
extras = <[ target hints pointer alert hidden tutorial step action content ]>
extras |> each _, (-> document.create-element it)
extras |> each _, (-> Slowparse.HTMLParser::html-elements.push it)

# HBS helpers:
Handlebars.register-helper \inc (value) -> 1 + parse-float value
Handlebars.register-helper \toFixed (n, places) -> n.to-fixed places
Handlebars.register-helper \date (date, fmt) -> moment date .format fmt

get-obj = (obj, path) ->
  | typeof path is \string => get-obj obj, path.split '.'
  | path.length is 0 => obj
  | path.length is 1 => obj[head path]
  | otherwise => get-obj obj[head path], tail path

window.l10n = (path) -> get-obj (require \translations), path
Handlebars.register-helper \l10n window.l10n

Handlebars.register-helper \countrySelectOptions ->
  (require 'ui/templates/country-select')!

PIXI.DisplayObject.prototype.interactive-children = false
# Promised texture loading for pixi:
PIXI.load-texture = (url) -> new Promise (resolve, reject) ~>
  texture = PIXI.Texture.from-image url, false
  if texture.base-texture.has-loaded
    resolve texture
  else
    texture.base-texture.on \loaded, -> resolve texture
    texture.base-texture.on \error, -> reject "Error loading sprite #url"

# PIXI Animate function:
PIXI.Container.prototype.animate = (duration, fn) -> new Promise (resolve, reject) ~>
  old-update-transform = @update-transform
  start = performance.now!
  @update-transform = ->
    old-update-transform.apply this, arguments
    t = min 1, (performance.now! - start) / duration
    fn.call this, t
    if t is 1
      @update-transform = old-update-transform
      resolve!

# Promise / event-emitter helpers:
window.wait-for-event = (subject, event, {timeout, condition} = {}) -> new Promise (resolve, reject) ->
  resolved = false
  handler = (...args) ->
    if resolved then return
    if not condition or (condition and condition ...args)
      resolve args
      resolved := true
      subject.off event, handler

  subject.on event, handler

  if timeout
    <- set-timeout _, timeout
    if resolved then return
    reject new window.wait-for-event.TimeoutError!
    resolved := true

window.wait-for-event.TimeoutError = class TimeoutError extends Error

# Prevent stuff from getting GCd, e.g. to work around https://code.google.com/p/chromium/issues/detail?id=349543
never-gc-name = "_NEVER_GC_#{Date.now!}"
window[never-gc-name] = []
window.never-gc = (val) -> window[never-gc-name][*] = val

FastClick.attach document.body

# use livescript style to-json rather than toJSON:
Backbone.Model.prototype.to-json = Backbone.Model.prototype.to-JSON
Backbone.Collection.prototype.to-json = Backbone.Collection.prototype.to-JSON

# Extract message from error:
window.error-message = (e) ->
  e.response-JSON?.details or
    e.details or
    e.message or
    e.status-text or
    e

# Little Arca spinner icon
$ '.insert-arca-spinner'
  ..add-class 'player entity spinner player-silhouette-white player-left player-running'
  ..html '''
    <div class="player-inner">
      <div class="player-head">
        <div class="player-ear-left"></div>
        <div class="player-ear-right"></div>
        <div class="player-face"></div>
        <div class="player-eyes"></div>
      </div>
      <div class="player-body"></div>
      <div class="player-leg-left"></div>
      <div class="player-leg-right"></div>
    </div>
  '''

# Helpful debuggy thing:
window.pr = (promise) ->
  now = performance.now!
  promise
    .then (result) -> console.log "resolve (#{(performance.now! - now).to-fixed 2}ms)" result
    .catch (err) -> console.log "reject (#{(performance.now! - now).to-fixed 2}ms)" err
  return promise

window.cx = class-names
