require! 'channels'

class Settings extends Backbone.Model
  defaults: ->
    ls = (JSON.parse local-storage.get-item 'eak-settings') or {}
    lang = window.location.pathname |> split '/' |> reject empty |> first
    if lang not in window.LANGUAGES then lang = 'en'

    ret = {
      lang: lang
      mute: ls.mute or false
      music-volume: if ls.music-volume? then ls.music-volume else 0.8
      effects-volume: if ls.effects-volume? then ls.effects-volume else 0.8
    }

    return ret

  initialize: ->
    @on 'change:mute' ~> @publish-mute!
    @on 'change:musicVolume' ~> @publish-volume 'music'
    @on 'change:effectsVolume' ~> @publish-volume 'effects'
    @on 'change:lang' ~> @switch-lang!
    @on 'change' ~> @save!

    @publish-mute!
    @publish-volume 'music'
    @publish-volume 'effects'

  _save: ~>
    data = {
      mute: @get 'mute'
      music-volume: @get 'musicVolume'
      effects-volume: @get 'effectsVolume'
    }
    local-storage.set-item 'eak-settings', JSON.stringify data

  save: ~>
    if @_save-thottled
      @_save-thottled!
    else
      @_save-thottled = _.throttle @_save, 1000ms, leading: false
      @_save-thottled!

  publish-mute: ~>
    channels.track-volume.publish {
      track: \master
      value: if (@get \mute) then 0 else 1
    }

  publish-volume: (name) ->
    channels.track-volume.publish {
      track: name
      value: @get "#{name}Volume"
    }

  switch-lang: (lang = @get 'lang') ~>
    document.cookie = "eak-lang=#{lang};"
    window.location.href = "/#{lang}/play/#{window.location.hash}"

module.exports = new Settings!
