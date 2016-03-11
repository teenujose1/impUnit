/**
 * impUnit Test Framework
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @version 0.3.0
 * @package ImpUnit
 */

// #include "lib/JSONEncoder.class.nut"
// #include "lib/Promise.class.nut"
// impUnit module

function __module_impUnit(Promise, JSONEncoder) {
// #include "src/ImpUnit.nut"
  // export symbols
  return {
    "ImpTestCase" : ImpTestCase,
    "ImpUnitRunner" : ImpUnitRunner
  }
}
