get-meta = (level) ->
  (name, default-value = null) ->
    level.find "meta[name=\"#{name}\"]" .attr \value or default-value

to-boolean = (str) ->
  str = str.trim!.to-lower-case!
  match str
  | '' => false
  | 'true' or 't' => true
  | 'false' or 'f' => false
  | otherwise => false

to-list = (str = '', delimeter = ' ') ->
  str.trim!.split delimeter

to-coordinates = (str = '0 0') ->
  parts = to-list str
  if parts.length isnt 2 then throw new Error 'Cannot parse coordinates. Wrong number of parts'
  parts.map parse-float

function find-level-settings level
  meta = get-meta level
  conf = {}
  # Set up the HTML/CSS for the level
  conf.html = level.find 'body' .html!
  conf.css = level.find 'style' |> map (-> $ it .text!) |> join '\n\n'

  # Should we display the top bar?
  conf.editable = meta \editable, 'true' |> to-boolean

  # What's the background image for this level?
  conf.bg = meta \background, 'white'

  # Find the level size
  [conf.width, conf.height] = meta \size |> to-coordinates

  # Set player coordinates
  [x, y] = meta \player |> to-coordinates

  # Set player colour
  colour = meta \player-color, 'black'

  conf.player = {x, y, colour}

  # Find borders
  borders = meta \borders, 'all' |> to-list
  if borders.0 is 'all' then borders = <[ top bottom left right ]>
  if borders.0 is 'none' then borders = []
  conf.borders = borders

  # Find music track:
  conf.music = meta \music, 'none'

  conf.targets = meta \targets |> to-list _, ',' |> map to-coordinates |> map ([x, y]) -> {x, y}

  conf

module.exports = {find: find-level-settings}
