/**
 * Test runner
 * @package ImpUnit
 */

// extend Promise for our needs
// don't do this, children
class Promise extends Promise {
  timedOut = false;
  timerId = null;
}

/**
 * Imp test runner
 */
class ImpUnitRunner {

  // public options
  timeout = 2;
  readableOutput = true;
  stopOnFailure = false;
  session = null;

  tests = 0;
  assertions = 0;
  failures = 0;
  testFunctions = null;

  constructor() {
    this.testFunctions = this._getTestFunctions();
  }

  /**
   * Run tests
   */
  function run() {
    this._log(ImpUnitMessage(ImpUnitMessageTypes.sessionStart))
    this._run();
  }

  /**
   * Log message
   * @param {ImpUnitMessage} message
   * @private
   */
  function _log(message) {
    // set session id
    message.session = this.session;

    if (this.readableOutput) {
      server.log(message.toString() /* use custom conversion method to avoid stack resizing limitations on metamethods */)
    } else {
      server.log(message.toJSON());
    }
  }

  /**
   * Loog for test cases/test functions
   * @returns {generator}
   * @private
   */
  function _getTestFunctions() {

    // iterate through the
    foreach (rootKey, rootValue in getroottable()) {

      if (type(rootValue) == "class" && rootValue.getbase() == ImpUnitCase) {

        // create instance of the test class
        local testInstance = rootValue();

        // log setUp() execution
        this._log(ImpUnitMessage(ImpUnitMessageTypes.testStart, rootKey + "::setUp()"));

        // yield setUp method
        yield [testInstance, testInstance.setUp.bindenv(testInstance)];

        // iterate through members of test class
        foreach (memberKey, memberValue in rootValue) {
          // we need test* methods
          if (memberKey.len() >= 4 && memberKey.slice(0, 4) == "test") {
            // log test method execution
            this._log(ImpUnitMessage(ImpUnitMessageTypes.testStart, rootKey + "::" + memberKey + "()"));

            this.tests++;

            // yield test method
            yield [testInstance, memberValue.bindenv(testInstance)];
          }
        }

        // log tearDown() execution
        this._log(ImpUnitMessage(ImpUnitMessageTypes.testStart, rootKey + "::tearDown()"));

        // yield tearDown method
        yield [testInstance, testInstance.tearDown.bindenv(testInstance)];
      }

    }

    // we're done
    return null;
  }

  /**
   * We're done
   * @private
   */
  function _finish() {
    // log result message
    this._log(ImpUnitMessage(ImpUnitMessageTypes.sessionResult, {
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
   * @private
   */
  function _done(success, result, assertions) {
      if (!success) {
        // log failure
        this.failures++;
        this._log(ImpUnitMessage(ImpUnitMessageTypes.testFail, result));
      } else {
        // log test method success
        this._log(ImpUnitMessage(ImpUnitMessageTypes.testOk, result));
      }

      // update assertions number
      this.assertions += assertions;

      // next
      if (!success && this.stopOnFailure) {
        this._finish();
      } else {
        this._run.bindenv(this)();
      }
  }

  /**
   * Run tests
   * @private
   */
  function _run() {

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

        result.timerId = imp.wakeup(this.timeout, function () {
          if (result._state == 0 /* pending*/) {
            // set the timeout flag
            result.timedOut = true;

            // update assertions counter to ignore assertions afrer the timeout
            assertionsMade = testInstance.assertions;

            this._done(false, "Timed out after " + this.timeout + "s", 0);
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
