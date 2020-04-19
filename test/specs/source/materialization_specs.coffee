describe "Materialization",  ->
  class Test1 extends Sirius.BaseModel
    @attrs: ['id']
    @validate :
      id:
        presence: true

  describe "Materializer", ->
    it "illegal arguments", ->
      expect(() ->
        Materializer.build(1, 2)
      ).toThrowError(/Illegal arguments/)
      expect(() ->
        Materializer.build(new Test1(), 1)
      ).toThrowError(/Illegal arguments/)
      expect(() ->
        Materializer.build(new Sirius.View("asd"), "asd")
      ).toThrowError(/Illegal arguments/)

    it "check model attributes", ->
      m = new Test1()
      expect(() ->
        Materializer._check_model_compliance(m, "id")
      ).not.toThrowError()
      expect(() ->
        Materializer._check_model_compliance(m, "foo")
      ).toThrowError(/Attribute 'foo' not found in model/)
      expect(() ->
        Materializer._check_model_compliance(m, "errors.id.presence")
      ).not.toThrowError()
      expect(() ->
        Materializer._check_model_compliance(m, "errors.id.numericality")
      ).toThrowError(/Unexpected 'errors.id.numericality' errors attribute/)
      expect(() ->
        Materializer._check_model_compliance(m, "foo.bar")
      ).toThrowError(/Try to bind 'foo.bar' from errors properties/)

  describe "BaseModel to View", ->
    materializer = null
    beforeEach () ->
      materializer = Materializer.build(new Test1(), new Sirius.View("#test"))

    describe "field", ->
      it "unwrap function", ->
        materializer.field((b) -> b.id).to("test")
        expect(materializer.current.field()).toEqual("id")
        materializer.field((b) -> b.errors.id.presence).to("test")
        expect(materializer.current.field()).toEqual("errors.id.presence")

      it "when attribute are not exist", ->
        expect(() ->
          materializer.field("foo")
        ).toThrowError("Attribute 'foo' not found in model attributes: 'Test1', available: '[id]'")

    describe "to", ->
      it "unwrap function", ->
        expect(() ->
          materializer.field('id').to((v) -> v.zoom("asd"))
        ).not.toThrowError()

      it "check types", ->
        expect(() ->
          materializer.field('id').to(1)
        ).toThrowError("'to' must be string or function, or instance of Sirius.View")

      it "'to' without 'field'", ->
        expect(() ->
          materializer.to("test")
        ).toThrowError("Incorrect call. Call 'to' after 'field'")

      it "double-to", ->
        expect(() ->
          materializer.field("id").to("test").to("test1")
        ).toThrowError("Incorrect call. 'id' already has 'to'")

    describe "attribute", ->
      it "without 'field'", ->
        expect(() ->
          materializer.attribute("class")
        ).toThrowError("Incorrect call. Define 'field' firstly, and then call 'attribute' after 'to'")

      it "without 'to'", ->
        expect(() ->
          materializer.field("id").attribute("class")
        ).toThrowError("Incorrect call. Call 'to' before 'attribute'")

      it "double-attribute", ->
        expect(() ->
          materializer.field("id").to("test").attribute("class").attribute("class")
        ).toThrowError("Incorrect call. 'id' already has 'attribute'")

    describe "transform", ->
      it "'with' are not a function", ->
        expect(() ->
          materializer.field("id")
            .to("test").transform(1)
        ).toThrowError("'transform' attribute must be function, #{typeof 1} given")

      it "'transform' without field", ->
        expect(() ->
          materializer.transform(() ->)
        ).toThrowError("Incorrect call. Call 'transform' after 'to' or 'attribute'")

      it "without 'to'", ->
        expect( () ->
          materializer.field("id").transform(() ->)
        ).toThrowError("Incorrect call. Call 'to' before 'transform'")

      it "double-transform", ->
        expect(() ->
          materializer.field("id")
            .to("test").transform(() ->).transform(() ->)
        ).toThrowError("Incorrect call. The field already has 'transform' function")

    describe "handle", ->
      it "without field", ->
        expect(() ->
          materializer.handle(() -> )
        ).toThrowError("Incorrect call. 'field' is not defined")

      it "without to", ->
        expect(() ->
          materializer.field((x) -> x.id)
          .handle(() -> )
        ).toThrowError("Incorrect call. define 'to'")

      it "when not a function", ->
        expect(() ->
          materializer.field('id')
          .to('input').handle(1)
        ).toThrowError("'handle' must be a function")

      it "double-handle", ->
        expect(() ->
          materializer.field('id').to('input').handle(() -> ).handle(() -> )
        ).toThrowError("'handle' already defined")


  describe "View To Model", ->

    materializer = null
    beforeEach () ->
      materializer = Materializer.build(new Sirius.View("#test"), new Test1())

    describe "field", ->
      it "unwrap function", ->
        expect(() ->
          materializer.field((v) -> v.zoom("view")).to((b) -> b.id)
        ).not.toThrowError()

      it "'field' must be string or view", ->
        expect(() ->
          materializer.field(1)
        ).toThrowError("Element must be string or function, or instance of Sirius.View")

        expect(() ->
          materializer.field("test")
        ).not.toThrowError()

        expect(() ->
          materializer.field(new Sirius.View("test"))
        ).not.toThrowError()

    describe "to", ->
      it "unwrap function", ->
        materializer.field("test").to((b) -> b.id)
        expect(materializer.current.to()).toEqual("id")

      it "call before 'field'", ->
        expect(() ->
          materializer.to("id")
        ).toThrowError("Incorrect call. Define 'field' firstly, and then call 'from'")

      it "double-to", ->
        expect(() ->
          materializer.field("test").to("id").to("id")
        ).toThrowError("Incorrect call. '#test test' already has 'to'")

    describe "from", ->
      it "without context", ->
        expect(() ->
          materializer.from("test")
        ).toThrowError("Incorrect call. Define 'field' firstly, and then call 'from'")

      it "before to", ->
        expect(() ->
          materializer.field("test").to("id").from("test")
        ).toThrowError("Incorrect call. Call 'from' before 'to'")

      it "double-from", ->
        expect(() ->
          materializer.field("test").from("id").from("id")
        ).toThrowError("Incorrect call. '#test test' already has 'from'")

    describe "transform", ->
      it "'transform' are not function", ->
        expect(() ->
          materializer.field("input")
            .to("id").transform(1)
        ).toThrowError("'transform' attribute must be function, #{typeof 1} given")

      it "'transform' without field", ->
        expect(() ->
          materializer.transform(() ->)
        ).toThrowError("Incorrect call. Call 'transform' after 'to' or 'attribute'")

      it "without 'to'", ->
        expect( () ->
          materializer.field("input").transform(() ->)
        ).toThrowError("Incorrect call. Call 'to' before 'transform'")

      it "double-transform", ->
        expect(() ->
          materializer.field("input")
            .to("id").transform(() ->).transform(() ->)
        ).toThrowError("Incorrect call. The field already has 'transform' function")

  describe "View To View", ->

    describe "to", ->
      materializer = null

      beforeEach () ->
        materializer = Materializer.build(new Sirius.View("#test"), new Sirius.View("#test1"))

      it "unwrap function", ->
        expect(() ->
          materializer.field("asd").to((v) -> v.zoom("das"))
        ).not.toThrowError()

      it "should be string or Sirius.View", ->
        expect(() ->
          materializer.field("test")
          .to(1)
        ).toThrowError("Element must be string or function, or instance of Sirius.View")

        expect(() ->
          materializer.field("test").to("asd")
        ).not.toThrowError()

    describe "handle", ->
      materializer = null

      beforeEach () ->
        materializer = Materializer.build(new Sirius.View("#test"), new Sirius.View("#test1"))

      it "without field", ->
        expect(() ->
          materializer.handle(() ->)
        ).toThrowError("Incorrect call. 'field' is not defined")

      it "without to", ->
        expect(() ->
          materializer.field("input")
          .handle(() -> )
        ).toThrowError("Incorrect call. define 'to'")

      it "when is not a function", ->
        expect(() ->
          materializer.field("input")
          .to("div").handle(1)
        ).toThrowError("'handle' must be a function")

      it "double handle", ->
        expect(() ->
          materializer.field("input")
          .to("div")
          .handle(() -> )
          .handle(() -> )
        ).toThrowError("'handle' already defined")


  describe "View To Function", ->

    describe "to", ->
      it "function is required", ->
        materializer = Materializer.build(new Sirius.View("test"))
        expect(() ->
          materializer.field("test").to(1)
        ).toThrowError("Function is required")

        expect(() ->
          materializer.field("test").to(() ->)
        ).not.toThrowError()

  describe "Model To Function", ->
    describe "to", ->
      materializer = null

      beforeEach () ->
        materializer = Materializer.build(new Test1())

      it "unwrap function", ->
        materializer.field((b) -> b.id)
        expect(materializer.current.field()).toEqual("id")

      it "without context", ->
        expect(() ->
          materializer.to(() ->)
        ).toThrowError("Incorrect call. Define 'field' firstly")

      it "double-to", ->
        expect(() ->
          materializer.field("id").to(() -> ).to(() -> )
        ).toThrowError("Incorrect call. The field already has 'to'")

      it "function is required", ->
        expect(() ->
          materializer.field("id").to(1)
        ).toThrowError("Function is required")

        expect(() ->
          materializer.field("id").to(() ->)
        ).not.toThrowError()

