require! {
  'gulp-changed'
  'gulp'
  'through2'
  'progress': ProgressBar
  'path'
  'mkdirp'
  'fluent-ffmpeg': ffmpeg
}

gulp.task 'audio' ['convert-audio'] ->
  gulp.src src.audio-cache
    .pipe gulp-changed dest.audio
    .pipe gulp.dest dest.audio

gulp.task 'convert-audio' ->
  gulp.src src.audio
    .pipe gulp-changed dest.audio-cache
    .pipe through2.obj (file, enc, cb) ->
      if file.stat.is-directory! then return cb!
      output = output-loc file, dest.audio-cache

      file-name = file.path.replace file.base, ''
      bar = new ProgressBar "[:bar] :percent #file-name", total: 100, width: 30
      l = 0

      <- mkdirp path.dirname output 'test'

      x = ffmpeg file.path
        .output output '.mp3'
        .audio-codec 'libmp3lame'
        .audio-channels 1
        .audio-frequency 44100
        .audio-bitrate 64k

        .output output '.ogg'
        .audio-codec 'libvorbis'
        .audio-channels 1
        .audio-frequency 44100

        .on 'progress', (progress) ->
          bar.tick progress.percent - l
          l := progress.percent
        .on 'end', ->
          bar.tick 100
          cb!
        .on 'error', (err, stdout, stderr) ->
          console.log 'ffmpeg err:', err
          console.log 'stdout:', stdout
          console.log 'stderr:', stderr
        .run!

change-ext = (new-ext, file) -->
  new-ext = new-ext.replace /^\./, ''
  old-ext = path.extname file
  "#{file.substring 0, file.length - oldExt.length}.#{newExt}"

output-loc = (file, output, ext) -->
  file.path
    |> change-ext ext
    |> ( .replace file.base, '' )
    |> -> path.resolve output, it
