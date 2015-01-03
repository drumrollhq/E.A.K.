require! {
  'ui/LoginView'
  'ui/SettingsView'
  'ui/SignUpNextView'
  'ui/SignUpView'
}

module.exports = ({user, settings, $overlay-views}) -> {
  settings: new SettingsView model: settings, el: '#settings'
  login: new LoginView el: $ '#login'
  login-loader: new Backbone.View el: $overlay-views.find '.login-loader'
  signup: new SignUpView el: $ '#signup'
  signup-loader: new Backbone.View el: $overlay-views.find '.signup-loader'
  signup-next: new SignUpNextView el: $ '#signup-next'
}
