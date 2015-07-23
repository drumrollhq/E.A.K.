require! {
  'bluebird': Promise
  'through2'
  'fs'
  'glob'
  'gulp'
  'gulp-debug'
  'gulp-rename'
  'path'
  'prelude-ls': {flatten, unique, pairs-to-obj, map}
  'vinyl'
}

glob = Promise.promisify-all glob
fs = Promise.promisify-all fs

gulp.task 'pack' ->
  gulp.src src.bundles
    .pipe create-bundle!
    .pipe gulp-debug {title: \packaged}
    .pipe gulp.dest dest.bundles

gulp.task 'bundle-sizes' ->
  gulp.src src.created-bundles, read: false
    .pipe bundle-sizes!
    .pipe gulp.dest dest.all

formats = {
  ogg: \ogg
  mp3: \mpeg
  png: \png
  jpg: \jpeg
  jpeg: \jpeg
  gif: \gif
}

export encode = (name, buffer) ->
  ext = path.extname name .to-lower-case!.replace /^\./ ''
  switch ext
  | <[html css js]> => buffer.to-string 'utf-8'
  | \json => type: \json, data: JSON.parse buffer.to-string 'utf-8'
  | <[png jpeg jpg gif]> => type: \image, format: formats[ext], data: buffer.to-string 'base64'
  | <[mp3 ogg]> => type: \audio, format: formats[ext], data: buffer.to-string 'base64'
  | otherwise => throw new TypeError "Unknown extname #{ext} on file #{name}"

export watch = ->
  filename-to-task-id = (name) -> "pack-#{name.to-lower-case!.replace /\//g, '-' .replace /[^a-z0-9-]/g, ''}"
  files-for = (name) ->
    file = JSON.parse fs.read-file-sync name, encoding: 'utf-8'

    dirname = path.dirname path.join path.sep, path.relative dest.bundles, name
    assets = file.map (asset) -> path.join dest.bundles, path.resolve dirname, asset

    assets

  packages = glob.sync src.bundles

  for let package-name in packages
    files = files-for package-name
    task-name = filename-to-task-id package-name
    gulp.task task-name, ->
      gulp.src package-name
        .pipe create-bundle!
        .pipe gulp.dest path.dirname package-name

    console.log 'Create task' task-name
    gulp.watch files, [task-name]

export create-bundle = ->
  through2.obj (file, enc, cb) ->
    bundle = JSON.parse file.contents.to-string!
    unless typeof! bundle is \Array then return cb!

    dirname = path.join path.sep, path.dirname path.relative dest.all, file.path
    assets = for asset-path in bundle => path.resolve dirname, asset-path

    make = (name, reject) ~>
      bundle-assets assets, reject: reject
        .then (assets) ~>
          f = file.clone!

          p = path.parse f.path
          p.name += 'd.' + name
          p.base = p.name + p.ext
          f.path = path.format p

          f.contents = new Buffer JSON.stringify assets
          @push f

    Promise.all [(make 'ogg', (.match /\.mp3$/)), (make 'mp3', (.match /\.ogg$/))]
      .then -> cb!
      .catch (e) -> cb e

export bundle-assets = (assets, {encoding = 'base64', reject = -> false} = {}) ->
  Promise
    .map assets, (f) -> glob.glob-async path.join dest.bundles, f
    .then flatten >> unique
    .filter (asset) ->
      fs.stat-async asset .then (stat) -> not stat.is-directory!
    .filter (asset) -> not reject asset
    .map (name) ->
      url = path.relative dest.bundles, name .replace /\\/g, '/'
      # console.log \pack url
      fs.read-file-async name
        .then (buffer) -> ["/#url", encode url, buffer]
    .then pairs-to-obj

bundle-sizes = ->
  sizes = {}
  last-file = null
  buffer-contents = (file, enc, cb) ->
    sizes['/' + file.relative.replace /\\/g '/'] = file.stat.size
    last-file := file
    cb!

  end-of-stream =(cb) ->
    unless last-file then cb!
    @push new vinyl {
      base: last-file.base
      path: path.join last-file.base, 'bundles.json'
      contents: new Buffer (JSON.stringify sizes), 'utf-8'
    }
    cb!

  through2.obj buffer-contents, end-of-stream
