describe "Routing", ->
  R = Sirius.RoutePart

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


  describe "Routing and Controllers", ->
    it "Hash Routing", ->
      window.location.hash = ""
      error = null
      Controller =
        error: (current) ->
          error = current
          #expect(current).toEqual("#/error")

        action: (e, id, klass) ->
          expect(id).toEqual("my-div")
          expect(klass).toEqual("abc")

        title: (title) ->
          expect(title).toEqual("abc")

      r =
        "#/": () -> expect(arguments.length).toEqual(0)
        "#/post/[0-9]+" : (id) ->
          expect(arguments.length).toEqual(1)
          expect(id).toEqual(12)
        "#/post/:title" : {controller: Controller, action: "title"}
        "#/post/x/*": () -> expect(arguments.length).toEqual(3)
        "#/static" : () -> expect(arguments.length).toEqual(0)
        404: {controller: Controller, action: "error"}
        "event:custom" : (e, p0) -> expect(p0).toEqual(0)
        "click #my-div": {controller: Controller, action: "action", data: ["id", "class"]}

      j = new JQueryAdapter()
      Sirius.Application.adapter = j
      ps = history.pushState? true : false
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
        () ->  window.location.hash = ""
        2400
      )

      j.fire(document, "event:custom", 0)
      $("#my-div").trigger("click")


    it "Plain Routing", ->
      $("body").append("<div id='links'></div>")
      arr = ["/", "/post/12", "/post/abc", "/post/x/a/b/c", "/static", "/error", "/"]
      for a in arr
        $('#links').append($("<a></a>").attr({'href':a}))

      Controller =
        error: (current) ->
          expect(current).toEqual("#/error")

        title: (title) ->
          expect(title).toEqual("abc")


      r =
        "/": () -> expect(arguments.length).toEqual(0)
        "/post/[0-9]+" : (id) ->
          expect(arguments.length).toEqual(1)
          expect(id).toEqual(12)
        "/post/:title" : {controller: Controller, action: "title"}
        "/post/x/*": () -> expect(arguments.length).toEqual(3)
        "/static" : () -> expect(arguments.length).toEqual(0)
        404: {controller: Controller, action: "error"}


      Sirius.Application.run({
        route: r,
        adapter: new JQueryAdapter()
      })

      setTimeout(() ->
        links = $("#links a")
        for l in links
          $(l).trigger("click")

        2800
      )




