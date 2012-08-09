# calculates the differences into a list of edit operations
describe 'calculate_operations', ->
  beforeEach ->
    @cut = (require '../src/htmldiff.coffee').calculate_operations

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'Actions', ->
    describe 'Replace', ->
      beforeEach ->
        before = 'working on it'.split ' '
        after = 'working in it'.split ' '
        @res = @cut before, after

      it 'should result in 3 operations', ->
        (expect @res.length).to.equal 3

      it 'should replace "on"', ->
        (expect @res[1]).eql
          action         : 'replace'
          start_in_before: 1
          end_in_before  : 1
          start_in_after : 1
          end_in_after   : 1


    describe 'Insert', ->
      beforeEach ->
        before = 'working it'.split ' '
        after = 'working on it'.split ' '
        @res = @cut before, after

      it 'should result in 3 operation', ->
        (expect @res.length).to.equal 3

      it 'should show an insert for "on"', ->
        (expect @res[1]).eql
          action         : 'insert'
          start_in_before: 1
          end_in_before  : undefined
          start_in_after : 1
          end_in_after   : 1

      describe 'More than one word', ->
        beforeEach ->
          before = 'working it'.split ' '
          after = 'working all up on it'.split ' '
          @res = @cut before, after

        it 'should still have 3 operations', ->
          (expect @res.length).to.equal 3

        it 'should show a big insert', ->
          (expect @res[1]).eql
            action         : 'insert'
            start_in_before: 1
            end_in_before  : undefined
            start_in_after : 1
            end_in_after   : 3

    describe 'Delete', ->
      beforeEach ->
        before = 'this is a lot of text'.split ' '
        after = 'this is text'.split ' '
        @res = @cut before, after

      it 'should return 3 operations', ->
        (expect @res.length).to.equal 3

      it 'should show the delete in the middle', ->
        (expect @res[1]).eql
          action: 'delete'
          start_in_before: 2
          end_in_before: 4
          start_in_after: 2
          end_in_after: undefined

    describe 'Equal', ->
      beforeEach ->
        before = 'this is what it sounds like'.split ' '
        after = 'this is what it sounds like'.split ' '
        @res = @cut before, after

      it 'should return a single op', ->
        (expect @res.length).to.equal 1
        (expect @res[0]).eql
          action: 'equal'
          start_in_before: 0
          end_in_before: 5
          start_in_after: 0
          end_in_after: 5
