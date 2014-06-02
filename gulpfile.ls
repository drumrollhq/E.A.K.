require! {
  'gulp'
  'gulp-handlebars'
  'gulp-livescript'
  'gulp-wrap-commonjs'
  'path'
}

script-root = new RegExp "^#{path.resolve './'}/app/scripts/"
commonjs-wrapper = gulp-wrap-commonjs {
  path-modifier: (path) ->
    path .= replace script-root, ''
    path .= replace /\.js$/, ''
}

gulp.task 'scripts' ->
  gulp.start 'livescript' 'handlebars'

gulp.task 'livescript' ->
  gulp.src './app/scripts/**/*.ls'
    .pipe gulp-livescript bare: true
    .on 'error' -> throw it
    .pipe commonjs-wrapper
    .pipe gulp.dest './public/js'

gulp.task 'handlebars' ->
  gulp.src './app/scripts/**/*.hbs'
    .pipe gulp-handlebars!
    .pipe commonjs-wrapper
    .pipe gulp.dest './public/js'

