; Visual C++ 6 runtime routines in bin/ds2wav.dll used by the engine
; Made by tools/disasm/make_listings.py from bin/ds2wav.dll (dumpbin /disasm).
; Notes after ';' are added: names of globals and calls, values of constants.

; ===== 10003060-10003087: _ftol: float to integer (truncating fistp qword)

; ---- _ftol ----
  10003060: 55                 push        ebp
  10003061: 8B EC              mov         ebp,esp
  10003063: 83 C4 F4           add         esp,0FFFFFFF4h
  10003066: 9B                 wait
  10003067: D9 7D FE           fnstcw      word ptr [ebp-2]
  1000306A: 9B                 wait
  1000306B: 66 8B 45 FE        mov         ax,word ptr [ebp-2]
  1000306F: 80 CC 0C           or          ah,0Ch
  10003072: 66 89 45 FC        mov         word ptr [ebp-4],ax
  10003076: D9 6D FC           fldcw       word ptr [ebp-4]
  10003079: DF 7D F4           fistp       qword ptr [ebp-0Ch]
  1000307C: D9 6D FE           fldcw       word ptr [ebp-2]
  1000307F: 8B 45 F4           mov         eax,dword ptr [ebp-0Ch]
  10003082: 8B 55 F8           mov         edx,dword ptr [ebp-8]
  10003085: C9                 leave
  10003086: C3                 ret

; ===== 100030CA-100030F2: _CIfmod entry and the fprem loop

; ---- _CIfmod ----
  100030CA: BA D0 F1 00 10     mov         edx,1000F1D0h
  100030CF: E9 5C 18 00 00     jmp         10004930
  100030D4: D9 C9              fxch        st(1)
  100030D6: 83 3D FC 24 01 10  cmp         dword ptr ds:[100124FCh],1
            01
  100030DD: 74 04              je          100030E3
  100030DF: D9 F8              fprem
  100030E1: EB 05              jmp         100030E8
  100030E3: E8 94 26 00 00     call        1000577C
  100030E8: 9B                 wait
  100030E9: DF E0              fnstsw      ax
  100030EB: 9B                 wait
  100030EC: 9E                 sahf
  100030ED: 7A E7              jp          100030D6
  100030EF: DD D9              fstp        st(1)
  100030F1: C3                 ret

; ===== 100032AA-100032D9: srand and rand (the seed is in the per-thread data, +14h)

; ---- srand ----
  100032AA: E8 62 49 00 00     call        10007C11
  100032AF: 8B 4C 24 04        mov         ecx,dword ptr [esp+4]
  100032B3: 89 48 14           mov         dword ptr [eax+14h],ecx
  100032B6: C3                 ret

; ---- rand ----
  100032B7: E8 55 49 00 00     call        10007C11
  100032BC: 8B 48 14           mov         ecx,dword ptr [eax+14h]
  100032BF: 69 C9 FD 43 03 00  imul        ecx,ecx,343FDh
  100032C5: 81 C1 C3 9E 26 00  add         ecx,269EC3h
  100032CB: 89 48 14           mov         dword ptr [eax+14h],ecx
  100032CE: 8B C1              mov         eax,ecx
  100032D0: C1 E8 10           shr         eax,10h
  100032D3: 25 FF 7F 00 00     and         eax,7FFFh
  100032D8: C3                 ret

; ===== 10003590-100037AD: _CIpow: argument checks, fyl2x, special cases, integer test

; ---- pow (_CIpow) ----
  10003590: 83 EC 10           sub         esp,10h
  10003593: D9 C9              fxch        st(1)
  10003595: DD 1C 24           fstp        qword ptr [esp]
  10003598: DD 54 24 08        fst         qword ptr [esp+8]
  1000359C: 8B 44 24 0C        mov         eax,dword ptr [esp+0Ch]
  100035A0: E8 0D 00 00 00     call        100035B2
  100035A5: 83 C4 10           add         esp,10h
  100035A8: C3                 ret
  100035A9: 8D 54 24 0C        lea         edx,[esp+0Ch]
  100035AD: E8 A3 51 00 00     call        10008755
  100035B2: 8B C8              mov         ecx,eax
  100035B4: 50                 push        eax
  100035B5: 9B                 wait
  100035B6: D9 3C 24           fnstcw      word ptr [esp]
  100035B9: 66 81 3C 24 7F 02  cmp         word ptr [esp],27Fh
  100035BF: 74 05              je          100035C6
  100035C1: E8 5F 51 00 00     call        10008725
  100035C6: 81 E1 00 00 F0 7F  and         ecx,7FF00000h
  100035CC: 8D 54 24 08        lea         edx,[esp+8]
  100035D0: 81 F9 00 00 F0 7F  cmp         ecx,7FF00000h
  100035D6: 0F 84 9D 00 00 00  je          10003679
  100035DC: E8 74 51 00 00     call        10008755
  100035E1: 0F 84 8E 00 00 00  je          10003675
  100035E7: A9 00 00 F0 7F     test        eax,7FF00000h
  100035EC: 0F 84 F6 00 00 00  je          100036E8
  100035F2: 8A 4C 24 0F        mov         cl,byte ptr [esp+0Fh]
  100035F6: 80 E1 80           and         cl,80h
  100035F9: 0F 85 61 01 00 00  jne         10003760
  100035FF: D9 F1              fyl2x
  10003601: E8 0A 51 00 00     call        10008710   ; 2^x (f2xm1, fscale)
  10003606: 80 F9 01           cmp         cl,1
  10003609: 75 02              jne         1000360D
  1000360B: D9 E0              fchs
  1000360D: 83 3D F8 24 01 10  cmp         dword ptr ds:[100124F8h],0
            00
  10003614: 0F 85 94 51 00 00  jne         100087AE
  1000361A: 8D 0D 28 F2 00 10  lea         ecx,ds:[1000F228h]
  10003620: BA 1D 00 00 00     mov         edx,1Dh
  10003625: E9 CF 51 00 00     jmp         100087F9
  1000362A: 83 3D F8 24 01 10  cmp         dword ptr ds:[100124F8h],0
            00
  10003631: 0F 85 77 51 00 00  jne         100087AE
  10003637: 8D 0D 28 F2 00 10  lea         ecx,ds:[1000F228h]
  1000363D: BA 1D 00 00 00     mov         edx,1Dh
  10003642: E8 69 50 00 00     call        100086B0
  10003647: 5A                 pop         edx
  10003648: C3                 ret
  10003649: 8D 54 24 08        lea         edx,[esp+8]
  1000364D: E8 03 51 00 00     call        10008755
  10003652: F6 44 24 16 08     test        byte ptr [esp+16h],8
  10003657: 75 03              jne         1000365C
  10003659: 41                 inc         ecx
  1000365A: EB 33              jmp         1000368F
  1000365C: DE C1              faddp       st(1),st
  1000365E: B8 01 00 00 00     mov         eax,1
  10003663: EB C5              jmp         1000362A
  10003665: F6 44 24 0E 08     test        byte ptr [esp+0Eh],8
  1000366A: 75 F0              jne         1000365C
  1000366C: DE C1              faddp       st(1),st
  1000366E: B8 07 00 00 00     mov         eax,7
  10003673: EB B5              jmp         1000362A
  10003675: 33 C9              xor         ecx,ecx
  10003677: EB 16              jmp         1000368F
  10003679: 33 C9              xor         ecx,ecx
  1000367B: 25 FF FF 0F 00     and         eax,0FFFFFh
  10003680: 0B 44 24 10        or          eax,dword ptr [esp+10h]
  10003684: 75 C3              jne         10003649
  10003686: 8D 54 24 08        lea         edx,[esp+8]
  1000368A: E8 C6 50 00 00     call        10008755
  1000368F: 8B 44 24 0C        mov         eax,dword ptr [esp+0Ch]
  10003693: 8B D0              mov         edx,eax
  10003695: 25 00 00 F0 7F     and         eax,7FF00000h
  1000369A: 81 E2 FF FF 0F 00  and         edx,0FFFFFh
  100036A0: 3D 00 00 F0 7F     cmp         eax,7FF00000h
  100036A5: 75 06              jne         100036AD
  100036A7: 0B 54 24 08        or          edx,dword ptr [esp+8]
  100036AB: 75 B8              jne         10003665
  100036AD: 85 C9              test        ecx,ecx
  100036AF: 75 BB              jne         1000366C
  100036B1: 83 EC 74           sub         esp,74h
  100036B4: 8B CC              mov         ecx,esp
  100036B6: 51                 push        ecx
  100036B7: 83 EC 10           sub         esp,10h
  100036BA: DD 1C 24           fstp        qword ptr [esp]
  100036BD: DD 5C 24 08        fstp        qword ptr [esp+8]
  100036C1: 9B                 wait
  100036C2: DD 71 08           fnsave      [ecx+8]
  100036C5: E8 D2 51 00 00     call        1000889C
  100036CA: 83 C4 10           add         esp,10h
  100036CD: 59                 pop         ecx
  100036CE: DD 61 08           frstor      [ecx+8]
  100036D1: DD 01              fld         qword ptr [ecx]
  100036D3: 83 C4 74           add         esp,74h
  100036D6: 85 C0              test        eax,eax
  100036D8: 0F 84 D0 50 00 00  je          100087AE
  100036DE: B8 01 00 00 00     mov         eax,1
  100036E3: E9 42 FF FF FF     jmp         1000362A
  100036E8: 8B 44 24 0C        mov         eax,dword ptr [esp+0Ch]
  100036EC: 25 FF FF 0F 00     and         eax,0FFFFFh
  100036F1: 0B 44 24 08        or          eax,dword ptr [esp+8]
  100036F5: 0F 85 F7 FE FF FF  jne         100035F2
  100036FB: DD D8              fstp        st(0)
  100036FD: 8B 44 24 14        mov         eax,dword ptr [esp+14h]
  10003701: A9 00 00 F0 7F     test        eax,7FF00000h
  10003706: 74 3D              je          10003745
  10003708: E8 78 00 00 00     call        10003785
  1000370D: 8A 6C 24 0F        mov         ch,byte ptr [esp+0Fh]
  10003711: C0 ED 07           shr         ch,7
  10003714: F7 44 24 17 80 00  test        dword ptr [esp+17h],80h
            00 00
  1000371C: 74 16              je          10003734
  1000371E: DB 2D 80 17 01 10  fld         tbyte ptr ds:[10011780h]
  10003724: 84 CD              test        ch,cl
  10003726: 74 02              je          1000372A
  10003728: D9 E0              fchs
  1000372A: B8 02 00 00 00     mov         eax,2
  1000372F: E9 F6 FE FF FF     jmp         1000362A
  10003734: D9 EE              fldz
  10003736: 84 CD              test        ch,cl
  10003738: 0F 84 70 50 00 00  je          100087AE
  1000373E: D9 E0              fchs
  10003740: E9 69 50 00 00     jmp         100087AE
  10003745: DD D8              fstp        st(0)
  10003747: 25 FF FF 0F 00     and         eax,0FFFFFh
  1000374C: 0B 44 24 10        or          eax,dword ptr [esp+10h]
  10003750: 75 07              jne         10003759
  10003752: D9 E8              fld1
  10003754: E9 55 50 00 00     jmp         100087AE
  10003759: D9 EE              fldz
  1000375B: E9 4E 50 00 00     jmp         100087AE
  10003760: D9 C1              fld         st(1)
  10003762: E8 1E 00 00 00     call        10003785
  10003767: D9 E0              fchs
  10003769: 84 C9              test        cl,cl
  1000376B: 0F 85 8E FE FF FF  jne         100035FF
  10003771: DD D8              fstp        st(0)
  10003773: DD D8              fstp        st(0)
  10003775: DB 2D 60 F2 00 10  fld         tbyte ptr ds:[1000F260h]
  1000377B: B8 01 00 00 00     mov         eax,1
  10003780: E9 A5 FE FF FF     jmp         1000362A
  10003785: D9 C0              fld         st(0)
  10003787: D9 FC              frndint
  10003789: D8 D9              fcomp       st(1)
  1000378B: B1 00              mov         cl,0
  1000378D: 9B                 wait
  1000378E: DF E0              fnstsw      ax
  10003790: 9E                 sahf
  10003791: 75 17              jne         100037AA
  10003793: DC 0D 20 F2 00 10  fmul        qword ptr ds:[1000F220h]
  10003799: FE C1              inc         cl
  1000379B: D9 C0              fld         st(0)
  1000379D: D9 FC              frndint
  1000379F: DE D9              fcompp
  100037A1: 9B                 wait
  100037A2: DF E0              fnstsw      ax
  100037A4: 9E                 sahf
  100037A5: 75 02              jne         100037A9
  100037A7: FE C1              inc         cl
  100037A9: C3                 ret
  100037AA: DD D8              fstp        st(0)
  100037AC: C3                 ret

; ===== 10004930-10004A57: the transcendental-function dispatcher used by _CIfmod

; ---- _trandisp2 (fmod dispatcher) ----
  10004930: 55                 push        ebp
  10004931: 8B EC              mov         ebp,esp
  10004933: 81 C4 30 FD FF FF  add         esp,0FFFFFD30h
  10004939: 53                 push        ebx
  1000493A: 9B                 wait
  1000493B: D9 BD 5C FF FF FF  fnstcw      word ptr [ebp+FFFFFF5Ch]
  10004941: 9B                 wait
  10004942: 83 3D E8 1F 01 10  cmp         dword ptr ds:[10011FE8h],0
            00
  10004949: 74 14              je          1000495F
  1000494B: E8 B7 02 00 00     call        10004C07   ; _ctrandisp classification
  10004950: 80 8D 38 FD FF FF  or          byte ptr [ebp+FFFFFD38h],3
            03
  10004957: E8 9E 00 00 00     call        100049FA
  1000495C: 5B                 pop         ebx
  1000495D: C9                 leave
  1000495E: C3                 ret
  1000495F: D9 C9              fxch        st(1)
  10004961: DD 95 7A FF FF FF  fst         qword ptr [ebp+FFFFFF7Ah]
  10004967: D9 C9              fxch        st(1)
  10004969: DD 55 82           fst         qword ptr [ebp-7Eh]
  1000496C: EB DD              jmp         1000494B
  1000496E: 55                 push        ebp
  1000496F: 8B EC              mov         ebp,esp
  10004971: 81 C4 30 FD FF FF  add         esp,0FFFFFD30h
  10004977: 53                 push        ebx
  10004978: 9B                 wait
  10004979: D9 BD 5C FF FF FF  fnstcw      word ptr [ebp+FFFFFF5Ch]
  1000497F: 83 3D E8 1F 01 10  cmp         dword ptr ds:[10011FE8h],0
            00
  10004986: 74 1B              je          100049A3
  10004988: E8 13 02 00 00     call        10004BA0
  1000498D: 80 8D 38 FD FF FF  or          byte ptr [ebp+FFFFFD38h],1
            01
  10004994: 80 A5 38 FD FF FF  and         byte ptr [ebp+FFFFFD38h],0FDh
            FD
  1000499B: E8 5A 00 00 00     call        100049FA
  100049A0: 5B                 pop         ebx
  100049A1: C9                 leave
  100049A2: C3                 ret
  100049A3: DD 95 7A FF FF FF  fst         qword ptr [ebp+FFFFFF7Ah]
  100049A9: EB DD              jmp         10004988
  100049AB: 55                 push        ebp
  100049AC: 8B EC              mov         ebp,esp
  100049AE: 81 C4 30 FD FF FF  add         esp,0FFFFFD30h
  100049B4: 53                 push        ebx
  100049B5: FF 75 0C           push        dword ptr [ebp+0Ch]
  100049B8: FF 75 08           push        dword ptr [ebp+8]
  100049BB: E8 9E 01 00 00     call        10004B5E
  100049C0: 83 C4 08           add         esp,8
  100049C3: FF 75 14           push        dword ptr [ebp+14h]
  100049C6: FF 75 10           push        dword ptr [ebp+10h]
  100049C9: E8 90 01 00 00     call        10004B5E
  100049CE: 83 C4 08           add         esp,8
  100049D1: 9B                 wait
  100049D2: D9 BD 5C FF FF FF  fnstcw      word ptr [ebp+FFFFFF5Ch]
  100049D8: 80 8D 38 FD FF FF  or          byte ptr [ebp+FFFFFD38h],2
            02
  100049DF: C6 85 71 FF FF FF  mov         byte ptr [ebp+FFFFFF71h],1
            01
  100049E6: E8 1C 02 00 00     call        10004C07   ; _ctrandisp classification
  100049EB: E8 03 00 00 00     call        100049F3
  100049F0: 5B                 pop         ebx
  100049F1: C9                 leave
  100049F2: C3                 ret
  100049F3: 80 A5 38 FD FF FF  and         byte ptr [ebp+FFFFFD38h],0FEh
            FE
  100049FA: 83 3D F8 24 01 10  cmp         dword ptr ds:[100124F8h],0
            00
  10004A01: 75 4C              jne         10004A4F
  10004A03: DD 95 30 FD FF FF  fst         qword ptr [ebp+FFFFFD30h]
  10004A09: 8A 85 70 FF FF FF  mov         al,byte ptr [ebp+FFFFFF70h]
  10004A0F: 0A C0              or          al,al
  10004A11: 74 1A              je          10004A2D
  10004A13: 3C FF              cmp         al,0FFh
  10004A15: 74 40              je          10004A57
  10004A17: 3C FE              cmp         al,0FEh
  10004A19: 74 3C              je          10004A57
  10004A1B: 0A C0              or          al,al
  10004A1D: 74 30              je          10004A4F
  10004A1F: 0F BE C0           movsx       eax,al
  10004A22: 89 85 72 FF FF FF  mov         dword ptr [ebp+FFFFFF72h],eax
  10004A28: E9 9C 00 00 00     jmp         10004AC9
  10004A2D: 66 8B 85 5C FF FF  mov         ax,word ptr [ebp+FFFFFF5Ch]
            FF
  10004A34: 66 83 E0 20        and         ax,20h
  10004A38: 75 15              jne         10004A4F
  10004A3A: 9B                 wait
  10004A3B: DF E0              fnstsw      ax
  10004A3D: 66 83 E0 20        and         ax,20h
  10004A41: 74 0C              je          10004A4F
  10004A43: C7 85 72 FF FF FF  mov         dword ptr [ebp+FFFFFF72h],8
            08 00 00 00
  10004A4D: EB 7A              jmp         10004AC9
  10004A4F: D9 AD 5C FF FF FF  fldcw       word ptr [ebp+FFFFFF5Ch]
  10004A55: 9B                 wait
  10004A56: C3                 ret

; ===== 10004C07-10004D6A: argument classification with fxam and the result handlers

; ---- _ctrandisp classification ----
  10004C07: 80 7A 0E 05        cmp         byte ptr [edx+0Eh],5
  10004C0B: 75 11              jne         10004C1E
  10004C0D: 66 8B 9D 5C FF FF  mov         bx,word ptr [ebp+FFFFFF5Ch]
            FF
  10004C14: 80 CF 02           or          bh,2
  10004C17: 80 E7 FE           and         bh,0FEh
  10004C1A: B3 3F              mov         bl,3Fh
  10004C1C: EB 04              jmp         10004C22
  10004C1E: 66 BB 3F 13        mov         bx,133Fh
  10004C22: 66 89 9D 5E FF FF  mov         word ptr [ebp+FFFFFF5Eh],bx
            FF
  10004C29: D9 AD 5E FF FF FF  fldcw       word ptr [ebp+FFFFFF5Eh]
  10004C2F: BB 7C F2 00 10     mov         ebx,1000F27Ch
  10004C34: D9 E5              fxam
  10004C36: 89 95 6C FF FF FF  mov         dword ptr [ebp+FFFFFF6Ch],edx
  10004C3C: 9B                 wait
  10004C3D: DD BD 60 FF FF FF  fnstsw      word ptr [ebp+FFFFFF60h]
  10004C43: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],0
            00
  10004C4A: D9 C9              fxch        st(1)
  10004C4C: 8A 8D 61 FF FF FF  mov         cl,byte ptr [ebp+FFFFFF61h]
  10004C52: D9 E5              fxam
  10004C54: 9B                 wait
  10004C55: DD BD 60 FF FF FF  fnstsw      word ptr [ebp+FFFFFF60h]
  10004C5B: D9 C9              fxch        st(1)
  10004C5D: 8A AD 61 FF FF FF  mov         ch,byte ptr [ebp+FFFFFF61h]
  10004C63: D0 E5              shl         ch,1
  10004C65: D0 FD              sar         ch,1
  10004C67: D0 C5              rol         ch,1
  10004C69: 8A C5              mov         al,ch
  10004C6B: 24 0F              and         al,0Fh
  10004C6D: D7                 xlat        byte ptr [ebx]
  10004C6E: 8A E0              mov         ah,al
  10004C70: D0 E1              shl         cl,1
  10004C72: D0 F9              sar         cl,1
  10004C74: D0 C1              rol         cl,1
  10004C76: 8A C1              mov         al,cl
  10004C78: 24 0F              and         al,0Fh
  10004C7A: D7                 xlat        byte ptr [ebx]
  10004C7B: D0 E4              shl         ah,1
  10004C7D: D0 E4              shl         ah,1
  10004C7F: 0A C4              or          al,ah
  10004C81: 0F BE C0           movsx       eax,al
  10004C84: 81 E1 04 04 00 00  and         ecx,404h
  10004C8A: 8B DA              mov         ebx,edx
  10004C8C: 03 D8              add         ebx,eax
  10004C8E: 83 C3 10           add         ebx,10h
  10004C91: FF 23              jmp         dword ptr [ebx]
  10004C93: E8 C1 00 00 00     call        10004D59
  10004C98: D9 C9              fxch        st(1)
  10004C9A: DD D8              fstp        st(0)
  10004C9C: C3                 ret
  10004C9D: E8 B7 00 00 00     call        10004D59
  10004CA2: EB F6              jmp         10004C9A
  10004CA4: DD D8              fstp        st(0)
  10004CA6: DD D8              fstp        st(0)
  10004CA8: D9 EE              fldz
  10004CAA: C3                 ret
  10004CAB: DD D8              fstp        st(0)
  10004CAD: DD D8              fstp        st(0)
  10004CAF: D9 E8              fld1
  10004CB1: C3                 ret
  10004CB2: DB BD 62 FF FF FF  fstp        tbyte ptr [ebp+FFFFFF62h]
  10004CB8: DB AD 62 FF FF FF  fld         tbyte ptr [ebp+FFFFFF62h]
  10004CBE: F6 85 69 FF FF FF  test        byte ptr [ebp+FFFFFF69h],40h
            40
  10004CC5: 74 08              je          10004CCF
  10004CC7: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],7
            07
  10004CCE: C3                 ret
  10004CCF: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],1
            01
  10004CD6: DC 05 74 F2 00 10  fadd        qword ptr ds:[1000F274h]
  10004CDC: C3                 ret
  10004CDD: D9 C9              fxch        st(1)
  10004CDF: DB BD 62 FF FF FF  fstp        tbyte ptr [ebp+FFFFFF62h]
  10004CE5: DB AD 62 FF FF FF  fld         tbyte ptr [ebp+FFFFFF62h]
  10004CEB: F6 85 69 FF FF FF  test        byte ptr [ebp+FFFFFF69h],40h
            40
  10004CF2: 74 09              je          10004CFD
  10004CF4: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],7
            07
  10004CFB: EB 07              jmp         10004D04
  10004CFD: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],1
            01
  10004D04: DE C1              faddp       st(1),st
  10004D06: C3                 ret
  10004D07: DB BD 62 FF FF FF  fstp        tbyte ptr [ebp+FFFFFF62h]
  10004D0D: DB AD 62 FF FF FF  fld         tbyte ptr [ebp+FFFFFF62h]
  10004D13: F6 85 69 FF FF FF  test        byte ptr [ebp+FFFFFF69h],40h
            40
  10004D1A: 74 20              je          10004D3C
  10004D1C: D9 C9              fxch        st(1)
  10004D1E: DB BD 62 FF FF FF  fstp        tbyte ptr [ebp+FFFFFF62h]
  10004D24: DB AD 62 FF FF FF  fld         tbyte ptr [ebp+FFFFFF62h]
  10004D2A: F6 85 69 FF FF FF  test        byte ptr [ebp+FFFFFF69h],40h
            40
  10004D31: 74 09              je          10004D3C
  10004D33: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],7
            07
  10004D3A: EB 07              jmp         10004D43
  10004D3C: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],1
            01
  10004D43: DE C1              faddp       st(1),st
  10004D45: C3                 ret
  10004D46: DD D8              fstp        st(0)
  10004D48: DD D8              fstp        st(0)
  10004D4A: DB 2D 60 F2 00 10  fld         tbyte ptr ds:[1000F260h]
  10004D50: 80 BD 70 FF FF FF  cmp         byte ptr [ebp+FFFFFF70h],0
            00
  10004D57: 7F 07              jg          10004D60
  10004D59: C6 85 70 FF FF FF  mov         byte ptr [ebp+FFFFFF70h],1
            01
  10004D60: 0A C9              or          cl,cl
  10004D62: C3                 ret
  10004D63: 0A C9              or          cl,cl
  10004D65: 74 02              je          10004D69
  10004D67: D9 E0              fchs
  10004D69: C3                 ret

; ===== 100086B0-10008725: _CIpow: error report, and 2^x with f2xm1 and fscale (10008710)
  100086B0: 55                 push        ebp
  100086B1: 8B EC              mov         ebp,esp
  100086B3: 83 C4 E0           add         esp,0FFFFFFE0h
  100086B6: 89 45 E0           mov         dword ptr [ebp-20h],eax
  100086B9: 8B 45 18           mov         eax,dword ptr [ebp+18h]
  100086BC: 89 45 F0           mov         dword ptr [ebp-10h],eax
  100086BF: 8B 45 1C           mov         eax,dword ptr [ebp+1Ch]
  100086C2: 89 45 F4           mov         dword ptr [ebp-0Ch],eax
  100086C5: EB 09              jmp         100086D0
  100086C7: 55                 push        ebp
  100086C8: 8B EC              mov         ebp,esp
  100086CA: 83 C4 E0           add         esp,0FFFFFFE0h
  100086CD: 89 45 E0           mov         dword ptr [ebp-20h],eax
  100086D0: DD 5D F8           fstp        qword ptr [ebp-8]
  100086D3: 89 4D E4           mov         dword ptr [ebp-1Ch],ecx
  100086D6: 8B 45 10           mov         eax,dword ptr [ebp+10h]
  100086D9: 8B 4D 14           mov         ecx,dword ptr [ebp+14h]
  100086DC: 89 45 E8           mov         dword ptr [ebp-18h],eax
  100086DF: 89 4D EC           mov         dword ptr [ebp-14h],ecx
  100086E2: 8D 45 08           lea         eax,[ebp+8]
  100086E5: 8D 4D E0           lea         ecx,[ebp-20h]
  100086E8: 50                 push        eax
  100086E9: 51                 push        ecx
  100086EA: 52                 push        edx
  100086EB: E8 49 1C 00 00     call        1000A339
  100086F0: 83 C4 0C           add         esp,0Ch
  100086F3: DD 45 F8           fld         qword ptr [ebp-8]
  100086F6: 66 81 7D 08 7F 02  cmp         word ptr [ebp+8],27Fh
  100086FC: 74 03              je          10008701
  100086FE: D9 6D 08           fldcw       word ptr [ebp+8]
  10008701: C9                 leave
  10008702: C3                 ret

; ---- 2^x (f2xm1, fscale) ----
  10008710: D9 C0              fld         st(0)
  10008712: D9 FC              frndint
  10008714: DC E1              fsubr       st(1),st
  10008716: D9 C9              fxch        st(1)
  10008718: D9 E0              fchs
  1000871A: D9 F0              f2xm1
  1000871C: D9 E8              fld1
  1000871E: DE C1              faddp       st(1),st
  10008720: D9 FD              fscale
  10008722: DD D9              fstp        st(1)
  10008724: C3                 ret

; ===== 10008725-1000889C: _CIpow: control word, argument load, result range check
  10008725: 8B 54 24 04        mov         edx,dword ptr [esp+4]
  10008729: 81 E2 00 03 00 00  and         edx,300h
  1000872F: 83 CA 7F           or          edx,7Fh
  10008732: 66 89 54 24 06     mov         word ptr [esp+6],dx
  10008737: D9 6C 24 06        fldcw       word ptr [esp+6]
  1000873B: C3                 ret
  1000873C: A9 00 00 08 00     test        eax,80000h
  10008741: 74 06              je          10008749
  10008743: B8 07 00 00 00     mov         eax,7
  10008748: C3                 ret
  10008749: DC 05 70 E3 00 10  fadd        qword ptr ds:[1000E370h]   ; double 1.0
  1000874F: B8 01 00 00 00     mov         eax,1
  10008754: C3                 ret
  10008755: 8B 42 04           mov         eax,dword ptr [edx+4]
  10008758: 25 00 00 F0 7F     and         eax,7FF00000h
  1000875D: 3D 00 00 F0 7F     cmp         eax,7FF00000h
  10008762: 74 03              je          10008767
  10008764: DD 02              fld         qword ptr [edx]
  10008766: C3                 ret
  10008767: 8B 42 04           mov         eax,dword ptr [edx+4]
  1000876A: 83 EC 0A           sub         esp,0Ah
  1000876D: 0D 00 00 FF 7F     or          eax,7FFF0000h
  10008772: 89 44 24 06        mov         dword ptr [esp+6],eax
  10008776: 8B 42 04           mov         eax,dword ptr [edx+4]
  10008779: 8B 0A              mov         ecx,dword ptr [edx]
  1000877B: 0F A4 C8 0B        shld        eax,ecx,0Bh
  1000877F: C1 E1 0B           shl         ecx,0Bh
  10008782: 89 44 24 04        mov         dword ptr [esp+4],eax
  10008786: 89 0C 24           mov         dword ptr [esp],ecx
  10008789: DB 2C 24           fld         tbyte ptr [esp]
  1000878C: 83 C4 0A           add         esp,0Ah
  1000878F: A9 00 00 00 00     test        eax,0
  10008794: 8B 42 04           mov         eax,dword ptr [edx+4]
  10008797: C3                 ret
  10008798: 8B 44 24 08        mov         eax,dword ptr [esp+8]
  1000879C: 25 00 00 F0 7F     and         eax,7FF00000h
  100087A1: 3D 00 00 F0 7F     cmp         eax,7FF00000h
  100087A6: 74 01              je          100087A9
  100087A8: C3                 ret
  100087A9: 8B 44 24 08        mov         eax,dword ptr [esp+8]
  100087AD: C3                 ret
  100087AE: 66 81 3C 24 7F 02  cmp         word ptr [esp],27Fh
  100087B4: 74 03              je          100087B9
  100087B6: D9 2C 24           fldcw       word ptr [esp]
  100087B9: 5A                 pop         edx
  100087BA: C3                 ret
  100087BB: 66 8B 04 24        mov         ax,word ptr [esp]
  100087BF: 66 3D 7F 02        cmp         ax,27Fh
  100087C3: 74 1E              je          100087E3
  100087C5: 66 83 E0 20        and         ax,20h
  100087C9: 74 15              je          100087E0
  100087CB: 9B                 wait
  100087CC: DF E0              fnstsw      ax
  100087CE: 66 83 E0 20        and         ax,20h
  100087D2: 74 0C              je          100087E0
  100087D4: B8 08 00 00 00     mov         eax,8
  100087D9: E8 E9 FE FF FF     call        100086C7
  100087DE: 5A                 pop         edx
  100087DF: C3                 ret
  100087E0: D9 2C 24           fldcw       word ptr [esp]
  100087E3: 5A                 pop         edx
  100087E4: C3                 ret
  100087E5: 83 EC 08           sub         esp,8
  100087E8: DD 14 24           fst         qword ptr [esp]
  100087EB: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  100087EF: 83 C4 08           add         esp,8
  100087F2: 25 00 00 F0 7F     and         eax,7FF00000h
  100087F7: EB 14              jmp         1000880D
  100087F9: 83 EC 08           sub         esp,8
  100087FC: DD 14 24           fst         qword ptr [esp]
  100087FF: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  10008803: 83 C4 08           add         esp,8
  10008806: 25 00 00 F0 7F     and         eax,7FF00000h
  1000880B: 74 3D              je          1000884A
  1000880D: 3D 00 00 F0 7F     cmp         eax,7FF00000h
  10008812: 74 5F              je          10008873
  10008814: 66 8B 04 24        mov         ax,word ptr [esp]
  10008818: 66 3D 7F 02        cmp         ax,27Fh
  1000881C: 74 2A              je          10008848
  1000881E: 66 83 E0 20        and         ax,20h
  10008822: 75 21              jne         10008845
  10008824: 9B                 wait
  10008825: DF E0              fnstsw      ax
  10008827: 66 83 E0 20        and         ax,20h
  1000882B: 74 18              je          10008845
  1000882D: B8 08 00 00 00     mov         eax,8
  10008832: 83 FA 1D           cmp         edx,1Dh
  10008835: 74 07              je          1000883E
  10008837: E8 8B FE FF FF     call        100086C7
  1000883C: 5A                 pop         edx
  1000883D: C3                 ret
  1000883E: E8 6D FE FF FF     call        100086B0
  10008843: 5A                 pop         edx
  10008844: C3                 ret
  10008845: D9 2C 24           fldcw       word ptr [esp]
  10008848: 5A                 pop         edx
  10008849: C3                 ret
  1000884A: DD 05 9C E3 00 10  fld         qword ptr ds:[1000E39Ch]   ; double 1536.0
  10008850: D9 C9              fxch        st(1)
  10008852: D9 FD              fscale
  10008854: DD D9              fstp        st(1)
  10008856: D9 C0              fld         st(0)
  10008858: D9 E1              fabs
  1000885A: DC 1D 8C E3 00 10  fcomp       qword ptr ds:[1000E38Ch]   ; double 2.2250738585072014e-308
  10008860: 9B                 wait
  10008861: DF E0              fnstsw      ax
  10008863: 9E                 sahf
  10008864: B8 04 00 00 00     mov         eax,4
  10008869: 73 C7              jae         10008832
  1000886B: DC 0D AC E3 00 10  fmul        qword ptr ds:[1000E3ACh]   ; double 0.0
  10008871: EB BF              jmp         10008832
  10008873: DD 05 94 E3 00 10  fld         qword ptr ds:[1000E394h]   ; double -1536.0
  10008879: D9 C9              fxch        st(1)
  1000887B: D9 FD              fscale
  1000887D: DD D9              fstp        st(1)
  1000887F: D9 C0              fld         st(0)
  10008881: D9 E1              fabs
  10008883: DC 1D 84 E3 00 10  fcomp       qword ptr ds:[1000E384h]   ; double 1.7976931348623157e+308
  10008889: 9B                 wait
  1000888A: DF E0              fnstsw      ax
  1000888C: 9E                 sahf
  1000888D: B8 03 00 00 00     mov         eax,3
  10008892: 76 9E              jbe         10008832
  10008894: DC 0D A4 E3 00 10  fmul        qword ptr ds:[1000E3A4h]   ; double inf
  1000889A: EB 96              jmp         10008832

; ===== 10003A8F-10003ACD: _fassign: sscanf's %f store

; ---- _fassign ----
  10003A8F: 55                 push        ebp
  10003A90: 8B EC              mov         ebp,esp
  10003A92: 51                 push        ecx
  10003A93: 51                 push        ecx
  10003A94: 83 7D 08 00        cmp         dword ptr [ebp+8],0
  10003A98: FF 75 10           push        dword ptr [ebp+10h]
  10003A9B: 74 1B              je          10003AB8
  10003A9D: 8D 45 F8           lea         eax,[ebp-8]
  10003AA0: 50                 push        eax
  10003AA1: E8 24 5F 00 00     call        100099CA
  10003AA6: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  10003AA9: 59                 pop         ecx
  10003AAA: 59                 pop         ecx
  10003AAB: 8B 4D F8           mov         ecx,dword ptr [ebp-8]
  10003AAE: 89 08              mov         dword ptr [eax],ecx
  10003AB0: 8B 4D FC           mov         ecx,dword ptr [ebp-4]
  10003AB3: 89 48 04           mov         dword ptr [eax+4],ecx
  10003AB6: C9                 leave
  10003AB7: C3                 ret
  10003AB8: 8D 45 10           lea         eax,[ebp+10h]
  10003ABB: 50                 push        eax
  10003ABC: E8 36 5F 00 00     call        100099F7   ; _atoflt
  10003AC1: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  10003AC4: 59                 pop         ecx
  10003AC5: 59                 pop         ecx
  10003AC6: 8B 4D 10           mov         ecx,dword ptr [ebp+10h]
  10003AC9: 89 08              mov         dword ptr [eax],ecx
  10003ACB: C9                 leave
  10003ACC: C3                 ret

; ===== 100099F7-10009A24: _atoflt: __strgtold12, then _ld12tof

; ---- _atoflt ----
  100099F7: 55                 push        ebp
  100099F8: 8B EC              mov         ebp,esp
  100099FA: 83 EC 0C           sub         esp,0Ch
  100099FD: 33 C0              xor         eax,eax
  100099FF: 50                 push        eax
  10009A00: 50                 push        eax
  10009A01: 50                 push        eax
  10009A02: 50                 push        eax
  10009A03: FF 75 0C           push        dword ptr [ebp+0Ch]
  10009A06: 8D 45 0C           lea         eax,[ebp+0Ch]
  10009A09: 50                 push        eax
  10009A0A: 8D 45 F4           lea         eax,[ebp-0Ch]
  10009A0D: 50                 push        eax
  10009A0E: E8 F4 25 00 00     call        1000C007   ; __strgtold12
  10009A13: FF 75 08           push        dword ptr [ebp+8]
  10009A16: 8D 45 F4           lea         eax,[ebp-0Ch]
  10009A19: 50                 push        eax
  10009A1A: E8 95 FF FF FF     call        100099B4   ; _ld12tof
  10009A1F: 83 C4 24           add         esp,24h
  10009A22: C9                 leave
  10009A23: C3                 ret

; ===== 1000C007-1000C4DC: __strgtold12: text to a 12-byte value (state machine)

; ---- __strgtold12 ----
  1000C007: 55                 push        ebp
  1000C008: 8B EC              mov         ebp,esp
  1000C00A: 83 EC 5C           sub         esp,5Ch
  1000C00D: 53                 push        ebx
  1000C00E: 56                 push        esi
  1000C00F: 57                 push        edi
  1000C010: 8B 7D 10           mov         edi,dword ptr [ebp+10h]
  1000C013: 8D 45 A4           lea         eax,[ebp-5Ch]
  1000C016: 6A 01              push        1
  1000C018: 89 45 F4           mov         dword ptr [ebp-0Ch],eax
  1000C01B: 33 C0              xor         eax,eax
  1000C01D: 5A                 pop         edx
  1000C01E: 89 45 D8           mov         dword ptr [ebp-28h],eax
  1000C021: 89 55 E8           mov         dword ptr [ebp-18h],edx
  1000C024: 89 45 FC           mov         dword ptr [ebp-4],eax
  1000C027: 89 45 F0           mov         dword ptr [ebp-10h],eax
  1000C02A: 89 45 DC           mov         dword ptr [ebp-24h],eax
  1000C02D: 89 45 E0           mov         dword ptr [ebp-20h],eax
  1000C030: 89 45 D4           mov         dword ptr [ebp-2Ch],eax
  1000C033: 89 45 D0           mov         dword ptr [ebp-30h],eax
  1000C036: 89 45 E4           mov         dword ptr [ebp-1Ch],eax
  1000C039: 89 45 F8           mov         dword ptr [ebp-8],eax
  1000C03C: 89 45 EC           mov         dword ptr [ebp-14h],eax
  1000C03F: 89 7D 10           mov         dword ptr [ebp+10h],edi
  1000C042: 8A 0F              mov         cl,byte ptr [edi]
  1000C044: 80 F9 20           cmp         cl,20h
  1000C047: 74 0F              je          1000C058
  1000C049: 80 F9 09           cmp         cl,9
  1000C04C: 74 0A              je          1000C058
  1000C04E: 80 F9 0A           cmp         cl,0Ah
  1000C051: 74 05              je          1000C058
  1000C053: 80 F9 0D           cmp         cl,0Dh
  1000C056: 75 03              jne         1000C05B
  1000C058: 47                 inc         edi
  1000C059: EB E7              jmp         1000C042
  1000C05B: 6A 04              push        4
  1000C05D: 5E                 pop         esi
  1000C05E: 8A 1F              mov         bl,byte ptr [edi]
  1000C060: 47                 inc         edi
  1000C061: 83 F8 0B           cmp         eax,0Bh
  1000C064: 0F 87 77 02 00 00  ja          1000C2E1
  1000C06A: FF 24 85 A8 C4 00  jmp         dword ptr [eax*4+1000C4A8h]
            10
  1000C071: 80 FB 31           cmp         bl,31h
  1000C074: 7C 0C              jl          1000C082
  1000C076: 80 FB 39           cmp         bl,39h
  1000C079: 7F 07              jg          1000C082
  1000C07B: 6A 03              push        3
  1000C07D: E9 1D 02 00 00     jmp         1000C29F
  1000C082: 3A 1D 9C 18 01 10  cmp         bl,byte ptr ds:[1001189Ch]
  1000C088: 75 07              jne         1000C091
  1000C08A: 6A 05              push        5
  1000C08C: E9 46 02 00 00     jmp         1000C2D7
  1000C091: 0F BE C3           movsx       eax,bl
  1000C094: 83 E8 2B           sub         eax,2Bh
  1000C097: 74 1E              je          1000C0B7
  1000C099: 48                 dec         eax
  1000C09A: 48                 dec         eax
  1000C09B: 74 0E              je          1000C0AB
  1000C09D: 83 E8 03           sub         eax,3
  1000C0A0: 0F 85 D4 02 00 00  jne         1000C37A
  1000C0A6: E9 8F 00 00 00     jmp         1000C13A
  1000C0AB: 6A 02              push        2
  1000C0AD: C7 45 D8 00 80 00  mov         dword ptr [ebp-28h],8000h
            00
  1000C0B4: 58                 pop         eax
  1000C0B5: EB A7              jmp         1000C05E
  1000C0B7: 83 65 D8 00        and         dword ptr [ebp-28h],0
  1000C0BB: 6A 02              push        2
  1000C0BD: 58                 pop         eax
  1000C0BE: EB 9E              jmp         1000C05E
  1000C0C0: 80 FB 31           cmp         bl,31h
  1000C0C3: 89 55 F0           mov         dword ptr [ebp-10h],edx
  1000C0C6: 7C 05              jl          1000C0CD
  1000C0C8: 80 FB 39           cmp         bl,39h
  1000C0CB: 7E AE              jle         1000C07B
  1000C0CD: 3A 1D 9C 18 01 10  cmp         bl,byte ptr ds:[1001189Ch]
  1000C0D3: 0F 84 BC 00 00 00  je          1000C195
  1000C0D9: 80 FB 2B           cmp         bl,2Bh
  1000C0DC: 74 31              je          1000C10F
  1000C0DE: 80 FB 2D           cmp         bl,2Dh
  1000C0E1: 74 2C              je          1000C10F
  1000C0E3: 80 FB 30           cmp         bl,30h
  1000C0E6: 74 52              je          1000C13A
  1000C0E8: 80 FB 43           cmp         bl,43h
  1000C0EB: 0F 8E 89 02 00 00  jle         1000C37A
  1000C0F1: 80 FB 45           cmp         bl,45h
  1000C0F4: 7E 12              jle         1000C108
  1000C0F6: 80 FB 63           cmp         bl,63h
  1000C0F9: 0F 8E 7B 02 00 00  jle         1000C37A
  1000C0FF: 80 FB 65           cmp         bl,65h
  1000C102: 0F 8F 72 02 00 00  jg          1000C37A
  1000C108: 6A 06              push        6
  1000C10A: E9 C8 01 00 00     jmp         1000C2D7
  1000C10F: 4F                 dec         edi
  1000C110: 6A 0B              push        0Bh
  1000C112: E9 C0 01 00 00     jmp         1000C2D7
  1000C117: 80 FB 31           cmp         bl,31h
  1000C11A: 7C 09              jl          1000C125
  1000C11C: 80 FB 39           cmp         bl,39h
  1000C11F: 0F 8E 56 FF FF FF  jle         1000C07B
  1000C125: 3A 1D 9C 18 01 10  cmp         bl,byte ptr ds:[1001189Ch]
  1000C12B: 0F 84 59 FF FF FF  je          1000C08A
  1000C131: 80 FB 30           cmp         bl,30h
  1000C134: 0F 85 B5 01 00 00  jne         1000C2EF
  1000C13A: 8B C2              mov         eax,edx
  1000C13C: E9 1D FF FF FF     jmp         1000C05E
  1000C141: 89 55 F0           mov         dword ptr [ebp-10h],edx
  1000C144: 39 15 98 18 01 10  cmp         dword ptr ds:[10011898h],edx
  1000C14A: 7E 11              jle         1000C15D
  1000C14C: 0F B6 C3           movzx       eax,bl
  1000C14F: 56                 push        esi
  1000C150: 50                 push        eax
  1000C151: E8 33 D3 FF FF     call        10009489
  1000C156: 59                 pop         ecx
  1000C157: 59                 pop         ecx
  1000C158: 6A 01              push        1
  1000C15A: 5A                 pop         edx
  1000C15B: EB 0E              jmp         1000C16B
  1000C15D: 8B 0D A4 18 01 10  mov         ecx,dword ptr ds:[100118A4h]
  1000C163: 0F B6 C3           movzx       eax,bl
  1000C166: 8A 04 41           mov         al,byte ptr [ecx+eax*2]
  1000C169: 23 C6              and         eax,esi
  1000C16B: 85 C0              test        eax,eax
  1000C16D: 74 1E              je          1000C18D
  1000C16F: 83 7D FC 19        cmp         dword ptr [ebp-4],19h
  1000C173: 73 10              jae         1000C185
  1000C175: 8B 45 F4           mov         eax,dword ptr [ebp-0Ch]
  1000C178: FF 45 FC           inc         dword ptr [ebp-4]
  1000C17B: 80 EB 30           sub         bl,30h
  1000C17E: FF 45 F4           inc         dword ptr [ebp-0Ch]
  1000C181: 88 18              mov         byte ptr [eax],bl
  1000C183: EB 03              jmp         1000C188
  1000C185: FF 45 F8           inc         dword ptr [ebp-8]
  1000C188: 8A 1F              mov         bl,byte ptr [edi]
  1000C18A: 47                 inc         edi
  1000C18B: EB B7              jmp         1000C144
  1000C18D: 3A 1D 9C 18 01 10  cmp         bl,byte ptr ds:[1001189Ch]
  1000C193: 75 67              jne         1000C1FC
  1000C195: 8B C6              mov         eax,esi
  1000C197: E9 C2 FE FF FF     jmp         1000C05E
  1000C19C: 83 7D FC 00        cmp         dword ptr [ebp-4],0
  1000C1A0: 89 55 F0           mov         dword ptr [ebp-10h],edx
  1000C1A3: 89 55 DC           mov         dword ptr [ebp-24h],edx
  1000C1A6: 75 0D              jne         1000C1B5
  1000C1A8: 80 FB 30           cmp         bl,30h
  1000C1AB: 75 08              jne         1000C1B5
  1000C1AD: FF 4D F8           dec         dword ptr [ebp-8]
  1000C1B0: 8A 1F              mov         bl,byte ptr [edi]
  1000C1B2: 47                 inc         edi
  1000C1B3: EB F3              jmp         1000C1A8
  1000C1B5: 39 15 98 18 01 10  cmp         dword ptr ds:[10011898h],edx
  1000C1BB: 7E 11              jle         1000C1CE
  1000C1BD: 0F B6 C3           movzx       eax,bl
  1000C1C0: 56                 push        esi
  1000C1C1: 50                 push        eax
  1000C1C2: E8 C2 D2 FF FF     call        10009489
  1000C1C7: 59                 pop         ecx
  1000C1C8: 59                 pop         ecx
  1000C1C9: 6A 01              push        1
  1000C1CB: 5A                 pop         edx
  1000C1CC: EB 0E              jmp         1000C1DC
  1000C1CE: 8B 0D A4 18 01 10  mov         ecx,dword ptr ds:[100118A4h]
  1000C1D4: 0F B6 C3           movzx       eax,bl
  1000C1D7: 8A 04 41           mov         al,byte ptr [ecx+eax*2]
  1000C1DA: 23 C6              and         eax,esi
  1000C1DC: 85 C0              test        eax,eax
  1000C1DE: 74 1C              je          1000C1FC
  1000C1E0: 83 7D FC 19        cmp         dword ptr [ebp-4],19h
  1000C1E4: 73 11              jae         1000C1F7
  1000C1E6: 8B 45 F4           mov         eax,dword ptr [ebp-0Ch]
  1000C1E9: FF 45 FC           inc         dword ptr [ebp-4]
  1000C1EC: 80 EB 30           sub         bl,30h
  1000C1EF: FF 45 F4           inc         dword ptr [ebp-0Ch]
  1000C1F2: FF 4D F8           dec         dword ptr [ebp-8]
  1000C1F5: 88 18              mov         byte ptr [eax],bl
  1000C1F7: 8A 1F              mov         bl,byte ptr [edi]
  1000C1F9: 47                 inc         edi
  1000C1FA: EB B9              jmp         1000C1B5
  1000C1FC: 80 FB 2B           cmp         bl,2Bh
  1000C1FF: 0F 84 0A FF FF FF  je          1000C10F
  1000C205: 80 FB 2D           cmp         bl,2Dh
  1000C208: 0F 84 01 FF FF FF  je          1000C10F
  1000C20E: E9 D5 FE FF FF     jmp         1000C0E8
  1000C213: 39 15 98 18 01 10  cmp         dword ptr ds:[10011898h],edx
  1000C219: 89 55 DC           mov         dword ptr [ebp-24h],edx
  1000C21C: 7E 11              jle         1000C22F
  1000C21E: 0F B6 C3           movzx       eax,bl
  1000C221: 56                 push        esi
  1000C222: 50                 push        eax
  1000C223: E8 61 D2 FF FF     call        10009489
  1000C228: 59                 pop         ecx
  1000C229: 59                 pop         ecx
  1000C22A: 6A 01              push        1
  1000C22C: 5A                 pop         edx
  1000C22D: EB 0E              jmp         1000C23D
  1000C22F: 8B 0D A4 18 01 10  mov         ecx,dword ptr ds:[100118A4h]
  1000C235: 0F B6 C3           movzx       eax,bl
  1000C238: 8A 04 41           mov         al,byte ptr [ecx+eax*2]
  1000C23B: 23 C6              and         eax,esi
  1000C23D: 85 C0              test        eax,eax
  1000C23F: 0F 84 AA 00 00 00  je          1000C2EF
  1000C245: 8B C6              mov         eax,esi
  1000C247: EB 57              jmp         1000C2A0
  1000C249: 8D 4F FE           lea         ecx,[edi-2]
  1000C24C: 80 FB 31           cmp         bl,31h
  1000C24F: 89 4D 10           mov         dword ptr [ebp+10h],ecx
  1000C252: 7C 05              jl          1000C259
  1000C254: 80 FB 39           cmp         bl,39h
  1000C257: 7E 44              jle         1000C29D
  1000C259: 0F BE C3           movsx       eax,bl
  1000C25C: 83 E8 2B           sub         eax,2Bh
  1000C25F: 74 74              je          1000C2D5
  1000C261: 48                 dec         eax
  1000C262: 48                 dec         eax
  1000C263: 74 64              je          1000C2C9
  1000C265: 83 E8 03           sub         eax,3
  1000C268: 0F 85 0F 01 00 00  jne         1000C37D
  1000C26E: 6A 08              push        8
  1000C270: EB 65              jmp         1000C2D7
  1000C272: 89 55 E0           mov         dword ptr [ebp-20h],edx
  1000C275: 80 FB 30           cmp         bl,30h
  1000C278: 75 05              jne         1000C27F
  1000C27A: 8A 1F              mov         bl,byte ptr [edi]
  1000C27C: 47                 inc         edi
  1000C27D: EB F6              jmp         1000C275
  1000C27F: 80 FB 31           cmp         bl,31h
  1000C282: 0F 8C F2 00 00 00  jl          1000C37A
  1000C288: 80 FB 39           cmp         bl,39h
  1000C28B: 0F 8F E9 00 00 00  jg          1000C37A
  1000C291: EB 0A              jmp         1000C29D
  1000C293: 80 FB 31           cmp         bl,31h
  1000C296: 7C 0E              jl          1000C2A6
  1000C298: 80 FB 39           cmp         bl,39h
  1000C29B: 7F 09              jg          1000C2A6
  1000C29D: 6A 09              push        9
  1000C29F: 58                 pop         eax
  1000C2A0: 4F                 dec         edi
  1000C2A1: E9 B8 FD FF FF     jmp         1000C05E
  1000C2A6: 80 FB 30           cmp         bl,30h
  1000C2A9: 75 44              jne         1000C2EF
  1000C2AB: EB C1              jmp         1000C26E
  1000C2AD: 83 7D 20 00        cmp         dword ptr [ebp+20h],0
  1000C2B1: 74 2A              je          1000C2DD
  1000C2B3: 0F BE C3           movsx       eax,bl
  1000C2B6: 8D 4F FF           lea         ecx,[edi-1]
  1000C2B9: 83 E8 2B           sub         eax,2Bh
  1000C2BC: 89 4D 10           mov         dword ptr [ebp+10h],ecx
  1000C2BF: 74 14              je          1000C2D5
  1000C2C1: 48                 dec         eax
  1000C2C2: 48                 dec         eax
  1000C2C3: 0F 85 B4 00 00 00  jne         1000C37D
  1000C2C9: 83 4D E8 FF        or          dword ptr [ebp-18h],0FFFFFFFFh
  1000C2CD: 6A 07              push        7
  1000C2CF: 58                 pop         eax
  1000C2D0: E9 89 FD FF FF     jmp         1000C05E
  1000C2D5: 6A 07              push        7
  1000C2D7: 58                 pop         eax
  1000C2D8: E9 81 FD FF FF     jmp         1000C05E
  1000C2DD: 6A 0A              push        0Ah
  1000C2DF: 4F                 dec         edi
  1000C2E0: 58                 pop         eax
  1000C2E1: 83 F8 0A           cmp         eax,0Ah
  1000C2E4: 0F 84 95 00 00 00  je          1000C37F
  1000C2EA: E9 6F FD FF FF     jmp         1000C05E
  1000C2EF: 8B 7D 10           mov         edi,dword ptr [ebp+10h]
  1000C2F2: E9 88 00 00 00     jmp         1000C37F
  1000C2F7: C7 45 E0 01 00 00  mov         dword ptr [ebp-20h],1
            00
  1000C2FE: 33 F6              xor         esi,esi
  1000C300: 83 3D 98 18 01 10  cmp         dword ptr ds:[10011898h],1
            01
  1000C307: 7E 0F              jle         1000C318
  1000C309: 0F B6 C3           movzx       eax,bl
  1000C30C: 6A 04              push        4
  1000C30E: 50                 push        eax
  1000C30F: E8 75 D1 FF FF     call        10009489
  1000C314: 59                 pop         ecx
  1000C315: 59                 pop         ecx
  1000C316: EB 0F              jmp         1000C327
  1000C318: 8B 0D A4 18 01 10  mov         ecx,dword ptr ds:[100118A4h]
  1000C31E: 0F B6 C3           movzx       eax,bl
  1000C321: 8A 04 41           mov         al,byte ptr [ecx+eax*2]
  1000C324: 83 E0 04           and         eax,4
  1000C327: 85 C0              test        eax,eax
  1000C329: 74 1C              je          1000C347
  1000C32B: 0F BE CB           movsx       ecx,bl
  1000C32E: 8D 04 B6           lea         eax,[esi+esi*4]
  1000C331: 8D 74 41 D0        lea         esi,[ecx+eax*2-30h]
  1000C335: 81 FE 50 14 00 00  cmp         esi,1450h
  1000C33B: 7F 05              jg          1000C342
  1000C33D: 8A 1F              mov         bl,byte ptr [edi]
  1000C33F: 47                 inc         edi
  1000C340: EB BE              jmp         1000C300
  1000C342: BE 51 14 00 00     mov         esi,1451h
  1000C347: 89 75 E4           mov         dword ptr [ebp-1Ch],esi
  1000C34A: 83 3D 98 18 01 10  cmp         dword ptr ds:[10011898h],1
            01
  1000C351: 7E 0F              jle         1000C362
  1000C353: 0F B6 C3           movzx       eax,bl
  1000C356: 6A 04              push        4
  1000C358: 50                 push        eax
  1000C359: E8 2B D1 FF FF     call        10009489
  1000C35E: 59                 pop         ecx
  1000C35F: 59                 pop         ecx
  1000C360: EB 0F              jmp         1000C371
  1000C362: 8B 0D A4 18 01 10  mov         ecx,dword ptr ds:[100118A4h]
  1000C368: 0F B6 C3           movzx       eax,bl
  1000C36B: 8A 04 41           mov         al,byte ptr [ecx+eax*2]
  1000C36E: 83 E0 04           and         eax,4
  1000C371: 85 C0              test        eax,eax
  1000C373: 74 05              je          1000C37A
  1000C375: 8A 1F              mov         bl,byte ptr [edi]
  1000C377: 47                 inc         edi
  1000C378: EB D0              jmp         1000C34A
  1000C37A: 4F                 dec         edi
  1000C37B: EB 02              jmp         1000C37F
  1000C37D: 8B F9              mov         edi,ecx
  1000C37F: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  1000C382: 83 7D F0 00        cmp         dword ptr [ebp-10h],0
  1000C386: 89 38              mov         dword ptr [eax],edi
  1000C388: 0F 84 D9 00 00 00  je          1000C467
  1000C38E: 6A 18              push        18h
  1000C390: 58                 pop         eax
  1000C391: 39 45 FC           cmp         dword ptr [ebp-4],eax
  1000C394: 76 15              jbe         1000C3AB
  1000C396: 80 7D BB 05        cmp         byte ptr [ebp-45h],5
  1000C39A: 7C 03              jl          1000C39F
  1000C39C: FE 45 BB           inc         byte ptr [ebp-45h]
  1000C39F: 89 45 FC           mov         dword ptr [ebp-4],eax
  1000C3A2: 8B 45 F4           mov         eax,dword ptr [ebp-0Ch]
  1000C3A5: 48                 dec         eax
  1000C3A6: FF 45 F8           inc         dword ptr [ebp-8]
  1000C3A9: EB 03              jmp         1000C3AE
  1000C3AB: 8B 45 F4           mov         eax,dword ptr [ebp-0Ch]
  1000C3AE: 83 7D FC 00        cmp         dword ptr [ebp-4],0
  1000C3B2: 0F 86 A5 00 00 00  jbe         1000C45D
  1000C3B8: 48                 dec         eax
  1000C3B9: 80 38 00           cmp         byte ptr [eax],0
  1000C3BC: 75 08              jne         1000C3C6
  1000C3BE: FF 4D FC           dec         dword ptr [ebp-4]
  1000C3C1: FF 45 F8           inc         dword ptr [ebp-8]
  1000C3C4: EB F2              jmp         1000C3B8
  1000C3C6: 8D 45 C0           lea         eax,[ebp-40h]
  1000C3C9: 50                 push        eax
  1000C3CA: 8D 45 A4           lea         eax,[ebp-5Ch]
  1000C3CD: FF 75 FC           push        dword ptr [ebp-4]
  1000C3D0: 50                 push        eax
  1000C3D1: E8 6A FB FF FF     call        1000BF40   ; __mtold12
  1000C3D6: 8B 45 E4           mov         eax,dword ptr [ebp-1Ch]
  1000C3D9: 33 C9              xor         ecx,ecx
  1000C3DB: 83 C4 0C           add         esp,0Ch
  1000C3DE: 39 4D E8           cmp         dword ptr [ebp-18h],ecx
  1000C3E1: 7D 02              jge         1000C3E5
  1000C3E3: F7 D8              neg         eax
  1000C3E5: 03 45 F8           add         eax,dword ptr [ebp-8]
  1000C3E8: 39 4D E0           cmp         dword ptr [ebp-20h],ecx
  1000C3EB: 75 03              jne         1000C3F0
  1000C3ED: 03 45 18           add         eax,dword ptr [ebp+18h]
  1000C3F0: 39 4D DC           cmp         dword ptr [ebp-24h],ecx
  1000C3F3: 75 03              jne         1000C3F8
  1000C3F5: 2B 45 1C           sub         eax,dword ptr [ebp+1Ch]
  1000C3F8: 3D 50 14 00 00     cmp         eax,1450h
  1000C3FD: 7E 30              jle         1000C42F
  1000C3FF: C7 45 D4 01 00 00  mov         dword ptr [ebp-2Ch],1
            00
  1000C406: 8B 5D 10           mov         ebx,dword ptr [ebp+10h]
  1000C409: 8B 75 10           mov         esi,dword ptr [ebp+10h]
  1000C40C: 8B 45 10           mov         eax,dword ptr [ebp+10h]
  1000C40F: 8B 55 10           mov         edx,dword ptr [ebp+10h]
  1000C412: 83 7D D4 00        cmp         dword ptr [ebp-2Ch],0
  1000C416: 74 60              je          1000C478
  1000C418: 33 DB              xor         ebx,ebx
  1000C41A: B8 FF 7F 00 00     mov         eax,7FFFh
  1000C41F: BE 00 00 00 80     mov         esi,80000000h
  1000C424: 33 D2              xor         edx,edx
  1000C426: C7 45 EC 02 00 00  mov         dword ptr [ebp-14h],2
            00
  1000C42D: EB 5E              jmp         1000C48D
  1000C42F: 3D B0 EB FF FF     cmp         eax,0FFFFEBB0h
  1000C434: 7D 09              jge         1000C43F
  1000C436: C7 45 D0 01 00 00  mov         dword ptr [ebp-30h],1
            00
  1000C43D: EB C7              jmp         1000C406
  1000C43F: FF 75 14           push        dword ptr [ebp+14h]
  1000C442: 50                 push        eax
  1000C443: 8D 45 C0           lea         eax,[ebp-40h]
  1000C446: 50                 push        eax
  1000C447: E8 7E 10 00 00     call        1000D4CA   ; __multtenpow12
  1000C44C: 8B 55 C0           mov         edx,dword ptr [ebp-40h]
  1000C44F: 8B 5D C2           mov         ebx,dword ptr [ebp-3Eh]
  1000C452: 8B 75 C6           mov         esi,dword ptr [ebp-3Ah]
  1000C455: 8B 45 CA           mov         eax,dword ptr [ebp-36h]
  1000C458: 83 C4 0C           add         esp,0Ch
  1000C45B: EB B5              jmp         1000C412
  1000C45D: 33 D2              xor         edx,edx
  1000C45F: 33 C0              xor         eax,eax
  1000C461: 33 F6              xor         esi,esi
  1000C463: 33 DB              xor         ebx,ebx
  1000C465: EB AB              jmp         1000C412
  1000C467: 33 D2              xor         edx,edx
  1000C469: 33 C0              xor         eax,eax
  1000C46B: 33 F6              xor         esi,esi
  1000C46D: 33 DB              xor         ebx,ebx
  1000C46F: C7 45 EC 04 00 00  mov         dword ptr [ebp-14h],4
            00
  1000C476: EB 15              jmp         1000C48D
  1000C478: 83 7D D0 00        cmp         dword ptr [ebp-30h],0
  1000C47C: 74 0F              je          1000C48D
  1000C47E: 33 D2              xor         edx,edx
  1000C480: 33 C0              xor         eax,eax
  1000C482: 33 F6              xor         esi,esi
  1000C484: 33 DB              xor         ebx,ebx
  1000C486: C7 45 EC 01 00 00  mov         dword ptr [ebp-14h],1
            00
  1000C48D: 8B 4D 08           mov         ecx,dword ptr [ebp+8]
  1000C490: 0B 45 D8           or          eax,dword ptr [ebp-28h]
  1000C493: 5F                 pop         edi
  1000C494: 89 71 06           mov         dword ptr [ecx+6],esi
  1000C497: 89 59 02           mov         dword ptr [ecx+2],ebx
  1000C49A: 66 89 41 0A        mov         word ptr [ecx+0Ah],ax
  1000C49E: 8B 45 EC           mov         eax,dword ptr [ebp-14h]
  1000C4A1: 5E                 pop         esi
  1000C4A2: 66 89 11           mov         word ptr [ecx],dx
  1000C4A5: 5B                 pop         ebx
  1000C4A6: C9                 leave
  1000C4A7: C3                 ret
  1000C4A8: 71 C0              jno         1000C46A
  1000C4AA: 00 10              add         byte ptr [eax],dl
  1000C4AC: C0 C0 00           rol         al,0
  1000C4AF: 10 17              adc         byte ptr [edi],dl
  1000C4B1: C1 00 10           rol         dword ptr [eax],10h
  1000C4B4: 41                 inc         ecx
  1000C4B5: C1 00 10           rol         dword ptr [eax],10h
  1000C4B8: 9C                 pushfd
  1000C4B9: C1 00 10           rol         dword ptr [eax],10h
  1000C4BC: 13 C2              adc         eax,edx
  1000C4BE: 00 10              add         byte ptr [eax],dl
  1000C4C0: 49                 dec         ecx
  1000C4C1: C2 00 10           ret         1000h
  1000C4C4: 93                 xchg        eax,ebx
  1000C4C5: C2 00 10           ret         1000h
  1000C4C8: 72 C2              jb          1000C48C
  1000C4CA: 00 10              add         byte ptr [eax],dl
  1000C4CC: F7 C2 00 10 E1 C2  test        edx,0C2E11000h
  1000C4D2: 00 10              add         byte ptr [eax],dl
  1000C4D4: AD                 lods        dword ptr [esi]
  1000C4D5: C2 00 10           ret         1000h
  1000C4D8: 55                 push        ebp
  1000C4D9: 8B EC              mov         ebp,esp
  1000C4DB: 83 EC 1C           sub         esp,1Ch

; ===== 1000BE66-1000C007: __addl, __add_12, __shl_12, __shr_12, __mtold12

; ---- __addl ----
  1000BE66: 8B 54 24 04        mov         edx,dword ptr [esp+4]
  1000BE6A: 56                 push        esi
  1000BE6B: 8B 74 24 0C        mov         esi,dword ptr [esp+0Ch]
  1000BE6F: 33 C0              xor         eax,eax
  1000BE71: 8D 0C 32           lea         ecx,[edx+esi]
  1000BE74: 3B CA              cmp         ecx,edx
  1000BE76: 72 04              jb          1000BE7C
  1000BE78: 3B CE              cmp         ecx,esi
  1000BE7A: 73 03              jae         1000BE7F
  1000BE7C: 6A 01              push        1
  1000BE7E: 58                 pop         eax
  1000BE7F: 8B 54 24 10        mov         edx,dword ptr [esp+10h]
  1000BE83: 5E                 pop         esi
  1000BE84: 89 0A              mov         dword ptr [edx],ecx
  1000BE86: C3                 ret

; ---- __add_12 ----
  1000BE87: 56                 push        esi
  1000BE88: 8B 74 24 08        mov         esi,dword ptr [esp+8]
  1000BE8C: 57                 push        edi
  1000BE8D: 8B 7C 24 10        mov         edi,dword ptr [esp+10h]
  1000BE91: 56                 push        esi
  1000BE92: FF 37              push        dword ptr [edi]
  1000BE94: FF 36              push        dword ptr [esi]
  1000BE96: E8 CB FF FF FF     call        1000BE66   ; __addl
  1000BE9B: 83 C4 0C           add         esp,0Ch
  1000BE9E: 85 C0              test        eax,eax
  1000BEA0: 74 17              je          1000BEB9
  1000BEA2: 8D 46 04           lea         eax,[esi+4]
  1000BEA5: 50                 push        eax
  1000BEA6: 6A 01              push        1
  1000BEA8: FF 30              push        dword ptr [eax]
  1000BEAA: E8 B7 FF FF FF     call        1000BE66   ; __addl
  1000BEAF: 83 C4 0C           add         esp,0Ch
  1000BEB2: 85 C0              test        eax,eax
  1000BEB4: 74 03              je          1000BEB9
  1000BEB6: FF 46 08           inc         dword ptr [esi+8]
  1000BEB9: 8D 46 04           lea         eax,[esi+4]
  1000BEBC: 50                 push        eax
  1000BEBD: FF 77 04           push        dword ptr [edi+4]
  1000BEC0: FF 30              push        dword ptr [eax]
  1000BEC2: E8 9F FF FF FF     call        1000BE66   ; __addl
  1000BEC7: 83 C4 0C           add         esp,0Ch
  1000BECA: 85 C0              test        eax,eax
  1000BECC: 74 03              je          1000BED1
  1000BECE: FF 46 08           inc         dword ptr [esi+8]
  1000BED1: 8D 46 08           lea         eax,[esi+8]
  1000BED4: 50                 push        eax
  1000BED5: FF 77 08           push        dword ptr [edi+8]
  1000BED8: FF 30              push        dword ptr [eax]
  1000BEDA: E8 87 FF FF FF     call        1000BE66   ; __addl
  1000BEDF: 83 C4 0C           add         esp,0Ch
  1000BEE2: 5F                 pop         edi
  1000BEE3: 5E                 pop         esi
  1000BEE4: C3                 ret

; ---- __shl_12 ----
  1000BEE5: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  1000BEE9: 56                 push        esi
  1000BEEA: 57                 push        edi
  1000BEEB: 8B 30              mov         esi,dword ptr [eax]
  1000BEED: 8B 78 04           mov         edi,dword ptr [eax+4]
  1000BEF0: 8B CE              mov         ecx,esi
  1000BEF2: 03 F6              add         esi,esi
  1000BEF4: 89 30              mov         dword ptr [eax],esi
  1000BEF6: 8D 34 3F           lea         esi,[edi+edi]
  1000BEF9: C1 E9 1F           shr         ecx,1Fh
  1000BEFC: 0B F1              or          esi,ecx
  1000BEFE: 8B 48 08           mov         ecx,dword ptr [eax+8]
  1000BF01: 8B D7              mov         edx,edi
  1000BF03: 89 70 04           mov         dword ptr [eax+4],esi
  1000BF06: C1 EA 1F           shr         edx,1Fh
  1000BF09: D1 E1              shl         ecx,1
  1000BF0B: 0B CA              or          ecx,edx
  1000BF0D: 5F                 pop         edi
  1000BF0E: 89 48 08           mov         dword ptr [eax+8],ecx
  1000BF11: 5E                 pop         esi
  1000BF12: C3                 ret

; ---- __shr_12 ----
  1000BF13: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  1000BF17: 56                 push        esi
  1000BF18: 57                 push        edi
  1000BF19: 8B 50 08           mov         edx,dword ptr [eax+8]
  1000BF1C: 8B 48 04           mov         ecx,dword ptr [eax+4]
  1000BF1F: 8B F2              mov         esi,edx
  1000BF21: 8B F9              mov         edi,ecx
  1000BF23: C1 E6 1F           shl         esi,1Fh
  1000BF26: D1 E9              shr         ecx,1
  1000BF28: 0B CE              or          ecx,esi
  1000BF2A: 89 48 04           mov         dword ptr [eax+4],ecx
  1000BF2D: 8B 08              mov         ecx,dword ptr [eax]
  1000BF2F: C1 E7 1F           shl         edi,1Fh
  1000BF32: D1 E9              shr         ecx,1
  1000BF34: D1 EA              shr         edx,1
  1000BF36: 0B CF              or          ecx,edi
  1000BF38: 5F                 pop         edi
  1000BF39: 89 50 08           mov         dword ptr [eax+8],edx
  1000BF3C: 89 08              mov         dword ptr [eax],ecx
  1000BF3E: 5E                 pop         esi
  1000BF3F: C3                 ret

; ---- __mtold12 ----
  1000BF40: 55                 push        ebp
  1000BF41: 8B EC              mov         ebp,esp
  1000BF43: 83 EC 10           sub         esp,10h
  1000BF46: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  1000BF49: 53                 push        ebx
  1000BF4A: 8B 5D 10           mov         ebx,dword ptr [ebp+10h]
  1000BF4D: 33 D2              xor         edx,edx
  1000BF4F: 3B C2              cmp         eax,edx
  1000BF51: 56                 push        esi
  1000BF52: C7 45 FC 4E 40 00  mov         dword ptr [ebp-4],404Eh
            00
  1000BF59: 89 13              mov         dword ptr [ebx],edx
  1000BF5B: 89 53 04           mov         dword ptr [ebx+4],edx
  1000BF5E: 89 53 08           mov         dword ptr [ebx+8],edx
  1000BF61: 76 51              jbe         1000BFB4
  1000BF63: 57                 push        edi
  1000BF64: 89 45 10           mov         dword ptr [ebp+10h],eax
  1000BF67: 8B F3              mov         esi,ebx
  1000BF69: 8D 7D F0           lea         edi,[ebp-10h]
  1000BF6C: A5                 movs        dword ptr es:[edi],dword ptr [esi]
  1000BF6D: A5                 movs        dword ptr es:[edi],dword ptr [esi]
  1000BF6E: 53                 push        ebx
  1000BF6F: A5                 movs        dword ptr es:[edi],dword ptr [esi]
  1000BF70: E8 70 FF FF FF     call        1000BEE5   ; __shl_12
  1000BF75: 53                 push        ebx
  1000BF76: E8 6A FF FF FF     call        1000BEE5   ; __shl_12
  1000BF7B: 8D 45 F0           lea         eax,[ebp-10h]
  1000BF7E: 50                 push        eax
  1000BF7F: 53                 push        ebx
  1000BF80: E8 02 FF FF FF     call        1000BE87   ; __add_12
  1000BF85: 53                 push        ebx
  1000BF86: E8 5A FF FF FF     call        1000BEE5   ; __shl_12
  1000BF8B: 8B 45 08           mov         eax,dword ptr [ebp+8]
  1000BF8E: 83 65 F4 00        and         dword ptr [ebp-0Ch],0
  1000BF92: 83 65 F8 00        and         dword ptr [ebp-8],0
  1000BF96: 0F BE 00           movsx       eax,byte ptr [eax]
  1000BF99: 89 45 F0           mov         dword ptr [ebp-10h],eax
  1000BF9C: 8D 45 F0           lea         eax,[ebp-10h]
  1000BF9F: 50                 push        eax
  1000BFA0: 53                 push        ebx
  1000BFA1: E8 E1 FE FF FF     call        1000BE87   ; __add_12
  1000BFA6: 83 C4 1C           add         esp,1Ch
  1000BFA9: FF 45 08           inc         dword ptr [ebp+8]
  1000BFAC: FF 4D 10           dec         dword ptr [ebp+10h]
  1000BFAF: 75 B6              jne         1000BF67
  1000BFB1: 33 D2              xor         edx,edx
  1000BFB3: 5F                 pop         edi
  1000BFB4: 39 53 08           cmp         dword ptr [ebx+8],edx
  1000BFB7: 75 28              jne         1000BFE1
  1000BFB9: 8B 4B 04           mov         ecx,dword ptr [ebx+4]
  1000BFBC: 8B C1              mov         eax,ecx
  1000BFBE: C1 E8 10           shr         eax,10h
  1000BFC1: 89 43 08           mov         dword ptr [ebx+8],eax
  1000BFC4: 8B 03              mov         eax,dword ptr [ebx]
  1000BFC6: 8B F0              mov         esi,eax
  1000BFC8: C1 EE 10           shr         esi,10h
  1000BFCB: C1 E1 10           shl         ecx,10h
  1000BFCE: 0B F1              or          esi,ecx
  1000BFD0: C1 E0 10           shl         eax,10h
  1000BFD3: 81 45 FC F0 FF 00  add         dword ptr [ebp-4],0FFF0h
            00
  1000BFDA: 89 73 04           mov         dword ptr [ebx+4],esi
  1000BFDD: 89 03              mov         dword ptr [ebx],eax
  1000BFDF: EB D3              jmp         1000BFB4
  1000BFE1: BE 00 80 00 00     mov         esi,8000h
  1000BFE6: 85 73 08           test        dword ptr [ebx+8],esi
  1000BFE9: 75 10              jne         1000BFFB
  1000BFEB: 53                 push        ebx
  1000BFEC: E8 F4 FE FF FF     call        1000BEE5   ; __shl_12
  1000BFF1: 81 45 FC FF FF 00  add         dword ptr [ebp-4],0FFFFh
            00
  1000BFF8: 59                 pop         ecx
  1000BFF9: EB EB              jmp         1000BFE6
  1000BFFB: 66 8B 45 FC        mov         ax,word ptr [ebp-4]
  1000BFFF: 5E                 pop         esi
  1000C000: 66 89 43 0A        mov         word ptr [ebx+0Ah],ax
  1000C004: 5B                 pop         ebx
  1000C005: C9                 leave
  1000C006: C3                 ret

; ===== 1000D2AA-1000D546: __ld12mul and __multtenpow12

; ---- __ld12mul ----
  1000D2AA: 55                 push        ebp
  1000D2AB: 8B EC              mov         ebp,esp
  1000D2AD: 83 EC 24           sub         esp,24h
  1000D2B0: 53                 push        ebx
  1000D2B1: 8B 5D 0C           mov         ebx,dword ptr [ebp+0Ch]
  1000D2B4: 56                 push        esi
  1000D2B5: 8B 75 08           mov         esi,dword ptr [ebp+8]
  1000D2B8: 66 8B 4B 0A        mov         cx,word ptr [ebx+0Ah]
  1000D2BC: 33 C0              xor         eax,eax
  1000D2BE: 57                 push        edi
  1000D2BF: 89 45 EC           mov         dword ptr [ebp-14h],eax
  1000D2C2: 89 45 DC           mov         dword ptr [ebp-24h],eax
  1000D2C5: 89 45 E0           mov         dword ptr [ebp-20h],eax
  1000D2C8: 89 45 E4           mov         dword ptr [ebp-1Ch],eax
  1000D2CB: 66 8B 46 0A        mov         ax,word ptr [esi+0Ah]
  1000D2CF: 8B F9              mov         edi,ecx
  1000D2D1: BA FF 7F 00 00     mov         edx,7FFFh
  1000D2D6: 33 F8              xor         edi,eax
  1000D2D8: 23 C2              and         eax,edx
  1000D2DA: 23 CA              and         ecx,edx
  1000D2DC: 81 E7 00 80 00 00  and         edi,8000h
  1000D2E2: 66 3D FF 7F        cmp         ax,7FFFh
  1000D2E6: 8D 14 01           lea         edx,[ecx+eax]
  1000D2E9: 89 55 08           mov         dword ptr [ebp+8],edx
  1000D2EC: 0F 83 B8 01 00 00  jae         1000D4AA
  1000D2F2: 66 81 F9 FF 7F     cmp         cx,7FFFh
  1000D2F7: 0F 83 AD 01 00 00  jae         1000D4AA
  1000D2FD: 66 81 FA FD BF     cmp         dx,0BFFDh
  1000D302: 0F 87 A2 01 00 00  ja          1000D4AA
  1000D308: 66 81 FA BF 3F     cmp         dx,3FBFh
  1000D30D: 77 04              ja          1000D313
  1000D30F: 33 C0              xor         eax,eax
  1000D311: EB 3A              jmp         1000D34D
  1000D313: 66 85 C0           test        ax,ax
  1000D316: BA FF FF FF 7F     mov         edx,7FFFFFFFh
  1000D31B: 75 18              jne         1000D335
  1000D31D: FF 45 08           inc         dword ptr [ebp+8]
  1000D320: 85 56 08           test        dword ptr [esi+8],edx
  1000D323: 75 10              jne         1000D335
  1000D325: 33 C0              xor         eax,eax
  1000D327: 39 46 04           cmp         dword ptr [esi+4],eax
  1000D32A: 75 0B              jne         1000D337
  1000D32C: 39 06              cmp         dword ptr [esi],eax
  1000D32E: 75 07              jne         1000D337
  1000D330: E9 6F 01 00 00     jmp         1000D4A4
  1000D335: 33 C0              xor         eax,eax
  1000D337: 66 3B C8           cmp         cx,ax
  1000D33A: 75 1E              jne         1000D35A
  1000D33C: FF 45 08           inc         dword ptr [ebp+8]
  1000D33F: 85 53 08           test        dword ptr [ebx+8],edx
  1000D342: 75 16              jne         1000D35A
  1000D344: 39 43 04           cmp         dword ptr [ebx+4],eax
  1000D347: 75 11              jne         1000D35A
  1000D349: 39 03              cmp         dword ptr [ebx],eax
  1000D34B: 75 0D              jne         1000D35A
  1000D34D: 89 46 08           mov         dword ptr [esi+8],eax
  1000D350: 89 46 04           mov         dword ptr [esi+4],eax
  1000D353: 89 06              mov         dword ptr [esi],eax
  1000D355: E9 6B 01 00 00     jmp         1000D4C5
  1000D35A: 89 45 F0           mov         dword ptr [ebp-10h],eax
  1000D35D: 8D 45 E0           lea         eax,[ebp-20h]
  1000D360: 89 45 FC           mov         dword ptr [ebp-4],eax
  1000D363: C7 45 0C 05 00 00  mov         dword ptr [ebp+0Ch],5
            00
  1000D36A: 8B 45 F0           mov         eax,dword ptr [ebp-10h]
  1000D36D: 03 C0              add         eax,eax
  1000D36F: 83 7D 0C 00        cmp         dword ptr [ebp+0Ch],0
  1000D373: 7E 49              jle         1000D3BE
  1000D375: 03 C6              add         eax,esi
  1000D377: 8D 4B 08           lea         ecx,[ebx+8]
  1000D37A: 89 45 F8           mov         dword ptr [ebp-8],eax
  1000D37D: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  1000D380: 89 4D F4           mov         dword ptr [ebp-0Ch],ecx
  1000D383: 89 45 E8           mov         dword ptr [ebp-18h],eax
  1000D386: 8B 45 F8           mov         eax,dword ptr [ebp-8]
  1000D389: 8B 4D F4           mov         ecx,dword ptr [ebp-0Ch]
  1000D38C: 0F B7 00           movzx       eax,word ptr [eax]
  1000D38F: 0F B7 09           movzx       ecx,word ptr [ecx]
  1000D392: 0F AF C1           imul        eax,ecx
  1000D395: 8B 4D FC           mov         ecx,dword ptr [ebp-4]
  1000D398: 83 C1 FC           add         ecx,0FFFFFFFCh
  1000D39B: 51                 push        ecx
  1000D39C: 50                 push        eax
  1000D39D: FF 31              push        dword ptr [ecx]
  1000D39F: E8 C2 EA FF FF     call        1000BE66   ; __addl
  1000D3A4: 83 C4 0C           add         esp,0Ch
  1000D3A7: 85 C0              test        eax,eax
  1000D3A9: 74 06              je          1000D3B1
  1000D3AB: 8B 45 FC           mov         eax,dword ptr [ebp-4]
  1000D3AE: 66 FF 00           inc         word ptr [eax]
  1000D3B1: 83 45 F8 02        add         dword ptr [ebp-8],2
  1000D3B5: 83 6D F4 02        sub         dword ptr [ebp-0Ch],2
  1000D3B9: FF 4D E8           dec         dword ptr [ebp-18h]
  1000D3BC: 75 C8              jne         1000D386
  1000D3BE: 83 45 FC 02        add         dword ptr [ebp-4],2
  1000D3C2: FF 45 F0           inc         dword ptr [ebp-10h]
  1000D3C5: FF 4D 0C           dec         dword ptr [ebp+0Ch]
  1000D3C8: 83 7D 0C 00        cmp         dword ptr [ebp+0Ch],0
  1000D3CC: 7F 9C              jg          1000D36A
  1000D3CE: 81 45 08 02 C0 00  add         dword ptr [ebp+8],0C002h
            00
  1000D3D5: 66 83 7D 08 00     cmp         word ptr [ebp+8],0
  1000D3DA: 7E 25              jle         1000D401
  1000D3DC: F6 45 E7 80        test        byte ptr [ebp-19h],80h
  1000D3E0: 75 18              jne         1000D3FA
  1000D3E2: 8D 45 DC           lea         eax,[ebp-24h]
  1000D3E5: 50                 push        eax
  1000D3E6: E8 FA EA FF FF     call        1000BEE5   ; __shl_12
  1000D3EB: 81 45 08 FF FF 00  add         dword ptr [ebp+8],0FFFFh
            00
  1000D3F2: 59                 pop         ecx
  1000D3F3: 66 83 7D 08 00     cmp         word ptr [ebp+8],0
  1000D3F8: 7F E2              jg          1000D3DC
  1000D3FA: 66 83 7D 08 00     cmp         word ptr [ebp+8],0
  1000D3FF: 7F 39              jg          1000D43A
  1000D401: 81 45 08 FF FF 00  add         dword ptr [ebp+8],0FFFFh
            00
  1000D408: 66 83 7D 08 00     cmp         word ptr [ebp+8],0
  1000D40D: 7D 2B              jge         1000D43A
  1000D40F: 0F BF 45 08        movsx       eax,word ptr [ebp+8]
  1000D413: F7 D8              neg         eax
  1000D415: 01 45 08           add         dword ptr [ebp+8],eax
  1000D418: 8B D8              mov         ebx,eax
  1000D41A: F6 45 DC 01        test        byte ptr [ebp-24h],1
  1000D41E: 74 03              je          1000D423
  1000D420: FF 45 EC           inc         dword ptr [ebp-14h]
  1000D423: 8D 45 DC           lea         eax,[ebp-24h]
  1000D426: 50                 push        eax
  1000D427: E8 E7 EA FF FF     call        1000BF13   ; __shr_12
  1000D42C: 4B                 dec         ebx
  1000D42D: 59                 pop         ecx
  1000D42E: 75 EA              jne         1000D41A
  1000D430: 83 7D EC 00        cmp         dword ptr [ebp-14h],0
  1000D434: 74 04              je          1000D43A
  1000D436: 80 4D DC 01        or          byte ptr [ebp-24h],1
  1000D43A: 66 81 7D DC 00 80  cmp         word ptr [ebp-24h],8000h
  1000D440: 77 0F              ja          1000D451
  1000D442: 8B 45 DC           mov         eax,dword ptr [ebp-24h]
  1000D445: 25 FF FF 01 00     and         eax,1FFFFh
  1000D44A: 3D 00 80 01 00     cmp         eax,18000h
  1000D44F: 75 35              jne         1000D486
  1000D451: 83 7D DE FF        cmp         dword ptr [ebp-22h],0FFFFFFFFh
  1000D455: 75 2C              jne         1000D483
  1000D457: 83 65 DE 00        and         dword ptr [ebp-22h],0
  1000D45B: 83 7D E2 FF        cmp         dword ptr [ebp-1Eh],0FFFFFFFFh
  1000D45F: 75 1D              jne         1000D47E
  1000D461: 83 65 E2 00        and         dword ptr [ebp-1Eh],0
  1000D465: 66 81 7D E6 FF FF  cmp         word ptr [ebp-1Ah],0FFFFh
  1000D46B: 75 0B              jne         1000D478
  1000D46D: FF 45 08           inc         dword ptr [ebp+8]
  1000D470: 66 C7 45 E6 00 80  mov         word ptr [ebp-1Ah],8000h
  1000D476: EB 0E              jmp         1000D486
  1000D478: 66 FF 45 E6        inc         word ptr [ebp-1Ah]
  1000D47C: EB 08              jmp         1000D486
  1000D47E: FF 45 E2           inc         dword ptr [ebp-1Eh]
  1000D481: EB 03              jmp         1000D486
  1000D483: FF 45 DE           inc         dword ptr [ebp-22h]
  1000D486: 8B 45 08           mov         eax,dword ptr [ebp+8]
  1000D489: 66 3D FF 7F        cmp         ax,7FFFh
  1000D48D: 73 1B              jae         1000D4AA
  1000D48F: 66 8B 4D DE        mov         cx,word ptr [ebp-22h]
  1000D493: 0B C7              or          eax,edi
  1000D495: 66 89 0E           mov         word ptr [esi],cx
  1000D498: 8B 4D E0           mov         ecx,dword ptr [ebp-20h]
  1000D49B: 89 4E 02           mov         dword ptr [esi+2],ecx
  1000D49E: 8B 4D E4           mov         ecx,dword ptr [ebp-1Ch]
  1000D4A1: 89 4E 06           mov         dword ptr [esi+6],ecx
  1000D4A4: 66 89 46 0A        mov         word ptr [esi+0Ah],ax
  1000D4A8: EB 1B              jmp         1000D4C5
  1000D4AA: 66 F7 DF           neg         di
  1000D4AD: 1B FF              sbb         edi,edi
  1000D4AF: 83 66 04 00        and         dword ptr [esi+4],0
  1000D4B3: 81 E7 00 00 00 80  and         edi,80000000h
  1000D4B9: 81 C7 00 80 FF 7F  add         edi,7FFF8000h
  1000D4BF: 83 26 00           and         dword ptr [esi],0
  1000D4C2: 89 7E 08           mov         dword ptr [esi+8],edi
  1000D4C5: 5F                 pop         edi
  1000D4C6: 5E                 pop         esi
  1000D4C7: 5B                 pop         ebx
  1000D4C8: C9                 leave
  1000D4C9: C3                 ret

; ---- __multtenpow12 ----
  1000D4CA: 55                 push        ebp
  1000D4CB: 8B EC              mov         ebp,esp
  1000D4CD: 83 EC 0C           sub         esp,0Ch
  1000D4D0: 53                 push        ebx
  1000D4D1: BB 10 21 01 10     mov         ebx,10012110h
  1000D4D6: 33 C9              xor         ecx,ecx
  1000D4D8: 83 EB 60           sub         ebx,60h
  1000D4DB: 39 4D 0C           cmp         dword ptr [ebp+0Ch],ecx
  1000D4DE: 74 63              je          1000D543
  1000D4E0: 7D 10              jge         1000D4F2
  1000D4E2: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  1000D4E5: BB 70 22 01 10     mov         ebx,10012270h
  1000D4EA: F7 D8              neg         eax
  1000D4EC: 89 45 0C           mov         dword ptr [ebp+0Ch],eax
  1000D4EF: 83 EB 60           sub         ebx,60h
  1000D4F2: 39 4D 10           cmp         dword ptr [ebp+10h],ecx
  1000D4F5: 75 06              jne         1000D4FD
  1000D4F7: 8B 45 08           mov         eax,dword ptr [ebp+8]
  1000D4FA: 66 89 08           mov         word ptr [eax],cx
  1000D4FD: 39 4D 0C           cmp         dword ptr [ebp+0Ch],ecx
  1000D500: 74 41              je          1000D543
  1000D502: 56                 push        esi
  1000D503: 57                 push        edi
  1000D504: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  1000D507: 83 C3 54           add         ebx,54h
  1000D50A: C1 7D 0C 03        sar         dword ptr [ebp+0Ch],3
  1000D50E: 83 E0 07           and         eax,7
  1000D511: 3B C1              cmp         eax,ecx
  1000D513: 74 27              je          1000D53C
  1000D515: 8D 04 40           lea         eax,[eax+eax*2]
  1000D518: 66 81 3C 83 00 80  cmp         word ptr [ebx+eax*4],8000h
  1000D51E: 8D 34 83           lea         esi,[ebx+eax*4]
  1000D521: 72 0C              jb          1000D52F
  1000D523: 8D 7D F4           lea         edi,[ebp-0Ch]
  1000D526: A5                 movs        dword ptr es:[edi],dword ptr [esi]
  1000D527: A5                 movs        dword ptr es:[edi],dword ptr [esi]
  1000D528: A5                 movs        dword ptr es:[edi],dword ptr [esi]
  1000D529: FF 4D F6           dec         dword ptr [ebp-0Ah]
  1000D52C: 8D 75 F4           lea         esi,[ebp-0Ch]
  1000D52F: 56                 push        esi
  1000D530: FF 75 08           push        dword ptr [ebp+8]
  1000D533: E8 72 FD FF FF     call        1000D2AA   ; __ld12mul
  1000D538: 59                 pop         ecx
  1000D539: 59                 pop         ecx
  1000D53A: 33 C9              xor         ecx,ecx
  1000D53C: 39 4D 0C           cmp         dword ptr [ebp+0Ch],ecx
  1000D53F: 75 C3              jne         1000D504
  1000D541: 5F                 pop         edi
  1000D542: 5E                 pop         esi
  1000D543: 5B                 pop         ebx
  1000D544: C9                 leave
  1000D545: C3                 ret

; ===== 10009638-100099CA: _IsZeroTail, _IncMan, _RoundMan, _CopyMan, _ZeroMan, _IsZeroMan, _ShrMan, _ld12cvt, _ld12tod, _ld12tof

; ---- _IsZeroTail ----
  10009638: 8B 44 24 08        mov         eax,dword ptr [esp+8]
  1000963C: 56                 push        esi
  1000963D: 6A 20              push        20h
  1000963F: 99                 cdq
  10009640: 59                 pop         ecx
  10009641: F7 F9              idiv        eax,ecx
  10009643: 6A 1F              push        1Fh
  10009645: 8B F0              mov         esi,eax
  10009647: 8B 44 24 10        mov         eax,dword ptr [esp+10h]
  1000964B: 99                 cdq
  1000964C: F7 F9              idiv        eax,ecx
  1000964E: 59                 pop         ecx
  1000964F: 8B 44 24 08        mov         eax,dword ptr [esp+8]
  10009653: 2B CA              sub         ecx,edx
  10009655: 83 CA FF           or          edx,0FFFFFFFFh
  10009658: D3 E2              shl         edx,cl
  1000965A: F7 D2              not         edx
  1000965C: 85 14 B0           test        dword ptr [eax+esi*4],edx
  1000965F: 75 1C              jne         1000967D
  10009661: 46                 inc         esi
  10009662: 83 FE 03           cmp         esi,3
  10009665: 7D 11              jge         10009678
  10009667: 8D 04 B0           lea         eax,[eax+esi*4]
  1000966A: 83 38 00           cmp         dword ptr [eax],0
  1000966D: 75 0E              jne         1000967D
  1000966F: 46                 inc         esi
  10009670: 83 C0 04           add         eax,4
  10009673: 83 FE 03           cmp         esi,3
  10009676: 7C F2              jl          1000966A
  10009678: 6A 01              push        1
  1000967A: 58                 pop         eax
  1000967B: 5E                 pop         esi
  1000967C: C3                 ret
  1000967D: 33 C0              xor         eax,eax
  1000967F: 5E                 pop         esi
  10009680: C3                 ret

; ---- _IncMan ----
  10009681: 8B 44 24 08        mov         eax,dword ptr [esp+8]
  10009685: 53                 push        ebx
  10009686: 56                 push        esi
  10009687: 57                 push        edi
  10009688: 6A 20              push        20h
  1000968A: 8B 5C 24 14        mov         ebx,dword ptr [esp+14h]
  1000968E: 99                 cdq
  1000968F: 59                 pop         ecx
  10009690: F7 F9              idiv        eax,ecx
  10009692: 8B F0              mov         esi,eax
  10009694: 8B 44 24 14        mov         eax,dword ptr [esp+14h]
  10009698: 99                 cdq
  10009699: F7 F9              idiv        eax,ecx
  1000969B: 8D 3C B3           lea         edi,[ebx+esi*4]
  1000969E: 57                 push        edi
  1000969F: 6A 1F              push        1Fh
  100096A1: 59                 pop         ecx
  100096A2: 6A 01              push        1
  100096A4: 58                 pop         eax
  100096A5: 2B CA              sub         ecx,edx
  100096A7: D3 E0              shl         eax,cl
  100096A9: 50                 push        eax
  100096AA: FF 37              push        dword ptr [edi]
  100096AC: E8 B5 27 00 00     call        1000BE66   ; __addl
  100096B1: 83 C4 0C           add         esp,0Ch
  100096B4: 4E                 dec         esi
  100096B5: 78 1C              js          100096D3
  100096B7: 8D 3C B3           lea         edi,[ebx+esi*4]
  100096BA: 85 C0              test        eax,eax
  100096BC: 74 15              je          100096D3
  100096BE: 57                 push        edi
  100096BF: 6A 01              push        1
  100096C1: FF 37              push        dword ptr [edi]
  100096C3: E8 9E 27 00 00     call        1000BE66   ; __addl
  100096C8: 83 C4 0C           add         esp,0Ch
  100096CB: 4E                 dec         esi
  100096CC: 83 EF 04           sub         edi,4
  100096CF: 85 F6              test        esi,esi
  100096D1: 7D E7              jge         100096BA
  100096D3: 5F                 pop         edi
  100096D4: 5E                 pop         esi
  100096D5: 5B                 pop         ebx
  100096D6: C3                 ret

; ---- _RoundMan ----
  100096D7: 55                 push        ebp
  100096D8: 8B EC              mov         ebp,esp
  100096DA: 51                 push        ecx
  100096DB: 51                 push        ecx
  100096DC: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  100096DF: 53                 push        ebx
  100096E0: 56                 push        esi
  100096E1: 57                 push        edi
  100096E2: 8D 78 FF           lea         edi,[eax-1]
  100096E5: 6A 20              push        20h
  100096E7: 59                 pop         ecx
  100096E8: 83 65 FC 00        and         dword ptr [ebp-4],0
  100096EC: 8D 5F 01           lea         ebx,[edi+1]
  100096EF: 6A 20              push        20h
  100096F1: 8B C3              mov         eax,ebx
  100096F3: 5E                 pop         esi
  100096F4: 99                 cdq
  100096F5: F7 F9              idiv        eax,ecx
  100096F7: 6A 1F              push        1Fh
  100096F9: 8B C8              mov         ecx,eax
  100096FB: 8B C3              mov         eax,ebx
  100096FD: 99                 cdq
  100096FE: F7 FE              idiv        eax,esi
  10009700: 8B 45 08           mov         eax,dword ptr [ebp+8]
  10009703: 5E                 pop         esi
  10009704: 6A 01              push        1
  10009706: 89 4D F8           mov         dword ptr [ebp-8],ecx
  10009709: 8D 04 88           lea         eax,[eax+ecx*4]
  1000970C: 89 45 0C           mov         dword ptr [ebp+0Ch],eax
  1000970F: 2B F2              sub         esi,edx
  10009711: 5A                 pop         edx
  10009712: 8B CE              mov         ecx,esi
  10009714: D3 E2              shl         edx,cl
  10009716: 85 10              test        dword ptr [eax],edx
  10009718: 74 21              je          1000973B
  1000971A: 43                 inc         ebx
  1000971B: 53                 push        ebx
  1000971C: FF 75 08           push        dword ptr [ebp+8]
  1000971F: E8 14 FF FF FF     call        10009638   ; _IsZeroTail
  10009724: 59                 pop         ecx
  10009725: 85 C0              test        eax,eax
  10009727: 59                 pop         ecx
  10009728: 75 0E              jne         10009738
  1000972A: 57                 push        edi
  1000972B: FF 75 08           push        dword ptr [ebp+8]
  1000972E: E8 4E FF FF FF     call        10009681   ; _IncMan
  10009733: 59                 pop         ecx
  10009734: 89 45 FC           mov         dword ptr [ebp-4],eax
  10009737: 59                 pop         ecx
  10009738: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  1000973B: 83 CA FF           or          edx,0FFFFFFFFh
  1000973E: 8B CE              mov         ecx,esi
  10009740: D3 E2              shl         edx,cl
  10009742: 6A 03              push        3
  10009744: 59                 pop         ecx
  10009745: 21 10              and         dword ptr [eax],edx
  10009747: 8B 45 F8           mov         eax,dword ptr [ebp-8]
  1000974A: 40                 inc         eax
  1000974B: 3B C1              cmp         eax,ecx
  1000974D: 7D 0C              jge         1000975B
  1000974F: 8B 55 08           mov         edx,dword ptr [ebp+8]
  10009752: 2B C8              sub         ecx,eax
  10009754: 8D 3C 82           lea         edi,[edx+eax*4]
  10009757: 33 C0              xor         eax,eax
  10009759: F3 AB              rep stos    dword ptr es:[edi]
  1000975B: 8B 45 FC           mov         eax,dword ptr [ebp-4]
  1000975E: 5F                 pop         edi
  1000975F: 5E                 pop         esi
  10009760: 5B                 pop         ebx
  10009761: C9                 leave
  10009762: C3                 ret

; ---- _CopyMan ----
  10009763: 8B 44 24 08        mov         eax,dword ptr [esp+8]
  10009767: 8B 4C 24 04        mov         ecx,dword ptr [esp+4]
  1000976B: 56                 push        esi
  1000976C: 6A 03              push        3
  1000976E: 2B C8              sub         ecx,eax
  10009770: 5A                 pop         edx
  10009771: 8B 30              mov         esi,dword ptr [eax]
  10009773: 89 34 01           mov         dword ptr [ecx+eax],esi
  10009776: 83 C0 04           add         eax,4
  10009779: 4A                 dec         edx
  1000977A: 75 F5              jne         10009771
  1000977C: 5E                 pop         esi
  1000977D: C3                 ret

; ---- _ZeroMan ----
  1000977E: 57                 push        edi
  1000977F: 8B 7C 24 08        mov         edi,dword ptr [esp+8]
  10009783: 33 C0              xor         eax,eax
  10009785: AB                 stos        dword ptr es:[edi]
  10009786: AB                 stos        dword ptr es:[edi]
  10009787: AB                 stos        dword ptr es:[edi]
  10009788: 5F                 pop         edi
  10009789: C3                 ret

; ---- _IsZeroMan ----
  1000978A: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  1000978E: 33 C9              xor         ecx,ecx
  10009790: 83 38 00           cmp         dword ptr [eax],0
  10009793: 75 0D              jne         100097A2
  10009795: 41                 inc         ecx
  10009796: 83 C0 04           add         eax,4
  10009799: 83 F9 03           cmp         ecx,3
  1000979C: 7C F2              jl          10009790
  1000979E: 6A 01              push        1
  100097A0: 58                 pop         eax
  100097A1: C3                 ret
  100097A2: 33 C0              xor         eax,eax
  100097A4: C3                 ret

; ---- _ShrMan ----
  100097A5: 55                 push        ebp
  100097A6: 8B EC              mov         ebp,esp
  100097A8: 83 EC 0C           sub         esp,0Ch
  100097AB: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  100097AE: 53                 push        ebx
  100097AF: 56                 push        esi
  100097B0: 57                 push        edi
  100097B1: 6A 20              push        20h
  100097B3: 8B 7D 08           mov         edi,dword ptr [ebp+8]
  100097B6: 5B                 pop         ebx
  100097B7: 83 CE FF           or          esi,0FFFFFFFFh
  100097BA: 99                 cdq
  100097BB: 8B CB              mov         ecx,ebx
  100097BD: C7 45 FC 03 00 00  mov         dword ptr [ebp-4],3
            00
  100097C4: F7 F9              idiv        eax,ecx
  100097C6: 89 45 F4           mov         dword ptr [ebp-0Ch],eax
  100097C9: 8B 45 0C           mov         eax,dword ptr [ebp+0Ch]
  100097CC: 99                 cdq
  100097CD: F7 F9              idiv        eax,ecx
  100097CF: 83 65 0C 00        and         dword ptr [ebp+0Ch],0
  100097D3: 8B CA              mov         ecx,edx
  100097D5: D3 E6              shl         esi,cl
  100097D7: 2B DA              sub         ebx,edx
  100097D9: F7 D6              not         esi
  100097DB: 8B 07              mov         eax,dword ptr [edi]
  100097DD: 8B C8              mov         ecx,eax
  100097DF: 23 CE              and         ecx,esi
  100097E1: 89 4D F8           mov         dword ptr [ebp-8],ecx
  100097E4: 8B CA              mov         ecx,edx
  100097E6: D3 E8              shr         eax,cl
  100097E8: 0B 45 0C           or          eax,dword ptr [ebp+0Ch]
  100097EB: 89 07              mov         dword ptr [edi],eax
  100097ED: 8B 45 F8           mov         eax,dword ptr [ebp-8]
  100097F0: 8B CB              mov         ecx,ebx
  100097F2: 83 C7 04           add         edi,4
  100097F5: D3 E0              shl         eax,cl
  100097F7: FF 4D FC           dec         dword ptr [ebp-4]
  100097FA: 89 45 0C           mov         dword ptr [ebp+0Ch],eax
  100097FD: 75 DC              jne         100097DB
  100097FF: 8B 7D F4           mov         edi,dword ptr [ebp-0Ch]
  10009802: 6A 02              push        2
  10009804: 5B                 pop         ebx
  10009805: 8B F7              mov         esi,edi
  10009807: 6A 08              push        8
  10009809: 59                 pop         ecx
  1000980A: C1 E6 02           shl         esi,2
  1000980D: 3B DF              cmp         ebx,edi
  1000980F: 7C 0F              jl          10009820
  10009811: 8B 55 08           mov         edx,dword ptr [ebp+8]
  10009814: 8B C1              mov         eax,ecx
  10009816: 2B C6              sub         eax,esi
  10009818: 8B 04 10           mov         eax,dword ptr [eax+edx]
  1000981B: 89 04 11           mov         dword ptr [ecx+edx],eax
  1000981E: EB 07              jmp         10009827
  10009820: 8B 45 08           mov         eax,dword ptr [ebp+8]
  10009823: 83 24 01 00        and         dword ptr [ecx+eax],0
  10009827: 4B                 dec         ebx
  10009828: 83 E9 04           sub         ecx,4
  1000982B: 79 E0              jns         1000980D
  1000982D: 5F                 pop         edi
  1000982E: 5E                 pop         esi
  1000982F: 5B                 pop         ebx
  10009830: C9                 leave
  10009831: C3                 ret

; ---- _ld12cvt ----
  10009832: 55                 push        ebp
  10009833: 8B EC              mov         ebp,esp
  10009835: 83 EC 18           sub         esp,18h
  10009838: 8B 45 08           mov         eax,dword ptr [ebp+8]
  1000983B: 53                 push        ebx
  1000983C: 56                 push        esi
  1000983D: 57                 push        edi
  1000983E: 0F B7 48 0A        movzx       ecx,word ptr [eax+0Ah]
  10009842: 8B D9              mov         ebx,ecx
  10009844: 81 E1 00 80 00 00  and         ecx,8000h
  1000984A: 89 4D 08           mov         dword ptr [ebp+8],ecx
  1000984D: 8B 48 06           mov         ecx,dword ptr [eax+6]
  10009850: 89 4D F4           mov         dword ptr [ebp-0Ch],ecx
  10009853: 8B 48 02           mov         ecx,dword ptr [eax+2]
  10009856: 0F B7 00           movzx       eax,word ptr [eax]
  10009859: 8B 7D 10           mov         edi,dword ptr [ebp+10h]
  1000985C: 81 E3 FF 7F 00 00  and         ebx,7FFFh
  10009862: 81 EB FF 3F 00 00  sub         ebx,3FFFh
  10009868: 89 4D F8           mov         dword ptr [ebp-8],ecx
  1000986B: C1 E0 10           shl         eax,10h
  1000986E: 81 FB 01 C0 FF FF  cmp         ebx,0FFFFC001h
  10009874: 89 45 FC           mov         dword ptr [ebp-4],eax
  10009877: 75 26              jne         1000989F
  10009879: 8D 45 F4           lea         eax,[ebp-0Ch]
  1000987C: 33 F6              xor         esi,esi
  1000987E: 50                 push        eax
  1000987F: E8 06 FF FF FF     call        1000978A   ; _IsZeroMan
  10009884: 85 C0              test        eax,eax
  10009886: 59                 pop         ecx
  10009887: 0F 85 D1 00 00 00  jne         1000995E
  1000988D: 8D 45 F4           lea         eax,[ebp-0Ch]
  10009890: 50                 push        eax
  10009891: E8 E8 FE FF FF     call        1000977E   ; _ZeroMan
  10009896: 59                 pop         ecx
  10009897: 6A 02              push        2
  10009899: 58                 pop         eax
  1000989A: E9 C1 00 00 00     jmp         10009960
  1000989F: 8D 45 F4           lea         eax,[ebp-0Ch]
  100098A2: 50                 push        eax
  100098A3: 8D 45 E8           lea         eax,[ebp-18h]
  100098A6: 50                 push        eax
  100098A7: E8 B7 FE FF FF     call        10009763   ; _CopyMan
  100098AC: FF 77 08           push        dword ptr [edi+8]
  100098AF: 8D 45 F4           lea         eax,[ebp-0Ch]
  100098B2: 50                 push        eax
  100098B3: E8 1F FE FF FF     call        100096D7   ; _RoundMan
  100098B8: 83 C4 10           add         esp,10h
  100098BB: 85 C0              test        eax,eax
  100098BD: 74 01              je          100098C0
  100098BF: 43                 inc         ebx
  100098C0: 8B 47 04           mov         eax,dword ptr [edi+4]
  100098C3: 8B C8              mov         ecx,eax
  100098C5: 2B 4F 08           sub         ecx,dword ptr [edi+8]
  100098C8: 3B D9              cmp         ebx,ecx
  100098CA: 7D 0C              jge         100098D8
  100098CC: 8D 45 F4           lea         eax,[ebp-0Ch]
  100098CF: 50                 push        eax
  100098D0: E8 A9 FE FF FF     call        1000977E   ; _ZeroMan
  100098D5: 59                 pop         ecx
  100098D6: EB 3C              jmp         10009914
  100098D8: 3B D8              cmp         ebx,eax
  100098DA: 7F 3F              jg          1000991B
  100098DC: 2B C3              sub         eax,ebx
  100098DE: 8B F0              mov         esi,eax
  100098E0: 8D 45 E8           lea         eax,[ebp-18h]
  100098E3: 50                 push        eax
  100098E4: 8D 45 F4           lea         eax,[ebp-0Ch]
  100098E7: 50                 push        eax
  100098E8: E8 76 FE FF FF     call        10009763   ; _CopyMan
  100098ED: 8D 45 F4           lea         eax,[ebp-0Ch]
  100098F0: 56                 push        esi
  100098F1: 50                 push        eax
  100098F2: E8 AE FE FF FF     call        100097A5   ; _ShrMan
  100098F7: FF 77 08           push        dword ptr [edi+8]
  100098FA: 8D 45 F4           lea         eax,[ebp-0Ch]
  100098FD: 50                 push        eax
  100098FE: E8 D4 FD FF FF     call        100096D7   ; _RoundMan
  10009903: 8B 47 0C           mov         eax,dword ptr [edi+0Ch]
  10009906: 40                 inc         eax
  10009907: 50                 push        eax
  10009908: 8D 45 F4           lea         eax,[ebp-0Ch]
  1000990B: 50                 push        eax
  1000990C: E8 94 FE FF FF     call        100097A5   ; _ShrMan
  10009911: 83 C4 20           add         esp,20h
  10009914: 33 F6              xor         esi,esi
  10009916: E9 7C FF FF FF     jmp         10009897
  1000991B: 3B 1F              cmp         ebx,dword ptr [edi]
  1000991D: 7C 28              jl          10009947
  1000991F: 8D 45 F4           lea         eax,[ebp-0Ch]
  10009922: 50                 push        eax
  10009923: E8 56 FE FF FF     call        1000977E   ; _ZeroMan
  10009928: FF 77 0C           push        dword ptr [edi+0Ch]
  1000992B: 80 4D F7 80        or          byte ptr [ebp-9],80h
  1000992F: 8D 45 F4           lea         eax,[ebp-0Ch]
  10009932: 50                 push        eax
  10009933: E8 6D FE FF FF     call        100097A5   ; _ShrMan
  10009938: 8B 77 14           mov         esi,dword ptr [edi+14h]
  1000993B: 83 C4 0C           add         esp,0Ch
  1000993E: 03 37              add         esi,dword ptr [edi]
  10009940: 6A 01              push        1
  10009942: E9 52 FF FF FF     jmp         10009899
  10009947: FF 77 0C           push        dword ptr [edi+0Ch]
  1000994A: 8B 77 14           mov         esi,dword ptr [edi+14h]
  1000994D: 80 65 F7 7F        and         byte ptr [ebp-9],7Fh
  10009951: 8D 45 F4           lea         eax,[ebp-0Ch]
  10009954: 50                 push        eax
  10009955: 03 F3              add         esi,ebx
  10009957: E8 49 FE FF FF     call        100097A5   ; _ShrMan
  1000995C: 59                 pop         ecx
  1000995D: 59                 pop         ecx
  1000995E: 33 C0              xor         eax,eax
  10009960: 6A 1F              push        1Fh
  10009962: 59                 pop         ecx
  10009963: 2B 4F 0C           sub         ecx,dword ptr [edi+0Ch]
  10009966: 8B 7F 10           mov         edi,dword ptr [edi+10h]
  10009969: D3 E6              shl         esi,cl
  1000996B: 8B 4D 08           mov         ecx,dword ptr [ebp+8]
  1000996E: F7 D9              neg         ecx
  10009970: 1B C9              sbb         ecx,ecx
  10009972: 81 E1 00 00 00 80  and         ecx,80000000h
  10009978: 0B F1              or          esi,ecx
  1000997A: 0B 75 F4           or          esi,dword ptr [ebp-0Ch]
  1000997D: 83 FF 40           cmp         edi,40h
  10009980: 75 0D              jne         1000998F
  10009982: 8B 4D 0C           mov         ecx,dword ptr [ebp+0Ch]
  10009985: 8B 55 F8           mov         edx,dword ptr [ebp-8]
  10009988: 89 71 04           mov         dword ptr [ecx+4],esi
  1000998B: 89 11              mov         dword ptr [ecx],edx
  1000998D: EB 0A              jmp         10009999
  1000998F: 83 FF 20           cmp         edi,20h
  10009992: 75 05              jne         10009999
  10009994: 8B 4D 0C           mov         ecx,dword ptr [ebp+0Ch]
  10009997: 89 31              mov         dword ptr [ecx],esi
  10009999: 5F                 pop         edi
  1000999A: 5E                 pop         esi
  1000999B: 5B                 pop         ebx
  1000999C: C9                 leave
  1000999D: C3                 ret
  1000999E: 68 B0 1A 01 10     push        10011AB0h
  100099A3: FF 74 24 0C        push        dword ptr [esp+0Ch]
  100099A7: FF 74 24 0C        push        dword ptr [esp+0Ch]
  100099AB: E8 82 FE FF FF     call        10009832   ; _ld12cvt
  100099B0: 83 C4 0C           add         esp,0Ch
  100099B3: C3                 ret

; ---- _ld12tof ----
  100099B4: 68 C8 1A 01 10     push        10011AC8h
  100099B9: FF 74 24 0C        push        dword ptr [esp+0Ch]
  100099BD: FF 74 24 0C        push        dword ptr [esp+0Ch]
  100099C1: E8 6C FE FF FF     call        10009832   ; _ld12cvt
  100099C6: 83 C4 0C           add         esp,0Ch
  100099C9: C3                 ret

