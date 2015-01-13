require! {
  'lib/parse': {to-boolean, to-list, to-coordinates, to-object}
}

get-meta = (level) ->
  (name, default-value = null) ->
    level.find "meta[name=\"#{name}\"]" .attr \content or default-value

parse-body = (src) -> src.match /<body>([\s\S]+)<\/body>/i .1.trim!

function find-level-settings level
  meta = get-meta level
  conf = {}

  conf.glitch = (level.find 'meta[name=glitch]' .0)?

  # Set up the HTML/CSS for the level
  conf.html = if conf.glitch then parse-body level.source else level.find 'body' .html!
  conf.css = level.find 'style' |> map (-> $ it .text!) |> join '\n\n'

  # Hidden elements, hints, and tutorials:
  conf.hidden = level.find 'head hidden' .children!
  conf.hints = level.find 'head hints' .children!
  conf.tutorial = level.find 'head tutorial'
  conf.has-tutorial = !!conf.tutorial.length

  # Should we display the top bar?
  conf.editable = meta \editable, 'true' |> to-boolean

  # Should we reset the player position when editing?
  conf.reset-player-on-edit = meta \reset-player-on-edit, 'false' |> to-boolean

  # What's the background image for this level?
  conf.bg = meta \background 'white'

  # Find the level size
  [conf.width, conf.height] = meta \size |> to-coordinates

  # Set player coordinates
  [x, y] = meta \player |> to-coordinates

  # Set player colour
  colour = meta \player-color, 'black'

  conf.player = {x, y, colour}

  # Find borders
  borders = meta \borders, 'none' |> to-list
  if borders.0 is 'all' then borders = <[ top bottom left right ]>
  if borders.0 is 'none' then borders = []
  conf.borders = borders

  conf.border-contract = meta \border-contract, '0' |> parse-float

  # How can arca exit?
  conf.exits = meta \exits, '' |> to-object

  # Find music track:
  conf.music = meta \music, 'none'

  conf.targets = meta \targets |> to-list _, ',' |> map to-coordinates |> map ([x, y]) -> {x, y}

  conf

module.exports = {find: find-level-settings, get-meta}
