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
}

glob = Promise.promisify-all glob
fs = Promise.promisify-all fs

gulp.task 'pack' ->
  gulp.src src.bundles
    .pipe create-bundle!
    .pipe gulp-debug {title: \packaged}
    .pipe gulp.dest dest.bundles

export encode = (name, buffer) ->
  ext = path.extname name .to-lower-case!.replace /^\./ ''
  switch ext
  | <[html css js]> => buffer.to-string 'utf-8'
  | \json => type: \json, data: JSON.parse buffer.to-string 'utf-8'
  | <[png jpeg gif]> => type: \image, format: ext, data: buffer.to-string 'base64'
  | <[mp3 ogg]> => type: \arraybuffer, format: ext, data: buffer.to-string 'base64'
  | otherwise => throw new TypeError "Unknown extname #{ext} on file #{name}"

export watch = ->
  filename-to-task-id = (name) -> "pack-#{name.to-lower-case!.replace /\//g, '-' .replace /[^a-z0-9-]/g, ''}"
  files-for = (name) ->
    file = JSON.parse fs.read-file-sync name, encoding: 'utf-8'
    unless file.assets then return []

    dirname = path.dirname path.join path.sep, path.relative dest.bundles, name
    assets = file.assets
      |> map (asset) -> path.join dest.bundles, path.resolve dirname, asset
      |> map glob.sync
      |> flatten
      |> unique

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

    dirname = path.join path.sep, path.dirname file.relative
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
    .filter (asset) -> not reject asset
    .map (name) ->
      url = path.relative dest.bundles, name .replace /\\/g, '/'
      fs.read-file-async name
        .then (buffer) -> ["/#url", encode url, buffer]
    .then pairs-to-obj
