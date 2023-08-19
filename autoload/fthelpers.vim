function! fthelpers#jump(to_line)
	normal! m`
	call cursor(a:to_line, 0)
endfunction

function! fthelpers#find_in_range(start, end, pattern)
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

