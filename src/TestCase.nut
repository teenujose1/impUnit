/**
 * Base for test cases
 * @package ImpUnit
 */
class ImpUnitCase {

  assertions = 0;

  /**
   * Assert that something is true
   * @param {bool} condition
   * @param {string|false} message
   */
  function assertTrue(condition, message = false) {
    this.assertions++;
    if (!condition) {
      throw message ? message : "Failed to assert that condition is true";
    }
  }

  /**
   * Assert that two values are equal
   * @param {bool} condition
   * @param {string|false} message
   */
   function assertEqual(expected, actual, message = false) {
    this.assertions++;
    if (expected != actual) {
      throw message ? message : "Expected value: " + expected + ", got: " + actual;
    }
  }

  /**
   * Assert that two values are within a certain range
   * @param {bool} condition
   * @param {string|false} message
   */
  function assertClose(expected, actual, maxDiff, message = false) {
    this.assertions++;
    if (math.abs(expected - actual) > maxDiff) {
      throw message ? message :
        "Expected value: " + expected + "±" + maxDiff + ", got: " + actual;
    }
  }

  /**
   * Setup test case
   * Can be async
   * @return {Promise|*}
   */
  function setUp() {}

  /**
   * Teardown test case
   * Can be async
   * @return {Promise|*}
   */
  function tearDown() {
  }

}
