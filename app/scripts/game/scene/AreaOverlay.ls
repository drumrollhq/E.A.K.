require! {
  'game/scene/TiledSpriteContainer'
}

module.exports = class AreaOverlay extends TiledSpriteContainer
  (name, @regions, width, height) ->
    super "/content/bg-tiles/#{name}.overlay", width, height
