" Hasktags module for Gutentags

" Global Options {{{

if !exists('g:gutentags_hasktags_executable')
    let g:gutentags_hasktags_executable = 'hasktags -c -x'
endif

if !exists('g:gutentags_hasktags_tagfile')
    let g:gutentags_hasktags_tagfile = 'hasktags'
endif

if !exists('g:gutentags_auto_set_tags')
    let g:gutentags_auto_set_tags = 1
endif

" }}}

" Gutentags Module Interface {{{

let s:runner_exe = gutentags#get_plat_file('update_tags')

function! gutentags#hasktags#init(project_root) abort
    " Figure out the path to the tags file.
    let b:gutentags_files['hasktags'] = gutentags#get_cachefile(
                \a:project_root, g:gutentags_hasktags_tagfile)

    " Set the tags file for Vim to use.
    if g:gutentags_auto_set_tags
        execute 'setlocal tags^=' . fnameescape(b:gutentags_files['hasktags'])
    endif
endfunction

function! gutentags#hasktags#generate(proj_dir, tags_file, write_mode) abort
    " Get to the tags file directory because ctags is finicky about
    " these things.
    let l:prev_cwd = getcwd()
    let l:work_dir = fnamemodify(a:tags_file, ':h')
    execute "chdir " . fnameescape(l:work_dir)

    try
        " Build the command line.
        let l:cmd = gutentags#get_execute_cmd() . s:runner_exe
        let l:cmd .= ' -e "' . g:gutentags_hasktags_executable . '"'
        let l:cmd .= ' -t "' . a:tags_file . '"'
        let l:cmd .= ' -p "' . a:proj_dir . '"'
        if a:write_mode == 0 && filereadable(a:tags_file)
            let l:full_path = expand('%:p')
            let l:cmd .= ' -s "' . l:full_path . '"'
        endif
        if g:gutentags_pause_after_update
            let l:cmd .= ' -c'
        endif
        if g:gutentags_trace
            if has('win32')
                let l:cmd .= ' -l "' . a:tags_file . '.log"'
            else
                let l:cmd .= ' > "' . a:tags_file . '.log" 2>&1'
            endif
        else
            if !has('win32')
                let l:cmd .= ' > /dev/null 2>&1'
            endif
        endif
        let l:cmd .= gutentags#get_execute_cmd_suffix()

        call gutentags#trace("Running: " . l:cmd)
        call gutentags#trace("In:      " . getcwd())
        if !g:gutentags_fake
            " Run the background process.
            if !g:gutentags_trace
                silent execute l:cmd
            else
                execute l:cmd
            endif

            " Flag this tags file as being in progress
            let l:full_tags_file = fnamemodify(a:tags_file, ':p')
            call gutentags#add_progress('ctags', l:full_tags_file)
        else
            call gutentags#trace("(fake... not actually running)")
        endif
        call gutentags#trace("")
    finally
        " Restore the previous working directory.
        execute "chdir " . fnameescape(l:prev_cwd)
    endtry
endfunction

" }}}

