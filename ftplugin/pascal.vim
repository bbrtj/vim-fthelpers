let s:sub_pattern = '\(class\s\+procedure\|class\s\+function\|class\s\+operator\|procedure\|function\|operator\|constructor\|destructor\)\s\+'
	\. '\%(\(\w\+\)\.\)\?'
	\. '\(\w\+\|\S\)'
	\. '\s*\(.*\)'

let s:sub_param_pattern = '^\s*\%(\(\w\+\)\s\+\)\?'
	\. '\(\w\+\%(\s*,\s*\w\+\)*\)\s*'
	\. ':\s*\(\w\+\)\s*'
	\. '\%(=\s*\(.\+\)\)\?'
	\. '\%(;\|$\)'

let s:sub_params_pattern = '^\s*\%((\([^)]*\))\)\?'
	\. '\%(\s*:\s*\(\w\+\)\)\?\s*;'

let s:class_pattern = '\s*=\s*\(class\|record\)[^;]*$'
let s:class_capture = '^\s*\%\(generic\)\?\s\+\(\w\+\)\%\(<\w\+>\)\?' . s:class_pattern

let s:if_pattern = '^\(\s*\%(else\s\+\)\?\)if\s\+\(.\+\)\s\+then\s*\(.*\)'
let s:comparison_pattern = '^\(.\{-}\)\s*\(>=\|<=\|<>\|>\|<\|=\|\<is\>\|\<in\>\)\s*\(.\+\)$'
let s:logical_operator_pattern = '\s*\<\(and\|or\|xor\)\>\s*'

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

function! s:get_params(func_dict, params_str)
	let last_param = 0

	while 1
		let matched = matchlist(a:params_str, s:sub_param_pattern, last_param)
		if len(matched) == 0
			break
		endif

		let last_param = last_param + strlen(matched[0])
		let vars = split(matched[2], '\s*,\s*')
		let param = {
			\ "modifier": matched[1],
			\ "vars": vars,
			\ "type": matched[3],
		\ }

		let a:func_dict.params = add(a:func_dict.params, param)
	endwhile

	if last_param < strlen(a:params_str)
		let a:func_dict.found = 0
	end
endfunction

function! s:get_subroutine_at_line(linenum)
	let max_lines = 5
	let line = getline(a:linenum)

	let matched = matchlist(line, s:sub_pattern)
	if len(matched) > 0
		let result = {
			\ "found": 1,
			\ "type": matched[1],
			\ "class": matched[2],
			\ "name": matched[3],
			\ "params": [],
			\ "result_type": '',
		\ }

		let line_count = 1
		let params_part = matched[4]
		while line_count <= max_lines
			let params_matched = matchlist(params_part, s:sub_params_pattern)
			if len(params_matched) > 0
				let result.result_type = params_matched[2]
				if strlen(params_matched[1]) > 0
					call s:get_params(result, params_matched[1])
				endif

				return result
			endif

			let params_part = params_part . getline(a:linenum + line_count)
			let line_count = line_count + 1
		endwhile
	else

	return { "found": 0 }
endfunction

function! s:same_subroutine(sub1, sub2)
	if a:sub1.found != a:sub2.found
		return 0
	endif

	if a:sub1.found == 0
		return 1
	endif

	return a:sub1 == a:sub2
endfunction

function! s:find_subroutine_in_range(start, end, func_def)
	let current = a:start
	while current != a:end
		let res = s:get_subroutine_at_line(current)
		if s:same_subroutine(a:func_def, res)
			return current
		endif

		let current += 1
	endwhile
endfunction

function! s:generate_function(func_dict)
	if a:func_dict.found == 0
		return ''
	endif

	let params = []
	for param in a:func_dict.params
		let modifier = ''
		if strlen(param.modifier)
			let modifier = param.modifier . ' '
		endif

		let params = add(params, modifier . join(param.vars, ', ') . ': ' . param.type)
	endfor

	let params = '(' . join(params, '; ') . ')'
	if strlen(a:func_dict.result_type) > 0
		let params = params . ': ' . a:func_dict.result_type
	endif


	if strlen(a:func_dict.class) > 0
		return a:func_dict.type . ' ' . a:func_dict.class . '.' . a:func_dict.name . params . ';'
	else
		return a:func_dict.type . ' ' . a:func_dict.name . params . ';'
	endif
endfunction

function! s:add_function(line, func_dict)
	if a:func_dict.found == 0
		return ''
	endif

	call append(a:line - 1, '')
	call append(a:line - 1, 'end;')
	call append(a:line - 1, 'begin')
	call append(a:line - 1, s:generate_function(a:func_dict))
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

function! s:find_depending_on_context(func_def)
	let implem = fthelpers#find_in_range(1, line('$'), s:implementation_pattern)
	if implem == 0
		unsilent echo 'Could not find implementation. Is this file a pascal unit?'
		return
	endif

	if line('.') > implem
		return s:find_declaration(a:func_def)
	else
		return s:find_definition(a:func_def)
	endif

endfunction

function! s:build_class_pattern(class)
	return a:class . '\%\(<\w\+>\)\?' . s:class_pattern
endfunction

function! s:find_declaration(func_def)
	let implem = fthelpers#find_in_range(1, line('$'), s:implementation_pattern)

	if strlen(a:func_def.class) > 0
		let class_line = fthelpers#find_in_range(1, implem, s:build_class_pattern(a:func_def.class))

		if class_line > 0
			let func_def_copy = copy(a:func_def)
			let func_def_copy.class = ''
			return s:find_subroutine_in_range(class_line, implem, func_def_copy)
		else
			return 0
		endif
	else
		let function_line = 1
		while function_line > 0 && function_line < implem
			let function_line = s:find_subroutine_in_range(function_line, implem, a:func_def)
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

function! s:find_definition(func_def)
	let class = s:find_class(line('.'))
	let implem = fthelpers#find_in_range(1, line('$'), s:implementation_pattern)

	if implem > 0
		let func_def_copy = copy(a:func_def)
		let func_def_copy.class = class
		return s:find_subroutine_in_range(implem, line('$'), func_def_copy)
	else
		return 0
	endif
endfunction

function! s:is_embraced(str)
	let openings = strlen(substitute(a:str, '[^(]', '', 'g'))
	let closings = strlen(substitute(a:str, '[^)]', '', 'g'))
	let starting_openings = match(a:str, '[^(]')
	let ending_closings = strlen(a:str) - match(a:str, '[^)])*$') - 1
	let middle_openings = openings - starting_openings
	let middle_closings = closings - ending_closings

	return ending_closings - middle_openings + middle_closings > 0
		\ && starting_openings - middle_closings + middle_openings > 0
endfunction

function! PascalJumpDeclaration()
	let line = line('.')

	let func_def = s:get_subroutine_at_line(line)
	if func_def.found == 1
		call fthelpers#jump(s:find_depending_on_context(func_def))
	else
		unsilent echo 'This line does not contain a pascal subroutine'
	endif
endfunction

function! PascalAddDefinition()
	let line = line('.')

	let func_def = s:get_subroutine_at_line(line)
	if func_def.found == 1 && strlen(func_def.class) == 0
		let found = s:find_definition(func_def)
		let func_def.class = s:find_class(line)

		if found == 0
			let impl_end = s:find_implementation_end()
			if impl_end == 0
				unsilent echo "can't find the end of the unit"
			endif

			call s:add_function(impl_end, func_def)
			call fthelpers#jump(impl_end)
		else
			call PascalJumpDeclaration()
		endif

		return 1
	else
		return 0
	endif
endfunction

function! PascalFixIf()
	let oldline = getline('.')
	let matched = matchlist(oldline, s:if_pattern)
	if len(matched) > 0
		let parts = split(matched[2], s:logical_operator_pattern . '\zs')
		let needs_embracing = len(parts) > 1
		let result = ''
		for part in parts
			let matched_operator = matchlist(part, s:logical_operator_pattern)
			if len(matched_operator) > 0
				let part = substitute(part, matched_operator[0], '', '')
				let matched_operator = ' ' . matched_operator[1] . ' '
			else
				let matched_operator = ''
			endif

			let matched_comparison = matchlist(part, s:comparison_pattern)
			if len(matched_comparison) > 0
				let part = matched_comparison[1] . ' ' . matched_comparison[2] . ' ' . matched_comparison[3]
				if !s:is_embraced(part) && needs_embracing
					let part = '(' . part . ')'
				endif
			elseif s:is_embraced(part)
				let part = part[1:strlen(part) - 2]
			endif

			let result = result . part . matched_operator
		endfor

		let newline = matched[1] . 'if ' . result . ' then ' . matched[3]
		if newline != oldline
			call setline('.', newline)
		endif

		return 1
	else
		return 0
	endif
endfunction

function! PascalComplete()
	let status = 0
	let status = status || PascalAddDefinition()
	let status = status || PascalFixIf()

	if !status
		unsilent echo "nothing to do"
	endif
endfunction

inoremap <buffer> &beg <c-g>ubegin<CR>end;<Esc>
inoremap <buffer> &proc <c-g>u<Esc>biprocedure <Esc>A();<Esc>$F)i
inoremap <buffer> &fun <c-g>u<Esc>bifunction <Esc>A(): T;<Esc>$F)i
inoremap <buffer> &con <c-g>uconstructor Create();<Esc>F)i
inoremap <buffer> &des <c-g>udestructor Destroy; override;
inoremap <buffer> &prop <c-g>u<Esc>b"hyeiproperty <Esc>A:  read F<C-r>h write F<C-r>h;<Esc>$T:a
inoremap <buffer> &mode <c-g>u{$mode objfpc}{$H+}{$J-}
inoremap <buffer> &corba <c-g>u{$interfaces corba}
inoremap <buffer> &int <c-g>u = interface<Esc>:read!uuidgen<CR>I['{<Esc>A}']<Esc>kJr<CR>oend;<Esc>

noremap <silent> <buffer> = :silent call PascalJumpDeclaration()<CR>
noremap <silent> <buffer> g= :silent call PascalComplete()<CR>

