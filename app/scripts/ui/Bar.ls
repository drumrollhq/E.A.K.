require! {
  'game/event-loop'
  'lib/channels'
  'settings'
  'user'
}

$overlay = $ '#overlay'
$overlay-views = $ '#overlay-views'

module.exports = class Bar extends Backbone.View
  events:
    'click .edit': \edit
    'click .mute': \toggleMute
    'click .settings-button': \toggleSettings
    'click .login': \login
    'click .logout': \logout

  initialize: ({views}) ->
    @views = views
    channels.key-press.filter ( .key in <[ e i ]> ) .subscribe @start-edit
    @$mute-button = @$ '.mute'
    @$settings-button = @$ '.settings-button'
    @$user-bits = @$ '.bar-user-item'
    @$user-button = @$ '.user-button'
    @$login-button = @$ '.login'
    @$logout-button = @$ '.logout'
    settings.on 'change:mute', @render, this
    user.on 'change', @render, this
    @render!

  render: ->
    console.log 'BAR RENDER'
    if settings.get 'mute'
      @$mute-button.remove-class 'fa-volume-up' .add-class 'fa-volume-off'
    else
      @$mute-button.remove-class 'fa-volume-off' .add-class 'fa-volume-up'

    if user.get 'available'
      @$user-bits.remove-class 'hidden'
      if user.get 'loggedIn'
        console.log 'LOGGED IN'
        @$user-button.html user.display-name! .remove-class 'hidden'
        @$login-button.add-class 'hidden'
        @$logout-button.remove-class 'hidden'
      else
        console.log 'NOT LOGGED IN'
        console.log @{$user-button, $login-button, $logout-button}
        @$user-button.add-class 'hidden'
        @$login-button.remove-class 'hidden'
        @$logout-button.add-class 'hidden'
    else
      @$user-bits.add-class 'hidden'

  edit: (e) ~>
    e.prevent-default!
    e.stop-propagation!
    @start-edit!
    e.target.blur!

  start-edit: ~>
    unless event-loop.paused then channels.game-commands.publish command: \edit

  toggle-mute: ->
    settings.set 'mute', not settings.get 'mute'

  toggle-settings: -> if @active-view then @deactivate! else @activate 'settings'
  login: -> @activate 'login'
  logout: -> user.logout!

  activate: (view) ->
    if @active-view is view then return
    if @active-view
      @deactivate false, false
    else
      channels.game-commands.publish command: \pause

    @active-view = view
    active-view = @get-active-view!
    active-view.$el.add-class 'active'
    active-view.once 'close', @deactivate, this
    $overlay.add-class 'active'
    $overlay-views.add-class 'active'
    @$settings-button.add-class 'active'

  deactivate: (overlay = true, resume = true) ->
    old-view = @get-active-view!
    old-view.off 'close', @deactivate, this
    @active-view = null

    to-deactivate = if overlay then [old-view.$el, $overlay] else [old-view.$el]
    to-deactivate.for-each (el) ~>
      el.remove-class 'active' .add-class 'inactive'
      <~ el.one prefixed.animation-end
      el.remove-class 'inactive'
      if el is $overlay then $overlay-views.remove-class 'active'
      if resume
        channels.game-commands.publish command: \resume
        resume := false

    if overlay then @$settings-button.remove-class 'active'

  get-active-view: -> @views[@active-view] or null
