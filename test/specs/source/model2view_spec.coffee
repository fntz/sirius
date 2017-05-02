describe "Model2View", ->
  element = "#model2view_spec"

  model = new MyTestModel2ViewSpecModel()
  view = new Sirius.View(element)

  it "model to input val", ->
    e = "input[name='model-name']"
    pipe = Sirius.Transformer.draw({
      "name": {
        "to": e
      }
    })
    model.pipe(view, pipe)
    model.name("foo")
    expect(get_value("#{element} #{e}")).toEqual("foo")

  it "model to div text", ->
    e = ".model2view_spec-text"
    pipe = Sirius.Transformer.draw({
      "name": {
        "to": e
      }
    })
    model.pipe(view, pipe)
    model.name("bar")
    expect(get_text("#{element} #{e}")).toEqual("bar")

  it "model to html attribute", ->
    e = ".model2view_spec-data-name"
    pipe = Sirius.Transformer.draw({
      "name": {
        "to": e,
        "attr": "data-name"
      }
    })
    model.pipe(view, pipe)
    model.name("baz")
    expect(adapter.get_attr("#{element} #{e}", "data-name")).toEqual("baz")






