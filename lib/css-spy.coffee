provider = require './provider'
path = require 'path'
fs = require 'fs'
{CompositeDisposable} = require 'atom'

module.exports =
  subscriptions : null
  fsHandle : null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @fsHandle = []
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      if path.extname(editor.getPath()) is ".html"
        provider.makeWordList(editor)
        for cssFile in provider.wordList[editor.getPath()].cssFiles
          fs.watch(cssFile, (event) ->
            provider.makeWordList(editor)
          )
        @subscriptions.add(editor.onDidChange (obj) ->
          #TODO-v2: have to include for absolute path and urls
          currentPath = path.dirname editor.getPath()
          #TODO-v2: have to combine both the regex tests
          text = editor.buffer.scanInRange(/<\s?link\s?rel=\s?('|")\s?stylesheet\s?\1\s?href\s?=\s?('|")([\w-:.\\/_]*)\2/g, [[obj.start,0], [obj.end+obj.screenDelta+1,0]], (obj) ->
            currentPath = currentPath + '/' unless obj.match[3][0] == '/'
            if !(currentPath+obj.match[3] in provider.wordList[editor.getPath()].cssFiles or obj.match[3] in provider.wordList[editor.getPath()].cssFiles)
              provider.makeWordList(editor)
              try
                fs.accessSync currentPath+obj.match[3], fs.R_OK
                fs.watch currentPath+obj.match[3], (event) ->
                  provider.makeWordList(editor)
              catch err

            )
          text = editor.buffer.scanInRange(/<\s?link\s?href\s?=\s?('|")([\w-:.\\/_]*)\2\s?rel=\s?('|")\s?stylesheet\s?\1\s?/g, [[obj.start,0], [obj.end+1,0]], (obj) ->
            currentPath = currentPath + '/' unless obj.match[3][0] == '/'
            if !(currentPath+obj.match[3] in provider.wordList[editor.getPath()].cssFiles or obj.match[3] in provider.wordList[editor.getPath()].cssFiles)
              provider.makeWordList(editor)
              try
                fs.accessSync currentPath+obj.match[3], fs.R_OK
                fs.watch currentPath+obj.match[3], (event) ->
                  provider.makeWordList(editor)
              catch err

            )) if editor


    @subscriptions.add atom.commands.add 'atom-workspace', 'css-spy:toggle': => @toggle()
  getProvider: ->
    provider

  toggle: ->
    if provider.inclusionPriority == 5
      provider.inclusionPriority = -1
    else
      provider.inclusionPriority = 5

  deactivate: ->
    handle.close() for handle in @fsHandle
    @subscriptions.dispose()
