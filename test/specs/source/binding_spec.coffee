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

    describe "text to attribute", ->
      pending "change value in input change attribute for related element"
      pending "change value in select change attribute for related element"
      pending "change value in div change attribute for related element"


  describe "Model to View", ->
    describe "model attribute to text", ->



    describe "model attribute to element attribute", ->


  describe "View to Model", ->

    describe "view text to model attribute", ->

    describe "view attribute to model attribute", ->


