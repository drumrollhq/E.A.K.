require! {
  'image-size'
  'path'
  'mkdirp'
  'through2'
  'child_process'
  'gulp-debug'
  'gulp-imagemin'
  'gulp-changed'
  'gulp-spawn'
  'gulp'
  'run-sequence'
}

gulp.task 'imagemin' ->
  gulp.src src.images
    .pipe gulp-imagemin!
    .pipe gulp.dest dest.images

gulp.task 'assets' <[backgrounds]> ->
  gulp.src src.assets
    .pipe gulp-changed dest.assets
    .pipe gulp.dest './public'

gulp.task 'fonts' ->
  gulp.src src.fonts
    .pipe gulp-changed dest.fonts
    .pipe gulp.dest dest.fonts

gulp.task 'backgrounds' (cb) ->
  run-sequence ['blur-backgrounds', 'cache-backgrounds'], 'tile-backgrounds', 'min-tiles', 'copy-tiles', cb

gulp.task 'blur-backgrounds' ->
  gulp.src src.bgs
    .pipe gulp-changed dest.bg-cache, extension: '.blur.png'
    .pipe blur dest.bg-cache

gulp.task 'cache-backgrounds' ->
  gulp.src src.bgs
    .pipe gulp-changed dest.bg-cache
    .pipe gulp.dest dest.bg-cache

gulp.task 'tile-backgrounds' ->
  gulp.src src.bg-cache
    .pipe gulp-changed dest.bg-tile-cache, extension: '.t0-0.png'
    .pipe tile 1024 1024 dest.bg-tile-cache

gulp.task 'copy-tiles' ->
  gulp.src src.bg-tile-cache
    .pipe gulp.dest dest.bg-tiles

gulp.task 'min-tiles' ->
  gulp.src src.bg-tile-cache
    .pipe gulp-changed dest.bg-tile-cache
    .pipe gulp-imagemin!
    .pipe gulp.dest dest.bg-tile-cache

function blur dest
  through2.obj (file, enc, cb) ->
    if file.stat.is-directory! then return cb!
    ext = path.extname file.path
    filename = path.relative file.base, file.path .slice 0, -ext.length

    <- mkdirp dest
    {width, height} = image-size file.contents
    proc = child_process
      .spawn 'convert' [
        file.path
        '-resize' '25x25%'
        '-gaussian-blur' '0x10'
        '-resize' "#{width}x#{height}!"
        "#{dest}/#{filename}.blur#{ext}"
      ] stdio: \inherit
        .on \close (code) ->
          if code isnt 0
            console.log proc
            throw 'Convert error'
          console.log "Blurred #filename#ext"
          cb!

function tile width, height, dest
  through2.obj (file, enc, cb) ->
    if file.stat.is-directory! then return cb!
    ext = path.extname file.path
    filename = path.relative file.base, file.path .slice 0, -ext.length
    <- mkdirp dest

    proc = child_process
      .spawn 'convert' [
        file.path
        '-crop' "#{width}x#{height}"
        '-set' 'filename:tile' "t%[fx:page.x/#{width}]-%[fx:page.y/#{height}]"
        '+repage' '+adjoin'
        "#{dest}/#{filename}.%[filename:tile]#{ext}"
      ] stdio: \inherit
      .on \close (code) ->
        if code isnt 0
          console.log proc
          throw 'Convert error'
        cb!

change-ext = (new-ext, file) -->
  new-ext = new-ext.replace /^\./, ''
  old-ext = path.extname file
  "#{file.substring 0, file.length - oldExt.length}.#{newExt}"

output-loc = (file, output, ext) -->
  file.path
    |> change-ext ext
    |> ( .replace file.base, '' )
    |> -> path.resolve output, it
