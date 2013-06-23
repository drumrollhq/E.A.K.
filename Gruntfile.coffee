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

  grunt.registerTask "levels", ->
    levels = (fs.readdirSync "levels").filter (el) ->
      grunt.file.isDir "levels/#{el}"

    levels = levels.map (el) ->
      html: grunt.file.read "levels/#{el}/html.html"
      css: grunt.file.read "levels/#{el}/style.css"
      config: JSON.parse grunt.file.read "levels/#{el}/config.js"


    grunt.file.write "public/data/levels.json", JSON.stringify levels

  grunt.loadNpmTasks 'grunt-contrib-coffee'
