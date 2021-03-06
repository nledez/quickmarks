View          = require "../lib/view"
AppRouter     = require "../routers/app_router"
BookmarksView = require "./bookmarks_view"
Bookmark      = require "../models/bookmark"
TagsView      = require "./tags_view"
Tag           = require "../models/tag"

module.exports = class AppView extends View
    el: "body.application"

    events:
        "submit #bookmark-add": "bookmarkLink"
        "shown.bs.modal #add-modal": "showAddForm"
        "shown.bs.modal #edit-modal": "showAddForm"
        "submit .search": "search"
        "click .tags-show": "showTags"
        "click .tags-hide": "hideTags"
        "click .import": "import"
        "change .import-file": "uploadFile"
        "click .export": "export"

    template: ->
        template = require "./templates/home"
        infos =
            "mainUrl": window.location.href
        template infos

    initialize: () ->
        @router = CozyApp.Routers.AppRouter = new AppRouter()
        @loader = $("#loader")

    startLoader: ->
        @loader.show("slow")

    stopLoader: ->
        @loader.hide()

    isQuickmarklet: ->
        window.location.href.search("quickmarklet") > 0

    parseArgs: ->
        path  = window.location.href.split("?")[1].split("&")
        args = 
            "url": decodeURIComponent(path[1].split("=")[1])
            "title": decodeURIComponent(path[2].split("=")[1])

    setQuickmarletValues: ->
        args = @parseArgs()
        $("#add-link").val(args["url"])
        $("#add-title").val(args["title"])

    afterRender: ->
        @startLoader()
        @bookmarksView = new BookmarksView()

        @bookmarksView.collection.fetch
            success: =>
                @stopLoader()
                window.sortOptions =
                    "valueNames": ["title", 
                                   "url", 
                                   "tags", 
                                   "description"]
                window.featureList = new List "content", window.sortOptions
                View.log "bookmarks loaded"

        @tagsView = new TagsView()
        @tagsView.collection.fetch
            success: =>
                @tagsView.renderAll()
        if @isQuickmarklet()
            $("#add-modal").modal("show")
            @setQuickmarletValues()

    showAddForm: (evt) ->
        $("#add-link").focus()

    showEditForm: (evt) ->
        $("#edit-link").focus()

    cleanForm: (form) ->
        form.find("input[type=text], textarea").val("")

    bookmarkLink: (evt) ->
        evt.preventDefault()

        url = $("#add-link").val()

        if url?.length > 0
            title       = $("#add-title").val()
            description = $("#add-description").val()
            bookmark = new Bookmark()
            bookmark.set  
                "title": title
                "url": url
                "description": description
                "tags": bookmark.setTags $("#add-tags").val()
            @bookmarksView.collection.create bookmark,
                "success": =>
                    View.log "" + (title || url) + " added."
                    modal = $("#add-modal")
                    modal.modal "hide"
                    @cleanForm(modal.find("form"))
                "error": =>
                    View.error "Server error occured, " +
                               "bookmark was not saved"
        else
            View.error "Url field is required"

    search: (evt) ->
        false

    showTags: () ->
        $(".tag").addClass("tag-show")
        $(".tags-show").hide()
        $(".tags-hide").show()

    hideTags: () ->
        $(".tag").removeClass("tag-show")
        $(".tags-hide").hide()
        $(".tags-show").show()


    addBookmarkFromFile: (link, others) ->
        $link = $ link
        if !!$link.attr("href").indexOf("place") and not $link.attr("feedurl")
            url         = $link.attr "href"
            title       = $link.text()
            description = ""
            next = $link.parents(":first").next()
            if next.is "dd"
                description = next.text()
            tags = []
            if $link.attr "tags"
               tags =  $link.attr("tags").split(",")

            bookmark = new Bookmark
                title: title
                url: url
                tags: tags
                description: description
            @bookmarksView.collection.create bookmark,
                success: =>
                    imported = $ ".import .done"
                    if imported.text()
                        imported.text(parseInt(imported.text()) + 1)
                    else
                        imported.text(1)
                    @addBookmarkFromFile others[0], others[1..]

                error: =>
                    notImported = $ ".import .failed"
                    if notImported.text()
                        notImported.text(parseInt(notImported.text()) + 1)
                    else
                        notImported.text(1)
                    @addBookmarkFromFile others[0], others[1..]

    addBookmarksFromFile: (file) ->
        importButton = $ ".import button"
        loaded = $ file
        links  = loaded.find "dt a"
        @addBookmarkFromFile links[0], links[1..]
        importButton.removeClass "doing"

    uploadFile: (evt) ->
        importButton = $ ".import button"
        if importButton.hasClass "doing"
            View.error "I'm working!" 
        else
            file = evt.target.files[0]
            if file.type != "text/html"
                View.error "This file cannot be imported"
                return
            importButton.addClass "doing"

            reader = new FileReader()
            reader.onload = (evt) => @addBookmarksFromFile evt.target.result
            reader.readAsText file

    import: () ->
        $(".import-file").click()

    export: () ->
        window.location = "export"