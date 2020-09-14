"randomcolor.vim
"
"author: fudesign2008@163.com
"
" This plugin will set random color scheme when the vim starts up.
" Use `:RandomTheme` command to random scheme manually
"
"
"

if &compatible || exists('g:random_theme_loaded')
    if exists(':RandomTheme')

        if exists('g:random_theme_start') && g:random_theme_start
            execute ':silent RandomTheme'
        endif

        finish
    endif
endif

let g:random_theme_loaded = 1
let s:save_cpo = &cpoptions
set cpoptions&vim


let s:scriptPath = expand('<sfile>:p:h')

"  s:allColorSchemes {list}  <{name: 'string', light: 0|1}>
function s:ReadColorSchemesData()
    if !exists('s:allColorSchemes')
        return
    endif
    let jsonFile = s:scriptPath . '/colorschemes.json'
    if filereadable(jsonFile)
        let lines = readfile(jsonFile)
        let content = join(lines, '')
        let schemeList = json_decode(content)
        let s:allColorSchemes = schemeList
    else
        echo 'file not filereadable'
    endif
    let s:allColorSchemes = []
endfunction



if exists('g:favorite_color_schemes')
    let s:favoriteColorSchemes = g:favorite_color_schemes
elseif exists('g:random_color_schemes')
    " compatible with old setting
    let s:favoriteColorSchemes = g:random_color_schemes
else
    let s:favoriteColorSchemes = []
endif


"==============================================================================
" RandomNumber is taken from
" https://github.com/dahu/vim-rng/blob/master/plugin/rng.vim
"==============================================================================
let s:m_w = 1 + getpid()
let s:m_z = localtime()

" not sure of the wisdom of generating a full 32-bit RN here
" and then using abs() on the sucker. Feedback welcome.
function! s:RandomNumber(...)
  if a:0 == 0
    let s:m_z = (36969 * and(s:m_z, 0xffff)) + (s:m_z / 65536)
    let s:m_w = (18000 * and(s:m_w, 0xffff)) + (s:m_w / 65536)
    return (s:m_z * 65536) + s:m_w      " 32-bit result
  elseif a:0 == 1 " We return a number in [0, a:1] or [a:1, 0]
    return a:1 < 0 ? s:RandomNumber(a:1,0) : s:RandomNumber(0,a:1)
  else " if a:2 >= 2
    return abs(s:RandomNumber()) % (abs(a:2 - a:1) + 1) + a:1
  endif
endfunction
" end RNG }}}
"============


"@param {Integer} max
"@return {Integer} return a integer between [0, max - 1]
function! s:RandomInt(max)
    let randomInt = 0

    if a:max > 0
        let randomInt = s:RandomNumber(a:max * 8) % a:max
    endif

    return randomInt
endfunction


"@param {List} colorSchemes
function! s:RandomColorSchemes(colorSchemes)

    if empty(a:colorSchemes)
        return
    endif

    let item = remove(a:colorSchemes, 0)
    let color = item

    execute 'colo ' . color
endfunction

function! s:UniqueList(list)
    let newList = []

    for item in a:list
        if index(newList, item) == -1
            call add(newList, item)
        endif
    endfor

    return newList
endfunction

"@param {List} theList
"@return {List}
function! s:RandomOrder(theList, isUnique)
    if a:isUnique
        let uniqueArr = a:theList
    else
        let uniqueArr = s:UniqueList(a:theList)
    endif

    let length = len(uniqueArr)
    let newList = []
    let counter = 0

    while counter < length
        let index = s:RandomInt(length)
        let item = get(uniqueArr, index)

        while index(newList, item) != -1
            let index = s:RandomInt(length)
            let item = get(uniqueArr, index)
        endwhile

        call add(newList, item)
        let counter = counter + 1
    endwhile

    return newList
endfunction


let s:allColorSchemesWithRandom = []
let s:allColorSchemeIndex = 0

" @param mode {string} 'light'/'dark'/''
function! s:RandomAll(mode)
    call s:ReadColorSchemesData()

    if empty(s:allColorSchemes)
      return
    endif

    if empty(s:allColorSchemesWithRandom)
        let s:allColorSchemesWithRandom = s:RandomOrder(s:allColorSchemes, 1)
    endif

    let length = len(s:allColorSchemesWithRandom)
    let found = -1

    let loopCount = 0

    while found == -1 && loopCount < length
        let loopCount += 1

        let index = (s:allColorSchemeIndex + length) % length
        let item = get(s:allColorSchemesWithRandom, index)
        let name = get(item, 'name', '')
        let isLight = get(item, 'light', 0)

        if a:mode ==# 'light'
            if isLight
                let found = name
            endif
        elseif a:mode ==# 'dark'
            if !isLight
                let found = name
            endif
        else
            let found = name
        endif

        let s:allColorSchemeIndex = index + 1
    endwhile

    if found == -1 || found ==# ''
        echomsg 'Failed to find a matched scheme'
    else
        execute 'colo ' . found
    endif

endfunction


let s:favoriteColorSchemesWithRandom = []

" @param mode {string} 'light'/'dark'/''
function! s:RandomFavorite(mode)
    if empty(s:favoriteColorSchemes)
        return
    endif
    if empty(s:favoriteColorSchemesWithRandom)
        let s:favoriteColorSchemesWithRandom = s:RandomOrder(s:favoriteColorSchemes, 0)
    endif
    call s:RandomColorSchemes(s:favoriteColorSchemesWithRandom)
endfunction



if exists('g:favorite_gui_fonts') == 0 || empty('g:favorite_gui_fonts')
    let g:favorite_gui_fonts = [
                \ 'Monaco:h12',
                \ 'Fira\ Code:h12',
                \ 'Cascadia\ Code:h12',
                \ 'Ubuntu\ Mono:h14',
                \ 'Inconsolata:h13',
                \ 'Source\ Code\ Variable:h12',
                \ 'JetBrains\ Mono:h13',
                \ 'Consolas:h13'
                \]
endif


" @see https://forum.ubuntu.com.cn/viewtopic.php?t=45358
" @see :help setting-guifont
" @params {string} guifont  font:h14 格式
function! s:SetGuiFont(guifont)
    if has('gui_running')
        let splitted = split(a:guifont, ':h')
        if len(splitted) != 2
            return
        endif
        let font = splitted[0]
        let size= splitted[1]
        " for ubuntu vim-gonme
        if has('x11')
            let commandStr = 'set guifont=' . font . '\ ' . size
            execute commandStr
        else
            let commandStr = 'set guifont=' . font . ':h' . size
            execute commandStr
        endif
    endif
endfunction



let s:fontSwitchIndex = s:RandomInt(len(g:favorite_gui_fonts))
function! s:SwitchFont()
    if exists('g:favorite_gui_fonts') == 0 ||  empty('g:favorite_gui_fonts')
        return
    endif
    let length = len(g:favorite_gui_fonts)
    let index = s:fontSwitchIndex % length
    let guifont = get(g:favorite_gui_fonts, index)
    let s:fontSwitchIndex = index + 1
    call s:SetGuiFont(guifont)
endfunction


function s:RandomTheme(...)
    let mode = ''

    if a:0 == 1
        let mode = a:1
    endif

    call s:RandomAll(mode)
    call s:SwitchFont()
endfunction

function s:RandomFavoriteTheme()
    if empty(s:favoriteColorSchemes)
        return
    endif
    call s:RandomFavorite()
    call s:SwitchFont()
endfunction

function RandomThemeCompleter(A, L, P)
    let modes = ['dark', 'light']
    let trimed = trim(a:A)
    let length = len(trimed)

    if length == 0
        return modes
    else
        for item in modes
            if stridx(item, trimed) > -1 && len(item) > length
                return [item]
            endif
        endfor
    endif

    return []
endfunction

command! -nargs=0 RandomFont call s:SwitchFont()
command! -nargs=? -complete=customlist,RandomThemeCompleter RandomTheme call s:RandomTheme(<f-args>)
command! -nargs=0 RandomThemeFavorite call s:RandomFavoriteTheme()


let s:randomOnStart = 1
if exists('g:random_theme_start')
    let s:randomOnStart = g:random_theme_start
endif

if s:randomOnStart != 0
    let guiRunning = has('gui_running')
    if s:randomOnStart == 2
        if guiRunning
            execute ':RandomTheme'
        endif
    elseif s:randomOnStart == 3
        if !guiRunning
            execute ':RandomTheme'
        endif
    else
        execute ':RandomTheme'
    endif
endif

let &cpoptions = s:save_cpo


