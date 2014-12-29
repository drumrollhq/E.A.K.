require! {
  'lib/channels'
  'user/LoginView'
}

$overlay = $ '#overlay, #user'

module.exports = class UserView extends Backbone.View
  initialize: ->
    channels.game-commands.subscribe @game-commands

    @login-view = new LoginView model: @model
    @$el.append @login-view.el

  game-commands: ({command}) ~>
    | command is \start-login => @start-login!

  start-login: ->
    @activate 'login'

  activate: (view) ->
    if @active-view is view then return
    if @active-view
      @deactivate false, false
    else
      channels.game-commands.publish command: 'pause'

    @active-view = view
    @get-active-view!.$el.add-class 'active'

    $overlay.add-class 'active'
    @$el.add-class 'active'

  deactivate: (overlay = true, resume = true) ->
    old-view = @get-active-view!
    @active-view = null

    resumed = not resume
    deactivate = if overlay then [old-view.$el, $overlay] else [old-view.$el]
    deactivate.for-each (el) ->
      el.remove-class 'active' .add-class 'inactive'
      <~ el.one prefixed.animation-end
      el.remove-class 'inactive'
      unless resumed
        channels.game-commands.publish command: 'resume'
        resumed = true

  get-active-view: ->
    name = "#{@active-view}View"
    if @[name]? then @[name] else null
