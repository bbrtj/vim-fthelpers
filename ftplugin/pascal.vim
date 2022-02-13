let s:sub_pattern = '\(procedure\|function\|constructor\|destructor\)\s\+'
	\. '\%(\(\w\+\)\.\)\?'
	\. '\(\w\+\)'
	\. '\(.*\);'

let s:class_pattern = '\s\+=\s\+class'
let s:class_capture = '^\s*\(\w\+\)' . s:class_pattern

let s:implementation_pattern = '^implementation$'

function! s:find_in_range(start, end, pattern)
	let dir = a:start > a:end ? -1 : 1
	let current = a:start

	while current != a:end && current > 0
		if getline(current) =~? a:pattern
			return current
		endif
		let current += dir
	endwhile

	return 0
endfunction

function! s:find_class(start)
	let linenum = s:find_in_range(a:start, 0, s:class_capture)
	if linenum > 0
		let matched = matchlist(getline(linenum), s:class_capture)
		return matched[1]
	endif

	return ''
endfunction

function! s:find_declaration(type, class, function)
	let implem = s:find_in_range(1, line('$'), s:implementation_pattern)
	let class_line = s:find_in_range(1, implem, a:class . s:class_pattern)

	if class_line > 0
		return s:find_in_range(class_line, implem, a:type . '\s\+' . a:function . '\W')
	else
		return 0
	endif
endfunction

function! s:find_definition(type, function)
	let class = s:find_class(line('.'))
	let implem = s:find_in_range(1, line('$'), s:implementation_pattern)

	if strlen(class) > 0 && implem > 0
		return s:find_in_range(implem, line('$'), a:type . '\s\+' . class . '\.' . a:function . '\W')
	else
		return 0
	endif
endfunction

function! s:add_function(line, type, class, function, params)
	call append(a:line - 1, '')
	call append(a:line - 1, 'end;')
	call append(a:line - 1, 'begin')
	call append(a:line - 1, a:type . ' ' . a:class . '.' . a:function . a:params . ';')
	call append(a:line - 1, '{}')
endfunction

function! JumpDeclaration()
	let line = getline('.')

	let matched = matchlist(line, s:sub_pattern)
	if len(matched) > 0
		if strlen(matched[2]) > 0
			call cursor(s:find_declaration(matched[1], matched[2], matched[3]), 0)
		else
			call cursor(s:find_definition(matched[1], matched[3]), 0)
		endif
	else
		echoe 'This line does not contain a pascal subroutine'
	endif
endfunction

function! AddDefinition()
	let line = getline('.')

	let matched = matchlist(line, s:sub_pattern)
	if len(matched) > 0 && strlen(matched[2]) == 0
		let found = s:find_definition(matched[1], matched[3])
		let class = s:find_class(line('.'))

		if found == 0 && strlen(class) > 0
			let impl_end = s:find_in_range(line('$'), 1, '{ implementation end }')
			if impl_end == 0
				let endline = s:find_in_range(line('$'), 1, 'end\.')

				if endline > 0
					call append(endline - 1, '')
					call append(endline - 1, '{ implementation end }')
					let impl_end = endline
				else
					echoe "can't find the end of the unit"
				endif
			endif

			call s:add_function(impl_end, matched[1], class, matched[3], matched[4])
			call cursor(impl_end, 0)
		else
			call JumpDeclaration()
		endif
	else
		echoe 'This line does not contain a pascal declaration'
	endif
endfunction

let g:pascal_fpc=1

inoremap <buffer> &beg <c-g>ubegin<CR>end;<Esc>
inoremap <buffer> &pro <c-g>u<Esc>biprocedure <Esc>A();<Esc>$F)i
inoremap <buffer> &fun <c-g>u<Esc>bifunction <Esc>A(): T;<Esc>$F)i
inoremap <buffer> &mode <c-g>u{$mode objfpc}{$H+}{$J-}

noremap <silent> <buffer> = :silent call JumpDeclaration()<CR>
noremap <silent> <buffer> g= :silent call AddDefinition()<CR>

