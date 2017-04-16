#require "promise.class.nut:3.0.0"
#require "JSONEncoder.class.nut:2.0.0"
// MIT License
//
// Copyright 2016-2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

/**
 * impUnit Test Framework
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @version 1.0.0
 * @package ImpUnit
 */

// impUnit module
function __module_impUnit() {
/**
 * Message handling
 * @package ImpUnit
 */

// message types
local ImpUnitMessageTypes = {
  info = "INFO", // info message
  debug = "DEBUG", // debug message
  testOk = "TEST_OK", // test success
  testFail = "TEST_FAIL", // test failure
  testStart = "TEST_START", // test start
  sessionStart = "SESSION_START", // session start
  sessionResult = "SESSION_RESULT", // session result
  externalCommand = "EXTERNAL_COMMAND" // external command
}

/**
 * Test message
 */
local ImpUnitMessage = class {

  static version = [0, 5, 0];

  type = "";
  message = "";
  session = "";

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
    return JSONEncoder.encode({
      __IMPUNIT__ = 1,
      type = this.type,
      session = this.session,
      message = this.message
    });
  }

  /**
   * Convert to human-readable string
   */
  function toString() {
    return "[impUnit:" + this.type + "] "
      + (typeof this.message == "string"
          ? this.message
          : JSONEncoder.encode(this.message)
        );
  }
}
/**
 * Base for test cases
 * @package ImpUnit
 */
local ImpTestCase = class {

  static version = [0, 5, 0];

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
   * Output an info message
   * @param {*=""} message
   */
  function info(message = "") {
    this.runner.log(
        ImpUnitMessage(ImpUnitMessageTypes.info, {
          "message": message
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
   * @param {*} value1
   * @param {*} value2
   * @param {string} message
   * @param {boolean} isForwardPass - on forward pass value1 is treated "expected", value2 as "actual" and vice-versa on backward pass
   * @param {string} path - current slot path
   * @param {int} level - current depth level
   * @private
   */
  function _assertDeepEqual(value1, value2, message, isForwardPass, path = "", level = 0) {
    local cleanPath = @(p) p.len() == 0 ? p : p.slice(1);

    if (level > 32) {
      throw "Possible cyclic reference at " + cleanPath(path);
    }

    switch (type(value1)) {
      case "table":
      case "class":
      case "array":

        foreach (k, v in value1) {
          path += "." + k;

          if (!(k in value2)) {
            throw format("%s slot [%s] in actual value",
              isForwardPass ? "Missing" : "Extra", cleanPath(path));
          }

          this._assertDeepEqual(value1[k], value2[k], message, isForwardPass, path, level + 1);
        }

        break;

      case "null":
        break;

      default:
        if (value2 != value1) {
          throw format(message, cleanPath(path), value1 + "", value2 + "");
        }

        break;
    }
  }

  /**
   * Perform a deep comparison of two values
   * Useful for comparing arrays or tables
   * @param {*} expected
   * @param {*} actual
   * @param {string} message
   */
  function assertDeepEqual(expected, actual, message = "At [%s]: expected \"%s\", got \"%s\"") {
    this.assertions++;
    this._assertDeepEqual(expected, actual, message, true); // forward pass
    this._assertDeepEqual(actual, expected, message, false); // backwards pass
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
/**
 * Test runner
 * @package ImpUnit
 */

/**
 * Imp test runner
 */
local ImpUnitRunner = class {

  static version = [0, 5, 0];

  // options
  timeout = 2;
  readableOutput = true;
  stopOnFailure = false;
  session = null;

  // result
  tests = 0;
  assertions = 0;
  failures = 0;

  _testsGenerator = null;

  /**
   * Run tests
   */
  function run() {
    this.log(ImpUnitMessage(ImpUnitMessageTypes.sessionStart))
    this._testsGenerator = this._createTestsGenerator();
    this._run();
  }

  /**
   * Log message
   * @param {ImpUnitMessage} message
   * @private
   */
  function log(message) {
    // set session id
    message.session = this.session;

    if (this.readableOutput) {
      server.log(message.toString() /* use custom conversion method to avoid stack resizing limitations on metamethods */)
    } else {
      server.log(message.toJSON());
    }
  }

  /**
   * Find test cases and methods
   */
  function _findTests() {

    local testCases = {};

    foreach (rootKey, rootValue in getroottable()) {
      if (type(rootValue) == "class" && rootValue.getbase() == ImpTestCase) {

        local testCaseName = rootKey;
        local testCaseClass = rootValue;

        testCases[testCaseName] <- {
          setUp = ("setUp" in testCaseClass),
          tearDown = ("tearDown" in testCaseClass),
          tests = []
        };

        // find test methoids
        foreach (memberKey, memberValue in testCaseClass) {
          if (memberKey.len() >= 4 && memberKey.slice(0, 4) == "test") {
            testCases[testCaseName].tests.push(memberKey);
          }
        }

        // sort test methods
        testCases[testCaseName].tests.sort();
      }
    }

    // [debug]
    this.log(ImpUnitMessage(ImpUnitMessageTypes.debug, {"testCasesFound": testCases}));

    return testCases;
  }

  /**
   * Create a generator that yields tests (test methods)
   * @return {Generator}
   * @private
   */
  function _createTestsGenerator() {

    local testCases = this._findTests();

    foreach (testCaseName, testCase in testCases) {

      local testCaseInstance = getroottable()[testCaseName]();
      testCaseInstance.session = this.session;
      testCaseInstance.runner = this;

      if (testCase.setUp) {
        this.log(ImpUnitMessage(ImpUnitMessageTypes.testStart, testCaseName + "::setUp()"));
        yield {
          "case" : testCaseInstance,
          "method" : testCaseInstance.setUp.bindenv(testCaseInstance)
        };
      }

      for (local i = 0; i < testCase.tests.len(); i++) {
        this.tests++;
        this.log(ImpUnitMessage(ImpUnitMessageTypes.testStart, testCaseName + "::" +  testCase.tests[i] + "()"));
        yield {
          "case" : testCaseInstance,
          "method" : testCaseInstance[testCase.tests[i]].bindenv(testCaseInstance)
        };
      }

      if (testCase.tearDown) {
        this.log(ImpUnitMessage(ImpUnitMessageTypes.testStart, testCaseName + "::tearDown()"));
        yield {
          "case" : testCaseInstance,
          "method" : testCaseInstance.tearDown.bindenv(testCaseInstance)
        };
      }
    }

    return null;
  }

  /**
   * We're done
   * @private
   */
  function _finish() {
    // log result message
    this.log(ImpUnitMessage(ImpUnitMessageTypes.sessionResult, {
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
  function _done(success, result, assertions = 0) {
      if (!success) {
        // log failure
        this.failures++;
        this.log(ImpUnitMessage(ImpUnitMessageTypes.testFail, result));
      } else {
        // log test method success
        this.log(ImpUnitMessage(ImpUnitMessageTypes.testOk, result));
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

  function _now() {
    return "hardware" in getroottable()
      ? hardware.millis().tofloat() / 1000
      : time();
  }

  /**
   * Run tests
   * @private
   */
  function _run() {

    local test = resume this._testsGenerator;

    if (test) {

      // do GC before each run
      collectgarbage();

      test.assertions <- test["case"].assertions;
      test.result <- null;

      // record start time
      test.startedAt <- this._now();

      // run test method
      try {
        test.result = test.method();
      } catch (e) {
        // store sync test info
        test.error <- e;
      }

      // detect if test is async
      test.async <- test.result instanceof Promise;

      if (test.async) {

        // set the timeout timer

        test.timedOut <- false;

        local isPending = true;
        test.timerId <- imp.wakeup(this.timeout, function () {
          if (isPending) {
            test.timedOut = true;

            // update assertions counter to ignore assertions afrer the timeout
            test.assertions = test["case"].assertions;

            this._done(false, "Test timed out after " + this.timeout + "s");
          }
        }.bindenv(this));

        // handle result

        test.result

          // we're fine
          .then(function (message) {
            isPending = false;
            test.message <- message;
          })

          // we're screwed
          .fail(function (error) {
            isPending = false;
            test.error <- error;
          })

          // anyways...
          .finally(function(e) {

            // cancel timeout detection
            if (test.timerId) {
              imp.cancelwakeup(test.timerId);
              test.timerId = null;
            }

            if (!test.timedOut) {
              if ("error" in test) {
                this._done(false /* failure */, test.error, test["case"].assertions - test.assertions);
              } else {
                this._done(true /* success */, test.message, test["case"].assertions - test.assertions);
              }
            }

          }.bindenv(this));

      } else {
        // check timeout

        local testDuration = this._now() - test.startedAt;

        if (testDuration > this.timeout) {
          test.error <- "Test took " + testDuration + "s, longer than timeout of " + this.timeout + "s"
        }

        // test was sync
        if ("error" in test) {
          this._done(false /* failure */, test.error, test["case"].assertions - test.assertions);
        } else {
          this._done(true /* success */, test.result, test["case"].assertions - test.assertions);
        }
      }

    } else {
      this._finish();
    }
  }
}
  // export symbols
  return {
    "ImpTestCase" : ImpTestCase,
    "ImpUnitRunner" : ImpUnitRunner
  }
}

// resolve modules
__module_impUnit_exports <- __module_impUnit();

// add symbols to root scope for old-scool usage
ImpTestCase <- __module_impUnit_exports.ImpTestCase;
ImpUnitRunner <- __module_impUnit_exports.ImpUnitRunner;

