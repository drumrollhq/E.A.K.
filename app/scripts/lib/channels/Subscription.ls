module.exports = class Subscription
  (@channel, @handler, @once = false) ->
    if typeof @handler isnt \function then throw new TypeError "Handler should be a function, not #{typeof @handler}"
    @_resub!

  _unsub: ~>
    @channel._unsub @handler
    @_subscribed = false

  _resub: ~>
    @channel._sub @handler, @once
    @_subscribed = true

  unsubscribe: ~>
    if @_subscribed then @_unsub!
    @handler = null

  subscribe: ~>
    console.warn 'Subscription.subscribe is deprecated, use Subscription.resume instead'
    @resume!

  pause: ~> if @_subscribed then @_unsub!
  resume: ~> unless @_subscribed then @_resub!
