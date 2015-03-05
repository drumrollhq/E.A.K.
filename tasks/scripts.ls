require! {
  'streamqueue'
  'gulp-concat'
  'gulp-uglify'
  'gulp-changed'
  'gulp-livescript'
  'gulp-header'
  'gulp-footer'
  'gulp-wrap'
  'gulp-handlebars'
  'gulp'
  'path'
  'run-sequence'
  'event-stream': es
}

gulp.task 'scripts' (done) ->
  run-sequence ['livescript' 'workers' 'handlebars'], done

gulp.task 'optimized-scripts' ['scripts'] ->
  gulp.src ['./public/js/**/*.js', '!**/{worker,app,vendor}.js']
    .pipe gulp-concat 'app.js'
    .pipe gulp-uglify!
    .pipe gulp.dest dest.js

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

gulp.task 'handlebars' ->
  gulp.src src.hbs
    .pipe gulp-changed dest.js, extension: '.js'
    .pipe gulp-handlebars!
    .on 'error' -> throw it
    .pipe gulp-wrap 'module.exports = Handlebars.template(<%= contents %>);'
    .pipe wrap-commonjs!
    .pipe gulp.dest dest.js

script-root = new RegExp "^#{path.resolve './' .replace /\\/g, '\\\\'}(/|\\\\)app(/|\\\\)(scripts|workers)(/|\\\\)"

function wrap-commonjs
  es.map (file, cb) ->
    name = file.path.replace script-root, '' .replace /\.js$/, '' .replace /\\/g '/'
    file.contents = Buffer.concat [
      new Buffer """;require.register("#{name}", function(exports,require,module){\n"""
      file.contents
      new Buffer '\n});'
    ]
    cb null, file

function noop
  es.map (file, cb) -> cb null, file
