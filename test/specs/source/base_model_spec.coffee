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

  describe "Convert", ->

    it "to_json", ->
      model = new MyModel()
      model.id(10)
      model.description("text")

      json = model.to_json()
      expected = JSON.stringify({"id": 10, "title": "default title", "description": "text"})

      expect(json).toEqual(expected)

      json = model.to_json("title")
      expected = JSON.stringify({"id" : 10, "description" : "text"})
      expect(json).toEqual(expected)

    it "from_json", ->
      json = JSON.stringify({"id": 10, "description": "text"})
      model = MyModel.from_json(json)

      expect(model.id()).toEqual(10)
      expect(model.title()).toEqual("default title")
      expect(model.description()).toEqual("text")


  it "guid", ->
    a = new UModel()
    b = new UModel()
    expect(a.id()).not.toBeNull()
    expect(a.id()).not.toEqual(b.id())

  describe "Validators", ->
    m = null
    beforeEach () ->
      m = new ModelwithValidators()

    describe "validate id", ->

      it "failed on numeric and range", ->
        m.id("asd")
        expect(m.get_errors('id').length).toEqual(2)

      it "failed only integers and range", ->
        m.id("123.1")
        expect(m.get_errors('id').length).toEqual(2)

      it "failed in range", ->
        m.id(12)
        expect(m.get_errors('id').length).toEqual(1)


    describe "validate title", ->
      it "failed format", ->
        m.title("asd")
        expect(m.get_errors('title').length).toEqual(1)

      it "failed length #min", ->
        m.title("Fo")
        expect(m.get_errors('title').length).toEqual(1)

      it "failed length #max", ->
        m.title("FooBarBaz")
        expect(m.get_errors('title').length).toEqual(1)

      it "failed inclusion", ->
        m.title("Title")
        expect(m.get_errors('title').length).toEqual(1)

    describe "validate description", ->
      it "validate with length", ->
        m.description("1234")
        expect(m.get_errors('description').length).toEqual(2)

    describe "#validate", ->
      it "should contain errors when fields not set", ->
        m.validate()
        expect(m.get_errors('description').length).toEqual(2)

    describe "when success", ->

      beforeEach () ->
        m.validate()

      it "should reset errors when set correct value", ->
        m.id(9)
        expect(m.get_errors('title').length + m.get_errors('description').length).toEqual(5)


  describe "SkipFields", ->
    it "work without errors when json contain another fields", ->
      obj = {"id": 1, "another_field": "foobar"}

      expect(() -> new SkipFieldsModel(obj)).not.toThrow()
      expect(() -> new MyModel(obj)).toThrow()



  describe "Computed field", ->
    it "define and use compute field as normal fields", ->
      model = new ComputedFieldModel()
      expect(model.full_name()).toBeNull()
      expect(() -> model.full_name("foo")).toThrow()
      model.first_name("John")
      model.last_name("Doe")
      expect(model.full_name()).toEqual("John Doe")
      expect(model.full_name1()).toEqual("John-Doe")
      expect(model.full()).toEqual("John Doe John-Doe")
      expect(model.get_errors('full_name').length).toEqual(1)









