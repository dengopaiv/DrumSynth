"""Experiments on the Windows profile functions (GetPrivateProfileStringA/IntA).

Usage: python tools/probes/ini_rules.py

Writes small .ds files to a temporary folder and prints what Windows returns
for them. The rules found are in docs/reference/ini-rules.md and are
implemented in engine/src/ds_ini.c; ini_probe.c then checks the parser
against Windows on all presets and on generated files.
"""
import ctypes, os, tempfile
k=ctypes.windll.kernel32
d=tempfile.mkdtemp(); path=os.path.join(d,'t.ds')
def put(data):
    open(path,'wb').write(data)
def gs(sec,key,size=256,default=b''):
    buf=ctypes.create_string_buffer(size+4)
    n=k.GetPrivateProfileStringA(sec,key,default,buf,size,path.encode())
    return n,buf.raw[:n]
def gi(sec,key,default=7):
    return k.GetPrivateProfileIntA(sec,key,default,path.encode()) & 0xffffffff
# 1. int digits
put(b"[T]\na="+b"1"*60+b"\n")
v=gi(b"T",b"a")
print('int digits:',[n for n in range(1,61) if int("1"*n)%2**32==v])
# whitespace bytes trimmed at value start / end, key start
lead=[];trail=[];keylead=[];intskip=[]
for c in range(1,256):
    if c in (10,13): continue
    b=bytes([c])
    put(b"[T]\na="+b+b"5\n")
    n,s=gs(b"T",b"a")
    if s==b"5": lead.append(c)
    if gi(b"T",b"a")==5: intskip.append(c)
    put(b"[T]\na=5"+b+b"\n")
    n,s=gs(b"T",b"a")
    if s==b"5": trail.append(c)
    put(b"[T]\n"+b+b"a=5\n")
    if gs(b"T",b"a")[1]==b"5": keylead.append(c)
print('lead trimmed',lead); print('trail trimmed',trail); print('key lead',keylead); print('int skips',intskip)
# comments
for pre in (b";",b"#",b" ;",b"//",b"\t;"):
    put(b"[T]\n"+pre+b"a=5\n"); print('comment',pre,gs(b"T",pre.strip()+b"a"), gs(b"T",b"a"))
# section names
for hdr in (b"[ T ]",b"[T ] x",b"[T]]",b"[[T]]",b" [T]",b"[T",b"[t]",b"[T]x]",b"[\tT\t]"):
    put(hdr+b"\na=5\n"); print('section',hdr,gs(b"T",b"a"))
# keys before section
put(b"a=5\n[T]\nb=1\n"); print('nameless',gs(b"",b"a"),gs(None,b"a") if False else '')
# int formats
for t in (b"0x10",b"0X10",b"0o17",b"0b101",b"-5",b"+5",b"--5",b" -5",b"- 5",b"\xa05",b"5abc",b"4294967296",b"-2147483649",b"0x",b"0xFFFFFFFFF", b"1.9", b"0010"):
    put(b"[T]\na="+t+b"\n"); print('int',t,gi(b"T",b"a"))
# empty / no '='
for body in (b"a=\n",b"a\n",b"a=  \n",b"=5\na=1\n",b"a==2\n"):
    put(b"[T]\n"+body); print('body',body,gs(b"T",b"a"),gi(b"T",b"a"))
# quotes
for v in (b'"abc"',b"'abc'",b'"abc',b'""',b'"',b"' x '",b'"a"b"',b' "  s  " '):
    put(b"[T]\na="+v+b"\n"); print('quote',v,gs(b"T",b"a"), gs(b"T",b"a",4))
# dup keys / sections
put(b"[T]\na=1\na=2\n[T]\nb=3\n"); print('dup',gs(b"T",b"a"),gs(b"T",b"b"))
# CR handling
put(b"[T]\ra=1\rb=2\r"); print('cr',gs(b"T",b"a"),gs(b"T",b"b"))
put(b"[T]\r\na=1\r\r\nb=2\n"); print('crcr',gs(b"T",b"a"),gs(b"T",b"b"))
put(b"[T]\na=1\x00b\nb=2\n"); print('nul in line',gs(b"T",b"a"),gs(b"T",b"b"))
put(b"\xef\xbb\xbf[T]\na=1\n"); print('bom',gs(b"T",b"a"))
print('---- part 2')
import random
r=random.Random(5)
for L in (20,28,29,30,31,32,33,34,35,36,40,64,100,255,300):
    digs=''.join(r.choice('123456789') for _ in range(L))
    put(b"[T]\na="+digs.encode()+b"\n"); v=gi(b"T",b"a")
    m=[n for n in range(1,L+1) if int(digs[:n])%2**32==v]
    print('len',L,'matches prefix lengths',m[:3])
for t in (b'"5"',b"'7'",b'\x80-5',b'-\x805',b'0x1G',b'0xab',b'0XAB',b'0xAB',b'  0x10',b'0b',b'0o',b'0xg',b'+0x10',b'-0x10'):
    put(b"[T]\na="+t+b"\n"); print('int',t,gi(b"T",b"a"))
# long string values: truncation for each size
put(b"[T]\na="+b"x"*300+b"\n"); print('long', [gs(b"T",b"a",n)[0] for n in (1,2,16,32,256,300)])
# section header with no name, key with spaces inside
for body in (b"[]\na=5\n", b"[ ]\na=5\n"):
    put(body); print('empty section', body, gs(b"",b"a"), gs(b" ",b"a"))
put(b"[T]\na b = 5\n"); print('inner space key', gs(b"T",b"a b"), gs(b"T",b"a  b"))
put(b"[T]\n;a=5\na=6\n"); print('comment then key', gs(b"T",b"a"))
put(b"[T]\n a ; x=5\n"); print('semicolon in key', gs(b"T",b"a ; x"))
put(b";[T]\na=5\n[T]\na=6\n"); print('commented section', gs(b"T",b"a"))
# value containing control chars inside
put(b"[T]\na=1\x012\n"); print('inner ctrl', gs(b"T",b"a"))
# requested names with spaces/case
put(b"[Test]\nKey=5\n"); print('req trims', gs(b" Test ",b" Key "), gs(b"TEST",b"KEY"), gs(b"Test\t",b"Key"))
# default value trailing spaces and leading
put(b"[T]\n"); print('defaults', gs(b"T",b"x",256,b"ab  "), gs(b"T",b"x",256,b"  ab"), gs(b"T",b"x",3,b"abcdef"))
