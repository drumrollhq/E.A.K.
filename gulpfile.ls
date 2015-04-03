require! {
  'gulp'
  'yargs': {argv}
  'require-dir'
  'git-rev'
  'bluebird': Promise
}

global.optimized = argv.o or argv.optimized or argv.optimised or false
console.log "Optimized?: #optimized"

try
  global.config = require './config.js'
catch e
  global.config = {}

global.eak-version = new Promise (resolve, reject) ->
  tag <- git-rev.tag!
  branch <- git-rev.branch!
  hash <- git-rev.short!

  resolve "#{tag}-#{branch}-#{hash}"

global.languages = ['en' 'es-419' 'nl']
global.default-lang = 'en'

global.src = {
  assets: './app/assets/**/*'
  audio: './app/audio/**/*'
  audio-cache: './gulp-cache/audio/**/*'
  bgs: './app/assets/content/bgs/**/*'
  bg-cache: './gulp-cache/bgs/**/*'
  bg-tile-cache: './gulp-cache/bg-tiles/**/*'
  bg-tile-min-cache: './gulp-cache/bg-tiles-min/**/*'
  css-all: './app/styles/**/*.styl'
  css: ['./app/styles/app.styl', './app/styles/min.styl']
  fonts: './bower_components/font-awesome/fonts/*'
  hbs: './app/scripts/**/*.hbs'
  images: './app/assets/**/*.{jpg,png,gif}'
  locale-data: './locales/**/*.json'
  locale-templates: './app/l10n-templates/**/*'
  lsc: './app/scripts/**/*.ls'
  tests: './test/**/*.ls'
  vendor: ['./vendor/*.js' './vendor/rework/rework.js', './vendor/slowparse/slowparse.js']
  workers-static: ['./bower_components/underscore/underscore.js'
                   './app/workers/**/*.js'
                   './vendor/require.js']
  workers: './app/workers/**/*.ls'
}

global.dest = {
  all: './public/'
  assets: './public'
  audio: './public/audio'
  audio-cache: './gulp-cache/audio'
  bg-cache: './gulp-cache/bgs'
  bg-tile-cache: './gulp-cache/bg-tiles'
  bg-tile-min-cache: './gulp-cache/bg-tiles-min'
  bg-tiles: './public/content/bg-tiles'
  cache: './gulp-cache/'
  css: './public/css'
  data: './public/data'
  fonts: './public/fonts'
  images: './app/assets'
  js: './public/js'
  tests: './.test'
  vendor: './public/lib'
}

gulp.task 'default' <[dev]>

require-dir './tasks'
