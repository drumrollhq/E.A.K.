require! {
  'ui/LoginView'
  'ui/SaveGamesView'
  'ui/SettingsView'
  'ui/SignUpNextView'
  'ui/SignUpView'
}

module.exports = ({user, settings, $overlay-views, save-games}) -> {
  login-loader: new Backbone.View el: $overlay-views.find '.login-loader'
  login: new LoginView el: $ '#login'
  my-games: new SaveGamesView collection: save-games, el: $overlay-views.find '#save-games'
  settings: new SettingsView model: settings, el: '#settings'
  signup-loader: new Backbone.View el: $overlay-views.find '.signup-loader'
  signup-next: new SignUpNextView el: $ '#signup-next'
  signup: new SignUpView el: $ '#signup'
}
