describe 'Diff', ->
  beforeEach ->
    @cut = require '../src/htmldiff.coffee'

  describe 'When both inputs are the same', ->
    beforeEach ->
      @res = @cut 'input text', 'input text'

    it 'should return the text', ->
      (expect @res).equal 'input text'

  describe 'When a letter is added', ->
    beforeEach ->
      @res = @cut 'input', 'input 2'

    it 'should mark the new letter', ->
      (expect @res).to.equal 'input<ins> 2</ins>'

  describe 'Whitespace differences', ->
    it 'should collapse adjacent whitespace', ->
      (expect @cut 'Much \n\t    spaces', 'Much spaces').to.equal 'Much spaces'

    it 'should consider non-breaking spaces as equal', ->
      (expect @cut 'Hello&nbsp;world', 'Hello&#160;world').to.equal 'Hello&#160;world'

    it 'should consider non-breaking spaces and non-adjacent regular spaces as equal', ->
      (expect @cut 'Hello&nbsp;world', 'Hello world').to.equal 'Hello world'

  describe 'When a class name is specified', ->
    it 'should include the class in the wrapper tags', ->
      (expect @cut 'input', 'input 2', 'diff-result').to.equal \
        'input<ins class="diff-result"> 2</ins>'
