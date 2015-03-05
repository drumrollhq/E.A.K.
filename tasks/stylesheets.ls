require! {
  'event-stream': es
  'gulp-stylus'
  '../node_modules/gulp-stylus/node_modules/stylus'
  'gulp'
  'path'
  'nib'
}

stylus-conf = {
  use: [nib!]
  define:
    url: stylus.url!
  paths: [path.resolve '/app/assets/']
  'include css': true
}

gulp.task 'stylus' (cb) ->
  gulp.src src.css
    .pipe gulp-stylus stylus-conf
    .on 'error' -> throw it
    .pipe if optimized then gulp-minify-css! else noop!
    .pipe gulp.dest dest.css

function noop
  es.map (file, cb) -> cb null, file
