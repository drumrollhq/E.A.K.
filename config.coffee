path = require "path"
fs = require "fs"
glob = require "glob"
L10N = require "l10n-lsc"

l10n = new L10N
  content: 'app/l10n-content'
  templates: 'app/l10n-templates'
  out: 'public'
  defaultLang: 'en'

isDir = (name) -> fs.lstatSync(name).isDirectory()

hasPrefix = (str, sub) ->
  (str.substr 0, sub.length) is sub

vendorInclude = [
  "beautify-css.js"
  "beautify-html.js"
  "beautify.js"
  "rework/rework.js"
]

workerInclude = [
  "bower_components/box2dweb/Box2dWeb-2.1.a.3.js"
  "bower_components/underscore/underscore.js"
]

optimize = ('--optimize' in process.argv) or ('-o' in process.argv)

scripts = []

# Hack Slowparse to expose some of its internals. This is really dirty. I should find a way of doing this properly:
spFile = 'bower_components/slowparse/slowparse.js'
sp = fs.readFileSync spFile, encoding: 'utf8'
a = "// ### Exported Symbols\n  //\n  // `Slowparse` is the object that holds all exported symbols from\n  // this library.\n  var Slowparse = {"

b = "// ### Exported Symbols - HACKILY MODIFIED FOR EAK!\n  //\n  // `Slowparse` is the object that holds all exported symbols from\n  // this library.\n  var Slowparse = {\n    HTMLParser: HTMLParser,"

sp = sp.replace a, b

fs.writeFileSync spFile, sp

getJoinTo = =>
  scripts = []
  vexp = /^(bower_components|vendor)/
  workerBits = (file) -> (file in workerInclude) or (file.match /^app\/workers\//) isnt null
  if optimize
    out =
      'js/app.js': /^app/
      'js/vendor.js': vexp
      'js/worker.js': workerBits
  else
    out = {}
    for file in glob.sync "app/scripts/**/*.coffee"
      pOut = file.replace /^app\/scripts/, "js"
      pOut = pOut.replace /\.coffee$/, ".js"
      out[pOut] = new RegExp "^#{file}$"
      scripts.push '/' + pOut

    for file in glob.sync "app/scripts/**/*.ls"
      pOut = file.replace /^app\/scripts/, "js"
      pOut = pOut.replace /\.ls$/, ".js"
      out[pOut] = new RegExp "^#{file}$"
      scripts.push '/' + pOut

    out['js/vendor.js'] = vexp
    out['js/worker.js'] = workerBits

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
    nameCleaner: (name) ->
      name = name.replace "app/scripts/", ""
      name = name.replace "app/workers/", ""

  onCompile: ->
    # Run localization before anything else:
    l10n.localise()

    fs.mkdirSync "public/data" unless fs.existsSync "public/data"

    ### SLOWPARSE ###
    errors = fs.readFileSync "bower_components/slowparse/spec/errors.base.html", encoding: "utf8"
    errors += "\n\n"
    errors += fs.readFileSync "bower_components/slowparse/spec/errors.forbidjs.html", encoding: "utf8"

    fs.writeFileSync "public/data/errors.all.html", errors

    ### CONDITIONAL STUFF ###
    htmlFile = glob.sync "public/**/*.html"
    for file in htmlFile
      game = fs.readFileSync file, encoding: "utf8"

      cond = if @optimize then "UNLESS" else "IF"
      other = if @optimize then "IF" else "UNLESS"

      remove = new RegExp "<!--#{cond}-OPTIMIZED-->[\\s\\S]+?<!--END-#{cond}-OPTIMIZED-->", "g"
      tidy = new RegExp "(<!--#{other}-OPTIMIZED-->)|(<!--END-#{other}-OPTIMIZED-->)", "g"

      game = game.replace remove, ""
      game = game.replace tidy, ""

      scriptsOut = []
      scriptsOut.push "<script src=\"#{script}\"></script>" for script in scripts
      game = game.replace "<!--SCRIPTS-->", scriptsOut.join "\n"

      fs.writeFileSync file, game

    ### WORKER INIT ###
    unless workerMarked
      worker = fs.readFileSync "public/js/worker.js", encoding: "utf8"
      worker = """
        if (self.window === undefined) {global = self;}
        #{worker}
        require("base");
      """
      fs.writeFileSync "public/js/worker.js", worker

      workerMarked = yes

workerMarked = no
