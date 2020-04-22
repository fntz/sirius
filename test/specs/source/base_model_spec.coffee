describe "BaseModel", ->

  it "#attributes", ->
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

  it "returns attributes", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["id", "foo"]
      @comp("bar", "id", "foo")

    t = new Test1()
    expect(t.attrs()).toEqual(["id", "foo", "bar"])

  it "return normalized name", ->
    class FooBarModel extends Sirius.BaseModel

    class Test1 extends Sirius.BaseModel

    expect(new FooBarModel().normal_name()).toEqual("foo_bar_model")
    expect(new Test1().normal_name()).toEqual("test1")

  it "returns __name/__klass_name properties", ->
    class FooBarModel extends Sirius.BaseModel

    t = new FooBarModel()
    expect(t.__name).toBe("BaseModel")
    expect(t._klass_name()).toBe("FooBarModel")

  it "generate guids", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["id"]
      @guid_for: "id"

    expect(new Test1().id()).not.toBeNull()

    class Test2 extends Sirius.BaseModel
      @attrs: ["id"]
      @guid_for: ["id"]

    expect(new Test2().id()).not.toBeNull()

    class Test3 extends Sirius.BaseModel
      @attrs: ["id"]
      @guid_for: 1

    expect( () ->
      t = new Test3()
    ).toThrowError("'@guid_for' must be array of string, but #{typeof(1)} given")

  it "normalize attributes", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["id", {"foo": 1}, {"bar": 10}, "test"]

    expect(new Test1().normalize_attrs()).toEqual(["id", "foo", "bar", "test"])
    expect(new Test1().get_attributes()).toEqual(["id", "foo", "bar", "test"])

  it "checks attribute is present", ->
    class Test1 extends Sirius.BaseModel
      @attrs: [{"id": "test"}]

    expect(() -> new Test1()._attribute_present("id")).not.toThrowError()
    expect(() -> new Test1()._attribute_present("unknown")).toThrowError()

  it "checks constructor", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["id", {}]

    expect(() -> new Test1())
      .toThrowError("@attrs must be defined as: '@attrs:['id', {'k':'v'}]'")

    class Test2 extends Sirius.BaseModel
      @attrs: ["id", "id"]

    expect(() -> new Test2())
      .toThrowError("Method 'id' already exist")

  it "set default property", ->
    class Test1 extends Sirius.BaseModel
      @attrs: [{"id": 10}, "title"]

    t = new Test1()
    expect(t.id()).toEqual(10)
    expect(t.title()).toBeNull()
    expect(t._id).toEqual(10)
    expect(t._title).toBeNull()

  it "calls callbacks when pass properties with constructor", ->
    after_update = []
    class Test1 extends Sirius.BaseModel
      @attrs: [{"id": 10}, "title"]

      after_update: (attr, new_value, old_value) ->
        after_update.push(attr, new_value, old_value)


    t = new Test1({"id": 100})
    expect(t.id()).toEqual(100)
    expect(after_update).toEqual(["id", 100, 10])

  it "generates properties and methods from attributes", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["id"]

    t = new Test1()
    expect(Object.keys(t)).toContain("_id")
    t.id(10)
    expect(t.id()).toEqual(10)
    t.id(null)
    expect(t.id()).toEqual(10)

  it "checks skip properties", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["id"]

    class Test2 extends Sirius.BaseModel
      @attrs: ["id"]
      @skip: true

    obj = {'id': 1, 'foo': "bar"}

    expect(() -> new Test1({})).not.toThrowError()
    expect(() -> new Test1(obj)).toThrowError()
    expect(() -> new Test2({})).not.toThrowError()
    expect(() -> new Test2(obj)).not.toThrowError()

  it "calls callback after creation", ->
    flag = false
    class Test1 extends Sirius.BaseModel
      after_create: () ->
        flag = true

    new Test1()
    expect(flag).toBeTrue()


  describe "#set, #get", ->
    after_update = []
    class Test1 extends Sirius.BaseModel
      @attrs: ["id", {"title": "default"}, "foo"]
      @comp("bar", "id", "foo")

      after_update: (a, n, o) ->
        after_update.push(a, n, o)

    beforeEach () ->
      after_update = []

    it "fails with computed fields", ->
      expect(() ->
        new Test1().set("bar", "asd")
      ).toThrowError("Impossible set computed attribute 'bar' in 'Test1'")

    it "fails when attribute does not exist", ->
      expect(() ->
        new Test1().set("unknown", "asd")
      ).toThrowError()

      expect( () ->
        new Test1().get("unknown")
      ).toThrowError()

    it "calls callbacks", ->
      t = new Test1({id: 1})
      expect(t.id()).toEqual(1)
      t.set('id', 10)
      expect(t.id()).toEqual(10)
      expect(t.id()).toEqual(t.get('id'))
      expect(after_update).toEqual(["id", 1, null, "id", 10, 1])

  describe "get_binding", ->
    it "returns binding for attributes, and for validators", ->
      class Test1 extends Sirius.BaseModel
        @attrs: ["id", "foo"]
        @validate:
          id:
            presence: true
            inclusion: within: [1..10]
          foo:
            format: with: /^[A-Z].+/
      b = new Test1().get_binding()
      expect(b.id).toEqual("id")
      expect(b.foo).toEqual("foo")
      expect(b.errors.id.presence).toEqual("errors.id.presence")
      expect(b.errors.id.inclusion).toEqual("errors.id.inclusion")
      expect(b.errors.foo.format).toEqual("errors.foo.format")
      expect(b.errors.foo.all).toEqual("errors.foo.all")
      expect(b.errors.id.all).toEqual("errors.id.all")
      expect(b.errors.all).toEqual("errors.all")
      expect(Object.keys(b)).toEqual(["id", "foo", "errors"])
      expect(Object.keys(b.errors)).toEqual(["id", "foo", "all"])
      expect(Object.keys(b.errors.foo)).toEqual(["format", "all"])
      console.log(b)


  describe "reset", ->

    class Test1 extends Sirius.BaseModel
      @attrs: ["id", "foo"]
      @validate:
        id:
          presence: true

    it "fails when attribute is not exist", ->
      expect( () ->
        t = new Test1()
        t.reset("boom")
      ).toThrowError("Attribute 'boom' not found for Test1 model")

    it "string to empty string", ->
      t = new Test1({"id": "asd"})
      t.reset('id')
      expect(t.id()).toBeNull()

    it "number to zero", ->
      t = new Test1({"id": 1})
      t.reset('id')
      expect(t.id()).toBeNull()

    it "array to empty array", ->
      t = new Test1({"id": ["asd"]})
      t.reset('id')
      expect(t.id()).toBeNull()

    it "reset only necessary attrs", ->
      t = new Test1({"id": 1, foo: "bar"})
      t.reset('id')
      expect(t.id()).toBeNull()
      expect(t.foo()).toEqual("bar")

    it "reset all attributes", ->
      t = new Test1({id: 1, foo: "bar"})
      t.reset()
      expect(t.id()).toBeNull()
      expect(t.foo()).toBeNull()

    it "reset errors also", ->
      t = new Test1({"id": ["asd"]})
      t.set_error("id.presence", "boom")
      expect(t.get_errors("id")).not.toEqual([])
      t.reset('id')
      expect(t.id()).toBeNull()
      expect(t.get_errors("id")).toEqual([])

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


  describe "Validators", ->
    m = null
    beforeEach () ->
      m = new ModelwithValidators()

    it "failed when validate_with defined with not a function", ->
      class Test1 extends Sirius.BaseModel
        @attrs: ["id"]
        @validate:
          id:
            validate_with: 123

      expect(() -> new Test1()).toThrowError(
        "Validator for attribute: 'id.validate_with' should be a function, number given"
      )

    it "returns validators", ->
      expect(new MyModel().validators()).toEqual({})
      expect(Object.keys(new ModelwithValidators().validators())).toEqual(["id", "title", "description"])

    it "checks is_valid_validator", ->
      a = new ModelwithValidators()
      expect(a._is_valid_validator("id.presence")).toBeTrue()
      expect(a._is_valid_validator("id.numericality")).toBeTrue()
      expect(a._is_valid_validator("id.inclusion")).toBeTrue()
      expect(a._is_valid_validator("id.validate_with")).toBeTrue()
      expect(a._is_valid_validator("id.format")).toBeFalse()

      expect(a._is_valid_validator("title.presence")).toBeTrue()
      expect(a._is_valid_validator("title.format")).toBeTrue()
      expect(a._is_valid_validator("title.length")).toBeTrue()
      expect(a._is_valid_validator("title.exclusion")).toBeTrue()
      expect(a._is_valid_validator("title.inclusion")).toBeFalse()

      expect(a._is_valid_validator("description.custom")).toBeTrue()
      expect(a._is_valid_validator("description.validate_with")).toBeTrue()
      expect(a._is_valid_validator("description.exclusion")).toBeFalse()

    describe "validate id", ->
      it "failed on numeric and range", ->
        m.id("asd")
        expect(m.get_errors('id')).not.toEqual([])
        expect(m.get_errors('title')).toEqual([])
        expect(m.get_errors('description')).toEqual([])
        expect(m.is_valid()).toBeFalse()
        expect(m.is_valid('context')).toBeTrue()

      it "failed only integers and range", ->
        m.id("123.1")
        expect(m.get_errors('id').length).toEqual(2)
        expect(m.is_valid()).toBeFalse()
        expect(m.is_valid('context')).toBeTrue()

      it "failed in range", ->
        m.id(12)
        expect(m.get_errors('id').length).toEqual(1)
        expect(m.is_valid()).toBeFalse()
        expect(m.is_valid('context')).toBeTrue()

    describe "validate title", ->
      it "failed format", ->
        m.title("asd")
        expect(m.get_errors('title').length).toEqual(1)
        expect(m.is_valid()).toBeFalse()

      it "failed length #min", ->
        m.title("Fo")
        expect(m.get_errors('title').length).toEqual(1)
        expect(m.is_valid()).toBeFalse()

      it "failed length #max", ->
        m.title("FooBarBaz")
        expect(m.get_errors('title').length).toEqual(1)
        expect(m.is_valid()).toBeFalse()

      it "failed inclusion", ->
        m.title("Title")
        expect(m.get_errors('title').length).toEqual(1)
        expect(m.is_valid()).toBeFalse()

    describe "validate description", ->
      it "validate with length", ->
        m.description("1234")
        expect(m.get_errors('description').length).toEqual(2)
        m.description("foo")
        expect(m.get_errors('description')).toEqual([])
        expect(m.is_valid()).toBeFalse()

    it "success flow", ->
      m.description("foo")
      m.title("Test")
      m.id(3)
      expect(m.is_valid()).toBeTrue()

    it "set_errors/get_errors", ->
      m.description("1")
      expect(m.get_errors('description')).toEqual(['Value length must be 3', 'Description must be foo'])
      m.set_error("description.custom", "foo")
      expect(m.get_errors('description')).toEqual(['foo', 'Description must be foo'])
      m.set_error("description.validate_with", "bar")
      expect(m.get_errors('description')).toEqual(['foo', 'bar'])
      expect(() -> m.set_error("description.asd", "asd")).toThrowError("Unexpected key: 'asd' for 'description' attribute")
      expect(() -> m.set_error("description.asd.123", "qwe")).toThrowError()
      expect(() -> m.set_error("description", "asd")).toThrowError()
      expect(() -> m.get_errors("asd")).toThrowError()

    describe "when success", ->
      beforeEach () ->
        m.validate()

      it "should reset errors when set correct value", ->
        m.id(9)
        m.validate()
        expect(m.get_errors('title').length + m.get_errors('description').length).toEqual(5)

    it "unexpected validators", ->
      class TestValidator extends Sirius.Validator
        validate: (value, attrs) ->
          true
      expect(() ->
        class Test1 extends Sirius.BaseModel
          @attrs: ["id"]
          @validate:
            id:
              custom_test_validator: true

        new Test1()
      ).toThrowError("Unregistered validator: 'custom_test_validator'")


  describe "SkipFields", ->
    it "work without errors when json contain another fields", ->
      obj = {"id": 1, "another_field": "foobar"}

      expect(() -> new SkipFieldsModel(obj)).not.toThrow()
      expect(() -> new MyModel(obj)).toThrow()


  describe "Computed field", ->
    it "define and use compute field as normal fields", ->
      class Test1 extends Sirius.BaseModel
        @attrs: ["first_name", "last_name"]
        @comp("full_name", "first_name", "last_name")
        @comp("full_name1", "first_name", "last_name", (f, l) -> "#{f}-#{l}")
        @comp("full", "full_name", "full_name1")
        @validate :
          full_name:
            length: min: 3, max: 8

      model = new Test1()
      expect(model.full_name()).toBeNull()
      expect(() -> model.full_name("foo")).toThrow()
      model.first_name("John")
      model.last_name("Doe")
      expect(model.full_name()).toEqual("John Doe")
      expect(model.full_name1()).toEqual("John-Doe")
      expect(model.full()).toEqual("John Doe John-Doe")
      model.first_name("1")
      expect(model.get_errors('full_name').length).toEqual(1)
      expect(model.full_name()).toEqual("John Doe")

    it "checks computed attributes", ->
      class Test1 extends Sirius.BaseModel
        @attrs: ["first_name", "last_name"]
        @comp("full_name", "first_name", "last_name")

      t = new Test1()

      expect(t._is_computed_attribute("first_name")).toBeFalse()
      expect(t._is_computed_attribute("full_name")).toBeTrue()
      expect(t._is_computed_attribute("unknown")).toBeFalse()


    it "generate exception with `comp` method", ->
      expect(() ->
        class Test1 extends Sirius.BaseModel
          @attrs: ["id"]
          @comp()
      ).toThrowError("Computed fields are empty")

      expect(() ->
        class Test2 extends Sirius.BaseModel
          @attrs: ["id"]
          @comp("test", "id")
      ).toThrowError("Define compute field like: '@comp(\"default_computed_field\", \"first_name\", \"last_name\")'")

      expect(() ->
        class Test3 extends Sirius.BaseModel
          @attrs: ["id"]
          @comp("test", "id", "id")
      ).toThrowError("Seems your calculated fields are not unique: [test,id,id]")

      expect(() ->
        class Test4 extends Sirius.BaseModel
          @attrs: ["id"]
          @comp("test", "foo", "id")
      ).toThrowError("Field 'foo' was not found, for 'test'")

  # uncomment in future
  #    expect(() ->
  #      class Test5 extends Sirius.BaseModel
  #        @attrs: ["id", "name"]
  #        @comp("id_name", "id", "name")
  #        @comp("comp_field", "name", "id_name")
  #    ).toThrowError("Cyclic references were detected in 'comp_field' field")










