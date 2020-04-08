describe "View", ->

  describe "#zoom", ->
    it "should zoom inner elements", ->
      view = new Sirius.View("#zoom-test")
      view.render("new-text").zoom(".zoom-class").swap("text")
      expect(get_text("#zoom-test .zoom-class")).toEqual("new-text")

    describe "Custom transformation", ->
      element = "#view-custom-transform"
      view = new Sirius.View(element, (txt) -> "text: #{txt}")

      describe "for inner text", ->
        beforeEach () ->
          set_text(element, "default")

        it "#swap", ->
          view.render("content").swap()
          expect(get_text(element)).toEqual("text: content")

        it "#append", ->
          view.render("content").append()
          expect(get_text(element)).toEqual("defaulttext: content")

        it "#prepend", ->
          view.render("content").prepend()
          expect(get_text(element)).toEqual("text: contentdefault")

    # fixme: for prototype/vanilla
    if JQueryAdapter?
      describe "Event", ->
        element = "#view-events"
        view = new Sirius.View(element)
        pp1 = null
        pp2 = null

        beforeAll (done) ->
          SA = Sirius.Application
          SA.run
            route :
              "event:click": (e1, e2, p1, p2) ->
                pp1 = p1
                pp2 = p2
            adapter: adapter

          p1 = 1
          p2 = "abc"

          view.on(element, "click", "event:click", p1, p2)
          setTimeout(
            () ->
              if JQueryAdapter?
                jQuery(element).trigger("click")
              else if PrototypeAdapter?
                $(element).simulate("click")
              else
                adapter.get(element).click()
              done()
            400
          )

        it "should fire custom event and pass params", ->
          expect(pp1).toEqual(1)
          expect(pp2).toEqual("abc")

    describe "strategies", ->

      describe "#append", ->
        view = new Sirius.View("#append-view")
        it "fails on input/select/textarea", ->
          expect(() -> view.render("test").zoom("input").append("text")).toThrowError(
            "'append' strategy does not work for `input` or `textarea` or `select` elements"
          )
          expect(() -> view.render("test").zoom("select").append("text")).toThrowError(
            "'append' strategy does not work for `input` or `textarea` or `select` elements"
          )
          expect(() -> view.render("test").zoom("textarea").append("text")).toThrowError(
            "'append' strategy does not work for `input` or `textarea` or `select` elements"
          )

        it "fails for not-text attributes", ->
          expect(() -> view.render("test").zoom("span").append("class")).toThrowError(
            "Strategy 'append' works only for 'text' content, your call with attribute:'class'"
          )

        it "update text", ->
          view.render("test").zoom("span").append("text")
          expect(get_text("#append-view span")).toEqual("123test")

      describe "#prepend", ->
        view = new Sirius.View("#prepend-view")
        it "fails on input/select/textarea", ->
          expect(() -> view.render("test").zoom("input").prepend("text")).toThrowError(
            "'prepend' strategy does not work for `input` or `textarea` or `select` elements"
          )
          expect(() -> view.render("test").zoom("select").prepend("text")).toThrowError(
            "'prepend' strategy does not work for `input` or `textarea` or `select` elements"
          )
          expect(() -> view.render("test").zoom("textarea").prepend("text")).toThrowError(
            "'prepend' strategy does not work for `input` or `textarea` or `select` elements"
          )

        it "fails for not-text attributes", ->
          expect(() -> view.render("test").zoom("span").prepend("class")).toThrowError(
            "Strategy 'prepend' works only for 'text' content, your call with attribute:'class'"
          )

        it "update text", ->
          view.render("test").zoom("span").prepend("text")
          expect(get_text("#prepend-view span")).toEqual("test123")

      describe "#swap", ->
        view = new Sirius.View("#swap-view")
        it "swap text", ->
          view.render("test").zoom(".swap-text").swap()
          expect(get_text("#swap-view .swap-text")).toEqual("test")

        it "swap property", ->
          view.render("test").zoom(".swap-data").swap('data-name')
          expect(get_attr("#swap-view .swap-data", 'data-name')).toEqual("test")

        it "swap checkbox", ->
          view.render(false).zoom(".swap-checkbox").swap('checked')
          expect(get_attr("#swap-view .swap-checkbox", 'checked')).toBeFalse()
          view.render(true).zoom(".swap-checkbox").swap('checked')
          expect(get_attr("#swap-view .swap-checkbox", 'checked')).toBeTrue()

      describe "#clear", ->
        view = new Sirius.View("#clear-view")

        it "clear text", ->
          view.zoom("span").clear()
          expect(get_text("#clear-view span")).toEqual("")

      describe "#register_strategy", ->
        it "fails when transform is missing", ->
          expect(() ->
            Sirius.View.register_strategy('test',
              render: (adapter, element, result, attribute) ->
                ""
            )
          ).toThrowError("Strategy 'transform' must be a function, but #{typeof (undefined)} given")

        it "fails when render is missing", ->
          expect(() ->
            Sirius.View.register_strategy('test',
              transform: (oldvalue, newvalue) -> ""
            )
          ).toThrowError("Strategy 'render' must be a function, but #{typeof (undefined)} given")

        it "fails when name is not valid", ->
          expect(() ->
            Sirius.View.register_strategy(123,
              transform: (oldvalue, newvalue) -> ""
              render: (adapter, element, result, attribute) ->
                ""
            )
          ).toThrowError("Strategy 'name' must be a string, but #{typeof (123)} given")
