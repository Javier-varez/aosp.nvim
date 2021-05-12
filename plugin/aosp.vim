if exists('g:loaded_aosp_nvim') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
command! AospBuildTarget lua require'aosp_nvim'.build_target()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_aosp_nvim = 1
