" vim: set et fdm=marker ft=vim sts=2 sw=0 ts=2 :


if exists('g:loaded_operator_gene')
  finish
endif
let g:loaded_operator_gene = 1


call operator#user#define('gene-echo', 'operator#gene#echo')
call operator#user#define('gene-open-split', 'operator#gene#open_split')
call operator#user#define('gene-open-vsplit', 'operator#gene#open_vsplit')
call operator#user#define('gene-preview', 'operator#gene#preview')
