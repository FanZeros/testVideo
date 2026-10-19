-- 第二轮导演修订：困境分层、五步发行，以及贯穿全片的节拍级信息推进。
local Revision = {}
local C = { white={239,248,247}, muted={145,172,180}, mint={69,230,194}, gold={245,203,126}, red={245,129,135}, panel={15,30,41}, border={40,67,78}, ink={8,16,24} }
local function clamp(v) return math.max(0,math.min(1,v)) end
local function ease(v) local p=clamp(v); return 1-(1-p)^3 end
local function rr(d,x,y,w,h,c,a,r) d.rect(x,y,w,h,c[1],c[2],c[3],a or 1,r or 0) end
local function box(d,x,y,w,h,c,a,r,lw) d.outline(x,y,w,h,c[1],c[2],c[3],a or 1,r or 0,lw or 1) end
local function line(d,x,y,x2,y2,c,a,lw) d.line(x,y,x2,y2,c[1],c[2],c[3],a or 1,lw or 2) end
local function dot(d,x,y,r,c,a,lw) d.circle(x,y,r,c[1],c[2],c[3],a or 1,lw or 0) end
local function txt(d,s,x,y,size,c,a,weight,align,w) d.text(s,x,y,size,c[1],c[2],c[3],a or 1,weight or 600,align or "left",w or 1700) end
local function enter(d,s,x,y,size,c,t,delay,align,w)
    local p=ease((t-(delay or 0))/.45)
    txt(d,s,x+50*(1-p),y+18*(1-p),size,c,p,700,align,w)
end
local function arrow(d,x,y,to,c,a)
    line(d,x,y,to,y,c,a,3); line(d,to-10,y-8,to,y,c,a,3);line(d,to-10,y+8,to,y,c,a,3)
end
local function panel(d,x,y,w,h,a,c)
    rr(d,x,y,w,h,C.panel,a,20);box(d,x,y,w,h,c or C.border,a,20,1)
end

function Revision.Problem(d,s,t)
    enter(d,"上架之后，真正的困境是——",112,177,57,C.white,t,.12)
    local phase=math.min(3,math.floor(math.max(0,t-1.1)/3.4))
    local p=ease((t-.5)/1.4)
    txt(d,tostring(math.floor(200*p)).."+",112,289,149,C.white,1,850,"left",530)
    txt(d,"款游戏，挤在同一张列表",119,472,34,C.muted,1,550)
    local q=ease((t-1.6)/.9)
    txt(d,"只有前",118,568,38,C.white,q,600)
    txt(d,tostring(math.floor(20*q)),310,523+30*(1-q),150,C.mint,q,850,"left",300)
    txt(d,"个",531,617,39,C.white,q,650)
    enter(d,"达到三位数流量",119,733,54,C.mint,t,2.1,"left",700)
    local labels={"大量新游同时争夺注意力","流量集中在列表头部","更多作品，很难获得第一眼","不只上架，更要争取被发现"}
    local x0,y0=943,296
    txt(d,"头部 20 个",950,226,29,C.mint,ease((t-1.5)/.5),650)
    txt(d,"其余游戏",1768,226,25,C.muted,1,500,"right")
    -- 220枚卡片只表示200多款的数量关系，不捏造逐款实际流量。
    for i=0,219 do
        local col=i%20; local row=math.floor(i/20)
        local p1=ease((t-.3-i*.003)/.5)
        local x=x0+col*42;local y=y0+row*43+35*(1-p1)
        local head=i<20
        local highlighted=head and t>1.6
        local a=p1*(highlighted and 1 or (t>2.2 and .23 or .65))
        local c=highlighted and C.mint or C.muted
        rr(d,x,y,31,30,c,a,5)
        if highlighted then
            local beat=math.exp(-((t*2+col*.035)%1)*6)
            box(d,x-3-beat*3,y-3-beat*3,37+beat*6,36+beat*6,C.mint,.15+beat*.25,7,1)
        end
    end
    line(d,935,341,1791,341,C.mint,ease((t-1.7)/.6),2)
    panel(d,941,824,854,78,1)
    txt(d,labels[phase+1],1368,846,28,phase==3 and C.mint or C.white,1,650,"center",806)
    -- 下方扫描游标与信息阶段一起移动。
    for i=0,3 do rr(d,948+i*211,914,190,3,i==phase and C.mint or C.border,1,1) end
    if t>7 then
        local a=ease((t-7)/.7)
        line(d,927,354,927,770,C.red,a*.6,2)
        txt(d,"你的游戏，会留在哪一层？",118,865,32,C.gold,a,650,"left",720)
    end
end

local steps={
    {name="预约期",short="预约期",goal="积累第一批意向玩家",action="建立曝光入口，沉淀预约",metric="关注预约量与玩家来源",kind="reserve"},
    {name="玩家预约反馈",short="玩家预约反馈",goal="先听见玩家，再做决策",action="收集期待与疑问，调整沟通",metric="关注真实需求与预约反馈",kind="feedback"},
    {name="限量测试",short="限量测试",goal="小范围验证，及时修正",action="验证核心体验，收集问题",metric="关注留存、体验与缺陷",kind="limited"},
    {name="不限量测试",short="不限量测试",goal="扩大验证，积累启动量",action="承接更多玩家，复盘数据",metric="关注规模化反馈与表现",kind="open"},
    {name="首发",short="首发",goal="集中资源，正式启动",action="整合曝光与福利流量",metric="关注首日表现与后续承接",kind="launch"},
}
Revision.steps=steps

-- 多期预约测试 vs 直接上线：折线仅表达节奏差异，不标注真实数值。
local chart={x0=232,x1=1200,y0=748,y1=410}
local function chartY(value) return chart.y0-value/100*(chart.y0-chart.y1) end
local function chartX(p) return chart.x0+p*(chart.x1-chart.x0) end
local function curveValue(keys,p)
    if p<=keys[1][1] then return keys[1][2] end
    for i=2,#keys do
        local a,b=keys[i-1],keys[i]
        if p<=b[1] then
            local f=clamp((p-a[1])/math.max(1e-6,b[1]-a[1]))
            local s=f*f*(3-2*f)
            return a[2]+(b[2]-a[2])*s
        end
    end
    return keys[#keys][2]
end
local function sampleCurve(keys,count)
    local pts={}
    for i=0,count do
        local p=i/count
        pts[#pts+1]={chartX(p),chartY(curveValue(keys,p))}
    end
    return pts
end
local function drawCurve(d,pts,progress,c,a,lw)
    local q=clamp(progress)*(#pts-1)
    local n=math.floor(q)
    local out={}
    for i=1,math.min(n+1,#pts) do out[#out+1]=pts[i] end
    if n<#pts-1 then
        local f=q-n;local p1,p2=pts[n+1],pts[n+2]
        out[#out+1]={p1[1]+(p2[1]-p1[1])*f,p1[2]+(p2[2]-p1[2])*f}
    end
    if #out>=2 then d.path(out,c[1],c[2],c[3],a or 1,lw or 3) end
    return out
end

local reserves={{0,10},{.28,26},{.44,38},{.62,54},{.66,78},{.72,86},{1,94}}
local direct={{0,7},{.62,8},{.66,24},{.76,18},{1,13}}
local ourPoints=sampleCurve(reserves,120)
local directPoints=sampleCurve(direct,120)

function Revision.Comparison(d,s,t)
    enter(d,s.title,112,174,58,C.white,t,.05)
    enter(d,s.subtitle,116,262,30,C.muted,t,.2)
    local cardIn=ease((t-.3)/.7)
    panel(d,112,334,1158,506,cardIn,C.mint)
    txt(d,"玩家关注与下载趋势",146,352,21,C.muted,cardIn,500)
    txt(d,"相对表现 · 示意",1236,352,19,C.muted,cardIn,450,"right",180)
    local axisIn=ease((t-.55)/.7)
    -- 阶段背景与网格
    local phases={{0,.28,"预约期"},{.28,.44,"限量测试"},{.44,.62,"不限量测试"},{.62,.72,"首发日"},{.72,1,"首发后"}}
    for i,v in ipairs(phases) do
        local x=chartX(v[1]);local w=chartX(v[2])-x
        if i==1 then rr(d,x,chart.y1,w,chart.y0-chart.y1,C.mint,.045*axisIn,0) end
        if i==4 then rr(d,x,chart.y1,w,chart.y0-chart.y1,C.gold,.06*axisIn,0) end
        if i>1 then line(d,x,chart.y1,x,chart.y0,C.border,.5*axisIn,1) end
    end
    for i=0,4 do
        local y=chartY(i*25)
        line(d,chart.x0,y,chart.x1,y,C.border,(i==0 and .75 or .28)*axisIn,1)
    end
    line(d,chart.x0,chart.y0,chart.x1,chart.y0,C.border,.9*axisIn,2)
    line(d,chart.x0,chart.y1,chart.x0,chart.y0,C.border,.9*axisIn,2)
    txt(d,"高",chart.x0-26,chart.y1-10,18,C.muted,axisIn,450,"right",40)
    txt(d,"低",chart.x0-26,chart.y0-14,18,C.muted,axisIn,450,"right",40)
    for i,v in ipairs(phases) do
        local p=ease((t-.8-i*.08)/.45)
        txt(d,v[3],chartX((v[1]+v[2])/2),chart.y0+26,19,i==4 and C.gold or C.muted,p,550,"center",150)
    end
    local launchX=chartX(.66)
    local launchIn=ease((t-3.0)/.5)
    if launchIn>0 then
        for i=0,17 do
            local y=chart.y1+i*19
            line(d,launchX,y,launchX,y+9,C.gold,.55*launchIn,2)
        end
    end
    -- 我方曲线：预约蓄水、测试验证、首发抬高
    local ourP=ease((t-1.0)/3.4)
    if ourP>0 then
        drawCurve(d,ourPoints,ourP,C.mint,.12,12)
        local out=drawCurve(d,ourPoints,ourP,C.mint,1,4)
        for i,v in ipairs(reserves) do
            if ourP>=v[1] then
                local a=ease((ourP-v[1])/.12)
                dot(d,chartX(v[1]),chartY(v[2]),5,C.mint,a)
            end
        end
        if #out>=2 then
            local last=out[#out]
            local score=math.exp(-((t*2)%1)*6)
            dot(d,last[1],last[2],10+score*9,C.mint,.2+score*.25,2)
            dot(d,last[1],last[2],4,C.mint,1)
        end
    end
    -- 直接上线：上线前几乎无蓄水，首发峰值低且回落更快
    local directP=ease((t-1.7)/2.3)
    if directP>0 then
        drawCurve(d,directPoints,directP,C.muted,.9,3)
        if directP>=1 then
            local last=directPoints[#directPoints]
            dot(d,last[1],last[2],5,C.muted,.9)
        end
    end
    -- 右侧图例与三条结论
    local rightIn=ease((t-2.6)/.6)
    panel(d,1295,334,513,506,rightIn)
    dot(d,1326,374,6,C.mint,rightIn)
    txt(d,"多期预约测试",1352,358,25,C.white,rightIn,650)
    txt(d,"我方做法",1352,388,19,C.muted,rightIn,450)
    dot(d,1326,436,6,C.muted,rightIn)
    txt(d,"直接上线",1352,420,25,C.white,rightIn,650)
    txt(d,"普通开发者",1352,450,19,C.muted,rightIn,450)
    line(d,1326,478,1777,478,C.border,rightIn*.8,1)
    local notes={
        {"01","预约期蓄水","提前积累第一批意向玩家"},
        {"02","测试期验证","用真实反馈修正体验与留存"},
        {"03","首发日集中","把启动量推到更高起点"},
    }
    for i,v in ipairs(notes) do
        local p=ease((t-3.3-(i-1)*.42)/.5)
        if p>0 then
            rr(d,1326,512+(i-1)*99,6,58,C.mint,p*.9,3)
            txt(d,v[1],1350,505+(i-1)*99,19,C.mint,p,700)
            txt(d,v[2],1388,501+(i-1)*99,25,C.white,p,650)
            txt(d,v[3],1350,539+(i-1)*99,20,C.muted,p,450,"left",410)
        end
    end
    local tail=math.exp(-((t*2)%1)*6)
    dot(d,1770,798,5+tail*3,C.mint,(.4+tail*.3)*rightIn,2)
    txt(d,"曲线仅表达节奏差异",1770,760,17,C.muted,.75*rightIn,450,"right",180)
    local take=ease((t-5.4)/.7)
    txt(d,"预约不是等待，而是把首发日的起点抬高。",960,884,30,C.gold,take,650,"center",1600)
end

local function stageVisual(d,kind,t,localTime)
    local cx,cy=1441,650
    for i=1,3 do
        local r=80+i*55+(localTime*34)%55
        dot(d,cx,cy,r,C.mint,.11*(1-i*.12),1)
    end
    if kind=="feedback" then
        for i=1,4 do
            local p=ease((localTime-(i-1)*.22)/.45)
            local x=1170+(i%2)*230;local y=470+math.floor((i-1)/2)*142
            panel(d,x+30*(1-p),y,206,94,p,C.mint)
            line(d,x+24,y+27,x+148,y+27,C.white,p*.8,3)
            line(d,x+24,y+48,x+179,y+48,C.muted,p*.7,2)
            line(d,x+24,y+68,x+97,y+68,C.mint,p,2)
        end
        txt(d,"反馈 → 调整",cx,834,29,C.mint,1,650,"center")
    elseif kind=="launch" then
        local pts={}
        for i=0,45 do
            local p=i/45
            pts[#pts+1]={1170+p*520,785-p*p*330+math.sin(p*10)*12}
        end
        local n=math.max(2,math.floor(2+44*ease(localTime/1.4)))
        local out={};for i=1,n do out[#out+1]=pts[i] end
        d.path(out,69,230,194,1,5)
        local last=out[#out];dot(d,last[1],last[2],10,C.gold,1)
        for i=1,7 do
            local a=localTime*1.5+i*.9
            dot(d,1690+math.cos(a)*40,455+math.sin(a)*40,3,C.gold,.6)
        end
        txt(d,"集中启动",cx,834,29,C.mint,1,650,"center")
    else
        local n=kind=="limited" and 12 or (kind=="open" and 36 or 20)
        local visible=math.floor(n*ease((localTime+.1)/1.35))
        for i=1,n do
            local col=(i-1)%6;local row=math.floor((i-1)/6)
            local x=1212+col*79;local y=467+row*58
            local on=i<=visible
            dot(d,x,y,13,C.mint,on and .95 or .15)
            line(d,x-19,y+23,x+19,y+23,C.mint,on and .6 or .1,5)
        end
        txt(d,kind=="limited" and "小范围验证" or (kind=="open" and "扩大验证范围" or "预约持续积累"),cx,834,29,C.mint,1,650,"center")
    end
end

function Revision.Stages(d,s,t)
    enter(d,s.title,112,174,62,C.white,t,.05)
    enter(d,"五个环节，逐步验证，而不是一次押注。",116,266,31,C.muted,t,.22)
    local active=math.min(5,math.floor(math.max(0,t-.75)/2.2)+1)
    local summary=t>=12.0
    -- 每个阶段切换的瞬间，游标必须恰好抵达对应节点。
    local progress=clamp((t-.75)/8.8)
    line(d,254,401,1666,401,C.border,1,3)
    line(d,254,401,254+1412*progress,401,C.mint,1,4)
    local cursor=254+1412*progress
    dot(d,cursor,401,10,C.mint,.9)
    for i,v in ipairs(steps) do
        local x=254+(i-1)*353
        local on=i<=active
        local col=on and C.mint or C.muted
        dot(d,x,401,27,C.panel,1)
        dot(d,x,401,27,col,on and 1 or .35,2)
        txt(d,string.format("%02d",i),x,384,22,col,1,650,"center")
        txt(d,v.short,x,329,i==2 and 25 or 30,on and C.white or C.muted,1,650,"center",320)
        if i==active and not summary then
            local r=31+(t*46)%28
            dot(d,x,401,r,C.mint,(1-(r-31)/28)*.4,2)
        end
    end
    if not summary then
        local v=steps[active]
        local localTime=math.max(0,t-.75-(active-1)*2.2)
        local p=ease(localTime/.4)
        panel(d,112+65*(1-p),474,950,420,p,C.mint)
        txt(d,string.format("0%d / 05",active),151,507,25,C.mint,p,650)
        enter(d,v.name,151,557,66,C.white,localTime,0,"left",853)
        enter(d,v.goal,154,656,36,C.mint,localTime,.06,"left",848)
        enter(d,v.action,154,731,29,C.white,localTime,.12,"left",848)
        enter(d,v.metric,154,810,25,C.muted,localTime,.18,"left",848)
        stageVisual(d,v.kind,t,localTime)
    else
        local p=.25+.75*ease((t-12)/.5)
        panel(d,112,474,1696,420,.45*(1-p),C.mint)
        for i,v in ipairs(steps) do
            local x=112+(i-1)*346
            panel(d,x,503+60*(1-p),312,273,p,i==5 and C.gold or C.mint)
            txt(d,string.format("%02d",i),x+27,528+60*(1-p),49,C.mint,p,750)
            txt(d,v.name,x+27,607+60*(1-p),i==2 and 29 or 33,C.white,p,700,"left",266)
            local desc={"意向积累","收集与调整","小范围验证","扩大验证","集中启动"}
            txt(d,desc[i],x+27,694+60*(1-p),24,C.muted,p,500)
            if i<5 then arrow(d,x+320,638,x+337,C.mint,p) end
        end
        enter(d,"预约不是结束，反馈才是下一步的起点。",960,830,34,C.gold,t,12.8,"center",1600)
    end
end

-- 所有章节保持实质信息变化：热点按节拍移交，目标、路径、节点持续动起来。
function Revision.Accents(d,id,t,duration)
    local beat=math.exp(-((t*2)%1)*7)
    if id=="opening" then
        local grow=ease(t/2.5)
        arrow(d,1210,823,1210+540*grow,C.mint,.45)
        txt(d,"从作品 → 到玩家",1480,867,27,C.mint,.85,600,"center")
    elseif id=="pivot" or id=="methods" then
        local idx=math.min(3,math.floor(t/.9)%4)
        local x=(id=="pivot" and 115 or 112)+idx*(id=="pivot" and 435 or 441)
        local y=id=="pivot" and 575 or 418
        box(d,x-3,y-3,id=="pivot" and 396 or 381,id=="pivot" and 228 or 351,C.mint,.25+beat*.5,25,2)
    elseif id=="credentials" then
        local i=math.min(2,math.floor(math.max(0,t-3)/1.9))
        local x=112+i*580
        line(d,x+39,761,x+39+456*ease(((t-3)%1.9)/1.2),761,i==2 and C.gold or C.mint,.85,4)
        if t>5.8 then txt(d,"发行经验 → 真实积累",960,872,26,C.mint,ease((t-5.8)/.5),600,"center") end
    elseif id=="evidence" then
        if t>2 then
            local x=158+((t-2)*135)%972
            dot(d,x,825,5,C.mint,.8)
        end
    elseif id=="ranking" then
        local p=clamp((t-2)/5)
        local x=995+695*p
        local y=775-560*p
        dot(d,x,y,6,C.gold,.9)
        dot(d,1690,218,16+beat*19,C.gold,.2+beat*.3,2)
        if t>5 then txt(d,"不是偶然看见，是一步步走到前面",1255,870,24,C.gold,ease((t-5)/.5),550,"center",1030) end
    elseif id=="exposure" then
        local idx=math.floor(t/1.4)%4
        local x=874+(idx%2)*479;local y=377+math.floor(idx/2)*252
        box(d,x-4,y-4,452,236,C.mint,.35+beat*.4,25,2)
        local cursor=(t*.7)%1
        dot(d,850,405+cursor*419,5,C.mint,.9)
    elseif id=="rep" then
        for i=1,7 do
            local p=(t*.45+i*.13)%1
            dot(d,785+150*p,447+(i%3)*161,3,C.mint,(1-p)*.75)
        end
    elseif id=="reputation" then
        local idx=math.floor(t/1.5)%4
        local x=885+(idx%2)*474;local y=380+math.floor(idx/2)*245
        box(d,x-3,y-3,448,226,C.mint,.25+beat*.4,23,2)
        dot(d,479,581,170+38*((t*.4)%1),C.mint,(1-(t*.4)%1)*.23,1)
    elseif id=="outcome" then
        local p=clamp((t-2)/4.8)
        line(d,533,595,533+850*p,595,C.mint,.9,4)
        dot(d,533+850*p,595,5+beat*3,C.mint,.9)
    elseif id=="cooperation" then
        local left=t<4.5
        local x=left and 112 or 976
        box(d,x-3,379,838,483,left and C.mint or C.gold,.35+beat*.25,25,2)
        if t>6 then txt(d,"选择适合产品阶段与预算的合作方式",960,898,25,C.mint,ease((t-6)/.5),600,"center") end
    elseif id=="closing" then
        local p=(t*.5)%1
        box(d,579-14*p,620-9*p,762+28*p,103+18*p,C.mint,(1-p)*.45,58,2)
        arrow(d,1390,669,1390+100*ease((t-2)/2),C.mint,ease((t-2)/.5))
    end
    -- 轻量节拍标记只占画面边缘，不遮挡核心信息。
    for i=0,9 do
        local h=4+(8+9*math.sin(t*7+i*.6))*beat
        rr(d,1655+i*14,1050-h,5,h,C.mint,.25+i*.035,2)
    end
end
return Revision
