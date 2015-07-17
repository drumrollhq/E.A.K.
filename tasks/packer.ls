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
  gulp.src './public/**/area.json'
    .pipe create-bundle!
    .pipe gulp-debug {title: \packaged}
    .pipe gulp.dest './public'

export watch = ->
  filename-to-task-id = (name) -> "pack-#{name.to-lower-case!.replace /\//g, '-' .replace /[^a-z0-9-]/g, ''}"
  files-for = (name) ->
    file = JSON.parse fs.read-file-sync name, encoding: 'utf-8'
    unless file.assets then return []

    dirname = path.dirname path.join path.sep, path.relative './public', name
    assets = file.assets
      |> map (asset) -> path.join './public', path.resolve dirname, asset
      |> map glob.sync
      |> flatten
      |> unique

    assets

  packages = glob.sync './public/**/area.json'

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
    unless bundle.assets then return cb!

    dirname = path.join path.sep, path.dirname file.relative
    assets = for asset-path in bundle.assets => path.resolve dirname, asset-path

    make = (name, reject) ~>
      bundle-assets assets, reject: reject
        .then (assets) ~>
          new-bundle = {} <<< bundle <<< {assets}
          f = file.clone!

          p = path.parse f.path
          p.name += '-' + name
          p.base = p.name + p.ext
          f.path = path.format p

          f.contents = new Buffer JSON.stringify new-bundle
          @push f

    Promise.all [(make 'packaged-ogg', (.match /\.mp3$/)), (make 'packaged-mp3', (.match /\.ogg$/))]
      .then -> cb!
      .catch (e) -> cb e

export bundle-assets = (assets, {encoding = 'base64', reject = -> false} = {}) ->
  Promise
    .map assets, (f) -> glob.glob-async path.join './public/', f
    .then flatten >> unique
    .filter (asset) -> not reject asset
    .map (name) ->
      url = path.relative 'public', name .replace /\\/g, '/'
      fs.read-file-async name
        .then (buffer) -> ["/#url", buffer.to-string encoding]
    .then pairs-to-obj
