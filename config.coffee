path = require "path"
fs = require "fs"
glob = require "glob"

isDir = (name) -> fs.lstatSync(name).isDirectory()

hasPrefix = (str, sub) ->
  (str.substr 0, sub.length) is sub

vendorInclude = [
  "beautify-css.js"
  "beautify-html.js"
  "beautify.js"
  "rework/rework.js"
]

optimize = ('--optimize' in process.argv) or ('-o' in process.argv)

scripts = []

getJoinTo = =>
  scripts = []
  vexp = /^(bower_components|vendor)/
  if optimize
    out =
      'js/app.js': /^app/
      'js/vendor.js': vexp
  else
    out = {}
    for file in glob.sync "app/scripts/**/*.coffee"
      pOut = file.replace /^app\/scripts/, "js"
      pOut = pOut.replace /\.coffee$/, ".js"
      out[pOut] = new RegExp "^#{file}$"
      scripts.push pOut

    out['js/vendor.js'] = vexp

  out

exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo: getJoinTo()
    stylesheets:
      joinTo: 'css/app.css'
    templates:
      joinTo: 'js/app.js'

  conventions:
    ignored: (file) ->
      if (path.extname file) is ".styl"
        return (path.basename file) isnt "index.styl"

      if hasPrefix file, "vendor/"
        file = file.replace /^vendor\//, ""
        return file not in vendorInclude

      false

  modules:
    nameCleaner: (name) -> name.replace "app/scripts/", ""

  onCompile: ->
    ### LEVELS ###
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

    ### SLOWPARSE ###
    errors = fs.readFileSync "bower_components/slowparse/spec/errors.base.html", encoding: "utf8"
    errors += "\n\n"
    errors += fs.readFileSync "bower_components/slowparse/spec/errors.forbidjs.html", encoding: "utf8"

    fs.writeFileSync "public/data/errors.all.html", errors

    ### CONDITIONAL STUFF ###
    index = fs.readFileSync "public/index.html", encoding: "utf8"

    cond = if @optimize then "UNLESS" else "IF"
    other = if @optimize then "IF" else "UNLESS"

    remove = new RegExp "<!--#{cond}-OPTIMIZED-->[\\s\\S]+?<!--END-#{cond}-OPTIMIZED-->", "g"
    tidy = new RegExp "(<!--#{other}-OPTIMIZED-->)|(<!--END-#{other}-OPTIMIZED-->)", "g"

    index = index.replace remove, ""
    index = index.replace tidy, ""

    scriptsOut = []
    scriptsOut.push "<script src=\"#{script}\"></script>" for script in scripts
    index = index.replace "<!--SCRIPTS-->", scriptsOut.join "\n"

    fs.writeFileSync "public/index.html", index