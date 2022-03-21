;=====================================================================
; ECOAR x86 - set line of picture either in black or white color, depending on the
; outcome of inequality 0.21R + 0.72G + 0.07B <= thresh
; Author: PJS_013
;=====================================================================

img_width		EQU 0
img_height		EQU 4
img_linebytes	EQU 8
img_pImg		EQU	12
img_RGBbmpHdr	EQU 16 ; not really used
red_coeff       EQU 21
green_coeff     EQU 72
blue_coeff      EQU 7

section	.text
global  get_and_set_color

get_and_set_color:
	push    ebp
	mov	    ebp, esp
	mov	    eax, [ebp + 8]	        ; eax <- address of imgInfo struct
	mov     ebx, [ebp+12]           ; ebx <- y
	mov     edi, [eax+img_linebytes] ; edi = linebytes
    imul    edi, ebx                ; edi = y * linebytes
    add     edi, [eax + img_pImg]   ; edi = pImg + y * linebytes
    mov     ecx, edi                ; ecx = pImg + y * linebytes

	mov     edx, [ebp + 16]	        ; ecx <- x_lower
	lea     edx, [2 * edx + edx]    ; ecx = 3 * x_lower
	add     edi, edx                ; edi = pImg + y * linebytes + 3 * x_lower

	mov     edx, [ebp + 20]         ; edx <- x_upper
	lea     edx, [2*edx+edx]        ; edx = 3 * x_upper
	add     ecx, edx                ; ecx = pImg + y * linebytes + 3 * x_upper
	sub     ecx, 3                  ; ecx = pImg + y * linebytes + 3 * x_upper - 3
	;if I don't substract 3 from the upper border, the loop changes also the first pixel
	;of next row of painting
	mov     esi, [ebp+24]           ; esi = thresh
    imul    esi, 100                ; esi = 100 * thresh

get_col:
    mov     ebx, 0                  ; cleaning ebx register
    mov     bl, BYTE[edi]           ; reading blue coefficient into ebx
    imul    edx, ebx, blue_coeff    ; multiplying blue coefficient by 7 and saving it in edx
    mov     ebx, 0                  ; cleaning ebx register
    mov     bl, BYTE[edi+1]         ; reading green coefficient into ebx
    imul    ebx, green_coeff        ; multiplying green coefficient by 72
    add     edx, ebx                ; adding content of ebx to content of edx
    mov     ebx, 0                  ; cleaning ebx register
    mov     bl, BYTE[edi+2]         ; reading red coefficient into ebx
    imul    ebx, red_coeff          ; multiplying red coefficient by 21
    add     edx, ebx                ; adding content of ebx to content of edx
    mov     ebx, 0                  ; cleaning ebx register

    cmp     edx, esi                ; if (edx <= esi ) so if sum of colors multiplied by coeffs<= 100*thresh
    jg      black                   ; set pixel to black
                                    ; else
    jmp     white                   ; set pixel to white
black:
    mov     BYTE[edi], 0x00         ; setting color of pixel to black
    mov     BYTE[edi + 1], 0x00
    mov     BYTE[edi + 2], 0x00
    jmp     if_next_pixel           ; go to if_next_pixel (so check if there is any more pixel in line to color
white:
    mov     BYTE[edi], 0xFF         ; setting color of pixel to white
    mov     BYTE[edi + 1], 0xFF
    mov     BYTE[edi + 2], 0xFF
    jmp     if_next_pixel           ; go to if_next_pixel
if_next_pixel:
    cmp     edi, ecx                ; if(edi<=ecx) so if adress of pixel is smaller than upper bound of adress
    jl      next_pixel              ; go to next_pixel
    jmp     end                     ; go to end
next_pixel:
    add     edi, 3                  ; increment adress of pixel
    jmp     get_col
end:
    pop	    ebp
    ret