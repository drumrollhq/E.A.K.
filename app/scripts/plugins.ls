# Globally expose prelude-ls:
window <<< window.prelude-ls

# Prefixes:
window.prefixed = {
  animation-end: {
    'WebkitAnimation': 'webkitAnimationEnd'
    'MozAnimation': 'mozanimationend'
    'OAnimation': 'oanimationend'
    'msAnimation': 'MSAnimationEnd'
    'animation': 'animationend'}[Modernizr.prefixed 'animation']
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

# performance.now polyfill
first = Date.now!
unless window.performance?
  window.performance = now: -> Date.now! - first

# Prevent clicking on in-game links
$ document .on \click '.level a[href]' (e) -> e.prevent-default!

# Prevent accidentally going 'back' a page when editing with the backspace key:
$ document.body .on 'keydown' (e) -> if e.which is 8 then e.prevent-default!

# Custom elements for KQ levels:
extras = <[ target hints pointer alert hidden tutorial step action content ]>
extras |> each _, (-> document.create-element it)
extras |> each _, (-> Slowparse.HTMLParser::html-elements.push it)

# Number increment hbs helper:
Handlebars.register-helper \inc (value) -> 1 + parse-float value

FastClick.attach document.body
