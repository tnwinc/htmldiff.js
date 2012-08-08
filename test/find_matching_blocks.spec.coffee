describe 'find_matching_blocks', ->
  beforeEach ->
    @diff = require '../src/htmldiff.coffee'

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

  describe 'find_matching_blocks', ->
    beforeEach ->
      @cut = @diff.find_matching_blocks

    it 'should be a function', ->
      (expect @cut).is.a 'function'

    describe 'When called with a single match', ->
      beforeEach ->
        before = 'a dog bites'.split ' '
        after = 'when a dog bites it hurts'.split ' '
        @res = @cut before, after

      it 'should return a match', ->
        (expect @res.length).to.equal 1

    describe 'When called with multiple matches', ->
      beforeEach ->
        before = 'the dog bit a man'.split ' '
        after = 'the large brown dog bit a tall man'.split ' '
        @res = @cut before, after

      it 'should return 3 matches', ->
        (expect @res.length).to.equal 3

      it 'should match "the"', ->
        (expect @res[0]).eql
          start_in_before: 0
          start_in_after: 0
          end_in_before: 0
          end_in_after: 0
          length: 1

      it 'should match "dog bit a"', ->
        (expect @res[1]).eql
          start_in_before: 1
          start_in_after: 3
          end_in_before: 3
          end_in_after: 5
          length: 3

      it 'should match "man"', ->
        (expect @res[2]).eql
          start_in_before: 4
          start_in_after: 7
          end_in_before: 4
          end_in_after: 7
          length: 1
