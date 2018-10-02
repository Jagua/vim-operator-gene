" vim: set et fdm=marker ft=vim sts=2 sw=0 ts=2 :


let s:save_cpo = &cpo
set cpo&vim


"
" for vspec
"


function! operator#gene#_sid() abort "{{{
  nnoremap <SID> <SID>
  return maparg('<SID>', 'n')
endfunction "}}}


function! operator#gene#_scope() abort "{{{
  return s:
endfunction "}}}


"
" api:
"


function! operator#gene#echo(motion_wise) abort "{{{
  call operator#gene#action(function('s:action_echo'), a:motion_wise)
endfunction "}}}


function! operator#gene#open_split(motion_wise) abort "{{{
  call operator#gene#action(function('s:action_buffer', [{'opener' : 'new', 'autoheight' : 1}]), a:motion_wise)
endfunction "}}}


function! operator#gene#open_vsplit(motion_wise) abort "{{{
  call operator#gene#action(function('s:action_buffer', [{'opener' : 'vnew'}]), a:motion_wise)
endfunction "}}}


function! operator#gene#preview(motion_wise) abort "{{{
  call operator#gene#action(function('s:action_buffer', [{'preview' : 1, 'autoheight' : 1}]), a:motion_wise)
endfunction "}}}


function! operator#gene#action(funcref, motion_wise) abort "{{{
  call s:read_genetxt()
  let words = s:lookup_words(s:get_word_list(a:motion_wise))
  let l:Func = get(a:funcref, 'func')
  let args = get(a:funcref, 'args')
  let ctx = get(args, 0, {})
  let ctx.lines = s:build_lines(words)
  call l:Func(ctx)
endfunction "}}}


function! operator#gene#set_syntax() abort "{{{
  syntax match operatorGeneLine /^.*$/
  syntax match operatorGeneTopic /^[^:]\{-}\ze:/ containedin=operatorGeneLine
  syntax match operatorGeneSep /^.\{-}\zs:\ze/ containedin=operatorGeneLine

  highlight default link operatorGeneTopic Type
  highlight default link operatorGeneSep Comment

  let b:current_syntax = 'OperatorGene'
endfunction "}}}


"
" action: echo
"


function! s:action_echo(ctx) abort "{{{
  echo join(a:ctx.lines, "\n")
endfunction "}}}


"
" action: buffer
"


function! s:action_buffer(ctx) abort "{{{
  let lines = a:ctx.lines
  let bufname = '*gene*'

  if get(a:ctx, 'preview', 0)
    let opener = get(a:ctx, 'opener', 'pedit')
  else
    let opener = get(a:ctx, 'opener', 'new')
  endif

  if get(a:ctx, 'autoheight', 0) && winheight(0) > s:displayheight(a:ctx.lines)
    let height = printf('+resize\ %d', s:displayheight(a:ctx.lines))
  else
    let height = ''
  endif
  execute printf('%s %s %s', opener, height, bufname)

  if get(a:ctx, 'preview', 0)
    wincmd P
  endif

  " Note: prevent to print '\d\+ more lines' message.
  "       'put = lines' prints the message, but
  "       execute('put = lines') does not print it.
  call execute('put = lines')

  1 delete _
  setlocal buftype=nofile readonly nomodified noswapfile nowritebackup bufhidden=delete nobuflisted
  call operator#gene#set_syntax()
  wincmd p
endfunction "}}}


"
" helper:
"


function! s:get_genetxt_path() abort "{{{
  let path = get(g:, 'operator_gene_dict_path', '')
  if !empty(path)
    return path
  else
    let path_list = globpath(&runtimepath, 'dict/gene.txt', 1, 1)
    return empty(path_list) ? '' : path_list[0]
  endif
endfunction "}}}


function! s:read_genetxt() abort "{{{
  if !exists('s:genetxt')
    let gene_dict_path = s:get_genetxt_path()
    if filereadable(expand(gene_dict_path))
      let s:genetxt = readfile(expand(gene_dict_path))[2:]
    else
      echoerr 'not found gene.txt'
    endif
  endif
endfunction "}}}


let s:normalize_english_table = [
      \ {'pattern' : '[[:alpha:]]\+$', 'normalize' : {word -> word}},
      \ {'pattern' : '[[:alpha:]]\+ed$', 'normalize' : {word -> word[ : -3]}},
      \ {'pattern' : '[[:alpha:]]\+ed$', 'normalize' : {word -> word[ : -2]}},
      \ {'pattern' : '[[:alpha:]]\+s$', 'normalize' : {word -> word[ : -2]}},
      \ {'pattern' : '[[:alpha:]]\+ie\%(s\|d\)$', 'normalize' : {word -> word[ : -4] . 'y'}},
      \ {'pattern' : '[[:alpha:]]\+ing$', 'normalize' : {word -> word[ : -4]}},
      \ {'pattern' : '[[:alpha:]]\+ing$', 'normalize' : {word -> word[ : -4] . 'e'}},
      \]


function! s:get_normalized_words(word) abort "{{{
  return map(filter(copy(s:normalize_english_table), 'a:word =~? v:val.pattern'),
        \ 'v:val.normalize(a:word)')
endfunction "}}}


function! s:get_word_list(motion_wise) abort "{{{
  return split(s:get_selection(a:motion_wise), '\W\+', 0)
endfunction "}}}


function! s:lookup_words(word_list) abort "{{{
  return map(copy(a:word_list), 's:lookup(v:val)')
endfunction "}}}


function! s:lookup(word) abort "{{{
  let res = {'word' : a:word, 'body' : ''}
  for word in s:get_normalized_words(a:word)
    let i = index(s:genetxt, word, 0, 1)
    if i == -1
      continue
    endif
    let body = get(s:genetxt, i + 1)
    let item_max = get(g:, 'operator_gene_item_max', 0)
    let body_items = split(body, ',')
    let res['word'] = word
    let res['body'] = join(body_items[0 : item_max - 1], ',')
    break
  endfor
  return res
endfunction "}}}


function! s:build_lines(words) abort "{{{
  return map(copy(a:words), 'printf("%s: %s", v:val.word, v:val.body)')
endfunction "}}}


function! s:displayheight(lines) abort "{{{
  let i = 0
  for line in a:lines
    let i += ceil(round(strdisplaywidth(line)) / round(winwidth(0)))
  endfor
  return float2nr(i)
endfunction "}}}


function! s:get_selection(motion_wise) abort "{{{
  let visual_command = operator#user#visual_command_from_wise_name(a:motion_wise)
  let reg = operator#user#register()
  let save_reg = getreg(reg)
  let original_selection = &selection
  let &selection = 'inclusive'
  execute 'normal! `[' . visual_command . '`]"' . reg . 'y'
  let &selection = original_selection
  let res = getreg(reg)
  call setreg(reg, save_reg)
  return res
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
