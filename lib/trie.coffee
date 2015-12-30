module.exports =

class SuggestionTree
  head : {}
  insertWord : (word) ->
    temp = @head
    for letter in word
      temp[letter] = {} unless temp[letter]?
      temp = temp[letter]
    temp["word"] = word

  insertWords : (words) ->
    @insertWord(word) for word in words

  search : (word, nodeSearch) ->
    temp = @head
    count = 0
    for letter in word
      count++;
      if temp[letter]?
        temp = temp[letter]
        if nodeSearch
          flag = (count == word.length)
        else
          flag = (temp.word == word)
        return temp if flag
      else
        return
    return

  DFS : (node) ->
    words=[]
    for child in Object.keys(node)
      if node[child].word?
        words.push node[child].word
        delete node[child].word
      else
        words.push node[child] if child is "word"
      words = words.concat @DFS node[child] unless node[child].word? or child is "word"
    words

  wordsWithPrefix : (prefix) ->
    prefix = prefix.trim()
    prefixNode = @search(prefix, true)
    @DFS prefixNode if prefixNode?
