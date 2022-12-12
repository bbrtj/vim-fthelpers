" this is not a standalone syntax definition. It compliments the one built
" into vim with this mode:
let g:pascal_delphi=1

syn keyword pascalDirective program unit
syn keyword pascalDirective uses type
syn keyword pascalDirective var const
syn keyword pascalStage implementation interface initialization finalization
syn keyword pascalSpecialize specialize
syn keyword pascalPropertyRW read write

syn keyword pascalIdentifier result Result self Self

syn match pascalLocalVariable "\<[vV][A-Z]\w\+\>"
syn match pascalClassVariable "\<[fF][A-Z]\w\+\>"
syn match pascalConstant "\<[cC][A-Z]\w\+\>"
syn match pascalCustomType "\<T[A-Z]\w*"
syn match pascalCustomType "\<E[A-Z]\w*"
syn match pascalFunctionDeclaration "\(function\|procedure\|constructor\|destructor\)\@<=\s\+\w\+\(\s*(\)\@="
syn match pascalFunctionDeclaration "\(\(function\|procedure\|constructor\|destructor\)\s\+\w\+\.\)\@<=\w\+\(\s*(\)\@="

hi link pascalDirective Define
hi link pascalStage Underlined
hi link pascalSpecialize Statement
hi link pascalPropertyRW Statement

hi link pascalIdentifier Identifier

hi link pascalLocalVariable Identifier
hi link pascalClassVariable Identifier
hi link pascalConstant Constant
hi link pascalCustomType TypeDef
hi link pascalFunctionDeclaration Function

