require! {
  es: 'event-stream'
  File: 'vinyl'
  'gulp'
  'gulp-changed'
  'gulp-clean'
  'gulp-handlebars'
  'gulp-header'
  'gulp-livescript'
  'gulp-stylus'
  'gulp-util'
  'handlebars'
  'LiveScript'
  'nib'
  'path'
  'prelude-ls'
  'through2'
}

default-lang = 'en'

stylus = require './node_modules/gulp-stylus/node_modules/stylus'
stylus-conf = {
  use: [nib!]
  define:
    url: stylus.url!
  paths: [__dirname + '/app/assets/']
}

src = {
  lsc: './app/scripts/**/*.ls'
  hbs: './app/scripts/**/*.hbs'
  css: ['./app/styles/app.styl', './app/styles/min.styl']
  css-all: './app/styles/**/*.styl'
  local-content: './app/l10n-content/**/*.json.ls'
  local-templates: './app/l10n-templates/**/*'
  assets: './app/assets/**/*'
}

dest = {
  all: './public/**/*'
  lsc: './public/js'
  hbs: './public/js'
  css: './public/css'
  assets: './public'
}

tmp = {
  css: './.tmp/css'
}

script-root = new RegExp "^#{path.resolve './'}/app/scripts/"

gulp.task 'default' -> gulp.start 'dev'

gulp.task 'build' <[clean]> ->
  gulp.start \scripts \assets \stylus \l10n

gulp.task 'dev' <[build]> ->
  gulp.watch src.lsc, ['livescript']
  gulp.watch src.hbs, ['handlebars']
  gulp.watch src.css-all, ['stylus']
  gulp.watch [src.local-content, src.local-templates], ['l10n']

gulp.task 'clean' ->
  gulp.src dest.all, read: false
    .pipe gulp-clean force: true

gulp.task 'scripts' ->
  gulp.start 'livescript' 'handlebars'

gulp.task 'assets' ->
  gulp.src src.assets #, cwd: src.assets
    .pipe gulp.dest dest.assets

gulp.task 'stylus' ->
  gulp.src src.css
    .pipe gulp-stylus stylus-conf
    .pipe gulp.dest dest.css

gulp.task 'livescript' ->
  gulp.src src.lsc
    .pipe gulp-changed dest.lsc, extension: '.js'
    .pipe gulp-livescript bare: true
    .on 'error' -> throw it
    .pipe wrap-commonjs!
    .pipe gulp.dest dest.lsc

gulp.task 'handlebars' ->
  gulp.src src.hbs
    .pipe gulp-changed dest.hbs, extension: '.js'
    .pipe gulp-handlebars!
    .pipe gulp-header 'module.exports = '
    .pipe wrap-commonjs!
    .pipe gulp.dest dest.hbs

gulp.task 'l10n-templates' ->
  gulp.src src.local-templates
    .pipe template-cache!

gulp.task 'l10n' ['l10n-templates'] ->
  gulp.src src.local-content
    .pipe localize!
    .pipe gulp.dest dest.assets

# Custom plugins:
function wrap-commonjs
  es.map (file, cb) ->
    name = file.path.replace script-root, '' .replace /\.js$/, ''
    file.contents = Buffer.concat [
      new Buffer """;require.register("#{name}", function(exports,require,module){\n"""
      file.contents
      new Buffer '\n});'
    ]
    cb null, file

function localize
  through2.obj (file, enc, cb) ->
    path = relative-path file
    template = path |> template-name |> load-template
    data = lsc-to-json file

    file.contents = data |> template |> to-buffer
    file.path .= replace /\.json\.ls$/ ''

    if default-lang is country-code path
      def = file.clone!
      def.path = def.base + (strip-country-code path)
      def.path .= replace /\.json\.ls$/ ''
      @push def

    @push file
    cb!

_t-cache = {}
function template-cache
  es.map (file, cb) ->
    if file.stat.is-directory! then return cb null, null
    name = relative-path file
    _t-cache[name] = handlebars.compile file.contents.to-string!
    cb null, file

# Utils:
function lsc-to-json file
  eval LiveScript.compile file.contents.to-string!, bare: true

function relative-path file
  base-re = new RegExp "^#{file.base}"
  file.path.replace base-re, ''

{split, first, tail, join} = prelude-ls
function country-code path
  path |> split '/' |> first

function strip-country-code path
  path |> split '/' |> tail |> join '/'

function template-name path
  path |> strip-country-code |> ( .replace /\.json\.ls$/, '')

function load-template name
  _t-cache[name]

function to-buffer str
  new Buffer str
