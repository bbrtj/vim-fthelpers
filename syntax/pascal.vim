syn keyword pascalDirective program unit
syn keyword pascalDirective uses type
syn keyword pascalDirective implementation interface initialization finalization
syn keyword pascalSpecialize specialize

syn keyword pascalResult result

syn match pascalLocalVariable "\<[vV][A-Z]\w\+\>"
syn match pascalClassVariable "\<[fF][A-Z]\w\+\>"
syn match pascalConstant "\<[cC][A-Z]\w\+\>"
syn match pascalCustomType "\<T[A-Z]\w*"
syn match pascalFunctionDeclaration "\(function\|procedure\|constructor\|destructor\)\@<=\s\+\w\+\(\s*(\)\@="
syn match pascalMethodDeclaration "\(\(function\|procedure\|constructor\|destructor\)\s\+\w\+\.\)\@<=\w\+\(\s*(\)\@="

hi link pascalDirective Define

hi link pascalSpecialize Statement

hi link pascalResult Identifier

hi link pascalLocalVariable Identifier
hi link pascalClassVariable Identifier
hi link pascalConstant Constant
hi link pascalCustomType TypeDef
hi link pascalFunctionDeclaration Function
hi link pascalMethodDeclaration Function

