" RouterOS script config -------------------------------------------------------
autocmd BufNewFile *.rsc
    \ :0r ~/.vim/templates/rsc.template                                     |
    \ :set virtualedit=all                                                  |
    \ :4s/\<DATE\>/\=strftime("%B %d, %Y")/
