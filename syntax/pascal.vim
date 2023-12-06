" this is not a standalone syntax definition. It complements the one built
" into vim with this mode:
let g:pascal_delphi=1

syn keyword pascalDirective program unit
syn keyword pascalDirective uses type
syn keyword pascalDirective var const
syn keyword pascalStage implementation interface initialization finalization
syn keyword pascalSpecialize specialize
syn keyword pascalPropertyRW read write

syn keyword pascalType NativeUInt NativeInt UInt8 Int8 UInt16 Int16 UInt32 Int32 UInt64 Int64 DWord QWord

syn keyword pascalIdentifier result self

syn keyword pascalInterfaceType interface contained

syn match pascalLocalVariable "\<[vVlL][A-Z]\w\+\>"
syn match pascalClassVariable "\<[fF][A-Z]\w\+\>"
syn match pascalConstant "\<[cC][A-Z]\w\+\>"
syn match pascalCustomType "\<T[A-Z]\w*"
syn match pascalCustomType "\<E[A-Z]\w*"
syn match pascalCustomType "\<I[A-Z]\w*"
syn match pascalFunctionDeclaration "\(function\|procedure\|constructor\|destructor\)\@<=\s\+\w\+\(\s*\((\|;\)\)\@="
syn match pascalFunctionDeclaration "\(\(function\|procedure\|constructor\|destructor\)\s\+\w\+\.\)\@<=\w\+\(\s*\((\|;\)\)\@="

syn match pascalInterfaceDeclaration "\w\+\s*=\s*interface" contains=pascalCustomType,pascalInterfaceType

hi link pascalDirective Define
hi link pascalStage Underlined
hi link pascalSpecialize Statement
hi link pascalPropertyRW Statement

hi link pascalIdentifier Identifier

hi link pascalInterfaceType Statement

hi link pascalLocalVariable Identifier
hi link pascalClassVariable Identifier
hi link pascalConstant Constant
hi link pascalCustomType TypeDef
hi link pascalFunctionDeclaration Function

