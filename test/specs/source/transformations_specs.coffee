
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
    class Test1 extends Sirius.BaseModel
      @attrs: ["name"]
      @validate:
        name:
          length: min: 3, max: 7

    it "push attribute changes from model to function", ->
      tmp = []
      new_name = "new"
      f = (attr, value) ->
        tmp.push(attr, value)

      model = new Test1()
      model.pipe(f)

      model.name(new_name)
      expect(model.name()).toEqual(new_name)

      new_name1 = "boo"
      model.set("name", new_name1)
      expect(model.get('name')).toEqual(new_name1)
      expect(tmp.indexOf("name")).not.toEqual(-1)
      expect(tmp.indexOf(new_name)).not.toEqual(-1)
      expect(tmp.indexOf(new_name1)).not.toEqual(-1)

    it "calls on invalid validation too", ->
      tmp = []
      f = (attr, value) ->
        tmp.push(attr, value)

      model = new Test1()
      model.pipe(f)
      model.name("1")
      expect(model.is_valid()).toBeFalse()
      expect(tmp).toEqual(["errors.name.length", "Required length in range [0..7], given: 1", 'name', "1"])

  describe "model to view", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["foo", "is_checked"]
      @validate:
        foo:
          length: min: 3, max: 10

    rootElement = "#model2view"
    view = new Sirius.View(rootElement)

    it "pass from property to input", () ->
      model = new Test1()
      output = "input[name='output-foo']"
      model.bind(view, {
        "foo": {
          "to": output
        }
      })
      model.foo("abcd")

      get_text("#{rootElement} #{output}")


    it "pass from property to data-attribute", () ->
      model = new Test1()
      output = "input[name='output-foo']"
      model.bind(view, {
        "foo": {
          "to": output,
          "attr": "data-output"
        }
      })
      model.foo("booom!")

      expect(adapter.get_attr("#{rootElement} #{output}", "data-output")).toEqual(model.foo())

    it "pass from property to span", () ->
      more = "+test"
      model = new Test1()
      output = "span.output-foo"
      model.bind(view, {
        "foo": {
          "to": output,
          "with": (value, selector, view, attribute = 'text') ->
            view.zoom(selector).render("#{value}#{more}").swap(attribute)
        }
      })
      model.foo("span!")

      expect(get_text("#{rootElement} #{output}")).toEqual("#{model.foo()}#{more}")

    it "pass from validation to span", ->
      model = new Test1()
      output = "span.output-validation-foo"
      model.bind(view, {
        "errors.foo.length": {
          "to": output
        }
      })
      model.foo("Z")

      expect(get_text("#{rootElement} #{output}")).toMatch(/Required length/)

      # and reset validation
      model.foo("abcd")
      expect(get_text("#{rootElement} #{output}")).toBe("")

  describe "view to model", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["foo", "is_checked"]
      @validate:
        foo:
          length: min: 3, max: 10

    rootElement = "#view2model"
    view = new Sirius.View(rootElement)

    it "from text to model (+validation)", ->
      model = new Test1({foo: "abcd"})
      view.bind(model, {
        "input[name='source']": {
          to: "foo",
          with: (value) -> "#{value}!"
        }
      })
      input = "q"
      input_text("#{rootElement} input[name='source']", input)
      expect(model.foo()).toEqual("#{input}!")
      expect(model.is_valid()).toBeFalse()

    it "from checkbox to bool attribute", ->
      model = new Test1()
      view.bind(model, {
        "input[name='bool-source']": {
          to: "is_checked"
          from: "checked"
        }
      })
      check_element("#{rootElement} input[name='bool-source']", true)
      expect(model.is_checked()).toBeTrue()
      check_element("#{rootElement} input[name='bool-source']", false)
      expect(model.is_checked()).toBeFalse()



  describe "view to view", ->
    rootElement = "#view2view"
    view = new Sirius.View(rootElement)

    it "from source to mirror", ->
      more = "+bar"
      sourceElement = "input[name='source']"
      source = view.zoom(sourceElement)
      mirror = view.zoom(".mirror")
      source.bind(mirror, {
        to: [
          {
          "selector": ".mirror1"
          },
          "selector": ".mirror-attr1",
          "attribute": "data-mirror",
          "with" : (value, selector, view, attribute = 'text') ->
            view.zoom(selector).render("#{value}#{more}").swap(attribute)
        ]
      })

      text = "foo"
      input_text("#{rootElement} #{sourceElement}", text)
      expect(get_text("#{rootElement} .mirror1")).toEqual(text)
      expect(adapter.get_attr("#{rootElement} .mirror-attr1", 'data-mirror')).toEqual("#{text}#{more}")


  describe "view to function", ->
    rootElement = "#view2function"
    inputElement = "input[name='email']"
    inputCheckbox = "input[type='checkbox']"

    view = new Sirius.View(rootElement)


    it "push changes from view", (done) ->
      expected = "baz"
      given = null
      func = (result, view, logger) ->
        given = result['text']


      materializer = Sirius.Transformer.draw({
        "#{inputElement}": {
          from: 'text'
        }
      })
      view.pipe(func, materializer)

      input_text("#{rootElement} #{inputElement}", expected)
      setTimeout(
        () ->
          expect(given).toEqual(expected)
          done()
        1000
      )

    it "push changes from checkbox view", (done) ->
      given = null
      func = (result, view, logger) ->
        given = result['state']

      materializer = Sirius.Transformer.draw({
        "#{inputCheckbox}": {
          from: 'text'
        }
      })
      view.pipe(func, materializer)

      check_element("#{rootElement} #{inputCheckbox}", true)
      setTimeout(
        () ->
          expect(given).toEqual(true)
          done()
        1000
      )

    it "push changes from view#attribute", (done) ->
      expected = "new-bind-class"
      given = []
      func = (result, view, logger) ->
        given.push(result['attribute'], result['text'])

      materializer = Sirius.Transformer.draw({
        "#{inputElement}": {
          from: 'class'
        }
      })
      view.pipe(func, materializer)

      adapter.set_attr("#{rootElement} #{inputElement}", "class", expected)

      setTimeout(
        () ->
          expect(given).toEqual(["class", expected])
          done()
        1000
      )
