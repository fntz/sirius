describe "BaseModel", ->
  it "Work with attributes", ->
    model = new MyModel()

    expect(model.get('id')).toBeNull()
    expect(model.id()).toBeNull()
    expect(model.get('title')).toEqual("default title")
    expect(model.title()).toEqual("default title")
    expect(model.get('description')).toBeNull()
    expect(model.description()).toBeNull()

    model.set('id', 10)
    expect(model.id()).toEqual(10)

    model.id(100)
    expect(model.get('id')).toEqual(100)

    model = new MyModel({id: 1, title: "new title", description: "description"})
    expect(model.id()).toEqual(1)
    expect(model.title()).toEqual("new title")
    expect(model.description()).toEqual("description")

  it "Validation", ->

  describe "Convertable", ->

    beforeEach ->
#      if !load
#        $.ajax "fixtures/model-form.html",
#          success: (html)->
#            $("body").append(html)
#            load = true


    it "to_json", ->
      model = new MyModel()
      model.id(10)
      model.description("text")

      json = model.to_json()
      expected = JSON.stringify({"id": 10, "title": "default title", "description": "text"})

      expect(json).toEqual(expected)

      json = model.to_json(true)
      expected = JSON.stringify({"my_model" : JSON.parse(expected)})

      expect(json).toEqual(expected)

    it "from_json", ->
      json = JSON.stringify({"id": 10, "description": "text"})
      model = MyModel.from_json(json)

      expect(model.id()).toEqual(10)
      expect(model.title()).toEqual("default title")
      expect(model.description()).toEqual("text")

    pending "from_html", ->
      Sirius.Application.adapter = new JQueryAdapter()

      model = MyModel.from_html("#my-model-form")
      console.log(model)
      expect(model.id()).toEqual(1)
      expect(model.title()).toEqual("new title")
      expect(model.description()).toEqual("text...")

  describe "Relations", ->

    it "has_*", ->


    describe "JSON", ->

      it "to_json", ->

      it "from_json", ->

  it "guid", ->
    a = new UModel()
    b = new UModel()
    expect(a.id()).not.toBeNull()
    expect(a.id()).not.toEqual(b.id())
