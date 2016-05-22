require! {
  'lib/tree-inspectors'
}

# This function is dedicated to Dom from A Tale Unfolds. http://ataleunfolds.co.uk/
# He's pretty awesome.
export to-dom = (src) ->
  Slowparse.HTML document, src, {
    error-detectors: [tree-inspectors.forbidJS]
    disable-omittable-close-tags: true
  }
