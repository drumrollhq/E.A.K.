require! {
  'ui/LoginView'
  'ui/SaveGamesView'
  'ui/SettingsView'
  'ui/SignUpNextView'
  'ui/SignUpView'
  'ui/TemplateView'
}

cache = {}

module.exports = ({user, settings, $overlay-views, save-games, app}) ->
  get-new-view = (name) ->
    console.log $overlay-views
    switch name
    | \loginLoader => new TemplateView template: 'ui/templates/login-loader'
    | \login => new LoginView!
    | \my-games => new SaveGamesView collection: save-games, app: app
    | \settings => new SettingsView model: settings, id: \settings
    | \signupLoader => new TemplateView template: 'ui/templates/signup-loader'
    | \signupNext => new SignUpNextView!
    | \signup => new SignUpView!
    | otherwise => throw new Error "view #name not found"

  (parent) -> (name) ->
    if cache[name] then return that
    view = cache[name] = get-new-view name
      ..$el.append-to $overlay-views
      ..parent = parent
    view
