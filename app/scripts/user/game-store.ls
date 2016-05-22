require! {
  'hindquarters'
  'user/local-game-store'
}

module.exports = ->
  require! 'user'
  if user.logged-in! then hindquarters.games else local-game-store
