is_end_of_tag = (char)->
  char is '>'

is_start_of_tag = (char)->
  char is '<'

is_whitespace = (char)->
  /\s/.test char

html_to_tokens = (html)->
  mode = 'char'
  current_word = ''
  words = []

  for char in html
    switch mode
      when 'tag'
        if is_end_of_tag char
          current_word += '>'
          words.push current_word
          current_word = ''
          if is_whitespace char
            mode = 'whitespace'
          else
            mode = 'char'
        else
          current_word += char
      when 'char'
        if is_start_of_tag char
          words.push current_word if current_word
          current_word = '<'
          mode = 'tag'
        else if /\s/.test char
          words.push current_word if current_word
          current_word = char
          mode = 'whitespace'
        else if /[\w\#@]+/i.test char
          current_word += char
        else
          words.push current_word if current_word
          current_word = char
      when 'whitespace'
        if is_start_of_tag char
          words.push current_word if current_word
          current_word = '<'
          mode = 'tag'
        else if is_whitespace char
          current_word += char
        else
          words.push current_word if current_word
          current_word = char
          mode = 'char'
      else throw new Error "Unknown mode #{mode}"

  words.push current_word if current_word
  return words

diff = (before, after)->
  return before if before is after

  before = html_to_tokens before
  after = html_to_tokens after

diff.html_to_tokens = html_to_tokens
module.exports = diff
