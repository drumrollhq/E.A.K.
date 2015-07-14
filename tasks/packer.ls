require! {
  'bluebird': Promise
  'event-stream': 'es'
  'fs'
  'glob'
  'gulp'
  'gulp-debug'
  'gulp-rename'
  'path'
  'prelude-ls': {flatten, unique, pairs-to-obj}
}

glob = Promise.promisify-all glob
fs = Promise.promisify-all fs

gulp.task 'pack' ->
  gulp.src './public/**/area.json'
    .pipe gulp-rename (path) -> path.basename += '-packaged'
    .pipe gulp-debug {title: \to-packaged}
    .pipe create-bundle!
    .pipe gulp-debug {title: \packaged}
    .pipe gulp.dest './public'

export create-bundle = (encoding) ->
  es.map (file, cb) ->
    bundle = JSON.parse file.contents.to-string!
    unless bundle.assets then return cb null, file

    dirname = path.join path.sep, path.dirname file.relative
    assets = for asset-path in bundle.assets => path.resolve dirname, asset-path

    bundle-assets assets, encoding
      .then (assets) ->
        bundle.assets = assets
        f = file.clone!
        f.contents = new Buffer JSON.stringify bundle, null, 2
        cb null, f
      .catch (e) ->
        cb e, null

export bundle-assets = (assets, encoding = 'base64') ->
  Promise
    .map assets, (f) -> glob.glob-async path.join './public/', f
    .then flatten >> unique
    .map (name) ->
      url = path.relative 'public', name .replace /\\/g, '/'
      fs.read-file-async name
        .then (buffer) -> ["/#url", buffer.to-string encoding]
    .then pairs-to-obj
