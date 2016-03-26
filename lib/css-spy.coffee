provider = require './provider'
path = require 'path'
fs = require 'fs'
cson = require 'cson'
{CompositeDisposable} = require 'atom'

classLoad = cson.load atom.packages.getPackageDirPaths()+'/css-spy/grammar/class-add.cson'

module.exports =
  subscriptions : null
  fsHandle : null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @fsHandle = []
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @watcherFunction(editor, @subscriptions)

    @subscriptions.add atom.commands.add 'atom-workspace', 'css-spy:toggle': => @toggle()
  getProvider: ->
    provider

  watcherFunction : (editor, subscription) =>
    if path.extname(editor.getPath()) is ".html" and !(editor.getPath() in Object.keys(provider.wordList))
      if atom.grammars.grammarsByScopeName['text.html.basic']?
        if !atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-class-attribute']?
          atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-class-attribute'] = classLoad['tag-class-attribute']
          atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-stuff'].patterns.unshift {include: "#tag-class-attribute"}
        provider.makeWordList(editor)
        provider.refreshWordList(editor)
        for cssFile in provider.wordList[editor.getPath()].cssFiles
          fs.watchFile(cssFile, (event) ->
            provider.makeWordList(editor)
            provider.refreshWordList(editor)
          ) unless cssFile.match(/http/i)?.index == 0

        changes = []

        subscription.add editor?.buffer.onDidChange (obj) ->
          changes.push obj

        subscription.add(editor?.buffer.onDidStopChanging (obj) ->
          #TODO-v2: have to include for absolute path and urls
          while changes.length != 0
            change = changes.pop()
            # provider.wordList[editor.getPath()]?.cssFiles = []
            currentPath = path.dirname editor.getPath()
            startRow = Math.min.apply @, [change?.newRange.start.row, change?.newRange.end.row, change?.oldRange.start.row, change?.oldRange.end.row]
            endRow = Math.max.apply @, [change?.newRange.start.row, change?.newRange.end.row, change?.oldRange.start.row, change?.oldRange.end.row]
            lines = atom.workspace.getActiveTextEditor(editor).getBuffer().lines
            for row in [(startRow-1)..(endRow+1)]
              line = lines[row]
              if line?.match(/\s*rel\s*=\s*('|")\s*(\w*)\s*\1/i)?[2] is "stylesheet"
                cssFile = line.match(/\s*href\s*=\s*('|")\s*([:\-.\/\\\w]+)\s*\1/i)?[2]
                currentPath = currentPath + '/' unless cssFile?[0] is '/'
                if !(currentPath+cssFile in provider.wordList[editor.getPath()]?.cssFiles or cssFile in provider.wordList[editor.getPath()]?.cssFiles)
                  try
                    fs.accessSync (currentPath+cssFile).trim(), fs.R_OK
                    # provider.wordList[editor.getPath()]?.cssFiles.push currentPath+cssFile
                    fs.watchFile currentPath+cssFile, (event) ->
                      provider.makeWordList(editor)
                      provider.refreshWordList(editor)
                  catch err

                  provider.makeWordList(editor)
                  provider.refreshWordList(editor)

              if row in provider.wordList[editor.getPath()]?.cssFileLines
                provider.makeWordList editor
                provider.refreshWordList(editor)
                break
          ) if editor

  toggle: ->
    if provider.inclusionPriority == 5
      provider.inclusionPriority = -1
    else
      provider.inclusionPriority = 5

  deactivate: ->
    handle.close() for handle in @fsHandle
    @subscriptions.dispose()
