describe "Binding", ->
  `var c = function(m){console.log(m);};`
  Sirius.Application.adapter = new JQueryAdapter()
  describe "View to View", ->
    element = ".attribute2text .element"
    related_div = ".attribute2text .related-div"
    related_input = ".attribute2text .related-input"
    related_select = ".attribute2text .related-select"

    view = new Sirius.View(element)
    view_div = new Sirius.View(related_div)
    view_input = new Sirius.View(related_input)
    view_select = new Sirius.View(related_select)

    describe "/attribute to text/", ->

      view.bind(view_div, {from: 'data-name'})
      view.bind(view_input, {from: 'data-name', to: 'text'})
      view.bind(view_select, {from: 'data-name'})
      txt = 'val3'

      beforeEach (done) ->
        $(element).attr('data-name', txt)

        setTimeout(
          () ->
            done()
          1000
        )

      it "change attribute in element should change text in related elements", (done)->
        expect($(related_div).text()).toEqual(txt)
        expect($(related_input).val()).toEqual(txt)
        expect($(related_select).val()).toEqual(txt)
        done()

    describe "/attribute to attribute/", ->

      view.bind(view_div, {from: 'data-attr', to: 'data-name'})
      view.bind(view_input, {from: 'data-attr', to: 'data-name'})
      view.bind(view_select, {from: 'data-attr', to: 'data-name'})
      txt = 'another-value'

      beforeEach (done) ->
        $(element).attr('data-attr', txt)

        setTimeout(
          () ->
            done()
          1000
        )

      it "change attribute in element should change attribute in related element", (done) ->
        expect($(related_div).data('name')).toEqual(txt)
        expect($(related_input).data('name')).toEqual(txt)
        expect($(related_select).data('name')).toEqual(txt)
        done()

    describe "/text to attribute/", ->
      # from text to data-name attribute
      div = ".text2attribute .div"
      input = ".text2attribute .input"
      select = ".text2attribute .select"
      for_div = ".text2attribute .for-div"
      for_input = ".text2attribute .for-input"
      for_select = ".text2attribute .for-select"

      divView = new Sirius.View(div)
      forDiv = new Sirius.View(for_div)
      inputView = new Sirius.View(for_input)
      forInput = new Sirius.View(for_input)
      selectView = new Sirius.View(select)
      forSelect = new Sirius.View(for_select)

      divView.bind(forDiv, {to: 'data-name'})
      inputView.bind(forInput, {to: 'data-name'})
      selectView.bind(forSelect, {to: 'data-name'})

      value = "val3"

      beforeEach (done) ->
        for a in value
          $(input).sendkeys(a)
        $(div).text(value)

        setTimeout(
          () ->
            done()
          1000
        )

      it "change value in input|select|div change attribute for related element", (done) ->
        expect($(for_div).data('name')).toEqual(value)
        expect($(for_input).data('name')).toEqual(value)
        #expect($(for_select).data('name')).toEqual(value)
        done()


  describe "View to Model", ->
    # form to model
    # text div to model
    describe "view /text to model/ attribute", ->
      form = ".view2model form.my-form"
      formView = new Sirius.View(form)
      model = new MyModel()

      formView.bind(model)

      description = "new description content"
      title       = "title for model"

      beforeEach (done) ->
        for a in title
          $("#{form} input[type='text']").sendkeys(a)
        for a in description
          $("#{form} textarea").sendkeys(a)

        setTimeout(
          () ->
            done()
          1000
        )

      it "change text in form should change model attributes", (done) ->
        expect(model.title()).toEqual(title)
        expect(model.description()).toEqual(description)
        done()

    describe "view attribute to model attribute", ->



  describe "Model to View", ->
    describe "model attribute to text", ->


    describe "model attribute to element attribute", ->
