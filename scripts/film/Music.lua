-- 确定性程序作曲：120 BPM，4/4，69小节，完整匹配138秒影片。
-- 音符、和声、编排均由本文件生成；不读取外部音乐、采样或生成服务。
local Music = {
    bpm = 120,
    duration = 138,
    sampleRate = 48000,
    seed = 20261019,
    output = "assets/audio/music/publishing_theme_procedural.wav",
}

function Music.BuildScore()
    local events = {}
    local function note(kind, at, midi, duration, gain, pan)
        events[#events + 1] = {
            kind = kind, at = at, midi = midi, duration = duration,
            gain = gain, pan = pan or 0,
        }
    end
    ---@type { root: integer, notes: integer[] }[]
    local chords = {
        { root = 35, notes = {59, 62, 66, 69, 73} }, -- Bm9
        { root = 31, notes = {55, 59, 62, 66, 69} }, -- Gmaj9
        { root = 38, notes = {57, 62, 66, 69, 76} }, -- Dadd9
        { root = 33, notes = {57, 61, 64, 66, 71} }, -- A6/9
    }
    ---@type number[][][]
    local motifs = {
        { {0,78,0.70},{1.5,76,0.45},{2.5,74,0.65},{4,73,0.75},{6,74,0.80} },
        { {0,78,0.65},{1.5,81,0.65},{3,78,0.55},{4.5,76,0.75},{6.5,74,0.60} },
        { {0,78,0.70},{2,76,0.55},{3.5,74,0.60},{5,69,0.55},{6.5,74,0.60} },
        { {0,76,0.75},{2,73,0.55},{3.5,71,0.55},{5,73,0.55},{6.5,76,0.75} },
    }
    local sections = {
        { start = 0, finish = 8, name = "稀疏引入", energy = 0.20 },
        { start = 8, finish = 24, name = "建立律动", energy = 0.43 },
        { start = 24, finish = 44, name = "数据推进", energy = 0.65 },
        { start = 44, finish = 54, name = "榜单高光", energy = 0.90 },
        { start = 54, finish = 70, name = "方法展开", energy = 0.62 },
        { start = 70, finish = 94, name = "节奏递进", energy = 0.74 },
        { start = 94, finish = 112, name = "口碑与价值", energy = 0.50 },
        { start = 112, finish = 130, name = "合作再现", energy = 0.76 },
        { start = 130, finish = 138, name = "主题收束", energy = 0.40 },
    }
    local function energy(at)
        for _, section in ipairs(sections) do
            if at >= section.start and at < section.finish then return section.energy end
        end
        return 0.2
    end
    for bar = 0, math.ceil(Music.duration/2)-1 do
        local at = bar * 2
        local chord = assert(chords[(bar // 2) % 4 + 1])
        local e = energy(at)
        -- 柔和长音保持和声；每两个小节换和弦，避免过度密集。
        if bar % 2 == 0 then
            for i, pitch in ipairs(chord.notes) do
                note("pad", at, pitch, 4.2, 0.032 + e * 0.019, (i - 3) * 0.24)
                note("piano", at + (i - 1) * 0.027, pitch, 2.8, 0.08 + e * 0.025, (i - 3) * 0.15)
            end
        end
        if bar >= 4 then
            ---@type integer[]
            local pattern = {1, 3, 5, 3, 2, 4, 5, 3}
            for step = 0, 7 do
                local pitchIndex = assert(pattern[step + 1])
                local pitch = assert(chord.notes[pitchIndex]) + 12
                local velocity = (step % 2 == 0 and 0.047 or 0.030) * (0.65 + e)
                note("pluck", at + step * 0.25, pitch, 0.73, velocity, math.sin(step * 1.6 + bar) * 0.35)
            end
            for beat = 0, 3 do
                if beat == 0 or beat == 2 or e >= 0.7 then
                    note("bass", at + beat * 0.5, chord.root + (beat == 3 and 12 or 0), 0.42, 0.13 + 0.04 * e, 0)
                    note("kick", at + beat * 0.5, 0, 0.42, 0.24 + 0.08 * e, 0)
                end
                if bar >= 8 and (beat == 1 or beat == 3) then
                    note("snare", at + beat * 0.5, 0, 0.24, 0.11 + e * 0.055, 0.06)
                end
            end
            if bar >= 8 then
                for step = 0, 7 do
                    local gain = step % 2 == 0 and 0.022 or 0.041
                    note("hat", at + step * 0.25 + (step % 2) * 0.008, 0, 0.08, gain * (0.6 + e), step % 2 == 0 and -0.28 or 0.28)
                end
            end
            if e >= 0.7 and bar % 4 == 3 then
                note("hat", at + 1.75, 0, 0.30, 0.040, 0.35)
                note("tom", at + 1.5, 43, 0.35, 0.08, -0.25)
                note("tom", at + 1.75, 40, 0.35, 0.07, 0.25)
            end
        end
    end
    -- 四小节主题，按和声周期展开；副段改变八度与力度，不引用现成歌曲。
    for phrase = 0, math.floor((Music.duration-8)/8) do
        local at = phrase * 8
        local motif = assert(motifs[phrase % 4 + 1])
        local e = energy(at)
        for _, v in ipairs(motif) do
            if phrase ~= 1 and phrase ~= 7 then
                local pitch = v[2] - (at < 16 and 12 or 0)
                note("piano", at + v[1], pitch, v[3] + 1.9, 0.10 + e * 0.075, -0.10)
                if e >= 0.72 then note("bell", at + v[1], pitch + 12, 2.0, 0.025, 0.24) end
            end
        end
    end
    -- 44秒与“热门榜第二”切场同步；结尾落在D大调，不硬截循环。
    for _, at in ipairs({4,17,24,44,60,68,84,94,102,120,130}) do
        note("swell", at - 0.85, 74, 1.9, at == 44 and 0.12 or 0.065, 0)
        note("bell", at, 86, 3.0, at == 44 and 0.095 or 0.055, 0.18)
    end
    for i, at in ipairs({68.75,70.95,73.15,75.35,77.55,80.0}) do
        note("bell", at, i==6 and 86 or 81, 1.2, 0.045, i%2==0 and 0.2 or -0.2)
        note("hat", at, 0, 0.12, 0.035, 0.1)
    end
    for i, pitch in ipairs({50,57,62,66,69,74}) do
        note("pad", 130, pitch, 6.2, 0.038, (i - 3.5) * 0.17)
        note("piano", 130 + i * 0.045, pitch, 5.5, 0.11, (i - 3.5) * 0.12)
    end
    for i, pitch in ipairs({78,76,74}) do note("piano", 131 + (i - 1) * 0.75, pitch, 3.8, 0.13, -0.1) end
    return { events = events, sections = sections, bpm = Music.bpm, duration = Music.duration, sampleRate = Music.sampleRate, seed = Music.seed, output = Music.output }
end

Music.backend = [==[
import sys, os, math, json, wave, hashlib
from pathlib import Path
import numpy as np
from lupa.lua54 import LuaRuntime
ROOT=Path(os.environ.get('PUBLISHING_PROJECT_ROOT',Path.cwd()))
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('package.path='+json.dumps(str(ROOT/'scripts/?.lua')+';')+'..package.path')
music=lua.eval("require('film.Music')")[0]
score=music.BuildScore()
sr=int(score.sampleRate); duration=float(score.duration); count=round(sr*duration)
rng=np.random.default_rng(int(score.seed))
dry=np.zeros((count,2),dtype=np.float32)
wet=np.zeros_like(dry)
beat=60/float(score.bpm)

def smoothstep(x):
    x=np.clip(x,0,1); return x*x*(3-2*x)

def synth(kind,midi,duration):
    n=round((duration+.1)*sr); t=np.arange(n,dtype=np.float64)/sr
    freq=440*2**((midi-69)/12)
    attack=smoothstep(t/.006); release=smoothstep((duration+.1-t)/.11)
    phase=2*np.pi*freq*t
    if kind=='pad':
        tone=np.zeros(n)
        for h,amp in [(1,1),(2,.17),(3,.055),(4,.018)]:
            for detune in [-.0016,.0016]:
                tone+=amp*.5*np.sin(phase*h*(1+detune)+.09*np.sin(t*.8))
        env=smoothstep(t/.75)*smoothstep((duration+.1-t)/1.1)
        return tone*env
    if kind=='piano':
        tone=np.zeros(n)
        for h,amp,decay in [(1,1,.75),(2,.42,1.5),(3,.16,2.6),(4,.065,3.4),(6,.022,5.0)]:
            tone+=amp*np.sin(phase*h*(1+.00008*h*h))*np.exp(-t*decay)
        return tone*attack*release*.66
    if kind=='pluck':
        fm=.8*np.exp(-t*10)*np.sin(phase*2)
        return (np.sin(phase+fm)+.14*np.sin(phase*2))*np.exp(-t*6)*attack*release
    if kind=='bell':
        tone=np.sin(phase+1.2*np.exp(-t*2.8)*np.sin(phase*2))
        return tone*np.exp(-t*1.8)*attack*release
    if kind=='bass':
        return (np.sin(phase)+.18*np.sin(phase*2)+.06*np.sin(phase*3))*np.exp(-t*2.1)*smoothstep(t/.014)*release
    if kind=='kick':
        phasekick=2*np.pi*(49*t+(150-49)*.028*(1-np.exp(-t/.028)))
        body=np.sin(phasekick)*np.exp(-t*11)
        click=rng.normal(0,1,n)*np.exp(-t*260)*.12
        return (body+click)*smoothstep(t/.001)*release
    if kind=='snare':
        noise=rng.normal(0,1,n)
        high=noise-np.convolve(noise,np.ones(16)/16,mode='same')
        return (high*.60*np.exp(-t*26)+np.sin(2*np.pi*185*t)*.50*np.exp(-t*35))*attack*release
    if kind=='hat':
        noise=rng.normal(0,1,n)
        high=noise-np.convolve(noise,np.ones(5)/5,mode='same')
        return high*np.exp(-t*(45 if duration<.1 else 16))*smoothstep(t/.001)*release
    if kind=='tom':
        return np.sin(phase-6*np.exp(-t*20))*np.exp(-t*13)*attack*release
    if kind=='swell':
        noise=rng.normal(0,1,n)
        airy=np.convolve(noise,np.ones(24)/24,mode='same')
        env=np.sin(np.pi*np.clip(t/duration,0,1))**2
        return (airy*.7+np.sin(phase)*.08)*env*release
    raise ValueError('未知乐器 '+kind)

for i in range(1,len(score.events)+1):
    e=score.events[i]
    kind=e.kind; start=round(e.at*sr)
    mono=synth(kind,e.midi,e.duration)*e.gain
    if start<0:mono=mono[-start:];start=0
    n=min(len(mono),count-start)
    if n<=0:continue
    pan=max(-1,min(1,e.pan)); gains=[math.cos((pan+1)*math.pi/4),math.sin((pan+1)*math.pi/4)]
    target=dry if kind in ['kick','snare','hat','bass','tom'] else wet
    target[start:start+n,0]+=mono[:n]*gains[0]
    target[start:start+n,1]+=mono[:n]*gains[1]
    if i%400==0:print(f'合成音符 {i}/{len(score.events)}',flush=True)

# 和声总线做轻微节拍侧链；立体声交叉延迟和多抽头混响全部由代码生成。
time=np.arange(count,dtype=np.float64)/sr
pump=1-.14*np.exp(-((time%beat)/.065))
wet*=pump[:,None]
ambience=np.zeros_like(wet)
for delay,gain,cross in [(.1875,.15,True),(.375,.12,True),(.521,.10,False),(.709,.08,True),(1.013,.055,False),(1.337,.035,True)]:
    shift=round(delay*sr)
    ambience[shift:]+=wet[:-shift,::-1 if cross else 1]*gain
signal=dry+wet+ambience
signal-=signal.mean(axis=0)
fade=smoothstep(time/1.4)*smoothstep((duration-time)/3.0)
signal*=fade[:,None]
raw_peak=float(np.max(np.abs(signal)))
signal=np.tanh(signal*1.18)
peak=float(np.max(np.abs(signal)))
signal*=.88/max(peak,1e-9)
assert np.all(np.isfinite(signal))
# 固定种子TPDF抖动；同一源码和依赖版本可复现PCM。
dither=(rng.random(signal.shape,dtype=np.float32)-rng.random(signal.shape,dtype=np.float32))/65536
pcm=np.clip(np.rint((signal+dither)*32767),-32768,32767).astype('<i2')
out=ROOT/score.output
out.parent.mkdir(parents=True,exist_ok=True)
with wave.open(str(out),'wb') as f:
    f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes(pcm.tobytes())
sections=[]
for i in range(1,len(score.sections)+1):
    s=score.sections[i];sections.append({k:s[k] for k in ['start','finish','name','energy']})
report={'generation':'确定性程序作曲与数字合成；无AI音乐、无外部采样','bpm':score.bpm,'meter':'4/4','bars':round(duration/2),'duration':duration,'sample_rate':sr,'channels':2,'notes':len(score.events),'seed':score.seed,'instruments':['加法合成柔和铺底','谐波衰减电钢琴','FM拨弦','FM钟音','正弦贝斯','合成底鼓','噪声军鼓','高通噪声踩镲','正弦通鼓','滤波噪声上升音'],'sections':sections,'peak_dbfs':20*math.log10(float(np.max(np.abs(pcm.astype(np.float64)/32768)))),'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'file':str(out.relative_to(ROOT))}
(ROOT/'assets/audio/music/procedural_score.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)
]==]
return Music
