require! {
  'hindquarters'
  'user'
}

module.exports = {
  component-did-mount: ->
    @_message-handler = (e) ~>
      if e.source is @sso-window then @sso-callback e.data

    window.add-event-listener \message, @_message-handler

  component-will-unmount: ->
    window.remove-event-listener \message, @_message-handler

  sso: (provider) ->
    if not @sso-window? or @sso-window.closed
      @sso-window = window.open "#{hindquarters.root}/v1/auth/#{provider}/?redirect=/v1/auth/js-return"
      @sso-provider = provider
    else if @sso-provider is provider
      @sso-window.focus!
    else
      @sso-window.close!
      @sso-provider = @sso-window = null
      @sso provider

  sso-callback: (data) ->
    @sso-window.close!
    window.focus!
    user.set-user data
    switch data.status
    | \active => @props.on-close!
    | \creating => window.location.hash = '/app/signup-next'

  sso-button: (provider-id, msg) ->
    React.DOM.button class-name: (cx \sso "sso-#provider-id"), on-click: (~> @sso provider-id), msg
}
