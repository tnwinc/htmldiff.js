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

  describe 'When dual pane is checked', ->
    beforeEach ->
      @res = @cut.diff_dual_pane 'input text', 'input text'

    it 'should should return the equivalent text', ->
      (expect @res).eql { before: 'input text', after: 'input text' }

  describe 'When dual pane is checked', ->
    beforeEach ->
      @res = @cut.diff_dual_pane 'input text', 'input texts'

    it 'should should return the text', ->
      (expect @res).eql { before: 'input <del>text</del>', after: 'input <ins>texts</ins>' }
