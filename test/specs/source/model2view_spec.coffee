describe "Model2View", ->
  Sirius.Application.adapter = if JQueryAdapter?
    new JQueryAdapter()
  else if PrototypeAdapter?
    new PrototypeAdapter()
  else
    new VanillaJsAdapter()

  adapter = Sirius.Application.adapter

  get_text = (element) ->
    adapter.text(element)

  describe "attribute 2 text", ->


    element = "div.model2view div.attribute2text"
    id_element = ".model-id"
    title_element = ".model-title"
    desc_element = ".model-description"


    view = new Sirius.View(element)
    model = new MyModel()


    model.bind(view, {
      '.model-id' : {from: "id"}
      '.model-title': {from: "title"}
      '.model-description': {from: "description"}
    })


    id = "1234567"
    title = "new title"
    description = "lorem ipsum dolore"

    beforeAll (done) ->
      model.id(id)
      model.title(title)
      model.description(description)

      setTimeout(
        () ->
          done()
        100
      )


    it "should have inner text as model attributes", ->
      expect(get_text(id_element)).toEqual(id)
      expect(get_text(title_element)).toEqual(title)
      expect(get_text(desc_element)).toEqual(description)


  describe "attribute to attribute", ->
    element = "div.model2view div.attribute2attribute"
    id_element = "#{element} .model-id"
    title_element = "#{element} .model-title"
    desc_element = "#{element} .model-description"

    view = new Sirius.View(element)
    model = new MyModel()

    model.bind(view, {
      '.model-id' : {from: "id", to: "data-name"}
      '.model-title': {from: "title", to: "data-name"}
      '.model-description': {from: "description", to: "data-name"}
    })

    id = "1234567"
    title = "new title"
    descrption = "lorem ipsum dolore"

    beforeAll () ->
      model.id(id)
      model.title(title)
      model.description(descrption)


    it "should have attributes as model attributes", ->
      e_id = adapter.get_attr(id_element, 'data-name')
      e_t = adapter.get_attr(title_element, 'data-name')
      e_d = adapter.get_attr(desc_element, 'data-name')

      expect(e_id).toEqual(id)
      expect(e_t).toEqual(title)
      expect(e_d).toEqual(descrption)

  describe "attribute to form", ->
    element = "div.model2view div.attribute2form"
    title_element = "#{element} input"
    desc_element = "#{element} textarea"

    view = new Sirius.View(element)
    model = new MyModel()

    model.bind(view, {
      "input[type='text']": {from: "title"}
      "textarea" : {from: "description"}
    })

    title = "new title"
    descrption = "lorem ipsum dolore"

    beforeAll () ->
      model.title(title)
      model.description(descrption)


    it "should have values as model attributes", ->
      t = adapter.get(title_element).value
      d = adapter.get(desc_element).value

      expect(t).toEqual(title)
      expect(d).toEqual(descrption)

  describe "attribute to form for logical attributes", ->
    element = "div.model2view div.forms"

    model = new MyModel()
    model0 = new MyModel0()

    simpleForm = new Sirius.View("#{element} form.simple")
    selectForm = new Sirius.View("#{element} form.select")
    checkForm = new Sirius.View("#{element} form.check")
    radioForm = new Sirius.View("#{element} form.radio")

    model.bind(simpleForm, {
      ".title-attr" : {from: "title", to: "data-name"}
      ".title-text" : {from: "title"}
      "input[type='text']": {from: "title"}
    })

    model.bind(selectForm, {
      'select': {from: "title"}
    })

    model0.bind(checkForm, {
      'input[type="checkbox"]': {from: "title", to: "checked"}
    })

    model0.bind(radioForm, {
      'input[type="radio"]': {from: "title", to: "checked"}
    })

    expected = "title2"
    title = {"title2" : true}

    beforeAll () ->
      model0.title(title)
      model.title(expected)


    it "should have correct attributes",  ->
      expect(adapter.all("#{element} form.check input:checked")[0].value).toEqual(expected)
      expect(adapter.all("#{element} form.radio input:checked")[0].value).toEqual(expected)
      select = adapter.all("#{element} form.select select")[0]
      sIndex = select.options.selectedIndex
      expect(select[sIndex].value).toEqual(expected)
      expect(adapter.text("#{element} form.simple span.title-text")).toEqual(expected)
