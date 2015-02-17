require! {
  'api'
  'user/local-game-store'
}

module.exports = ->
  require! 'user'
  if user.logged-in! then api.games else local-game-store
