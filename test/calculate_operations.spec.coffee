# calculates the differences into a list of edit operations
describe 'calculate_operations', ->
  beforeEach ->
    @cut = (require '../src/htmldiff.coffee').calculate_operations

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'Actions', ->
    #: action,
    #: start_in_before,
    #: end_in_before,
    #: start_in_after,
    #: end_in_after
    describe 'Replace', ->
      beforeEach ->
        before = 'working on it'.split ' '
        after = 'working in it'.split ' '
        @res = @cut before, after
        console.log @res

      it 'should result in 3 operations', ->
        (expect @res.length).to.equal 3

      it 'should replace "on"', ->
        (expect @res[1]).eql
          action: 'replace'
          start_in_before: 1
          end_in_before: 1
          start_in_after: 1
          end_in_after: 1


    describe 'Insert', ->

    describe 'Delete', ->

    describe 'Equal', ->
