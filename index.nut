#require "promise.class.nut:3.0.0"
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

// libs required by impUnit

@include __PATH__+"/lib/JSONEncoder.mod.nut"

// impUnit module
function __module_impUnit(JSONEncoder) {
@include __PATH__+"/src/ImpUnit.nut"
  // export symbols
  return {
    "ImpTestCase" : ImpTestCase,
    "ImpUnitRunner" : ImpUnitRunner
  }
}

// resolve modules
__module_ImpUnit_JSONEncoder_exports <- __module_ImpUnit_JSONEncoder();
__module_impUnit_exports <- __module_impUnit(__module_ImpUnit_JSONEncoder_exports);

// add symbols to root scope for old-scool usage
ImpTestCase <- __module_impUnit_exports.ImpTestCase;
ImpUnitRunner <- __module_impUnit_exports.ImpUnitRunner;
