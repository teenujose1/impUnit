/**
 * Base for test cases
 * @package ImpUnit
 */
class ImpTestCase {

  assertions = 0;

  /**
   * Assert that something is true
   * @param {bool} condition
   * @param {string|false} message
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
   * @param {string|false} message
   */
   function assertEqual(expected, actual, message = "Expected value: %s, got: %s") {
    this.assertions++;
    if (expected != actual) {
      throw format(message, expected, actual);
    }
  }

  /**
   * Assert that two values are within a certain range
   * @param {bool} condition
   * @param {string|false} message
   */
  function assertClose(expected, actual, maxDiff, message = "Expected value: %s±%s, got: %s") {
    this.assertions++;
    if (math.abs(expected - actual) > maxDiff) {
      throw format(message, expected, maxDiff, actual);
    }
  }

  /**
   * Perform a deep comparison of two values
   * Useful for comparing arrays or tables
   * @param {*} a
   * @param {*} b
   */
  function assertDeepEqual(a, b, message = "At [%s]: expected \"%s\", got \"%s\"", path = "", level = 0) {

    local cleanPath = @(p) p.len() == 0 ? p : p.slice(1);

    if (level > 32) {
      throw "Possible cyclic reference at " + cleanPath(path);
    }

    switch (type(a)) {
      case "table":
      case "class":
      case "array":

        foreach (k, v in a) {

          path += "." + k;

          if (!(k in b)) {
            throw format("Missing slot [%s]", cleanPath(path));
          }

          this.assertDeepEqual(a[k], b[k], message, path, level + 1);
        }

        break;

      case "null":
        break;

      default:
        if (a != b) {
          throw format(message, cleanPath(path), a + "", b + "");
        }

        break;
    }
  }


}
