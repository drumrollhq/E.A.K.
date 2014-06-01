module.exports = class Subscription
  (sub, @channel) ->
    @handler = sub.callback
    @_subscribed = true

  _unsub: ~>
    @channel.unsubscribe @handler
    @_subscribed = false
  _resub: ~>
    @channel.subscribe @handler
    @_subscribed = true

  unsubscribe: ~>
    if @_subscribed then @_unsub!
    else throw new Error 'Subscription already unsubscribed!'

  subscribe: ~>
    unless @_subscribed then @_resub!
    else throw new Error 'Subscription already subscribed!'

  pause: ~> if @_subscribed then @_unsub!
  resume: ~> unless @_subscribed then @_resub!
