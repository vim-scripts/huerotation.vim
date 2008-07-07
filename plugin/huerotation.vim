" huerotation.vim: rotate hue of current colorscheme (GUI only).
" Last Change: 2008-07-07
" Maintainer: Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License: This file is placed in the public domain.
"
" Description:
"   Hue is one of component of HSV color model.  You can rotate hue of current
"   colorscheme.
"
" Usage:
"   :call RotateHue(60)
"
" Reference:
"   EasyRGB - Color mathematics and conversion formulas.:
"     http://www.easyrgb.com/math.php
"   Wikipedia - HSL and HSV
"     http://en.wikipedia.org/wiki/HSL_and_HSV

function! RotateHue(degree)
  call s:lib.rotate_hue(a:degree)
endfunction

let s:lib = {}

function s:lib.rotate_hue(degree)
  for [name, fg, bg] in self.dump_highlight()
    if fg == ''
      let fg = synIDattr(hlID('Normal'), 'fg#')
      if fg == ''
        let fg = '#000000'
      endif
    endif
    if bg == ''
      let bg = synIDattr(hlID('Normal'), 'bg#')
      if bg == ''
        let bg = '#FFFFFF'
      endif
    endif
    let fg = self.rotate_hue_hex(fg, a:degree)
    let bg = self.rotate_hue_hex(bg, a:degree)
    let hl = printf('hi %s guifg=%s guibg=%s', name, fg, bg)
    execute hl
  endfor
endfunction

function s:lib.rotate_hue_hex(color, degree)
  let [_0, x, r, g, b; _] = matchlist(a:color, '\v(#)?(\x\x)(\x\x)(\x\x)')
  let r = str2nr(r, 16)
  let g = str2nr(g, 16)
  let b = str2nr(b, 16)
  let [r, g, b] = self.rotate_hue_rgb(r, g, b, a:degree)
  return printf("%s%02X%02X%02X", x, r, g, b)
endfunction

function s:lib.rotate_hue_rgb(r, g, b, degree)
  let [h, s, l] = self.rgb2hsl(a:r, a:g, a:b)
  let h = h + a:degree / 360.0
  while h > 1
    let h = h - 1.0
  endwhile
  while h < 0
    let h = h + 1.0
  endwhile
  return self.hsl2rgb(h, s, l)
endfunction

function s:lib.rgb2hsl(r, g, b)
  let var_r = a:r / 255.0
  let var_g = a:g / 255.0
  let var_b = a:b / 255.0

  let var_min = self.min([var_r, var_g, var_b])
  let var_max = self.max([var_r, var_g, var_b])
  let del_max = var_max - var_min

  let l = (var_max + var_min) / 2.0

  if del_max == 0
    let h = 0.0
    let s = 0.0
  else
    if l < 0.5
      let s = del_max / (var_max + var_min)
    else
      let s = del_max / ((2.0 - var_max) - var_min)
    endif

    let del_r = ((var_max - var_r) / 6.0 + del_max / 2.0) / del_max
    let del_g = ((var_max - var_g) / 6.0 + del_max / 2.0) / del_max
    let del_b = ((var_max - var_b) / 6.0 + del_max / 2.0) / del_max

    if var_r == var_max
      let h = del_b - del_g
    elseif var_g == var_max
      let h = (1.0 / 3.0) + del_r - del_b
    elseif var_b == var_max
      let h = (2.0 / 3.0) + del_g - del_r
    endif

    if h < 0
      let h = h + 1.0
    endif

    if h > 1
      let h = h - 1.0
    endif
  endif

  return [h, s, l]
endfunction

function s:lib.hsl2rgb(h, s, l)
  let [h, s, l] = [a:h, a:s, a:l]
  if s == 0
    let r = l * 255.0
    let g = l * 255.0
    let b = l * 255.0
  else
    if l < 0.5
      let var_2 = l * (1.0 + s)
    else
      let var_2 = (l + s) - s * l
    endif
    let var_1 = 2.0 * l - var_2
    let r = 255.0 * self.hue2rgb(var_1, var_2, h + (1.0 / 3.0))
    let g = 255.0 * self.hue2rgb(var_1, var_2, h)
    let b = 255.0 * self.hue2rgb(var_1, var_2, h - (1.0 / 3.0))
  endif
  return [float2nr(r), float2nr(g), float2nr(b)]
endfunction

function s:lib.hue2rgb(v1, v2, vh)
  let [v1, v2, vh] = [a:v1, a:v2, a:vh]
  if vh < 0
    let vh = vh + 1.0
  endif
  if vh > 1
    let vh = vh - 1.0
  endif
  if 6.0 * vh < 1
    return v1 + ((v2 - v1) * 6.0 * vh)
  elseif 2.0 * vh < 1
    return v2
  elseif 3.0 * vh < 2
    return v1 + ((v2 - v1) * (2.0 / 3.0 - vh) * 6.0)
  endif
  return v1
endfunction

function s:lib.dump_highlight()
  redir => str
  silent hi
  redir END
  let res = []
  for line in split(str, '\n')
    if line =~ '^\w'
      let name = matchstr(line, '^\w*')
      let fg = synIDattr(hlID(name), 'fg#')
      let bg = synIDattr(hlID(name), 'bg#')
      if fg != '' || bg != ''
        call add(res, [name, fg, bg])
      endif
    endif
  endfor
  return res
endfunction

" XXX: max() and min() don't work for Float.
function s:lib.max(lst)
  let a = a:lst[0]
  for n in a:lst
    if a < n
      let a = n
    endif
  endfor
  return a
endfunction

function s:lib.min(lst)
  let a = a:lst[0]
  for n in a:lst
    if a > n
      let a = n
    endif
  endfor
  return a
endfunction

