; The DrumSynth engine in bin/ds2wav.dll
; Made by tools/disasm/make_listings.py from bin/ds2wav.dll (dumpbin /disasm).
; Notes after ';' are added: names of globals and calls, values of constants.

; ===== 10001000-10003010: drumsynth.c: DllMain, LongestEnv, LoudestEnv, UpdateEnv, getEnv, waveform, GetPrivateProfileFloat, ds2mem, ds2buf, ds2wav
  10001000: B8 01 00 00 00     mov         eax,1
  10001005: C2 0C 00           ret         0Ch

; ---- LongestEnv ----
  10001010: 83 EC 10           sub         esp,10h
  10001013: D9 05 14 E1 00 10  fld         dword ptr ds:[1000E114h]   ; float 0.0
  10001019: 53                 push        ebx
  1000101A: 55                 push        ebp
  1000101B: 56                 push        esi
  1000101C: BA A4 4F 01 10     mov         edx,10014FA4h   ; &envpts[1][0][1]
  10001021: 57                 push        edi
  10001022: C7 44 24 14 01 00  mov         dword ptr [esp+14h],1
            00 00
  1000102A: BB 60 00 00 00     mov         ebx,60h
  1000102F: BD 98 5A 01 10     mov         ebp,10015A98h   ; &envData[1][MAX]
  10001034: 89 54 24 1C        mov         dword ptr [esp+1Ch],edx
  10001038: 33 FF              xor         edi,edi
  1000103A: 8B CA              mov         ecx,edx
  1000103C: 8B 44 24 14        mov         eax,dword ptr [esp+14h]
  10001040: 89 7C 24 18        mov         dword ptr [esp+18h],edi
  10001044: 48                 dec         eax
  10001045: 83 F8 02           cmp         eax,2
  10001048: 7E 07              jle         10001051
  1000104A: 8D 47 FC           lea         eax,[edi-4]
  1000104D: 89 44 24 18        mov         dword ptr [esp+18h],eax
  10001051: D9 01              fld         dword ptr [ecx]
  10001053: D8 1D 14 E1 00 10  fcomp       dword ptr ds:[1000E114h]   ; float 0.0
  10001059: 33 F6              xor         esi,esi
  1000105B: DF E0              fnstsw      ax
  1000105D: F6 C4 01           test        ah,1
  10001060: 75 14              jne         10001076
  10001062: D9 42 04           fld         dword ptr [edx+4]
  10001065: D8 1D 14 E1 00 10  fcomp       dword ptr ds:[1000E114h]   ; float 0.0
  1000106B: 83 C2 04           add         edx,4
  1000106E: 46                 inc         esi
  1000106F: DF E0              fnstsw      ax
  10001071: F6 C4 01           test        ah,1
  10001074: 74 EC              je          10001062
  10001076: D9 05 40 5B 01 10  fld         dword ptr ds:[10015B40h]   ; timestretch
  1000107C: 8D 14 33           lea         edx,[ebx+esi]
  1000107F: D8 0C 95 20 4E 01  fmul        dword ptr [edx*4+10014E20h]   ; envpts[0][0][0] (base)
            10
  10001086: 8B 54 24 18        mov         edx,dword ptr [esp+18h]
  1000108A: D9 5C 24 10        fstp        dword ptr [esp+10h]
  1000108E: 8B 44 24 10        mov         eax,dword ptr [esp+10h]
  10001092: 89 45 00           mov         dword ptr [ebp],eax
  10001095: 8B 82 80 28 01 10  mov         eax,dword ptr [edx+10012880h]   ; chkOn[0] (base)
  1000109B: 83 F8 01           cmp         eax,1
  1000109E: 75 13              jne         100010B3
  100010A0: D9 44 24 10        fld         dword ptr [esp+10h]
  100010A4: D8 D9              fcomp       st(1)
  100010A6: DF E0              fnstsw      ax
  100010A8: F6 C4 41           test        ah,41h
  100010AB: 75 06              jne         100010B3
  100010AD: DD D8              fstp        st(0)
  100010AF: D9 44 24 10        fld         dword ptr [esp+10h]
  100010B3: 8B 74 24 14        mov         esi,dword ptr [esp+14h]
  100010B7: 8B 54 24 1C        mov         edx,dword ptr [esp+1Ch]
  100010BB: 81 C1 80 01 00 00  add         ecx,180h
  100010C1: 46                 inc         esi
  100010C2: 83 C7 04           add         edi,4
  100010C5: 81 C2 80 01 00 00  add         edx,180h
  100010CB: 83 C3 60           add         ebx,60h
  100010CE: 83 C5 18           add         ebp,18h
  100010D1: 81 F9 A4 58 01 10  cmp         ecx,100158A4h
  100010D7: 89 74 24 14        mov         dword ptr [esp+14h],esi
  100010DB: 89 54 24 1C        mov         dword ptr [esp+1Ch],edx
  100010DF: 0F 8C 57 FF FF FF  jl          1000103C
  100010E5: D8 0D 10 E1 00 10  fmul        dword ptr ds:[1000E110h]   ; float -0.0008333333535119891
  100010EB: E8 70 1F 00 00     call        10003060   ; _ftol
  100010F0: B9 02 00 00 00     mov         ecx,2
  100010F5: 5F                 pop         edi
  100010F6: 2B C8              sub         ecx,eax
  100010F8: 5E                 pop         esi
  100010F9: 5D                 pop         ebp
  100010FA: 5B                 pop         ebx
  100010FB: 8D 04 49           lea         eax,[ecx+ecx*2]
  100010FE: 8D 04 80           lea         eax,[eax+eax*4]
  10001101: 8D 04 80           lea         eax,[eax+eax*4]
  10001104: C1 E0 04           shl         eax,4
  10001107: 83 C4 10           add         esp,10h
  1000110A: C3                 ret

; ---- LoudestEnv ----
  10001110: 51                 push        ecx
  10001111: D9 05 14 E1 00 10  fld         dword ptr ds:[1000E114h]   ; float 0.0
  10001117: 33 C9              xor         ecx,ecx
  10001119: BA 01 00 00 00     mov         edx,1
  1000111E: 39 91 80 28 01 10  cmp         dword ptr [ecx+10012880h],edx   ; chkOn[0] (base)
  10001124: 75 19              jne         1000113F
  10001126: DB 81 40 5A 01 10  fild        dword ptr [ecx+10015A40h]   ; sliLev[0] (base)
  1000112C: D9 54 24 00        fst         dword ptr [esp]
  10001130: D8 D9              fcomp       st(1)
  10001132: DF E0              fnstsw      ax
  10001134: F6 C4 41           test        ah,41h
  10001137: 75 06              jne         1000113F
  10001139: DD D8              fstp        st(0)
  1000113B: D9 44 24 00        fld         dword ptr [esp]
  1000113F: 83 C1 04           add         ecx,4
  10001142: 83 F9 14           cmp         ecx,14h
  10001145: 7C D7              jl          1000111E
  10001147: D9 C0              fld         st(0)
  10001149: DE C9              fmulp       st(1),st
  1000114B: 59                 pop         ecx
  1000114C: C3                 ret

; ---- UpdateEnv ----
  10001150: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  10001154: 56                 push        esi
  10001155: 57                 push        edi
  10001156: 8D 34 40           lea         esi,[eax+eax*2]
  10001159: 8D 3C 40           lea         edi,[eax+eax*2]
  1000115C: C1 E6 03           shl         esi,3
  1000115F: C1 E7 05           shl         edi,5
  10001162: D9 86 88 5A 01 10  fld         dword ptr [esi+10015A88h]   ; envData[0][PNT] (base)
  10001168: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  1000116E: E8 ED 1E 00 00     call        10003060   ; _ftol
  10001173: D9 05 40 5B 01 10  fld         dword ptr ds:[10015B40h]   ; timestretch
  10001179: 03 C7              add         eax,edi
  1000117B: D8 0C 85 20 4E 01  fmul        dword ptr [eax*4+10014E20h]   ; envpts[0][0][0] (base)
            10
  10001182: D9 96 90 5A 01 10  fst         dword ptr [esi+10015A90h]   ; envData[0][NEXTT] (base)
  10001188: D8 1D 14 E1 00 10  fcomp       dword ptr ds:[1000E114h]   ; float 0.0
  1000118E: DF E0              fnstsw      ax
  10001190: F6 C4 01           test        ah,1
  10001193: 74 12              je          100011A7
  10001195: D9 05 40 5B 01 10  fld         dword ptr ds:[10015B40h]   ; timestretch
  1000119B: D8 0D 24 E1 00 10  fmul        dword ptr ds:[1000E124h]   ; float 442000.0
  100011A1: D9 9E 90 5A 01 10  fstp        dword ptr [esi+10015A90h]   ; envData[0][NEXTT] (base)
  100011A7: D9 86 88 5A 01 10  fld         dword ptr [esi+10015A88h]   ; envData[0][PNT] (base)
  100011AD: E8 AE 1E 00 00     call        10003060   ; _ftol
  100011B2: 03 C7              add         eax,edi
  100011B4: D9 04 85 A0 4E 01  fld         dword ptr [eax*4+10014EA0h]   ; envpts[0][1][0] (base)
            10
  100011BB: D8 0D 20 E1 00 10  fmul        dword ptr ds:[1000E120h]   ; float 0.009999999776482582
  100011C1: D9 96 84 5A 01 10  fst         dword ptr [esi+10015A84h]   ; envData[0][ENV] (base)
  100011C7: D9 86 88 5A 01 10  fld         dword ptr [esi+10015A88h]   ; envData[0][PNT] (base)
  100011CD: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  100011D3: E8 88 1E 00 00     call        10003060   ; _ftol
  100011D8: 03 C7              add         eax,edi
  100011DA: D9 04 85 A0 4E 01  fld         dword ptr [eax*4+10014EA0h]   ; envpts[0][1][0] (base)
            10
  100011E1: D8 0D 20 E1 00 10  fmul        dword ptr ds:[1000E120h]   ; float 0.009999999776482582
  100011E7: DB 44 24 10        fild        dword ptr [esp+10h]
  100011EB: D8 AE 90 5A 01 10  fsubr       dword ptr [esi+10015A90h]   ; envData[0][NEXTT] (base)
  100011F1: DC 15 18 E1 00 10  fcom        qword ptr ds:[1000E118h]   ; double 1.0
  100011F7: DF E0              fnstsw      ax
  100011F9: F6 C4 01           test        ah,1
  100011FC: 74 08              je          10001206
  100011FE: DD D8              fstp        st(0)
  10001200: D9 05 28 E1 00 10  fld         dword ptr ds:[1000E128h]   ; float 1.0
  10001206: D9 C9              fxch        st(1)
  10001208: D8 E2              fsub        st,st(2)
  1000120A: 5F                 pop         edi
  1000120B: D8 F1              fdiv        st,st(1)
  1000120D: D9 9E 8C 5A 01 10  fstp        dword ptr [esi+10015A8Ch]   ; envData[0][dENV] (base)
  10001213: DD D8              fstp        st(0)
  10001215: DD D8              fstp        st(0)
  10001217: D9 86 88 5A 01 10  fld         dword ptr [esi+10015A88h]   ; envData[0][PNT] (base)
  1000121D: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  10001223: D9 9E 88 5A 01 10  fstp        dword ptr [esi+10015A88h]   ; envData[0][PNT] (base)
  10001229: 5E                 pop         esi
  1000122A: C3                 ret

; ---- getEnv ----
  10001230: 81 EC 0C 01 00 00  sub         esp,10Ch
  10001236: 8B 84 24 1C 01 00  mov         eax,dword ptr [esp+0000011Ch]
            00
  1000123D: 8B 94 24 18 01 00  mov         edx,dword ptr [esp+00000118h]
            00
  10001244: 55                 push        ebp
  10001245: 56                 push        esi
  10001246: 57                 push        edi
  10001247: 50                 push        eax
  10001248: 8B 84 24 24 01 00  mov         eax,dword ptr [esp+00000124h]
            00
  1000124F: 8D 4C 24 18        lea         ecx,[esp+18h]
  10001253: 68 00 01 00 00     push        100h
  10001258: 51                 push        ecx
  10001259: 68 4C F0 00 10     push        1000F04Ch   ; &"0,0 100,0"
  1000125E: 52                 push        edx
  1000125F: 50                 push        eax
  10001260: 33 F6              xor         esi,esi
  10001262: 33 ED              xor         ebp,ebp
  10001264: FF 15 00 E0 00 10  call        dword ptr ds:[1000E000h]   ; GetPrivateProfileStringA
  1000126A: 8A 44 24 14        mov         al,byte ptr [esp+14h]
  1000126E: 8B BC 24 1C 01 00  mov         edi,dword ptr [esp+0000011Ch]
            00
  10001275: 84 C0              test        al,al
  10001277: C6 84 24 14 01 00  mov         byte ptr [esp+00000114h],0
            00 00
  1000127F: 74 7B              je          100012FC
  10001281: 53                 push        ebx
  10001282: 8D 5C 24 18        lea         ebx,[esp+18h]
  10001286: 8A 03              mov         al,byte ptr [ebx]
  10001288: 3C 2C              cmp         al,2Ch
  1000128A: 75 2C              jne         100012B8
  1000128C: 8D 0C 7F           lea         ecx,[edi+edi*2]
  1000128F: 8D 54 24 10        lea         edx,[esp+10h]
  10001293: C1 E1 05           shl         ecx,5
  10001296: 03 CD              add         ecx,ebp
  10001298: 8D 34 8D 20 4E 01  lea         esi,[ecx*4+10014E20h]
            10
  1000129F: 56                 push        esi
  100012A0: 68 48 F0 00 10     push        1000F048h   ; &"%f"
  100012A5: 52                 push        edx
  100012A6: E8 DC 1D 00 00     call        10003087   ; sscanf
  100012AB: 83 C4 0C           add         esp,0Ch
  100012AE: 85 C0              test        eax,eax
  100012B0: 75 02              jne         100012B4
  100012B2: 89 06              mov         dword ptr [esi],eax
  100012B4: 33 F6              xor         esi,esi
  100012B6: EB 3B              jmp         100012F3
  100012B8: 3C 20              cmp         al,20h
  100012BA: 75 2D              jne         100012E9
  100012BC: 8D 04 7F           lea         eax,[edi+edi*2]
  100012BF: 8D 4C 24 10        lea         ecx,[esp+10h]
  100012C3: C1 E0 05           shl         eax,5
  100012C6: 03 C5              add         eax,ebp
  100012C8: 8D 34 85 A0 4E 01  lea         esi,[eax*4+10014EA0h]
            10
  100012CF: 56                 push        esi
  100012D0: 68 48 F0 00 10     push        1000F048h   ; &"%f"
  100012D5: 51                 push        ecx
  100012D6: E8 AC 1D 00 00     call        10003087   ; sscanf
  100012DB: 83 C4 0C           add         esp,0Ch
  100012DE: 85 C0              test        eax,eax
  100012E0: 75 02              jne         100012E4
  100012E2: 89 06              mov         dword ptr [esi],eax
  100012E4: 33 F6              xor         esi,esi
  100012E6: 45                 inc         ebp
  100012E7: EB 0A              jmp         100012F3
  100012E9: 88 44 34 10        mov         byte ptr [esp+esi+10h],al
  100012ED: 46                 inc         esi
  100012EE: C6 44 34 10 00     mov         byte ptr [esp+esi+10h],0
  100012F3: 8A 43 01           mov         al,byte ptr [ebx+1]
  100012F6: 43                 inc         ebx
  100012F7: 84 C0              test        al,al
  100012F9: 75 8B              jne         10001286
  100012FB: 5B                 pop         ebx
  100012FC: 8D 34 7F           lea         esi,[edi+edi*2]
  100012FF: 8D 54 24 0C        lea         edx,[esp+0Ch]
  10001303: C1 E6 05           shl         esi,5
  10001306: 03 F5              add         esi,ebp
  10001308: C1 E6 02           shl         esi,2
  1000130B: 8D AE A0 4E 01 10  lea         ebp,[esi+10014EA0h]
  10001311: 55                 push        ebp
  10001312: 68 48 F0 00 10     push        1000F048h   ; &"%f"
  10001317: 52                 push        edx
  10001318: E8 6A 1D 00 00     call        10003087   ; sscanf
  1000131D: 83 C4 0C           add         esp,0Ch
  10001320: 85 C0              test        eax,eax
  10001322: 75 03              jne         10001327
  10001324: 89 45 00           mov         dword ptr [ebp],eax
  10001327: C7 86 24 4E 01 10  mov         dword ptr [esi+10014E24h],0BF800000h   ; envpts[0][0][1] (base), &envpts[0][0][1]
            00 00 80 BF
  10001331: 8B 8E 20 4E 01 10  mov         ecx,dword ptr [esi+10014E20h]   ; envpts[0][0][0] (base)
  10001337: 8D 04 7F           lea         eax,[edi+edi*2]
  1000133A: 5F                 pop         edi
  1000133B: 5E                 pop         esi
  1000133C: 5D                 pop         ebp
  1000133D: 89 0C C5 80 5A 01  mov         dword ptr [eax*8+10015A80h],ecx   ; envData[0][MAX] (base), &envData[0][MAX]
            10
  10001344: 81 C4 0C 01 00 00  add         esp,10Ch
  1000134A: C3                 ret

; ---- waveform ----
  10001350: 8B 44 24 08        mov         eax,dword ptr [esp+8]
  10001354: 83 F8 03           cmp         eax,3
  10001357: 0F 87 C4 00 00 00  ja          10001421
  1000135D: FF 24 85 50 14 00  jmp         dword ptr [eax*4+10001450h]
            10
  10001364: D9 44 24 04        fld         dword ptr [esp+4]
  10001368: DD 05 50 E1 00 10  fld         qword ptr ds:[1000E150h]   ; double 6.2831854820251465
  1000136E: E8 57 1D 00 00     call        100030CA   ; _CIfmod
  10001373: D9 FE              fsin
  10001375: C3                 ret
  10001376: D9 44 24 04        fld         dword ptr [esp+4]
  1000137A: D8 0D 4C E1 00 10  fmul        dword ptr ds:[1000E14Ch]   ; float 0.5
  10001380: DD 05 50 E1 00 10  fld         qword ptr ds:[1000E150h]   ; double 6.2831854820251465
  10001386: E8 3F 1D 00 00     call        100030CA   ; _CIfmod
  1000138B: D9 FE              fsin
  1000138D: DC C0              fadd        st(0),st
  1000138F: D9 E1              fabs
  10001391: D8 25 28 E1 00 10  fsub        dword ptr ds:[1000E128h]   ; float 1.0
  10001397: C3                 ret
  10001398: D9 44 24 04        fld         dword ptr [esp+4]
  1000139C: D8 15 48 E1 00 10  fcom        dword ptr ds:[1000E148h]   ; float 6.2831854820251465
  100013A2: DF E0              fnstsw      ax
  100013A4: F6 C4 01           test        ah,1
  100013A7: 74 46              je          100013EF
  100013A9: D8 05 48 E1 00 10  fadd        dword ptr ds:[1000E148h]   ; float 6.2831854820251465
  100013AF: D8 15 48 E1 00 10  fcom        dword ptr ds:[1000E148h]   ; float 6.2831854820251465
  100013B5: DF E0              fnstsw      ax
  100013B7: F6 C4 01           test        ah,1
  100013BA: 75 ED              jne         100013A9
  100013BC: D9 5C 24 04        fstp        dword ptr [esp+4]
  100013C0: D9 44 24 04        fld         dword ptr [esp+4]
  100013C4: DD 05 50 E1 00 10  fld         qword ptr ds:[1000E150h]   ; double 6.2831854820251465
  100013CA: E8 FB 1C 00 00     call        100030CA   ; _CIfmod
  100013CF: D8 0D 44 E1 00 10  fmul        dword ptr ds:[1000E144h]   ; float 0.6366196870803833
  100013D5: D8 25 28 E1 00 10  fsub        dword ptr ds:[1000E128h]   ; float 1.0
  100013DB: D8 15 28 E1 00 10  fcom        dword ptr ds:[1000E128h]   ; float 1.0
  100013E1: DF E0              fnstsw      ax
  100013E3: F6 C4 41           test        ah,41h
  100013E6: 75 64              jne         1000144C
  100013E8: D8 2D 40 E1 00 10  fsubr       dword ptr ds:[1000E140h]   ; float 2.0
  100013EE: C3                 ret
  100013EF: DD D8              fstp        st(0)
  100013F1: EB CD              jmp         100013C0
  100013F3: D9 44 24 04        fld         dword ptr [esp+4]
  100013F7: D8 0D 3C E1 00 10  fmul        dword ptr ds:[1000E13Ch]   ; float 0.15915493667125702
  100013FD: E8 5E 1C 00 00     call        10003060   ; _ftol
  10001402: 89 44 24 08        mov         dword ptr [esp+8],eax
  10001406: DB 44 24 08        fild        dword ptr [esp+8]
  1000140A: D8 0D 48 E1 00 10  fmul        dword ptr ds:[1000E148h]   ; float 6.2831854820251465
  10001410: D8 6C 24 04        fsubr       dword ptr [esp+4]
  10001414: D8 0D 38 E1 00 10  fmul        dword ptr ds:[1000E138h]   ; float 0.31830981373786926
  1000141A: D8 25 28 E1 00 10  fsub        dword ptr ds:[1000E128h]   ; float 1.0
  10001420: C3                 ret
  10001421: D9 44 24 04        fld         dword ptr [esp+4]
  10001425: DD 05 50 E1 00 10  fld         qword ptr ds:[1000E150h]   ; double 6.2831854820251465
  1000142B: E8 9A 1C 00 00     call        100030CA   ; _CIfmod
  10001430: D9 FE              fsin
  10001432: DC 1D 30 E1 00 10  fcomp       qword ptr ds:[1000E130h]   ; double 0.0
  10001438: DF E0              fnstsw      ax
  1000143A: F6 C4 41           test        ah,41h
  1000143D: 75 07              jne         10001446
  1000143F: D9 05 28 E1 00 10  fld         dword ptr ds:[1000E128h]   ; float 1.0
  10001445: C3                 ret
  10001446: D9 05 2C E1 00 10  fld         dword ptr ds:[1000E12Ch]   ; float -1.0
  1000144C: C3                 ret
  1000144D: 8D 49 00           lea         ecx,[ecx]
  10001450: 64 13 00           adc         eax,dword ptr fs:[eax]
  10001453: 10 76 13           adc         byte ptr [esi+13h],dh
  10001456: 00 10              add         byte ptr [eax],dl
  10001458: 98                 cwde
  10001459: 13 00              adc         eax,dword ptr [eax]
  1000145B: 10 F3              adc         bl,dh
  1000145D: 13 00              adc         eax,dword ptr [eax]
  1000145F: 10 83 EC 14 8B 44  adc         byte ptr [ebx+448B14ECh],al
  10001465: 24 24              and         al,24h
  10001467: 8B 54 24 1C        mov         edx,dword ptr [esp+1Ch]
  1000146B: 50                 push        eax
  1000146C: 8B 44 24 1C        mov         eax,dword ptr [esp+1Ch]
  10001470: 8D 4C 24 08        lea         ecx,[esp+8]
  10001474: 6A 10              push        10h
  10001476: 51                 push        ecx
  10001477: 68 F4 24 01 10     push        100124F4h   ; &"" (empty string)
  1000147C: 52                 push        edx
  1000147D: 50                 push        eax
  1000147E: C7 44 24 18 00 00  mov         dword ptr [esp+18h],0
            00 00
  10001486: FF 15 00 E0 00 10  call        dword ptr ds:[1000E000h]   ; GetPrivateProfileStringA
  1000148C: 8D 4C 24 00        lea         ecx,[esp]
  10001490: 8D 54 24 04        lea         edx,[esp+4]
  10001494: 51                 push        ecx
  10001495: 68 48 F0 00 10     push        1000F048h   ; &"%f"
  1000149A: 52                 push        edx
  1000149B: E8 E7 1B 00 00     call        10003087   ; sscanf
  100014A0: 8A 44 24 10        mov         al,byte ptr [esp+10h]
  100014A4: 83 C4 0C           add         esp,0Ch
  100014A7: 84 C0              test        al,al
  100014A9: 75 08              jne         100014B3
  100014AB: D9 44 24 20        fld         dword ptr [esp+20h]
  100014AF: 83 C4 14           add         esp,14h
  100014B2: C3                 ret
  100014B3: D9 44 24 00        fld         dword ptr [esp]
  100014B7: 83 C4 14           add         esp,14h
  100014BA: C3                 ret

; ---- ds2mem ----
  100014C0: 8B 44 24 0C        mov         eax,dword ptr [esp+0Ch]
  100014C4: 8B 4C 24 10        mov         ecx,dword ptr [esp+10h]
  100014C8: 8B 54 24 14        mov         edx,dword ptr [esp+14h]
  100014CC: A3 30 F0 00 10     mov         dword ptr ds:[1000F030h],eax   ; mem_t
  100014D1: 8B 44 24 18        mov         eax,dword ptr [esp+18h]
  100014D5: 89 0D 34 F0 00 10  mov         dword ptr ds:[1000F034h],ecx   ; mem_o
  100014DB: 8B 4C 24 1C        mov         ecx,dword ptr [esp+1Ch]
  100014DF: A3 3C F0 00 10     mov         dword ptr ds:[1000F03Ch],eax   ; mem_b
  100014E4: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  100014E8: 89 15 38 F0 00 10  mov         dword ptr ds:[1000F038h],edx   ; mem_n
  100014EE: 8B 54 24 20        mov         edx,dword ptr [esp+20h]
  100014F2: 6A 00              push        0
  100014F4: 68 F4 24 01 10     push        100124F4h   ; &"" (empty string)
  100014F9: 50                 push        eax
  100014FA: C7 05 F0 24 01 10  mov         dword ptr ds:[100124F0h],1   ; wavemode
            01 00 00 00
  10001504: 89 0D 40 F0 00 10  mov         dword ptr ds:[1000F040h],ecx   ; mem_tune
  1000150A: 89 15 44 F0 00 10  mov         dword ptr ds:[1000F044h],edx   ; mem_time
  10001510: E8 7B 00 00 00     call        10001590   ; ds2wav
  10001515: 8B 0D 20 5A 01 10  mov         ecx,dword ptr ds:[10015A20h]   ; wavewords
  1000151B: F7 D8              neg         eax
  1000151D: 1B C0              sbb         eax,eax
  1000151F: F7 D0              not         eax
  10001521: 23 C1              and         eax,ecx
  10001523: C2 20 00           ret         20h

; ---- ds2buf ----
  10001530: 8B 44 24 04        mov         eax,dword ptr [esp+4]
  10001534: 53                 push        ebx
  10001535: 8B 1D 20 5A 01 10  mov         ebx,dword ptr ds:[10015A20h]   ; wavewords
  1000153B: 3B C3              cmp         eax,ebx
  1000153D: 7D 02              jge         10001541
  1000153F: 8B D8              mov         ebx,eax
  10001541: 85 DB              test        ebx,ebx
  10001543: 7E 1F              jle         10001564
  10001545: 8D 0C 1B           lea         ecx,[ebx+ebx]
  10001548: 56                 push        esi
  10001549: 8B 35 EC 24 01 10  mov         esi,dword ptr ds:[100124ECh]   ; wave
  1000154F: 8B C1              mov         eax,ecx
  10001551: 57                 push        edi
  10001552: 8B 7C 24 14        mov         edi,dword ptr [esp+14h]
  10001556: C1 E9 02           shr         ecx,2
  10001559: F3 A5              rep movs    dword ptr es:[edi],dword ptr [esi]
  1000155B: 8B C8              mov         ecx,eax
  1000155D: 83 E1 03           and         ecx,3
  10001560: F3 A4              rep movs    byte ptr es:[edi],byte ptr [esi]
  10001562: 5F                 pop         edi
  10001563: 5E                 pop         esi
  10001564: A1 EC 24 01 10     mov         eax,dword ptr ds:[100124ECh]   ; wave
  10001569: 85 C0              test        eax,eax
  1000156B: 74 13              je          10001580
  1000156D: 50                 push        eax
  1000156E: E8 7F 1B 00 00     call        100030F2   ; free
  10001573: 83 C4 04           add         esp,4
  10001576: C7 05 EC 24 01 10  mov         dword ptr ds:[100124ECh],0   ; wave
            00 00 00 00
  10001580: 8B C3              mov         eax,ebx
  10001582: 5B                 pop         ebx
  10001583: C2 08 00           ret         8

; ---- ds2wav ----
  10001590: 81 EC FC 02 00 00  sub         esp,2FCh
  10001596: A1 E8 24 01 10     mov         eax,dword ptr ds:[100124E8h]
  1000159B: 53                 push        ebx
  1000159C: 55                 push        ebp
  1000159D: 56                 push        esi
  1000159E: 57                 push        edi
  1000159F: BB 01 00 00 00     mov         ebx,1
  100015A4: 33 FF              xor         edi,edi
  100015A6: 3B C3              cmp         eax,ebx
  100015A8: 89 BC 24 10 01 00  mov         dword ptr [esp+00000110h],edi
            00
  100015AF: 89 BC 24 E0 00 00  mov         dword ptr [esp+000000E0h],edi
            00
  100015B6: 89 BC 24 E4 00 00  mov         dword ptr [esp+000000E4h],edi
            00
  100015BD: 89 BC 24 38 01 00  mov         dword ptr [esp+00000138h],edi
            00
  100015C4: 89 BC 24 18 01 00  mov         dword ptr [esp+00000118h],edi
            00
  100015CB: 89 BC 24 04 01 00  mov         dword ptr [esp+00000104h],edi
            00
  100015D2: 89 BC 24 EC 00 00  mov         dword ptr [esp+000000ECh],edi
            00
  100015D9: 89 BC 24 AC 00 00  mov         dword ptr [esp+000000ACh],edi
            00
  100015E0: 89 7C 24 78        mov         dword ptr [esp+78h],edi
  100015E4: 89 BC 24 94 00 00  mov         dword ptr [esp+00000094h],edi
            00
  100015EB: 89 BC 24 98 00 00  mov         dword ptr [esp+00000098h],edi
            00
  100015F2: 89 BC 24 0C 01 00  mov         dword ptr [esp+0000010Ch],edi
            00
  100015F9: 89 BC 24 24 01 00  mov         dword ptr [esp+00000124h],edi
            00
  10001600: 89 BC 24 B8 00 00  mov         dword ptr [esp+000000B8h],edi
            00
  10001607: 89 7C 24 74        mov         dword ptr [esp+74h],edi
  1000160B: 89 BC 24 F8 00 00  mov         dword ptr [esp+000000F8h],edi
            00
  10001612: 89 7C 24 28        mov         dword ptr [esp+28h],edi
  10001616: 89 7C 24 34        mov         dword ptr [esp+34h],edi
  1000161A: 75 11              jne         1000162D
  1000161C: 8B 35 10 E0 00 10  mov         esi,dword ptr ds:[1000E010h]   ; Sleep
  10001622: 57                 push        edi
  10001623: FF D6              call        esi
  10001625: 39 1D E8 24 01 10  cmp         dword ptr ds:[100124E8h],ebx
  1000162B: 74 F5              je          10001622
  1000162D: A1 F0 24 01 10     mov         eax,dword ptr ds:[100124F0h]   ; wavemode
  10001632: 89 1D E8 24 01 10  mov         dword ptr ds:[100124E8h],ebx
  10001638: 3B C7              cmp         eax,edi
  1000163A: 75 3C              jne         10001678
  1000163C: C7 05 30 F0 00 10  mov         dword ptr ds:[1000F030h],3F800000h   ; mem_t
            00 00 80 3F
  10001646: C7 05 34 F0 00 10  mov         dword ptr ds:[1000F034h],3F800000h   ; mem_o
            00 00 80 3F
  10001650: C7 05 38 F0 00 10  mov         dword ptr ds:[1000F038h],3F800000h   ; mem_n
            00 00 80 3F
  1000165A: C7 05 3C F0 00 10  mov         dword ptr ds:[1000F03Ch],3F800000h   ; mem_b
            00 00 80 3F
  10001664: C7 05 40 F0 00 10  mov         dword ptr ds:[1000F040h],0   ; mem_tune
            00 00 00 00
  1000166E: C7 05 44 F0 00 10  mov         dword ptr ds:[1000F044h],3F800000h   ; mem_time
            00 00 80 3F
  10001678: 8B 2D 0C E0 00 10  mov         ebp,dword ptr ds:[1000E00Ch]   ; lstrcpyA
  1000167E: 8D 44 24 4C        lea         eax,[esp+4Ch]
  10001682: 68 B0 F1 00 10     push        1000F1B0h
  10001687: 50                 push        eax
  10001688: FF D5              call        ebp
  1000168A: 8B 1D 00 E0 00 10  mov         ebx,dword ptr ds:[1000E000h]   ; GetPrivateProfileStringA
  10001690: 8D 8C 24 AC 01 00  lea         ecx,[esp+000001ACh]
            00
  10001697: 8B B4 24 10 03 00  mov         esi,dword ptr [esp+00000310h]
            00
  1000169E: 8D 54 24 4C        lea         edx,[esp+4Ch]
  100016A2: 56                 push        esi
  100016A3: 6A 20              push        20h
  100016A5: 51                 push        ecx
  100016A6: 68 F4 24 01 10     push        100124F4h   ; &"" (empty string)
  100016AB: 68 A8 F1 00 10     push        1000F1A8h
  100016B0: 52                 push        edx
  100016B1: FF D3              call        ebx
  100016B3: 8D 84 24 AC 01 00  lea         eax,[esp+000001ACh]
            00
  100016BA: 68 9C F1 00 10     push        1000F19Ch
  100016BF: 50                 push        eax
  100016C0: C6 84 24 BD 01 00  mov         byte ptr [esp+000001BDh],0
            00 00
  100016C8: FF 15 08 E0 00 10  call        dword ptr ds:[1000E008h]   ; lstrcmpA
  100016CE: 85 C0              test        eax,eax
  100016D0: 74 1C              je          100016EE
  100016D2: 5F                 pop         edi
  100016D3: 5E                 pop         esi
  100016D4: 5D                 pop         ebp
  100016D5: C7 05 E8 24 01 10  mov         dword ptr ds:[100124E8h],0
            00 00 00 00
  100016DF: B8 02 00 00 00     mov         eax,2
  100016E4: 5B                 pop         ebx
  100016E5: 81 C4 FC 02 00 00  add         esp,2FCh
  100016EB: C2 0C 00           ret         0Ch
  100016EE: 8A 84 24 B7 01 00  mov         al,byte ptr [esp+000001B7h]
            00
  100016F5: 3C 31              cmp         al,31h
  100016F7: 74 20              je          10001719
  100016F9: 3C 32              cmp         al,32h
  100016FB: 74 1C              je          10001719
  100016FD: 5F                 pop         edi
  100016FE: 5E                 pop         esi
  100016FF: 5D                 pop         ebp
  10001700: C7 05 E8 24 01 10  mov         dword ptr ds:[100124E8h],0
            00 00 00 00
  1000170A: B8 01 00 00 00     mov         eax,1
  1000170F: 5B                 pop         ebx
  10001710: 81 C4 FC 02 00 00  add         esp,2FCh
  10001716: C2 0C 00           ret         0Ch
  10001719: 56                 push        esi
  1000171A: 8D 8C 24 10 02 00  lea         ecx,[esp+00000210h]
            00
  10001721: 68 00 01 00 00     push        100h
  10001726: 51                 push        ecx
  10001727: 68 F4 24 01 10     push        100124F4h   ; &"" (empty string)
  1000172C: 8D 54 24 5C        lea         edx,[esp+5Ch]
  10001730: 68 94 F1 00 10     push        1000F194h
  10001735: 52                 push        edx
  10001736: FF D3              call        ebx
  10001738: 8A 84 24 0C 02 00  mov         al,byte ptr [esp+0000020Ch]
            00
  1000173F: 84 C0              test        al,al
  10001741: 74 18              je          1000175B
  10001743: 81 FF FE 00 00 00  cmp         edi,0FEh
  10001749: 7D 0C              jge         10001757
  1000174B: 8A 84 3C 0D 02 00  mov         al,byte ptr [esp+edi+0000020Dh]
            00
  10001752: 47                 inc         edi
  10001753: 84 C0              test        al,al
  10001755: 75 EC              jne         10001743
  10001757: 85 FF              test        edi,edi
  10001759: 75 15              jne         10001770
  1000175B: C6 84 24 0C 02 00  mov         byte ptr [esp+0000020Ch],20h
            00 20
  10001763: C6 84 24 0D 02 00  mov         byte ptr [esp+0000020Dh],0
            00 00
  1000176B: BF 01 00 00 00     mov         edi,1
  10001770: C6 84 3C 0D 02 00  mov         byte ptr [esp+edi+0000020Dh],0
            00 00
  10001778: 47                 inc         edi
  10001779: 8B C7              mov         eax,edi
  1000177B: 89 BC 24 A8 00 00  mov         dword ptr [esp+000000A8h],edi
            00
  10001782: 25 01 00 00 80     and         eax,80000001h
  10001787: 79 05              jns         1000178E
  10001789: 48                 dec         eax
  1000178A: 83 C8 FE           or          eax,0FFFFFFFEh
  1000178D: 40                 inc         eax
  1000178E: 83 F8 01           cmp         eax,1
  10001791: 75 08              jne         1000179B
  10001793: 47                 inc         edi
  10001794: 89 BC 24 A8 00 00  mov         dword ptr [esp+000000A8h],edi
            00
  1000179B: 56                 push        esi
  1000179C: 68 00 00 C8 42     push        42C80000h
  100017A1: 8D 4C 24 54        lea         ecx,[esp+54h]
  100017A5: 68 8C F1 00 10     push        1000F18Ch
  100017AA: 51                 push        ecx
  100017AB: E8 B0 FC FF FF     call        10001460   ; GetPrivateProfileFloat
  100017B0: D8 0D 44 F0 00 10  fmul        dword ptr ds:[1000F044h]   ; mem_time
  100017B6: 83 C4 10           add         esp,10h
  100017B9: D8 0D 20 E1 00 10  fmul        dword ptr ds:[1000E120h]   ; float 0.009999999776482582
  100017BF: D9 15 40 5B 01 10  fst         dword ptr ds:[10015B40h]   ; timestretch
  100017C5: D8 1D 1C E2 00 10  fcomp       dword ptr ds:[1000E21Ch]   ; float 0.20000000298023224
  100017CB: DF E0              fnstsw      ax
  100017CD: F6 C4 01           test        ah,1
  100017D0: 74 0C              je          100017DE
  100017D2: C7 05 40 5B 01 10  mov         dword ptr ds:[10015B40h],3E4CCCCDh   ; timestretch
            CD CC 4C 3E
  100017DC: EB 1D              jmp         100017FB
  100017DE: D9 05 40 5B 01 10  fld         dword ptr ds:[10015B40h]   ; timestretch
  100017E4: D8 1D 18 E2 00 10  fcomp       dword ptr ds:[1000E218h]   ; float 10.0
  100017EA: DF E0              fnstsw      ax
  100017EC: F6 C4 41           test        ah,41h
  100017EF: 75 0A              jne         100017FB
  100017F1: C7 05 40 5B 01 10  mov         dword ptr ds:[10015B40h],41200000h   ; timestretch
            00 00 20 41
  100017FB: 56                 push        esi
  100017FC: 6A 00              push        0
  100017FE: 8D 54 24 54        lea         edx,[esp+54h]
  10001802: 68 84 F1 00 10     push        1000F184h
  10001807: 52                 push        edx
  10001808: C7 84 24 E4 00 00  mov         dword ptr [esp+000000E4h],0
            00 00 00 00 00
  10001813: C7 84 24 E8 00 00  mov         dword ptr [esp+000000E8h],40240000h
            00 00 00 24 40
  1000181E: E8 3D FC FF FF     call        10001460   ; GetPrivateProfileFloat
  10001823: DC 0D 10 E2 00 10  fmul        qword ptr ds:[1000E210h]   ; double 0.05
  10001829: DD 84 24 E4 00 00  fld         qword ptr [esp+000000E4h]
            00
  10001830: D9 C9              fxch        st(1)
  10001832: E8 59 1D 00 00     call        10003590   ; pow (_CIpow)
  10001837: D9 9C 24 8C 00 00  fstp        dword ptr [esp+0000008Ch]
            00
  1000183E: 56                 push        esi
  1000183F: 6A 00              push        0
  10001841: 8D 44 24 64        lea         eax,[esp+64h]
  10001845: 68 7C F1 00 10     push        1000F17Ch
  1000184A: 50                 push        eax
  1000184B: E8 10 FC FF FF     call        10001460   ; GetPrivateProfileFloat
  10001850: D9 5C 24 38        fstp        dword ptr [esp+38h]
  10001854: DD 05 08 E2 00 10  fld         qword ptr ds:[1000E208h]   ; double 1.0594631433486938
  1000185A: D9 44 24 38        fld         dword ptr [esp+38h]
  1000185E: D8 05 40 F0 00 10  fadd        dword ptr ds:[1000F040h]   ; mem_tune
  10001864: 83 C4 20           add         esp,20h
  10001867: E8 24 1D 00 00     call        10003590   ; pow (_CIpow)
  1000186C: 8B 3D 04 E0 00 10  mov         edi,dword ptr ds:[1000E004h]   ; GetPrivateProfileIntA
  10001872: 56                 push        esi
  10001873: D9 5C 24 1C        fstp        dword ptr [esp+1Ch]
  10001877: 6A 00              push        0
  10001879: 8D 4C 24 54        lea         ecx,[esp+54h]
  1000187D: 68 74 F1 00 10     push        1000F174h
  10001882: 51                 push        ecx
  10001883: FF D7              call        edi
  10001885: 56                 push        esi
  10001886: 6A 00              push        0
  10001888: 8D 54 24 54        lea         edx,[esp+54h]
  1000188C: 68 68 F1 00 10     push        1000F168h
  10001891: D1 E0              shl         eax,1
  10001893: 52                 push        edx
  10001894: 89 84 24 B4 00 00  mov         dword ptr [esp+000000B4h],eax
            00
  1000189B: E8 C0 FB FF FF     call        10001460   ; GetPrivateProfileFloat
  100018A0: D8 0D 00 E2 00 10  fmul        dword ptr ds:[1000E200h]   ; float 0.010099999606609344
  100018A6: DD 05 F8 E1 00 10  fld         qword ptr ds:[1000E1F8h]   ; double 0.5
  100018AC: 83 C4 10           add         esp,10h
  100018AF: E8 DC 1C 00 00     call        10003590   ; pow (_CIpow)
  100018B4: D9 9C 24 00 01 00  fstp        dword ptr [esp+00000100h]
            00
  100018BB: 56                 push        esi
  100018BC: 6A 00              push        0
  100018BE: 8D 44 24 54        lea         eax,[esp+54h]
  100018C2: 68 5C F1 00 10     push        1000F15Ch
  100018C7: 50                 push        eax
  100018C8: FF D7              call        edi
  100018CA: 56                 push        esi
  100018CB: 8D 4C 24 50        lea         ecx,[esp+50h]
  100018CF: 68 50 F1 00 10     push        1000F150h
  100018D4: 51                 push        ecx
  100018D5: 6A 07              push        7
  100018D7: 89 84 24 18 01 00  mov         dword ptr [esp+00000118h],eax
            00
  100018DE: E8 4D F9 FF FF     call        10001230   ; getEnv
  100018E3: 83 C4 10           add         esp,10h
  100018E6: 8D 54 24 4C        lea         edx,[esp+4Ch]
  100018EA: 68 48 F1 00 10     push        1000F148h
  100018EF: 52                 push        edx
  100018F0: FF D5              call        ebp
  100018F2: 56                 push        esi
  100018F3: 6A 00              push        0
  100018F5: 8D 44 24 54        lea         eax,[esp+54h]
  100018F9: 68 44 F1 00 10     push        1000F144h
  100018FE: 50                 push        eax
  100018FF: FF D7              call        edi
  10001901: 56                 push        esi
  10001902: 6A 00              push        0
  10001904: 8D 4C 24 54        lea         ecx,[esp+54h]
  10001908: 68 84 F1 00 10     push        1000F184h
  1000190D: 51                 push        ecx
  1000190E: A3 84 28 01 10     mov         dword ptr ds:[10012884h],eax   ; chkOn[1]
  10001913: FF D7              call        edi
  10001915: 56                 push        esi
  10001916: A3 44 5A 01 10     mov         dword ptr ds:[10015A44h],eax   ; sliLev[1]
  1000191B: 6A 00              push        0
  1000191D: 8D 54 24 54        lea         edx,[esp+54h]
  10001921: 68 3C F1 00 10     push        1000F13Ch
  10001926: 52                 push        edx
  10001927: FF D7              call        edi
  10001929: 8B D8              mov         ebx,eax
  1000192B: 56                 push        esi
  1000192C: 8D 44 24 50        lea         eax,[esp+50h]
  10001930: 68 30 F1 00 10     push        1000F130h
  10001935: 50                 push        eax
  10001936: 6A 02              push        2
  10001938: 89 5C 24 40        mov         dword ptr [esp+40h],ebx
  1000193C: E8 EF F8 FF FF     call        10001230   ; getEnv
  10001941: A1 44 5A 01 10     mov         eax,dword ptr ds:[10015A44h]   ; sliLev[1]
  10001946: 8B 0D 84 28 01 10  mov         ecx,dword ptr ds:[10012884h]   ; chkOn[1]
  1000194C: 8B D0              mov         edx,eax
  1000194E: 83 C4 10           add         esp,10h
  10001951: 0F AF D0           imul        edx,eax
  10001954: 89 54 24 20        mov         dword ptr [esp+20h],edx
  10001958: 89 8C 24 30 01 00  mov         dword ptr [esp+00000130h],ecx
            00
  1000195F: DB 44 24 20        fild        dword ptr [esp+20h]
  10001963: 85 DB              test        ebx,ebx
  10001965: D8 0D 38 F0 00 10  fmul        dword ptr ds:[1000F038h]   ; mem_n
  1000196B: 7D 4F              jge         100019BC
  1000196D: DB 44 24 30        fild        dword ptr [esp+30h]
  10001971: F7 DB              neg         ebx
  10001973: 89 5C 24 20        mov         dword ptr [esp+20h],ebx
  10001977: D9 C0              fld         st(0)
  10001979: D8 0D F0 E1 00 10  fmul        dword ptr ds:[1000E1F0h]   ; float 0.009523809887468815
  1000197F: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  10001985: D9 9C 24 20 01 00  fstp        dword ptr [esp+00000120h]
            00
  1000198C: DB 44 24 20        fild        dword ptr [esp+20h]
  10001990: D8 0D F0 E1 00 10  fmul        dword ptr ds:[1000E1F0h]   ; float 0.009523809887468815
  10001996: D9 9C 24 EC 00 00  fstp        dword ptr [esp+000000ECh]
            00
  1000199D: D9 C0              fld         st(0)
  1000199F: D8 C9              fmul        st,st(1)
  100019A1: D8 0D EC E1 00 10  fmul        dword ptr ds:[1000E1ECh]   ; float 0.0005000000237487257
  100019A7: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  100019AD: D8 CA              fmul        st,st(2)
  100019AF: D9 9C 24 F0 00 00  fstp        dword ptr [esp+000000F0h]
            00
  100019B6: DD D8              fstp        st(0)
  100019B8: DD D8              fstp        st(0)
  100019BA: EB 3C              jmp         100019F8
  100019BC: F7 DB              neg         ebx
  100019BE: 89 5C 24 20        mov         dword ptr [esp+20h],ebx
  100019C2: C7 84 24 20 01 00  mov         dword ptr [esp+00000120h],3F800000h
            00 00 00 80 3F
  100019CD: DB 44 24 20        fild        dword ptr [esp+20h]
  100019D1: D8 0D E8 E1 00 10  fmul        dword ptr ds:[1000E1E8h]   ; float 0.019999999552965164
  100019D7: D9 9C 24 18 01 00  fstp        dword ptr [esp+00000118h]
            00
  100019DE: DB 44 24 30        fild        dword ptr [esp+30h]
  100019E2: D9 E1              fabs
  100019E4: D8 0D E4 E1 00 10  fmul        dword ptr ds:[1000E1E4h]   ; float 0.009999999776482582
  100019EA: D9 9C 24 04 01 00  fstp        dword ptr [esp+00000104h]
            00
  100019F1: D9 9C 24 F0 00 00  fstp        dword ptr [esp+000000F0h]
            00
  100019F8: 6A 01              push        1
  100019FA: E8 AB 18 00 00     call        100032AA   ; srand
  100019FF: 83 C4 04           add         esp,4
  10001A02: 8D 44 24 4C        lea         eax,[esp+4Ch]
  10001A06: 68 28 F1 00 10     push        1000F128h
  10001A0B: 50                 push        eax
  10001A0C: FF D5              call        ebp
  10001A0E: 56                 push        esi
  10001A0F: 6A 00              push        0
  10001A11: 8D 4C 24 54        lea         ecx,[esp+54h]
  10001A15: 68 44 F1 00 10     push        1000F144h
  10001A1A: 51                 push        ecx
  10001A1B: FF D7              call        edi
  10001A1D: 56                 push        esi
  10001A1E: 68 80 00 00 00     push        80h
  10001A23: 8D 54 24 54        lea         edx,[esp+54h]
  10001A27: 8B D8              mov         ebx,eax
  10001A29: 68 84 F1 00 10     push        1000F184h
  10001A2E: 52                 push        edx
  10001A2F: A3 80 28 01 10     mov         dword ptr ds:[10012880h],eax   ; chkOn[0]
  10001A34: 89 9C 24 0C 01 00  mov         dword ptr [esp+0000010Ch],ebx
            00
  10001A3B: FF D7              call        edi
  10001A3D: 8B C8              mov         ecx,eax
  10001A3F: 56                 push        esi
  10001A40: 0F AF C8           imul        ecx,eax
  10001A43: 89 4C 24 24        mov         dword ptr [esp+24h],ecx
  10001A47: 8D 54 24 50        lea         edx,[esp+50h]
  10001A4B: DB 44 24 24        fild        dword ptr [esp+24h]
  10001A4F: 68 30 F1 00 10     push        1000F130h
  10001A54: 52                 push        edx
  10001A55: 6A 01              push        1
  10001A57: A3 40 5A 01 10     mov         dword ptr ds:[10015A40h],eax   ; sliLev[0]
  10001A5C: D8 0D 30 F0 00 10  fmul        dword ptr ds:[1000F030h]   ; mem_t
  10001A62: D9 9C 24 4C 01 00  fstp        dword ptr [esp+0000014Ch]
            00
  10001A69: E8 C2 F7 FF FF     call        10001230   ; getEnv
  10001A6E: 56                 push        esi
  10001A6F: 68 00 00 48 43     push        43480000h
  10001A74: 8D 44 24 64        lea         eax,[esp+64h]
  10001A78: 68 24 F1 00 10     push        1000F124h
  10001A7D: 50                 push        eax
  10001A7E: E8 DD F9 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001A83: D8 4C 24 38        fmul        dword ptr [esp+38h]
  10001A87: 83 C4 20           add         esp,20h
  10001A8A: D8 0D E0 E1 00 10  fmul        dword ptr ds:[1000E1E0h]   ; float 0.00014247586659621447
  10001A90: D9 54 24 2C        fst         dword ptr [esp+2Ch]
  10001A94: D9 E1              fabs
  10001A96: DC 1D D8 E1 00 10  fcomp       qword ptr ds:[1000E1D8h]   ; double 0.0010000000474974513
  10001A9C: DF E0              fnstsw      ax
  10001A9E: F6 C4 01           test        ah,1
  10001AA1: 74 08              je          10001AAB
  10001AA3: C7 44 24 2C 6F 12  mov         dword ptr [esp+2Ch],3A83126Fh
            83 3A
  10001AAB: 56                 push        esi
  10001AAC: 68 00 00 F0 42     push        42F00000h
  10001AB1: 8D 4C 24 54        lea         ecx,[esp+54h]
  10001AB5: 68 20 F1 00 10     push        1000F120h
  10001ABA: 51                 push        ecx
  10001ABB: E8 A0 F9 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001AC0: D8 4C 24 28        fmul        dword ptr [esp+28h]
  10001AC4: 56                 push        esi
  10001AC5: 6A 00              push        0
  10001AC7: 8D 54 24 64        lea         edx,[esp+64h]
  10001ACB: 68 18 F1 00 10     push        1000F118h
  10001AD0: D8 0D E0 E1 00 10  fmul        dword ptr ds:[1000E1E0h]   ; float 0.00014247586659621447
  10001AD6: 52                 push        edx
  10001AD7: D9 5C 24 68        fstp        dword ptr [esp+68h]
  10001ADB: E8 80 F9 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001AE0: D9 94 24 8C 00 00  fst         dword ptr [esp+0000008Ch]
            00
  10001AE7: D8 1D 14 E1 00 10  fcomp       dword ptr ds:[1000E114h]   ; float 0.0
  10001AED: 83 C4 20           add         esp,20h
  10001AF0: DF E0              fnstsw      ax
  10001AF2: F6 C4 41           test        ah,41h
  10001AF5: 75 7C              jne         10001B73
  10001AF7: DD 05 D0 E1 00 10  fld         qword ptr ds:[1000E1D0h]   ; double 10.0
  10001AFD: D9 44 24 6C        fld         dword ptr [esp+6Ch]
  10001B01: D8 25 CC E1 00 10  fsub        dword ptr ds:[1000E1CCh]   ; float 20.0
  10001B07: D8 0D C8 E1 00 10  fmul        dword ptr ds:[1000E1C8h]   ; float 0.03333333507180214
  10001B0D: E8 7E 1A 00 00     call        10003590   ; pow (_CIpow)
  10001B12: D8 0D C4 E1 00 10  fmul        dword ptr ds:[1000E1C4h]   ; float -4.0
  10001B18: C7 84 24 38 01 00  mov         dword ptr [esp+00000138h],1
            00 01 00 00 00
  10001B23: D8 35 98 5A 01 10  fdiv        dword ptr ds:[10015A98h]   ; envData[1][MAX]
  10001B29: D9 5C 24 6C        fstp        dword ptr [esp+6Ch]
  10001B2D: D9 44 24 48        fld         dword ptr [esp+48h]
  10001B31: D8 64 24 2C        fsub        dword ptr [esp+2Ch]
  10001B35: D9 05 98 5A 01 10  fld         dword ptr ds:[10015A98h]   ; envData[1][MAX]
  10001B3B: D8 4C 24 6C        fmul        dword ptr [esp+6Ch]
  10001B3F: D9 EA              fldl2e
  10001B41: DE C9              fmulp       st(1),st
  10001B43: D9 C0              fld         st(0)
  10001B45: D9 FC              frndint
  10001B47: D9 C9              fxch        st(1)
  10001B49: D8 E1              fsub        st,st(1)
  10001B4B: D9 F0              f2xm1
  10001B4D: D9 E8              fld1
  10001B4F: DE C1              faddp       st(1),st
  10001B51: D9 FD              fscale
  10001B53: DD D9              fstp        st(1)
  10001B55: D9 C9              fxch        st(1)
  10001B57: D9 C9              fxch        st(1)
  10001B59: D8 2D 28 E1 00 10  fsubr       dword ptr ds:[1000E128h]   ; float 1.0
  10001B5F: DE F9              fdivp       st(1),st
  10001B61: D8 44 24 2C        fadd        dword ptr [esp+2Ch]
  10001B65: D9 5C 24 48        fstp        dword ptr [esp+48h]
  10001B69: D9 44 24 2C        fld         dword ptr [esp+2Ch]
  10001B6D: D8 64 24 48        fsub        dword ptr [esp+48h]
  10001B71: EB 08              jmp         10001B7B
  10001B73: D9 44 24 48        fld         dword ptr [esp+48h]
  10001B77: D8 64 24 2C        fsub        dword ptr [esp+2Ch]
  10001B7B: D9 9C 24 CC 00 00  fstp        dword ptr [esp+000000CCh]
            00
  10001B82: 56                 push        esi
  10001B83: 68 00 00 B4 42     push        42B40000h
  10001B88: 8D 44 24 54        lea         eax,[esp+54h]
  10001B8C: 68 10 F1 00 10     push        1000F110h
  10001B91: 50                 push        eax
  10001B92: E8 C9 F8 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001B97: D8 0D C0 E1 00 10  fmul        dword ptr ds:[1000E1C0h]   ; float 0.01745329238474369
  10001B9D: 83 C4 10           add         esp,10h
  10001BA0: 8D 4C 24 4C        lea         ecx,[esp+4Ch]
  10001BA4: 68 04 F1 00 10     push        1000F104h
  10001BA9: 51                 push        ecx
  10001BAA: D9 5C 24 44        fstp        dword ptr [esp+44h]
  10001BAE: FF D5              call        ebp
  10001BB0: 56                 push        esi
  10001BB1: 6A 00              push        0
  10001BB3: 8D 54 24 54        lea         edx,[esp+54h]
  10001BB7: 68 44 F1 00 10     push        1000F144h
  10001BBC: 52                 push        edx
  10001BBD: FF D7              call        edi
  10001BBF: A3 88 28 01 10     mov         dword ptr ds:[10012888h],eax   ; chkOn[2]
  10001BC4: 56                 push        esi
  10001BC5: 89 84 24 44 01 00  mov         dword ptr [esp+00000144h],eax
            00
  10001BCC: 68 80 00 00 00     push        80h
  10001BD1: 8D 44 24 54        lea         eax,[esp+54h]
  10001BD5: 68 84 F1 00 10     push        1000F184h
  10001BDA: 50                 push        eax
  10001BDB: FF D7              call        edi
  10001BDD: 8B C8              mov         ecx,eax
  10001BDF: 56                 push        esi
  10001BE0: 0F AF C8           imul        ecx,eax
  10001BE3: 89 4C 24 24        mov         dword ptr [esp+24h],ecx
  10001BE7: 8D 54 24 50        lea         edx,[esp+50h]
  10001BEB: DB 44 24 24        fild        dword ptr [esp+24h]
  10001BEF: 68 F8 F0 00 10     push        1000F0F8h
  10001BF4: 52                 push        edx
  10001BF5: 6A 03              push        3
  10001BF7: A3 48 5A 01 10     mov         dword ptr ds:[10015A48h],eax   ; sliLev[2]
  10001BFC: D8 0D 34 F0 00 10  fmul        dword ptr ds:[1000F034h]   ; mem_o
  10001C02: D9 9C 24 9C 00 00  fstp        dword ptr [esp+0000009Ch]
            00
  10001C09: E8 22 F6 FF FF     call        10001230   ; getEnv
  10001C0E: 56                 push        esi
  10001C0F: 8D 44 24 60        lea         eax,[esp+60h]
  10001C13: 68 EC F0 00 10     push        1000F0ECh
  10001C18: 50                 push        eax
  10001C19: 6A 04              push        4
  10001C1B: E8 10 F6 FF FF     call        10001230   ; getEnv
  10001C20: 83 C4 20           add         esp,20h
  10001C23: 8D 4C 24 4C        lea         ecx,[esp+4Ch]
  10001C27: 56                 push        esi
  10001C28: 6A 02              push        2
  10001C2A: 68 E4 F0 00 10     push        1000F0E4h
  10001C2F: 51                 push        ecx
  10001C30: FF D7              call        edi
  10001C32: 56                 push        esi
  10001C33: 68 00 00 48 43     push        43480000h
  10001C38: 8D 54 24 54        lea         edx,[esp+54h]
  10001C3C: 68 24 F1 00 10     push        1000F124h
  10001C41: 52                 push        edx
  10001C42: 89 84 24 54 01 00  mov         dword ptr [esp+00000154h],eax
            00
  10001C49: E8 12 F8 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001C4E: D8 4C 24 28        fmul        dword ptr [esp+28h]
  10001C52: 56                 push        esi
  10001C53: 68 00 00 F0 42     push        42F00000h
  10001C58: 8D 44 24 64        lea         eax,[esp+64h]
  10001C5C: 68 20 F1 00 10     push        1000F120h
  10001C61: D8 0D E0 E1 00 10  fmul        dword ptr ds:[1000E1E0h]   ; float 0.00014247586659621447
  10001C67: 50                 push        eax
  10001C68: D9 9C 24 90 00 00  fstp        dword ptr [esp+00000090h]
            00
  10001C6F: E8 EC F7 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001C74: D8 4C 24 38        fmul        dword ptr [esp+38h]
  10001C78: 83 C4 20           add         esp,20h
  10001C7B: 8D 4C 24 4C        lea         ecx,[esp+4Ch]
  10001C7F: D8 0D E0 E1 00 10  fmul        dword ptr ds:[1000E1E0h]   ; float 0.00014247586659621447
  10001C85: 56                 push        esi
  10001C86: 6A 00              push        0
  10001C88: 68 DC F0 00 10     push        1000F0DCh
  10001C8D: 51                 push        ecx
  10001C8E: D9 9C 24 90 00 00  fstp        dword ptr [esp+00000090h]
            00
  10001C95: FF D7              call        edi
  10001C97: 89 84 24 C8 00 00  mov         dword ptr [esp+000000C8h],eax
            00
  10001C9E: 56                 push        esi
  10001C9F: 6A 00              push        0
  10001CA1: 8D 54 24 54        lea         edx,[esp+54h]
  10001CA5: 68 D4 F0 00 10     push        1000F0D4h
  10001CAA: 52                 push        edx
  10001CAB: FF D7              call        edi
  10001CAD: 56                 push        esi
  10001CAE: 6A 32              push        32h
  10001CB0: 89 84 24 B8 00 00  mov         dword ptr [esp+000000B8h],eax
            00
  10001CB7: 8D 44 24 54        lea         eax,[esp+54h]
  10001CBB: 68 CC F0 00 10     push        1000F0CCh
  10001CC0: 50                 push        eax
  10001CC1: FF D7              call        edi
  10001CC3: 89 84 24 D4 00 00  mov         dword ptr [esp+000000D4h],eax
            00
  10001CCA: C7 84 24 D8 00 00  mov         dword ptr [esp+000000D8h],0
            00 00 00 00 00
  10001CD5: DF AC 24 D4 00 00  fild        qword ptr [esp+000000D4h]
            00
  10001CDC: D9 94 24 88 00 00  fst         dword ptr [esp+00000088h]
            00
  10001CE3: DD 05 B8 E1 00 10  fld         qword ptr ds:[1000E1B8h]   ; double 3.0
  10001CE9: E8 A2 18 00 00     call        10003590   ; pow (_CIpow)
  10001CEE: D9 54 24 20        fst         dword ptr [esp+20h]
  10001CF2: DD 05 B0 E1 00 10  fld         qword ptr ds:[1000E1B0h]   ; double 50.0
  10001CF8: DD 05 B8 E1 00 10  fld         qword ptr ds:[1000E1B8h]   ; double 3.0
  10001CFE: E8 8D 18 00 00     call        10003590   ; pow (_CIpow)
  10001D03: D9 54 24 20        fst         dword ptr [esp+20h]
  10001D07: DE F9              fdivp       st(1),st
  10001D09: 8B 4C 24 3C        mov         ecx,dword ptr [esp+3Ch]
  10001D0D: 8B 84 24 A4 00 00  mov         eax,dword ptr [esp+000000A4h]
            00
  10001D14: 8B D1              mov         edx,ecx
  10001D16: 89 4C 24 44        mov         dword ptr [esp+44h],ecx
  10001D1A: 85 C0              test        eax,eax
  10001D1C: 89 54 24 40        mov         dword ptr [esp+40h],edx
  10001D20: D9 9C 24 14 01 00  fstp        dword ptr [esp+00000114h]
            00
  10001D27: D9 84 24 88 00 00  fld         dword ptr [esp+00000088h]
            00
  10001D2E: D8 0D 20 E1 00 10  fmul        dword ptr ds:[1000E120h]   ; float 0.009999999776482582
  10001D34: D9 9C 24 88 00 00  fstp        dword ptr [esp+00000088h]
            00
  10001D3B: D9 05 28 E1 00 10  fld         dword ptr ds:[1000E128h]   ; float 1.0
  10001D41: D8 A4 24 88 00 00  fsub        dword ptr [esp+00000088h]
            00
  10001D48: D9 9C 24 D0 00 00  fstp        dword ptr [esp+000000D0h]
            00
  10001D4F: 75 16              jne         10001D67
  10001D51: 56                 push        esi
  10001D52: 6A 00              push        0
  10001D54: 8D 44 24 54        lea         eax,[esp+54h]
  10001D58: 68 74 F1 00 10     push        1000F174h
  10001D5D: 50                 push        eax
  10001D5E: FF D7              call        edi
  10001D60: 89 84 24 A4 00 00  mov         dword ptr [esp+000000A4h],eax
            00
  10001D67: 56                 push        esi
  10001D68: 6A 00              push        0
  10001D6A: 8D 4C 24 54        lea         ecx,[esp+54h]
  10001D6E: 68 C4 F0 00 10     push        1000F0C4h
  10001D73: 51                 push        ecx
  10001D74: FF D7              call        edi
  10001D76: 83 F8 01           cmp         eax,1
  10001D79: 75 17              jne         10001D92
  10001D7B: 3B D8              cmp         ebx,eax
  10001D7D: 75 13              jne         10001D92
  10001D7F: D9 44 24 70        fld         dword ptr [esp+70h]
  10001D83: D8 74 24 2C        fdiv        dword ptr [esp+2Ch]
  10001D87: 89 84 24 0C 01 00  mov         dword ptr [esp+0000010Ch],eax
            00
  10001D8E: D9 5C 24 70        fstp        dword ptr [esp+70h]
  10001D92: 56                 push        esi
  10001D93: 6A 00              push        0
  10001D95: 8D 54 24 54        lea         edx,[esp+54h]
  10001D99: 68 BC F0 00 10     push        1000F0BCh
  10001D9E: 52                 push        edx
  10001D9F: FF D7              call        edi
  10001DA1: 83 F8 01           cmp         eax,1
  10001DA4: 75 1D              jne         10001DC3
  10001DA6: 3B D8              cmp         ebx,eax
  10001DA8: 75 19              jne         10001DC3
  10001DAA: D9 84 24 80 00 00  fld         dword ptr [esp+00000080h]
            00
  10001DB1: D8 74 24 2C        fdiv        dword ptr [esp+2Ch]
  10001DB5: 89 84 24 24 01 00  mov         dword ptr [esp+00000124h],eax
            00
  10001DBC: D9 9C 24 80 00 00  fstp        dword ptr [esp+00000080h]
            00
  10001DC3: D9 84 24 D0 00 00  fld         dword ptr [esp+000000D0h]
            00
  10001DCA: D8 8C 24 D0 00 00  fmul        dword ptr [esp+000000D0h]
            00
  10001DD1: 33 C9              xor         ecx,ecx
  10001DD3: 8D 84 24 DC 01 00  lea         eax,[esp+000001DCh]
            00
  10001DDA: 89 4C 24 30        mov         dword ptr [esp+30h],ecx
  10001DDE: D8 05 A8 E1 00 10  fadd        dword ptr ds:[1000E1A8h]   ; float 0.2800000011920929
  10001DE4: D9 C0              fld         st(0)
  10001DE6: D8 C9              fmul        st,st(1)
  10001DE8: D9 9C 24 34 01 00  fstp        dword ptr [esp+00000134h]
            00
  10001DEF: DD D8              fstp        st(0)
  10001DF1: D9 84 24 34 01 00  fld         dword ptr [esp+00000134h]
            00
  10001DF8: D8 0D A4 E1 00 10  fmul        dword ptr ds:[1000E1A4h]   ; float 0.699999988079071
  10001DFE: D8 2D A0 E1 00 10  fsubr       dword ptr ds:[1000E1A0h]   ; float 1.7999999523162842
  10001E04: D8 0D 9C E1 00 10  fmul        dword ptr ds:[1000E19Ch]   ; float 0.9200000166893005
  10001E0A: D9 9C 24 48 01 00  fstp        dword ptr [esp+00000148h]
            00
  10001E11: D9 05 48 E1 00 10  fld         dword ptr ds:[1000E148h]   ; float 6.2831854820251465
  10001E17: D8 74 24 70        fdiv        dword ptr [esp+70h]
  10001E1B: D9 05 48 E1 00 10  fld         dword ptr ds:[1000E148h]   ; float 6.2831854820251465
  10001E21: D8 B4 24 80 00 00  fdiv        dword ptr [esp+00000080h]
            00
  10001E28: D8 E1              fsub        st,st(1)
  10001E2A: DB 44 24 30        fild        dword ptr [esp+30h]
  10001E2E: 41                 inc         ecx
  10001E2F: 83 C0 08           add         eax,8
  10001E32: 83 F9 06           cmp         ecx,6
  10001E35: 89 4C 24 30        mov         dword ptr [esp+30h],ecx
  10001E39: D8 C9              fmul        st,st(1)
  10001E3B: D8 0D 1C E2 00 10  fmul        dword ptr ds:[1000E21Ch]   ; float 0.20000000298023224
  10001E41: D8 C2              fadd        st,st(2)
  10001E43: D9 50 FC           fst         dword ptr [eax-4]
  10001E46: D9 58 F8           fstp        dword ptr [eax-8]
  10001E49: 7C DF              jl          10001E2A
  10001E4B: 8D 44 24 4C        lea         eax,[esp+4Ch]
  10001E4F: 68 B0 F0 00 10     push        1000F0B0h
  10001E54: DD D8              fstp        st(0)
  10001E56: 50                 push        eax
  10001E57: DD D8              fstp        st(0)
  10001E59: FF D5              call        ebp
  10001E5B: 56                 push        esi
  10001E5C: 6A 00              push        0
  10001E5E: 8D 4C 24 54        lea         ecx,[esp+54h]
  10001E62: 68 44 F1 00 10     push        1000F144h
  10001E67: 51                 push        ecx
  10001E68: FF D7              call        edi
  10001E6A: 56                 push        esi
  10001E6B: 68 80 00 00 00     push        80h
  10001E70: 8D 54 24 54        lea         edx,[esp+54h]
  10001E74: 68 84 F1 00 10     push        1000F184h
  10001E79: 52                 push        edx
  10001E7A: A3 8C 28 01 10     mov         dword ptr ds:[1001288Ch],eax   ; chkOn[3]
  10001E7F: 89 84 24 38 01 00  mov         dword ptr [esp+00000138h],eax
            00
  10001E86: FF D7              call        edi
  10001E88: 8B C8              mov         ecx,eax
  10001E8A: 56                 push        esi
  10001E8B: 0F AF C8           imul        ecx,eax
  10001E8E: 89 4C 24 24        mov         dword ptr [esp+24h],ecx
  10001E92: 68 00 00 7A 44     push        447A0000h
  10001E97: DB 44 24 28        fild        dword ptr [esp+28h]
  10001E9B: 8D 54 24 54        lea         edx,[esp+54h]
  10001E9F: 68 AC F0 00 10     push        1000F0ACh
  10001EA4: 52                 push        edx
  10001EA5: A3 4C 5A 01 10     mov         dword ptr ds:[10015A4Ch],eax   ; sliLev[3]
  10001EAA: D8 0D 3C F0 00 10  fmul        dword ptr ds:[1000F03Ch]   ; mem_b
  10001EB0: D9 9C 24 60 01 00  fstp        dword ptr [esp+00000160h]
            00
  10001EB7: E8 A4 F5 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001EBC: D8 4C 24 28        fmul        dword ptr [esp+28h]
  10001EC0: 56                 push        esi
  10001EC1: 8D 44 24 60        lea         eax,[esp+60h]
  10001EC5: 68 30 F1 00 10     push        1000F130h
  10001ECA: 50                 push        eax
  10001ECB: D8 0D E0 E1 00 10  fmul        dword ptr ds:[1000E1E0h]   ; float 0.00014247586659621447
  10001ED1: 6A 05              push        5
  10001ED3: C7 84 24 D4 00 00  mov         dword ptr [esp+000000D4h],3F490FDBh
            00 DB 0F 49 3F
  10001EDE: D9 9C 24 E0 00 00  fstp        dword ptr [esp+000000E0h]
            00
  10001EE5: E8 46 F3 FF FF     call        10001230   ; getEnv
  10001EEA: 83 C4 20           add         esp,20h
  10001EED: 8D 4C 24 4C        lea         ecx,[esp+4Ch]
  10001EF1: 56                 push        esi
  10001EF2: 6A 32              push        32h
  10001EF4: 68 A8 F0 00 10     push        1000F0A8h
  10001EF9: 51                 push        ecx
  10001EFA: FF D7              call        edi
  10001EFC: 89 84 24 DC 00 00  mov         dword ptr [esp+000000DCh],eax
            00
  10001F03: DB 84 24 DC 00 00  fild        dword ptr [esp+000000DCh]
            00
  10001F0A: D9 C0              fld         st(0)
  10001F0C: D9 C0              fld         st(0)
  10001F0E: D8 C9              fmul        st,st(1)
  10001F10: D9 84 24 C0 00 00  fld         dword ptr [esp+000000C0h]
            00
  10001F17: D9 FA              fsqrt
  10001F19: DD DA              fstp        st(2)
  10001F1B: D9 C9              fxch        st(1)
  10001F1D: D8 25 98 E1 00 10  fsub        dword ptr ds:[1000E198h]   ; float 0.1899999976158142
  10001F23: D8 0D 94 E1 00 10  fmul        dword ptr ds:[1000E194h]   ; float 6600.0
  10001F29: D8 2D 90 E1 00 10  fsubr       dword ptr ds:[1000E190h]   ; float 10000.0
  10001F2F: DE F9              fdivp       st(1),st
  10001F31: D9 9C 24 F4 00 00  fstp        dword ptr [esp+000000F4h]
            00
  10001F38: D8 0D 8C E1 00 10  fmul        dword ptr ds:[1000E18Ch]   ; float 0.4000000059604645
  10001F3E: D8 2D 88 E1 00 10  fsubr       dword ptr ds:[1000E188h]   ; float 40.0
  10001F44: D9 84 24 C0 00 00  fld         dword ptr [esp+000000C0h]
            00
  10001F4B: D8 84 24 F4 00 00  fadd        dword ptr [esp+000000F4h]
            00
  10001F52: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  10001F58: DE F9              fdivp       st(1),st
  10001F5A: E8 01 11 00 00     call        10003060   ; _ftol
  10001F5F: 40                 inc         eax
  10001F60: 68 9C F0 00 10     push        1000F09Ch
  10001F65: 89 84 24 E0 00 00  mov         dword ptr [esp+000000E0h],eax
            00
  10001F6C: 8D 54 24 50        lea         edx,[esp+50h]
  10001F70: 52                 push        edx
  10001F71: FF D5              call        ebp
  10001F73: 56                 push        esi
  10001F74: 6A 00              push        0
  10001F76: 8D 44 24 54        lea         eax,[esp+54h]
  10001F7A: 68 44 F1 00 10     push        1000F144h
  10001F7F: 50                 push        eax
  10001F80: FF D7              call        edi
  10001F82: 56                 push        esi
  10001F83: 68 80 00 00 00     push        80h
  10001F88: 8D 4C 24 54        lea         ecx,[esp+54h]
  10001F8C: 68 84 F1 00 10     push        1000F184h
  10001F91: 51                 push        ecx
  10001F92: A3 90 28 01 10     mov         dword ptr ds:[10012890h],eax   ; chkOn[4]
  10001F97: 89 84 24 3C 01 00  mov         dword ptr [esp+0000013Ch],eax
            00
  10001F9E: FF D7              call        edi
  10001FA0: 8B D0              mov         edx,eax
  10001FA2: A3 50 5A 01 10     mov         dword ptr ds:[10015A50h],eax   ; sliLev[4]
  10001FA7: 0F AF D0           imul        edx,eax
  10001FAA: 89 54 24 20        mov         dword ptr [esp+20h],edx
  10001FAE: 56                 push        esi
  10001FAF: DB 44 24 24        fild        dword ptr [esp+24h]
  10001FB3: 68 00 00 7A 44     push        447A0000h
  10001FB8: 8D 44 24 54        lea         eax,[esp+54h]
  10001FBC: 68 AC F0 00 10     push        1000F0ACh
  10001FC1: 50                 push        eax
  10001FC2: D8 0D 3C F0 00 10  fmul        dword ptr ds:[1000F03Ch]   ; mem_b
  10001FC8: D9 9C 24 5C 01 00  fstp        dword ptr [esp+0000015Ch]
            00
  10001FCF: E8 8C F4 FF FF     call        10001460   ; GetPrivateProfileFloat
  10001FD4: D8 4C 24 28        fmul        dword ptr [esp+28h]
  10001FD8: 56                 push        esi
  10001FD9: 8D 4C 24 60        lea         ecx,[esp+60h]
  10001FDD: 68 30 F1 00 10     push        1000F130h
  10001FE2: 51                 push        ecx
  10001FE3: D8 0D E0 E1 00 10  fmul        dword ptr ds:[1000E1E0h]   ; float 0.00014247586659621447
  10001FE9: 6A 06              push        6
  10001FEB: C7 84 24 E4 00 00  mov         dword ptr [esp+000000E4h],3F490FDBh
            00 DB 0F 49 3F
  10001FF6: D9 9C 24 DC 00 00  fstp        dword ptr [esp+000000DCh]
            00
  10001FFD: E8 2E F2 FF FF     call        10001230   ; getEnv
  10002002: 83 C4 20           add         esp,20h
  10002005: 8D 54 24 4C        lea         edx,[esp+4Ch]
  10002009: 56                 push        esi
  1000200A: 6A 32              push        32h
  1000200C: 68 A8 F0 00 10     push        1000F0A8h
  10002011: 52                 push        edx
  10002012: FF D7              call        edi
  10002014: 89 84 24 90 00 00  mov         dword ptr [esp+00000090h],eax
            00
  1000201B: DB 84 24 90 00 00  fild        dword ptr [esp+00000090h]
            00
  10002022: D9 C0              fld         st(0)
  10002024: D8 C9              fmul        st,st(1)
  10002026: D9 84 24 BC 00 00  fld         dword ptr [esp+000000BCh]
            00
  1000202D: D9 FA              fsqrt
  1000202F: DD DA              fstp        st(2)
  10002031: D9 C9              fxch        st(1)
  10002033: D8 25 98 E1 00 10  fsub        dword ptr ds:[1000E198h]   ; float 0.1899999976158142
  10002039: D8 0D 94 E1 00 10  fmul        dword ptr ds:[1000E194h]   ; float 6600.0
  1000203F: D8 2D 90 E1 00 10  fsubr       dword ptr ds:[1000E190h]   ; float 10000.0
  10002045: DE F9              fdivp       st(1),st
  10002047: D9 9C 24 1C 01 00  fstp        dword ptr [esp+0000011Ch]
            00
  1000204E: DB 84 24 90 00 00  fild        dword ptr [esp+00000090h]
            00
  10002055: DC 0D 80 E1 00 10  fmul        qword ptr ds:[1000E180h]   ; double 0.4
  1000205B: DC 2D 78 E1 00 10  fsubr       qword ptr ds:[1000E178h]   ; double 40.0
  10002061: D9 84 24 BC 00 00  fld         dword ptr [esp+000000BCh]
            00
  10002068: D8 84 24 1C 01 00  fadd        dword ptr [esp+0000011Ch]
            00
  1000206F: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  10002075: DE F9              fdivp       st(1),st
  10002077: E8 E4 0F 00 00     call        10003060   ; _ftol
  1000207C: 40                 inc         eax
  1000207D: 68 90 F0 00 10     push        1000F090h
  10002082: 89 84 24 94 00 00  mov         dword ptr [esp+00000094h],eax
            00
  10002089: 8D 44 24 50        lea         eax,[esp+50h]
  1000208D: 50                 push        eax
  1000208E: FF D5              call        ebp
  10002090: 56                 push        esi
  10002091: 6A 00              push        0
  10002093: 8D 4C 24 54        lea         ecx,[esp+54h]
  10002097: 68 44 F1 00 10     push        1000F144h
  1000209C: 51                 push        ecx
  1000209D: FF D7              call        edi
  1000209F: 56                 push        esi
  100020A0: 6A 00              push        0
  100020A2: 8D 54 24 54        lea         edx,[esp+54h]
  100020A6: 8B D8              mov         ebx,eax
  100020A8: 68 88 F0 00 10     push        1000F088h
  100020AD: 52                 push        edx
  100020AE: A3 94 28 01 10     mov         dword ptr ds:[10012894h],eax   ; chkOn[5]
  100020B3: 89 9C 24 E4 00 00  mov         dword ptr [esp+000000E4h],ebx
            00
  100020BA: FF D7              call        edi
  100020BC: 40                 inc         eax
  100020BD: 83 F8 07           cmp         eax,7
  100020C0: 89 84 24 84 00 00  mov         dword ptr [esp+00000084h],eax
            00
  100020C7: 75 0D              jne         100020D6
  100020C9: C7 84 24 84 00 00  mov         dword ptr [esp+00000084h],14h
            00 14 00 00 00
  100020D4: EB 22              jmp         100020F8
  100020D6: 83 F8 06           cmp         eax,6
  100020D9: 75 0D              jne         100020E8
  100020DB: C7 84 24 84 00 00  mov         dword ptr [esp+00000084h],0Ah
            00 0A 00 00 00
  100020E6: EB 10              jmp         100020F8
  100020E8: 83 F8 05           cmp         eax,5
  100020EB: 75 0B              jne         100020F8
  100020ED: C7 84 24 84 00 00  mov         dword ptr [esp+00000084h],8
            00 08 00 00 00
  100020F8: 83 FB 01           cmp         ebx,1
  100020FB: 66 C7 05 60 5A 01  mov         word ptr ds:[10015A60h],7FBCh
            10 BC 7F
  10002104: C7 44 24 30 00 00  mov         dword ptr [esp+30h],3F800000h
            80 3F
  1000210C: 0F 85 D0 00 00 00  jne         100021E2
  10002112: E8 F9 EF FF FF     call        10001110   ; LoudestEnv
  10002117: E8 44 0F 00 00     call        10003060   ; _ftol
  1000211C: 0F BF C0           movsx       eax,ax
  1000211F: 89 44 24 20        mov         dword ptr [esp+20h],eax
  10002123: DB 44 24 20        fild        dword ptr [esp+20h]
  10002127: D8 4C 24 7C        fmul        dword ptr [esp+7Ch]
  1000212B: D8 15 70 E1 00 10  fcom        dword ptr ds:[1000E170h]   ; float 32700.0
  10002131: DF E0              fnstsw      ax
  10002133: F6 C4 41           test        ah,41h
  10002136: 75 0D              jne         10002145
  10002138: DD D8              fstp        st(0)
  1000213A: 66 C7 05 60 5A 01  mov         word ptr ds:[10015A60h],7FBCh
            10 BC 7F
  10002143: EB 0B              jmp         10002150
  10002145: E8 16 0F 00 00     call        10003060   ; _ftol
  1000214A: 66 A3 60 5A 01 10  mov         word ptr ds:[10015A60h],ax
  10002150: 33 DB              xor         ebx,ebx
  10002152: 56                 push        esi
  10002153: 53                 push        ebx
  10002154: 8D 4C 24 54        lea         ecx,[esp+54h]
  10002158: 68 80 F0 00 10     push        1000F080h
  1000215D: 51                 push        ecx
  1000215E: C7 84 24 AC 00 00  mov         dword ptr [esp+000000ACh],0
            00 00 00 00 00
  10002169: C7 84 24 B0 00 00  mov         dword ptr [esp+000000B0h],40000000h
            00 00 00 00 40
  10002174: FF D7              call        edi
  10002176: 89 44 24 20        mov         dword ptr [esp+20h],eax
  1000217A: 89 5C 24 24        mov         dword ptr [esp+24h],ebx
  1000217E: DF 6C 24 20        fild        qword ptr [esp+20h]
  10002182: DC C0              fadd        st(0),st
  10002184: DD 84 24 9C 00 00  fld         qword ptr [esp+0000009Ch]
            00
  1000218B: D9 C9              fxch        st(1)
  1000218D: E8 FE 13 00 00     call        10003590   ; pow (_CIpow)
  10002192: D9 5C 24 30        fstp        dword ptr [esp+30h]
  10002196: 56                 push        esi
  10002197: 53                 push        ebx
  10002198: 8D 54 24 54        lea         edx,[esp+54h]
  1000219C: 68 74 F0 00 10     push        1000F074h
  100021A1: 52                 push        edx
  100021A2: 89 9C 24 AC 00 00  mov         dword ptr [esp+000000ACh],ebx
            00
  100021A9: C7 84 24 B0 00 00  mov         dword ptr [esp+000000B0h],40240000h
            00 00 00 24 40
  100021B4: FF D7              call        edi
  100021B6: 89 44 24 20        mov         dword ptr [esp+20h],eax
  100021BA: 89 5C 24 24        mov         dword ptr [esp+24h],ebx
  100021BE: DF 6C 24 20        fild        qword ptr [esp+20h]
  100021C2: DC 0D 10 E2 00 10  fmul        qword ptr ds:[1000E210h]   ; double 0.05
  100021C8: DD 84 24 9C 00 00  fld         qword ptr [esp+0000009Ch]
            00
  100021CF: D9 C9              fxch        st(1)
  100021D1: E8 BA 13 00 00     call        10003590   ; pow (_CIpow)
  100021D6: D8 4C 24 30        fmul        dword ptr [esp+30h]
  100021DA: D8 4C 24 7C        fmul        dword ptr [esp+7Ch]
  100021DE: D9 5C 24 7C        fstp        dword ptr [esp+7Ch]
  100021E2: B8 A0 5A 01 10     mov         eax,10015AA0h   ; &envData[1][PNT]
  100021E7: 33 C9              xor         ecx,ecx
  100021E9: 89 48 08           mov         dword ptr [eax+8],ecx
  100021EC: 89 08              mov         dword ptr [eax],ecx
  100021EE: 83 C0 18           add         eax,18h
  100021F1: 3D 48 5B 01 10     cmp         eax,10015B48h
  100021F6: 7C F1              jl          100021E9
  100021F8: E8 13 EE FF FF     call        10001010   ; LongestEnv
  100021FD: 8B F8              mov         edi,eax
  100021FF: A1 EC 24 01 10     mov         eax,dword ptr ds:[100124ECh]   ; wave
  10002204: 33 F6              xor         esi,esi
  10002206: 89 7C 24 20        mov         dword ptr [esp+20h],edi
  1000220A: 3B C6              cmp         eax,esi
  1000220C: 74 09              je          10002217
  1000220E: 50                 push        eax
  1000220F: E8 DE 0E 00 00     call        100030F2   ; free
  10002214: 83 C4 04           add         esp,4
  10002217: 8D 84 3F 00 05 00  lea         eax,[edi+edi+00000500h]
            00
  1000221E: 50                 push        eax
  1000221F: E8 32 12 00 00     call        10003456   ; malloc
  10002224: 83 C4 04           add         esp,4
  10002227: 3B C6              cmp         eax,esi
  10002229: A3 EC 24 01 10     mov         dword ptr ds:[100124ECh],eax   ; wave
  1000222E: 75 18              jne         10002248
  10002230: 89 35 E8 24 01 10  mov         dword ptr ds:[100124E8h],esi
  10002236: 5F                 pop         edi
  10002237: 5E                 pop         esi
  10002238: 5D                 pop         ebp
  10002239: B8 03 00 00 00     mov         eax,3
  1000223E: 5B                 pop         ebx
  1000223F: 81 C4 FC 02 00 00  add         esp,2FCh
  10002245: C2 0C 00           ret         0Ch
  10002248: A1 F0 24 01 10     mov         eax,dword ptr ds:[100124F0h]   ; wavemode
  1000224D: 89 35 20 5A 01 10  mov         dword ptr ds:[10015A20h],esi   ; wavewords
  10002253: 3B C6              cmp         eax,esi
  10002255: 0F 85 41 01 00 00  jne         1000239C
  1000225B: 8B 8C 24 14 03 00  mov         ecx,dword ptr [esp+00000314h]
            00
  10002262: 68 70 F0 00 10     push        1000F070h
  10002267: 51                 push        ecx
  10002268: E8 D6 11 00 00     call        10003443   ; fopen
  1000226D: 83 C4 08           add         esp,8
  10002270: 3B C6              cmp         eax,esi
  10002272: 89 84 24 9C 00 00  mov         dword ptr [esp+0000009Ch],eax
            00
  10002279: 75 18              jne         10002293
  1000227B: 89 35 E8 24 01 10  mov         dword ptr ds:[100124E8h],esi
  10002281: 5F                 pop         edi
  10002282: 5E                 pop         esi
  10002283: 5D                 pop         ebp
  10002284: B8 03 00 00 00     mov         eax,3
  10002289: 5B                 pop         ebx
  1000228A: 81 C4 FC 02 00 00  add         esp,2FCh
  10002290: C2 0C 00           ret         0Ch
  10002293: 8B B4 24 A8 00 00  mov         esi,dword ptr [esp+000000A8h]
            00
  1000229A: 8D 84 24 94 01 00  lea         eax,[esp+00000194h]
            00
  100022A1: BB 10 00 00 00     mov         ebx,10h
  100022A6: 68 60 F0 00 10     push        1000F060h
  100022AB: 8D 56 24           lea         edx,[esi+24h]
  100022AE: 50                 push        eax
  100022AF: C7 84 24 88 01 00  mov         dword ptr [esp+00000188h],5453494Ch
            00 4C 49 53 54
  100022BA: 89 94 24 8C 01 00  mov         dword ptr [esp+0000018Ch],edx
            00
  100022C1: C7 84 24 90 01 00  mov         dword ptr [esp+00000190h],4F464E49h
            00 49 4E 46 4F
  100022CC: C7 84 24 94 01 00  mov         dword ptr [esp+00000194h],54465349h
            00 49 53 46 54
  100022D7: 89 9C 24 98 01 00  mov         dword ptr [esp+00000198h],ebx
            00
  100022DE: FF D5              call        ebp
  100022E0: 8D 4C 7E 50        lea         ecx,[esi+edi*2+50h]
  100022E4: 8D 14 3F           lea         edx,[edi+edi]
  100022E7: 89 8C 24 58 01 00  mov         dword ptr [esp+00000158h],ecx
            00
  100022EE: 8B 8C 24 9C 00 00  mov         ecx,dword ptr [esp+0000009Ch]
            00
  100022F5: B8 01 00 00 00     mov         eax,1
  100022FA: 89 94 24 7C 01 00  mov         dword ptr [esp+0000017Ch],edx
            00
  10002301: 51                 push        ecx
  10002302: 6A 2C              push        2Ch
  10002304: 8D 94 24 5C 01 00  lea         edx,[esp+0000015Ch]
            00
  1000230B: 50                 push        eax
  1000230C: 52                 push        edx
  1000230D: C6 84 24 B3 01 00  mov         byte ptr [esp+000001B3h],0
            00 00
  10002315: C7 84 24 B4 01 00  mov         dword ptr [esp+000001B4h],544D4349h
            00 49 43 4D 54
  10002320: 89 B4 24 B8 01 00  mov         dword ptr [esp+000001B8h],esi
            00
  10002327: C7 84 24 64 01 00  mov         dword ptr [esp+00000164h],46464952h
            00 52 49 46 46
  10002332: C7 84 24 6C 01 00  mov         dword ptr [esp+0000016Ch],45564157h
            00 57 41 56 45
  1000233D: C7 84 24 70 01 00  mov         dword ptr [esp+00000170h],20746D66h
            00 66 6D 74 20
  10002348: 89 9C 24 74 01 00  mov         dword ptr [esp+00000174h],ebx
            00
  1000234F: 66 89 84 24 78 01  mov         word ptr [esp+00000178h],ax
            00 00
  10002357: 66 89 84 24 7A 01  mov         word ptr [esp+0000017Ah],ax
            00 00
  1000235F: C7 84 24 7C 01 00  mov         dword ptr [esp+0000017Ch],0AC44h
            00 44 AC 00 00
  1000236A: C7 84 24 80 01 00  mov         dword ptr [esp+00000180h],15888h
            00 88 58 01 00
  10002375: 66 C7 84 24 84 01  mov         word ptr [esp+00000184h],2
            00 00 02 00
  1000237F: 66 89 9C 24 86 01  mov         word ptr [esp+00000186h],bx
            00 00
  10002387: C7 84 24 88 01 00  mov         dword ptr [esp+00000188h],61746164h
            00 64 61 74 61
  10002392: E8 42 0F 00 00     call        100032D9   ; fwrite
  10002397: 83 C4 10           add         esp,10h
  1000239A: 33 F6              xor         esi,esi
  1000239C: 3B FE              cmp         edi,esi
  1000239E: 89 74 24 18        mov         dword ptr [esp+18h],esi
  100023A2: 0F 8E DD 0B 00 00  jle         10002F85
  100023A8: 8B 74 24 18        mov         esi,dword ptr [esp+18h]
  100023AC: 8B 84 24 30 01 00  mov         eax,dword ptr [esp+00000130h]
            00
  100023B3: BA 01 00 00 00     mov         edx,1
  100023B8: 3B C2              cmp         eax,edx
  100023BA: 8D 9E AF 04 00 00  lea         ebx,[esi+000004AFh]
  100023C0: 0F 85 17 01 00 00  jne         100024DD
  100023C6: 3B F3              cmp         esi,ebx
  100023C8: 89 74 24 14        mov         dword ptr [esp+14h],esi
  100023CC: 0F 8F ED 00 00 00  jg          100024BF
  100023D2: 8D 2C B5 00 00 00  lea         ebp,[esi*4+00000000h]
            00
  100023D9: 8B FD              mov         edi,ebp
  100023DB: DB 44 24 14        fild        dword ptr [esp+14h]
  100023DF: D8 1D C0 5A 01 10  fcomp       dword ptr ds:[10015AC0h]   ; envData[2][NEXTT]
  100023E5: DF E0              fnstsw      ax
  100023E7: F6 C4 01           test        ah,1
  100023EA: 74 14              je          10002400
  100023EC: D9 05 BC 5A 01 10  fld         dword ptr ds:[10015ABCh]   ; envData[2][dENV]
  100023F2: D8 05 B4 5A 01 10  fadd        dword ptr ds:[10015AB4h]   ; envData[2][ENV]
  100023F8: D9 1D B4 5A 01 10  fstp        dword ptr ds:[10015AB4h]   ; envData[2][ENV]
  100023FE: EB 0B              jmp         1000240B
  10002400: 56                 push        esi
  10002401: 6A 02              push        2
  10002403: E8 48 ED FF FF     call        10001150   ; UpdateEnv
  10002408: 83 C4 08           add         esp,8
  1000240B: 8B 84 24 E4 00 00  mov         eax,dword ptr [esp+000000E4h]
            00
  10002412: 8B 8C 24 E0 00 00  mov         ecx,dword ptr [esp+000000E0h]
            00
  10002419: 89 84 24 E8 00 00  mov         dword ptr [esp+000000E8h],eax
            00
  10002420: 89 8C 24 E4 00 00  mov         dword ptr [esp+000000E4h],ecx
            00
  10002427: E8 8B 0E 00 00     call        100032B7   ; rand
  1000242C: 89 44 24 10        mov         dword ptr [esp+10h],eax
  10002430: 8B C7              mov         eax,edi
  10002432: DB 44 24 10        fild        dword ptr [esp+10h]
  10002436: 2B C5              sub         eax,ebp
  10002438: 46                 inc         esi
  10002439: 83 C7 04           add         edi,4
  1000243C: 3B F3              cmp         esi,ebx
  1000243E: D8 0D 6C E1 00 10  fmul        dword ptr ds:[1000E16Ch]   ; float 6.103701889514923e-05
  10002444: 89 74 24 14        mov         dword ptr [esp+14h],esi
  10002448: D8 25 28 E1 00 10  fsub        dword ptr ds:[1000E128h]   ; float 1.0
  1000244E: D9 9C 24 E0 00 00  fstp        dword ptr [esp+000000E0h]
            00
  10002455: D9 84 24 20 01 00  fld         dword ptr [esp+00000120h]
            00
  1000245C: D8 8C 24 E0 00 00  fmul        dword ptr [esp+000000E0h]
            00
  10002463: D9 84 24 AC 00 00  fld         dword ptr [esp+000000ACh]
            00
  1000246A: D8 8C 24 EC 00 00  fmul        dword ptr [esp+000000ECh]
            00
  10002471: DE C1              faddp       st(1),st
  10002473: D9 84 24 04 01 00  fld         dword ptr [esp+00000104h]
            00
  1000247A: D8 8C 24 E8 00 00  fmul        dword ptr [esp+000000E8h]
            00
  10002481: DE C1              faddp       st(1),st
  10002483: D9 84 24 18 01 00  fld         dword ptr [esp+00000118h]
            00
  1000248A: D8 8C 24 E4 00 00  fmul        dword ptr [esp+000000E4h]
            00
  10002491: DE C1              faddp       st(1),st
  10002493: D9 9C 24 AC 00 00  fstp        dword ptr [esp+000000ACh]
            00
  1000249A: D9 05 B4 5A 01 10  fld         dword ptr ds:[10015AB4h]   ; envData[2][ENV]
  100024A0: D8 8C 24 F0 00 00  fmul        dword ptr [esp+000000F0h]
            00
  100024A7: D8 8C 24 AC 00 00  fmul        dword ptr [esp+000000ACh]
            00
  100024AE: D9 98 60 3B 01 10  fstp        dword ptr [eax+10013B60h]
  100024B4: 0F 8E 21 FF FF FF  jle         100023DB
  100024BA: BA 01 00 00 00     mov         edx,1
  100024BF: DB 44 24 14        fild        dword ptr [esp+14h]
  100024C3: D8 1D B0 5A 01 10  fcomp       dword ptr ds:[10015AB0h]   ; envData[2][MAX]
  100024C9: DF E0              fnstsw      ax
  100024CB: F6 C4 01           test        ah,1
  100024CE: 75 1B              jne         100024EB
  100024D0: C7 84 24 30 01 00  mov         dword ptr [esp+00000130h],0
            00 00 00 00 00
  100024DB: EB 0E              jmp         100024EB
  100024DD: B9 B0 04 00 00     mov         ecx,4B0h
  100024E2: 33 C0              xor         eax,eax
  100024E4: BF 60 3B 01 10     mov         edi,10013B60h
  100024E9: F3 AB              rep stos    dword ptr es:[edi]
  100024EB: 39 94 24 FC 00 00  cmp         dword ptr [esp+000000FCh],edx
            00
  100024F2: 0F 85 66 01 00 00  jne         1000265E
  100024F8: 8B 44 24 3C        mov         eax,dword ptr [esp+3Ch]
  100024FC: 89 44 24 78        mov         dword ptr [esp+78h],eax
  10002500: 8B 84 24 38 01 00  mov         eax,dword ptr [esp+00000138h]
            00
  10002507: 3B C2              cmp         eax,edx
  10002509: 8B 54 24 18        mov         edx,dword ptr [esp+18h]
  1000250D: 89 54 24 14        mov         dword ptr [esp+14h],edx
  10002511: 75 54              jne         10002567
  10002513: 3B D3              cmp         edx,ebx
  10002515: 0F 8F 84 00 00 00  jg          1000259F
  1000251B: 8B CA              mov         ecx,edx
  1000251D: 8D 34 8D 00 00 00  lea         esi,[ecx*4+00000000h]
            00
  10002524: 8B CE              mov         ecx,esi
  10002526: DB 44 24 14        fild        dword ptr [esp+14h]
  1000252A: 8B C1              mov         eax,ecx
  1000252C: 83 C1 04           add         ecx,4
  1000252F: 2B C6              sub         eax,esi
  10002531: 42                 inc         edx
  10002532: D8 4C 24 6C        fmul        dword ptr [esp+6Ch]
  10002536: D9 EA              fldl2e
  10002538: 3B D3              cmp         edx,ebx
  1000253A: 89 54 24 14        mov         dword ptr [esp+14h],edx
  1000253E: DE C9              fmulp       st(1),st
  10002540: D9 C0              fld         st(0)
  10002542: D9 FC              frndint
  10002544: D9 C9              fxch        st(1)
  10002546: D8 E1              fsub        st,st(1)
  10002548: D9 F0              f2xm1
  1000254A: D9 E8              fld1
  1000254C: DE C1              faddp       st(1),st
  1000254E: D9 FD              fscale
  10002550: DD D9              fstp        st(1)
  10002552: D8 8C 24 CC 00 00  fmul        dword ptr [esp+000000CCh]
            00
  10002559: D8 44 24 48        fadd        dword ptr [esp+48h]
  1000255D: D9 98 A0 28 01 10  fstp        dword ptr [eax+100128A0h]
  10002563: 7E C1              jle         10002526
  10002565: EB 38              jmp         1000259F
  10002567: 3B D3              cmp         edx,ebx
  10002569: 7F 34              jg          1000259F
  1000256B: 8D 34 95 00 00 00  lea         esi,[edx*4+00000000h]
            00
  10002572: 8B CE              mov         ecx,esi
  10002574: DB 44 24 14        fild        dword ptr [esp+14h]
  10002578: 8B C1              mov         eax,ecx
  1000257A: 83 C1 04           add         ecx,4
  1000257D: 2B C6              sub         eax,esi
  1000257F: 42                 inc         edx
  10002580: D8 35 98 5A 01 10  fdiv        dword ptr ds:[10015A98h]   ; envData[1][MAX]
  10002586: 3B D3              cmp         edx,ebx
  10002588: 89 54 24 14        mov         dword ptr [esp+14h],edx
  1000258C: D8 8C 24 CC 00 00  fmul        dword ptr [esp+000000CCh]
            00
  10002593: D8 44 24 2C        fadd        dword ptr [esp+2Ch]
  10002597: D9 98 A0 28 01 10  fstp        dword ptr [eax+100128A0h]
  1000259D: 7E D5              jle         10002574
  1000259F: 8B 7C 24 18        mov         edi,dword ptr [esp+18h]
  100025A3: 3B FB              cmp         edi,ebx
  100025A5: 89 7C 24 14        mov         dword ptr [esp+14h],edi
  100025A9: 0F 8F 91 00 00 00  jg          10002640
  100025AF: 8B D7              mov         edx,edi
  100025B1: 8B DF              mov         ebx,edi
  100025B3: 8D 04 95 00 00 00  lea         eax,[edx*4+00000000h]
            00
  100025BA: 89 44 24 10        mov         dword ptr [esp+10h],eax
  100025BE: 8B E8              mov         ebp,eax
  100025C0: EB 04              jmp         100025C6
  100025C2: 8B 44 24 10        mov         eax,dword ptr [esp+10h]
  100025C6: DB 44 24 14        fild        dword ptr [esp+14h]
  100025CA: 8B F5              mov         esi,ebp
  100025CC: 2B F0              sub         esi,eax
  100025CE: D8 1D A8 5A 01 10  fcomp       dword ptr ds:[10015AA8h]   ; envData[1][NEXTT]
  100025D4: DF E0              fnstsw      ax
  100025D6: F6 C4 01           test        ah,1
  100025D9: 74 14              je          100025EF
  100025DB: D9 05 A4 5A 01 10  fld         dword ptr ds:[10015AA4h]   ; envData[1][dENV]
  100025E1: D8 05 9C 5A 01 10  fadd        dword ptr ds:[10015A9Ch]   ; envData[1][ENV]
  100025E7: D9 1D 9C 5A 01 10  fstp        dword ptr ds:[10015A9Ch]   ; envData[1][ENV]
  100025ED: EB 0B              jmp         100025FA
  100025EF: 57                 push        edi
  100025F0: 6A 01              push        1
  100025F2: E8 59 EB FF FF     call        10001150   ; UpdateEnv
  100025F7: 83 C4 08           add         esp,8
  100025FA: D9 44 24 3C        fld         dword ptr [esp+3Ch]
  100025FE: D8 86 A0 28 01 10  fadd        dword ptr [esi+100128A0h]
  10002604: D9 54 24 3C        fst         dword ptr [esp+3Ch]
  10002608: DD 05 50 E1 00 10  fld         qword ptr ds:[1000E150h]   ; double 6.2831854820251465
  1000260E: E8 B7 0A 00 00     call        100030CA   ; _CIfmod
  10002613: D9 FE              fsin
  10002615: 47                 inc         edi
  10002616: 8D 83 AF 04 00 00  lea         eax,[ebx+000004AFh]
  1000261C: 83 C5 04           add         ebp,4
  1000261F: 3B F8              cmp         edi,eax
  10002621: 89 7C 24 14        mov         dword ptr [esp+14h],edi
  10002625: D8 0D 9C 5A 01 10  fmul        dword ptr ds:[10015A9Ch]   ; envData[1][ENV]
  1000262B: D8 8C 24 3C 01 00  fmul        dword ptr [esp+0000013Ch]
            00
  10002632: D8 86 60 3B 01 10  fadd        dword ptr [esi+10013B60h]
  10002638: D9 9E 60 3B 01 10  fstp        dword ptr [esi+10013B60h]
  1000263E: 7E 82              jle         100025C2
  10002640: DB 44 24 14        fild        dword ptr [esp+14h]
  10002644: D8 1D 98 5A 01 10  fcomp       dword ptr ds:[10015A98h]   ; envData[1][MAX]
  1000264A: DF E0              fnstsw      ax
  1000264C: F6 C4 01           test        ah,1
  1000264F: 75 1D              jne         1000266E
  10002651: C7 84 24 FC 00 00  mov         dword ptr [esp+000000FCh],0
            00 00 00 00 00
  1000265C: EB 10              jmp         1000266E
  1000265E: 8B 44 24 48        mov         eax,dword ptr [esp+48h]
  10002662: B9 B0 04 00 00     mov         ecx,4B0h
  10002667: BF A0 28 01 10     mov         edi,100128A0h
  1000266C: F3 AB              rep stos    dword ptr es:[edi]
  1000266E: 83 BC 24 28 01 00  cmp         dword ptr [esp+00000128h],1
            00 01
  10002676: 0F 85 13 01 00 00  jne         1000278F
  1000267C: 8B 7C 24 18        mov         edi,dword ptr [esp+18h]
  10002680: 89 7C 24 14        mov         dword ptr [esp+14h],edi
  10002684: 8D 87 AF 04 00 00  lea         eax,[edi+000004AFh]
  1000268A: 3B F8              cmp         edi,eax
  1000268C: 0F 8F E1 00 00 00  jg          10002773
  10002692: 8B C7              mov         eax,edi
  10002694: 8B DF              mov         ebx,edi
  10002696: 8D 2C 85 00 00 00  lea         ebp,[eax*4+00000000h]
            00
  1000269D: 89 6C 24 10        mov         dword ptr [esp+10h],ebp
  100026A1: DB 44 24 14        fild        dword ptr [esp+14h]
  100026A5: D8 1D 08 5B 01 10  fcomp       dword ptr ds:[10015B08h]   ; envData[5][NEXTT]
  100026AB: DF E0              fnstsw      ax
  100026AD: F6 C4 01           test        ah,1
  100026B0: 74 14              je          100026C6
  100026B2: D9 05 04 5B 01 10  fld         dword ptr ds:[10015B04h]   ; envData[5][dENV]
  100026B8: D8 05 FC 5A 01 10  fadd        dword ptr ds:[10015AFCh]   ; envData[5][ENV]
  100026BE: D9 1D FC 5A 01 10  fstp        dword ptr ds:[10015AFCh]   ; envData[5][ENV]
  100026C4: EB 0B              jmp         100026D1
  100026C6: 57                 push        edi
  100026C7: 6A 05              push        5
  100026C9: E8 82 EA FF FF     call        10001150   ; UpdateEnv
  100026CE: 83 C4 08           add         esp,8
  100026D1: 8B C7              mov         eax,edi
  100026D3: 99                 cdq
  100026D4: F7 BC 24 DC 00 00  idiv        eax,dword ptr [esp+000000DCh]
            00
  100026DB: 85 D2              test        edx,edx
  100026DD: 75 26              jne         10002705
  100026DF: E8 D3 0B 00 00     call        100032B7   ; rand
  100026E4: 89 84 24 94 00 00  mov         dword ptr [esp+00000094h],eax
            00
  100026EB: DB 84 24 94 00 00  fild        dword ptr [esp+00000094h]
            00
  100026F2: D8 0D 68 E1 00 10  fmul        dword ptr ds:[1000E168h]   ; float 3.0518509447574615e-05
  100026F8: D8 25 4C E1 00 10  fsub        dword ptr ds:[1000E14Ch]   ; float 0.5
  100026FE: D9 9C 24 94 00 00  fstp        dword ptr [esp+00000094h]
            00
  10002705: D9 84 24 F4 00 00  fld         dword ptr [esp+000000F4h]
            00
  1000270C: D8 8C 24 94 00 00  fmul        dword ptr [esp+00000094h]
            00
  10002713: 8B 44 24 10        mov         eax,dword ptr [esp+10h]
  10002717: 8B F5              mov         esi,ebp
  10002719: 2B F0              sub         esi,eax
  1000271B: D8 84 24 B4 00 00  fadd        dword ptr [esp+000000B4h]
            00
  10002722: D8 84 24 C0 00 00  fadd        dword ptr [esp+000000C0h]
            00
  10002729: D9 9C 24 B4 00 00  fstp        dword ptr [esp+000000B4h]
            00
  10002730: D9 84 24 B4 00 00  fld         dword ptr [esp+000000B4h]
            00
  10002737: DD 05 50 E1 00 10  fld         qword ptr ds:[1000E150h]   ; double 6.2831854820251465
  1000273D: E8 88 09 00 00     call        100030CA   ; _CIfmod
  10002742: D9 FF              fcos
  10002744: 47                 inc         edi
  10002745: 8D 83 AF 04 00 00  lea         eax,[ebx+000004AFh]
  1000274B: 83 C5 04           add         ebp,4
  1000274E: 3B F8              cmp         edi,eax
  10002750: 89 7C 24 14        mov         dword ptr [esp+14h],edi
  10002754: D8 0D FC 5A 01 10  fmul        dword ptr ds:[10015AFCh]   ; envData[5][ENV]
  1000275A: D8 8C 24 50 01 00  fmul        dword ptr [esp+00000150h]
            00
  10002761: D8 86 60 3B 01 10  fadd        dword ptr [esi+10013B60h]
  10002767: D9 9E 60 3B 01 10  fstp        dword ptr [esi+10013B60h]
  1000276D: 0F 8E 2E FF FF FF  jle         100026A1
  10002773: DB 44 24 14        fild        dword ptr [esp+14h]
  10002777: D8 1D F8 5A 01 10  fcomp       dword ptr ds:[10015AF8h]   ; envData[5][MAX]
  1000277D: DF E0              fnstsw      ax
  1000277F: F6 C4 01           test        ah,1
  10002782: 75 0B              jne         1000278F
  10002784: C7 84 24 28 01 00  mov         dword ptr [esp+00000128h],0
            00 00 00 00 00
  1000278F: 83 BC 24 2C 01 00  cmp         dword ptr [esp+0000012Ch],1
            00 01
  10002797: 0F 85 0F 01 00 00  jne         100028AC
  1000279D: 8B 7C 24 18        mov         edi,dword ptr [esp+18h]
  100027A1: 89 7C 24 14        mov         dword ptr [esp+14h],edi
  100027A5: 8D 87 AF 04 00 00  lea         eax,[edi+000004AFh]
  100027AB: 3B F8              cmp         edi,eax
  100027AD: 0F 8F DD 00 00 00  jg          10002890
  100027B3: 8B CF              mov         ecx,edi
  100027B5: 8D 1C 8D 00 00 00  lea         ebx,[ecx*4+00000000h]
            00
  100027BC: 8B EB              mov         ebp,ebx
  100027BE: DB 44 24 14        fild        dword ptr [esp+14h]
  100027C2: D8 1D 20 5B 01 10  fcomp       dword ptr ds:[10015B20h]   ; envData[6][NEXTT]
  100027C8: DF E0              fnstsw      ax
  100027CA: F6 C4 01           test        ah,1
  100027CD: 74 14              je          100027E3
  100027CF: D9 05 1C 5B 01 10  fld         dword ptr ds:[10015B1Ch]   ; envData[6][dENV]
  100027D5: D8 05 14 5B 01 10  fadd        dword ptr ds:[10015B14h]   ; envData[6][ENV]
  100027DB: D9 1D 14 5B 01 10  fstp        dword ptr ds:[10015B14h]   ; envData[6][ENV]
  100027E1: EB 0B              jmp         100027EE
  100027E3: 57                 push        edi
  100027E4: 6A 06              push        6
  100027E6: E8 65 E9 FF FF     call        10001150   ; UpdateEnv
  100027EB: 83 C4 08           add         esp,8
  100027EE: 8B C7              mov         eax,edi
  100027F0: 99                 cdq
  100027F1: F7 BC 24 90 00 00  idiv        eax,dword ptr [esp+00000090h]
            00
  100027F8: 85 D2              test        edx,edx
  100027FA: 75 26              jne         10002822
  100027FC: E8 B6 0A 00 00     call        100032B7   ; rand
  10002801: 89 84 24 98 00 00  mov         dword ptr [esp+00000098h],eax
            00
  10002808: DB 84 24 98 00 00  fild        dword ptr [esp+00000098h]
            00
  1000280F: D8 0D 68 E1 00 10  fmul        dword ptr ds:[1000E168h]   ; float 3.0518509447574615e-05
  10002815: D8 25 4C E1 00 10  fsub        dword ptr ds:[1000E14Ch]   ; float 0.5
  1000281B: D9 9C 24 98 00 00  fstp        dword ptr [esp+00000098h]
            00
  10002822: D9 84 24 1C 01 00  fld         dword ptr [esp+0000011Ch]
            00
  10002829: D8 8C 24 98 00 00  fmul        dword ptr [esp+00000098h]
            00
  10002830: 8B F5              mov         esi,ebp
  10002832: 2B F3              sub         esi,ebx
  10002834: D8 84 24 C4 00 00  fadd        dword ptr [esp+000000C4h]
            00
  1000283B: D8 84 24 BC 00 00  fadd        dword ptr [esp+000000BCh]
            00
  10002842: D9 9C 24 C4 00 00  fstp        dword ptr [esp+000000C4h]
            00
  10002849: D9 84 24 C4 00 00  fld         dword ptr [esp+000000C4h]
            00
  10002850: DD 05 50 E1 00 10  fld         qword ptr ds:[1000E150h]   ; double 6.2831854820251465
  10002856: E8 6F 08 00 00     call        100030CA   ; _CIfmod
  1000285B: D9 FF              fcos
  1000285D: 8B 54 24 18        mov         edx,dword ptr [esp+18h]
  10002861: 47                 inc         edi
  10002862: 83 C5 04           add         ebp,4
  10002865: 89 7C 24 14        mov         dword ptr [esp+14h],edi
  10002869: 8D 82 AF 04 00 00  lea         eax,[edx+000004AFh]
  1000286F: 3B F8              cmp         edi,eax
  10002871: D8 0D 14 5B 01 10  fmul        dword ptr ds:[10015B14h]   ; envData[6][ENV]
  10002877: D8 8C 24 4C 01 00  fmul        dword ptr [esp+0000014Ch]
            00
  1000287E: D8 86 60 3B 01 10  fadd        dword ptr [esi+10013B60h]
  10002884: D9 9E 60 3B 01 10  fstp        dword ptr [esi+10013B60h]
  1000288A: 0F 8E 2E FF FF FF  jle         100027BE
  10002890: DB 44 24 14        fild        dword ptr [esp+14h]
  10002894: D8 1D 10 5B 01 10  fcomp       dword ptr ds:[10015B10h]   ; envData[6][MAX]
  1000289A: DF E0              fnstsw      ax
  1000289C: F6 C4 01           test        ah,1
  1000289F: 75 0B              jne         100028AC
  100028A1: C7 84 24 2C 01 00  mov         dword ptr [esp+0000012Ch],0
            00 00 00 00 00
  100028AC: 8B 6C 24 18        mov         ebp,dword ptr [esp+18h]
  100028B0: 8B DD              mov         ebx,ebp
  100028B2: 8D 85 AF 04 00 00  lea         eax,[ebp+000004AFh]
  100028B8: 89 5C 24 14        mov         dword ptr [esp+14h],ebx
  100028BC: 3B E8              cmp         ebp,eax
  100028BE: 0F 8F 2E 05 00 00  jg          10002DF2
  100028C4: 8D 3C AD 00 00 00  lea         edi,[ebp*4+00000000h]
            00
  100028CB: 8B F7              mov         esi,edi
  100028CD: 83 BC 24 40 01 00  cmp         dword ptr [esp+00000140h],1
            00 01
  100028D5: 0F 85 02 03 00 00  jne         10002BDD
  100028DB: DB 44 24 14        fild        dword ptr [esp+14h]
  100028DF: D9 54 24 10        fst         dword ptr [esp+10h]
  100028E3: D8 1D D8 5A 01 10  fcomp       dword ptr ds:[10015AD8h]   ; envData[3][NEXTT]
  100028E9: DF E0              fnstsw      ax
  100028EB: F6 C4 01           test        ah,1
  100028EE: 74 14              je          10002904
  100028F0: D9 05 D4 5A 01 10  fld         dword ptr ds:[10015AD4h]   ; envData[3][dENV]
  100028F6: D8 05 CC 5A 01 10  fadd        dword ptr ds:[10015ACCh]   ; envData[3][ENV]
  100028FC: D9 1D CC 5A 01 10  fstp        dword ptr ds:[10015ACCh]   ; envData[3][ENV]
  10002902: EB 3C              jmp         10002940
  10002904: D9 44 24 10        fld         dword ptr [esp+10h]
  10002908: D8 1D C8 5A 01 10  fcomp       dword ptr ds:[10015AC8h]   ; envData[3][MAX]
  1000290E: DF E0              fnstsw      ax
  10002910: F6 C4 01           test        ah,1
  10002913: 75 20              jne         10002935
  10002915: C7 05 CC 5A 01 10  mov         dword ptr ds:[10015ACCh],0   ; envData[3][ENV]
            00 00 00 00
  1000291F: C7 05 D4 5A 01 10  mov         dword ptr ds:[10015AD4h],0   ; envData[3][dENV]
            00 00 00 00
  10002929: C7 05 D8 5A 01 10  mov         dword ptr ds:[10015AD8h],497423F0h   ; envData[3][NEXTT]
            F0 23 74 49
  10002933: EB 0B              jmp         10002940
  10002935: 53                 push        ebx
  10002936: 6A 03              push        3
  10002938: E8 13 E8 FF FF     call        10001150   ; UpdateEnv
  1000293D: 83 C4 08           add         esp,8
  10002940: D9 44 24 10        fld         dword ptr [esp+10h]
  10002944: D8 1D F0 5A 01 10  fcomp       dword ptr ds:[10015AF0h]   ; envData[4][NEXTT]
  1000294A: DF E0              fnstsw      ax
  1000294C: F6 C4 01           test        ah,1
  1000294F: 74 14              je          10002965
  10002951: D9 05 EC 5A 01 10  fld         dword ptr ds:[10015AECh]   ; envData[4][dENV]
  10002957: D8 05 E4 5A 01 10  fadd        dword ptr ds:[10015AE4h]   ; envData[4][ENV]
  1000295D: D9 1D E4 5A 01 10  fstp        dword ptr ds:[10015AE4h]   ; envData[4][ENV]
  10002963: EB 3C              jmp         100029A1
  10002965: D9 44 24 10        fld         dword ptr [esp+10h]
  10002969: D8 1D E0 5A 01 10  fcomp       dword ptr ds:[10015AE0h]   ; envData[4][MAX]
  1000296F: DF E0              fnstsw      ax
  10002971: F6 C4 01           test        ah,1
  10002974: 75 20              jne         10002996
  10002976: C7 05 E4 5A 01 10  mov         dword ptr ds:[10015AE4h],0   ; envData[4][ENV]
            00 00 00 00
  10002980: C7 05 EC 5A 01 10  mov         dword ptr ds:[10015AECh],0   ; envData[4][dENV]
            00 00 00 00
  1000298A: C7 05 F0 5A 01 10  mov         dword ptr ds:[10015AF0h],497423F0h   ; envData[4][NEXTT]
            F0 23 74 49
  10002994: EB 0B              jmp         100029A1
  10002996: 53                 push        ebx
  10002997: 6A 04              push        4
  10002999: E8 B2 E7 FF FF     call        10001150   ; UpdateEnv
  1000299E: 83 C4 08           add         esp,8
  100029A1: D9 44 24 78        fld         dword ptr [esp+78h]
  100029A5: 8B 8C 24 0C 01 00  mov         ecx,dword ptr [esp+0000010Ch]
            00
  100029AC: 8B C6              mov         eax,esi
  100029AE: 2B C7              sub         eax,edi
  100029B0: D8 80 A0 28 01 10  fadd        dword ptr [eax+100128A0h]
  100029B6: B8 01 00 00 00     mov         eax,1
  100029BB: 3B C8              cmp         ecx,eax
  100029BD: D9 5C 24 78        fstp        dword ptr [esp+78h]
  100029C1: 75 0A              jne         100029CD
  100029C3: D9 44 24 70        fld         dword ptr [esp+70h]
  100029C7: D8 4C 24 78        fmul        dword ptr [esp+78h]
  100029CB: EB 08              jmp         100029D5
  100029CD: D9 44 24 44        fld         dword ptr [esp+44h]
  100029D1: D8 44 24 70        fadd        dword ptr [esp+70h]
  100029D5: 8B 8C 24 24 01 00  mov         ecx,dword ptr [esp+00000124h]
            00
  100029DC: D9 5C 24 44        fstp        dword ptr [esp+44h]
  100029E0: 3B C8              cmp         ecx,eax
  100029E2: 75 0D              jne         100029F1
  100029E4: D9 84 24 80 00 00  fld         dword ptr [esp+00000080h]
            00
  100029EB: D8 4C 24 78        fmul        dword ptr [esp+78h]
  100029EF: EB 0B              jmp         100029FC
  100029F1: D9 44 24 40        fld         dword ptr [esp+40h]
  100029F5: D8 84 24 80 00 00  fadd        dword ptr [esp+00000080h]
            00
  100029FC: 8B 84 24 44 01 00  mov         eax,dword ptr [esp+00000144h]
            00
  10002A03: C7 44 24 1C 00 00  mov         dword ptr [esp+1Ch],0
            00 00
  10002A0B: D9 5C 24 40        fstp        dword ptr [esp+40h]
  10002A0F: 83 F8 03           cmp         eax,3
  10002A12: 0F 87 C5 01 00 00  ja          10002BDD
  10002A18: FF 24 85 F8 2F 00  jmp         dword ptr [eax*4+10002FF8h]
            10
  10002A1F: 8B 84 24 C8 00 00  mov         eax,dword ptr [esp+000000C8h]
            00
  10002A26: 8B 4C 24 44        mov         ecx,dword ptr [esp+44h]
  10002A2A: 50                 push        eax
  10002A2B: 51                 push        ecx
  10002A2C: E8 1F E9 FF FF     call        10001350   ; waveform
  10002A31: D8 0D CC 5A 01 10  fmul        dword ptr ds:[10015ACCh]   ; envData[3][ENV]
  10002A37: 8B 94 24 B8 00 00  mov         edx,dword ptr [esp+000000B8h]
            00
  10002A3E: 8B 44 24 48        mov         eax,dword ptr [esp+48h]
  10002A42: 52                 push        edx
  10002A43: 50                 push        eax
  10002A44: D8 8C 24 E0 00 00  fmul        dword ptr [esp+000000E0h]
            00
  10002A4B: D9 5C 24 2C        fstp        dword ptr [esp+2Ch]
  10002A4F: E8 FC E8 FF FF     call        10001350   ; waveform
  10002A54: D8 0D E4 5A 01 10  fmul        dword ptr ds:[10015AE4h]   ; envData[4][ENV]
  10002A5A: 83 C4 10           add         esp,10h
  10002A5D: D8 8C 24 88 00 00  fmul        dword ptr [esp+00000088h]
            00
  10002A64: D8 44 24 1C        fadd        dword ptr [esp+1Ch]
  10002A68: D8 8C 24 8C 00 00  fmul        dword ptr [esp+0000008Ch]
            00
  10002A6F: D9 5C 24 1C        fstp        dword ptr [esp+1Ch]
  10002A73: E9 65 01 00 00     jmp         10002BDD
  10002A78: 8B 8C 24 B0 00 00  mov         ecx,dword ptr [esp+000000B0h]
            00
  10002A7F: 8B 54 24 40        mov         edx,dword ptr [esp+40h]
  10002A83: 51                 push        ecx
  10002A84: 52                 push        edx
  10002A85: E8 C6 E8 FF FF     call        10001350   ; waveform
  10002A8A: D8 0D E4 5A 01 10  fmul        dword ptr ds:[10015AE4h]   ; envData[4][ENV]
  10002A90: 8B 84 24 D0 00 00  mov         eax,dword ptr [esp+000000D0h]
            00
  10002A97: 83 C4 08           add         esp,8
  10002A9A: D8 8C 24 14 01 00  fmul        dword ptr [esp+00000114h]
            00
  10002AA1: 50                 push        eax
  10002AA2: 51                 push        ecx
  10002AA3: D8 44 24 4C        fadd        dword ptr [esp+4Ch]
  10002AA7: D9 1C 24           fstp        dword ptr [esp]
  10002AAA: E8 A1 E8 FF FF     call        10001350   ; waveform
  10002AAF: D8 0D CC 5A 01 10  fmul        dword ptr ds:[10015ACCh]   ; envData[3][ENV]
  10002AB5: 83 C4 08           add         esp,8
  10002AB8: D8 8C 24 8C 00 00  fmul        dword ptr [esp+0000008Ch]
            00
  10002ABF: D9 5C 24 1C        fstp        dword ptr [esp+1Ch]
  10002AC3: E9 15 01 00 00     jmp         10002BDD
  10002AC8: D9 84 24 14 01 00  fld         dword ptr [esp+00000114h]
            00
  10002ACF: D8 0D 64 E1 00 10  fmul        dword ptr ds:[1000E164h]   ; float 0.125
  10002AD5: 8B 8C 24 B0 00 00  mov         ecx,dword ptr [esp+000000B0h]
            00
  10002ADC: 8B 54 24 40        mov         edx,dword ptr [esp+40h]
  10002AE0: 51                 push        ecx
  10002AE1: 52                 push        edx
  10002AE2: D9 5C 24 18        fstp        dword ptr [esp+18h]
  10002AE6: E8 65 E8 FF FF     call        10001350   ; waveform
  10002AEB: D9 44 24 18        fld         dword ptr [esp+18h]
  10002AEF: D8 0D E4 5A 01 10  fmul        dword ptr ds:[10015AE4h]   ; envData[4][ENV]
  10002AF5: 8B 84 24 D0 00 00  mov         eax,dword ptr [esp+000000D0h]
            00
  10002AFC: 8B 4C 24 4C        mov         ecx,dword ptr [esp+4Ch]
  10002B00: 50                 push        eax
  10002B01: 51                 push        ecx
  10002B02: DE C9              fmulp       st(1),st
  10002B04: D9 05 28 E1 00 10  fld         dword ptr ds:[1000E128h]   ; float 1.0
  10002B0A: D8 64 24 20        fsub        dword ptr [esp+20h]
  10002B0E: DE C1              faddp       st(1),st
  10002B10: D9 5C 24 2C        fstp        dword ptr [esp+2Ch]
  10002B14: E8 37 E8 FF FF     call        10001350   ; waveform
  10002B19: D8 4C 24 2C        fmul        dword ptr [esp+2Ch]
  10002B1D: 83 C4 10           add         esp,10h
  10002B20: D8 0D CC 5A 01 10  fmul        dword ptr ds:[10015ACCh]   ; envData[3][ENV]
  10002B26: D8 8C 24 8C 00 00  fmul        dword ptr [esp+0000008Ch]
            00
  10002B2D: D9 5C 24 1C        fstp        dword ptr [esp+1Ch]
  10002B31: E9 A7 00 00 00     jmp         10002BDD
  10002B36: 8D 8C 24 DC 01 00  lea         ecx,[esp+000001DCh]
            00
  10002B3D: BA 06 00 00 00     mov         edx,6
  10002B42: D9 01              fld         dword ptr [ecx]
  10002B44: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  10002B4A: D9 54 24 10        fst         dword ptr [esp+10h]
  10002B4E: D9 19              fstp        dword ptr [ecx]
  10002B50: D9 44 24 10        fld         dword ptr [esp+10h]
  10002B54: D8 59 04           fcomp       dword ptr [ecx+4]
  10002B57: DF E0              fnstsw      ax
  10002B59: F6 C4 41           test        ah,41h
  10002B5C: 75 1A              jne         10002B78
  10002B5E: D9 44 24 10        fld         dword ptr [esp+10h]
  10002B62: D8 61 04           fsub        dword ptr [ecx+4]
  10002B65: D9 19              fstp        dword ptr [ecx]
  10002B67: D9 05 CC 5A 01 10  fld         dword ptr ds:[10015ACCh]   ; envData[3][ENV]
  10002B6D: D8 8C 24 8C 00 00  fmul        dword ptr [esp+0000008Ch]
            00
  10002B74: D9 5C 24 1C        fstp        dword ptr [esp+1Ch]
  10002B78: 83 C1 08           add         ecx,8
  10002B7B: 4A                 dec         edx
  10002B7C: 75 C4              jne         10002B42
  10002B7E: D9 05 E4 5A 01 10  fld         dword ptr ds:[10015AE4h]   ; envData[4][ENV]
  10002B84: D8 8C 24 48 01 00  fmul        dword ptr [esp+00000148h]
            00
  10002B8B: 8B 54 24 1C        mov         edx,dword ptr [esp+1Ch]
  10002B8F: D9 C0              fld         st(0)
  10002B91: D8 4C 24 74        fmul        dword ptr [esp+74h]
  10002B95: D8 84 24 B8 00 00  fadd        dword ptr [esp+000000B8h]
            00
  10002B9C: D9 9C 24 B8 00 00  fstp        dword ptr [esp+000000B8h]
            00
  10002BA3: D9 44 24 1C        fld         dword ptr [esp+1Ch]
  10002BA7: D8 84 24 F8 00 00  fadd        dword ptr [esp+000000F8h]
            00
  10002BAE: D9 84 24 34 01 00  fld         dword ptr [esp+00000134h]
            00
  10002BB5: D8 4C 24 74        fmul        dword ptr [esp+74h]
  10002BB9: 89 94 24 F8 00 00  mov         dword ptr [esp+000000F8h],edx
            00
  10002BC0: DE E9              fsubp       st(1),st
  10002BC2: D8 A4 24 B8 00 00  fsub        dword ptr [esp+000000B8h]
            00
  10002BC9: D8 C9              fmul        st,st(1)
  10002BCB: D8 44 24 74        fadd        dword ptr [esp+74h]
  10002BCF: D9 5C 24 74        fstp        dword ptr [esp+74h]
  10002BD3: 8B 44 24 74        mov         eax,dword ptr [esp+74h]
  10002BD7: DD D8              fstp        st(0)
  10002BD9: 89 44 24 1C        mov         dword ptr [esp+1Ch],eax
  10002BDD: 8B 84 24 A4 00 00  mov         eax,dword ptr [esp+000000A4h]
            00
  10002BE4: 83 F8 01           cmp         eax,1
  10002BE7: 0F 85 DF 00 00 00  jne         10002CCC
  10002BED: DB 44 24 14        fild        dword ptr [esp+14h]
  10002BF1: D8 1D 38 5B 01 10  fcomp       dword ptr ds:[10015B38h]   ; envData[7][NEXTT]
  10002BF7: DF E0              fnstsw      ax
  10002BF9: F6 C4 01           test        ah,1
  10002BFC: 74 14              je          10002C12
  10002BFE: D9 05 34 5B 01 10  fld         dword ptr ds:[10015B34h]   ; envData[7][dENV]
  10002C04: D8 05 2C 5B 01 10  fadd        dword ptr ds:[10015B2Ch]   ; envData[7][ENV]
  10002C0A: D9 1D 2C 5B 01 10  fstp        dword ptr ds:[10015B2Ch]   ; envData[7][ENV]
  10002C10: EB 0B              jmp         10002C1D
  10002C12: 53                 push        ebx
  10002C13: 6A 07              push        7
  10002C15: E8 36 E5 FF FF     call        10001150   ; UpdateEnv
  10002C1A: 83 C4 08           add         esp,8
  10002C1D: 8B 0D 2C 5B 01 10  mov         ecx,dword ptr ds:[10015B2Ch]   ; envData[7][ENV]
  10002C23: 89 4C 24 38        mov         dword ptr [esp+38h],ecx
  10002C27: D9 44 24 38        fld         dword ptr [esp+38h]
  10002C2B: D8 1D 1C E2 00 10  fcomp       dword ptr ds:[1000E21Ch]   ; float 0.20000000298023224
  10002C31: DF E0              fnstsw      ax
  10002C33: F6 C4 41           test        ah,41h
  10002C36: 75 1D              jne         10002C55
  10002C38: DD 05 D0 E1 00 10  fld         qword ptr ds:[1000E1D0h]   ; double 10.0
  10002C3E: D9 44 24 38        fld         dword ptr [esp+38h]
  10002C42: D8 25 28 E1 00 10  fsub        dword ptr ds:[1000E128h]   ; float 1.0
  10002C48: E8 43 09 00 00     call        10003590   ; pow (_CIpow)
  10002C4D: D8 2D 60 E1 00 10  fsubr       dword ptr ds:[1000E160h]   ; float 1.0010000467300415
  10002C53: EB 10              jmp         10002C65
  10002C55: D9 44 24 38        fld         dword ptr [esp+38h]
  10002C59: D8 0D 5C E1 00 10  fmul        dword ptr ds:[1000E15Ch]   ; float 0.7824000120162964
  10002C5F: D8 2D 58 E1 00 10  fsubr       dword ptr ds:[1000E158h]   ; float 0.9990000128746033
  10002C65: D9 05 28 E1 00 10  fld         dword ptr ds:[1000E128h]   ; float 1.0
  10002C6B: D8 F1              fdiv        st,st(1)
  10002C6D: 8B D6              mov         edx,esi
  10002C6F: 8B C6              mov         eax,esi
  10002C71: 2B D7              sub         edx,edi
  10002C73: 2B C7              sub         eax,edi
  10002C75: 89 54 24 10        mov         dword ptr [esp+10h],edx
  10002C79: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  10002C7F: D9 44 24 28        fld         dword ptr [esp+28h]
  10002C83: D8 64 24 34        fsub        dword ptr [esp+34h]
  10002C87: DE C9              fmulp       st(1),st
  10002C89: D8 8C 24 00 01 00  fmul        dword ptr [esp+00000100h]
            00
  10002C90: D8 44 24 1C        fadd        dword ptr [esp+1Ch]
  10002C94: D9 44 24 28        fld         dword ptr [esp+28h]
  10002C98: D8 E1              fsub        st,st(1)
  10002C9A: D8 CA              fmul        st,st(2)
  10002C9C: D8 C1              fadd        st,st(1)
  10002C9E: D9 5C 24 28        fstp        dword ptr [esp+28h]
  10002CA2: DD D8              fstp        st(0)
  10002CA4: D9 44 24 34        fld         dword ptr [esp+34h]
  10002CA8: D8 64 24 28        fsub        dword ptr [esp+28h]
  10002CAC: D8 C9              fmul        st,st(1)
  10002CAE: D8 44 24 28        fadd        dword ptr [esp+28h]
  10002CB2: D9 5C 24 34        fstp        dword ptr [esp+34h]
  10002CB6: DD D8              fstp        st(0)
  10002CB8: DB 84 24 08 01 00  fild        dword ptr [esp+00000108h]
            00
  10002CBF: D8 4C 24 1C        fmul        dword ptr [esp+1Ch]
  10002CC3: D8 6C 24 34        fsubr       dword ptr [esp+34h]
  10002CC7: E9 04 01 00 00     jmp         10002DD0
  10002CCC: 83 F8 02           cmp         eax,2
  10002CCF: 0F 85 EB 00 00 00  jne         10002DC0
  10002CD5: DB 44 24 14        fild        dword ptr [esp+14h]
  10002CD9: D8 1D 38 5B 01 10  fcomp       dword ptr ds:[10015B38h]   ; envData[7][NEXTT]
  10002CDF: DF E0              fnstsw      ax
  10002CE1: F6 C4 01           test        ah,1
  10002CE4: 74 14              je          10002CFA
  10002CE6: D9 05 34 5B 01 10  fld         dword ptr ds:[10015B34h]   ; envData[7][dENV]
  10002CEC: D8 05 2C 5B 01 10  fadd        dword ptr ds:[10015B2Ch]   ; envData[7][ENV]
  10002CF2: D9 1D 2C 5B 01 10  fstp        dword ptr ds:[10015B2Ch]   ; envData[7][ENV]
  10002CF8: EB 0B              jmp         10002D05
  10002CFA: 53                 push        ebx
  10002CFB: 6A 07              push        7
  10002CFD: E8 4E E4 FF FF     call        10001150   ; UpdateEnv
  10002D02: 83 C4 08           add         esp,8
  10002D05: A1 2C 5B 01 10     mov         eax,dword ptr ds:[10015B2Ch]   ; envData[7][ENV]
  10002D0A: 89 44 24 38        mov         dword ptr [esp+38h],eax
  10002D0E: D9 44 24 38        fld         dword ptr [esp+38h]
  10002D12: D8 1D 1C E2 00 10  fcomp       dword ptr ds:[1000E21Ch]   ; float 0.20000000298023224
  10002D18: DF E0              fnstsw      ax
  10002D1A: F6 C4 41           test        ah,41h
  10002D1D: 75 1D              jne         10002D3C
  10002D1F: DD 05 D0 E1 00 10  fld         qword ptr ds:[1000E1D0h]   ; double 10.0
  10002D25: D9 44 24 38        fld         dword ptr [esp+38h]
  10002D29: D8 25 28 E1 00 10  fsub        dword ptr ds:[1000E128h]   ; float 1.0
  10002D2F: E8 5C 08 00 00     call        10003590   ; pow (_CIpow)
  10002D34: D8 2D 60 E1 00 10  fsubr       dword ptr ds:[1000E160h]   ; float 1.0010000467300415
  10002D3A: EB 10              jmp         10002D4C
  10002D3C: D9 44 24 38        fld         dword ptr [esp+38h]
  10002D40: D8 0D 5C E1 00 10  fmul        dword ptr ds:[1000E15Ch]   ; float 0.7824000120162964
  10002D46: D8 2D 58 E1 00 10  fsubr       dword ptr ds:[1000E158h]   ; float 0.9990000128746033
  10002D4C: D9 05 28 E1 00 10  fld         dword ptr ds:[1000E128h]   ; float 1.0
  10002D52: D8 F1              fdiv        st,st(1)
  10002D54: 8B C6              mov         eax,esi
  10002D56: 8B CE              mov         ecx,esi
  10002D58: 2B C7              sub         eax,edi
  10002D5A: 2B CF              sub         ecx,edi
  10002D5C: 89 4C 24 10        mov         dword ptr [esp+10h],ecx
  10002D60: D8 05 28 E1 00 10  fadd        dword ptr ds:[1000E128h]   ; float 1.0
  10002D66: D9 44 24 28        fld         dword ptr [esp+28h]
  10002D6A: D8 64 24 34        fsub        dword ptr [esp+34h]
  10002D6E: DE C9              fmulp       st(1),st
  10002D70: D8 8C 24 00 01 00  fmul        dword ptr [esp+00000100h]
            00
  10002D77: D8 80 60 3B 01 10  fadd        dword ptr [eax+10013B60h]
  10002D7D: 8B C6              mov         eax,esi
  10002D7F: 2B C7              sub         eax,edi
  10002D81: D8 44 24 1C        fadd        dword ptr [esp+1Ch]
  10002D85: D9 44 24 28        fld         dword ptr [esp+28h]
  10002D89: D8 E1              fsub        st,st(1)
  10002D8B: D8 CA              fmul        st,st(2)
  10002D8D: D8 C1              fadd        st,st(1)
  10002D8F: D9 5C 24 28        fstp        dword ptr [esp+28h]
  10002D93: DD D8              fstp        st(0)
  10002D95: D9 44 24 34        fld         dword ptr [esp+34h]
  10002D99: D8 64 24 28        fsub        dword ptr [esp+28h]
  10002D9D: D8 C9              fmul        st,st(1)
  10002D9F: D8 44 24 28        fadd        dword ptr [esp+28h]
  10002DA3: D9 5C 24 34        fstp        dword ptr [esp+34h]
  10002DA7: DD D8              fstp        st(0)
  10002DA9: D9 44 24 1C        fld         dword ptr [esp+1Ch]
  10002DAD: D8 80 60 3B 01 10  fadd        dword ptr [eax+10013B60h]
  10002DB3: DA 8C 24 08 01 00  fimul       dword ptr [esp+00000108h]
            00
  10002DBA: D8 6C 24 34        fsubr       dword ptr [esp+34h]
  10002DBE: EB 16              jmp         10002DD6
  10002DC0: D9 44 24 1C        fld         dword ptr [esp+1Ch]
  10002DC4: 8B D6              mov         edx,esi
  10002DC6: 8B C6              mov         eax,esi
  10002DC8: 2B D7              sub         edx,edi
  10002DCA: 2B C7              sub         eax,edi
  10002DCC: 89 54 24 10        mov         dword ptr [esp+10h],edx
  10002DD0: D8 80 60 3B 01 10  fadd        dword ptr [eax+10013B60h]
  10002DD6: D9 98 60 3B 01 10  fstp        dword ptr [eax+10013B60h]
  10002DDC: 43                 inc         ebx
  10002DDD: 8D 85 AF 04 00 00  lea         eax,[ebp+000004AFh]
  10002DE3: 83 C6 04           add         esi,4
  10002DE6: 3B D8              cmp         ebx,eax
  10002DE8: 89 5C 24 14        mov         dword ptr [esp+14h],ebx
  10002DEC: 0F 8E DB FA FF FF  jle         100028CD
  10002DF2: 83 BC 24 D4 00 00  cmp         dword ptr [esp+000000D4h],1
            00 01
  10002DFA: 0F 85 88 00 00 00  jne         10002E88
  10002E00: BE 60 3B 01 10     mov         esi,10013B60h
  10002E05: D9 06              fld         dword ptr [esi]
  10002E07: D8 74 24 30        fdiv        dword ptr [esp+30h]
  10002E0B: E8 50 02 00 00     call        10003060   ; _ftol
  10002E10: 89 44 24 10        mov         dword ptr [esp+10h],eax
  10002E14: 83 C6 04           add         esi,4
  10002E17: DB 44 24 10        fild        dword ptr [esp+10h]
  10002E1B: 81 FE 20 4E 01 10  cmp         esi,10014E20h
  10002E21: D8 4C 24 7C        fmul        dword ptr [esp+7Ch]
  10002E25: D9 5E FC           fstp        dword ptr [esi-4]
  10002E28: 7C DB              jl          10002E05
  10002E2A: 8B 9C 24 84 00 00  mov         ebx,dword ptr [esp+00000084h]
            00
  10002E31: 33 D2              xor         edx,edx
  10002E33: BD 60 3B 01 10     mov         ebp,10013B60h
  10002E38: D9 05 14 E1 00 10  fld         dword ptr ds:[1000E114h]   ; float 0.0
  10002E3E: 8D 4C 1A FF        lea         ecx,[edx+ebx-1]
  10002E42: 3B D1              cmp         edx,ecx
  10002E44: 7F 0F              jg          10002E55
  10002E46: 8B C1              mov         eax,ecx
  10002E48: 8B F5              mov         esi,ebp
  10002E4A: 2B C2              sub         eax,edx
  10002E4C: 40                 inc         eax
  10002E4D: D8 06              fadd        dword ptr [esi]
  10002E4F: 83 C6 04           add         esi,4
  10002E52: 48                 dec         eax
  10002E53: 75 F8              jne         10002E4D
  10002E55: DB 84 24 84 00 00  fild        dword ptr [esp+00000084h]
            00
  10002E5C: 3B D1              cmp         edx,ecx
  10002E5E: D8 F9              fdivr       st,st(1)
  10002E60: D9 5C 24 10        fstp        dword ptr [esp+10h]
  10002E64: DD D8              fstp        st(0)
  10002E66: 7F 0B              jg          10002E73
  10002E68: 8B 44 24 10        mov         eax,dword ptr [esp+10h]
  10002E6C: 2B CA              sub         ecx,edx
  10002E6E: 41                 inc         ecx
  10002E6F: 8B FD              mov         edi,ebp
  10002E71: F3 AB              rep stos    dword ptr es:[edi]
  10002E73: 8D 04 9D 00 00 00  lea         eax,[ebx*4+00000000h]
            00
  10002E7A: 03 D3              add         edx,ebx
  10002E7C: 03 E8              add         ebp,eax
  10002E7E: 81 FD 20 4E 01 10  cmp         ebp,10014E20h
  10002E84: 7C B2              jl          10002E38
  10002E86: EB 18              jmp         10002EA0
  10002E88: B8 60 3B 01 10     mov         eax,10013B60h
  10002E8D: D9 44 24 7C        fld         dword ptr [esp+7Ch]
  10002E91: D8 08              fmul        dword ptr [eax]
  10002E93: 83 C0 04           add         eax,4
  10002E96: 3D 20 4E 01 10     cmp         eax,10014E20h
  10002E9B: D9 58 FC           fstp        dword ptr [eax-4]
  10002E9E: 7C ED              jl          10002E8D
  10002EA0: BE 60 3B 01 10     mov         esi,10013B60h
  10002EA5: 66 8B 0D 60 5A 01  mov         cx,word ptr ds:[10015A60h]
            10
  10002EAC: 8B 3D EC 24 01 10  mov         edi,dword ptr ds:[100124ECh]   ; wave
  10002EB2: 0F BF D1           movsx       edx,cx
  10002EB5: 89 54 24 10        mov         dword ptr [esp+10h],edx
  10002EB9: DB 44 24 10        fild        dword ptr [esp+10h]
  10002EBD: D8 1E              fcomp       dword ptr [esi]
  10002EBF: DF E0              fnstsw      ax
  10002EC1: F6 C4 01           test        ah,1
  10002EC4: 74 0B              je          10002ED1
  10002EC6: A1 20 5A 01 10     mov         eax,dword ptr ds:[10015A20h]   ; wavewords
  10002ECB: 66 89 0C 47        mov         word ptr [edi+eax*2],cx
  10002ECF: EB 33              jmp         10002F04
  10002ED1: F7 DA              neg         edx
  10002ED3: 89 54 24 10        mov         dword ptr [esp+10h],edx
  10002ED7: DB 44 24 10        fild        dword ptr [esp+10h]
  10002EDB: D8 1E              fcomp       dword ptr [esi]
  10002EDD: DF E0              fnstsw      ax
  10002EDF: F6 C4 41           test        ah,41h
  10002EE2: 75 0F              jne         10002EF3
  10002EE4: 8B 15 20 5A 01 10  mov         edx,dword ptr ds:[10015A20h]   ; wavewords
  10002EEA: 66 F7 D9           neg         cx
  10002EED: 66 89 0C 57        mov         word ptr [edi+edx*2],cx
  10002EF1: EB 11              jmp         10002F04
  10002EF3: D9 06              fld         dword ptr [esi]
  10002EF5: E8 66 01 00 00     call        10003060   ; _ftol
  10002EFA: 8B 0D 20 5A 01 10  mov         ecx,dword ptr ds:[10015A20h]   ; wavewords
  10002F00: 66 89 04 4F        mov         word ptr [edi+ecx*2],ax
  10002F04: A1 20 5A 01 10     mov         eax,dword ptr ds:[10015A20h]   ; wavewords
  10002F09: 83 C6 04           add         esi,4
  10002F0C: 40                 inc         eax
  10002F0D: 81 FE 20 4E 01 10  cmp         esi,10014E20h
  10002F13: A3 20 5A 01 10     mov         dword ptr ds:[10015A20h],eax   ; wavewords
  10002F18: 7C 8B              jl          10002EA5
  10002F1A: 8B 74 24 18        mov         esi,dword ptr [esp+18h]
  10002F1E: 8B 7C 24 20        mov         edi,dword ptr [esp+20h]
  10002F22: 8D 04 B6           lea         eax,[esi+esi*4]
  10002F25: 8D 04 80           lea         eax,[eax+eax*4]
  10002F28: C1 E0 02           shl         eax,2
  10002F2B: 99                 cdq
  10002F2C: F7 FF              idiv        eax,edi
  10002F2E: 8B 94 24 10 01 00  mov         edx,dword ptr [esp+00000110h]
            00
  10002F35: 83 C2 04           add         edx,4
  10002F38: 3B C2              cmp         eax,edx
  10002F3A: 7E 37              jle         10002F73
  10002F3C: 89 84 24 10 01 00  mov         dword ptr [esp+00000110h],eax
            00
  10002F43: 50                 push        eax
  10002F44: 8D 84 24 D0 01 00  lea         eax,[esp+000001D0h]
            00
  10002F4B: 68 58 F0 00 10     push        1000F058h
  10002F50: 50                 push        eax
  10002F51: E8 02 03 00 00     call        10003258   ; sprintf
  10002F56: 8B 84 24 24 03 00  mov         eax,dword ptr [esp+00000324h]
            00
  10002F5D: 83 C4 0C           add         esp,0Ch
  10002F60: 85 C0              test        eax,eax
  10002F62: 76 0F              jbe         10002F73
  10002F64: 8D 8C 24 CC 01 00  lea         ecx,[esp+000001CCh]
            00
  10002F6B: 51                 push        ecx
  10002F6C: 50                 push        eax
  10002F6D: FF 15 00 E1 00 10  call        dword ptr ds:[1000E100h]   ; SetWindowTextA
  10002F73: 81 C6 B0 04 00 00  add         esi,4B0h
  10002F79: 3B F7              cmp         esi,edi
  10002F7B: 89 74 24 18        mov         dword ptr [esp+18h],esi
  10002F7F: 0F 8C 23 F4 FF FF  jl          100023A8
  10002F85: A1 F0 24 01 10     mov         eax,dword ptr ds:[100124F0h]   ; wavemode
  10002F8A: 33 FF              xor         edi,edi
  10002F8C: 3B C7              cmp         eax,edi
  10002F8E: 75 4D              jne         10002FDD
  10002F90: 8B B4 24 9C 00 00  mov         esi,dword ptr [esp+0000009Ch]
            00
  10002F97: 8B 54 24 20        mov         edx,dword ptr [esp+20h]
  10002F9B: A1 EC 24 01 10     mov         eax,dword ptr ds:[100124ECh]   ; wave
  10002FA0: 56                 push        esi
  10002FA1: 52                 push        edx
  10002FA2: 6A 02              push        2
  10002FA4: 50                 push        eax
  10002FA5: E8 2F 03 00 00     call        100032D9   ; fwrite
  10002FAA: 56                 push        esi
  10002FAB: 6A 2C              push        2Ch
  10002FAD: 8D 8C 24 98 01 00  lea         ecx,[esp+00000198h]
            00
  10002FB4: 6A 01              push        1
  10002FB6: 51                 push        ecx
  10002FB7: E8 1D 03 00 00     call        100032D9   ; fwrite
  10002FBC: 8B 94 24 C8 00 00  mov         edx,dword ptr [esp+000000C8h]
            00
  10002FC3: 56                 push        esi
  10002FC4: 52                 push        edx
  10002FC5: 8D 84 24 34 02 00  lea         eax,[esp+00000234h]
            00
  10002FCC: 6A 01              push        1
  10002FCE: 50                 push        eax
  10002FCF: E8 05 03 00 00     call        100032D9   ; fwrite
  10002FD4: 56                 push        esi
  10002FD5: E8 01 02 00 00     call        100031DB   ; fclose
  10002FDA: 83 C4 34           add         esp,34h
  10002FDD: 89 3D F0 24 01 10  mov         dword ptr ds:[100124F0h],edi   ; wavemode
  10002FE3: 89 3D E8 24 01 10  mov         dword ptr ds:[100124E8h],edi
  10002FE9: 5F                 pop         edi
  10002FEA: 5E                 pop         esi
  10002FEB: 5D                 pop         ebp
  10002FEC: 33 C0              xor         eax,eax
  10002FEE: 5B                 pop         ebx
  10002FEF: 81 C4 FC 02 00 00  add         esp,2FCh
  10002FF5: C2 0C 00           ret         0Ch
  10002FF8: 1F                 pop         ds
  10002FF9: 2A 00              sub         al,byte ptr [eax]
  10002FFB: 10 78 2A           adc         byte ptr [eax+2Ah],bh
  10002FFE: 00 10              add         byte ptr [eax],dl
  10003000: C8 2A 00 10        enter       2Ah,10h
  10003004: 36 2B 00           sub         eax,dword ptr ss:[eax]
  10003007: 10 90 90 90 90 90  adc         byte ptr [eax+90909090h],dl

