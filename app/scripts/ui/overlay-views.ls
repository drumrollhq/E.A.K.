require! {
  'ui/components/Login'
  'ui/components/Subscribe'
  'ui/components/SaveGames'
  'ui/SettingsView'
  'ui/SignUpNextView'
  'ui/SignUpView'
  'ui/TemplateView'
  'ui/ReactView'
}

cache = {}

module.exports = ({user, settings, $overlay-views, save-games, app}) ->
  $view-container = $overlay-views.find \#overlay-view-container
  get-new-view = (name) ->
    switch name
    | \login => new ReactView component: Login
    | \myGames => new ReactView component: SaveGames, collection: save-games, app: app
    | \settings => new SettingsView model: settings, id: \settings
    | \signup => new SignUpView!
    | \signupLoader => new TemplateView template: 'ui/templates/signup-loader'
    | \signupNext => new SignUpNextView!
    | \subscribe => new ReactView component: Subscribe
    | otherwise => throw new Error "view #name not found"

  (parent) -> (name) ->
    if cache[name] then return that
    try
      view = cache[name] = get-new-view name
        ..$el.append-to $view-container
        ..parent = parent

      return view
    catch e
      console.log e
      return null
