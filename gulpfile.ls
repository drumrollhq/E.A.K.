require! {
  es: 'event-stream'
  'gulp'
  'gulp-changed'
  'gulp-clean'
  'gulp-handlebars'
  'gulp-livescript'
  'gulp-util'
  'gulp-wrap'
  'path'
}

paths = {
  lsc: './app/scripts/**/*.ls'
  hbs: './app/scripts/**/*.hbs'
}

script-root = new RegExp "^#{path.resolve './'}/app/scripts/"

gulp.task 'default' -> gulp.start 'dev'

gulp.task 'build' <[clean]> ->
  gulp.start 'scripts'

gulp.task 'dev' <[build]> ->
  gulp.watch paths.lsc, ['livescript']
  gulp.watch paths.hbs, ['handlebars']

gulp.task 'clean' ->
  gulp.src './public/**/*' read: false
    .pipe gulp-clean force: true

gulp.task 'scripts' ->
  gulp.start 'livescript' 'handlebars'

gulp.task 'livescript' ->
  gulp.src paths.lsc
    .pipe gulp-changed './public/js' extension: '.js'
    .pipe gulp-livescript bare: true
    .on 'error' -> throw it
    .pipe wrap-commonjs!
    .pipe gulp.dest './public/js'

gulp.task 'handlebars' ->
  gulp.src paths.hbs
    .pipe gulp-handlebars!
    .pipe gulp-header 'module.exports = '
    .pipe wrap-commonjs!
    .pipe gulp.dest './public/js'

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
