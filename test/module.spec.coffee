describe 'The module', ->
  beforeEach ->
    @cut = require '../src/htmldiff'

  it 'should return a function', ->
    (expect @cut).is.a 'function'
