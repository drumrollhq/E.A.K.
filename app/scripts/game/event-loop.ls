require! {
  'lib/channels'
  'lib/keys'
}

raf = window.request-animation-frame or window.moz-request-animation-frame or
  window.webkit-request-animation-frame or window.ms-request-animation-frame or
  (fn) -> set-timeout fn, 16ms
window.request-animation-frame = raf

key-dict = {
  0: \esc, 8: \backspace, 9: \tab, 13: \enter, 16: \shift, 17: \ctrl,
  19: \pausebreak, 18: \alt, 20: \capslock, 27: \escape, 32: \space, 33: \pageup,
  34: \pagedown, 35: \end, 36: \home, 37: \left, 38: \up, 39: \right,
  40: \down, 45: \insert, 46: \delete
}
key-channels = keypress: channels.key-press, keyup: channels.key-up, keydown: channels.key-down

$window = $ window
$body = $ document.body
$document = $ document

class EventLoop
  ->
    @paused = @paused-keys = false
    @last = window.performance.now!
    window.request-animation-frame @frame-driver
    @setup-keys!
    @setup-dom-events!
    @_skip-frame = 0

  frame-driver: ~>
    now = window.performance.now!
    diff = now - @last
    @last = now

    if @_skip-frame > 0
      @_skip-frame--
    else
      channels.pre-frame.publish-sync t: diff
      unless @paused
        channels.frame.publish-sync t: diff

      channels.post-frame.publish-sync t: diff

    window.request-animation-frame @frame-driver

  setup-keys: ~>
    $window .on 'keypress keyup keydown' (e) ~>
      unless @paused-keys
        if e.which in [8 32 37 38 39 40] then e.prevent-default!
        key = key-dict[e.which] or (String.from-char-code e.which .to-lower-case!)
        key-channels[e.type].publish code: e.which, key: key

  setup-dom-events: ~>
    $window .on 'resize' (e) ->
      channels.window-size.publish width: $body.width!, height: $body.height!

    $document.on prefixed.visibility-change, (e) ~>
      @_skip-frame += 5

  pause: ~>
    keys.reset!
    @paused = @paused-keys = true

  pause-keys: ~>
    keys.reset!
    @paused-keys = true

  resume: ~> @paused = @paused-keys = false
  resume-keys: ~> @paused-keys = false

module.exports = new EventLoop!
