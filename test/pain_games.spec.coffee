describe 'Pain Games', ->
  beforeEach ->
    @cut = require '../src/htmldiff.coffee'

  describe 'When an entire sentence is replaced', ->
    beforeEach ->
      @res = @cut 'this is what I had', 'and now we have a new one'

    it 'should replace the whole chunk', ->
      (expect @res).to.equal '<del>this is what I had</del>'\
      + '<ins>and now we have a new one</ins>'
