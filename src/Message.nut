/**
 * Message handling
 * @package ImpUnit
 */

// message types
enum ImpUnitMessageTypes {
  start = "START", // session start
  testStart = "TEST_START", // test start
  testOk = "TEST_OK", // test success
  testFail = "TEST_FAIL", // test failure
  result = "RESULT", // session result
  debug = "DEBUG" // debug message
}

/**
 * Test message
 */
class ImpUnitMessage {

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
