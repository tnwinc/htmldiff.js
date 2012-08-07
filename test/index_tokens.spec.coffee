describe 'index_tokens', ->
  beforeEach ->
    @cut = (require '../src/htmldiff.coffee').find_matching_blocks.create_index

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'When the items exist in the search target', ->
    beforeEach ->
      @res = @cut
        find_these: ['a', 'has']
        in_these: ['a', 'apple', 'has', 'a', 'worm']

    it 'should find "a" twice', ->
      (expect @res['a'].length).to.equal 2

    it 'should find "a" at 0', ->
      (expect @res['a'][0]).to.equal 0

    it 'should find "a" at 3', ->
      (expect @res['a'][1]).to.equal 3

    it 'should find "has" at 2', ->
      (expect @res['has'][0]).to.equal 2
