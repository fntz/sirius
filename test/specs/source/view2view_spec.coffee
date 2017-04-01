describe "View2View", ->

  element = "#view2view_spec"


  it "input text to view input text", ->
    input2input = "#input2input"
    v1 = new Sirius.View("#{input2input}")
    v2 = new Sirius.View("#{input2input}")
    e1 = "input[name='input-1']"
    e2 = "input[name='input-1']"
    p = Sirius.Transformer.draw({
      "#{e1}": {
        to: "#{e2}"
      }
    })

    v1.bind(v2, p)

    t = "input2input"
    input_text("#{input2input} #{e1}", t)
    expect(get_value("#{input2input} #{e2}")).toEqual(t)


  describe "input text to view attribute", ->

  describe "attribute to view attribute", ->

  describe "attribute to view input text", ->

