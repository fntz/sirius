describe "Routing", ->
  R = Sirius.RoutePart
  j = if JQueryAdapter?
    new JQueryAdapter()
  else
    new PrototypeAdapter()

  Sirius.Application.adapter = j


  describe "RoutePart", ->
    it "Hash Routing", ->
      r = new R("#")
      expect(r.match("#/")).toBeTruthy()
      expect(r.match("#/abc")).toBeFalsy()
      expect(r.args.length).toEqual(0)

      r = new R("#/*")
      expect(r.end).toBeFalsy()
      expect(r.match("#/title/id/date/param1")).toBeTruthy()
      expect(r.args.length).toEqual(4)

      r = new R("#/:title/:id")
      expect(r.end).toBeTruthy()
      expect(r.match("#/post/1"))
      expect(r.args.length).toEqual(2)
      expect(r.match("#/post/abc/1")).toBeFalsy()
      expect(r.args.length).toEqual(0)

      r = new R("#/title")
      expect(r.end).toBeTruthy()
      expect(r.match("#/title")).toBeTruthy()
      expect(r.match("#/title1")).toBeFalsy()

      r = new R("#/post/[0-9]+")
      expect(r.match("#/post/190")).toBeTruthy()
      expect(r.args.length).toEqual(1)
      expect(r.match("#/post/")).toBeFalsy()
      expect(r.args.length).toEqual(0)
      expect(r.match("#/post/a90")).toBeFalsy()
      expect(r.args.length).toEqual(0)
      expect(r.match("#/post/title")).toBeFalsy()
      expect(r.args.length).toEqual(0)

    it "Plain Routing", ->
      r = new R("/")
      expect(r.match("/")).toBeTruthy()
      expect(r.match("/abc")).toBeFalsy()
      expect(r.args.length).toEqual(0)

      r = new R("/*")
      expect(r.end).toBeFalsy()
      expect(r.match("/title/id/date/param1")).toBeTruthy()
      expect(r.args.length).toEqual(4)

      r = new R("/:title/:id")
      expect(r.end).toBeTruthy()
      expect(r.match("/post/1"))
      expect(r.args.length).toEqual(2)
      expect(r.match("/post/abc/1")).toBeFalsy()
      expect(r.args.length).toEqual(0)

      r = new R("/title")
      expect(r.end).toBeTruthy()
      expect(r.match("/title")).toBeTruthy()
      expect(r.match("/title1")).toBeFalsy()

      r = new R("post/[0-9]+")
      expect(r.match("post/190")).toBeTruthy()
      expect(r.args.length).toEqual(1)
      expect(r.match("post/")).toBeFalsy()
      expect(r.args.length).toEqual(0)
      expect(r.match("post/a90")).toBeFalsy()
      expect(r.args.length).toEqual(0)
      expect(r.match("post/title")).toBeFalsy()
      expect(r.args.length).toEqual(0)


  describe "Routing and Controllers for Hash Routing and Event Routing", ->

    postValue = errorValue = actionId = actionClass = titleValue = null
    emptyValue = postXValue = eventCustomValue = nonEmptyValue = null
    beforeEach (done) ->
      window.location.hash = ""
      Controller =
        error: (current) ->
          errorValue = current

        action: (e, id, klass) ->
          actionId = id
          actionClass = klass

        title: (title) ->
          titleValue = "abc"


      r =
        "#/": () -> emptyValue = arguments.length
        "#/post/[0-9]+" : (id) ->
          postValue = id
        "#/post/:title" : {controller: Controller, action: "title"}
        "#/post/x/*": () -> nonEmptyValue = arguments.length
        "#/static" : () -> postXValue = arguments.length
        404: {controller: Controller, action: "error"}
        "event:custom" : (e, p0) -> eventCustomValue = p0
        "click #my-div": {controller: Controller, action: "action", data: ["id", "class"]}

      ps = history.pushState ? true : false
      setting =
        old: true
        top: true
        support: ps

      Sirius.RouteSystem.create(r, setting)

      setTimeout(
        () ->  window.location.hash = "#/"
        0
      )
      setTimeout(
        () ->  window.location.hash = "#/post/12"
        400
      )
      setTimeout(
        () ->  window.location.hash = "#/post/abc"
        800
      )
      setTimeout(
        () ->  window.location.hash = "#/post/x/a/b/c"
        1200
      )
      setTimeout(
        () ->  window.location.hash = "#/static"
        1600
      )
      setTimeout(
        () ->  window.location.hash = "#/error"
        2000
      )
      setTimeout(
        () ->
          window.location.hash = ""
          done()
        2400
      )

      j.fire(document, "event:custom", 0)
      if JQueryAdapter?
        jQuery("#my-div").trigger("click")
      else
        $("my-div").simulate("click")


    it "test", (done)->
      expect(postValue).toEqual("12")
      expect(actionId).toEqual("my-div")
      expect(actionClass).toEqual("abc")
      expect(titleValue).toEqual("abc")
      expect(errorValue).toEqual("#/error")
      expect(emptyValue).toEqual(0)
      expect(nonEmptyValue).toEqual(3)
      expect(postXValue).toEqual(0)
      # fixme fire not work with prototype.js without path
      if JQueryAdapter?
        expect(eventCustomValue).toEqual(0)
      done()


  describe "Routing and Controllers for Plain Routing", ->
    if history.pushState
      emptyValue = postValue = titleValue = postXValue = staticValue = errorValue = null

      beforeEach (done) ->
        arr = ["/", "/post/12", "/post/abc", "/post/x/a/b/c", "/static", "/error", "/"]
        if JQueryAdapter?
          jQuery("body").append("<div id='links'></div>")
          for a in arr
            jQuery('#links').append($("<a></a>").attr({'href':a}).text(a))
        else
          $(document.body).insert({bottom: "<div id='links'></div>"})
          for a in arr
            $("links").insert("<a href='#{a}'>#{a}</a>")

        Controller =
          error: (current) -> errorValue = current
          title: (title) -> titleValue = title

        r =
          "/": () ->
            emptyValue = arguments.length
          "/post/[0-9]+" : (id) -> postValue = id
          "/post/:title" : {controller: Controller, action: "title"}
          "/post/x/*": () -> postXValue = arguments.length
          "/static" : () -> staticValue = arguments.length
          404: {controller: Controller, action: "error"}

        Sirius.Application.run({
          route: r,
          adapter: j
        })

        if JQueryAdapter?
          links = $("#links a")
          for l in links
            jQuery(l).trigger("click")
        else
          links = $("links").childElements()
          for l in links
            $(l).simulate("click")
        done()

      it "test", (done) ->
        expect(emptyValue).toEqual(0)
        expect(postValue).toEqual("12")
        expect(titleValue).toEqual("abc")
        expect(errorValue).toEqual("/error")
        expect(postXValue).toEqual(3)
        expect(staticValue).toEqual(0)
        done()







