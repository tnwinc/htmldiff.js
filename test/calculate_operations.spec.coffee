# calculates the differences into a list of edit operations
describe 'calculate_operations', ->
  beforeEach ->
    @cut = (require '../src/htmldiff.coffee').calculate_operations

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'Actions', ->
    describe 'In the middle', ->

      describe 'Replace', ->
        beforeEach ->
          before = 'working on it'.split ' '
          after = 'working in it'.split ' '
          @res = @cut before, after

        it 'should result in 3 operations', ->
          (expect @res.length).to.equal 3

        it 'should replace "on"', ->
          (expect @res[1]).eql
            action         :  'replace'
            start_in_before: 1
            end_in_before  : 1
            start_in_after : 1
            end_in_after   : 1

      describe 'Insert', ->
        beforeEach ->
          before = 'working it'.split ' '
          after = 'working on it'.split ' '
          @res = @cut before, after

        it 'should result in 3 operations', ->
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

    describe 'At the beginning', ->

      describe 'Replace', ->
        beforeEach ->
          before = 'I dont like veggies'.split ' '
          after = 'Joe loves veggies'.split ' '
          @res = @cut before, after

        it 'should return 2 operations', ->
          (expect @res.length).to.equal 2

        it 'should have a replace at the beginning', ->
          (expect @res[0]).eql
            action         : 'replace'
            start_in_before: 0
            end_in_before  : 2
            start_in_after : 0
            end_in_after   : 1

      describe 'Insert', ->
        beforeEach ->
          before = 'dog'.split ' '
          after = 'the shaggy dog'.split ' '
          @res = @cut before, after

        it 'should return 2 operations', ->
          (expect @res.length).to.equal 2

        it 'should have an insert at the beginning', ->
          (expect @res[0]).eql
            action         : 'insert'
            start_in_before: 0
            end_in_before  : undefined
            start_in_after : 0
            end_in_after   : 1

      describe 'Delete', ->
        beforeEach ->
          before = 'awesome dog barks'.split ' '
          after = 'dog barks'.split ' '
          @res = @cut before, after

        it 'should return 2 operations', ->
          (expect @res.length).to.equal 2

        it 'should have a delete at the beginning', ->
          (expect @res[0]).eql
            action         : 'delete'
            start_in_before: 0
            end_in_before  : 0
            start_in_after : 0
            end_in_after   : undefined

    describe 'At the end', ->
      describe 'Replace', ->
        beforeEach ->
          before = 'the dog bit the cat'.split ' '
          after = 'the dog bit a bird'.split ' '
          @res = @cut before, after

        it 'should return 2 operations', ->
          (expect @res.length).to.equal 2

        it 'should have a replace at the end', ->
          (expect @res[1]).eql
            action         : 'replace'
            start_in_before: 3
            end_in_before  : 4
            start_in_after : 3
            end_in_after   : 4

      describe 'Insert', ->
        beforeEach ->
          before = 'this is a dog'.split ' '
          after = 'this is a dog that barks'.split ' '
          @res = @cut before, after

        it 'should return 2 operations', ->
          (expect @res.length).to.equal 2

        it 'should have an Insert at the end', ->
          (expect @res[1]).eql
            action         : 'insert'
            start_in_before: 4
            end_in_before  : undefined
            start_in_after : 4
            end_in_after   : 5

      describe 'Delete', ->
        beforeEach ->
          before = 'this is a dog that barks'.split ' '
          after = 'this is a dog'.split ' '
          @res = @cut before, after

        it 'should have 2 operations', ->
          (expect @res.length).to.equal 2

        it 'should have a delete at the end', ->
          (expect @res[1]).eql
            action         : 'delete'
            start_in_before: 4
            end_in_before  : 5
            start_in_after : 4
            end_in_after   : undefined

  describe 'Action Combination', ->
    describe 'Absorb single-whitespace to make contiguous replace actions', ->
      beforeEach ->
        #There are a bunch of replaces, but, because whitespace is
        #tokenized, they are broken up with equals. We want to combine
        #them into a contiguous replace operation.
        before = ['I', ' ', 'am', ' ', 'awesome']
        after = ['You', ' ', 'are', ' ', 'great']
        @res = @cut before, after

      it 'should return 1 action', ->
        (expect @res.length).to.equal 1

      it 'should return the correct replace action', ->
        (expect @res[0]).eql
          action: 'replace'
          start_in_before: 0
          end_in_before: 4
          start_in_after: 0
          end_in_after: 4

      describe 'but dont absorb non-single-whitespace tokens', ->
        beforeEach ->
          before = ['I', '  ', 'am', ' ', 'awesome']
          after = ['You', '  ', 'are', ' ', 'great']
          @res = @cut before, after

        it 'should return 3 actions', ->
          (expect @res.length).to.equal 3

        it 'should have a replace first', ->
          (expect @res[0].action).to.equal 'replace'

        it 'should have an equal second', ->
          (expect @res[1].action).to.equal 'equal'

        it 'should have a replace last', ->
          (expect @res[2].action).to.equal 'replace'
