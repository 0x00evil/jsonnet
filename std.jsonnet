/*
Copyright 2014 Google Inc. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the Jsonnet standard library, at least the parts of it that are written in Jsonnet.
 *
 * There are some native methods as well, which are defined in the interpreter and added to this
 * file.  It is never necessary to import std.jsonnet, it is embedded into the interpreter at
 * compile-time and automatically imported into all other Jsonnet programs.
 */
{

    local std = self,

    toString(a)::
        "" + a,
    
    substr(str, from, len)::
        if std.type(str) != "string" then
            error "substr first parameter should be a string, got " + std.type(str)
        else if std.type(from) != "number" then
            error "substr second parameter should be a number, got " + std.type(from)
        else if std.type(len) != "number" then
            error "substr third parameter should be a number, got " + std.type(len)
        else if len < 0 then
            error "substr third parameter should be greater than zero, got " + len
        else
            std.join("", std.makeArray(len, function(i) str[i + from])),

    split(str, c)::
        if std.type(str) != "string" then
            error "std.split first parameter should be a string, got " + std.type(str)
        else if std.type(c) != "string" then
            error "std.split second parameter should be a string, got " + std.type(c)
        else if std.length(c) != 1 then
            error "std.split second parameter should have length 1, got " + std.length(c)
        else
            local aux(str, delim, i, arr, v) =
                local c = str[i];
                if i >= std.length(str) then
                    arr + [v]
                else if c == delim then
                    aux(str, delim, i + 1, arr + [v], "")
                else
                    aux(str, delim, i + 1, arr, v + c);
            aux(str, c, 0, [], ""),

    range(from, to)::
        std.makeArray(to - from + 1, function(i) i + from),

    mod(a, b)::
        if std.type(a) == "number" && std.type(b) == "number" then
            std.modulo(a, b)
        else if std.type(a) == "string" && (std.type(b) == "array" || std.type(b) == "object") then
            std.format(a, b)
        else
            error "Operator % cannot be used on types " + std.type(a) + " and " + std.type(b) + ".",

    map(func, arr)::
        if std.type(func) != "function" then
            error("std.map first param must be function, got " + std.type(func))
        else if std.type(arr) != "array" then
            error("std.map second param must be array, got " + std.type(arr))
        else
            std.makeArray(std.length(arr), function(i) func(arr[i])),

    join(sep, arr)::
        local aux(arr, i, running) =
            if i >= std.length(arr) then
                running
            else if i == 0 then
                aux(arr, i+1, running + arr[i])
            else
                aux(arr, i+1, running + sep + arr[i]);
        if std.type(arr) != "array" then
            error "join second parameter should be array, got " + std.type(arr)
        else if std.type(sep) == "string" then
            aux(arr, 0, "")
        else if std.type(sep) == "array" then
            aux(arr, 0, [])
        else
            error "join first parameter should be string or array, got " + std.type(arr),

    format(str, vals)::

        /////////////////////////////
        // Parse the mini-language //
        /////////////////////////////

        local try_parse_mapping_key(str, i) =
            if i >= std.length(str) then
                error "Truncated format code."
            else
                local c = str[i];
                if c == "(" then
                    local consume(str, j, v) =
                        if j >= std.length(str) then
                            error "Truncated format code."
                        else
                            local c = str[j];
                            if c != ")" then
                                consume(str, j + 1, v + c)
                            else
                                { i: j + 1, v: v };
                    consume(str, i + 1, "")
                else
                    { i: i, v: null };

        local try_parse_cflags(str, i) =
            local consume(str, j, v) =
                if j >= std.length(str) then
                    error "Truncated format code."
                else
                    local c = str[j];
                    if c == "#" then
                        consume(str, j + 1, v + { alt: true })
                    else if c == "0" then
                        consume(str, j + 1, v + { zero: true })
                    else if c == "-" then
                        consume(str, j + 1, v + { left: true })
                    else if c == " " then
                        consume(str, j + 1, v + { blank: true })
                    else if c == "+" then
                        consume(str, j + 1, v + { sign: true })
                    else
                        { i: j, v: v };
            consume(str, i, { alt: false, zero: false, left: false, blank: false, sign: false});

        local try_parse_field_width(str, i) =
            if i < std.length(str) && str[i] == "*" then
                { i: i+1, v: "*" }
            else
                local consume(str, j, v) =
                    if j >= std.length(str) then
                        error "Truncated format code."
                    else
                        local c = str[j];
                        if c == "0" then
                            consume(str, j + 1, v * 10 + 0)
                        else if c == "1" then
                            consume(str, j + 1, v * 10 + 1)
                        else if c == "2" then
                            consume(str, j + 1, v * 10 + 2)
                        else if c == "3" then
                            consume(str, j + 1, v * 10 + 3)
                        else if c == "4" then
                            consume(str, j + 1, v * 10 + 4)
                        else if c == "5" then
                            consume(str, j + 1, v * 10 + 5)
                        else if c == "6" then
                            consume(str, j + 1, v * 10 + 6)
                        else if c == "7" then
                            consume(str, j + 1, v * 10 + 7)
                        else if c == "8" then
                            consume(str, j + 1, v * 10 + 8)
                        else if c == "9" then
                            consume(str, j + 1, v * 10 + 9)
                        else
                            { i: j, v: v };
                consume(str, i, 0);

        local try_parse_precision(str, i) =
            if i >= std.length(str) then
                error "Truncated format code."
            else
                local c = str[i];
                if c == "." then
                    try_parse_field_width(str, i + 1)
                else
                    { i: i, v: null };

        // Ignored, if it exists.
        local try_parse_length_modifier(str, i) =
            if i >= std.length(str) then
                error "Truncated format code."
            else
                local c = str[i];
                if c == "h" || c == "l" || c == "L" then
                    i + 1
                else
                    i;

        local parse_conv_type(str, i) =
            if i >= std.length(str) then
                error "Truncated format code."
            else
                local c = str[i];
                if c == "d" || c == "i" || c == "u" then
                    { i: i + 1, v: "d", caps: false }
                else if c == "o" then
                    { i: i + 1, v: "o", caps: false }
                else if c == "x" then
                    { i: i + 1, v: "x", caps: false }
                else if c == "X" then
                    { i: i + 1, v: "x", caps: true }
                else if c == "e" then
                    { i: i + 1, v: "e", caps: false }
                else if c == "E" then
                    { i: i + 1, v: "e", caps: true }
                else if c == "f" then
                    { i: i + 1, v: "f", caps: false }
                else if c == "F" then
                    { i: i + 1, v: "f", caps: true }
                else if c == "g" then
                    { i: i + 1, v: "g", caps: false }
                else if c == "G" then
                    { i: i + 1, v: "g", caps: true }
                else if c == "c" then
                    { i: i + 1, v: "c", caps: false }
                else if c == "s" then
                    { i: i + 1, v: "s", caps: false }
                else if c == "%" then
                    { i: i + 1, v: "%", caps: false }
                else
                    error "Unrecognised conversion type: " + c;
                    

        // Parsed initial %, now the rest.
        local parse_code(str, i) =
            if i >= std.length(str) then
                error "Truncated format code."
            else
                local mkey = try_parse_mapping_key(str, i);
                local cflags = try_parse_cflags(str, mkey.i);
                local fw = try_parse_field_width(str, cflags.i);
                local prec = try_parse_precision(str, fw.i);
                local len_mod = try_parse_length_modifier(str, prec.i);
                local ctype = parse_conv_type(str, len_mod);
                {
                    i: ctype.i,
                    code: {
                        mkey: mkey.v,
                        cflags: cflags.v,
                        fw: fw.v,
                        prec: prec.v,
                        ctype: ctype.v,
                        caps: ctype.caps,
                    }
                };

        // Parse a format string (containing none or more % format tags).
        local parse_codes(str, i, out) = 
            if i >= std.length(str) then
                out
            else
                local c = str[i];
                if c == "%" then
                    local r = parse_code(str, i + 1);
                    parse_codes(str, r.i, out+[r.code])
                else
                    local last = out[std.length(out)-1];
                    local append = std.length(out) > 0 && std.type(last) == "string";
                    parse_codes(str, i + 1, if append then
                        std.makeArray(std.length(out),
                            function(i) if i < std.length(out)-1 then out[i] else last + c)
                    else
                        std.makeArray(std.length(out) + 1,
                            function(i) if i < std.length(out) then out[i] else c));

        local codes = parse_codes(str, 0, []);


        ///////////////////////
        // Format the values //
        ///////////////////////

        // Useful utilities
        local padding(w, s) =
            local aux(w, v) =
                if w <= 0 then
                    v
                else
                    aux(w - 1, v + s);
            aux(w, "");

        // Add s to the left of str so that its length is at least w.
        local pad_left(str, w, s) =
            padding(w - std.length(str), s) + str;

        // Add s to the right of str so that its length is at least w.
        local pad_right(str, w, s) =
            str + padding(w - std.length(str), s);

        // Render an integer (e.g., decimal or octal).
        local render_int(n__, zero_pad, blank, sign, radix, zero_prefix) =
            local neg = n__ < 0;
            local n_ = std.abs(n__);
            local zp = zero_pad - (if neg || blank || sign then 1 else 0);
            local aux(n) =
                if n == 0 then
                    zero_prefix
                else
                    aux(std.floor(n / radix)) + (n % radix);
            local dec = if std.floor(n_) == 0 then "0" else aux(std.floor(n_));
            local dec2 = pad_left(dec, zp, "0");
            (if neg then "-" else if sign then "+" else if blank then " " else "") + dec2;

        // Render an integer in hexadecimal.
        local render_hex(n__, zero_pad, blank, sign, add_zerox, capitals) =
            local numerals = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                             + if capitals then ["A", "B", "C", "D", "E", "F"]
                                           else ["a", "b", "c", "d", "e", "f"];
            local n_ = std.abs(n__);
            local aux(n) =
                if n == 0 then
                    ""
                else
                    aux(std.floor(n / 16)) + numerals[n % 16];
            local hex = if std.floor(n_) == 0 then "0" else aux(std.floor(n_));

            local neg = n__ < 0;
            local zp = zero_pad - (if neg || blank || sign then 1 else 0)
                                - (if add_zerox then 2 else 0);
            local hex2 = (if add_zerox then (if capitals then "0X" else "0x") else "")
                         + pad_left(hex, zp, "0");
            (if neg then "-" else if sign then "+" else if blank then " " else "") + hex2;

        // Render floating point in decimal form
        local render_float_dec(n__, zero_pad, blank, sign, ensure_pt, prec) =
            local n_ = std.abs(n__);
            local whole = std.floor(n_);
            local dot_size = if prec == 0 && !ensure_pt then 0 else 1;
            local str = render_int(n__ / n_ * whole, zero_pad - prec - dot_size, blank, sign, 10, "");
            if prec == 0 then
                str + if ensure_pt then "." else ""
            else
                local frac = std.floor((n_ - whole) * std.pow(10, prec) + 0.5);
                local frac_str = render_int(frac, prec, false, false, 10, "");
                str + "." + frac_str;

        // Render floating point in scientific form
        local render_float_sci(n__, zero_pad, blank, sign, ensure_pt, caps, prec) =
            local n_ = std.abs(n__);
            local exponent = std.floor(std.log(std.abs(n_)) / std.log(10));
            local suff = (if caps then "E" else "e")
                         + render_int(exponent, 3, false, true, 10, "");
            local mantissa = n__ / n_ * n_ / std.pow(10, exponent);
            render_float_dec(mantissa, zero_pad - std.length(suff), blank, sign, ensure_pt, prec)
            + suff;

        // Render a value with an arbitrary format code.
        local format_code(val, code, fw, prec_or_null, i) =
            local cflags = code.cflags;
            local prec = if prec_or_null != null then prec_or_null else 6;
            local zp = if cflags.zero && !cflags.left then fw else 0;
            if code.ctype == "s" then
                std.toString(val)
            else if code.ctype == "d" then
                if std.type(val) != "number" then
                    error "Format required number at "
                          + i + ", got " + std.type(val)
                else
                    render_int(val, zp, cflags.blank, cflags.sign, 10, "")
            else if code.ctype == "o" then
                if std.type(val) != "number" then
                    error "Format required number at "
                          + i + ", got " + std.type(val)
                else
                    local zero_prefix = if cflags.alt then "0" else "";
                    render_int(val, zp, cflags.blank, cflags.sign, 8, zero_prefix)
            else if code.ctype == "x" then
                if std.type(val) != "number" then
                    error "Format required number at "
                          + i + ", got " + std.type(val)
                else
                    render_hex(val, zp, cflags.blank, cflags.sign, cflags.alt,
                               code.caps)
            else if code.ctype == "f" then
                if std.type(val) != "number" then
                    error "Format required number at "
                          + i + ", got " + std.type(val)
                else
                    render_float_dec(val, zp, cflags.blank,
                                     cflags.sign, cflags.alt, prec)
            else if code.ctype == "e" then
                if std.type(val) != "number" then
                    error "Format required number at "
                          + i + ", got " + std.type(val)
                else
                    render_float_sci(val, zp, cflags.blank,
                                     cflags.sign, cflags.alt, code.caps, prec)
            else if code.ctype == "g" then
                if std.type(val) != "number" then
                    error "Format required number at "
                          + i + ", got " + std.type(val)
                else
                    local exponent = std.log(std.abs(val))/std.log(10);
                    if exponent < -4 || exponent >= prec then
                        render_float_sci(val, zp, cflags.blank,
                                         cflags.sign, cflags.alt, code.caps, prec)
                    else
                        render_float_dec(val, zp, cflags.blank,
                                         cflags.sign, cflags.alt, prec)
            else if code.ctype == "c" then
                if std.type(val) == "number" then
                    std.char(val)
                else if std.type(val) == "string" then
                    if std.length(val) == 1 then
                        val
                    else
                        error "%c expected 1-sized string got: " + std.length(val)
                else
                    error "%c expected number / string, got: " + std.type(val)
            else
                error "Unknown code: " + code.ctype;

        // Render a parsed format string with an array of values.
        local format_codes_arr(codes, arr, i, j, v) =
            if i >= std.length(codes) then
                if j < std.length(arr) then
                    error("Too many values to format: " + std.length(arr) + ", expected " + j)
                else
                    v
            else
                local code = codes[i];
                if std.type(code) == "string" then
                    format_codes_arr(codes, arr, i + 1, j, v + code)
                else
                    local tmp = if code.fw == "*" then {
                        j: j + 1,
                        fw: if j >= std.length(arr) then
                                error "Not enough values to format: " + std.length(arr)
                            else
                                arr[j]
                    } else {
                        j: j,
                        fw: code.fw,
                    };
                    local tmp2 = if code.prec == "*" then {
                        j: tmp.j + 1,
                        prec: if tmp.j >= std.length(arr) then
                                error "Not enough values to format: " + std.length(arr)
                            else
                                arr[tmp.j]
                    } else {
                        j: tmp.j,
                        prec: code.prec,
                    };
                    local j2 = tmp2.j;
                    local val =
                        if j2 < std.length(arr) then
                            arr[j2]
                        else 
                            error "Not enough values to format, got " + std.length(arr);
                    local s =
                        if code.ctype == "%" then
                            "%"
                        else
                            format_code(val, code, tmp.fw, tmp2.prec, j2);
                    local s_padded =
                        if code.cflags.left then
                            pad_right(s, tmp.fw, " ")
                        else
                            pad_left(s, tmp.fw, " ");
                    format_codes_arr(codes, arr, i + 1, j2 + 1, v + s_padded);

        // Render a parsed format string with an object of values.
        local format_codes_obj(codes, obj, i, v) =
            if i >= std.length(codes) then
                v
            else
                local code = codes[i];
                if std.type(code) == "string" then
                    format_codes_obj(codes, obj, i + 1, v + code)
                else
                    local f =
                        if code.mkey == null then
                            error "Mapping keys required."
                        else
                            code.mkey;
                    local fw =
                        if code.fw == "*" then
                            error "Cannot use * field width with object."
                        else
                            code.fw;
                    local prec =
                        if code.prec == "*" then
                            error "Cannot use * precision with object."
                        else
                            code.prec;
                    local val = 
                        if std.objectHas(obj, f) then
                            obj[f]
                        else
                            error "No such field: " + std.length(f);
                    local s =
                        if code.ctype == "%" then
                            "%"
                        else
                            format_code(val, code, fw, prec, f);
                    local s_padded =
                        if code.cflags.left then
                            pad_right(s, fw, " ")
                        else
                            pad_left(s, fw, " ");
                    format_codes_obj(codes, obj, i + 1, v + s_padded);

        if std.type(vals) == "array" then
            format_codes_arr(codes, vals, 0, 0, "")
        else
            format_codes_obj(codes, vals, 0, ""),

    foldr(func, arr, init)::
        local aux(func, arr, running, idx) =
            if idx < 0 then
                running
            else
                aux(func, arr, func(arr[idx], running), idx - 1);
        aux(func, arr, init, std.length(arr) - 1),

    foldl(func, arr, init)::
        local aux(func, arr, running, idx) =
            if idx >= std.length(arr) then
                running
            else
                aux(func, arr, func(running, arr[idx]), idx+1);
        aux(func, arr, init, 0),


    filterMap(filter_func, map_func, arr)::
        if std.type(filter_func) != "function" then
            error("std.filterMap first param must be function, got " + std.type(filter_func))
        else if std.type(map_func) != "function" then
            error("std.filterMap second param must be function, got " + std.type(map_func))
        else if std.type(arr) != "array" then
            error("std.filterMap third param must be array, got " + std.type(arr))
        else
            std.map(map_func, std.filter(filter_func, arr)),

    assertEqual(a, b)::
        if a == b then
            true
        else
            error "Assertion failed. " + a + " != " + b,

    abs(n)::
        if std.type(n) != "number" then
            error "std.abs expected number, got " + std.type(n)
        else
            if n > 0 then n else -n,

}
