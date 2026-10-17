function _M0TPB13StringBuilder(param0) {
  this.val = param0;
}
function _M0TPC16string10StringView(param0, param1, param2) {
  this.str = param0;
  this.start = param1;
  this.end = param2;
}
class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
function _M0TPB4IterGRPC16string10StringViewE(param0, param1) {
  this.f = param0;
  this.size_hint = param1;
}
function _M0TPB4IterGcE(param0, param1) {
  this.f = param0;
  this.size_hint = param1;
}
function $oob() {
  throw new Error("Index out of bounds");
}
function _M0TPB8MutLocalGiE(param0) {
  this.val = param0;
}
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
const _M0MPB7JSArray4push = (arr, val) => { arr.push(val); };
function _M0TPB8MutLocalGORPC16string10StringViewE(param0) {
  this.val = param0;
}
function _M0TPB9ArrayViewGsE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
const _M0MPB7JSArray11set__length = (arr, len) => { arr.length = len; };
function _M0TPB9ArrayViewGRPC16string10StringViewE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block7Section(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block7Section.prototype.$tag = 0;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9Paragraph(param0) {
  this._0 = param0;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9Paragraph.prototype.$tag = 1;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block4List(param0) {
  this._0 = param0;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block4List.prototype.$tag = 2;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block5Quote(param0) {
  this._0 = param0;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block5Quote.prototype.$tag = 3;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block5Table(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block5Table.prototype.$tag = 4;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9CodeBlock(param0) {
  this._0 = param0;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9CodeBlock.prototype.$tag = 5;
function _M0TP46podhmo14html_2dsandbox3pkg12tinymarkdown4Item(param0, param1) {
  this.text = param0;
  this.children = param1;
}
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(param0) {
  this._0 = param0;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block.prototype.$tag = 0;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat7Heading(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat7Heading.prototype.$tag = 1;
function _M0TP46podhmo14html_2dsandbox3pkg12tinymarkdown8Document(param0) {
  this.children = param0;
}
function _M0TP46podhmo14html_2dsandbox3pkg12tinymarkdown7RawItem(param0, param1) {
  this.indent = param0;
  this.text = param1;
}
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Text(param0) {
  this._0 = param0;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Text.prototype.$tag = 0;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Code(param0) {
  this._0 = param0;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Code.prototype.$tag = 1;
function _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Link(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Link.prototype.$tag = 2;
const _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js11new__object = () => ({});
const _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10new__array = () => [];
const _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js3set = (o, k, v) => { o[k] = v; };
const _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js4push = (a, v) => { a.push(v); };
const _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string = (s) => s;
const _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js7of__int = (n) => n;
const _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger = { method_0: _M0IPB13StringBuilderPB6Logger13write__string, method_1: _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE, method_2: _M0IPB13StringBuilderPB6Logger11write__view, method_3: _M0IPB13StringBuilderPB6Logger11write__char, method_4: _M0IP016_24default__implPB6Logger28write__string__interpolationGRPB13StringBuilderE, method_5: _M0IP016_24default__implPB6Logger5writeGRPB13StringBuilderE };
const _M0MPB4Iter4nextN6constrS63GRPC16string10StringViewE = 0;
const _M0MPB4Iter4nextN6constrS64GRPC16string10StringViewE = 0;
const _M0MPB4Iter4nextN6constrS79GcE = 0;
const _M0MPB4Iter4nextN6constrS80GcE = 0;
const _M0MPB4Iter3newN6constrS87GRPC16string10StringViewE = 0;
const _M0MPB4Iter3newN6constrS93GcE = 0;
const _M0MPC16string10StringView4findN6constrS252 = 0;
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14parse__headingN7_2abindS555 = " ";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS558 = "\\";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS559 = "\\|";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS560 = "|";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS562 = "|";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS563 = "|";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS564 = "";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS606 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS607 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS608 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS609 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS610 = "\r";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS611 = "```";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS612 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS613 = "```";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS614 = "";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS615 = "|";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS616 = ">";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS617 = ">";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS618 = " ";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS619 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS667 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS668 = "\n";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS669 = " ";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS670 = " ";
const _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS671 = "";
function _M0MPB13StringBuilder13write__objectGRPC16string10StringViewE(self, obj) {
  const _p = { self: self, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger };
  _p.method_table.method_2(_p.self, obj);
}
function _M0MPB13StringBuilder21StringBuilder_2einner(size_hint) {
  return new _M0TPB13StringBuilder("");
}
function _M0IPB13StringBuilderPB6Logger11write__char(self, ch) {
  self.val = `${self.val}${String.fromCodePoint(ch)}`;
}
function _M0IPB13StringBuilderPB6Logger13write__string(self, str) {
  self.val = `${self.val}${str}`;
}
function _M0FPB32code__point__of__surrogate__pair(leading, trailing) {
  return (((Math.imul(leading - 55296 | 0, 1024) | 0) + trailing | 0) - 56320 | 0) + 65536 | 0;
}
function _M0MPC16string6String16unsafe__char__at(self, index) {
  const c1 = self.charCodeAt(index);
  if (c1 >= 55296 && c1 <= 56319) {
    const c2 = self.charCodeAt(index + 1 | 0);
    return _M0FPB32code__point__of__surrogate__pair(c1, c2);
  } else {
    return c1;
  }
}
function _M0MPC16string10StringView21clamped__view_2einner(self, start, end) {
  const len = self.end - self.start | 0;
  let lo = start < 0 ? 0 : start > len ? len : start;
  let hi;
  if (end === undefined) {
    hi = len;
  } else {
    const _Some = end;
    const _e = _Some;
    hi = _e < 0 ? 0 : _e > len ? len : _e;
  }
  const str = self.str;
  const base = self.start;
  let _tmp;
  if (lo > 0) {
    let _tmp$2;
    if (lo < len) {
      let _tmp$3;
      const _p = str.charCodeAt(base + lo | 0);
      if (_p >= 56320 && _p <= 57343) {
        const _p$2 = str.charCodeAt((base + lo | 0) - 1 | 0);
        _tmp$3 = _p$2 >= 55296 && _p$2 <= 56319;
      } else {
        _tmp$3 = false;
      }
      _tmp$2 = _tmp$3;
    } else {
      _tmp$2 = false;
    }
    _tmp = _tmp$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    lo = lo + 1 | 0;
  }
  let _tmp$2;
  if (hi > 0) {
    let _tmp$3;
    if (hi < len) {
      let _tmp$4;
      const _p = str.charCodeAt(base + hi | 0);
      if (_p >= 56320 && _p <= 57343) {
        const _p$2 = str.charCodeAt((base + hi | 0) - 1 | 0);
        _tmp$4 = _p$2 >= 55296 && _p$2 <= 56319;
      } else {
        _tmp$4 = false;
      }
      _tmp$3 = _tmp$4;
    } else {
      _tmp$3 = false;
    }
    _tmp$2 = _tmp$3;
  } else {
    _tmp$2 = false;
  }
  if (_tmp$2) {
    hi = hi - 1 | 0;
  }
  return lo >= hi ? new _M0TPC16string10StringView(str, base + lo | 0, base + lo | 0) : new _M0TPC16string10StringView(str, base + lo | 0, base + hi | 0);
}
function _M0MPC16string10StringView12view_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.end - self.start | 0;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  if (start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= (self.end - self.start | 0))) {
    return new _M0TPC16string10StringView(self.str, self.start + start_offset | 0, self.start + end_offset$2 | 0);
  } else {
    return $panic();
  }
}
function _M0IP016_24default__implPB2Eq10not__equalGRPC16string10StringViewE(x, y) {
  return !_M0IPC16string10StringViewPB2Eq5equal(x, y);
}
function _M0IP016_24default__implPB6Logger28write__string__interpolationGRPB13StringBuilderE(self, show) {
  show.method_table.method_0(show.self, { self: self, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
}
function _M0IP016_24default__implPB6Logger5writeGRPB13StringBuilderE(self, show) {
  show.method_table.method_0(show.self, { self: self, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
}
function _M0MPC16string6String21clamped__view_2einner(self, start, end) {
  const len = self.length;
  let lo = start < 0 ? 0 : start > len ? len : start;
  let hi;
  if (end === undefined) {
    hi = len;
  } else {
    const _Some = end;
    const _e = _Some;
    hi = _e < 0 ? 0 : _e > len ? len : _e;
  }
  let _tmp;
  if (lo > 0) {
    let _tmp$2;
    if (lo < len) {
      let _tmp$3;
      const _p = self.charCodeAt(lo);
      if (_p >= 56320 && _p <= 57343) {
        const _p$2 = self.charCodeAt(lo - 1 | 0);
        _tmp$3 = _p$2 >= 55296 && _p$2 <= 56319;
      } else {
        _tmp$3 = false;
      }
      _tmp$2 = _tmp$3;
    } else {
      _tmp$2 = false;
    }
    _tmp = _tmp$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    lo = lo + 1 | 0;
  }
  let _tmp$2;
  if (hi > 0) {
    let _tmp$3;
    if (hi < len) {
      let _tmp$4;
      const _p = self.charCodeAt(hi);
      if (_p >= 56320 && _p <= 57343) {
        const _p$2 = self.charCodeAt(hi - 1 | 0);
        _tmp$4 = _p$2 >= 55296 && _p$2 <= 56319;
      } else {
        _tmp$4 = false;
      }
      _tmp$3 = _tmp$4;
    } else {
      _tmp$3 = false;
    }
    _tmp$2 = _tmp$3;
  } else {
    _tmp$2 = false;
  }
  if (_tmp$2) {
    hi = hi - 1 | 0;
  }
  return lo >= hi ? new _M0TPC16string10StringView(self, lo, lo) : new _M0TPC16string10StringView(self, lo, hi);
}
function _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(self, value, start, len) {
  _M0IPB13StringBuilderPB6Logger11write__view(self, _M0MPC16string6String21clamped__view_2einner(value, start, start + len | 0));
}
function _M0MPB4Iter4nextGRPC16string10StringViewE(self) {
  const _func = self.f;
  const result = _func();
  const _bind = self.size_hint;
  if (result === undefined) {
    self.size_hint = _M0MPB4Iter4nextN6constrS64GRPC16string10StringViewE;
  } else {
    if (_bind === undefined) {
    } else {
      const _Some = _bind;
      const _n = _Some;
      self.size_hint = _n > 0 ? _n - 1 | 0 : _M0MPB4Iter4nextN6constrS63GRPC16string10StringViewE;
    }
  }
  return result;
}
function _M0MPB4Iter4nextGcE(self) {
  const _func = self.f;
  const result = _func();
  const _bind = self.size_hint;
  if (result === -1) {
    self.size_hint = _M0MPB4Iter4nextN6constrS80GcE;
  } else {
    if (_bind === undefined) {
    } else {
      const _Some = _bind;
      const _n = _Some;
      self.size_hint = _n > 0 ? _n - 1 | 0 : _M0MPB4Iter4nextN6constrS79GcE;
    }
  }
  return result;
}
function _M0MPB4Iter3newGRPC16string10StringViewE(f, size_hint) {
  let size_hint$2;
  if (size_hint === undefined) {
    size_hint$2 = undefined;
  } else {
    const _Some = size_hint;
    const _n = _Some;
    size_hint$2 = _n > 0 ? _n : _M0MPB4Iter3newN6constrS87GRPC16string10StringViewE;
  }
  return new _M0TPB4IterGRPC16string10StringViewE(f, size_hint$2);
}
function _M0MPB4Iter3newGcE(f, size_hint) {
  let size_hint$2;
  if (size_hint === undefined) {
    size_hint$2 = undefined;
  } else {
    const _Some = size_hint;
    const _n = _Some;
    size_hint$2 = _n > 0 ? _n : _M0MPB4Iter3newN6constrS93GcE;
  }
  return new _M0TPB4IterGcE(f, size_hint$2);
}
function _M0MPC16string10StringView9to__owned(self) {
  return self.str.substring(self.start, self.end);
}
function _M0MPC16string10StringView4iter(self) {
  const start = self.start;
  const end = self.end;
  const index = new _M0TPB8MutLocalGiE(start);
  return _M0MPB4Iter3newGcE(() => {
    if (index.val < end) {
      const c1 = self.str.charCodeAt(index.val);
      if (c1 >= 55296 && c1 <= 56319 && (index.val + 1 | 0) < self.end) {
        const c2 = self.str.charCodeAt(index.val + 1 | 0);
        if (c2 >= 56320 && c2 <= 57343) {
          index.val = index.val + 2 | 0;
          return _M0FPB32code__point__of__surrogate__pair(c1, c2);
        }
      }
      index.val = index.val + 1 | 0;
      return c1;
    } else {
      return -1;
    }
  }, undefined);
}
function _M0MPC16string6String20unsafe__range__equal(self, self_off, other, other_off, len) {
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < len) {
      const _p = self.charCodeAt(self_off + i | 0);
      const _p$2 = other.charCodeAt(other_off + i | 0);
      if (_p === _p$2) {
      } else {
        return false;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return true;
}
function _M0IPC16string10StringViewPB2Eq5equal(self, other) {
  const len = self.end - self.start | 0;
  if (len === (other.end - other.start | 0)) {
    if (self.str === other.str && self.start === other.start) {
      return true;
    }
    return _M0MPC16string6String20unsafe__range__equal(self.str, self.start, other.str, other.start, len);
  } else {
    return false;
  }
}
function _M0MPC16string6String31offset__of__nth__char__backward(self, n, start_offset, end_offset) {
  let _tmp = end_offset;
  let _tmp$2 = 0;
  while (true) {
    const utf16_offset = _tmp;
    const char_count = _tmp$2;
    if ((utf16_offset - 1 | 0) >= start_offset && char_count < n) {
      const c = self.charCodeAt(utf16_offset - 1 | 0);
      if (c >= 56320 && c <= 57343) {
        _tmp = utf16_offset - 2 | 0;
        _tmp$2 = char_count + 1 | 0;
        continue;
      } else {
        _tmp = utf16_offset - 1 | 0;
        _tmp$2 = char_count + 1 | 0;
        continue;
      }
    } else {
      return char_count < n || utf16_offset < start_offset ? undefined : utf16_offset;
    }
  }
}
function _M0MPC16string6String30offset__of__nth__char__forward(self, n, start_offset, end_offset) {
  if (start_offset >= 0 && start_offset <= end_offset) {
    let _tmp = start_offset;
    let _tmp$2 = 0;
    while (true) {
      const utf16_offset = _tmp;
      const char_count = _tmp$2;
      if (utf16_offset < end_offset && char_count < n) {
        const c = self.charCodeAt(utf16_offset);
        if (c >= 55296 && c <= 56319) {
          _tmp = utf16_offset + 2 | 0;
          _tmp$2 = char_count + 1 | 0;
          continue;
        } else {
          _tmp = utf16_offset + 1 | 0;
          _tmp$2 = char_count + 1 | 0;
          continue;
        }
      } else {
        return char_count < n || utf16_offset >= end_offset ? undefined : utf16_offset;
      }
    }
  } else {
    return $panic();
  }
}
function _M0MPC16string6String29offset__of__nth__char_2einner(self, i, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return i >= 0 ? _M0MPC16string6String30offset__of__nth__char__forward(self, i, start_offset, end_offset$2) : _M0MPC16string6String31offset__of__nth__char__backward(self, -i | 0, start_offset, end_offset$2);
}
function _M0MPC16string6String12view_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  if (start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= self.length)) {
    return new _M0TPC16string10StringView(self, start_offset, end_offset$2);
  } else {
    return $panic();
  }
}
function _M0IPB13StringBuilderPB6Logger11write__view(self, str) {
  self.val = `${self.val}${_M0MPC16string10StringView9to__owned(str)}`;
}
function _M0FPB19kmp__failure__table(pattern) {
  const m = pattern.end - pattern.start | 0;
  const table = $make_array_len_and_init(m, 0);
  let k = 0;
  let _tmp = 1;
  while (true) {
    const i = _tmp;
    if (i < m) {
      const c = pattern.str.charCodeAt(pattern.start + i | 0);
      while (true) {
        let _tmp$2;
        if (k > 0) {
          const _p = pattern.str.charCodeAt(pattern.start + k | 0);
          _tmp$2 = c !== _p;
        } else {
          _tmp$2 = false;
        }
        if (_tmp$2) {
          const _tmp$3 = k - 1 | 0;
          k = _tmp$3 >>> 0 < table.length ? table[_tmp$3] : $oob();
          continue;
        } else {
          break;
        }
      }
      const _p = pattern.str.charCodeAt(pattern.start + k | 0);
      if (c === _p) {
        k = k + 1 | 0;
      }
      if (i >>> 0 < table.length) {
        table[i] = k;
      } else {
        $oob();
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return table;
}
function _M0FPB24find__pattern__kmp__from(target, pattern, start) {
  const n = target.end - target.start | 0;
  const m = pattern.end - pattern.start | 0;
  const table = _M0FPB19kmp__failure__table(pattern);
  let k = 0;
  let _tmp = start;
  while (true) {
    const i = _tmp;
    if (i < n) {
      const c = target.str.charCodeAt(target.start + i | 0);
      while (true) {
        let _tmp$2;
        if (k > 0) {
          const _p = pattern.str.charCodeAt(pattern.start + k | 0);
          _tmp$2 = c !== _p;
        } else {
          _tmp$2 = false;
        }
        if (_tmp$2) {
          const _tmp$3 = k - 1 | 0;
          k = _tmp$3 >>> 0 < table.length ? table[_tmp$3] : $oob();
          continue;
        } else {
          break;
        }
      }
      const _p = pattern.str.charCodeAt(pattern.start + k | 0);
      if (c === _p) {
        k = k + 1 | 0;
      }
      if (k === m) {
        return (i - m | 0) + 1 | 0;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return undefined;
}
function _M0FPB36find__two__anchor__candidate__scalar(data, start, candidate_end, first, last_offset, last) {
  let _tmp = start;
  while (true) {
    const pos = _tmp;
    if (pos < candidate_end) {
      let _tmp$2;
      const _p = data.charCodeAt(pos);
      if (_p === first) {
        const _p$2 = data.charCodeAt(pos + last_offset | 0);
        _tmp$2 = _p$2 === last;
      } else {
        _tmp$2 = false;
      }
      if (_tmp$2) {
        return pos;
      }
      _tmp = pos + 1 | 0;
      continue;
    } else {
      return -1;
    }
  }
}
function _M0FPB42find__two__anchor__candidate__from__string(data, start, candidate_end, first, last_offset, last) {
  return _M0FPB36find__two__anchor__candidate__scalar(data, start, candidate_end, first, last_offset, last);
}
function _M0FPB21string__ranges__equal(left, left_start, right, right_start, length) {
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < length) {
      const _p = left.charCodeAt(left_start + i | 0);
      const _p$2 = right.charCodeAt(right_start + i | 0);
      if (_p !== _p$2) {
        return false;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return true;
}
function _M0FPB22find__by__two__anchors(target, pattern) {
  const target_len = target.end - target.start | 0;
  const pattern_len = pattern.end - pattern.start | 0;
  const target_start = target.start;
  const pattern_start = pattern.start;
  const last_offset = pattern_len - 1 | 0;
  const candidate_end = ((target_start + target_len | 0) - pattern_len | 0) + 1 | 0;
  const first = pattern.str.charCodeAt(pattern.start);
  const last = pattern.str.charCodeAt(pattern.start + last_offset | 0);
  const middle_len = last_offset - 1 | 0;
  let _tmp = target_start;
  let _tmp$2 = 0;
  while (true) {
    const pos = _tmp;
    const failures = _tmp$2;
    if (pos < candidate_end) {
      const found = _M0FPB42find__two__anchor__candidate__from__string(target.str, pos, candidate_end, first, last_offset, last);
      if (found < 0) {
        return undefined;
      }
      if (_M0FPB21string__ranges__equal(target.str, found + 1 | 0, pattern.str, pattern_start + 1 | 0, middle_len)) {
        return found - target_start | 0;
      }
      const failures$2 = failures + 1 | 0;
      const scanned = found - target_start | 0;
      if (failures$2 > 64 || failures$2 > (4 + (scanned / 8 | 0) | 0)) {
        return _M0FPB24find__pattern__kmp__from(target, pattern, scanned + 1 | 0);
      }
      _tmp = found + 1 | 0;
      _tmp$2 = failures$2;
      continue;
    } else {
      return undefined;
    }
  }
}
function _M0FPB24find__code__unit__scalar(data, start, end, code) {
  let _tmp = start;
  while (true) {
    const pos = _tmp;
    if (pos < end) {
      const _p = data.charCodeAt(pos);
      if (_p === code) {
        return pos;
      }
      _tmp = pos + 1 | 0;
      continue;
    } else {
      return -1;
    }
  }
}
function _M0FPB30find__code__unit__from__string(data, start, end, code) {
  return _M0FPB24find__code__unit__scalar(data, start, end, code);
}
function _M0FPB28find__code__unit__from__view(target, start, end, code) {
  const target_start = target.start;
  const found = _M0FPB30find__code__unit__from__string(target.str, target_start + start | 0, target_start + end | 0, code);
  return found < 0 ? -1 : found - target_start | 0;
}
function _M0MPC16string10StringView4find(self, str) {
  const pattern_len = str.end - str.start | 0;
  switch (pattern_len) {
    case 0: {
      return _M0MPC16string10StringView4findN6constrS252;
    }
    case 1: {
      const found = _M0FPB28find__code__unit__from__view(self, 0, self.end - self.start | 0, str.str.charCodeAt(str.start));
      return found < 0 ? undefined : found;
    }
    default: {
      return pattern_len > (self.end - self.start | 0) ? undefined : _M0FPB22find__by__two__anchors(self, str);
    }
  }
}
function _M0MPC16string10StringView11has__prefix(self, str) {
  const str_len = str.end - str.start | 0;
  if (str_len <= (self.end - self.start | 0)) {
    let _tmp;
    if (str_len === 0) {
      _tmp = true;
    } else {
      const _p = self.str.charCodeAt(self.start);
      const _p$2 = str.str.charCodeAt(str.start);
      _tmp = _p === _p$2;
    }
    if (_tmp) {
      return _M0MPC16string6String20unsafe__range__equal(self.str, self.start, str.str, str.start, str_len);
    } else {
      return false;
    }
  } else {
    return false;
  }
}
function _M0MPC16string10StringView13strip__suffix(self, suffix) {
  const self_len = self.end - self.start | 0;
  const suffix_len = suffix.end - suffix.start | 0;
  return self_len >= suffix_len && _M0IPC16string10StringViewPB2Eq5equal(_M0MPC16string10StringView12view_2einner(self, self_len - suffix_len | 0, undefined), suffix) ? _M0MPC16string10StringView12view_2einner(self, 0, self_len - suffix_len | 0) : undefined;
}
function _M0MPC16string10StringView13strip__prefix(self, prefix) {
  const prefix_len = prefix.end - prefix.start | 0;
  return (self.end - self.start | 0) >= prefix_len && _M0IPC16string10StringViewPB2Eq5equal(_M0MPC16string10StringView12view_2einner(self, 0, prefix_len), prefix) ? _M0MPC16string10StringView12view_2einner(self, prefix_len, undefined) : undefined;
}
function _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0MPC15array5Array4pushGRPB5ArrayGsEE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0FPB36string__contains__code__unit__scalar(str, start, end, code) {
  let _tmp = start;
  while (true) {
    const i = _tmp;
    if (i < end) {
      const _p = str.charCodeAt(i);
      if (_p === code) {
        return true;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return false;
}
function _M0FPB28string__contains__code__unit(str, start, end, code) {
  return _M0FPB36string__contains__code__unit__scalar(str, start, end, code);
}
function _M0MPC16string10StringView20contains__code__unit(self, code) {
  return _M0FPB28string__contains__code__unit(self.str, self.start, self.end, code);
}
function _M0MPC16string10StringView8contains(self, str) {
  const _bind = str.end - str.start | 0;
  switch (_bind) {
    case 0: {
      return true;
    }
    case 1: {
      return _M0MPC16string10StringView20contains__code__unit(self, str.str.charCodeAt(str.start));
    }
    default: {
      const _bind$2 = _M0MPC16string10StringView4find(self, str);
      return !(_bind$2 === undefined);
    }
  }
}
function _M0FPB23build__ascii__char__set(chars) {
  let bits0 = 0;
  let bits1 = 0;
  let bits2 = 0;
  let bits3 = 0;
  const _bind = chars.str;
  const _bind$2 = chars.start;
  const _bind$3 = chars.end;
  let _tmp = _bind$2;
  while (true) {
    const _string_index = _tmp;
    if (_string_index < _bind$3) {
      let _decoded_next_string_index;
      let _decoded_char;
      _L: {
        const _bind$4 = _bind.charCodeAt(_string_index);
        if (_bind$4 >= 55296 && _bind$4 <= 56319 && (_string_index + 1 | 0) < _bind$3) {
          const _bind$5 = _bind.charCodeAt(_string_index + 1 | 0);
          if (_bind$5 >= 56320 && _bind$5 <= 57343) {
            const _tmp$2 = _string_index + 2 | 0;
            const _p = (((Math.imul(_bind$4 - 55296 | 0, 1024) | 0) + _bind$5 | 0) - 56320 | 0) + 65536 | 0;
            _decoded_next_string_index = _tmp$2;
            _decoded_char = _p;
            break _L;
          } else {
            const _tmp$2 = _string_index + 1 | 0;
            const _p = _bind$4;
            _decoded_next_string_index = _tmp$2;
            _decoded_char = _p;
            break _L;
          }
        } else {
          const _tmp$2 = _string_index + 1 | 0;
          const _p = _bind$4;
          _decoded_next_string_index = _tmp$2;
          _decoded_char = _p;
          break _L;
        }
      }
      const code = _decoded_char;
      if (code >>> 0 < 128 >>> 0) {
        const bit = 1 << (code & 31);
        const _bind$4 = code >>> 5 | 0;
        switch (_bind$4) {
          case 0: {
            bits0 = bits0 | bit;
            break;
          }
          case 1: {
            bits1 = bits1 | bit;
            break;
          }
          case 2: {
            bits2 = bits2 | bit;
            break;
          }
          default: {
            bits3 = bits3 | bit;
          }
        }
      } else {
        return undefined;
      }
      _tmp = _decoded_next_string_index;
      continue;
    } else {
      break;
    }
  }
  return { _0: bits0, _1: bits1, _2: bits2, _3: bits3 };
}
function _M0FPB26ascii__char__set__contains(bits0, bits1, bits2, bits3, code) {
  if (code >>> 0 < 128 >>> 0) {
    const bit = 1 << (code & 31);
    const _bind = code >>> 5 | 0;
    switch (_bind) {
      case 0: {
        return (bits0 & bit) !== 0;
      }
      case 1: {
        return (bits1 & bit) !== 0;
      }
      case 2: {
        return (bits2 & bit) !== 0;
      }
      default: {
        return (bits3 & bit) !== 0;
      }
    }
  } else {
    return false;
  }
}
function _M0FPB34string__trim__start__ascii__scalar(str, start, end, bits0, bits1, bits2, bits3) {
  let _tmp = start;
  while (true) {
    const pos = _tmp;
    let _tmp$2;
    if (pos < end) {
      const _p = str.charCodeAt(pos);
      _tmp$2 = _M0FPB26ascii__char__set__contains(bits0, bits1, bits2, bits3, _p);
    } else {
      _tmp$2 = false;
    }
    if (_tmp$2) {
      _tmp = pos + 1 | 0;
      continue;
    } else {
      return pos;
    }
  }
}
function _M0FPB32string__trim__end__ascii__scalar(str, start, end, bits0, bits1, bits2, bits3) {
  let _tmp = end;
  while (true) {
    const pos = _tmp;
    let _tmp$2;
    if (pos > start) {
      const _p = str.charCodeAt(pos - 1 | 0);
      _tmp$2 = _M0FPB26ascii__char__set__contains(bits0, bits1, bits2, bits3, _p);
    } else {
      _tmp$2 = false;
    }
    if (_tmp$2) {
      _tmp = pos - 1 | 0;
      continue;
    } else {
      return pos;
    }
  }
}
function _M0FPB26string__trim__start__ascii(str, start, end, _chars, bits0, bits1, bits2, bits3) {
  return _M0FPB34string__trim__start__ascii__scalar(str, start, end, bits0, bits1, bits2, bits3);
}
function _M0FPB24string__trim__end__ascii(str, start, end, _chars, bits0, bits1, bits2, bits3) {
  return _M0FPB32string__trim__end__ascii__scalar(str, start, end, bits0, bits1, bits2, bits3);
}
function _M0MPC16string10StringView14contains__char(self, c) {
  const len = self.end - self.start | 0;
  if (len > 0) {
    const c$2 = c;
    if (c$2 >= 0 && c$2 <= 65535) {
      return _M0MPC16string10StringView20contains__code__unit(self, c$2 & 65535);
    } else {
      if (c$2 < 0) {
        return false;
      } else {
        if (len >= 2) {
          const adj = c$2 - 65536 | 0;
          const high = 55296 + (adj >> 10) | 0;
          if (high <= 65535) {
            const high$2 = high & 65535;
            const low = (56320 + (adj & 1023) | 0) & 65535;
            let _tmp = 0;
            while (true) {
              const i = _tmp;
              if (i < (len - 1 | 0)) {
                const _p = self.str.charCodeAt(self.start + i | 0);
                if (_p === high$2) {
                  const _p$2 = self.str.charCodeAt(self.start + (i + 1 | 0) | 0);
                  if (_p$2 === low) {
                    return true;
                  }
                  _tmp = i + 2 | 0;
                  continue;
                }
                _tmp = i + 1 | 0;
                continue;
              } else {
                break;
              }
            }
          } else {
            return false;
          }
        } else {
          return false;
        }
      }
    }
    return false;
  } else {
    return false;
  }
}
function _M0MPC16string10StringView24trim__start__with__chars(self, chars) {
  let _tmp = self;
  while (true) {
    const x = _tmp;
    if ((x.end - x.start | 0) === 0) {
      return x;
    } else {
      const _c = _M0MPC16string6String16unsafe__char__at(x.str, _M0MPC16string6String29offset__of__nth__char_2einner(x.str, 0, x.start, x.end));
      const _tmp$2 = x.str;
      const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(x.str, 1, x.start, x.end);
      let _tmp$3;
      if (_bind === undefined) {
        _tmp$3 = x.end;
      } else {
        const _Some = _bind;
        _tmp$3 = _Some;
      }
      const _x = new _M0TPC16string10StringView(_tmp$2, _tmp$3, x.end);
      if (_M0MPC16string10StringView14contains__char(chars, _c)) {
        _tmp = _x;
        continue;
      } else {
        return x;
      }
    }
  }
}
function _M0MPC16string10StringView22trim__end__with__chars(self, chars) {
  let _tmp = self;
  while (true) {
    const x = _tmp;
    if ((x.end - x.start | 0) === 0) {
      return x;
    } else {
      const _c = _M0MPC16string6String16unsafe__char__at(x.str, _M0MPC16string6String29offset__of__nth__char_2einner(x.str, -1, x.start, x.end));
      const _x = new _M0TPC16string10StringView(x.str, x.start, _M0MPC16string6String29offset__of__nth__char_2einner(x.str, -1, x.start, x.end));
      if (_M0MPC16string10StringView14contains__char(chars, _c)) {
        _tmp = _x;
        continue;
      } else {
        return x;
      }
    }
  }
}
function _M0MPC16string10StringView12trim_2einner(self, chars) {
  const _bind = _M0FPB23build__ascii__char__set(chars);
  if (_bind === undefined) {
    return _M0MPC16string10StringView22trim__end__with__chars(_M0MPC16string10StringView24trim__start__with__chars(self, chars), chars);
  } else {
    const _Some = _bind;
    const _x = _Some;
    const _bits0 = _x._0;
    const _bits1 = _x._1;
    const _bits2 = _x._2;
    const _bits3 = _x._3;
    const start = _M0FPB26string__trim__start__ascii(self.str, self.start, self.end, chars, _bits0, _bits1, _bits2, _bits3);
    const end = _M0FPB24string__trim__end__ascii(self.str, start, self.end, chars, _bits0, _bits1, _bits2, _bits3);
    return new _M0TPC16string10StringView(self.str, start, end);
  }
}
function _M0MPB4Iter3mapGcRPC16string10StringViewE(self, f) {
  return new _M0TPB4IterGRPC16string10StringViewE(() => {
    const _bind = _M0MPB4Iter4nextGcE(self);
    if (_bind === -1) {
      return undefined;
    } else {
      const _Some = _bind;
      const _x = _Some;
      return f(_x);
    }
  }, self.size_hint);
}
function _M0IPC14char4CharPB4Show10to__string(self) {
  return String.fromCodePoint(self);
}
function _M0MPC16string10StringView5split(self, sep) {
  const sep_len = sep.end - sep.start | 0;
  if (sep_len === 0) {
    return _M0MPB4Iter3mapGcRPC16string10StringViewE(_M0MPC16string10StringView4iter(self), (c) => _M0MPC16string6String12view_2einner(_M0IPC14char4CharPB4Show10to__string(c), 0, undefined));
  }
  const remaining = new _M0TPB8MutLocalGORPC16string10StringViewE(self);
  return _M0MPB4Iter3newGRPC16string10StringViewE(() => {
    const _bind = remaining.val;
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _view = _Some;
      const _bind$2 = _M0MPC16string10StringView4find(_view, sep);
      if (_bind$2 === undefined) {
        remaining.val = undefined;
        return _view;
      } else {
        const _Some$2 = _bind$2;
        const _end = _Some$2;
        remaining.val = _M0MPC16string10StringView12view_2einner(_view, _end + sep_len | 0, undefined);
        return _M0MPC16string10StringView12view_2einner(_view, 0, _end);
      }
    }
  }, undefined);
}
function _M0MPC16string6String5split(self, sep) {
  return _M0MPC16string10StringView5split(new _M0TPC16string10StringView(self, 0, self.length), sep);
}
function _M0MPC16string10StringView12replace__all(self, old, new_) {
  const len = self.end - self.start | 0;
  const buf = _M0MPB13StringBuilder21StringBuilder_2einner(len);
  const old_len = old.end - old.start | 0;
  const new$2 = _M0MPC16string10StringView9to__owned(new_);
  if (old_len === 0) {
    _M0IPB13StringBuilderPB6Logger13write__string(buf, new$2);
    const _bind = self.str;
    const _bind$2 = self.start;
    const _bind$3 = self.end;
    let _tmp = _bind$2;
    while (true) {
      const _string_index = _tmp;
      if (_string_index < _bind$3) {
        let _decoded_next_string_index;
        let _decoded_char;
        _L: {
          const _bind$4 = _bind.charCodeAt(_string_index);
          if (_bind$4 >= 55296 && _bind$4 <= 56319 && (_string_index + 1 | 0) < _bind$3) {
            const _bind$5 = _bind.charCodeAt(_string_index + 1 | 0);
            if (_bind$5 >= 56320 && _bind$5 <= 57343) {
              const _tmp$2 = _string_index + 2 | 0;
              const _p = (((Math.imul(_bind$4 - 55296 | 0, 1024) | 0) + _bind$5 | 0) - 56320 | 0) + 65536 | 0;
              _decoded_next_string_index = _tmp$2;
              _decoded_char = _p;
              break _L;
            } else {
              const _tmp$2 = _string_index + 1 | 0;
              const _p = _bind$4;
              _decoded_next_string_index = _tmp$2;
              _decoded_char = _p;
              break _L;
            }
          } else {
            const _tmp$2 = _string_index + 1 | 0;
            const _p = _bind$4;
            _decoded_next_string_index = _tmp$2;
            _decoded_char = _p;
            break _L;
          }
        }
        _M0IPB13StringBuilderPB6Logger11write__char(buf, _decoded_char);
        _M0IPB13StringBuilderPB6Logger13write__string(buf, new$2);
        _tmp = _decoded_next_string_index;
        continue;
      } else {
        break;
      }
    }
    const _bind$4 = buf.val;
    return new _M0TPC16string10StringView(_bind$4, 0, _bind$4.length);
  } else {
    const first_end = _M0MPC16string10StringView4find(self, old);
    if (first_end === undefined) {
      return self;
    } else {
      const _Some = first_end;
      const _end = _Some;
      let _tmp = self;
      let _tmp$2 = _end;
      while (true) {
        const view = _tmp;
        const end = _tmp$2;
        const seg = _M0MPC16string10StringView12view_2einner(view, 0, end);
        _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(buf, seg.str, seg.start, seg.end - seg.start | 0);
        _M0IPB13StringBuilderPB6Logger13write__string(buf, new$2);
        if ((end + old_len | 0) <= len) {
          const next_view = _M0MPC16string10StringView12view_2einner(view, end + old_len | 0, undefined);
          const _bind = _M0MPC16string10StringView4find(next_view, old);
          if (_bind === undefined) {
            _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(buf, next_view.str, next_view.start, next_view.end - next_view.start | 0);
            break;
          } else {
            const _Some$2 = _bind;
            const _next_end = _Some$2;
            _tmp = next_view;
            _tmp$2 = _next_end;
            continue;
          }
        } else {
          break;
        }
      }
      const _bind = buf.val;
      return new _M0TPC16string10StringView(_bind, 0, _bind.length);
    }
  }
}
function _M0MPC15array9ArrayView4iterGsE(self) {
  const i = new _M0TPB8MutLocalGiE(0);
  const len = self.end - self.start | 0;
  return _M0MPB4Iter3newGRPC16string10StringViewE(() => {
    if (i.val < len) {
      const elem = self.buf[self.start + i.val | 0];
      i.val = i.val + 1 | 0;
      return elem;
    } else {
      return undefined;
    }
  }, len);
}
function _M0MPC15array5Array4iterGsE(self) {
  return _M0MPC15array9ArrayView4iterGsE(new _M0TPB9ArrayViewGsE(self, 0, self.length));
}
function _M0MPC15array9ArrayView4joinGRPC16string10StringViewE(self, separator) {
  if ((self.end - self.start | 0) === 0) {
    return "";
  } else {
    const _hd = self.buf[self.start];
    const _x_buf = self.buf;
    const _x_start = 1 + self.start | 0;
    const _x_end = self.end;
    const hd = _hd;
    const _bind = _x_end - _x_start | 0;
    let size_hint;
    let _tmp = 0;
    let _tmp$2 = hd.end - hd.start | 0;
    while (true) {
      const _ = _tmp;
      const size_hint$2 = _tmp$2;
      if (_ < _bind) {
        const s = _x_buf[_x_start + _ | 0];
        _tmp = _ + 1 | 0;
        const _bind$2 = s;
        _tmp$2 = (size_hint$2 + (_bind$2.end - _bind$2.start | 0) | 0) + (separator.end - separator.start | 0) | 0;
        continue;
      } else {
        size_hint = size_hint$2;
        break;
      }
    }
    const size_hint$2 = size_hint << 1;
    const buf = _M0MPB13StringBuilder21StringBuilder_2einner(size_hint$2);
    _M0IPB13StringBuilderPB6Logger11write__view(buf, hd);
    if ((separator.end - separator.start | 0) === 0) {
      const _bind$2 = _x_end - _x_start | 0;
      let _tmp$3 = 0;
      while (true) {
        const _ = _tmp$3;
        if (_ < _bind$2) {
          const s = _x_buf[_x_start + _ | 0];
          const s$2 = s;
          _M0IPB13StringBuilderPB6Logger11write__view(buf, s$2);
          _tmp$3 = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    } else {
      const _bind$2 = _x_end - _x_start | 0;
      let _tmp$3 = 0;
      while (true) {
        const _ = _tmp$3;
        if (_ < _bind$2) {
          const s = _x_buf[_x_start + _ | 0];
          const s$2 = s;
          _M0IPB13StringBuilderPB6Logger11write__view(buf, separator);
          _M0IPB13StringBuilderPB6Logger11write__view(buf, s$2);
          _tmp$3 = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
    return buf.val;
  }
}
function _M0MPC16option6Option10unwrap__orGRPC16string10StringViewE(self, default_) {
  if (self === undefined) {
    return default_;
  } else {
    const _Some = self;
    const _t = _Some;
    return _t;
  }
}
function _M0MPC15array5Array28unsafe__truncate__to__lengthGRPC16string10StringViewE(self, new_len) {
  _M0MPB7JSArray11set__length(self, new_len);
}
function _M0MPC15array5Array2atGRP46podhmo14html_2dsandbox3pkg12tinymarkdown4FlatE(self, index) {
  const len = self.length;
  return index >= 0 && index < len ? self[index] : $panic();
}
function _M0MPC15array5Array5clearGRPC16string10StringViewE(self) {
  _M0MPC15array5Array28unsafe__truncate__to__lengthGRPC16string10StringViewE(self, 0);
}
function _M0MPC15array5Array8truncateGsE(self, len) {
  if (len >= 0 && len < self.length) {
    _M0MPC15array5Array28unsafe__truncate__to__lengthGRPC16string10StringViewE(self, len);
    return;
  } else {
    return;
  }
}
function _M0MPC15array5Array4joinGRPC16string10StringViewE(self, separator) {
  return _M0MPC15array9ArrayView4joinGRPC16string10StringViewE(new _M0TPB9ArrayViewGRPC16string10StringViewE(self, 0, self.length), separator);
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown15is__space__code(c) {
  if (c <= 32) {
    let _tmp;
    if (c >= 9 && c <= 13) {
      _tmp = true;
    } else {
      const _p = 32;
      _tmp = c === _p;
    }
    return _tmp;
  }
  switch (c) {
    case 133: {
      return true;
    }
    case 160: {
      return true;
    }
    case 5760: {
      return true;
    }
    case 8232: {
      return true;
    }
    case 8233: {
      return true;
    }
    case 8239: {
      return true;
    }
    case 8287: {
      return true;
    }
    case 12288: {
      return true;
    }
    default: {
      return c >= 8192 && c <= 8202;
    }
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11trim__space(s) {
  const n = s.end - s.start | 0;
  let start = 0;
  while (true) {
    let _tmp;
    if (start < n) {
      const _bind = start;
      if (_bind < 0 || _bind >= (s.end - s.start | 0)) {
        $panic();
      }
      _tmp = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown15is__space__code(s.str.charCodeAt(s.start + _bind | 0));
    } else {
      _tmp = false;
    }
    if (_tmp) {
      start = start + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let end = n;
  while (true) {
    let _tmp;
    if (end > start) {
      const _bind = end - 1 | 0;
      if (_bind < 0 || _bind >= (s.end - s.start | 0)) {
        $panic();
      }
      _tmp = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown15is__space__code(s.str.charCodeAt(s.start + _bind | 0));
    } else {
      _tmp = false;
    }
    if (_tmp) {
      end = end - 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return _M0MPC16string10StringView21clamped__view_2einner(s, start, end);
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4nest(flat, from, level) {
  const out = [];
  let _tmp = from;
  while (true) {
    const i = _tmp;
    if (i < flat.length) {
      const _bind = _M0MPC15array5Array2atGRP46podhmo14html_2dsandbox3pkg12tinymarkdown4FlatE(flat, i);
      if (_bind.$tag === 0) {
        const _Block = _bind;
        const _b = _Block._0;
        _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, _b);
        _tmp = i + 1 | 0;
        continue;
      } else {
        const _Heading = _bind;
        const _h = _Heading._0;
        const _x = _Heading._1;
        if (_h <= level) {
          return { _0: out, _1: i };
        } else {
          const _bind$2 = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4nest(flat, i + 1 | 0, _h);
          const _children = _bind$2._0;
          const _next = _bind$2._1;
          _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block7Section(_h, _x, _children));
          _tmp = _next;
          continue;
        }
      }
    } else {
      return { _0: out, _1: i };
    }
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown6indent(line) {
  const n = line.end - line.start | 0;
  let i = 0;
  while (true) {
    let _tmp;
    if (i < n) {
      let _tmp$2;
      const _bind = i;
      if (_bind < 0 || _bind >= (line.end - line.start | 0)) {
        $panic();
      }
      const _p = line.str.charCodeAt(line.start + _bind | 0);
      const _p$2 = 32;
      if (_p === _p$2) {
        _tmp$2 = true;
      } else {
        const _bind$2 = i;
        if (_bind$2 < 0 || _bind$2 >= (line.end - line.start | 0)) {
          $panic();
        }
        const _p$3 = line.str.charCodeAt(line.start + _bind$2 | 0);
        const _p$4 = 9;
        _tmp$2 = _p$3 === _p$4;
      }
      _tmp = _tmp$2;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      i = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return i;
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11is__heading(line) {
  const n = line.end - line.start | 0;
  let i = 0;
  while (true) {
    let _tmp;
    if (i < n) {
      const _bind = i;
      if (_bind < 0 || _bind >= (line.end - line.start | 0)) {
        $panic();
      }
      const _p = line.str.charCodeAt(line.start + _bind | 0);
      const _p$2 = 35;
      _tmp = _p === _p$2;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      i = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (1 <= i) {
    let _tmp;
    if (i <= 5) {
      let _tmp$2;
      if (i < n) {
        const _bind = i;
        if (_bind < 0 || _bind >= (line.end - line.start | 0)) {
          $panic();
        }
        const _p = line.str.charCodeAt(line.start + _bind | 0);
        const _p$2 = 32;
        _tmp$2 = _p === _p$2;
      } else {
        _tmp$2 = false;
      }
      _tmp = _tmp$2;
    } else {
      _tmp = false;
    }
    return _tmp;
  } else {
    return false;
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11nest__items(flat, from, parent) {
  const out = [];
  let _tmp = from;
  while (true) {
    const i = _tmp;
    if (i < flat.length && _M0MPC15array5Array2atGRP46podhmo14html_2dsandbox3pkg12tinymarkdown4FlatE(flat, i).indent > parent) {
      const _bind = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11nest__items(flat, i + 1 | 0, _M0MPC15array5Array2atGRP46podhmo14html_2dsandbox3pkg12tinymarkdown4FlatE(flat, i).indent);
      const _children = _bind._0;
      const _next = _bind._1;
      _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0TP46podhmo14html_2dsandbox3pkg12tinymarkdown4Item(_M0MPC15array5Array2atGRP46podhmo14html_2dsandbox3pkg12tinymarkdown4FlatE(flat, i).text, _children));
      _tmp = _next;
      continue;
    } else {
      return { _0: out, _1: i };
    }
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14parse__heading(line) {
  const _p = _M0MPC16string10StringView4find(line, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14parse__headingN7_2abindS555, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14parse__headingN7_2abindS555.length));
  let n;
  if (_p === undefined) {
    n = $panic();
  } else {
    const _p$2 = _p;
    n = _p$2;
  }
  return new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat7Heading(n, _M0MPC16string10StringView9to__owned(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11trim__space(_M0MPC16string10StringView21clamped__view_2einner(line, n, undefined))));
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cell(s) {
  return _M0MPC16string10StringView8contains(s, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS558, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS558.length)) ? _M0MPC16string10StringView21clamped__view_2einner(_M0MPC16string10StringView12replace__all(s, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS559, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS559.length), new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS560, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cellN7_2abindS560.length)), 0, undefined) : s;
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cells(line) {
  const line$2 = _M0MPC16option6Option10unwrap__orGRPC16string10StringViewE(_M0MPC16string10StringView13strip__prefix(line, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS562, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS562.length)), line);
  const out = [];
  const n = line$2.end - line$2.start | 0;
  let start = 0;
  let i = 0;
  while (true) {
    if (i < n) {
      const _bind = _M0MPC16string10StringView4find(_M0MPC16string10StringView21clamped__view_2einner(line$2, i, undefined), new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS563, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS563.length));
      let j;
      if (_bind === undefined) {
        break;
      } else {
        const _Some = _bind;
        const _k = _Some;
        j = i + _k | 0;
      }
      i = j + 1 | 0;
      let _tmp;
      if (j > start) {
        const _bind$2 = j - 1 | 0;
        if (_bind$2 < 0 || _bind$2 >= (line$2.end - line$2.start | 0)) {
          $panic();
        }
        const _p = line$2.str.charCodeAt(line$2.start + _bind$2 | 0);
        const _p$2 = 92;
        _tmp = _p === _p$2;
      } else {
        _tmp = false;
      }
      if (_tmp) {
        continue;
      }
      _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, _M0MPC16string10StringView9to__owned(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11trim__space(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cell(_M0MPC16string10StringView21clamped__view_2einner(line$2, start, j)))));
      start = i;
      continue;
    } else {
      break;
    }
  }
  const rest = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11trim__space(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14unescape__cell(_M0MPC16string10StringView21clamped__view_2einner(line$2, start, undefined)));
  if (_M0IP016_24default__implPB2Eq10not__equalGRPC16string10StringViewE(rest, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS564, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cellsN7_2abindS564.length))) {
    _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, _M0MPC16string10StringView9to__owned(rest));
  }
  return out;
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown13is__delimiter(c) {
  const c_end = c.length;
  let start = 0;
  let end = c_end;
  let _tmp;
  if (start < end) {
    const _bind = start;
    if (_bind < 0 || _bind >= c_end) {
      $panic();
    }
    const _p = c.charCodeAt(_bind);
    const _p$2 = 58;
    _tmp = _p === _p$2;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    start = start + 1 | 0;
  }
  let _tmp$2;
  if (end > start) {
    const _bind = end - 1 | 0;
    if (_bind < 0 || _bind >= c_end) {
      $panic();
    }
    const _p = c.charCodeAt(_bind);
    const _p$2 = 58;
    _tmp$2 = _p === _p$2;
  } else {
    _tmp$2 = false;
  }
  if (_tmp$2) {
    end = end - 1 | 0;
  }
  if (start >= end) {
    return false;
  }
  let _tmp$3 = start;
  while (true) {
    const i = _tmp$3;
    if (i < end) {
      if (i < 0 || i >= c_end) {
        $panic();
      }
      const _p = c.charCodeAt(i);
      const _p$2 = 45;
      if (_p !== _p$2) {
        return false;
      }
      _tmp$3 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return true;
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown12parse__table(lines) {
  if (lines.length >= 2) {
    const _header = lines[0];
    const _delim = lines[1];
    const _x_end = lines.length;
    const header = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cells(_header);
    const delim = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cells(_delim);
    let _tmp;
    if (delim.length === header.length) {
      const _p = _M0MPC15array5Array4iterGsE(delim);
      let _tmp$2;
      while (true) {
        const _p$2 = _M0MPB4Iter4nextGRPC16string10StringViewE(_p);
        if (_p$2 === undefined) {
          _tmp$2 = true;
          break;
        } else {
          const _p$3 = _p$2;
          const _p$4 = _p$3;
          if (_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown13is__delimiter(_p$4)) {
          } else {
            _tmp$2 = false;
            break;
          }
          continue;
        }
      }
      _tmp = _tmp$2;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      const rows = [];
      const _bind = _x_end - 2 | 0;
      let _tmp$2 = 0;
      while (true) {
        const _ = _tmp$2;
        if (_ < _bind) {
          const line = lines[2 + _ | 0];
          const row = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5cells(line);
          _M0MPC15array5Array8truncateGsE(row, header.length);
          const _bind$2 = row.length;
          const _bind$3 = header.length;
          let _tmp$3 = _bind$2;
          while (true) {
            const _$2 = _tmp$3;
            if (_$2 < _bind$3) {
              _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(row, "");
              _tmp$3 = _$2 + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _M0MPC15array5Array4pushGRPB5ArrayGsEE(rows, row);
          _tmp$2 = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block5Table(header, rows);
    } else {
      return undefined;
    }
  } else {
    return undefined;
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5parse(src) {
  const _bind = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4nest(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scan(src), 0, 0);
  const _children = _bind._0;
  return new _M0TP46podhmo14html_2dsandbox3pkg12tinymarkdown8Document(_children);
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env) {
  const out = _env._4;
  const table = _env._3;
  const items = _env._2;
  const para = _env._1;
  const quote = _env._0;
  if (!(para.length === 0)) {
    _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9Paragraph(_M0MPC15array5Array4joinGRPC16string10StringViewE(para, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS606, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS606.length)))));
    _M0MPC15array5Array5clearGRPC16string10StringViewE(para);
  }
  if (!(items.length === 0)) {
    _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block4List(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11nest__items(items, 0, -1)._0)));
    _M0MPC15array5Array5clearGRPC16string10StringViewE(items);
  }
  if (!(quote.length === 0)) {
    _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block5Quote(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5parse(_M0MPC15array5Array4joinGRPC16string10StringViewE(quote, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS607, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS607.length))).children)));
    _M0MPC15array5Array5clearGRPC16string10StringViewE(quote);
  }
  if (!(table.length === 0)) {
    const _bind = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown12parse__table(table);
    if (_bind === undefined) {
      _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9Paragraph(_M0MPC15array5Array4joinGRPC16string10StringViewE(table, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS608, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS608.length)))));
    } else {
      const _Some = _bind;
      const _t = _Some;
      _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(_t));
    }
    _M0MPC15array5Array5clearGRPC16string10StringViewE(table);
    return;
  } else {
    return;
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scan(src) {
  const out = [];
  const para = [];
  const items = [];
  const quote = [];
  const table = [];
  const _env = { _0: quote, _1: para, _2: items, _3: table, _4: out };
  const code = [];
  let in_code = false;
  const _it = _M0MPC16string6String5split(src, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS609, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS609.length));
  while (true) {
    const _bind = _M0MPB4Iter4nextGRPC16string10StringViewE(_it);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _raw = _Some;
      const line = _M0MPC16option6Option10unwrap__orGRPC16string10StringViewE(_M0MPC16string10StringView13strip__suffix(_raw, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS610, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS610.length)), _raw);
      const trimmed = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11trim__space(line);
      if (in_code) {
        if (_M0IPC16string10StringViewPB2Eq5equal(trimmed, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS611, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS611.length))) {
          _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9CodeBlock(_M0MPC15array5Array4joinGRPC16string10StringViewE(code, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS612, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS612.length)))));
          _M0MPC15array5Array5clearGRPC16string10StringViewE(code);
          in_code = false;
        } else {
          _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(code, line);
        }
        continue;
      }
      if (_M0MPC16string10StringView11has__prefix(trimmed, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS613, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS613.length))) {
        _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
        in_code = true;
      } else {
        if (_M0IPC16string10StringViewPB2Eq5equal(trimmed, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS614, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS614.length))) {
          _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
        } else {
          if (_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11is__heading(trimmed)) {
            _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
            _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14parse__heading(trimmed));
          } else {
            if (_M0MPC16string10StringView11has__prefix(trimmed, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS615, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS615.length))) {
              if (!(para.length === 0) || (!(items.length === 0) || !(quote.length === 0))) {
                _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
              }
              _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(table, trimmed);
            } else {
              if (_M0MPC16string10StringView11has__prefix(trimmed, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS616, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS616.length))) {
                if (!(para.length === 0) || (!(items.length === 0) || !(table.length === 0))) {
                  _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
                }
                const _p = _M0MPC16string10StringView4find(line, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS617, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS617.length));
                let _tmp;
                if (_p === undefined) {
                  _tmp = $panic();
                } else {
                  const _p$2 = _p;
                  _tmp = _p$2;
                }
                const rest = _M0MPC16string10StringView21clamped__view_2einner(line, _tmp + 1 | 0, undefined);
                const _bind$2 = _M0MPC16string10StringView9to__owned(_M0MPC16option6Option10unwrap__orGRPC16string10StringViewE(_M0MPC16string10StringView13strip__prefix(rest, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS618, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS618.length)), rest));
                _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(quote, new _M0TPC16string10StringView(_bind$2, 0, _bind$2.length));
              } else {
                _L: {
                  _L$2: {
                    if ((trimmed.end - trimmed.start | 0) >= 2) {
                      const _x = trimmed.str.charCodeAt(trimmed.start);
                      if (_x === 45) {
                        const _x$2 = trimmed.str.charCodeAt(trimmed.start + 1 | 0);
                        if (_x$2 === 32) {
                          const _x$3 = new _M0TPC16string10StringView(trimmed.str, trimmed.start + 2 | 0, trimmed.end);
                          if (!(para.length === 0) || (!(quote.length === 0) || !(table.length === 0))) {
                            _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
                          }
                          _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(items, new _M0TP46podhmo14html_2dsandbox3pkg12tinymarkdown7RawItem(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown6indent(line), _M0MPC16string10StringView9to__owned(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown11trim__space(_x$3))));
                        } else {
                          break _L$2;
                        }
                      } else {
                        break _L$2;
                      }
                    } else {
                      break _L$2;
                    }
                    break _L;
                  }
                  _L$3: {
                    _L$4: {
                      if (!(items.length === 0)) {
                        if ((line.end - line.start | 0) !== (trimmed.end - trimmed.start | 0)) {
                          _L$5: {
                            if (0 >= (line.end - line.start | 0)) {
                              $panic();
                            }
                            const _bind$2 = line.str.charCodeAt(line.start);
                            switch (_bind$2) {
                              case 32: {
                                break _L$5;
                              }
                              case 9: {
                                break _L$5;
                              }
                              default: {
                                break _L$4;
                              }
                            }
                          }
                          const _bind$2 = _M0MPC15array5Array2atGRP46podhmo14html_2dsandbox3pkg12tinymarkdown4FlatE(items, items.length - 1 | 0);
                          const _tmp = _bind$2.text;
                          const _string_builder = _M0MPB13StringBuilder21StringBuilder_2einner(1);
                          _M0IPB13StringBuilderPB6Logger13write__string(_string_builder, "\n");
                          _M0MPB13StringBuilder13write__objectGRPC16string10StringViewE(_string_builder, trimmed);
                          _bind$2.text = `${_tmp}${_string_builder.val}`;
                        } else {
                          break _L$4;
                        }
                      } else {
                        break _L$4;
                      }
                      break _L$3;
                    }
                    if (!(items.length === 0) || (!(quote.length === 0) || !(table.length === 0))) {
                      _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
                    }
                    _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(para, trimmed);
                  }
                }
              }
            }
          }
        }
      }
      continue;
    }
  }
  if (in_code) {
    _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown4Flat5Block(new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown5Block9CodeBlock(_M0MPC15array5Array4joinGRPC16string10StringViewE(code, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS619, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN7_2abindS619.length)))));
  }
  _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4scanN5flushS605(_env);
  return out;
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10backquotes(s, i) {
  const n = s.length;
  let j = i;
  while (true) {
    let _tmp;
    if (j < n) {
      const _tmp$2 = j;
      const _p = _tmp$2 >>> 0 < s.length ? s.charCodeAt(_tmp$2) : $oob();
      const _p$2 = 96;
      _tmp = _p === _p$2;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      j = j + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return j - i | 0;
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown12closing__run(s, from, n) {
  let _tmp = from;
  while (true) {
    const j = _tmp;
    if (j < s.length) {
      const _p = j >>> 0 < s.length ? s.charCodeAt(j) : $oob();
      const _p$2 = 96;
      if (_p !== _p$2) {
        _tmp = j + 1 | 0;
        continue;
      }
      const m = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10backquotes(s, j);
      if (m === n) {
        return j;
      }
      _tmp = j + m | 0;
      continue;
    } else {
      return -1;
    }
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__text(s) {
  const s$2 = _M0MPC16string10StringView8contains(s, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS667, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS667.length)) ? _M0MPC16string10StringView12replace__all(s, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS668, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS668.length), new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS669, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS669.length)) : s;
  _L: {
    _L$2: {
      if ((s$2.end - s$2.start | 0) >= 2) {
        const _x = s$2.str.charCodeAt(s$2.start);
        if (_x === 32) {
          const _x$2 = s$2.str.charCodeAt(s$2.end - 1 | 0);
          if (_x$2 === 32) {
            const _x$3 = new _M0TPC16string10StringView(s$2.str, s$2.start + 1 | 0, s$2.end - 1 | 0);
            if (_M0IP016_24default__implPB2Eq10not__equalGRPC16string10StringViewE(_M0MPC16string10StringView12trim_2einner(_x$3, new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS670, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS670.length)), new _M0TPC16string10StringView(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS671, 0, _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__textN7_2abindS671.length))) {
              return _M0MPC16string10StringView9to__owned(_x$3);
            } else {
              break _L;
            }
          } else {
            break _L$2;
          }
        } else {
          break _L$2;
        }
      } else {
        break _L$2;
      }
    }
    break _L;
  }
  return _M0MPC16string10StringView9to__owned(s$2);
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4link(s, i) {
  let j;
  let _tmp = i + 1 | 0;
  while (true) {
    const j$2 = _tmp;
    let _tmp$2;
    if (j$2 < s.length) {
      const _p = j$2 >>> 0 < s.length ? s.charCodeAt(j$2) : $oob();
      const _p$2 = 93;
      _tmp$2 = _p !== _p$2;
    } else {
      _tmp$2 = false;
    }
    if (_tmp$2) {
      const _p = j$2 >>> 0 < s.length ? s.charCodeAt(j$2) : $oob();
      const _p$2 = 91;
      if (_p === _p$2) {
        return undefined;
      }
      const _p$3 = j$2 >>> 0 < s.length ? s.charCodeAt(j$2) : $oob();
      const _p$4 = 96;
      if (_p$3 === _p$4) {
        const n = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10backquotes(s, j$2);
        const c = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown12closing__run(s, j$2 + n | 0, n);
        _tmp = c >= 0 ? c + n | 0 : j$2 + n | 0;
        continue;
      }
      _tmp = j$2 + 1 | 0;
      continue;
    } else {
      j = j$2;
      break;
    }
  }
  let _tmp$2;
  if ((j + 1 | 0) < s.length) {
    const _tmp$3 = j + 1 | 0;
    const _p = _tmp$3 >>> 0 < s.length ? s.charCodeAt(_tmp$3) : $oob();
    const _p$2 = 40;
    _tmp$2 = _p === _p$2;
  } else {
    _tmp$2 = false;
  }
  if (_tmp$2) {
    const label = _M0MPC16string10StringView9to__owned(_M0MPC16string6String21clamped__view_2einner(s, i + 1 | 0, j));
    let k;
    let _tmp$3 = j + 2 | 0;
    while (true) {
      const k$2 = _tmp$3;
      let _tmp$4;
      if (k$2 < s.length) {
        const _p = k$2 >>> 0 < s.length ? s.charCodeAt(k$2) : $oob();
        const _p$2 = 41;
        _tmp$4 = _p !== _p$2;
      } else {
        _tmp$4 = false;
      }
      if (_tmp$4) {
        _L: {
          _L$2: {
            const _bind = k$2 >>> 0 < s.length ? s.charCodeAt(k$2) : $oob();
            switch (_bind) {
              case 32: {
                break _L$2;
              }
              case 9: {
                break _L$2;
              }
              case 10: {
                break _L$2;
              }
              case 40: {
                break _L$2;
              }
            }
            break _L;
          }
          return undefined;
        }
        _tmp$3 = k$2 + 1 | 0;
        continue;
      } else {
        k = k$2;
        break;
      }
    }
    return k < s.length ? { _0: label, _1: _M0MPC16string10StringView9to__owned(_M0MPC16string6String21clamped__view_2einner(s, j + 2 | 0, k)), _2: k + 1 | 0 } : undefined;
  } else {
    return undefined;
  }
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14split__inlines(s, links) {
  const out = [];
  let text = 0;
  const n = s.length;
  let i = 0;
  while (true) {
    if (i < n) {
      const _tmp = i;
      const _p = _tmp >>> 0 < s.length ? s.charCodeAt(_tmp) : $oob();
      const _p$2 = 96;
      if (_p === _p$2) {
        const m = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10backquotes(s, i);
        const end = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown12closing__run(s, i + m | 0, m);
        if (end < 0) {
          i = i + m | 0;
          continue;
        }
        if (text < i) {
          _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Text(_M0MPC16string10StringView9to__owned(_M0MPC16string6String21clamped__view_2einner(s, text, i))));
        }
        _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Code(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown10code__text(_M0MPC16string6String21clamped__view_2einner(s, i + m | 0, end))));
        i = end + m | 0;
        text = i;
      } else {
        let _tmp$2;
        const _tmp$3 = i;
        const _p$3 = _tmp$3 >>> 0 < s.length ? s.charCodeAt(_tmp$3) : $oob();
        const _p$4 = 91;
        if (_p$3 === _p$4) {
          _tmp$2 = links;
        } else {
          _tmp$2 = false;
        }
        if (_tmp$2) {
          const _bind = _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown4link(s, i);
          if (_bind === undefined) {
            i = i + 1 | 0;
          } else {
            const _Some = _bind;
            const _x = _Some;
            const _label = _x._0;
            const _url = _x._1;
            const _end = _x._2;
            if (text < i) {
              _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Text(_M0MPC16string10StringView9to__owned(_M0MPC16string6String21clamped__view_2einner(s, text, i))));
            }
            _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Link(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14split__inlines(_label, false), _url));
            i = _end;
            text = i;
          }
        } else {
          i = i + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  if (text < n) {
    _M0MPC15array5Array4pushGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(out, new _M0DTP46podhmo14html_2dsandbox3pkg12tinymarkdown6Inline4Text(_M0MPC16string10StringView9to__owned(_M0MPC16string6String21clamped__view_2einner(s, text, undefined))));
  }
  return out;
}
function _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown7inlines(s) {
  return _M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown14split__inlines(s, true);
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5arrayGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(xs, f) {
  const a = _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10new__array();
  const _bind = xs.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const x = xs[_];
      _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js4push(a, f(x));
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return a;
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5arrayGRPB5ArrayGsEE(xs, f) {
  const a = _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10new__array();
  const _bind = xs.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const x = xs[_];
      _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js4push(a, f(x));
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return a;
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js7strings(xs) {
  return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5arrayGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(xs, _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string);
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object(kind, fields) {
  const o = _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js11new__object();
  _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js3set(o, "kind", _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(kind));
  const _bind = fields.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const field = fields[_];
      _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js3set(o, field._0, field._1);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return o;
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js11list__items(items) {
  return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5arrayGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(items, (it) => {
    const o = _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js11new__object();
    _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js3set(o, "text", _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(it.text));
    _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js3set(o, "children", _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js11list__items(it.children));
    return o;
  });
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6blocks(bs) {
  return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5arrayGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(bs, (b) => {
    switch (b.$tag) {
      case 0: {
        const _Section = b;
        const _level = _Section._0;
        const _title = _Section._1;
        const _children = _Section._2;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("section", [{ _0: "level", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js7of__int(_level) }, { _0: "title", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(_title) }, { _0: "children", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6blocks(_children) }]);
      }
      case 1: {
        const _Paragraph = b;
        const _text = _Paragraph._0;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("paragraph", [{ _0: "text", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(_text) }]);
      }
      case 2: {
        const _List = b;
        const _items = _List._0;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("list", [{ _0: "items", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js11list__items(_items) }]);
      }
      case 3: {
        const _Quote = b;
        const _children$2 = _Quote._0;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("quote", [{ _0: "children", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6blocks(_children$2) }]);
      }
      case 4: {
        const _Table = b;
        const _header = _Table._0;
        const _rows = _Table._1;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("table", [{ _0: "header", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js7strings(_header) }, { _0: "rows", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5arrayGRPB5ArrayGsEE(_rows, _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js7strings) }]);
      }
      default: {
        const _CodeBlock = b;
        const _code = _CodeBlock._0;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("code", [{ _0: "code", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(_code) }]);
      }
    }
  });
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5parse(src) {
  const o = _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js11new__object();
  _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js3set(o, "children", _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6blocks(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown5parse(src).children));
  return o;
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js13inline__array(xs) {
  return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5arrayGRP46podhmo14html_2dsandbox3pkg12tinymarkdown5BlockE(xs, (i) => {
    switch (i.$tag) {
      case 0: {
        const _Text = i;
        const _t = _Text._0;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("text", [{ _0: "text", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(_t) }]);
      }
      case 1: {
        const _Code = i;
        const _t$2 = _Code._0;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("code", [{ _0: "text", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(_t$2) }]);
      }
      default: {
        const _Link = i;
        const _children = _Link._0;
        const _url = _Link._1;
        return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js6object("link", [{ _0: "children", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js13inline__array(_children) }, { _0: "url", _1: _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js10of__string(_url) }]);
      }
    }
  });
}
function _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js7inlines(s) {
  return _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js13inline__array(_M0FP46podhmo14html_2dsandbox3pkg12tinymarkdown7inlines(s));
}
export { _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js5parse as parse, _M0FP56podhmo14html_2dsandbox3pkg12tinymarkdown2js7inlines as inlines }
