is_end_of_tag = (char)->
  char is '>'

is_start_of_tag = (char)->
  char is '<'

is_whitespace = (char)->
  /\s/.test char

util = require 'util'

class Match
  constructor: (@start_in_before, @start_in_after, @length)->
    @end_in_before = (@start_in_before + @length) - 1
    @end_in_after = (@start_in_after + @length) - 1

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

find_match = (before_tokens, after_tokens,
  index_of_before_locations_in_after_tokens,
  start_in_before, end_in_before,
  start_in_after, end_in_after)->

  best_match_in_before = start_in_before
  best_match_in_after = start_in_after
  best_match_length = 0

  match_length_at = {}

  for index_in_before in [start_in_before...end_in_before]
    new_match_length_at = {}
    looking_for = before_tokens[index_in_before]
    locations_in_after =
      index_of_before_locations_in_after_tokens[looking_for]

    for index_in_after in locations_in_after
      continue if index_in_after < start_in_after
      break if index_in_after >= end_in_after

      unless match_length_at[index_in_after - 1]?
        match_length_at[index_in_after - 1] = 0
      new_match_length = match_length_at[index_in_after - 1] + 1
      new_match_length_at[index_in_after] = new_match_length

      if new_match_length > best_match_length
        best_match_in_before = index_in_before - new_match_length + 1
        best_match_in_after = index_in_after - new_match_length + 1
        best_match_length = new_match_length

    match_length_at = new_match_length_at

  unless best_match_length is 0
    match = (new Match best_match_in_before, best_match_in_after,\
    best_match_length)

  return match

recursively_find_matching_blocks = (before_tokens, after_tokens,
  index_of_before_locations_in_after_tokens,
  start_in_before, end_in_before, start_in_after, end_in_after,
  matching_blocks)->

  match = (find_match before_tokens, after_tokens,
    index_of_before_locations_in_after_tokens,
    start_in_before, end_in_before, start_in_after, end_in_after)

  if match?
    if start_in_before < match.start_in_before\
    and start_in_after < match.start_in_after
      recursively_find_matching_blocks start_in_before, match.start_in_before,
        start_in_after, match.start_in_after, matching_blocks

    matching_blocks.push match
    if match.end_in_before < end_in_before and match.end_in_after < end_in_after
      recursively_find_matching_blocks match.end_in_before, end_in_before,
        match.end_in_after, end_in_after, matching_blocks

create_index = (p)->
  throw new Error 'params must have find_these key' unless p.find_these?
  throw new Error 'params must have in_these key' unless p.in_these?

  index = {}
  for token in p.find_these
    index[token] = []
    idx = p.in_these.indexOf token
    while idx isnt -1
      index[token].push idx
      idx = p.in_these.indexOf token, idx+1

  return index

find_matching_blocks = (before_tokens, after_tokens)->
  index_of_before_locations_in_after_tokens =
    create_index find_these: before_tokens, in_these: after_tokens
  matching_blocks = []
  recursively_find_matching_blocks before_tokens, after_tokens,
    index_of_before_locations_in_after_tokens,
    0, before_tokens.length,
    0, after_tokens.length, matching_blocks
  return matching_blocks


calculate_operations = (before_tokens, after_tokens)->
  #find matches
  #--work on matches--


diff = (before, after)->
  return before if before is after

  before = html_to_tokens before
  after = html_to_tokens after

diff.html_to_tokens = html_to_tokens
diff.find_matching_blocks = find_matching_blocks
find_matching_blocks.find_match = find_match
find_matching_blocks.create_index = create_index
diff.calculate_operations = calculate_operations
module.exports = diff
