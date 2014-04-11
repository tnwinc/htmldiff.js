describe 'render_operations', ->
  beforeEach ->
    diff = (require '../src/htmldiff.coffee')
    @cut = (before, after)->
      ops = diff.calculate_operations before, after
      diff.render_operations before, after, ops

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'equal', ->
    beforeEach ->
      before = ['this', ' ', 'is', ' ', 'a', ' ', 'test']
      @res = @cut before, before

    it 'should output the text', ->
      (expect @res).equal 'this is a test'

  describe 'insert', ->
    beforeEach ->
      before = ['this', ' ', 'is']
      after = ['this', ' ', 'is', ' ', 'a', ' ', 'test']
      @res = @cut before, after

    it 'should wrap in an <ins>', ->
      (expect @res).equal 'this is<ins> a test</ins>'


  describe 'delete', ->
    beforeEach ->
      before = ['this', ' ', 'is', ' ', 'a', ' ', 'test', \
      ' ', 'of', ' ', 'stuff']
      after = ['this', ' ', 'is', ' ', 'a', ' ', 'test']
      @res = @cut before, after

    it 'should wrap in a <del>', ->
      (expect @res).to.equal 'this is a test<del> of stuff</del>'


  describe 'replace', ->
    beforeEach ->
      before = ['this', ' ', 'is', ' ', 'a', ' ', 'break']
      after = ['this', ' ', 'is', ' ', 'a', ' ', 'test']
      @res = @cut before, after

    it 'should wrap in both <ins> and <del>', ->
      (expect @res).to.equal 'this is a <del>break</del><ins>test</ins>'

  describe 'Dealing with tags', ->
    beforeEach ->
      before = ['<p>', 'a', '</p>']
      after = ['<p>', 'a', ' ', 'b', '</p>', '<p>', 'c', '</p>']
      @res = @cut before, after

    it 'should make sure the <ins/del> tags are within the <p> tags', ->
      (expect @res).to.equal '<p>a<ins> b</ins></p><p><ins>c</ins></p>'

    describe 'When there is a change at the beginning, in a <p>', ->
      beforeEach ->
        before = ['<p>', 'this', ' ', 'is', ' ', 'awesome', '</p>']
        after = ['<p>', 'I', ' ', 'is', ' ', 'awesome', '</p>']
        @res = @cut before, after

      it 'should keep the change inside the <p>', ->
        (expect @res).to.equal '<p><del>this</del><ins>I</ins> is awesome</p>'

  describe 'empty tokens', ->
    it 'should not be wrapped', ->
      before = ['text']
      after = ['text', ' ']

      @res = @cut before, after

      (expect @res).to.equal 'text'

  describe 'tags with attributes', ->
    it 'should treat attribute changes as equal and output the after tag', ->
      before = ['<p>', 'this', ' ', 'is', ' ', 'awesome', '</p>']
      after = ['<p style="margin: 2px;" class="after">', 'this', ' ', 'is', ' ', 'awesome', '</p>']

      @res = @cut before, after

      (expect @res).to.equal '<p style="margin: 2px;" class="after">this is awesome</p>'

    it 'should show changes within tags with different attributes', ->
      before = ['<p>', 'this', ' ', 'is', ' ', 'awesome', '</p>']
      after = ['<p style="margin: 2px;" class="after">', 'that', ' ', 'is', ' ', 'awesome', '</p>']

      @res = @cut before, after

      (expect @res).to.equal \
        '<p style="margin: 2px;" class="after"><del>this</del><ins>that</ins> is awesome</p>'

  describe 'wrappable tags', ->
    it 'should wrap void tags', ->
      before = ['old', ' ', 'text']
      after = ['new', '<br/>', ' ', 'text']

      @res = @cut before, after

      (expect @res).to.equal '<del>old</del><ins>new<br/></ins> text'

    it 'should wrap atomic tags', ->
      before = ['old', '<iframe src="source.html"></iframe>', ' ', 'text']
      after = ['new', ' ', 'text']

      @res = @cut before, after

      (expect @res).to.equal '<del>old<iframe src="source.html"></iframe></del><ins>new</ins> text'
