css = require 'css'
fs = require 'fs'
SuggestionTree = require './trie'
path = require 'path'
wordList = {}

module.exports =
  selector: '.text.html .class'
  disableForSelector: '.text.html .comment'
  inclusionPriority: 5
  excludeLowerPriority: true
  wordList : wordList

  makeWordList: (editor)->
    filePath = editor.getPath()
    wordList[filePath] = {}
    wordList[filePath].cssFiles = []
    wordList[filePath].cssFileLines = []
    wordList[filePath].suggTrie = new SuggestionTree()
    currentPath = path.dirname filePath
    lines = editor.getBuffer().lines
    linkLines = []
    for line, index in lines
      linkLines.push {lineText : line, lineNo : index} if line.match(/<\s*link\s*[\s:\-.='"\\\/\w]+\s*>/i)
    for line in linkLines
      if line.lineText?.match(/\s*rel\s*=\s*('|")\s*(\w*)\s*\1/i)?[2] is "stylesheet"
        cssFile = line.lineText.match(/\s*href\s*=\s*('|")\s*([\-.\/\\\w]+)\s*\1/i)?[2]
        continue unless cssFile
        cssFileLine = line.lineNo
        currentPath = currentPath + '/' unless cssFile?[0] == '/'
        try
          fs.accessSync (currentPath+cssFile).trim(), fs.R_OK
          wordList[filePath].cssFiles.push(currentPath+cssFile)
          wordList[filePath].cssFileLines.push cssFileLine
        catch err

  refreshWordList: (editor) ->
    filePath = editor.getPath()
    wordList[filePath].listArray = []
    for file in wordList[filePath].cssFiles when wordList[filePath].cssFiles?
      try
        cssText = fs.readFileSync file, 'utf8'
      catch err
        continue
      cssParseObj = css.parse cssText
      for oneRule in cssParseObj.stylesheet.rules when cssParseObj.type is "stylesheet" and oneRule.type is "rule"
        for oneSelector in oneRule.selectors when wordList[filePath].listArray.indexOf(oneSelector) is -1
          wordList[filePath].listArray = wordList[filePath].listArray.concat oneSelector.split(' ')
    wordList[editor.getPath()].suggTrie.head = {}
    wordList[editor.getPath()].suggTrie.insertWords wordList[editor.getPath()].listArray

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    new Promise (resolve) ->
      prefix = prefix.trim()
      if prefix == ""
        resolve []
      else
        list = []
        list = wordList[editor.getPath()].suggTrie.wordsWithPrefix "."+prefix
        suggestions = []
        suggestions.push({"text": eachWord?.substring(1,eachWord?.length), "type": "class"}) for eachWord in list if list?
        resolve suggestions
