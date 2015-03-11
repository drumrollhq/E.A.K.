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
  if e.which in [8 32] and e.target.tag-name.to-lower-case! isnt 'input' then e.prevent-default!

# Custom elements for KQ levels:
extras = <[ target hints pointer alert hidden tutorial step action content ]>
extras |> each _, (-> document.create-element it)
extras |> each _, (-> Slowparse.HTMLParser::html-elements.push it)

# HBS helpers:
Handlebars.register-helper \inc (value) -> 1 + parse-float value

Handlebars.register-helper \date (date, fmt) -> moment date .format fmt

FastClick.attach document.body

# use livescript style to-json rather than toJSON:
Backbone.Model.prototype.to-json = Backbone.Model.prototype.to-JSON
Backbone.Collection.prototype.to-json = Backbone.Collection.prototype.to-JSON

# Extract message from error:
window.error-message = (e) ->
  e.response-JSON?.details or
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
