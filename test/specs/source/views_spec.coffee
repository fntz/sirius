describe "View", ->
  `var c = function(m){console.log(m);};`

  Sirius.Application.adapter = new JQueryAdapter()

  describe "Elements", ->
    describe "Input Text element", ->
      describe "for value", ->
        element = "#txt"
        view = new Sirius.View(element)

        beforeEach () ->
          $(element).val("default")

        it "#swap should change value", ->
          view.render("new value").swap()
          expect($(element).val()).toEqual("new value")

        it "#append should add text into value", ->
          view.render("new value").append()
          expect($(element).val()).toEqual("defaultnew value")

        it "#prepend should prepend text before original", ->
          view.render("new value").prepend()
          expect($(element).val()).toEqual("new valuedefault")

      describe "for attribute", ->
        pending "#swap change attribute with new content", ->
        pending "#append add content into attribute", ->
        pending "#prepend content before attribute", ->

    describe "Input Checkbox element", ->
      describe "for value", ->


      describe "for attribute", ->


    describe "Input Radio element", ->
      describe "for value", ->

      describe "for attribute", ->

    describe "Select element", ->
      describe "for value", ->

      describe "for attribute", ->

    describe "DIV element", ->
      describe "for value [inner text]", ->
        pending "#swap change content", ->
        pending "#append add new content in end", ->
        pending "#prepend add new content in start", ->


      describe "for attribute", ->


