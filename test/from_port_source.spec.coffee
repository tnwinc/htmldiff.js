describe 'The specs from the ruby source project', ->
  beforeEach ->
    @cut = require '../src/htmldiff'

  xit 'should diff text', ->
    diff = @cut 'a word is here', 'a nother word is there'
    (expect diff).equal 'a<ins class=\"diffins\"> nother</ins> word " +
      "is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>'

  xit "should insert a letter and a space", ->
    diff = @cut 'a c', 'a b c'
    (expect diff).equal "a <ins class=\"diffins\">b </ins>c"

  xit "should remove a letter and a space", ->
    diff = @cut 'a b c', 'a c'
    diff.should == "a <del class=\"diffdel\">b </del>c"

  xit "should change a letter", ->
    diff = @cut 'a b c', 'a d c'
    (expect diff).equal "a <del class=\"diffmod\">b</del>" +
      "<ins class=\"diffmod\">d</ins> c"
