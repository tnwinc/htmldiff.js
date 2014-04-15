###
 * htmldiff.js is a library that compares HTML content. It creates a diff between two
 * HTML documents by combining the two documents and wrapping the differences with
 * <ins> and <del> tags. Here is a high-level overview of how the diff works.
 *
 * 1. Tokenize the before and after HTML with html_to_tokens.
 * 2. Generate a list of operations that convert the before list of tokens to the after
 *    list of tokens with calculate_operations, which does the following:
 *      a. Find all the matching blocks of tokens between the before and after lists of
 *         tokens with find_matching_blocks. This is done by finding the single longest
 *         matching block with find_match, then recursively finding the next longest
 *         matching block that precede and follow the longest matching block with
 *         recursively_find_matching_blocks.
 *      b. Determine insertions, deletions, and replacements from the matching blocks.
 *         This is done in calculate_operations.
 * 3. Render the list of operations by wrapping tokens with <ins> and <del> tags where
 *    appropriate with render_operations.
 *
 * Example usage:
 *
 *   htmldiff = require 'htmldiff.js'
 *
 *   htmldiff '<p>this is some text</p>', '<p>this is some more text</p>'
 *   == '<p>this is some <ins>more </ins>text</p>'
 *
 *   htmldiff '<p>this is some text</p>', '<p>this is some more text</p>', 'diff-class'
 *   == '<p>this is some <ins class="diff-class">more </ins>text</p>'
###

is_end_of_tag = (char)-> char is '>'
is_start_of_tag = (char)-> char is '<'
is_whitespace = (char)-> /^\s+$/.test char
is_tag = (token)-> /^\s*<[^>]+>\s*$/.test token
isnt_tag = (token)-> not is_tag token

###
 * Checks if the current word is the beginning of an atomic tag. An atomic tag is one whose
 * child nodes should not be compared - the entire tag should be treated as one token. This
 * is useful for tags where it does not make sense to insert <ins> and <del> tags.
 *
 * @param {string} word The characters of the current token read so far.
 *
 * @return {string|null} The name of the atomic tag if the word will be an atomic tag,
 *    null otherwise
###
is_start_of_atomic_tag = (word)->
  result = /^<(iframe|object|math|svg|script)/.exec word
  result = result[1] if result
  return result

###
 * Checks if the current word is the end of an atomic tag (i.e. it has all the characters,
 * except for the end bracket of the closing tag, such as "<iframe></iframe").
 *
 * @param {string} word The characters of the current token read so far.
 * @param {string} tag The ending tag to look for.
 *
 * @return {boolean} True if the word is now a complete token (including the end tag),
 *    false otherwise.
###
is_end_of_atomic_tag = (word, tag)->
  (word.substring word.length - tag.length - 2) is "</#{tag}"

###
 * Checks if a tag is a void tag.
 *
 * @param {string} token The token to check.
 *
 * @return {boolean} True if the token is a void tag, false otherwise.
###
is_void_tag = (token) ->
  /^\s*<[^>]+\/>\s*$/.test token

###
 * Checks if a token can be wrapped inside a tag.
 *
 * @param {string} token The token to check.
 *
 * @return {boolean} True if the token can be wrapped inside a tag, false otherwise.
###
is_wrappable = (token) ->
  (isnt_tag token) or (is_start_of_atomic_tag token) or (is_void_tag token)

###
 * A Match stores the information of a matching block. A matching block is a list of
 * consecutive tokens that appear in both the before and after lists of tokens.
 *
 * @param {number} start_in_before The index of the first token in the list of before tokens.
 * @param {number} start_in_after The index of the first token in the list of after tokens.
 * @param {number} length The number of consecutive matching tokens in this block.
###
class Match
  constructor: (@start_in_before, @start_in_after, @length)->
    @end_in_before = (@start_in_before + @length) - 1
    @end_in_after = (@start_in_after + @length) - 1

###
 * Tokenizes a string of HTML.
 *
 * @param {string} html The string to tokenize.
 *
 * @return {Array.<string>} The list of tokens.
###
html_to_tokens = (html)->
  mode = 'char'
  current_word = ''
  current_atomic_tag = ''
  words = []

  for char in html
    switch mode
      when 'tag'
        atomic_tag = is_start_of_atomic_tag current_word
        if atomic_tag
          mode = 'atomic_tag'
          current_atomic_tag = atomic_tag
          current_word += char
        else if is_end_of_tag char
          current_word += '>'
          words.push current_word
          current_word = ''
          if is_whitespace char
            mode = 'whitespace'
          else
            mode = 'char'
        else
          current_word += char
      when 'atomic_tag'
        if (is_end_of_tag char) \
        and (is_end_of_atomic_tag current_word, current_atomic_tag)
          current_word += '>'
          words.push current_word
          current_word = ''
          current_atomic_tag = ''
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
        else if /[\w\d\#@]/.test char
          # Consider '#' as part of the same word, since it might be part of an HTML escaped
          # character (e.g. '&#160;').
          current_word += char
        else if /&/.test char
          # Consider '&' as the start of a new word, since it might be the start of an HTML
          # escaped character (e.g. '&#160;').
          words.push current_word if current_word
          current_word = char
        else
          current_word += char
          words.push current_word
          current_word = ''
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

###
 * Creates a key that should be used to match tokens. This is useful, for example, if we want
 * to consider two open tag tokens as equal, even if they don't have the same attributes. We
 * use a key instead of overwriting the token because we may want to render the original string
 * without losing the attributes.
 *
 * @param {string} token The token to create the key for.
 *
 * @return {string} The identifying key that should be used to match before and after tokens.
###
get_key_for_token = (token)->
  # If the token is a tag, return just the tag with no attributes since we do not compare
  # attributes yet.
  tag_name = /<([^\s>]+)[\s>]/.exec token
  return "<#{tag_name[1].toLowerCase()}>" if tag_name

  # If the token is text, collapse adjacent whitespace and replace non-breaking spaces with
  # regular spaces.
  return token.replace /(\s+|&nbsp;|&#160;)/g, ' ' if token

  return token

###
 * Finds the matching block with the most consecutive tokens within the given range in the
 * before and after lists of tokens.
 *
 * @param {Array.<string>} before_tokens The before list of tokens.
 * @param {Array.<string>} after_tokens The after list of tokens.
 * @param {Object} index_of_before_locations_in_after_tokens The index that is used to search
 *      for tokens in the after list.
 * @param {number} start_in_before The beginning of the range in the list of before tokens.
 * @param {number} end_in_before The end of the range in the list of before tokens.
 * @param {number} start_in_after The beginning of the range in the list of after tokens.
 * @param {number} end_in_after The end of the range in the list of after tokens.
 *
 * @return {Match} A Match that describes the best matching block in the given range.
###
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
    looking_for = get_key_for_token before_tokens[index_in_before]
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

###
 * Finds all the matching blocks within the given range in the before and after lists of
 * tokens. This function is called recursively to find the next best matches that precede
 * and follow the first best match.
 *
 * @param {Array.<string>} before_tokens The before list of tokens.
 * @param {Array.<string>} after_tokens The after list of tokens.
 * @param {Object} index_of_before_locations_in_after_tokens The index that is used to search
 *      for tokens in the after list.
 * @param {number} start_in_before The beginning of the range in the list of before tokens.
 * @param {number} end_in_before The end of the range in the list of before tokens.
 * @param {number} start_in_after The beginning of the range in the list of after tokens.
 * @param {number} end_in_after The end of the range in the list of after tokens.
 * @param {Array.<Match>} matching_blocks The list of matching blocks found so far.
 *
 * @return {Array.<Match>} The list of matching blocks in this range.
###
recursively_find_matching_blocks = (before_tokens, after_tokens,
  index_of_before_locations_in_after_tokens,
  start_in_before, end_in_before,
  start_in_after, end_in_after,
  matching_blocks)->

  match = (find_match before_tokens, after_tokens,
    index_of_before_locations_in_after_tokens,
    start_in_before, end_in_before,
    start_in_after, end_in_after)

  if match?
    if start_in_before < match.start_in_before\
    and start_in_after < match.start_in_after
      recursively_find_matching_blocks before_tokens, after_tokens,
        index_of_before_locations_in_after_tokens,
        start_in_before, match.start_in_before,
        start_in_after, match.start_in_after,
        matching_blocks

    matching_blocks.push match

    if match.end_in_before <= end_in_before\
    and match.end_in_after <= end_in_after
      recursively_find_matching_blocks before_tokens, after_tokens,
        index_of_before_locations_in_after_tokens,
        match.end_in_before + 1, end_in_before,
        match.end_in_after + 1, end_in_after,
        matching_blocks

  return matching_blocks

###
 * Creates an index (A.K.A. hash table) that will be used to match the list of before
 * tokens with the list of after tokens.
 *
 * @param {Object} options An object with the following:
 *    - {Array.<string>} find_these The list of tokens that will be used to search.
 *    - {Array.<string>} in_these The list of tokens that will be returned.
 *
 * @return {Object} An index that can be used to search for tokens.
###
create_index = (options)->
  throw new Error 'params must have find_these key' unless options.find_these?
  throw new Error 'params must have in_these key' unless options.in_these?

  queries = options.find_these.map (token)->
    return get_key_for_token token
  results = options.in_these.map (token)->
    return get_key_for_token token

  index = {}
  for query in queries
    index[query] = []
    idx = results.indexOf query
    while idx isnt -1
      index[query].push idx
      idx = results.indexOf query, idx+1

  return index

###
 * Finds all the matching blocks in the before and after lists of tokens. This function
 * is a wrapper for the recursive function recursively_find_matching_blocks.
 *
 * @param {Array.<string>} before_tokens The before list of tokens.
 * @param {Array.<string>} after_tokens The after list of tokens.
 *
 * @return {Array.<Match>} The list of matching blocks.
###
find_matching_blocks = (before_tokens, after_tokens)->
  matching_blocks = []
  index_of_before_locations_in_after_tokens =
    create_index
      find_these: before_tokens
      in_these: after_tokens

  recursively_find_matching_blocks before_tokens, after_tokens,
    index_of_before_locations_in_after_tokens,
    0, before_tokens.length,
    0, after_tokens.length,
    matching_blocks

###
 * Gets a list of operations required to transform the before list of tokens into the
 * after list of tokens. An operation describes whether a particular list of consecutive
 * tokens are equal, replaced, inserted, or deleted.
 *
 * @param {Array.<string>} before_tokens The before list of tokens.
 * @param {Array.<string>} after_tokens The after list of tokens.
 *
 * @return {Array.<Object>} The list of operations to transform the before list of
 *      tokens into the after list of tokens, where each operation has the following
 *      keys:
 *      - {string} action One of {'replace', 'insert', 'delete', 'equal'}.
 *      - {number} start_in_before The beginning of the range in the list of before tokens.
 *      - {number} end_in_before The end of the range in the list of before tokens.
 *      - {number} start_in_after The beginning of the range in the list of after tokens.
 *      - {number} end_in_after The end of the range in the list of after tokens.
###
calculate_operations = (before_tokens, after_tokens)->
  throw new Error 'before_tokens?' unless before_tokens?
  throw new Error 'after_tokens?' unless after_tokens?
  position_in_before = position_in_after = 0
  operations = []
  action_map =
    'false,false': 'replace'
    'true,false' : 'insert'
    'false,true' : 'delete'
    'true,true'  : 'none'

  matches = find_matching_blocks before_tokens, after_tokens
  matches.push new Match before_tokens.length,  after_tokens.length, 0

  for match, index in matches
    match_starts_at_current_position_in_before =
      position_in_before is match.start_in_before
    match_starts_at_current_position_in_after =
      position_in_after is match.start_in_after

    action_up_to_match_positions =
    action_map[[match_starts_at_current_position_in_before,\
    match_starts_at_current_position_in_after].toString()]

    if action_up_to_match_positions isnt 'none'
      operations.push
        action: action_up_to_match_positions
        start_in_before: position_in_before
        end_in_before: (match.start_in_before - 1 \
        unless action_up_to_match_positions is 'insert')
        start_in_after: position_in_after
        end_in_after: (match.start_in_after - 1 \
        unless action_up_to_match_positions is 'delete')

    unless match.length is 0
      operations.push
        action: 'equal'
        start_in_before: match.start_in_before
        end_in_before: match.end_in_before
        start_in_after: match.start_in_after
        end_in_after: match.end_in_after

    position_in_before = match.end_in_before + 1
    position_in_after = match.end_in_after + 1

  post_processed = []
  last_op = action: 'none'
  is_single_whitespace = (op)->
    return no unless op.action is 'equal'
    return no unless op.end_in_before - op.start_in_before is 0
    return /^\s$/.test before_tokens[op.start_in_before..op.end_in_before]

  for op in operations
    if ((is_single_whitespace op) and last_op.action is 'replace') or
    (op.action is 'replace' and last_op.action is 'replace')
      last_op.end_in_before = op.end_in_before
      last_op.end_in_after = op.end_in_after
    else
      post_processed.push op
      last_op = op

  return post_processed

###
 * Returns a list of tokens of a particular type starting at a given index.
 *
 * @param {number} start The index of first token to test.
 * @param {Array.<string>} content The list of tokens.
 * @param {function} predicate A function that returns true if a token is of
 *      a particular type, false otherwise. It should accept the following
 *      parameters:
 *      - {string} The token to test.
###
consecutive_where = (start, content, predicate)->
  content = content[start..content.length]
  last_matching_index = undefined

  for token, index in content
    answer = predicate token
    last_matching_index = index if answer is yes
    break if answer is no

  return content[0..last_matching_index] if last_matching_index?
  return []

###
 * Wraps and concatenates a list of tokens with a tag. Does not wrap tag tokens,
 * unless they are wrappable (i.e. void and atomic tags).
 *
 * @param {sting} tag The tag name of the wrapper tags.
 * @param {Array.<string>} content The list of tokens to wrap.
 * @param {string} class_name (Optional) The class name to include in the wrapper tag.
###
wrap = (tag, content, class_name)->
  rendering = ''
  position = 0
  length = content.length

  loop
    break if position >= length
    non_tags = consecutive_where position, content, is_wrappable
    position += non_tags.length
    if non_tags.length isnt 0
      val = non_tags.join ''
      attrs = if class_name then " class=\"#{class_name}\"" else ''
      rendering += "<#{tag}#{attrs}>#{val}</#{tag}>" if val.trim()

    break if position >= length
    tags = consecutive_where position, content, is_tag
    position += tags.length
    rendering += tags.join ''

  return rendering

###
 * op_map.equal/insert/delete/replace are functions that render an operation into
 * HTML content.
 *
 * @param {Object} op The operation that applies to a prticular list of tokens. Has the
 *      following keys:
 *      - {string} action One of {'replace', 'insert', 'delete', 'equal'}.
 *      - {number} start_in_before The beginning of the range in the list of before tokens.
 *      - {number} end_in_before The end of the range in the list of before tokens.
 *      - {number} start_in_after The beginning of the range in the list of after tokens.
 *      - {number} end_in_after The end of the range in the list of after tokens.
 * @param {Array.<string>} before_tokens The before list of tokens.
 * @param {Array.<string>} after_tokens The after list of tokens.
 * @param {string} class_name (Optional) The class name to include in the wrapper tag.
 *
 * @return {string} The rendering of that operation.
###
op_map =
  equal: (op, before_tokens, after_tokens, class_name)->
    after_tokens[op.start_in_after..op.end_in_after].join ''

  insert: (op, before_tokens, after_tokens, class_name)->
    val = after_tokens[op.start_in_after..op.end_in_after]
    wrap 'ins', val, class_name

  delete: (op, before_tokens, after_tokens, class_name)->
    val = before_tokens[op.start_in_before..op.end_in_before]
    wrap 'del', val, class_name

op_map.replace = (op, before_tokens, after_tokens, class_name)->
  (op_map.delete op, before_tokens, after_tokens, class_name) +
  (op_map.insert op, before_tokens, after_tokens, class_name)

###
 * Renders a list of operations into HTML content. The result is the combined version
 * of the before and after tokens with the differences wrapped in tags.
 *
 * @param {Array.<string>} before_tokens The before list of tokens.
 * @param {Array.<string>} after_tokens The after list of tokens.
 * @param {Array.<Object>} operations The list of operations to transform the before
 *      list of tokens into the after list of tokens, where each operation has the
 *      following keys:
 *      - {string} action One of {'replace', 'insert', 'delete', 'equal'}.
 *      - {number} start_in_before The beginning of the range in the list of before tokens.
 *      - {number} end_in_before The end of the range in the list of before tokens.
 *      - {number} start_in_after The beginning of the range in the list of after tokens.
 *      - {number} end_in_after The end of the range in the list of after tokens.
 * @param {string} class_name (Optional) The class name to include in the wrapper tag.
 *
 * @return {string} The rendering of the list of operations.
###
render_operations = (before_tokens, after_tokens, operations, class_name)->
  rendering = ''
  for op in operations
    rendering += op_map[op.action] op, before_tokens, after_tokens, class_name

  return rendering

###
 * Compares two pieces of HTML content and returns the combined content with differences
 * wrapped in <ins> and <del> tags.
 *
 * @param {string} before The HTML content before the changes.
 * @param {string} after The HTML content after the changes.
 * @param {string} class_name (Optional) The class attribute to include in <ins> and <del> tags.
 *
 * @return {string} The combined HTML content with differences wrapped in <ins> and <del> tags.
###
diff = (before, after, class_name)->
  return before if before is after

  before = html_to_tokens before
  after = html_to_tokens after

  ops = calculate_operations before, after

  render_operations before, after, ops, class_name

diff.html_to_tokens = html_to_tokens
diff.find_matching_blocks = find_matching_blocks
find_matching_blocks.find_match = find_match
find_matching_blocks.create_index = create_index
find_matching_blocks.get_key_for_token = get_key_for_token
diff.calculate_operations = calculate_operations
diff.render_operations = render_operations

if typeof define is 'function'
  define [], ()-> diff
else if module?
  module.exports = diff
else
  this.htmldiff = diff
