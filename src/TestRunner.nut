// MIT License
//
// Copyright 2016 Electric Imp
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
