" vim: set et fdm=indent ft=vim sts=2 sw=0 ts=2 :


scriptencoding utf-8


if $PROFILE_LOG !=# ''
  execute printf('profile start %s', $PROFILE_LOG)
  execute printf('profile! file %s', 'autoload/*.vim')
endif


call vspec#hint({'sid' : 'operator#gene#_sid()', 'scope' : 'operator#gene#_scope()'})


runtime plugin/operator/user.vim
runtime plugin/operator/gene.vim


describe 'operator-gene'
  before
    let g:operator_gene_dict_path = expand('<sfile>:h') . '/t/fake-gene.txt'
    new
    put=['headline']
    1 delete _
  end

  after
    unlet g:operator_gene_dict_path
    close!
  end

  it 'is only available when "gene.txt" is readable'
    Expect filereadable(g:operator_gene_dict_path) == 1
  end

  it 'sets proper variables'
    Expect g:loaded_operator_gene == 1
    Expect Call('s:get_genetxt_path') ==# g:operator_gene_dict_path
  end
end

describe 's:read_genetxt'
  before
    let g:operator_gene_dict_path = expand('<sfile>:h') . '/t/fake-gene.txt'
  end

  after
    unlet g:operator_gene_dict_path
  end

  it 'defines s:genetext'
    call Call('s:read_genetxt')
    Expect Ref('s:genetxt') ==# ['headline', '見出し']
  end
end

describe 's:get_selection()'
  before
    new
    put=['headline']
    1 delete _
  end

  after
    close!
  end

  it 'returns selected characters'
    execute "normal \<Plug>(operator-gene-echo)iw"
    Expect Call('s:get_selection', 'char') ==# 'headline'
  end
end

describe 's:lookup_words()'
  it 'returns a list of dictionary'
    Expect Call('s:lookup_words', ['headline']) ==# [{'word' : 'headline', 'body' : '見出し'}]
    Expect Call('s:lookup_words', ['no_data']) ==# [{'word' : 'no_data', 'body' : ''}]
  end
end

describe 's:lookup()'
  it 'returns a dictionary which contains two keys, "word" and "body"'
    Expect Call('s:lookup', 'headline') ==# {'word' : 'headline', 'body' : '見出し'}
  end

  it 'returns a dictionary which body value is empty if data is none'
    Expect Call('s:lookup', 'no_data') ==# {'word' : 'no_data', 'body' : ''}
  end
end

describe 's:build_lines()'
  it 'returns a list of translated line'
    Expect Call('s:build_lines', [{'word' : 'headline', 'body' : '見出し'}]) == ['headline: 見出し']
  end
end

describe 's:displayheight()'
  it 'returns display height'
    Expect Call('s:displayheight', [repeat('a', winwidth(0) * 1 - 1)]) == 1
    Expect Call('s:displayheight', [repeat('a', winwidth(0) * 1 + 0)]) == 1
    Expect Call('s:displayheight', [repeat('a', winwidth(0) * 1 + 1)]) == 2
  end
end

describe '<Plug>'
  it 'is available in proper modes'
    let plugs = [
          \ '<Plug>(operator-gene-echo)',
          \ '<Plug>(operator-gene-open-split)',
          \ '<Plug>(operator-gene-open-vsplit)',
          \ '<Plug>(operator-gene-preview)']
    for lhs in plugs
      Expect maparg(lhs, 'n') =~# 'operator#gene#'
      Expect maparg(lhs, 'v') =~# 'operator#gene#'
    endfor
  end
end


describe '<Plug>'
  before
    let g:operator_gene_dict_path = expand('<sfile>:h') . '/t/fake-gene.txt'
    new
    put=['headline']
    1 delete _
    call Call('s:read_genetxt')
  end

  after
    unlet g:operator_gene_dict_path
    close!
  end

  context '(operator-gene-echo)'
    it 'works properly'
      Expect execute("normal \<Plug>(operator-gene-echo)iw") ==# "\nheadline: 見出し"
    end
  end

  context '(operator-gene-open-split)'
    it 'works properly'
      Expect execute(["normal \<Plug>(operator-gene-open-split)iw\<C-w>k", 'echo getline(".")']) ==# "\nheadline: 見出し"
      close!
    end

    it 'applies syntax in buffer'
      execute "normal \<Plug>(operator-gene-open-split)iw\<C-w>k"
      Expect b:current_syntax ==# 'OperatorGene'
      close!
    end
  end

  context '(operator-gene-open-vsplit)'
    it 'works properly'
      Expect execute(["normal \<Plug>(operator-gene-open-vsplit)iw\<C-w>h", 'echo getline(".")']) ==# "\nheadline: 見出し"
      close!
    end
  end

  context '(operator-gene-preview)'
    it 'works properly'
      Expect execute(["normal \<Plug>(operator-gene-preview)iw\<C-w>P", 'echo getline(".")']) ==# "\nheadline: 見出し"
      close!
    end
  end
end


describe 's:get_normalized_words()'
  it 'returns a list of normalized english words'
    let table = {
          \ 'headlines' : 'headline',
          \ 'watching' : 'watch',
          \ 'watched' : 'watch',
          \ 'operating' : 'operate',
          \ 'operated' : 'operate',
          \}
    for key in keys(table)
      execute printf('Expect index(Call("s:get_normalized_words", "%s"), "%s") >= 0', key, key)
      execute printf('Expect index(Call("s:get_normalized_words", "%s"), table["%s"]) >= 0', key, key)
    endfor
  end
end
