// #include "dist/impUnit.nut"

class SampleTestCase extends ImpTestCase {
  function testSomethingSync() {
    this.assertTrue(true);
  }

  function testSomethingAsync() {
    return Promise(function (ok, err) {
      ok("Hi there");
    });
  }
}

t <- ImpUnitRunner();
t.run();
