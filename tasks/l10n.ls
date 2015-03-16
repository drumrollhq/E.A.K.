require! {
  'path'
  'event-stream': es
  'through2'
  'glob'
  'gulp-preprocess'
  'gulp'
  'prelude-ls': {map, join, split, first, initial, camelize, last, tail}
  'handlebars'
  'lodash.merge': merge
  'lodash.defaults': defaults
}

scripts = glob.sync './app/scripts/**/*.{ls,hbs}'
  |> map ( .replace /^\.\/app\/scripts\// '/js/')
  |> map ( .replace /\.(ls|hbs)$/ '.js')
  |> map -> """<script src="#it"></script>"""
  |> join '\n'

preprocess-context = {
  optimized: optimized
  scripts: scripts
  languages: languages |> map (-> "'#it'") |> join ',' |> (-> "[#it]")
}

gulp.task 'l10n-data' ->
  gulp.src src.locale-data
    .pipe locale-data-cache! .on 'error' -> throw it

gulp.task 'l10n' ['l10n-data'] ->
  eak-version.then (v) ->
    console.log 'Version:' v
    preprocess-context.version = v
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
      file = key |> split '/' |> initial |> join '/'
      path = key |> split '/' |> last |> split '.' |> map camelize

      lang-data[file] ?= {}
      file-data = lang-data[file]
      set-path file-data, path, message

    cb null, file

function relative-path file
  path.relative file.base, file.path

function country-code dir
  dir |> split path.sep |> first

function get-locale-data lang, file
  default-lang = first languages
  data = _locale-cache{}[lang]{}[file]

  default-data = _locale-cache[default-lang][file]
  merge data, default-data, defaults

function set-path obj, path, val
  switch
  | path.length is 1 => obj[first path] = val
  | otherwise =>
    obj[first path] ?= {}
    set-path obj[first path], (tail path), val
