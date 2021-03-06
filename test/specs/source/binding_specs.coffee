describe "Binding", ->
  describe "Model To Function", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["id", "name"]
      @validate:
        id:
          numericality: only_integers: true
        name:
          exclusion: within: ["test"]

    it "produce changes", ->
      model = new Test1()
      results = []
      all_errors = []
      id_errors = []
      materializer = Sirius.Materializer.build(model)
      materializer
        .field((x) -> x.errors.all)
          .to((err) -> all_errors.push(err))
        .field((x) -> x.errors.id.all)
          .to((err) -> id_errors.push(err) )
        .field((x) -> x.id)
          .to((id) -> results.push(id))
        .field((x) -> x.name)
          .to((name) -> results.push(name))
        .field((x) -> x.errors.id.numericality)
          .to((error) -> results.push(error))
        .run()

      expect(results.length).toEqual(0)

      model.name("test")
      expect(results).toEqual([])
      expect(all_errors).toEqual(["Value test reserved"])
      expect(id_errors).toEqual([])
      model.id("asd")
      expect(all_errors).toEqual(["Value test reserved", "Only allows integer numbers"])
      expect(id_errors).toEqual(["Only allows integer numbers"])
      expect(results).toEqual(["Only allows integer numbers"])
      model.id(123)
      # '' - reset validation
      expect(results).toEqual(["Only allows integer numbers", "", 123])
      expect(id_errors).toEqual(["Only allows integer numbers", ""])
      expect(all_errors).toEqual(["Value test reserved", "Only allows integer numbers", ""])
      results = []
      materializer.stop()
      model.id(1234)
      expect(results).toEqual([])
      expect(model.id()).toEqual(1234)


  describe "View To Function", ->
    rootElement = "#view2function"
    inputElement = "input[name='email']"
    inputCheckbox = "input[type='checkbox']"

    view = new Sirius.View(rootElement)

    it "push changes from view", (done) ->
      expected = "baz"
      given = null

      materializer = Sirius.Materializer.build(view)
      materializer
      .field(inputElement)
        .to((result) ->
          given = result.text;
      )
      .run()

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

      materializer = Sirius.Materializer.build(view)
      materializer
        .field(inputCheckbox)
        .to((result) -> given = result.state)
        .run()

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

      materializer = Sirius.Materializer.build(view)
      materializer
        .field(inputElement)
        .from('class')
        .to((result) ->
          given.push(result['attribute'], result['text'])
      ).run()

      adapter.set_attr("#{rootElement} #{inputElement}", "class", expected)

      setTimeout(
        () ->
          expect(given).toEqual(["class", expected])
          done()
        1000
      )

  describe "View To View", ->
    rootElement = "#view2view"
    view = new Sirius.View(rootElement)

    it "from source to mirror", ->
      sourceElement = "input[name='source']"
      source = view.zoom(sourceElement)
      mirror = view.zoom(".mirror")
      materializer = Sirius.Materializer.build(view, view)
      materializer
        .field(source)
        .to(mirror)
        .handle((v, result) ->
           v.zoom(".mirror1").render(result.text).swap()
           v.zoom(".mirror-attr1").render(result.text).swap('data-mirror')
        ).run()

      text = "foo"
      input_text("#{rootElement} #{sourceElement}", text)
      expect(get_text("#{rootElement} .mirror1")).toEqual(text)
      expect(adapter.get_attr("#{rootElement} .mirror-attr1", 'data-mirror')).toEqual(text)

      materializer.stop()
      new_text = "bar"
      input_text("#{rootElement} #{sourceElement}", new_text)
      expect(adapter.get_attr("#{rootElement} .mirror-attr1", 'data-mirror')).toEqual(text)


  describe "View To Model", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["foo", "is_checked"]
      @validate:
        foo:
          length: min: 3, max: 10

    rootElement = "#view2model"
    view = new Sirius.View(rootElement)

    it "from text to model (+validation)", () ->
      model = new Test1({foo: "abcd"})

      materializer = Sirius.Materializer.build(view, model)
        .field("input[name='source']")
        .to((b) -> b.foo)
        .transform((x) -> "#{x.text}!")

      materializer.run()

      input = "q4444"
      input_text("#{rootElement} input[name='source']", input)
      expect(model.foo()).toEqual("#{input}!")
      expect(model.is_valid()).toBeTrue()

      materializer.stop()

      new_input = "asdasdsad"
      expect(1).toEqual(1)
      input_text("#{rootElement} input[name='source']", new_input)
      expect(model.foo()).toEqual("#{input}!")


    it "from checkbox to bool attribute", ->
      model = new Test1()
      materializer = Sirius.Materializer.build(view, model)
      materializer
        .field("input[name='bool-source']")
        .to((b) -> b.is_checked)
        .transform((x) -> x.state)
        .run()

      check_element("#{rootElement} input[name='bool-source']", true)
      expect(model.is_checked()).toBeTrue()
      check_element("#{rootElement} input[name='bool-source']", false)
      expect(model.is_checked()).toBeFalse()

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
      Sirius.Materializer.build(model, view)
        .field((x) -> x.foo)
        .to(output)
        .run()

      model.foo("abcd")

      expect(get_text("#{rootElement} #{output}")).toEqual("abcd")

    it "pass from property to data-attribute", () ->
      model = new Test1()
      output = "input[name='output-foo']"
      Sirius.Materializer.build(model, view)
        .field((x) -> x.foo)
        .to(output)
        .attribute('data-output')
        .run()

      model.foo("booom!")

      expect(adapter.get_attr("#{rootElement} #{output}", "data-output")).toEqual(model.foo())

    it "pass from property to span", () ->
      more = "+test"
      model = new Test1()
      output = "span.output-foo"
      Sirius.Materializer.build(model, view)
        .field((x) -> x.foo)
        .to(output)
        .transform((r) -> "#{r}#{more}")
        .handle((view, result) ->
          view.render(result).swap()
      ).run()

      model.foo("span!")

      expect(get_text("#{rootElement} #{output}")).toEqual("#{model.foo()}#{more}")

    it "pass from validation to span", ->
      model = new Test1()
      output = "span.output-validation-foo"
      Sirius.Materializer.build(model, view)
        .field((x) -> x.errors.foo.length)
        .to(output)
        .run()

      model.foo("Z")

      expect(get_text("#{rootElement} #{output}")).toMatch(/Required length/)

      # and reset validation
      model.foo("abcd")
      expect(get_text("#{rootElement} #{output}")).toBe("")