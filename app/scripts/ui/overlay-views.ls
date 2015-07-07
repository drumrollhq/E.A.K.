require! {
  'ui/LoginView'
  'ui/PayView'
  'ui/SaveGamesView'
  'ui/SettingsView'
  'ui/SignUpNextView'
  'ui/SignUpView'
  'ui/SubscribeView'
  'ui/TemplateView'
  'ui/ReactView'
}

cache = {}

module.exports = ({user, settings, $overlay-views, save-games, app}) ->
  $view-container = $overlay-views.find \#overlay-view-container
  get-new-view = (name) ->
    switch name
    | \login => new LoginView!
    | \loginLoader => new TemplateView template: 'ui/templates/login-loader'
    | \my-games => new SaveGamesView collection: save-games, app: app
    | \pay => new ReactView component: PayView
    | \settings => new SettingsView model: settings, id: \settings
    | \signup => new SignUpView!
    | \signupLoader => new TemplateView template: 'ui/templates/signup-loader'
    | \signupNext => new SignUpNextView!
    | \subscribe => new ReactView component: SubscribeView
    | otherwise => throw new Error "view #name not found"

  (parent) -> (name) ->
    if cache[name] then return that
    try
      view = cache[name] = get-new-view name
        ..$el.append-to $view-container
        ..parent = parent

      return view
    catch e
      return null
