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
