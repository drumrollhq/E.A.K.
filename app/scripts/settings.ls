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
      effects-volume: ls.effects-volume or 0.8
    }

  initialize: ->
    @on 'change:mute'  ~>
      @publish-mute!
      @save!

    @publish-mute!

  _save: ~>
    console.log 'Save settings'
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

module.exports = new Settings!
