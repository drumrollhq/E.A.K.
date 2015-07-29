require! {
  '../node_modules/gulp-stylus/node_modules/stylus'
  'event-stream': es
  'gulp'
  'gulp-minify-css'
  'gulp-stylus'
  'nib'
  'path'
}

stylus-conf = {
  use: [nib!]
  define: {}
  paths: [path.resolve './app/assets/']
  'include css': true
}

gulp.task 'stylus' (cb) ->
  stylus-conf.define.url = stylus.url!
  gulp.src src.css
    .pipe gulp-stylus stylus-conf
    .on 'error' -> throw it
    .pipe if optimized then gulp-minify-css! else noop!
    .pipe gulp.dest dest.css

gulp.task 'entity-stylus' ->
  conf = {} <<< stylus-conf
  conf.import = [
    path.resolve './app/styles/variables.styl'
    path.resolve './app/styles/mixins.styl'
  ]

  gulp.src src.entity-styles
    .pipe gulp-stylus conf
    .on 'error' -> throw it
    .pipe if optimized then gulp-minify-css! else noop!
    .pipe gulp.dest dest.entities

function noop
  es.map (file, cb) -> cb null, file
