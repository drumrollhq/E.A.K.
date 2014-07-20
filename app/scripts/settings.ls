require! 'channels'

class Settings extends Backbone.Model
  defaults: ->
    ls = (JSON.parse local-storage.get-item 'eak-settings') or {}
    lang = window.location.pathname |> split '/' |> reject empty |> first
    if lang not in window.LANGUAGES then lang = 'en'

    return {
      lang: lang
      mute: ls.mute or false
      music-volume: ls.music-volume or 0.8
      effects-volume: ls.effects-volume or 1
    }

  initialize: ->
    @on 'change:mute'  ~>
      @publish-mute!
      @save-ls!

    @publish-mute!

  save-ls: ~>
    data = {
      mute: @get 'mute'
      music-volume: @get 'music-volume'
      effects-volume: @get 'effects-volume'
    }
    local-storage.set-item 'eak-settings', JSON.stringify data

  publish-mute: ~>
    channels.track-volume.publish {
      track: \master
      value: if (@get \mute) then 0 else 1
    }

module.exports = new Settings!
