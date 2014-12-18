module.exports = class Subscription
  (@channel, @handler) -> @_resub!

  _unsub: ~>
    @channel._unsub @handler
    @_subscribed = false
  _resub: ~>
    @channel._sub @handler
    @_subscribed = true

  unsubscribe: ~>
    if @_subscribed then @_unsub!
    else throw new Error 'Subscription already unsubscribed!'
  subscribe: ~>
    unless @_subscribed then @_resub!
    else throw new Error 'Subscription already subscribed!'

  pause: ~> if @_subscribed then @_unsub!
  resume: ~> unless @_subscribed then @_resub!
