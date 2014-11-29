require! {
  'event-stream': es
  'execSync': exec
  'fluent-ffmpeg': ffmpeg
  'glob'
  'gulp'
  'gulp-changed'
  'gulp-concat'
  'gulp-footer'
  'gulp-handlebars'
  'gulp-header'
  'gulp-imagemin'
  'gulp-livescript'
  'gulp-minify-css'
  'gulp-preprocess'
  'gulp-rimraf'
  'gulp-stylus'
  'gulp-uglify'
  'gulp-wrap'
  'handlebars'
  'karma'
  'main-bower-files'
  'mkdirp'
  'nib'
  'path'
  'prelude-ls': {split, first, last, initial, tail, join, map, camelize}
  'progress': ProgressBar
  'run-sequence'
  'streamqueue'
  'through2'
  'vinyl': File
  'yargs': {argv}
}

languages = ['en' 'es-419']

_ = {
  merge: require 'lodash.merge'
  defaults: require 'lodash.defaults'
}

scripts = glob.sync './app/scripts/**/*.{ls,hbs}'
  |> map ( .replace /^\.\/app\/scripts\// '/js/')
  |> map ( .replace /\.(ls|hbs)$/ '.js')
  |> map -> """<script src="#it"></script>"""
  |> join '\n'

optimized = argv.o or argv.optimized or argv.optimised or false
console.log "Optimized?: #optimized"
preprocess-context = {
  optimized: optimized
  version: exec.exec 'git rev-parse HEAD' .stdout.trim!
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
  audio-cache: './gulp-cache/audio/**/*'
  css-all: './app/styles/**/*.styl'
  css: ['./app/styles/app.styl', './app/styles/min.styl']
  fonts: './bower_components/font-awesome/fonts/*'
  hbs: './app/scripts/**/*.hbs'
  images: './app/assets/**/*.{jpg,png,gif}'
  locale-data: './locales/**/*.json'
  locale-templates: './app/l10n-templates/**/*'
  lsc: './app/scripts/**/*.ls'
  tests: './test/**/*.ls'
  vendor: ['./vendor/*.js' './vendor/rework/rework.js', './vendor/slowparse/slowparse.js',
    './vendor/slowparse/tree-inspectors.js', './vendor/slowparse/spec/errors.jquery.js']
  workers-static: ['./bower_components/underscore/underscore.js'
                   './app/workers/**/*.js'
                   './vendor/require.js']
  workers: './app/workers/**/*.ls'
}

dest = {
  all: './public/'
  assets: './public'
  audio: './public/audio'
  audio-cache: './gulp-cache/audio'
  cache: './gulp-cache/'
  css: './public/css'
  data: './public/data'
  fonts: './public/fonts'
  images: './app/assets'
  js: './public/js'
  tests: './.test'
  vendor: './public/lib'
}

tmp = {
  css: './.tmp/css'
}

script-root = new RegExp "^#{path.resolve './' .replace /\\/g, '\\\\'}(/|\\\\)app(/|\\\\)(scripts|workers)(/|\\\\)"

karma-config = path.resolve 'karma.conf.js'

gulp.task 'default' <[dev]>

gulp.task 'build' (done) ->
  scripts = if optimized then \optimized-scripts else \scripts
  run-sequence 'clean', [scripts, \assets \stylus \l10n \vendor \audio \fonts], done

karma-server = null
gulp.task 'dev' <[build]> ->
  karma.server.start config-file: karma-config
  gulp.watch src.assets, ['assets']
  gulp.watch src.lsc, ['app-livescript']
  gulp.watch src.tests, ['test-livescript']
  gulp.watch src.hbs, ['handlebars']
  gulp.watch src.css-all, ['stylus']
  gulp.watch [src.locale-data, src.locale-templates], ['l10n']
  gulp.watch src.vendor, ['vendor']
  gulp.watch src.audio, ['audio']

gulp.task 'clean' ->
  gulp.src dest.all, read: false
    .pipe gulp-rimraf force: true

gulp.task 'clean-cache' ->
  gulp.src dest.cache, read: false
    .pipe gulp-rimraf force: true

gulp.task 'scripts' (done) ->
  run-sequence ['livescript' 'workers' 'handlebars'], done

gulp.task 'optimized-scripts' ['scripts'] ->
  gulp.src ['./public/js/**/*.js', '!**/{worker,app,vendor}.js']
    .pipe gulp-concat 'app.js'
    .pipe gulp-uglify!
    .pipe gulp.dest dest.js

gulp.task 'imagemin' ->
  images = './app/assets/**/*.{png,jpg,gif}'
  gulp.src src.images
    .pipe gulp-imagemin!
    .pipe gulp.dest dest.images

gulp.task 'assets' ->
  gulp.src src.assets #, cwd: src.assets
    .pipe gulp-changed dest.assets
    .pipe gulp.dest dest.assets

gulp.task 'fonts' ->
  gulp.src src.fonts
    .pipe gulp-changed dest.fonts
    .pipe gulp.dest dest.fonts

gulp.task 'vendor' ->
  streamqueue {+object-mode}, (gulp.src main-bower-files!), (gulp.src src.vendor)
    .pipe vendor-wrapper!
    .pipe gulp-concat 'vendor.js'
    .pipe if optimized then gulp-uglify! else noop!
    .pipe gulp.dest dest.js

gulp.task 'audio' ['convert-audio'] ->
  gulp.src src.audio-cache
    .pipe gulp-changed dest.audio
    .pipe gulp.dest dest.audio

gulp.task 'convert-audio' ->
  gulp.src src.audio, # read: false
    .pipe gulp-changed dest.audio-cache
    .pipe through2.obj (file, enc, cb) ->
      if file.stat.is-directory! then return cb!
      output = output-loc file, dest.audio-cache

      file-name = file.path.replace file.base, ''
      bar = new ProgressBar "[:bar] :percent #file-name", total: 100, width: 30
      l = 0

      <- mkdirp path.dirname output 'test'

      x = ffmpeg file.path
        .output output '.mp3'
        .audio-codec 'libmp3lame'
        .audio-channels 1
        .audio-frequency 44100
        .audio-bitrate 64k

        .output output '.ogg'
        .audio-codec 'libvorbis'
        .audio-channels 1
        .audio-frequency 44100

        .on 'progress', (progress) ->
          bar.tick progress.percent - l
          l := progress.percent
        .on 'end', ->
          bar.tick 100
          cb!
        .run!

gulp.task 'stylus' (cb) ->
  gulp.src src.css
    .pipe gulp-stylus stylus-conf
    .on 'error' -> throw it
    .pipe if optimized then gulp-minify-css! else noop!
    .pipe gulp.dest dest.css

gulp.task 'livescript' (done) ->
  run-sequence ['app-livescript', 'test-livescript'], done

gulp.task 'app-livescript' ->
  gulp.src src.lsc
    .pipe gulp-changed dest.js, extension: '.js'
    .pipe gulp-livescript bare: true
    .on 'error' -> throw it
    .pipe wrap-commonjs!
    .pipe gulp.dest dest.js

gulp.task 'test-livescript' ->
  gulp.src src.tests
    .pipe gulp-changed dest.tests, extension: '.js'
    .pipe gulp-livescript bare: true
    .on 'error' -> throw it
    .pipe gulp.dest dest.tests

gulp.task 'handlebars' ->
  gulp.src src.hbs
    .pipe gulp-changed dest.js, extension: '.js'
    .pipe gulp-handlebars!
    .on 'error' -> throw it
    .pipe gulp-wrap 'module.exports = Handlebars.template(<%= contents %>);'
    .pipe wrap-commonjs!
    .pipe gulp.dest dest.js

gulp.task 'l10n-data' ->
  gulp.src src.locale-data
    .pipe locale-data-cache! .on 'error' -> throw it

gulp.task 'l10n' ['l10n-data'] ->
  gulp.src src.locale-templates
    .pipe gulp-preprocess context: preprocess-context
    .pipe localize! .on 'error' -> throw it
    .pipe gulp.dest dest.assets

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

gulp.task 'test' (done) ->
  karma.server.start {
    config-file: karma-config
    single-run: true
  }, done

# Custom plugins:
function wrap-commonjs
  es.map (file, cb) ->
    name = file.path.replace script-root, '' .replace /\.js$/, '' .replace /\\/g '/'
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

function vendor-wrapper
  es.map (file, cb) ->
    unless file.path.replace /\\/g '/' .match /slowparse|handlebars/
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
  base-re = new RegExp "^#{file.base .replace /\\/g, '\\\\'}"

  file.path.replace base-re, '' .replace /\\/g, '/'

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
