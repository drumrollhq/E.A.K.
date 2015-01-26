require! {
  'game/event-loop'
  'lib/channels'
  'settings'
  'user'
}

$body = $ document.body
$overlay-views = $ '#overlay-views'

module.exports = class Bar extends Backbone.View
  events:
    'click .edit': \edit
    'click .mute': \toggleMute
    'click .settings-button': \toggleSettings
    'click .logout': \logout

  initialize: ({views}) ->
    @views = views
    @setup-views!

    @$mute-button = @$ '.mute'
    @$settings-button = @$ '.settings-button'
    @$user-bits = @$ '.bar-user-item'
    @$display-name = @$ '.display-name'
    @$login-button = @$ '.login'
    @$logout-button = @$ '.logout'

    channels.key-press.filter ( .key in <[ e i ]> ) .subscribe @start-edit
    channels.page.subscribe ({name, prev}) ~> @activate name, prev
    settings.on 'change:mute', @render, this
    user.on 'change', @render, this

    @render!

  render: ->
    if settings.get 'mute'
      @$mute-button.remove-class 'fa-volume-up' .add-class 'fa-volume-off'
    else
      @$mute-button.remove-class 'fa-volume-off' .add-class 'fa-volume-up'

    if user.get 'available'
      @$user-bits.remove-class 'hidden'
      if user.get 'loggedIn'
        @$display-name.html user.display-name!
        @$login-button.add-class 'hidden'
        @$logout-button.remove-class 'hidden'
      else
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

  toggle-settings: ->
    if @active-view
      @trigger 'dismiss'
    else
      window.location.hash = '#/app/settings'

  login: -> @activate 'login'
  logout: -> user.logout!

  activate: (view, prev) ->
    if view in [\none null] then return @deactivate!
    if @active-view is view then return
    if @active-view
      @deactivate false

    if prev then @prev = prev

    @active-view = view
    active = @get-active-view!
      ..$el.add-class 'active'
      ..once 'close', @deactivate, this

    $overlay-views.add-class 'active'
    @$settings-button.add-class 'active'
    active.activate! if active.activate?

  deactivate: (all = true) ->
    old-view = @get-active-view!
    unless old-view then return
    old-view.off 'close', @deactivate, this
    @active-view = null

    el = old-view.$el
    el.remove-class 'active' .add-class 'inactive'
    <~ el.one prefixed.animation-end
    el.remove-class 'inactive'
    $overlay-views.remove-class 'active' if all

  get-active-view: -> @views[@active-view] or null

  setup-views: ->
    for name, view of @views
      view.parent = this

  show: -> $body.remove-class 'hide-bar'
  hide: -> $body.add-class 'hide-bar'
