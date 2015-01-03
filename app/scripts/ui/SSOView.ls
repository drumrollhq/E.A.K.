require! {
  'api'
  'user'
}

module.exports = class SSOView extends Backbone.View
  initialize: ->
    window.add-event-listener 'message' (e) ~>
      if e.source is @sso-window then @sso-callback e.data

  sso: (provider) ->
    if not @sso-window? or @sso-window.closed
      @sso-window = window.open api.auth.url provider, redirect: api.auth.url 'js-return'
      @sso-provider = provider
    else if @sso-provider is provider
      @sso-window.focus!
    else
      @sso-window.close!
      @sse-provider = @sso-window = null
      @sso provider

  sso-callback: (data) ->
    @sso-window.close!
    window.focus!
    user.set-user data
    switch data.status
    case 'active'
      @trigger 'close'
    case 'creating'
      @parent.activate 'signupNext'

  sso-button-click: (e) ~>
    $el = $ e.target
    switch
    | $el.has-class 'sso-google' => @sso 'google'
    | $el.has-class 'sso-facebook' => @sso 'facebook'
