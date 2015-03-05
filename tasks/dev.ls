require! {
  'gulp-connect'
  'gulp'
  'path'
  'run-sequence'
  'karma'
}

karma-config = path.resolve 'karma.conf.js'

gulp.task 'build' (done) ->
  scripts = if optimized then \optimized-scripts else \scripts
  run-sequence 'clean', [scripts, \assets \stylus \l10n \vendor \audio \fonts], done

gulp.task 'dev' <[watch server]>

karma-server = null
gulp.task 'watch' <[build]> ->
  karma.server.start config-file: karma-config
  gulp.watch src.assets, ['assets']
  gulp.watch src.lsc, ['app-livescript']
  gulp.watch src.tests, ['test-livescript']
  gulp.watch src.hbs, ['handlebars']
  gulp.watch src.css-all, ['stylus']
  gulp.watch [src.locale-data, src.locale-templates], ['l10n']
  gulp.watch src.vendor, ['vendor']
  gulp.watch src.audio, ['audio']

gulp.task 'server' ->
  gulp-connect.server {
    root: 'public'
    port: 4000
  }

gulp.task 'test' (done) ->
  karma.server.start {
    config-file: karma-config
    single-run: true
  }, done
