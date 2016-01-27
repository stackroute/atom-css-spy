css = require 'css'
fs = require 'fs'
SuggestionTree = require './trie'
path = require 'path'
wordList = {}
{TextEditorView} = require('atom')
console.log TextEditorView

module.exports =
  selector: '.text.html .class'
  disableForSelector: '.text.html .comment'
  inclusionPriority: 5
  excludeLowerPriority: true
  wordList : wordList

  makeWordList: (editor)->
    filePath = editor.getPath()
    console.log filePath
    wordList[filePath] = {}
    wordList[filePath].cssFiles = []
    wordList[filePath].cssFileLines = []
    console.log "emptying suggestions to rebuild makeWordList"
    console.log wordList[filePath].suggTrie
    wordList[filePath].suggTrie = new SuggestionTree()
    currentPath = path.dirname filePath
    editorView = atom.views.getView(editor)
    console.log editorView.querySelector('body /deep/ .meta.tag.inline.link.html')
    # console.log editorView
    # console.log editorView?.querySelectorAll('.meta.tag.inline.link.html .meta.toc-list.rel.html')
    # console.log "e" if editorView?.querySelector('.meta.tag.inline.link.html .meta.toc-list.rel.html')?.innerHTML is "stylesheet"

    # console.log editorView
    linkLines = editorView?.querySelectorAll('body /deep/ .meta.tag.inline.link.html')
    console.log editorView.querySelectorAll('body /deep/ .meta.tag.inline.link.html')
    for line in linkLines
      if line?.querySelectorAll('.meta.toc-list.rel.html')?[0]?.innerHTML is "stylesheet"
        cssFile = line?.querySelectorAll('.meta.toc-list.href.html')?[0]?.innerHTML
        cssFileLine = line?.parentNode.parentNode.getAttribute('data-screen-row')
        currentPath = currentPath + '/' unless cssFile[0] == '/'
        try
          fs.accessSync (currentPath+cssFile).trim(), fs.R_OK
          wordList[filePath].cssFiles.push(currentPath+cssFile)
          wordList[filePath].cssFileLines.push cssFileLine
        catch err
          console.log currentPath+cssFile + " not found"
          line.querySelectorAll('.meta.toc-list.href.html')?[0]?.style.textDecoration = "underline"

    # editor.scan(/stylesheet/g, (object) ->
    #   line = object.lineText
    #   console.log object
    #   if line.match(/[\w._/]+\.css/)
    #     link = line.match(/[\w._/]+\.css/)[0]
    #   else
    #     return
    #   currentPath = currentPath + '/' unless link[0] == '/'
    #   try
    #     fs.accessSync currentPath+link, fs.R_OK
    #     wordList[filePath].cssFiles.push(currentPath+link)
    #   catch err
    #     # no such css file exists
    #   )
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
    # console.log wordList[editor.getPath()].suggTrie.search("", true)
    wordList[editor.getPath()].suggTrie.head = {}
    wordList[editor.getPath()].suggTrie.insertWords wordList[editor.getPath()].listArray
    # wordList[filePath].listArray
    # console.log wordList[editor.getPath()].suggTrie.search("", true)
    console.log "word list made"

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    new Promise (resolve) ->
      console.log atom.workspaceView
      if prefix == ""
        resolve []
      else
        console.log "asking for sugg"
        list = []
        # sugg = wordList[editor.getPath()].suggTrie
        # console.log wordList[editor.getPath()].listArray

        # console.log sugg
        console.log wordList[editor.getPath()].suggTrie.search("", true)
        list = wordList[editor.getPath()].suggTrie.wordsWithPrefix "."+prefix
        # console.log wordList[editor.getPath()].suggTrie.wordsWithPrefix ".c"
        suggestions = []
        console.log list
        suggestions.push({"text": eachWord?.substring(1,eachWord?.length), "type": "class"}) for eachWord in list if list?
        console.log suggestions
        console.log editor.getPath()
        console.log wordList[editor.getPath()]
        resolve suggestions
