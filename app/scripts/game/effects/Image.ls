require! {
  'assets'
}

module.exports = class Image extends PIXI.Sprite
  (url, width, height, x, y) ->
    super PIXI.Texture.from-image assets.load-asset url, \url
    this <<< {width, height, x, y}
