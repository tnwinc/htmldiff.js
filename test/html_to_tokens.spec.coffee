describe 'html_to_tokens', ->
  beforeEach ->
    @cut = (require '../src/htmldiff.coffee').html_to_tokens

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'when called with text', ->
    beforeEach ->
      @res = @cut 'this is a test'

    it 'should return 4', ->
      (expect @res.length).to.equal 7

  describe 'when called with html', ->
    beforeEach ->
      @res = @cut '<p>this is a <strong>test</strong></p>'

    it 'should return 11', ->
      (expect @res.length).to.equal 11
