require! {
  'user'
}

exports.setup = (key) ->
  script = document.create-element \script
  script.add-event-listener \load -> zzish-setup key
  script.src = 'https://www.zzish.com/dist/zzish.js'
  document.head.append-child script

Zzish = null

zzish-setup = (key) ->
  Zzish := Promise.promisify-all window.Zzish
  exports.api = Zzish
  Zzish.init key
  user.fetch!
    .then ->
      unless user.logged-in! then return
      Zzish.get-user-async user.id, user.display-name!
    .then ->
      console.log arguments

