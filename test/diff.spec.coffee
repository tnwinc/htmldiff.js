describe 'Diff', ->
  beforeEach ->
    @cut = require '../src/htmldiff.coffee'

  describe 'When both inputs are the same', ->
    beforeEach ->
      @res = @cut 'input text', 'input text'

    it 'should return the text', ->
      (expect @res).equal 'input text'

  xdescribe 'When a letter is added', ->
    beforeEach ->
      @res = @cut 'input', 'input 2'

    it 'should mark the new letter', ->
      (expect @res).to.equal 'input <ins>2</ins>'
