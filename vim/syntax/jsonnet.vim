syntax match Number "\<\d*\([Ee][+-]\?\d\+\)\?\>"
syntax match Number "\<\d\+[.]\d*\([Ee][+-]\?\d\+\)\?\>"
syntax match Number "\<[.]\d\+\([Ee][+-]\?\d\+\)\?\>"

syn match Constant "std.abs"
syn match Constant "std.acos"
syn match Constant "std.asin"
syn match Constant "std.assertEqual"
syn match Constant "std.atan"
syn match Constant "std.ceil"
syn match Constant "std.char"
syn match Constant "std.codepoint"
syn match Constant "std.cos"
syn match Constant "std.exp"
syn match Constant "std.exponent"
syn match Constant "std.filter"
syn match Constant "std.filterMap"
syn match Constant "std.floor"
syn match Constant "std.foldl"
syn match Constant "std.foldr"
syn match Constant "std.join"
syn match Constant "std.length"
syn match Constant "std.log"
syn match Constant "std.makeArray"
syn match Constant "std.mantissa"
syn match Constant "std.map"
syn match Constant "std.objectFields"
syn match Constant "std.objectHas"
syn match Constant "std.pow"
syn match Constant "std.range"
syn match Constant "std.sin"
syn match Constant "std.sqrt"
syn match Constant "std.substr"
syn match Constant "std.tan"
syn match Constant "std.toString"
syn match Constant "std.type"

syn match Type "\$"

syn region String start='L\="' skip='\\\\\|\\"' end='"'

syn region Comment start="/[*]" end="[*]/"
syn match Comment "//.*$"

syn match Keyword "\<[a-zA-Z_][a-z0-9A-Z_]*\w*:"

syntax keyword Include import importstr
syntax keyword Type function self super
syntax keyword Statement if then else for in
syntax keyword Special local
syntax keyword Constant true false null
syntax keyword Underlined error


