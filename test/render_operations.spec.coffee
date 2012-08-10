describe 'render_operations', ->
  beforeEach ->
    diff = (require '../src/htmldiff.coffee')
    @operations = diff.calculate_operations
    @cut = diff.render_operations

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'equal', ->
    beforeEach ->
      before = 'this is a test'.split ' '
      after = 'this is a test'.split ' '
      ops = @operations before, after
      @res = @cut before, after, ops

    it 'should output the text', ->
      (expect @res).equal 'this is a test'
