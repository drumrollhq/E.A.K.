require! {
  'lib/channels'
  'settings'
  'user'
  'ui/components/CharacterMessages'
}

$body = $ document.body
$overlay-views = $ '#overlay-views'
$character-messages = $ '#character-messages'

module.exports = class Bar extends Backbone.View
  events:
    'click .edit': \edit
    'click .mute': \toggleMute
    'click .settings-button': \toggleSettings
    'click .logout': \logout

  initialize: ({views}) ->
    @views = views this

    @$mute-button = @$ '.mute'
    @$settings-button = @$ '.settings-button'
    @$user-bits = @$ '.bar-user-item'
    @$display-name = @$ '.display-name'
    @$login-button = @$ '.login'
    @$logout-button = @$ '.logout'

    channels.key-press.filter ( .key in <[ e i ]> ) .subscribe @edit
    channels.page.subscribe ({name, prev}) ~> @activate name, prev
    channels.character-message.subscribe (message) ~> @character-messages.activate message
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

    @character-messages = ReactDOM.render (React.create-element CharacterMessages), $character-messages.0

  edit: (e) ~>
    if e.prevent-default
      e.prevent-default!
      e.stop-propagation!
      e.target.blur!
    channels.game-commands.publish command: \edit

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
    view = camelize view
    if view in [\none null] then return @deactivate!
    if @active-view is view then return
    if @active-view
      @deactivate false

    if prev then @prev = prev

    @active-view = view
    active = @get-active-view!
      ..$el.add-class 'active'
      ..once 'close', @close, this

    $overlay-views.add-class 'active'
    @$settings-button.add-class 'active'
    active.activate! if active.activate?
    @trigger \activate view, active

  args: (args) ->
    view = @get-active-view!
    if view and typeof view.args is \function then view.args ...args

  close: ->
    unless @_prevent-close then @deactivate!
    @_prevent-close = false

  prevent-close: ->
    @_prevent-close = true

  deactivate: (all = true) ->
    old-view = @get-active-view!
    old-view-name = @active-view
    unless old-view then return
    console.log 'deactivate' arguments, old-view
    old-view.off 'close', this
    @active-view = null

    el = old-view.$el
    el.remove-class 'active' .add-class 'inactive'
    <~ el.one prefixed.animation-end
    el.remove-class 'inactive'
    if all
      $overlay-views.remove-class 'active' if all
      @trigger \dismiss

    @trigger \deactivate, old-view-name, old-view

  get-active-view: -> (@views @active-view) or null

  show: -> $body.remove-class 'hide-bar'
  hide: -> $body.add-class 'hide-bar'
