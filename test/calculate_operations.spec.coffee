# calculates the differences into a list of edit operations
describe 'calculate_operations', ->
  beforeEach ->
    @cut = (require '../src/htmldiff.coffee').calculate_operations

  it 'should be a function', ->
    (expect @cut).is.a 'function'
