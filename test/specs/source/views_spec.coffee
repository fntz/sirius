describe "View", ->
  `var c = function(m){console.log(m);};`

  Sirius.Application.adapter = new JQueryAdapter()

  describe "Elements", ->
    describe "Input Text element", ->
      element = "#txt"
      view = new Sirius.View(element)

      describe "for value", ->
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
        beforeEach () ->
          $(element).removeClass().addClass("input-class")
          $(element).removeData('name').data('name', 'input')

        it "#swap change attribute with new content", ->
          view.render("new-class").swap('class')
          expect($(element).attr('class')).toEqual("new-class")

        it "#append add content into attribute", ->
          view.render("new-class").append('class', 'data-name')
          expect($(element).attr('class')).toEqual("input-classnew-class")
          expect($(element).data('name')).toEqual("inputnew-class")

        it "#prepend content before attribute", ->
          view.render("new-class").prepend('class', 'data-name')
          expect($(element).attr('class')).toEqual("new-classinput-class")
          expect($(element).data('name')).toEqual("new-classinput")

    describe "Select element", ->
      element = "#views-select"
      view = new Sirius.View(element)

      describe "for value", ->

        it "should swap option in select element", ->
          view.render("val3").swap()
          expect($(element).val()).toEqual("val3")

    describe "DIV element", ->
      element = "#content"
      view = new Sirius.View(element)
      describe "for value [inner text]", ->
        beforeEach () ->
          $(element).text("default")

        it "#swap change content", ->
          view.render("new content").swap('text')
          expect($(element).text()).toEqual("new content")

        it "#append add new content in end", ->
          view.render("new content").append()
          expect($(element).text()).toEqual("defaultnew content")

        it "#prepend add new content in start", ->
          view.render("new content").prepend()
          expect($(element).text()).toEqual("new contentdefault")


