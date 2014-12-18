require! 'lib/parse'

describe 'lib/parse' ->
  describe '#to-object' ->
    specify 'should turn strings to objects' ->
      expect (typeof! parse.to-object 'hello world') .to.equal 'Object'

    specify 'should pull out keys and values' ->
      expect (parse.to-object 'hello world, sing songs') .to.eql hello: 'world', sing: 'songs'

    specify 'should remove colons from keys' ->
      expect (parse.to-object 'hello: world, sing: songs') .to.eql hello: 'world', sing: 'songs'

    specify 'should camelize keys' ->
      expect (parse.to-object 'some-greeting: hello!') .to.eql some-greeting: 'hello!'

    specify 'should handle values containing spaces' ->
      expect (parse.to-object 'i contain spaces, and so do I') .to.eql i: 'contain spaces', and: 'so do I'

    specify 'should return an empty object for an empty string' ->
      expect (parse.to-object '') .to.eql {}
