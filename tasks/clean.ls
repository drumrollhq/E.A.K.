require! {
  'gulp-rimraf'
  'gulp'
}

gulp.task 'clean' ->
  gulp.src [dest.all, dest.tests], read: false
    .pipe gulp-rimraf force: true

gulp.task 'clean-cache' ->
  gulp.src dest.cache, read: false
    .pipe gulp-rimraf force: true
