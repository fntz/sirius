describe "View2View", ->

  adapter = if JQueryAdapter?
    new JQueryAdapter()
  else
    new PrototypeAdapter()

  Sirius.Application.adapter = adapter


  element = ".attribute2text .element"
  related_div = ".attribute2text .related-div"
  related_input = ".attribute2text .related-input"
  related_select = ".attribute2text .related-select"

  view = new Sirius.View(element)
  view_div = new Sirius.View(related_div)
  view_input = new Sirius.View(related_input)
  view_select = new Sirius.View(related_select)

  describe "attribute to text", ->
    view.bind(view_div, {from: 'data-name'})
    view.bind(view_input, {from: 'data-name', to: 'text'})
    view.bind(view_select, {from: 'data-name'})

    txt = 'val3'

    beforeAll (done) ->
      adapter.get(element).setAttribute('data-name', txt)

      setTimeout(
        () ->
          done()
        100
      )

    it "change attribute in element should change text in related elements", ()->
      expect(adapter.text(related_div)).toEqual(txt)
      expect(adapter.text(related_input)).toEqual(txt)
      expect(adapter.text(related_select)).toEqual(txt)

  describe "attribute to attribute", ->

    view.bind(view_div, {from: 'data-attr', to: 'data-name'})
    view.bind(view_input, {from: 'data-attr', to: 'data-name'})
    view.bind(view_select, {from: 'data-attr', to: 'data-name'})
    txt = 'another-value'

    beforeAll (done) ->
      adapter.get(element).setAttribute('data-attr', txt)

      setTimeout(
        () ->
          done()
        100
      )

    it "change attribute in element should change attribute in related element", () ->
      expect(adapter.get_attr(related_div, 'data-name')).toEqual(txt)
      expect(adapter.get_attr(related_input, 'data-name')).toEqual(txt)
      expect(adapter.get_attr(related_select, 'data-name')).toEqual(txt)


  describe "/text to attribute/", ->
    # from text to data-name attribute
    div = ".text2attribute .div"
    for_div = ".text2attribute .for-div"

    #FIXME add an input element
    divView = new Sirius.View(div)
    forDiv = new Sirius.View(for_div)

    divView.bind(forDiv, {to: 'data-name'})

    value = "val3"

    beforeAll (done) ->
      if JQueryAdapter?
        jQuery(div).html(value)
      else
        $$(div)[0].update(value)

      setTimeout(
        () ->
          done()
        100
      )

    it "change value in input|select|div change attribute for related element", () ->
      expect(adapter.get_attr(for_div, 'data-name')).toEqual(value)

