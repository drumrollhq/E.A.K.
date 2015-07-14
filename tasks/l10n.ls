require! {
  './packer'
  'event-stream': es
  'fs'
  'glob'
  'gulp'
  'gulp-preprocess'
  'handlebars'
  'lodash.defaults': defaults
  'lodash.merge': merge
  'path'
  'prelude-ls': {map, join, split, first, initial, camelize, last, tail}
  'through2'
}

scripts = glob.sync './app/scripts/**/*.{ls,hbs}'
  |> map ( .replace /^\.\/app\/scripts\// '/js/')
  |> map ( .replace /\.(ls|hbs)$/ '.js')
  |> map -> """<script src="#it"></script>"""
  |> join '\n'

scripts += '<script src="/js/api-spec.js"></script>'

preprocess-context = {
  optimized: optimized
  production: production
  scripts: scripts
  languages: languages |> map (-> "'#it'") |> join ',' |> (-> "[#it]")
  config: global.config
  config-str: JSON.stringify global.config
}

create-app-bundle = ->
  packer.bundle-assets ['js/vendor.js', 'js/eak.js', 'css/app.css'], 'utf-8'
    .then (assets) ->
      contents = new Buffer (JSON.stringify assets), encoding: 'utf-8'
      fs.write-file-sync 'public/eak-bundle.json', contents
      ['/eak-bundle.json', contents.length]

get-bootstrap = -> fs.read-file-sync './gulp-cache/bootstrap.js', encoding: 'utf-8'

get-context = ->
  Promise.all [
    eak-version
    create-app-bundle!
    get-bootstrap!
  ] .then ([version, [app-package-src, app-package-size], bootstrap]) ->
    {version, app-package-src, app-package-size, bootstrap}

gulp.task 'l10n-data' ->
  gulp.src src.locale-data
    .pipe locale-data-cache! .on 'error' -> throw it

gulp.task 'l10n' ['l10n-data' 'bootstrap-livescript'] ->
  get-context!.then (ctx) ->
    console.log 'Version:' ctx.version
    preprocess-context <<< ctx
    gulp.src src.locale-templates
      .pipe gulp-preprocess context: preprocess-context
      .pipe localize! .on 'error' -> throw it
      .pipe gulp.dest dest.assets

function localize
  default-lang = first languages
  through2.obj (file, enc, cb) ->
    if file.stat.is-directory! then return cb!
    path = relative-path file
    template = handlebars.compile file.contents.to-string!

    for lang in languages
      data = get-locale-data lang, path
      f = file.clone!
      f.contents = new Buffer template data
      f.path = "#{f.base}/#{lang}/#{path}"
      @push f

      if lang is default-lang
        f .= clone!
        f.path = "#{f.base}/#{path}"
        @push f

    cb!

_locale-cache = {}
function locale-data-cache
  es.map (file, cb) ->
    lang = file |> relative-path |> country-code
    data = JSON.parse file.contents.to-string!

    _locale-cache[lang] ?= {}
    lang-data = _locale-cache[lang]

    for key, {message} of data
      file = key |> split '/' |> initial |> join path.sep
      name = key |> split '/' |> last |> split '.' |> map camelize

      lang-data[file] ?= {}
      file-data = lang-data[file]
      set-path file-data, name, message

    cb null, file

function relative-path file
  path.relative file.base, file.path

function country-code dir
  dir |> split path.sep |> first

function get-locale-data lang, file
  default-lang = first languages
  data = _locale-cache{}[lang]{}[file]

  default-data = _locale-cache[default-lang][file]
  d = merge data, default-data, defaults
  unless file is \app
    d.app-translations = JSON.stringify get-locale-data lang, \app

  d.LANG = lang
  d

function set-path obj, path, val
  switch
  | path.length is 1 => obj[first path] = val
  | otherwise =>
    obj[first path] ?= {}
    set-path obj[first path], (tail path), val
