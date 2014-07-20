require! {
  es: 'event-stream'
  exec: 'exec-sync'
  ffmpeg: 'fluent-ffmpeg'
  File: 'vinyl'
  ProgressBar: 'progress'
  'glob'
  'gulp'
  'gulp-changed'
  'gulp-concat'
  'gulp-footer'
  'gulp-header'
  'gulp-imagemin'
  'gulp-livescript'
  'gulp-minify-css'
  'gulp-preprocess'
  'gulp-rimraf'
  'gulp-stylus'
  'gulp-uglify'
  'handlebars'
  'LiveScript'
  'main-bower-files'
  'mkdirp'
  'nib'
  'path'
  'prelude-ls'
  'streamqueue'
  'through2'
  'yargs'
}

languages = ['en' 'es-419']

_ = {
  merge: require 'lodash.merge'
  defaults: require 'lodash.defaults'
}

{split, first, last, initial, tail, join, map, camelize} = prelude-ls

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
  languages: languages |> map (-> "'#it'") |> join ',' |> (-> "[#it]")
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
  assets: './app/assets/**/*'
  audio: './app/audio/**/*'
  css-all: './app/styles/**/*.styl'
  css: ['./app/styles/app.styl', './app/styles/min.styl']
  errors: './bower_components/slowparse/spec/errors.{base,forbidjs}.html'
  images: './app/assets/**/*.{jpg,png,gif}'
  locale-data: './locales/**/*.json'
  locale-templates: './app/l10n-templates/**/*'
  lsc: './app/scripts/**/*.ls'
  vendor: ['./vendor/*.js' './vendor/rework/rework.js']
  workers-static: ['./bower_components/underscore/underscore.js'
                   './app/workers/**/*.js'
                   './vendor/require.js']
  workers: './app/workers/**/*.ls'
}

dest = {
  all: './public/'
  assets: './public'
  audio: './public/audio'
  css: './public/css'
  data: './public/data'
  images: './app/assets'
  js: './public/js'
  vendor: './public/lib'
}

tmp = {
  css: './.tmp/css'
}

script-root = new RegExp "^#{path.resolve './'}/app/(scripts|workers)/"

gulp.task 'default' <[dev]>

gulp.task 'build' <[clean]> ->
  gulp.start \scripts \assets \stylus \l10n \vendor \errors \audio

gulp.task 'dev' <[build]> ->
  gulp.watch src.assets, ['assets']
  gulp.watch src.lsc, ['livescript']
  gulp.watch src.css-all, ['stylus']
  gulp.watch [src.locale-data, src.locale-templates], ['l10n']
  gulp.watch src.vendor, ['vendor']

gulp.task 'clean' ->
  gulp.src dest.all, read: false
    .pipe gulp-rimraf force: true

gulp.task 'scripts' ['livescript' 'workers']

gulp.task 'imagemin' ->
  images = './app/assets/**/*.{png,jpg,gif}'
  gulp.src src.images
    .pipe gulp-imagemin!
    .pipe gulp.dest dest.images

gulp.task 'assets' ->
  gulp.src src.assets #, cwd: src.assets
    .pipe gulp-changed dest.assets
    .pipe gulp.dest dest.assets

gulp.task 'vendor' ->
  streamqueue {+object-mode}, (gulp.src main-bower-files!), (gulp.src src.vendor)
    .pipe hack-slowparse!
    .pipe vendor-wrapper!
    .pipe gulp-concat 'vendor.js'
    .pipe if optimized then gulp-uglify! else noop!
    .pipe gulp.dest dest.js

gulp.task 'audio' ->
  gulp.src src.audio, read: false .pipe through2.obj (file, enc, cb) ->
    if file.stat.is-directory! then return cb!
    output = output-loc file, dest.audio

    file-name = file.path.replace file.base, ''
    bar = new ProgressBar "[:bar] :percent #file-name", total: 100, width: 30
    l = 0

    <- mkdirp path.dirname output 'test'

    x = ffmpeg file.path
      .output output '.mp3'
      .audio-codec 'libmp3lame'
      .audio-channels 1
      .audio-frequency 22050

      .output output '.ogg'
      .audio-codec 'libvorbis'
      .audio-channels 1
      .audio-frequency 22050

      .on 'progress', (progress) ->
        bar.tick progress.percent - l
        l := progress.percent
      .on 'end', ->
        bar.tick 100
        cb!
      .run!

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

gulp.task 'l10n-data' ->
  gulp.src src.locale-data
    .pipe locale-data-cache! .on 'error' -> throw it

gulp.task 'l10n' ['l10n-data'] ->
  gulp.src src.locale-templates
    .pipe gulp-preprocess context: preprocess-context
    .pipe localize! .on 'error' -> throw it
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
  default-lang = first languages
  through2.obj (file, enc, cb) ->
    if file.stat.is-directory! then return cb!
    path = relative-path file
    template = handlebars.compile file.contents.to-string!

    for lang in languages
      data = get-locale-data lang, path
      f = file.clone!
      f.contents = new Buffer template data
      f.path = "#{f.base}/#{lang}/#{path}"
      @push f

      if lang is default-lang
        f .= clone!
        f.path = "#{f.base}/#{path}"
        @push f

    cb!

_locale-cache = {}
function locale-data-cache
  es.map (file, cb) ->
    lang = file |> relative-path |> country-code
    data = JSON.parse file.contents.to-string!

    _locale-cache[lang] ?= {}
    lang-data = _locale-cache[lang]

    for key, {message} of data
      file = key |> split '/' |> initial |> join '/'
      path = key |> split '/' |> last |> split '.' |> map camelize

      lang-data[file] ?= {}
      file-data = lang-data[file]
      set-path file-data, path, message

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

function vendor-wrapper
  es.map (file, cb) ->
    unless file.path.match /\/bower_components\/slowparse/
      file.contents = Buffer.concat [
        new Buffer ';(function(){'
        file.contents
        new Buffer '}.call(this));'
      ]

    cb null, file

function noop
  es.map (file, cb) -> cb null, file

# Utils:
function relative-path file
  base-re = new RegExp "^#{file.base}"
  file.path.replace base-re, ''

function country-code path
  path |> split '/' |> first

function get-locale-data lang, file
  default-lang = first languages
  data = _locale-cache{}[lang]{}[file]

  default-data = _locale-cache[default-lang][file]
  _.merge data, default-data, _.defaults

function to-buffer str
  new Buffer str

function set-path obj, path, val
  switch
  | path.length is 1 => obj[first path] = val
  | otherwise =>
    obj[first path] ?= {}
    set-path obj[first path], (tail path), val

change-ext = (new-ext, file) -->
  new-ext = new-ext.replace /^\./, ''
  old-ext = path.extname file
  "#{file.substring 0, file.length - oldExt.length}.#{newExt}"

output-loc = (file, output, ext) -->
  file.path
    |> change-ext ext
    |> ( .replace file.base, '' )
    |> -> path.resolve output, it
