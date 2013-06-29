fs = require "fs"
path = require "path"

module.exports = (grunt) ->

  copyDir = (from, to) ->
    grunt.file.recurse from, (abspath, rootdir, subdir, filename) ->
      subdir or= ""

      fromPath = path.join from, subdir, filename
      toPath = path.join to, subdir, filename

      grunt.file.copy fromPath, toPath

  grunt.initConfig
    uglify:
      options:
        mangle:
          except: ['jQuery', 'Backbone', '_', '$', 'Modernizr', 'require']
      libs:
        files:
          "public/libs/libs.min.js": "public/libs/libs.js"

      scripts:
        files:
          "public/js/index.min.js": ["public/js/**/*.js", "!public/js/index.min.js"]

    coffee:
      scripts:
        options:
          bare: true
        expand: true
        cwd: "src/scripts/"
        src: ["**/*.coffee"]
        dest: "tmp/src/"
        ext: ".js"

    commonjs:
      scripts:
        cwd: "tmp/src/"
        src: "**/*.js"
        dest: "tmp/dest/"

    stylus:
      dev:
        options:
          paths: ['node_modules/grunt-contrib-stylus/node_modules']
          linenos: true
          compress: false

        files:
          'public/styles/main.css': 'src/styles/index.styl'

      production:
        options:
          paths: ['node_modules/grunt-contrib-stylus/node_modules']
          linenos: false
          compress: true

        files:
          'public/styles/main.css': 'src/styles/index.styl'

    watch:
      options:
        nospawn: true

      scripts:
        files: ["src/scripts/**/*"]
        tasks: ["scripts"]

      stylus:
        files: ["src/styles/**/*"]
        tasks: ["stylus:dev"]

      levels:
        files: ["levels/**/*"]
        tasks: ["levels"]

      build:
        files: ["src/**/*", "!src/scripts/**/*", "!src/styles/**/*"]
        tasks: ["build"]

  grunt.registerTask "default", ["build"]

  # Main task: basically, do everything.
  grunt.registerTask "build", (type = "dev") ->
    if type isnt "dev" and type isnt "production"
      grunt.log.error "Unrecognised: #{type}. Only \"dev\" and \"production\" allowed."
      return false

    dev = type is "dev"

    # Start with a blank canvas
    grunt.file.delete "public"

    # Copy across libs
    grunt.task.run "libs:#{type}"

    # Convert source files
    grunt.task.run "scripts:#{type}"

    # Convert styles
    grunt.task.run "stylus:#{type}"

    # Grab level definitions
    grunt.task.run "levels"


  # Pull level definitions into data/levels.json
  grunt.registerTask "levels", ->
    levels = (fs.readdirSync "levels").filter (el) ->
      grunt.file.isDir "levels/#{el}"

    levels = levels.map (el) ->
      html: grunt.file.read "levels/#{el}/html.html"
      css: grunt.file.read "levels/#{el}/style.css"
      config: grunt.file.readJSON "levels/#{el}/config.js"

    data =
      levels: levels
      base: grunt.file.read "levels/base"

    grunt.file.write "public/data/levels.json", JSON.stringify data
    grunt.log.ok "File public/data/levels.json created."


  # Get libraries from bower
  grunt.registerTask "libs", (type = "dev") ->
    if type isnt "dev" and type isnt "production"
      grunt.log.error "Unrecognised: #{type}. Only \"dev\" and \"production\" allowed."
      return false

    dev = type is "dev"

    if grunt.file.exists "public/libs/" then grunt.file.delete "public/libs/"

    if grunt.file.exists "public/index.html"
      source = grunt.file.read "public/index.html"
    else
      source = grunt.file.read "src/index.html"

    re = new RegExp "(<!--BEGIN LIBS-->.*?<!--END LIBS-->)|(<!--LIBS-->)", "gm"

    libs = (grunt.file.readJSON "bower.json").dependencies

    out = ""

    for file of libs
      lib = grunt.file.read "components/#{file}/#{file}.js"

      grunt.file.write "public/libs/#{file}.js", lib
      grunt.log.ok "File public/libs/#{file}.js created."

      if dev
        out += "<script src=\"libs/#{file}.js\"></script>\n"
      else
        out += lib + ";\n\n"

    if not dev
      grunt.file.write "public/libs/libs.js", out
      grunt.log.ok "File public/libs/libs.js created."
      grunt.task.run "uglify:libs"
      out = "<script src=\"libs/libs.min.js\"></script>"

    out = "<!--BEGIN LIBS-->#{out}<!--END LIBS-->"

    source = source.replace re, out

    grunt.file.write "public/index.html", source
    grunt.log.ok "File public/index.html created."

  # Convert coffeescript to javascript & wrap commonjs modules
  grunt.registerTask "scripts", (type = "dev") ->
    if type isnt "dev" and type isnt "production"
      grunt.log.error "Unrecognised: #{type}. Only \"dev\" and \"production\" allowed."
      return false

    dev = type is "dev"

    # Coffee2JS, stored in tmp/
    grunt.file.mkdir "tmp/src"
    grunt.file.mkdir "tmp/dest"

    grunt.task.run "coffee:scripts"

    # Wrap CommonJS modules
    grunt.task.run "commonjs:scripts"

    # Finish off with scripts
    grunt.task.run "postscripts:#{type}"

  grunt.registerTask "postscripts", (type = "dev") ->
    if type isnt "dev" and type isnt "production"
      grunt.log.error "Unrecognised: #{type}. Only \"dev\" and \"production\" allowed."
      return false

    dev = type is "dev"

    re = new RegExp "(<!--BEGIN SCRIPT-->.*?<!--END SCRIPTS-->)|(<!--SCRIPTS-->)", "gm"

    if grunt.file.exists "public/js/" then grunt.file.delete "public/js"

    # Copy scripts over and assemble <script> tags
    out = ""

    grunt.file.recurse "tmp/dest/", (abspath, root, dir, file) ->
      if dir isnt undefined
        file = "#{dir}/#{file}"

      grunt.file.copy abspath, "public/js/#{file}"

      out += "<script src=\"js/#{file}\"></script>\n"

      grunt.log.ok "File public/js/#{file} created."

    if grunt.file.exists "public/index.html"
      index = grunt.file.read "public/index.html"
    else
      index = grunt.file.read "src/index.html"

    if not dev
      out = "<script src=\"js/index.min.js\"></script>"

    console.log out

    out = "<!--BEGIN SCRIPT-->#{out}<!--END SCRIPTS-->"

    index = index.replace re, out

    grunt.file.write "public/index.html", index

    grunt.log.ok "File public/index.html created."

    grunt.file.delete "tmp/"

    if not dev then grunt.task.run "uglify:scripts"

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-commonjs'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
