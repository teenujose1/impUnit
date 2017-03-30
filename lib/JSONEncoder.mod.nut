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
 * JSON encoder
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @verion 0.4.0-impUnit
 *
 *  impUnit chages:
 *   - packaging as module
 */
function __module_ImpUnit_JSONEncoder() {
  local exports = class {

    static version = [0, 4, 0, "impUnit"];

    // max structure depth
    // anything above probably has a cyclic ref
    static _maxDepth = 32;

    /**
     * Encode value to JSON
     * @param {table|array|*} value
     * @returns {string}
     */
    function encode(value) {
      return this._encode(value);
    }

    /**
     * @param {table|array} val
     * @param {integer=0} depth – current depth level
     * @private
     */
    function _encode(val, depth = 0) {

      // detect cyclic reference
      if (depth > this._maxDepth) {
        throw "Possible cyclic reference";
      }

      local
        r = "",
        s = "",
        i = 0;

      switch (typeof val) {

        case "table":
        case "class":
          s = "";

          // serialize properties, but not functions
          foreach (k, v in val) {
            if (typeof v != "function") {
              s += ",\"" + k + "\":" + this._encode(v, depth + 1);
            }
          }

          s = s.len() > 0 ? s.slice(1) : s;
          r += "{" + s + "}";
          break;

        case "array":
          s = "";

          for (i = 0; i < val.len(); i++) {
            s += "," + this._encode(val[i], depth + 1);
          }

          s = (i > 0) ? s.slice(1) : s;
          r += "[" + s + "]";
          break;

        case "integer":
        case "float":
        case "bool":
          r += val;
          break;

        case "null":
          r += "null";
          break;

        case "instance":

          if ("_serialize" in val && typeof val._serialize == "function") {

            // serialize instances by calling _serialize method
            r += this._encode(val._serialize(), depth + 1);

          } else {

            s = "";

            try {

              // iterate through instances which implement _nexti meta-method
              foreach (k, v in val) {
                s += ",\"" + k + "\":" + this._encode(v, depth + 1);
              }

            } catch (e) {

              // iterate through instances w/o _nexti
              // serialize properties, but not functions
              foreach (k, v in val.getclass()) {
                if (typeof v != "function") {
                  s += ",\"" + k + "\":" + this._encode(val[k], depth + 1);
                }
              }

            }

            s = s.len() > 0 ? s.slice(1) : s;
            r += "{" + s + "}";
          }

          break;

        // strings and all other
        default:
          r += "\"" + this._escape(val.tostring()) + "\"";
          break;
      }

      return r;
    }

    /**
     * Escape strings according to http://www.json.org/ spec
     * @param {string} str
     */
    function _escape(str) {
      local res = "";

      for (local i = 0; i < str.len(); i++) {

        local ch1 = (str[i] & 0xFF);

        if ((ch1 & 0x80) == 0x00) {
          // 7-bit Ascii

          ch1 = format("%c", ch1);

          if (ch1 == "\"") {
            res += "\\\"";
          } else if (ch1 == "\\") {
            res += "\\\\";
          } else if (ch1 == "/") {
            res += "\\/";
          } else if (ch1 == "\b") {
            res += "\\b";
          } else if (ch1 == "\f") {
            res += "\\f";
          } else if (ch1 == "\n") {
            res += "\\n";
          } else if (ch1 == "\r") {
            res += "\\r";
          } else if (ch1 == "\t") {
            res += "\\t";
          } else {
            res += ch1;
          }

        } else {

          if ((ch1 & 0xE0) == 0xC0) {
            // 110xxxxx = 2-byte unicode
            local ch2 = (str[++i] & 0xFF);
            res += format("%c%c", ch1, ch2);
          } else if ((ch1 & 0xF0) == 0xE0) {
            // 1110xxxx = 3-byte unicode
            local ch2 = (str[++i] & 0xFF);
            local ch3 = (str[++i] & 0xFF);
            res += format("%c%c%c", ch1, ch2, ch3);
          } else if ((ch1 & 0xF8) == 0xF0) {
            // 11110xxx = 4 byte unicode
            local ch2 = (str[++i] & 0xFF);
            local ch3 = (str[++i] & 0xFF);
            local ch4 = (str[++i] & 0xFF);
            res += format("%c%c%c%c", ch1, ch2, ch3, ch4);
          }

        }
      }

      return res;
    }
  }

  return exports;
}
