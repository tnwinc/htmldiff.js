describe 'html_to_tokens', ->
  beforeEach ->
    @cut = (require '../src/htmldiff.coffee').html_to_tokens

  it 'should be a function', ->
    (expect @cut).is.a 'function'

  describe 'when called with text', ->
    beforeEach ->
      @res = @cut 'this is a test'

    it 'should return 4', ->
      (expect @res.length).to.equal 7

  describe 'when called with html', ->
    beforeEach ->
      @res = @cut '<p>this is a <strong>test</strong></p>'

    it 'should return 11', ->
      (expect @res.length).to.equal 11

  it 'should identify contiguous whitespace as a single token', ->
    (expect @cut 'a   b').to.eql ['a', '   ', 'b']

  it 'should identify a single space as a single token', ->
    (expect @cut ' a b ').to.eql [' ', 'a', ' ', 'b', ' ']

  it 'should identify self closing tags as tokens', ->
    (expect @cut '<p>hello</br>goodbye</p>')
    .eql ['<p>', 'hello', '</br>', 'goodbye', '</p>']

  describe 'when encountering atomic tags', ->
    it 'should identify an image tag as a single token', ->
      (expect @cut '<p><img src="1.jpg"><img src="2.jpg"></p>')
      .eql ['<p>', '<img src="1.jpg">', '<img src="2.jpg">', '</p>']

    it 'should identify an iframe tag as a single token', ->
      (expect @cut '<p><iframe src="sample.html"></iframe></p>')
      .eql ['<p>', '<iframe src="sample.html"></iframe>', '</p>']

    it 'should identify an object tag as a single token', ->
      (expect @cut '<p><object><param name="1" /><param name="2" /></object></p>')
      .eql ['<p>', '<object><param name="1" /><param name="2" /></object>', '</p>']

    it 'should identify a math tag as a single token', ->
      (expect @cut '<p><math xmlns="http://www.w3.org/1998/Math/MathML">' +
        '<mi>&#x03C0;<!-- π --></mi>' +
        '<mo>&#x2062;<!-- &InvisibleTimes; --></mo>' +
        '<msup><mi>r</mi><mn>2</mn></msup></math></p>')
      .eql [
        '<p>',
        '<math xmlns="http://www.w3.org/1998/Math/MathML">' +
            '<mi>&#x03C0;<!-- π --></mi>' +
            '<mo>&#x2062;<!-- &InvisibleTimes; --></mo>' +
            '<msup><mi>r</mi><mn>2</mn></msup></math>',
        '</p>']

    it 'should identify an svg tag as a single token', ->
      (expect @cut '<p><svg width="100" height="100">' +
        '<circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" />' +
        '</svg></p>')
      .eql [
        '<p>',
        '<svg width="100" height="100">' +
          '<circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" />' +
          '</svg>',
        '</p>']

    it 'should identify a script tag as a single token', ->
      (expect @cut '<p><script>console.log("hi");</script></p>')
      .eql ['<p>', '<script>console.log("hi");</script>', '</p>']
