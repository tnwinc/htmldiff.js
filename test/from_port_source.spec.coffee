describe 'The specs from the ruby source project', ->
  beforeEach ->
    @cut = require '../src/htmldiff.coffee'

  it 'should diff text', ->
    diff = @cut 'a word is here', 'a nother word is there'
    (expect diff).equal 'a<ins> nother</ins> word ' +
    'is <del>here</del><ins>there</ins>'

  it "should insert a letter and a space", ->
    diff = @cut 'a c', 'a b c'
    (expect diff).equal "a <ins>b </ins>c"

  it "should remove a letter and a space", ->
    diff = @cut 'a b c', 'a c'
    diff.should == "a <del>b </del>c"

  it "should change a letter", ->
    diff = @cut 'a b c', 'a d c'
    (expect diff).equal "a <del>b</del>" +
      "<ins>d</ins> c"
