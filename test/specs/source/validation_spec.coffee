describe "Validators", ->

  describe "#length", ->
    lv = new Sirius.LengthValidator()

    it "#max", ->
      expect(lv.validate("abc", {max: 3})).toBeTruthy()
      expect(lv.validate("abc", {max: 1})).toBeFalsy()

    it "#min", ->
      expect(lv.validate("abc", {"min": 1})).toBeTruthy()
      expect(lv.validate("abc", {"min": 10})).toBeFalsy()

    it "#length", ->
      expect(lv.validate("abc", {"length": 3})).toBeTruthy()
      expect(lv.validate("abcd", {"length": 3})).toBeFalsy()

  describe "#exclusion", ->
    ev = new Sirius.ExclusionValidator()

    it "should exclude from range", ->
      expect(ev.validate("a", {within: ["b", "c", "d"]})).toBeTruthy()
      expect(ev.validate("b", {within: ["b", "c", "d"]})).toBeFalsy()

  describe "#inclusion", ->
    iv = new Sirius.InclusionValidator()

    it "should include in range", ->
      expect(iv.validate("b", {within: ["b", "c", "d"]})).toBeTruthy()
      expect(iv.validate("a", {within: ["b", "c", "d"]})).toBeFalsy()

  describe "#format", ->
    fv = new Sirius.FormatValidator()

    it "should match format", ->
      expect(fv.validate("abc", {"with": /\w+/g})).toBeTruthy()
      expect(fv.validate("abc", {"with": /\d+/g})).toBeFalsy()

  describe "#numericality", ->
    nv = new Sirius.NumericalityValidator()

    it "have a number only", ->
      expect(nv.validate("123.1", {})).toBeTruthy()
      expect(nv.validate("dsa", {})).toBeFalsy()
      expect(nv.validate("123", {only_integers: true})).toBeTruthy()
      expect(nv.validate("123.1", {only_integers: true})).toBeFalsy()

  describe "#presence", ->
    pv = new Sirius.PresenceValidator()

    it "should be present", ->
      expect(pv.validate("abc")).toBeTruthy()
      expect(pv.validate()).toBeFalsy()
