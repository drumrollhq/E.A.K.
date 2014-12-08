# Chrome has a bug that causes the 'on-ended' callback not to be fired.
# This works around that. https://code.google.com/p/chromium/issues/detail?id=349543

module.exports = on-ended = (duration, cb) ->
  called = false
  callback = (...args) ->
    if called then return
    called = true
    clear-timeout timeout
    cb.apply this, args

  timeout = set-timeout callback, duration * 1.1
  callback
