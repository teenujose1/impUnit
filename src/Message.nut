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
