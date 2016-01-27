provider = require './provider'
path = require 'path'
fs = require 'fs'
cson = require 'cson'
SuggestionTree = require './trie'
{CompositeDisposable} = require 'atom'
{TextEditor} = require 'atom'

classLoad = cson.load atom.packages.getLoadedPackage('css-spy').path+'/grammar/class-add.cson'

# atom.grammars.grammarsByScopeName['text.html.basic'].rawPatterns.unshift classLoad['link']
# atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-class-attribute'] = classLoad['tag-class-attribute']
# atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-href-attribute'] = classLoad['tag-href-attribute']
# atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-rel-attribute'] = classLoad['tag-rel-attribute']
# atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-stuff'].patterns.unshift {include: "#tag-class-attribute"}, {include: "#tag-href-attribute"}, {include: "#tag-rel-attribute"}


module.exports =
  subscriptions : null
  fsHandle : null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @fsHandle = []
    # startEditor = atom.workspace.getActiveTextEditor()
    # if startEditor?
    #   @watcherFunction(startEditor, @subscriptions)
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @watcherFunction(editor, @subscriptions)

    @subscriptions.add atom.commands.add 'atom-workspace', 'css-spy:toggle': => @toggle()
  getProvider: ->
    provider

  watcherFunction : (editor, subscription) =>
    if editor instanceof TextEditor && path.extname(editor.getPath()) is ".html" and !(editor.getPath() in Object.keys(provider.wordList))
      if atom.grammars.grammarsByScopeName['text.html.basic']?
        atom.grammars.grammarsByScopeName['text.html.basic'].rawPatterns.unshift classLoad['link']
        atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-class-attribute'] = classLoad['tag-class-attribute']
        atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-href-attribute'] = classLoad['tag-href-attribute']
        atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-rel-attribute'] = classLoad['tag-rel-attribute']
        atom.grammars.grammarsByScopeName['text.html.basic'].rawRepository['tag-stuff'].patterns.unshift {include: "#tag-class-attribute"}, {include: "#tag-href-attribute"}, {include: "#tag-rel-attribute"}
        console.log "grammars getting loaded"
        setTimeout(->
          console.log "list made for first time"
          # console.log editor.getPath()
          provider.makeWordList(editor)
          console.log "wordlistmade now refreshing"
          provider.refreshWordList(editor)
          console.log provider.wordList[editor.getPath()].cssFiles
          for cssFile in provider.wordList[editor.getPath()].cssFiles
            fs.watch(cssFile, (event) ->
              provider.makeWordList(editor)
              console.log "wordlistmade now refreshing"
              provider.refreshWordList(editor)
            )
        , 2000)

        changes = []

        subscription.add editor?.buffer.onDidChange (obj) ->
          changes.push obj

        subscription.add(editor?.buffer.onDidStopChanging (obj) ->
          #TODO-v2: have to include for absolute path and urls
          # console.log changes
          while changes.length != 0
            change = changes.pop()
            console.log change
            oldCssFiles = provider.wordList[editor.getPath()].cssFiles
            currentPath = path.dirname editor.getPath()
            startRow = Math.min.apply @, [change?.newRange.start.row, change?.newRange.end.row, change?.oldRange.start.row, change?.oldRange.end.row]
            endRow = Math.max.apply @, [change?.newRange.start.row, change?.newRange.end.row, change?.oldRange.start.row, change?.oldRange.end.row]
            for row in [(startRow-1)..(endRow+1)]
              line = atom.views.getView(editor).shadowRoot.querySelectorAll("[data-screen-row = '"+row+"']")?[1]
              if line?.querySelectorAll('.meta.tag.inline.link.html .meta.toc-list.rel.html')?[0]?.innerHTML is "stylesheet"
                cssFile = line.querySelectorAll('.meta.tag.inline.link.html .meta.toc-list.href.html')?[0]?.innerHTML
                # console.log cssFile
                currentPath = currentPath + '/' unless cssFile?[0] is '/'
                # console.log currentPath
                # console.log currentPath+cssFile in provider.wordList[editor.getPath()]?.cssFiles
                if !(currentPath+cssFile in provider.wordList[editor.getPath()]?.cssFiles?)
                  # provider.makeWordList(editor)
                  try
                    fs.accessSync (currentPath+cssFile).trim(), fs.R_OK
                    provider.wordList[editor.getPath()]?.cssFiles.push currentPath+cssFile
                    provider.makeWordList(editor)
                    console.log "wordlistmade now refreshing"
                    provider.refreshWordList(editor)
                    fs.watch currentPath+cssFile, (event) ->
                      provider.makeWordList(editor)
                      console.log "wordlistmade now refreshing"
                      provider.refreshWordList(editor)
                  catch err
                    console.log currentPath+cssFile+" not found"
                    line.querySelectorAll('.meta.tag.inline.link.html .meta.toc-list.href.html')?[0]?.style.textDecoration = "underline"
              # if row+"" in provider.wordList[editor.getPath()]?.cssFileLines

              provider.makeWordList editor
              console.log "wordlistmade now may refreshing"
              console.log oldCssFiles.sort().join(',')
              console.log provider.wordList[editor.getPath()]?.cssFiles.sort().join(',')
              if oldCssFiles.sort().join(',') != provider.wordList[editor.getPath()]?.cssFiles.sort().join(',')
                console.log provider.wordList[editor.getPath()]?.cssFiles.sort().join(', ')
                console.log "refreshing wordlist"
                provider.refreshWordList(editor)
              break

          # console.log atom.views.getView(editor).shadowRoot.querySelectorAll("[data-screen-row = '8']")?[1]?.querySelectorAll('.meta.tag.inline.link.html .meta.toc-list.rel.html')
          # console.log atom.views.getView(editor).shadowRoot
          # console.log obj
          # console.log editor.buffer
          # if obj.oldText == ""
          #   #TODO-v2: have to combine both the regex tests
          #   text = editor.buffer.scanInRange(/<\s?link\s?rel=\s?('|")\s?stylesheet\s?\1\s?href\s?=\s?('|")([\w-:.\\/_]*)\2/g, [[obj.newRange.start.row,0], [obj.newRange.end.row+1,0]], (obj) ->
          #     currentPath = currentPath + '/' unless obj.match[3][0] == '/'
          #     if !(currentPath+obj.match[3] in provider.wordList[editor.getPath()].cssFiles or obj.match[3] in provider.wordList[editor.getPath()].cssFiles)
          #       provider.makeWordList(editor)
          #       try
          #         fs.accessSync currentPath+obj.match[3], fs.R_OK
          #         fs.watch currentPath+obj.match[3], (event) ->
          #           provider.makeWordList(editor)
          #       catch err
          #     )
          #   text = editor.buffer.scanInRange(/<\s?link\s?href\s?=\s?('|")([\w-:.\\/_]*)\2\s?rel=\s?('|")\s?stylesheet\s?\1\s?/g, [[obj.newRange.start.row,0], [obj.newRange.end.row+1,0]], (obj) ->
          #     currentPath = currentPath + '/' unless obj.match[3][0] == '/'
          #     if !(currentPath+obj.match[3] in provider.wordList[editor.getPath()].cssFiles or obj.match[3] in provider.wordList[editor.getPath()].cssFiles)
          #       provider.makeWordList(editor)
          #       try
          #         fs.accessSync currentPath+obj.match[3], fs.R_OK
          #         fs.watch currentPath+obj.match[3], (event) ->
          #           provider.makeWordList(editor)
          #       catch err
          #     )
          # else
          #   # console.log "hi"
          #   # console.log editor.buffer.getText()
          #   text = editor.buffer.scanInRange(/<\s?link\s?rel=\s?('|")\s?stylesheet\s?\1\s?href\s?=\s?('|")([\w-:.\\/_]*)\2/g, [[obj.newRange.start.row,0], [obj.newRange.end.row+1,0]], (obj) ->
          #     currentPath = currentPath + '/' unless obj.match[3][0] == '/'
          #     if !(currentPath+obj.match[3] in provider.wordList[editor.getPath()].cssFiles or obj.match[3] in provider.wordList[editor.getPath()].cssFiles)
          #       provider.makeWordList(editor)
          #       try
          #         fs.accessSync currentPath+obj.match[3], fs.R_OK
          #         fs.watch currentPath+obj.match[3], (event) ->
          #           provider.makeWordList(editor)
          #       catch err
          #     )
          #
          ) if editor


  toggle: ->
    if provider.inclusionPriority == 5
      provider.inclusionPriority = -1
    else
      provider.inclusionPriority = 5

  deactivate: ->
    handle.close() for handle in @fsHandle
    @subscriptions.dispose()
