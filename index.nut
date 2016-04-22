/**
 * impUnit Test Framework
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @version 0.5.0
 * @package ImpUnit
 */

// libs required by impUnit

// #include "lib/JSONEncoder.mod.nut"

// #include "lib/Promise.mod.nut"

// impUnit module
function __module_impUnit(Promise, JSONEncoder) {
// #include "src/ImpUnit.nut"
  // export symbols
  return {
    "ImpTestCase" : ImpTestCase,
    "ImpUnitRunner" : ImpUnitRunner
  }
}

// resolve modules
__module_ImpUnit_Promise_exports <- __module_ImpUnit_Promise();
__module_ImpUnit_JSONEncoder_exports <- __module_ImpUnit_JSONEncoder();
__module_impUnit_exports <- __module_impUnit(__module_ImpUnit_Promise_exports, __module_ImpUnit_JSONEncoder_exports);

// add symbols to root scope for old-scool usage
Promise <- __module_ImpUnit_Promise_exports;
ImpTestCase <- __module_impUnit_exports.ImpTestCase;
ImpUnitRunner <- __module_impUnit_exports.ImpUnitRunner;
