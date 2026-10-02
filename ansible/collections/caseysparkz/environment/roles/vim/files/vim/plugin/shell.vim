" Shell script config ---------------------------------------------------------
autocmd BufNewFile *.sh
    \ :0r ~/.vim/templates/sh/sh.template                                   |
    \ :3s/\<DATE\>/\=strftime("%B %d, %Y")/

autocmd BufNewFile *.bash
    \ :0r ~/.vim/templates/sh/sh.template                                   |
    \ :3s/\<DATE\>/\=strftime("%B %d, %Y")/
