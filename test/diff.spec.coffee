describe 'Diff', ->
  beforeEach ->
    @cut = require '../src/htmldiff.coffee'

  describe 'When both inputs are the same', ->
    beforeEach ->
      @res = @cut 'input text', 'input text'

    it 'should return the text', ->
      (expect @res).equal 'input text'
