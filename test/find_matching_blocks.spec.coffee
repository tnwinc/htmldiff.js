describe 'find_matching_blocks', ->
  beforeEach ->
    @diff = require '../src/htmldiff.coffee'

  describe 'find_match', ->
    beforeEach ->
      @cut = @diff.find_matching_blocks.find_match
      @invoke = (before, after)=>
        index = @diff.find_matching_blocks.create_index
          find_these: before
          in_these: after

        @res = @cut before, after, index, 0, before.length, 0, after.length

    describe 'When there is a match', ->
      beforeEach ->
        before = ['a', 'dog', 'bites']
        after = ['a', 'dog', 'bites', 'a', 'man']
        @invoke before, after

      it 'should match the match', ->
        (expect @res).to.exist
        (expect @res.start_in_before).equal 0
        (expect @res.start_in_after).equal 0
        (expect @res.length).equal 3
        (expect @res.end_in_before).equal 2
        (expect @res.end_in_after).equal 2

      describe 'When the match is surrounded', ->
        beforeEach ->
          before = ['dog', 'bites']
          after = ['the', 'dog', 'bites', 'a', 'man']
          @invoke before, after

        it 'should match with appropriate indexing', ->
          (expect @res).to.exist
          (expect @res.start_in_before).to.equal 0
          (expect @res.start_in_after).to.equal 1
          (expect @res.end_in_before).to.equal 1
          (expect @res.end_in_after).to.equal 2



    describe 'When these is no match', ->
      beforeEach ->
        before = ['the', 'rat', 'sqeaks']
        after = ['a', 'dog', 'bites', 'a', 'man']
        @invoke before, after

      it 'should return nothing', ->
        (expect @res).to.not.exist



  describe 'index_tokens', ->
    beforeEach ->
      @cut = (require '../src/htmldiff.coffee')
        .find_matching_blocks.create_index

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
