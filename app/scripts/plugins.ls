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

# Custom elements for KQ levels:
extras = <[ target hints pointer alert hidden ]>
extras |> each _, (-> document.create-element it)
extras |> each _, (-> Slowparse.HTMLParser::html-elements.push it)

# tap event jQuery plugin
``(function(u,n){"use strict";var r,c,i,a,t,s,e,o,h;r=n.support.touch=!!("ontouchstart"in window||window.DocumentTouch&&u instanceof DocumentTouch),c="._tap",i="tap",a="clientX clientY screenX screenY pageX pageY".split(" "),t={$el:null,x:0,y:0,count:0,cancel:!1},s=function(u,s){var t,e,o,c,i;for(t=s.originalEvent,e=n.Event(t),o=t.changedTouches?t.changedTouches[0]:t,e.type=u,c=0,i=a.length;i>c;c++)e[a[c]]=o[a[c]];return e},e={isEnabled:!1,isTracking:!1,enable:function(){return this.isEnabled?this:(this.isEnabled=!0,n(u.body).on("touchstart"+c,this.onTouchStart).on("touchend"+c,this.onTouchEnd).on("touchcancel"+c,this.onTouchCancel),this)},disable:function(){return this.isEnabled?(this.isEnabled=!1,n(u.body).off("touchstart"+c,this.onTouchStart).off("touchend"+c,this.onTouchEnd).off("touchcancel"+c,this.onTouchCancel),this):this},onTouchStart:function(i){var c,o;c=i.originalEvent.touches,t.count=c.length,e.isTracking||(e.isTracking=!0,o=c[0],t.cancel=!1,t.$el=n(i.target),t.x=o.pageX,t.y=o.pageY)},onTouchEnd:function(n){!t.cancel&&t.count===1&&e.isTracking&&t.$el.trigger(s(i,n)),e.onTouchCancel(n)},onTouchCancel:function(n){e.isTracking=!1,t.cancel=!0}},n.event.special[i]={setup:function(){e.enable()}},r||(o=[],h=function(t){var c,e;c=t.originalEvent,!t.isTrigger&&0>o.indexOf(c)&&(o.length>3&&o.splice(0,o.length-3),o.push(c),e=s(i,t),n(t.target).trigger(e))},n.event.special[i]={setup:function(){n(this).on("click"+c,h)},teardown:function(){n(this).off("click"+c,h)}})})(document,jQuery)``
