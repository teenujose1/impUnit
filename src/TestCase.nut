/**
 * Base for test cases
 * @package ImpUnit
 */
class ImpTestCase {

  runner = null; // runner instance
  session = null; // session name
  assertions = 0;

  /**
   * Send message to impTest to execute external command
   * @param {string} command
   */
  function runCommand(command = "") {
    this.runner.log(
        ImpUnitMessage(ImpUnitMessageTypes.externalCommand, {
          "command": command
        })
    );
  }

  /**
   * Assert that something is true
   * @param {bool} condition
   * @param {string} message
   */
  function assertTrue(condition, message = "Failed to assert that condition is true") {
    this.assertions++;
    if (!condition) {
      throw message;
    }
  }

  /**
   * Assert that two values are equal
   * @param {bool} condition
   * @param {string} message
   */
   function assertEqual(expected, actual, message = "Expected value: %s, got: %s") {
    this.assertions++;
    if (expected != actual) {
      throw format(message, expected + "", actual + "");
    }
  }

  /**
   * Assert that value is greater than something
   * @param {number|*} actual
   * @param {number|*} cmp
   * @param {string} message
   */
   function assertGreater(actual, cmp, message = "Failed to assert that %s > %s") {
    this.assertions++;
    if (actual <= cmp) {
      throw format(message, actual + "", cmp + "");
    }
  }

  /**
   * Assert that value is less than something
   * @param {number|*} actual
   * @param {number|*} cmp
   * @param {string} message
   */
   function assertLess(actual, cmp, message = "Failed to assert that %s < %s") {
    this.assertions++;
    if (actual >= cmp) {
      throw format(message, actual + "", cmp + "");
    }
  }

  /**
   * Assert that two values are within a certain range
   * @param {bool} condition
   * @param {string} message
   */
  function assertClose(expected, actual, maxDiff, message = "Expected value: %s±%s, got: %s") {
    this.assertions++;
    if (math.abs(expected - actual) > maxDiff) {
      throw format(message, expected + "", maxDiff + "", actual + "");
    }
  }

  /**
   * Perform a deep comparison of two values
   * Useful for comparing arrays or tables
   * @param {*} expected
   * @param {*} actual
   * @param {string} message
   */
  function assertDeepEqual(expected, actual, message = "At [%s]: expected \"%s\", got \"%s\"", path = "", level = 0) {

    if (0 == level) {
      this.assertions++;
    }

    local cleanPath = @(p) p.len() == 0 ? p : p.slice(1);

    if (level > 32) {
      throw "Possible cyclic reference at " + cleanPath(path);
    }

    switch (type(actual)) {
      case "table":
      case "class":
      case "array":

        foreach (k, v in expected) {

          path += "." + k;

          if (!(k in actual)) {
            throw format("Missing slot [%s] in actual value", cleanPath(path));
          }

          this.assertDeepEqual(expected[k], actual[k], message, path, level + 1);
        }

        break;

      case "null":
        break;

      default:
        if (expected != actual) {
          throw format(message, cleanPath(path), expected + "", actual + "");
        }

        break;
    }
  }

  /**
   * Assert that the value is between min amd max
   * @param {number|*} actual
   * @param {number|*} min
   * @param {number|*} max
   */
  function assertBetween(actual, min, max, message = "Expected value the range of %s..%s, got %s") {
    this.assertions++;

    // swap min/max if min > max
    if (min > max) {
      local t = max;
      max = min;
      min = t;
    }

    if (actual < min || actual > max) {
      throw format(message, min + "", max + "", actual + "");
    }
  }

  /**
   * Assert that function throws an erorr
   * @param {function} fn
   * @param {table|userdata|class|instance|meta} ctx
   * @param {array} args - arguments for the function
   * @param {string} message
   * @return {error} error thrown by function
   */
  function assertThrowsError(fn, ctx, args = [], message = "Function was expected to throw an error") {
    this.assertions++;
    args.insert(0, ctx)

    try {
      fn.pacall(args);
    } catch (e) {
      return e;
    }

    throw message;
  }
}
