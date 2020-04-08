
describe "Adapter", ->

  it "all", ->
    expect(adapter.all("#adapter .adapter-class").length).toEqual(2)
    expect(adapter.all("#adapter").length).toEqual(1)

  it "get", ->
    expect(adapter.get("#adapter")).not.toBeNull()
    expect(adapter.get("#adapter .adapter-class")).not.toBeNull()
    expect(adapter.get("#adapter123")).toBeNull()

  describe "get_attr/set_attr", ->
    it "in the data", ->
      expect(adapter.get_attr("#adapter .get-attr", "data-test")).toEqual("boom")
      adapter.set_attr("#adapter .get-attr", "data-test", "test")
      expect(adapter.get_attr("#adapter .get-attr", "data-test")).toEqual("test")

    it "in the class", ->
      expect(adapter.get_attr("#adapter .get-attr", "class")).toEqual("get-attr second-class-attr")
      adapter.set_attr("#adapter .get-attr", "class", "get-attr second-class-attr1")
      expect(adapter.get_attr("#adapter .get-attr", "class")).toEqual("get-attr second-class-attr1")

    it "in the input value", ->
      expect(adapter.get_attr("#adapter .input-attr", "value")).toEqual("test")
      adapter.set_attr("#adapter .input-attr", "value", "boom")
      expect(adapter.get_attr("#adapter .input-attr", "value")).toEqual("boom")

    it "in the checkbox", ->
      expect(adapter.get_attr("#adapter .checkbox1", "checked")).toEqual(true)
      adapter.set_attr("#adapter .checkbox1", "checked", false)
      expect(adapter.get_attr("#adapter .checkbox1", "checked")).toEqual(false)

      expect(adapter.get_attr("#adapter .checkbox2", "checked")).toEqual(false)
      adapter.set_attr("#adapter .checkbox2", "checked", true)
      expect(adapter.get_attr("#adapter .checkbox2", "checked")).toEqual(true)

  describe "get_attr", ->
    it "from checkbox", ->
      element = "#adapter input[name='adapter-attr']"
      expect(adapter.get_attr(element, "checked")).toBeFalse()
      check_element(element, true)
      expect(adapter.get_attr(element, "checked")).toBeTrue()
      check_element(element, false)
      expect(adapter.get_attr(element, "checked")).toBeFalse()


  describe "#text", ->
    it "from the input", ->
      expect(adapter.text("#adapter .input-attr-text")).toEqual("test")

    it "from the checkbox", ->
      expect(adapter.text("#adapter .checkbox1")).toEqual("test")

    it "from the select", ->
      expect(adapter.text("#adapter .select1")).toEqual("1")
      expect(adapter.text("#adapter .select2")).toEqual("10")

    it "from the span", ->
      expect(adapter.text("#adapter .another-adapter-class")).toEqual("boom")


