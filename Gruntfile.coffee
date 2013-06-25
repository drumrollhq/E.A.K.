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

    dev = type is "dev"

    grunt.file.delete "public/libs/"

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

    grunt.file.delete "public/js"

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



    out = "<!--BEGIN SCRIPT-->#{out}<!--END SCRIPTS-->"

    index = index.replace re, out

    grunt.file.write "public/index.html", index

    grunt.file.delete "tmp/"

    if not dev then grunt.task.run "uglify:scripts"

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-commonjs'
