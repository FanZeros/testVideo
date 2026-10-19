-- 离线视频合成入口：画面与时间轴使用 Lua 5.4，Python 仅提供栅格化及 FFmpeg 管道。
-- 复现命令见 assets/video/production.json 的 reproduction 字段。
local Export = {}
Export.backend = [==[
import os, sys, json, math, argparse, subprocess, functools, wave
from pathlib import Path
sys.path.insert(0, '/home/Maker/video-python')
from lupa.lua54 import LuaRuntime
from PIL import Image, ImageDraw, ImageFont
import numpy as np

ROOT = Path(os.environ.get('PUBLISHING_PROJECT_ROOT', Path.cwd()))
if not (ROOT/'scripts/film/Timeline.lua').is_file():
    raise SystemExit('请在项目根目录运行，或设置 PUBLISHING_PROJECT_ROOT。')
P = argparse.ArgumentParser()
P.add_argument('--mode', choices=['stills','render','audio','audit'], default='stills')
P.add_argument('--width', type=int, default=1920)
P.add_argument('--fps', type=int, default=30)
P.add_argument('--start', type=float, default=0)
P.add_argument('--end', type=float, default=128)
P.add_argument('--output', default='assets/video/publishing_visual.mp4')
A = P.parse_args()
W, H = A.width, round(A.width * 9 / 16)
S = W / 1920
FONT = str(ROOT/'assets/fonts/NotoSansSC.ttf')

@functools.lru_cache(maxsize=160)
def font(size, weight):
    f = ImageFont.truetype(FONT, max(8, round(size*S)))
    f.set_variation_by_axes([weight])
    return f

@functools.lru_cache(maxsize=1800)
def glyph(string, size, weight, r,g,b):
    f = font(size,weight)
    box = f.getbbox(string)
    width, height = max(1, box[2]-box[0]+8), max(1, box[3]-box[1]+8)
    out = Image.new('RGBA', (width, height))
    ImageDraw.Draw(out).text((4-box[0],4-box[1]),string,font=f,fill=(r,g,b,255))
    return out, f.getlength(string)

@functools.lru_cache(maxsize=40)
def picture(path, w, h):
    im = Image.open(ROOT/'assets'/path).convert('RGB')
    im.thumbnail((w,h),Image.Resampling.LANCZOS)
    return im

@functools.lru_cache(maxsize=2)
def backdrop(gold):
    y,x=np.mgrid[0:H,0:W]
    x=x/W; y=y/H
    a=np.exp(-(((x-.77)/.40)**2+((y-.45)/.63)**2)*2.0)
    b=np.exp(-(((x-.05)/.60)**2+((y-.98)/.8)**2)*1.8)
    rgb=np.zeros((H,W,3),dtype=np.float32)
    rgb[:]=[7,15,23]
    col=[30,23,10] if gold else [5,28,27]
    for i in range(3): rgb[:,:,i]+=a*col[i]+b*[4,7,17][i]
    # 极轻的固定抖动可减轻深色渐变的编码色带。
    rng=np.random.default_rng(42)
    rgb+=rng.uniform(-.65,.65,(H,W,1))
    return Image.fromarray(np.uint8(np.clip(rgb,0,255)),'RGB')

class Canvas:
    def __init__(self):
        self.im=backdrop(False).copy()
        self.d=ImageDraw.Draw(self.im,'RGBA')
        self.overflows=[]
    def background(self,t,gold):
        self.im=backdrop(bool(gold)).copy()
        self.d=ImageDraw.Draw(self.im,'RGBA')
    def rect(self,x,y,w,h,r,g,b,a,rad):
        if w<=0 or h<=0 or a<=0:return
        self.d.rounded_rectangle((round(x*S),round(y*S),round((x+w)*S),round((y+h)*S)),radius=max(0,round(rad*S)),fill=(r,g,b,round(max(0,min(1,a))*255)))
    def outline(self,x,y,w,h,r,g,b,a,rad,lw):
        if a<=0:return
        self.d.rounded_rectangle((round(x*S),round(y*S),round((x+w)*S),round((y+h)*S)),radius=max(0,round(rad*S)),outline=(r,g,b,round(max(0,min(1,a))*255)),width=max(1,round(lw*S)))
    def line(self,x1,y1,x2,y2,r,g,b,a,lw):
        if a<=0:return
        self.d.line((round(x1*S),round(y1*S),round(x2*S),round(y2*S)),fill=(r,g,b,round(max(0,min(1,a))*255)),width=max(1,round(lw*S)))
    def circle(self,x,y,rad,r,g,b,a,lw):
        if a<=0:return
        box=(round((x-rad)*S),round((y-rad)*S),round((x+rad)*S),round((y+rad)*S))
        c=(r,g,b,round(max(0,min(1,a))*255))
        self.d.ellipse(box,fill=c if lw==0 else None,outline=c if lw else None,width=max(1,round(lw*S)))
    def path(self,pts,r,g,b,a,lw):
        points=[(round(pts[i][1]*S),round(pts[i][2]*S)) for i in range(1,len(pts)+1)]
        self.d.line(points,fill=(r,g,b,round(max(0,min(1,a))*255)),width=max(1,round(lw*S)),joint='curve')
    def text(self,string,x,y,size,r,g,b,a,weight,align,maxwidth):
        if a<.003:return
        size=round(size)
        tile,length=glyph(string,size,weight,r,g,b)
        if length>maxwidth*S:
            self.overflows.append({'text':string,'requested':size,'width':round(length/S),'max':maxwidth})
            ratio=maxwidth*S/length
            tile=tile.resize((max(1,round(tile.width*ratio)),max(1,round(tile.height*ratio))),Image.Resampling.LANCZOS)
        tx=round(x*S)
        if align=='center':tx-=round(tile.width/2)
        elif align=='right':tx-=tile.width
        if a>=.999:self.im.paste(tile,(tx,round(y*S)),tile)
        else:
            mask=tile.getchannel('A').point(lambda v:round(v*max(0,min(1,a))))
            self.im.paste(tile,(tx,round(y*S)),mask)
    def image(self,path,x,y,w,h,a):
        if a<.003:return
        im=picture(path,round(w*S),round(h*S))
        px=round(x*S+(w*S-im.width)/2); py=round(y*S+(h*S-im.height)/2)
        if a>.999:self.im.paste(im,(px,py))
        else:
            layer=Image.new('RGBA',im.size, (0,0,0,0));layer.paste(im,(0,0));layer.putalpha(round(a*255))
            self.im.paste(layer,(px,py),layer)

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute("package.path="+json.dumps(str(ROOT/'scripts/?.lua')+';'+str(ROOT/'scripts/?/init.lua')+';')+"..package.path")
film=lua.eval("require('film.Timeline')")[0]
motion=lua.eval("require('film.Motion')")[0]
c=Canvas()
d=lua.table_from({k:getattr(c,k) for k in ['background','rect','outline','line','circle','path','text','image']})

def frame(t):
    motion.Render(d,t)
    # 摄影机式慢推与微平移贯穿整段；不是将静帧循环成视频。
    c.im=c.im.transform((W,H),Image.Transform.AFFINE,
        (0.976,0,(0.012+0.0035*math.sin(t*.19))*W,
         0,0.976,(0.012+0.003*math.cos(t*.17))*H),
        resample=Image.Resampling.BICUBIC)
    return c.im

if A.mode=='stills':
    frames=[]
    for i in range(1,len(film.scenes)+1):
        scene=film.scenes[i]
        t=scene.start+min(scene.duration-1,4.5)
        im=frame(t).copy()
        path=ROOT/f'assets/image/film/scene_{i:02d}.jpg'
        im.save(path,quality=93)
        im.thumbnail((480,270),Image.Resampling.LANCZOS)
        tile=Image.new('RGB',(480,302),(7,15,23));tile.paste(im,(0,0))
        ImageDraw.Draw(tile).text((10,277),f'{i:02d} | {scene.id} | {t:.1f}s',font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15),fill=(180,220,216))
        frames.append(tile)
    board=Image.new('RGB',(1920,302*math.ceil(len(frames)/4)),(7,15,23))
    for i,im in enumerate(frames):board.paste(im,((i%4)*480,(i//4)*302))
    board.save(ROOT/'assets/image/film/storyboard.jpg',quality=95)
    (ROOT/'assets/video/layout_audit.json').write_text(json.dumps(c.overflows,ensure_ascii=False,indent=2))
    print('分镜图已输出；文字宽度自动调整：',json.dumps(c.overflows,ensure_ascii=False))
elif A.mode=='render':
    out=ROOT/A.output
    out.parent.mkdir(parents=True,exist_ok=True)
    cmd=['ffmpeg','-y','-loglevel','warning','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(A.fps),'-i','pipe:0','-an','-c:v','libx264','-preset','fast','-crf','18','-pix_fmt','yuv420p','-threads','2','-movflags','+faststart',str(out)]
    proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
    total=round((A.end-A.start)*A.fps)
    for i in range(total):
        t=A.start+i/A.fps
        proc.stdin.write(frame(t).tobytes())
        if i%(A.fps*4)==0:print(f'画面合成 {i}/{total} ({t:.1f}s)',flush=True)
    proc.stdin.close()
    rc=proc.wait()
    if rc:raise SystemExit(rc)
    print('画面完成',str(out),flush=True)
elif A.mode=='audio':
    sr=48000;duration=128
    signal=np.zeros((duration*sr,2),np.float32)
    rng=np.random.default_rng(2026)
    for i in range(2,len(film.scenes)+1):
        scene=film.scenes[i];start=scene.start
        n=int(sr*.50);t=np.arange(n)/sr
        noise=rng.normal(0,1,n)
        smooth=np.convolve(noise,np.ones(18)/18,mode='same')
        env=np.sin(np.pi*np.linspace(0,1,n))**2
        tone=np.sin(2*np.pi*(180*t+1050*t*t))*np.exp(-10*t)
        whoosh=(smooth*.35+tone*.035)*env
        at=int((start-.08)*sr)
        signal[at:at+n,0]+=whoosh*.75;signal[at:at+n,1]+=whoosh
    for start in [25,26.5,28,35,38,46,62,72,74,76,84,94,112,121.3]:
        n=int(sr*.7);t=np.arange(n)/sr
        freq=784 if start<44 else 523.25
        tone=(np.sin(2*np.pi*freq*t)+.4*np.sin(2*np.pi*freq*2*t))*.06*np.exp(-t*8)
        at=int(start*sr);signal[at:at+n,:]+=tone[:,None]
    n=int(sr*1.2);t=np.arange(n)/sr
    impact=np.sin(2*np.pi*(66*t-13*t*t))*.20*np.exp(-5*t)
    at=44*sr;signal[at:at+n,:]+=impact[:,None]
    out=ROOT/'assets/audio/motion_design_sfx.wav'
    with wave.open(str(out),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr)
        f.writeframes((np.clip(signal,-1,1)*32767).astype('<i2').tobytes())
    print('已输出程序化转场与数据音效',out)
elif A.mode=='audit':
    for i in range(1,len(film.scenes)+1):
        s=film.scenes[i]
        for offset in [.45,1,2,s.duration-.5]:frame(s.start+offset)
    errors=list({e['text']:e for e in c.overflows}.values())
    print(json.dumps({'scenes':len(film.scenes),'frames_checked':len(film.scenes)*4,'text_auto_fit':errors},ensure_ascii=False,indent=2))
]==]
return Export
