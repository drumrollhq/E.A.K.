require! {
  'gulp-cache'
  'gulp-rimraf'
  'gulp'
}

gulp.task 'clean' ->
  gulp.src [dest.all, dest.tests], read: false
    .pipe gulp-rimraf force: true

gulp.task 'clean-manual-cache' ->
  gulp.src dest.cache, read: false
    .pipe gulp-rimraf force: true

gulp.task 'clean-gulp-cache' (done) ->
  gulp-cache.clear-all done

gulp.task 'clean-cache' <[clean-manual-cache clean-gulp-cache]>
gulp.task 'clean-all' <[clean clean-cache]>
