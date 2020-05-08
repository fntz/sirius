describe "Routing", ->
  R = Sirius.Internal.RoutePart
  j = if JQueryAdapter?
    new JQueryAdapter()
  else if PrototypeAdapter?
    new PrototypeAdapter()
  else
    new VanillaJsAdapter()

  Sirius.Application.adapter = j

  describe "RoutePart", ->
    it "Hash Routing", ->
      r = new R("#")

      expect(r.match("#/").is_success()).toBeTrue()
      expect(r.match("#/abc").is_success()).toBeFalse()
      expect(r.match("#/abc").get_args()).toEqual([])

      r = new R("#/*")
      expect(r.is_end).toBeFalse()
      expect(r.match("#/title/id/date/param1").is_success()).toBeTrue()
      expect(r.match("#/title/id/date/param1").get_args())
        .toEqual(["title", "id", "date", "param1"])

      r = new R("#/:title/:id")
      expect(r.is_end).toBeTrue()
      expect(r.match("#/post/1").is_success()).toBeTrue()
      expect(r.match("#/post/1").get_args()).toEqual(["post", "1"])
      expect(r.match("#/post/abc/1").is_success()).toBeFalse()

      r = new R("#/title")
      expect(r.is_end).toBeTrue()
      expect(r.match("#/title").is_success()).toBeTrue()
      expect(r.match("#/title1").is_success()).toBeFalse()

      r = new R("#/post/[0-9]+")
      expect(r.match("#/post/190").is_success()).toBeTrue()
      expect(r.match("#/post/190").get_args()).toEqual(["190"])
      expect(r.match("#/post/").is_success()).toBeFalse()
      expect(r.match("#/post/a90").is_success()).toBeFalse()
      expect(r.match("#/post/title").is_success()).toBeFalse()

    it "Plain Routing", ->
      r = new R("/")
      expect(r.match("/").is_success()).toBeTrue()
      expect(r.match("/abc").is_success()).toBeFalse()

      r = new R("/*")
      expect(r.is_end).toBeFalse()
      expect(r.match("/title/id/date/param1").is_success()).toBeTrue()
      expect(r.match("/title/id/date/param1").get_args())
        .toEqual(["title", "id", "date", "param1"])

      r = new R("/:title/:id")
      expect(r.is_end).toBeTrue()
      expect(r.match("/post/1").is_success()).toBeTrue()
      expect(r.match("/post/1").get_args()).toEqual(["post", "1"])
      expect(r.match("/post/abc/1").is_success()).toBeFalse()

      r = new R("/title")
      expect(r.is_end).toBeTrue()
      expect(r.match("/title").is_success()).toBeTrue()
      expect(r.match("/title1").is_success()).toBeFalse()

      r = new R("post/[0-9]+")
      expect(r.match("post/190").is_success()).toBeTrue()
      expect(r.match("post/190").get_args()).toEqual(["190"])
      expect(r.match("post/").is_success()).toBeFalse()
      expect(r.match("post/a90").is_success()).toBeFalse()
      expect(r.match("post/title").is_success()).toBeFalse()

    it "More examples", ->
      p1 = new R("/show/sources/:source-name/all/page/:page")
      p2 = new R("/show/sources/:source-name")
      p3 = new R("/show/sources/:source-name/page/:page")
      p4 = new R("/show/sources/:source-name/all")
      p5 = new R("/show/feeds")

      source = "test-source"
      t1 = "/show/sources/#{source}"
      r12 = p2.match(t1)
      expect(r12.is_success()).toBeTrue()
      expect(r12.get_args()).toEqual([source])
      for p in [p1, p3, p4, p5]
        r = p.match(t1)
        expect(r.is_success()).toBeFalse()
        expect(r.get_args()).toEqual([])


      t2 = "/foo"
      for p in [p1, p2, p3, p4, p5]
        r = p.match(t2)
        expect(r.is_success()).toBeFalse()
        expect(r.get_args()).toEqual([])

      t3 = "/show/sources/#{source}/page/1"
      r33 = p3.match(t3)
      expect(r33.is_success()).toBeTrue()
      expect(r33.get_args()).toEqual([source, "1"])
      for p in [p1, p2, p4, p5]
        r = p.match(t3)
        expect(r.is_success()).toBeFalse()
        expect(r.get_args()).toEqual([])

      t4 = "/show/sources/#{source}/all/page/1"
      r41 = p1.match(t4)
      expect(r41.is_success()).toBeTrue()
      expect(r41.get_args()).toEqual([source, "1"])
      for p in [p2, p3, p4, p5]
        r = p.match(t4)
        expect(r.is_success()).toBeFalse()
        expect(r.get_args()).toEqual([])

      t5 = "/show/sources/#{source}/all"
      r54 = p4.match(t5)
      expect(r54.is_success()).toBeTrue()
      expect(r54.get_args()).toEqual([source])
      for p in [p1, p2, p3, p5]
        r = p.match(t5)
        expect(r.is_success()).toBeFalse()
        expect(r.get_args()).toEqual([])

      t6 = "/show/sources/test/"
      r62 = p2.match(t6)
      expect(r62.is_success()).toBeTrue()
      expect(r62.get_args()).toEqual(["test"])
      for p in [p1, p3, p4, p5]
        r = p.match(t6)
        expect(r.is_success()).toBeFalse()
        expect(r.get_args()).toEqual([])

  describe "convert from to hash routing", ->
    RS = Sirius.Internal.RouteSystem
    logger = new Sirius.Logger("test")
    it "convert", ->
      params = {
        "click input": () ->
        "/test/abc": () ->
        "#/test/new": () ->
      }
      setup = Sirius.Internal.RoutingSetup.build({
        old: false,
        support: true,
        ignore: true
      })
      result = RS._convert_to_hash_routing(setup, params, logger)

      expect(result["/test/abc"]).toBeDefined()
      expect(result["#/test/new"]).toBeDefined()
      expect(result["click input"]).toBeDefined()

      # convert
      setup = Sirius.Internal.RoutingSetup.build({
        old: true,
        support: false,
        ignore: true
      })
      result = RS._convert_to_hash_routing(setup, params, logger)
      expect(result["/test/abc"]).not.toBeDefined()
      expect(result["#/test/abc"]).toBeDefined()
      expect(result["#/test/new"]).toBeDefined()
      expect(result["click input"]).toBeDefined()

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
      routing_setup = Sirius.Internal.RoutingSetup.build
        old: true
        support: ps

      Sirius.Internal.RouteSystem.create(r, routing_setup)

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
      else if PrototypeAdapter?
        $("my-div").simulate("click")
      else
        jQuery("#my-div").trigger("click")

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

      beforeAll (done) ->
        arr = ["/", "/post/12", "/post/abc", "/post/x/a/b/c", "/static", "/error", "/"]
        if PrototypeAdapter?
          $(document.body).insert({bottom: "<div id='links'></div>"})
          for a in arr
            $("links").insert("<a href='#{a}'>#{a}</a>")

        else
          jQuery("body").append("<div id='links'></div>")
          for a in arr
            jQuery('#links').append($("<a></a>").attr({'href':a}).text(a))


        Controller =
          error: (current) -> errorValue = current
          title: (title) -> titleValue = title

        r =
          "/": () -> emptyValue = arguments.length
          "/post/[0-9]+" : (id) -> postValue = id
          "/post/:title" : {controller: Controller, action: "title"}
          "/post/x/*": () -> postXValue = arguments.length
          "/static" : () -> staticValue = arguments.length
          404: {controller: Controller, action: "error"}

        Sirius.Application.run({
          route: r,
          adapter: j,
          mix_logger_into_controller: false,
          controller_wrapper: {},
          ignore_not_matched_urls: false
        })

        links = j.all("#links a")
        if JQueryAdapter?
          for l in links
            jQuery(l).trigger("click")
        else if PrototypeAdapter?
          for l in links
            $(l).simulate("click")
        else
          for l in links
            l.click()

        done()

      it "test", (done) ->
        expect(emptyValue).toEqual(0)
        expect(postValue).toEqual("12")
        expect(titleValue).toEqual("abc")
        expect(errorValue).toEqual("/error")
        expect(postXValue).toEqual(3)
        expect(staticValue).toEqual(0)
        done()







