let s:sub_pattern = '\(class\s\+procedure\|class\s\+function\|procedure\|function\|constructor\|destructor\)\s\+'
	\. '\%(\(\w\+\)\.\)\?'
	\. '\(\w\+\)'
	\. '\(.*\);'

let s:sub_params_pattern = '\(([^)]*)\)\?'
	\. '\(:\s*\w\+\)\?'

let s:class_pattern = '\s*=\s*class[^;]*$'
let s:class_capture = '^\s*\%\(generic\)\?\s\+\(\w\+\)\%\(<\w\+>\)\?' . s:class_pattern

let s:begin = '^\s*begin'
let s:end = '^\s*end;'
let s:implementation_end = '^\(initialization\|finalization\)$'

let s:implementation_pattern = '^\(implementation\|{\s*implementation\s*}\)$'
let s:end_pattern = '^\(end\.\|{\s*implementation end\s*}\)$'

function! s:find_class(start)
	let linenum = fthelpers#find_in_range(a:start, 0, s:class_capture)
	if linenum > 0
		" check whether the class was closed
		let end_linenum = fthelpers#find_in_range(linenum, a:start, s:end)
		if end_linenum > 0
			" the class we found was closed, so find another one
			return s:find_class(linenum - 1)
		endif

		" not closed? good
		let matched = matchlist(getline(linenum), s:class_capture)
		return matched[1]
	endif

	return ''
endfunction

function! s:find_implementation_end()
	let endline = fthelpers#find_in_range(line('$'), 1, s:end_pattern)
	let impl = fthelpers#find_in_range(endline, 1, s:implementation_pattern)
	if endline > 0 && impl > 0
		let end = fthelpers#find_in_range(impl, endline, s:implementation_end)
		if end > 0
			return end
		else
			let minor_end = fthelpers#find_in_range(endline, impl, s:end)
			let begin = fthelpers#find_in_range(endline, impl, s:begin)
			if begin > 0 && minor_end < begin
				return begin
			else
				return endline
			endif
		endif
	else
		return 0
	endif
endfunction

function! s:find_depending_on_context(type, class, function, params)
	let implem = fthelpers#find_in_range(1, line('$'), s:implementation_pattern)
	if implem == 0
		unsilent echo 'Could not find implementation. Is this file a pascal unit?'
		return
	endif

	if line('.') > implem
		return s:find_declaration(a:type, a:class, a:function, a:params)
	else
		return s:find_definition(a:type, a:function, a:params)
	endif

endfunction

function! s:build_class_pattern(class)
	return a:class . '\%\(<\w\+>\)\?' . s:class_pattern
endfunction

function! s:find_declaration(type, class, function, params)
	let implem = fthelpers#find_in_range(1, line('$'), s:implementation_pattern)

	if strlen(a:class) > 0
		let class_line = fthelpers#find_in_range(1, implem, s:build_class_pattern(a:class))

		if class_line > 0
			return fthelpers#find_in_range(class_line, implem, a:type . '\s\+' . a:function . a:params)
		else
			return 0
		endif
	else
		let function_line = 1
		while function_line > 0 && function_line < implem
			let function_line = fthelpers#find_in_range(function_line, implem, a:type . '\s\+' . a:function . a:params)
			if function_line > 0
				let class_name = s:find_class(function_line)
				if strlen(class_name) == 0
					return function_line
				endif

				let function_line = function_line + 1
			endif
		endwhile

		return 0
	endif
endfunction

function! s:find_definition(type, function, params)
	let class = s:find_class(line('.'))
	let implem = fthelpers#find_in_range(1, line('$'), s:implementation_pattern)

	if implem > 0
		if strlen(class) > 0
			return fthelpers#find_in_range(implem, line('$'), a:type . '\s\+' . class . '\.' . a:function . a:params)
		else
			return fthelpers#find_in_range(implem, line('$'), a:type . '\s\+' . a:function . a:params)
		endif
	else
		return 0
	endif
endfunction

function! s:add_function(line, type, class, function, params)
	call append(a:line - 1, '')
	call append(a:line - 1, 'end;')
	call append(a:line - 1, 'begin')
	if strlen(a:class) > 0
		call append(a:line - 1, a:type . ' ' . a:class . '.' . a:function . a:params . ';')
	else
		call append(a:line - 1, a:type . ' ' . a:function . a:params . ';')
	endif
endfunction

function! s:get_essential_params(arguments, default = '')
	let matched = matchlist(a:arguments, s:sub_params_pattern)

	if len(matched) > 0
		return matched[0]
	else
		return a:default
	endif
endfunction

function! JumpDeclaration()
	let line = getline('.')

	let matched = matchlist(line, s:sub_pattern)
	if len(matched) > 0
		let params = s:get_essential_params(matched[4], '\W')

		call fthelpers#jump(s:find_depending_on_context(matched[1], matched[2], matched[3], params))
	else
		unsilent echo 'This line does not contain a pascal subroutine'
	endif
endfunction

function! AddDefinition()
	let line = getline('.')

	let matched = matchlist(line, s:sub_pattern)
	if len(matched) > 0 && strlen(matched[2]) == 0
		let params = s:get_essential_params(matched[4], '\W')
		let found = s:find_definition(matched[1], matched[3], params)
		let class = s:find_class(line('.'))

		if found == 0
			let impl_end = s:find_implementation_end()
			if impl_end == 0
				unsilent echo "can't find the end of the unit"
			endif

			call s:add_function(impl_end, matched[1], class, matched[3], s:get_essential_params(matched[4]))
			call fthelpers#jump(impl_end)
		else
			call JumpDeclaration()
		endif
	else
		unsilent echo 'This line does not contain a pascal declaration'
	endif
endfunction

inoremap <buffer> &beg <c-g>ubegin<CR>end;<Esc>
inoremap <buffer> &pro <c-g>u<Esc>biprocedure <Esc>A();<Esc>$F)i
inoremap <buffer> &fun <c-g>u<Esc>bifunction <Esc>A(): T;<Esc>$F)i
inoremap <buffer> &con <c-g>uconstructor Create();<Esc>F)i
inoremap <buffer> &des <c-g>udestructor Destroy; override;
inoremap <buffer> &mode <c-g>u{$mode objfpc}{$H+}{$J-}
inoremap <buffer> &corba <c-g>u{$interfaces corba}
inoremap <buffer> &int <c-g>u = interface<Esc>:read!uuidgen<CR>I['{<Esc>A}']<Esc>kJr<CR>oend;<Esc>

noremap <silent> <buffer> = :silent call JumpDeclaration()<CR>
noremap <silent> <buffer> g= :silent call AddDefinition()<CR>

