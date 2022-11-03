let s:sub_pattern = '\(my\s\+\)\?sub\s\+'
	\. '\(\w\+\)\?'
	\. '\s*\((.*)\)\?'
	\. '\s*{\?$'

let s:params_pattern = 'my\s\+(\(.*\))\s\+'
	\. '=\s\+@_;$'

" finds first sub
function! s:find_sub(start)
	return fthelpers#find_in_range(a:start, 0, s:sub_pattern)
endfunction

" finds first named, non-lexical sub
function! s:find_top_sub(start)
	let linenum = s:find_sub(a:start)
	if linenum > 0
		let matched = matchlist(getline(linenum), s:sub_pattern)
		if strlen(matched[1]) > 0 || strlen(matched[2]) == 0
			return s:find_top_sub(linenum - 1)
		endif
	endif

	return linenum
endfunction

function! s:get_old_params(line)
	let matched = matchlist(getline(a:line), s:params_pattern)

	if len(matched) == 0
		return ''
	endif
	return matched[1]
endfunction

function! JumpSub()
	let found = s:find_top_sub(line('.'))

	if found > 0
		call cursor(found, 0)
	else
		unsilent echo 'Could not find a perl sub'
	endif
endfunction

function! ConvertParams()
	let at_line = line('.')
	let params = s:get_old_params(at_line)
	let declaration = s:find_sub(at_line)

	if strlen(params) && declaration > 0
		let matched = matchlist(getline(declaration), s:sub_pattern)

		if strlen(matched[3]) > 0
			unsilent echo 'This sub already has a signature'
		else
			if strlen(matched[2]) > 0
				let result = substitute(getline(declaration), 'sub\s\+' . matched[2], 'sub ' . matched[2] . ' (' . params . ')', '')
			else
				let result = substitute(getline(declaration), 'sub\(\s*{\?\)$', 'sub (' . params . ')\1', '')
			endif

			call setline(declaration, result)
			call deletebufline('%', at_line)
		endif
	else
		unsilent echo 'Could not find a perl sub or its arguments'
	endif
endfunction

inoremap <buffer> &swo <c-g>uuse v5.10;<CR>use strict;<CR>use warnings;
inoremap <buffer> &swn <c-g>uuse v5.36;
inoremap <buffer> &se <c-g>u$self->
inoremap <buffer> &sup <c-g>u$self->SUPER::
inoremap <buffer> &my <c-g>umy () = @_;<Esc>F)i
inoremap <buffer> &dd <c-g>uuse Data::Dumper; die Dumper();<Esc>hi
inoremap <buffer> &dw <c-g>uuse Data::Dumper; warn Dumper();<Esc>hi
inoremap <buffer> &try <c-g>utry {<CR>} catch {<CR>}<Esc>kO<Tab>
inoremap <buffer> &imp <c-g>uuse  qw();<Esc>^ela

" moose-related bindings
inoremap <buffer> &moo <c-g>uhas '' => (<CR>);<Esc>O<Tab>is => 'ro',<Esc>k$F'i
inoremap <buffer> &maf <c-g>uhas field '' => (<CR>);<Esc>k$F'i
inoremap <buffer> &map <c-g>uhas param '' => (<CR>);<Esc>k$F'i
inoremap <buffer> &mao <c-g>uhas option '' => (<CR>);<Esc>k$F'i
inoremap <buffer> &mae <c-g>uhas extended '' => (<CR>);<Esc>k$F'i
inoremap <buffer> &mex <c-g>uextends '';<Esc>hi
inoremap <buffer> &mwi <c-g>uwith qw();<Esc>hi
imap <buffer> &mmar <c-g>uaround  => sub {<CR>};<Esc>O<Tab>&my$orig, $self, @args<Esc>k$F=hi
imap <buffer> &mmaf <c-g>uafter  => sub {<CR>};<Esc>O<Tab>&my$self, @args<Esc>k$F=hi
imap <buffer> &mmbe <c-g>ubefore  => sub {<CR>};<Esc>O<Tab>&my$self, @args<Esc>k$F=hi

noremap <silent> <buffer> = :silent call JumpSub()<CR>
noremap <buffer> g= :!perlcritic --nocolor %<CR>
noremap <silent> <buffer> <leader>wp :silent call ConvertParams()<CR>

