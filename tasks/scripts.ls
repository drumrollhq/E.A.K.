require! {
  'event-stream': es
  'fs'
  'gulp'
  'gulp-changed'
  'gulp-concat'
  'gulp-footer'
  'gulp-handlebars'
  'gulp-header'
  'gulp-livescript'
  'gulp-rename'
  'gulp-uglify'
  'gulp-wrap'
  'path'
  'request'
  'run-sequence'
  'streamqueue'
}

gulp.task 'scripts' (done) ->
  run-sequence ['livescript' 'workers' 'handlebars' 'api-spec'], done

gulp.task 'optimized-scripts' ['scripts'] ->
  gulp.src ['./public/js/**/*.js', '!**/{worker,eak,vendor}.js']
    .pipe gulp-concat 'eak.js'
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

gulp.task 'update-api' (done) !->
  url = if optimized then 'https://api.eraseallkittens.com/v1/' else 'http://localhost:3000/v1/'
  console.log "fetch api spec from #url"
  request url, (err, resp, body) ->
    if err then throw err
    fs.write-file 'api-spec.json', body, encoding: \utf-8, (err) ->
      if err then throw err
      done!

gulp.task 'api-spec' ->
  gulp.src 'api-spec.json'
    .pipe gulp-wrap '(function(){window.EAK_API_SPEC = <%= contents %>;}())'
    .pipe gulp-rename extname: '.js'
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
