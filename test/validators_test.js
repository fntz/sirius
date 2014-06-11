suite("Validators", function() {
  suite("#length", function() {
    test("#max", function() {
      var lv = new LengthValidator();
      assert(lv.validate("abc", {"max": 3}));
      assert(!lv.validate("abc", {"max": 1}));
    });
    test("#min", function() {
      var lv = new LengthValidator();
      assert(lv.validate("abc", {"min": 1}));
      assert(!lv.validate("abc", {"min": 10}));
    });
    test("#length", function() {
      var lv = new LengthValidator();
      assert(lv.validate("abc", {"length": 3}));
      assert(!lv.validate("abcd", {"length": 3}));
    });
  });

  suite("#exclusion", function() {
    test("should exclude from range", function() {
      var ev = new ExclusionValidator();
      assert(ev.validate("a", {within: ["b", "c", "d"]}));
      assert(!ev.validate("b", {within: ["b", "c", "d"]}));
    });
  });

  suite("#includsion", function() {
    test("should include in range", function() {
      var iv = new InclusionValidator();
      assert(iv.validate("b", {within: ["b", "c", "d"]}));
      assert(!iv.validate("a", {within: ["b", "c", "d"]}));
    });
  });

  suite("#format", function() {
    test("should match format", function() {
      var fv = new FormatValidator();
      assert(fv.validate("abc", {"with": /\w+/g}));
      assert(!fv.validate("abc", {"with": /\d+/g}));
    });
  });

  suite("#numericality", function() {
    test("have a numbers only", function() {
      var nv = new NumericalityValidator();
      assert(nv.validate("123.1", {}));
      assert(!nv.validate("dsa", {}));
      assert(nv.validate("123", {only_integers: true}));
      assert(!nv.validate("123.1", {only_integers: true}));
    });
  });

  suite("#presence", function() {
    test("should be presence", function() {
      var pv = new PresenceValidator();
      assert(pv.validate("abc"));
      assert(!pv.validate());
    });
  });
});