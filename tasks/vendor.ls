require! {
  'gulp-concat'
  'gulp-uglify'
  'gulp'
  'event-stream': es
  'streamqueue'
  'main-bower-files'
}

gulp.task 'vendor' ->
  streamqueue {+object-mode}, (gulp.src main-bower-files!), (gulp.src src.vendor)
    .pipe vendor-wrapper!
    .pipe gulp-concat 'vendor.js'
    .pipe if optimized then gulp-uglify! else noop!
    .pipe gulp.dest dest.js

function vendor-wrapper
  es.map (file, cb) ->
    unless file.path.replace /\\/g '/' .match /slowparse|handlebars|stats|pixi/
      file.contents = Buffer.concat [
        new Buffer ';(function(){'
        file.contents
        new Buffer '}.call(this));'
      ]

    cb null, file

function noop
  es.map (file, cb) -> cb null, file
