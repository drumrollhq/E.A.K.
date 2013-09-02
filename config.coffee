path = require "path"
fs = require "fs"

isDir = (name) -> fs.lstatSync(name).isDirectory()

exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo:
        'js/app.js': /^app/
        'js/vendor.js': /^(bower_components|vendor)/
    stylesheets:
      joinTo: 'css/app.css'
    templates:
      joinTo: 'js/app.js'

  conventions:
    ignored: (file) ->
      if (path.extname file) is ".styl"
        return (path.basename file) isnt "index.styl"

      false

  modules:
    nameCleaner: (name) -> name.replace "app/scripts/", ""

  sourceMaps: false

  onCompile: ->
    fs.mkdirSync "public/data" unless fs.existsSync "public/data"

    # concat and copy level definitions
    levels = (fs.readdirSync "levels").filter (el) ->
      isDir "levels/#{el}"

    levels = levels.map (el) ->
      html: (fs.readFileSync "levels/#{el}/html.html", encoding: "utf8")
      css: (fs.readFileSync "levels/#{el}/style.css", encoding: "utf8")
      config: (JSON.parse fs.readFileSync "levels/#{el}/config.js", encoding: "utf8")

    data =
      levels: levels
      base: (fs.readFileSync "levels/base", encoding: "utf8")

    fs.writeFileSync "public/data/levels.json", JSON.stringify data

    # Copy across slowparse errors
    errors = fs.readFileSync "bower_components/slowparse/spec/errors.base.html", encoding: "utf8"
    errors += "\n\n"
    errors += fs.readFileSync "bower_components/slowparse/spec/errors.forbidjs.html", encoding: "utf8"

    fs.writeFileSync "public/data/errors.all.html", errors
