require! {
  'api'
  'user'
  'user/login': template
}

module.exports = class LoginView extends Backbone.View
  initialize: ->
    window.add-event-listener 'message' (e) ~>
      if e.source is @sso-window then @sso-callback e.data

  events:
    'click .sso-google': 'withGoogle'
    'click .sso-facebook': 'withFacebook'

  with-google: -> @sso 'google'
  with-facebook: -> @sso 'facebook'

  sso: (provider) ->
    if not @sso-window? or @sso-window.closed
      @sso-window = window.open api.auth.url provider, redirect: api.auth.url 'js-return'
      @sso-provider = provider
      console.log @sso-window
    else if @sso-provider is provider
      @sso-window.focus!
    else
      @sso-window.close!
      @sso-provider = @sso-window = null
      @sso provider

  sso-callback: (data) ->
    @sso-window.close!
    window.focus!
    if data.status is 'active'
      user.set-user data
      @trigger 'close'
