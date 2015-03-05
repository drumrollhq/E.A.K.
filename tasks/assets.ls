require! {
  'gulp-imagemin'
  'gulp-changed'
  'gulp'
}

gulp.task 'imagemin' ->
  gulp.src src.images
    .pipe gulp-imagemin!
    .pipe gulp.dest dest.images

gulp.task 'assets' ->
  gulp.src src.assets
    .pipe gulp-changed dest.assets
    .pipe gulp.dest './public'

gulp.task 'fonts' ->
  gulp.src src.fonts
    .pipe gulp-changed dest.fonts
    .pipe gulp.dest dest.fonts
