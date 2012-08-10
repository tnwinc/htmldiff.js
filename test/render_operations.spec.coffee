describe 'render_operations', ->
  beforeEach ->
    diff = (require '../src/htmldiff.coffee')
    @cut = (before, after)->
      before = before.split ' '
      after = after.split ' '
      ops = diff.calculate_operations before, after
      diff.render_operations before, after, ops

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'equal', ->
    beforeEach ->
      before = 'this is a test'
      after = 'this is a test'
      @res = @cut before, after

    it 'should output the text', ->
      (expect @res).equal 'this is a test'

  describe 'insert', ->
    beforeEach ->
      before = 'this is'
      after = 'this is a test'
      @res = @cut before, after

    it 'should wrap in an <ins>', ->
      (expect @res).equal 'this is<ins> a test</ins>'


  describe 'delete', ->
    beforeEach ->
      before = 'this is a test of stuff'
      after = 'this is a test'
      @res = @cut before, after

    it 'should wrap in a <del>', ->
      (expect @res).to.equal 'this is a test<del> of stuff</del>'


  describe 'replace', ->
    beforeEach ->
      before = 'this is a break'
      after = 'this is a test'
      @res = @cut before, after

    it 'should wrap in both <ins> and <del>', ->
      (expect @res).to.equal 'this is a<del> break</del><ins> test</ins>'
