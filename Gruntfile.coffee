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
    watch:
      files: ['levels']

    uglify:
      options:
        mangle:
          except: ['jQuery', 'Backbone', '_', '$', 'Modernizr']
      libs:
        files:
          "public/libs/libs.min.js": "public/libs/libs.js"


  # Pull level definitions into data/levels.json
  grunt.registerTask "levels", ->
    levels = (fs.readdirSync "levels").filter (el) ->
      grunt.file.isDir "levels/#{el}"

    levels = levels.map (el) ->
      html: grunt.file.read "levels/#{el}/html.html"
      css: grunt.file.read "levels/#{el}/style.css"
      config: JSON.parse grunt.file.read "levels/#{el}/config.js"

    grunt.file.write "public/data/levels.json", JSON.stringify levels

  # Get libraries from bower
  grunt.registerTask "libs", (type = "dev") ->
    if type isnt "dev" and type isnt "production"
      grunt.log.error "Unrecognised: #{type}. Only \"dev\" and \"production\" allowed."
      return false

    grunt.file.delete "public/libs/"

    dev = type is "dev"

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

      if dev
        out += "<script src=\"libs/#{file}.js\"></script>\n"
      else
        out += lib + ";\n\n"

    if not dev
      grunt.file.write "public/libs/libs.js", out
      grunt.task.run "uglify:libs"
      out = "<script src=\"libs/libs.min.js\"></script>"

    out = "<!--BEGIN LIBS-->#{out}<!--END LIBS-->"

    source = source.replace re, out

    grunt.file.write "public/index.html", source

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
