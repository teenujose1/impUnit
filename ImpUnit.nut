// Suggests JSON 0.3.2 + Promise 1.1.0 libs available

/**
 * impUnit
 * In-dev version, major changes can occur!
 *
 * @version 0.0.1-dev
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 */

// extend Promise for our needs
// don't do this, children
class Promise extends Promise {
  timedOut = false;
  timerId = null;
}

/**
 * Base for test cases
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

// message types
enum ImpUnitMessageTypes {
  result = "RESULT",
  debug = "DEBUG",
  status = "STATUS",
  fail = "FAIL"
}

/**
 * Test message
 */
class ImpUnitMessage {

  type = "";
  message = "";

  /**
   * @param {ImpUnitMessageTypes} type - Message type
   * @param {string} message - Message
   */
  constructor(type, message = "") {
    this.type = type;
    this.message = message;
  }

  /**
   * Convert message to JSON
   */
  function toJSON() {
    return JSON.stringify({
      __IMPUNIT_MESSAGE__ = true,
      type = this.type,
      message = this.message
    });
  }

  /**
   * Convert to human-readable string
   */
  function _tostring() {
    return "[impUnit:" + this.type + "] "
      + (typeof this.message == "table"
          ? JSON.stringify(this.message)
          : this.message
        );
  }
}

/**
 * Imp test runner
 */
class ImpUnitRunner {

  // public options
  asyncTimeout = 2;
  readableOutput = true;
  stopOnFailure = false;

  tests = 0;
  assertions = 0;
  failures = 0;
  testFunctions = null;

  constructor() {
    this.readableOutput = readableOutput;
    this.testFunctions = this._getTestFunctions();
  }

  /**
   * Log message
   * @parame {ImpUnitMessage} message
   */
  function _log(message) {
    if (this.readableOutput) {
      server.log(message)
    } else {
      server.log(message.toJSON());
    }
  }

  /**
   * Loog for test cases/test functions
   * @returns {generator}
   */
  function _getTestFunctions() {

    // iterate through the
    foreach (rootKey, rootValue in getroottable()) {

      if (type(rootValue) == "class" && rootValue.getbase() == ImpUnitCase) {

        // create instance of the test class
        local testInstance = rootValue();

        // log setUp() execution
        this._log(ImpUnitMessage(ImpUnitMessageTypes.status, rootKey + "::setUp()"));

        // yield setUp method
        yield [testInstance, testInstance.setUp.bindenv(testInstance)];

        // iterate through members of test class
        foreach (memberKey, memberValue in rootValue) {
          // we need test* methods
          if (memberKey.len() >= 4 && memberKey.slice(0, 4) == "test") {
            // log test method execution
            this._log(ImpUnitMessage(ImpUnitMessageTypes.status, rootKey + "::" + memberKey + "()"));

            this.tests++;

            // yield test method
            yield [testInstance, memberValue.bindenv(testInstance)];
          }
        }

        // log tearDown() execution
        this._log(ImpUnitMessage(ImpUnitMessageTypes.status, rootKey + "::tearDown()"));

        // yield tearDown method
        yield [testInstance, testInstance.tearDown.bindenv(testInstance)];
      }

    }

    // we're done
    return null;
  }

  /**
   * We're done
   */
  function _finish() {
    // log result message
    this._log(ImpUnitMessage(ImpUnitMessageTypes.result, {
      tests = this.tests,
      assertions = this.assertions,
      failures = this.failures
    }));
  }

  /**
   * Called when test method is finished
   * @param {bool} success
   * @param {*} result - resolution/rejection argument
   * @param {integer} assertions - # of assettions made
   */
  function _done(success, result, assertions) {
      if (!success) {
        // log failure
        this.failures++;
        this._log(ImpUnitMessage(ImpUnitMessageTypes.fail, result));
      }

      // update assertions number
      this.assertions += assertions;

      // next
      if (!success && this.stopOnFailure) {
        this._finish();
      } else {
        this.run.call(this);
      }
  }

  /**
   * Run tests
   */
  function run() {

    local test = resume this.testFunctions;

    if (test) {

      local testInstance = test[0];
      local testMethod = test[1];
      local result = null;
      local assertionsMade;

      local syncSuccess = true;
      local syncMessage = "";

      // do GC before each run
      collectgarbage();

      try {
        assertionsMade = testInstance.assertions;
        result = testMethod();
      } catch (e) {

        // store sync test info
        syncSuccess = false;
        syncMessage = e;

      }

      if (result instanceof Promise) {

        // set the timeout timer

        result.timerId = imp.wakeup(this.asyncTimeout, function () {
          if (result._state == 0 /* pending*/) {
            // set the timeout flag
            result.timedOut = true;

            // update assertions counter to ignore assertions afrer the timeout
            assertionsMade = testInstance.assertions;

            this._done(false, "Timed out after " + this.asyncTimeout + "s", 0);
          }
        }.bindenv(this));

        // handle result

        result

          // we're fine
          .then(function (message) {
            if (!result.timedOut) {
              this._done(true, message, testInstance.assertions - assertionsMade);
            }
          }.bindenv(this))

          // we're screwed
          .fail(function (reason) {
            if (!result.timedOut) {
              this._done(false, reason, testInstance.assertions - assertionsMade);
            }
          }.bindenv(this))

          // anyways...
          .finally(function(e) {
            // cancel timeout detection
            if (result.timerId) {
              imp.cancelwakeup(result.timerId);
              result.timerId = null;
            }
          });

      } else {
        // test was sync one
        this._done(syncSuccess, syncMessage, testInstance.assertions - assertionsMade);
      }

    } else {
      this._finish();
    }

  }

}
