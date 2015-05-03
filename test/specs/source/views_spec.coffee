describe "View", ->

  adapter = if JQueryAdapter?
    new JQueryAdapter()
  else if PrototypeAdapter?
    new PrototypeAdapter()
  else
    new VanillaJsAdapter()

  Sirius.Application.adapter = adapter

  get_text = (element) ->
    adapter.text(element)

  set_text = (element, text) ->
    if JQueryAdapter?
      jQuery(element).text(text)
    else
      e = adapter.get(element)
      if e.textContent
        e.textContent = text
      else
        e.innerHTML = text
    return

  describe "Elements", ->
    describe "Input Text element", ->
      element = "#txt"
      view = new Sirius.View(element)

      describe "for value", ->
        beforeEach () ->
          adapter.clear(element)
          adapter.swap(element, "default")

        it "#swap should change value", ->
          view.render("new value").swap()
          expect(adapter.text(element)).toEqual("new value")

      describe "for attribute", ->
        beforeEach () ->
          if JQueryAdapter?
            jQuery(element).removeClass().addClass("input-class")
            jQuery(element).removeData().data('name', 'input')

        it "#swap change attribute with new content", ->
          view.render("new-class").swap('class')
          expect(adapter.get(element).getAttribute('class')).toEqual("new-class")

    describe "Select element", ->
      element = "#views-select"
      view = new Sirius.View(element)

      describe "for value", ->

        it "should swap option in select element", ->
          view.render("val3").swap()
          elem = adapter.get(element).value
          expect(elem).toEqual("val3")

    describe "DIV element", ->
      element = "#content"
      view = new Sirius.View(element)
      describe "for value [inner text]", ->
        beforeEach () ->
          set_text(element, "default")

        it "#swap change content", ->
          view.render("new content").swap('text')
          expect(get_text(element)).toEqual("new content")

        it "#append add new content in end", ->
          view.render("new content").append()
          expect(get_text(element)).toEqual("defaultnew content")

        it "#prepend add new content in start", ->
          view.render("new content").prepend()
          expect(get_text(element)).toEqual("new contentdefault")


    describe "With Custom Transform method", ->
      element = "#content"
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

    if JQueryAdapter?
      #FIXME for prototype and for vanillajs
      describe "Event", ->
        element = "#content"
        view = new Sirius.View(element)
        pp1 = null
        pp2 = null

        beforeAll (done) ->
          adapter = if JQueryAdapter?
            new JQueryAdapter()
          else if PrototypeAdapter?
            new PrototypeAdapter()
          else
            new VanillaJsAdapter()

          Sirius.Application.run
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