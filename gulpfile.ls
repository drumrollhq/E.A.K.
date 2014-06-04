require! {
  es: 'event-stream'
  exec: 'exec-sync'
  File: 'vinyl'
  'glob'
  'gulp'
  'gulp-bower-files'
  'gulp-changed'
  'gulp-clean'
  'gulp-concat'
  'gulp-footer'
  'gulp-header'
  'gulp-livescript'
  'gulp-minify-css'
  'gulp-preprocess'
  'gulp-stylus'
  'gulp-uglify'
  'handlebars'
  'LiveScript'
  'nib'
  'path'
  'prelude-ls'
  'streamqueue'
  'through2'
  'yargs'
}

{split, first, tail, join, map} = prelude-ls

scripts = glob.sync './app/scripts/**/*.ls'
  |> map ( .replace /^\.\/app\/scripts\// '/js/')
  |> map ( .replace /\.ls$/ '.js')
  |> map -> """<script src="#it"></script>"""
  |> join '\n'

{argv} = yargs
optimized = argv.o or argv.optimized or argv.optimised or false
console.log "Optimized?: #optimized"
preprocess-context = {
  optimized: optimized
  version: exec 'git rev-parse HEAD'
  scripts: scripts
}

default-lang = 'en'

stylus = require './node_modules/gulp-stylus/node_modules/stylus'
stylus-conf = {
  use: [nib!]
  define:
    url: stylus.url!
  paths: [__dirname + '/app/assets/']
  'include css': true
}

src = {
  lsc: './app/scripts/**/*.ls'
  css: ['./app/styles/app.styl', './app/styles/min.styl']
  css-all: './app/styles/**/*.styl'
  local-content: './app/l10n-content/**/*.json.ls'
  local-templates: './app/l10n-templates/**/*'
  assets: './app/assets/**/*'
  vendor: ['./vendor/*.js' './vendor/rework/rework.js']
  errors: './bower_components/slowparse/spec/errors.{base,forbidjs}.html'
  workers: './app/workers/**/*.ls'
  workers-static: ['./bower_components/underscore/underscore.js'
                   './app/workers/**/*.js'
                   './vendor/require.js']
}

dest = {
  all: './public/**/*'
  js: './public/js'
  css: './public/css'
  assets: './public'
  vendor: './public/lib'
  data: './public/data'
}

tmp = {
  css: './.tmp/css'
}

script-root = new RegExp "^#{path.resolve './'}/app/(scripts|workers)/"

gulp.task 'default' -> gulp.start 'dev'

gulp.task 'build' <[clean]> ->
  gulp.start \scripts \assets \stylus \l10n \vendor \errors

gulp.task 'dev' <[build]> ->
  gulp.watch src.assets, ['assets']
  gulp.watch src.lsc, ['livescript']
  gulp.watch src.css-all, ['stylus']
  gulp.watch [src.local-content, src.local-templates], ['l10n']

gulp.task 'clean' ->
  gulp.src dest.all, read: false
    .pipe gulp-clean force: true

gulp.task 'scripts' ['livescript' 'workers']

gulp.task 'assets' ->
  gulp.src src.assets #, cwd: src.assets
    .pipe gulp-changed dest.assets
    .pipe gulp.dest dest.assets

gulp.task 'vendor' ->
  streamqueue {+object-mode}, (gulp-bower-files!), (gulp.src src.vendor)
    .pipe hack-slowparse!
    .pipe gulp-concat 'vendor.js'
    .pipe if optimized then gulp-uglify! else noop!
    .pipe gulp.dest dest.js

gulp.task 'stylus' ->
  gulp.src src.css
    .pipe gulp-stylus stylus-conf
    .pipe if optimized then gulp-minify-css! else noop!
    .pipe gulp.dest dest.css

gulp.task 'livescript' ->
  gulp.src src.lsc
    .pipe gulp-changed dest.js, extension: '.js'
    .pipe gulp-livescript bare: true
    .on 'error' -> throw it
    .pipe wrap-commonjs!
    .pipe if optimized then gulp-concat 'app.js' else noop!
    .pipe if optimized then gulp-uglify! else noop!
    .pipe gulp.dest dest.js

gulp.task 'l10n-templates' ->
  gulp.src src.local-templates
    .pipe gulp-preprocess context: preprocess-context
    .pipe template-cache!

gulp.task 'l10n' ['l10n-templates'] ->
  gulp.src src.local-content
    .pipe localize!
    .pipe gulp.dest dest.assets

gulp.task 'errors' ->
  gulp.src src.errors
    .pipe gulp-concat 'errors.all.html'
    .pipe gulp.dest dest.data

gulp.task 'workers' ->
  ls = gulp.src src.workers
    .pipe gulp-livescript bare: true
    .pipe wrap-commonjs!

  streamqueue {+object-mode}, (gulp.src src.workers-static), ls
    .pipe gulp-concat 'worker.js'
    .pipe gulp-header 'if (self.window === undefined) {global = self;};'
    .pipe gulp-footer ';require(\'base\');'
    .pipe if optimized then gulp-uglify! else noop!
    .pipe gulp.dest dest.js

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

function hack-slowparse
  es.map (file, cb) ->
    if file.path.match /\/bower_components\/slowparse\/slowparse\.js$/
      orig = file.contents.to-string!
      a = '''
        // ### Exported Symbols
          //
          // `Slowparse` is the object that holds all exported symbols from
          // this library.
          var Slowparse = {'''

      b = '''
        // ### Exported Symbols - HACKILY MODIFIED FOR EAK!
          //
          // `Slowparse` is the object that holds all exported symbols from
          // this library.
          var Slowparse = {
            // EAK requires the HTMLParser to be exposed so we can add custom elements:
            HTMLParser: HTMLParser,'''

      contents = orig.replace a, b

      file.contents = new Buffer contents

    cb null, file

function noop
  es.map (file, cb) -> cb null, file

# Utils:
function lsc-to-json file
  eval LiveScript.compile file.contents.to-string!, bare: true

function relative-path file
  base-re = new RegExp "^#{file.base}"
  file.path.replace base-re, ''

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
