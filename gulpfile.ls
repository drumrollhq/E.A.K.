require! {
  es: 'event-stream'
  'gulp'
  'gulp-changed'
  'gulp-clean'
  'gulp-handlebars'
  'gulp-header'
  'gulp-livescript'
  'gulp-util'
  'path'
}

src = {
  lsc: './app/scripts/**/*.ls'
  hbs: './app/scripts/**/*.hbs'
  assets: './app/assets/**/*'
}

dest = {
  all: './public/**/*'
  lsc: './public/js'
  hbs: './public/js'
  assets: './public'
}

script-root = new RegExp "^#{path.resolve './'}/app/scripts/"

gulp.task 'default' -> gulp.start 'dev'

gulp.task 'build' <[clean]> ->
  gulp.start \scripts \assets

gulp.task 'dev' <[build]> ->
  gulp.watch src.lsc, ['livescript']
  gulp.watch src.hbs, ['handlebars']

gulp.task 'clean' ->
  gulp.src dest.all, read: false
    .pipe gulp-clean force: true

gulp.task 'scripts' ->
  gulp.start 'livescript' 'handlebars'

gulp.task 'assets' ->
  gulp.src src.assets #, cwd: src.assets
    .pipe gulp.dest dest.assets

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

# Custom/utils etc.
function wrap-commonjs
  es.map (file, cb) ->
    name = file.path.replace script-root, '' .replace /\.js$/, ''
    file.contents = Buffer.concat [
      new Buffer """;require.register("#{name}", function(exports,require,module){\n"""
      file.contents
      new Buffer '\n});'
    ]
    cb null, file
