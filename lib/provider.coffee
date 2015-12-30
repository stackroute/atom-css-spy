css = require 'css'
fs = require 'fs'
SuggestionTree = require './trie'
wordList = {}

module.exports =
  selector: '.text.html .string'
  disableForSelector: '.text.html .comment'
  inclusionPriority: 5
  excludeLowerPriority: true
  wordList : wordList

  makeWordList: (editor)->
    filePath = editor.getPath()
    wordList[filePath] = {}
    wordList[filePath].cssFiles = []
    wordList[filePath].listArray = []
    wordList[filePath].suggTrie = new SuggestionTree()
    currentPath = filePath.substring 0,filePath.lastIndexOf("\\")+1
    editor.scan(/stylesheet/g, (object) ->
      line = object.lineText
      link = line.match(/[\w._/]+\.css/)[0]
      wordList[filePath].cssFiles.push(currentPath+link)
      )
    for file in wordList[filePath].cssFiles when wordList[filePath].cssFiles?
      try
        cssText = fs.readFileSync file, 'utf8'
      catch err
        console.log err
        continue
      cssParseObj = css.parse cssText
      # console.log cssParseObj
      for oneRule in cssParseObj.stylesheet.rules when cssParseObj.type is "stylesheet" and oneRule.type is "rule"
        for oneSelector in oneRule.selectors when wordList[filePath].listArray.indexOf(oneSelector) is -1
          wordList[filePath].listArray = wordList[filePath].listArray.concat oneSelector.split(' ')
    wordList[filePath].listArray

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    new Promise (resolve) ->
      if prefix == ""
        resolve []
      else
        editor.buffer.backwardsScanInRange(/\bclass\s?=\s?(?:"|')[a-z][\w-:]*/i, [[0,0], [bufferPosition.row,bufferPosition.column]], (obj) ->
          if obj.range.end.column is bufferPosition.column
            list = []
            sugg = wordList[editor.getPath()].suggTrie
            sugg.insertWords wordList[editor.getPath()].listArray
            list = sugg.wordsWithPrefix "."+prefix
            suggestions = []
            suggestions.push({"text": eachWord?.substring(1,list[0]?.length), "type": "class"}) for eachWord in list if list?
            resolve suggestions
          )
