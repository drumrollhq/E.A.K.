require! {
  './packer'
  'gulp'
  'gulp-connect'
  'karma'
  'path'
  'run-sequence'
}

karma-config = path.resolve 'karma.conf.js'

gulp.task 'build' (done) ->
  scripts = if optimized then \optimized-scripts else \scripts
  run-sequence 'clean', [scripts, \assets \entity-assets \entity-stylus \stylus \vendor \audio \fonts], \l10n, \pack, done

gulp.task 'dev' ->
  run-sequence 'build', 'watch'

karma-server = null
gulp.task 'watch' ['server'] ->
  karma.server.start config-file: karma-config
  gulp.watch
  gulp.watch src.assets, ['assets']
  gulp.watch src.entity-assets, ['entity-assets']
  gulp.watch src.lsc, ['app-livescript']
  gulp.watch src.entity-scripts, ['entity-livescript']
  gulp.watch src.tests, ['test-livescript']
  gulp.watch src.hbs, ['handlebars']
  gulp.watch src.css-all, ['stylus']
  gulp.watch src.entity-styles, ['entity-stylus']
  gulp.watch [src.locale-data, src.locale-templates], ['l10n']
  gulp.watch src.vendor, ['vendor']
  gulp.watch src.audio, ['audio']
  packer.watch!

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
