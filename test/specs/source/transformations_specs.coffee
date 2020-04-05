
describe "Transformations", ->

  describe "common errors", ->
    it "fails for non-View/Model in #from position", ->
      expect(() ->
        new Sirius.Transformer(1, () -> )
      ).toThrowError("Bad argument: Model or View required, 'number' given")

    it "fails for non-V/M/F in #to position", ->
      expect(() ->
        new Sirius.Transformer(new Sirius.BaseModel(), 1)
      ).toThrowError("Bind works only with BaseModel, BaseView or Function, 'number' given")

    it "fails for bind m2m", ->
      class Test1 extends Sirius.BaseModel
        @attrs: ['id']
      class Test2 extends Sirius.BaseModel
        @attrs: ['id']

      expect(() ->
        new Sirius.Transformer(new Test1(), new Test2())
      ).toThrowError("No way to bind two Models: 'Test1' and 'Test2'")

  describe "#compliance", ->
    view = new Sirius.View("#transformations-view")

    class Test1 extends Sirius.BaseModel
      @attrs: ["id"]
      @validate:
        id:
          presence: true

    it "fails when materializer is not an object", ->
       expect(() ->
         new Sirius.Transformer(view, new Test1()).run(1)
       ).toThrowError("Materializer must be object, '#{typeof 1}' given")

    it "fails when materizlier is empty object", ->
      expect(() ->
        new Sirius.Transformer(view, new Test1()).run({})
      ).toThrowError("Materializer must be non empty object")

    describe "from model", ->
      it "fails when materializer does not contain attribute", ->
        expect(() ->
          new Sirius.Transformer(new Test1(), () -> ).run({
            "name": {
              "to": "input"
            }
          })
        ).toThrowError("Attribute 'name' not found in model attributes: 'Test1', available: '[id]'")

      it "fails with invalid error binding", ->
        expect(() ->
          new Sirius.Transformer(new Test1(), () ->).run({
            "errors.id.numericality": {
              "to": "input"
            }
          })
        ).toThrowError("Unexpected 'errors.id.numericality' errors attribute for 'Test1' (check validators)")

      it "success for validation", ->
        expect(() ->
          new Sirius.Transformer(new Test1(), () ->).run({
            "errors.id.presence": {
              "to": "input"
            }
          })
        ).not.toThrowError()

    describe "#to model", ->
      it "fails when materializer.to is not defined", ->
        expect(() -> new Sirius.Transformer(view, new Test1()).run({foo: "bar"}))
          .toThrowError("Failed to create transformer for 'Test1', because '#{JSON.stringify({foo: "bar"})}', does not contain 'to'-property")

      it "fails, with unexpected properties", ->
        expect(() ->
          new Sirius.Transformer(view, new Test1()).run({
            "input": {
              to: "name"
            }
          })
        ).toThrowError(
          "Unexpected 'name' for model binding. Model is: 'Test1', available attributes: '[id]'"
        )

    describe "view to view", ->
      it "to is required", ->
        expect(() ->
          new Sirius.Transformer(view, view).run({
            "foo": "bar"
          })
        ).toThrowError(/Define View to View binding with/)

      it "to must be array or string", ->
        expect(() ->
          new Sirius.Transformer(view, view).run({
            "to": 1
          })
        ).toThrowError("View to View binding must contains 'to' as an array or a string, but number given")

      it "to must contains selector propery", ->
        expect(() ->
          new Sirius.Transformer(view, view).run({
            "to": [
              {
                "foo": "#my-id"
              }
            ]
          })
        ).toThrowError(/You defined binding with/)


    describe "view to function", ->
      it "from property must be required", ->
        expect(() ->
          new Sirius.Transformer(view, () ->).run({
            "input": {
              "foo": "bar"
            }
          })
        ).toThrowError(/View to Function binding must contain/)

  describe "model to function", ->

  describe "model to view", ->

  describe "view to model", ->

  describe "view to view", ->

  describe "view to function", ->

