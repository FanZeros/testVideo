-- 基于 scaffold-2d.lua 的生命周期组织；离线合成与引擎共用确定性分镜。
local Film = require("film.Timeline")
local Motion = {}
local C = {
    ink = {8, 16, 24}, panel = {15, 30, 41}, border = {40, 67, 78},
    white = {239, 248, 247}, muted = {145, 172, 180}, mint = {69, 230, 194},
    gold = {245, 203, 126}, blue = {105, 161, 246}, red = {245, 129, 135},
}

local function clamp(v) return math.max(0, math.min(1, v)) end
local function ease(v) local p = clamp(v); return 1 - (1 - p)^3 end
local function smooth(v) local p = clamp(v); return p*p*(3-2*p) end
local function reveal(t, delay, duration) return ease((t-(delay or 0))/(duration or 0.8)) end
local function rect(d,x,y,w,h,c,a,r) d.rect(x,y,w,h,c[1],c[2],c[3],a or 1,r or 0) end
local function outline(d,x,y,w,h,c,a,r,lw) d.outline(x,y,w,h,c[1],c[2],c[3],a or 1,r or 0,lw or 1) end
local function line(d,x1,y1,x2,y2,c,a,lw) d.line(x1,y1,x2,y2,c[1],c[2],c[3],a or 1,lw or 2) end
local function circle(d,x,y,r,c,a,lw) d.circle(x,y,r,c[1],c[2],c[3],a or 1,lw or 0) end
local function text(d,str,x,y,size,c,a,weight,align,maxWidth)
    d.text(str,x,y,size,c[1],c[2],c[3],a or 1,weight or 500,align or "left",maxWidth or 1800)
end
local function say(d,str,x,y,size,c,t,delay,weight,align,maxWidth)
    local p = reveal(t,delay)
    text(d,str,x,y+30*(1-p),size,c,p,weight,align,maxWidth)
end
local function pill(d,str,x,y,w,c,a)
    outline(d,x,y,w,48,c,a or 1,24,1)
    text(d,str,x+w/2,y+11,21,c,a or 1,500,"center",w-20)
end
local function arrow(d,x,y,w,c,a)
    line(d,x,y,x+w,y,c,a,3)
    line(d,x+w-10,y-9,x+w,y,c,a,3)
    line(d,x+w-10,y+9,x+w,y,c,a,3)
end
local function path(d,pts,c,a,lw)
    d.path(pts,c[1],c[2],c[3],a or 1,lw or 3)
end
local function card(d,x,y,w,h,a,accent)
    rect(d,x,y,w,h,C.panel,a,24)
    outline(d,x,y,w,h,accent or C.border,a,24,1)
end
local function icon(d,kind,x,y,s,c,a,t)
    local function L(ax,ay,bx,by) line(d,x+ax*s,y+ay*s,x+bx*s,y+by*s,c,a,3) end
    if kind == "target" then
        circle(d,x,y,38*s,c,a,2); circle(d,x,y,23*s,c,a,2); circle(d,x,y,7*s,c,a)
        L(8,-8,40,-40); L(40,-40,25,-40); L(40,-40,40,-25)
    elseif kind == "chart" then
        L(-35,34,38,34); L(-35,34,-35,-35)
        L(-26,18,-7,2); L(-7,2,10,8); L(10,8,34,-26); L(21,-26,34,-26); L(34,-26,34,-13)
    elseif kind == "spark" then
        L(-34,0,34,0); L(0,-34,0,34); L(-23,-23,23,23); L(-23,23,23,-23)
        circle(d,x,y,11*s,C.ink,1)
    elseif kind == "shield" then
        path(d,{{x,y-39*s},{x+31*s,y-25*s},{x+26*s,y+13*s},{x,y+39*s},{x-26*s,y+13*s},{x-31*s,y-25*s},{x,y-39*s}},c,a,3)
        L(-14,0,-3,11); L(-3,11,18,-14)
    else
        circle(d,x,y,32*s,c,a,2); L(-14,0,14,0); L(0,-14,0,14)
    end
end
local function heading(d,s,t)
    say(d,s.title,112,172,66,C.white,t,0.1,750,"left",1690)
    say(d,s.subtitle,116,270,32,C.muted,t,0.5,450,"left",1690)
end
local function particles(d,t,gold)
    local col=gold and C.gold or C.mint
    for i=1,34 do
        local x=(i*173.27+math.sin(t*0.13+i)*60)%1920
        local y=(i*97.13-t*(5+i%5))%1080
        circle(d,x,y,1+(i%3)*0.5,col,0.10+0.08*math.sin(i+t*0.4))
    end
end
local function background(d,t,id)
    d.background(t,id == "ranking" or id == "closing")
    for i=0,20 do line(d,i*96,0,i*96,1080,C.border,0.12,1) end
    for j=0,12 do line(d,0,j*96,1920,j*96,C.border,0.10,1) end
    particles(d,t,id == "ranking")
end
local function chrome(d,s,t,index)
    rect(d,110,66,9,27,C.mint,1,3)
    text(d,"发行实战 / GAME PUBLISHING",134,66,23,C.white,1,650)
    text(d,string.format("%02d / 14   ·   %s",index,s.chapter),1805,66,20,C.muted,1,500,"right")
    line(d,112,117,1808,117,C.border,0.8,1)
    text(d,s.caption,112,965,20,C.muted,0.92,450,"left",1700)
    rect(d,112,1012,1696,3,C.border,0.6,1)
    rect(d,112,1012,1696*clamp(t/Film.duration),3,C.mint,0.9,1)
end

local function opening(d,s,t)
    local p=reveal(t,0.0,1.5)
    circle(d,1490,520,245+10*math.sin(t*0.6),C.mint,0.17,2)
    circle(d,1490,520,190,C.mint,0.13,1)
    for i=1,3 do
        local a=t*0.25+i*2.094
        circle(d,1490+245*math.cos(a),520+245*math.sin(a),6,C.mint,0.9)
    end
    icon(d,"chart",1490,525,3.2,C.mint,p,t)
    pill(d,"INDEPENDENT GAME PUBLISHING",116,226,532,C.mint,p)
    say(d,"你的游戏",110,333,102,C.white,t,0.3,800)
    say(d,"值得被更多玩家",110,470,86,C.white,t,0.7,750)
    say(d,"看见。",110,582,112,C.mint,t,1.1,850)
    local q=reveal(t,1.7)
    rect(d,116,775,65*q,3,C.mint,q)
    say(d,"TapTap 平台发行服务",205,756,30,C.muted,t,1.7,500)
end
local function problem(d,s,t)
    heading(d,s,t)
    local a=reveal(t,0.6)
    for i=1,7 do
        local y=365+(i-1)*71
        card(d,1045,y,730,59,a*0.45)
        rect(d,1063,y+13,33,33,C.border,a,8)
        rect(d,1117,y+17,160+i%3*52,8,C.muted,a*0.25,4)
        rect(d,1117,y+34,230+i%2*70,5,C.muted,a*0.12,2)
    end
    local y=360+smooth((t-0.8)/4)*350
    card(d,1010,y,800,84,a,C.mint)
    rect(d,1035,y+17,50,50,C.mint,a,12)
    icon(d,"spark",1060,y+42,0.4,C.ink,a)
    text(d,"你的游戏",1110,y+14,27,C.white,a,650)
    text(d,"在拥挤的列表里，等待被发现",1110,y+48,18,C.muted,a)
    local items={{"01","缺少曝光入口"},{"02","首发没有蓄水"},{"03","投放节奏失焦"},{"04","口碑缺少维护"}}
    for i,v in ipairs(items) do
        local p=reveal(t,0.8+i*0.35)
        text(d,v[1],120,383+(i-1)*103,23,C.red,p,600)
        text(d,v[2],186,368+(i-1)*103,37,C.white,p,600)
        line(d,186,429+(i-1)*103,830,429+(i-1)*103,C.border,p*0.6,1)
    end
end
local function pivot(d,s,t)
    say(d,"不只把游戏上架",960,260,76,C.white,t,0.2,750,"center")
    say(d,"更要把发行节奏跑通",960,365,84,C.mint,t,0.7,800,"center")
    local list={{"曝光入口","target"},{"测试节奏","chart"},{"流量使用","spark"},{"口碑运营","shield"}}
    for i,v in ipairs(list) do
        local p=reveal(t,1.2+(i-1)*0.22)
        local x=115+(i-1)*435
        card(d,x,575+35*(1-p),390,222,p)
        icon(d,v[2],x+65,640+35*(1-p),0.85,C.mint,p)
        text(d,v[1],x+38,712+35*(1-p),33,C.white,p,650)
        if i<4 then text(d,"×",x+412,658,36,C.muted,p,400,"center") end
    end
end
local function credentials(d,s,t)
    heading(d,s,t)
    local data={{9,"年","平台深耕",C.mint},{127,"款","累计发行游戏",C.white},{115,"万+","累计新增用户",C.gold}}
    for i,v in ipairs(data) do
        local x=112+(i-1)*580
        local p=reveal(t,0.8+(i-1)*0.35)
        card(d,x,391+45*(1-p),536,348,p)
        local n=math.floor(v[1]*ease((t-1-(i-1)*0.35)/2.0)+0.5)
        text(d,tostring(n),x+39,408+45*(1-p),146,v[4],p,800,"left",340)
        text(d,v[2],x+403,510+45*(1-p),32,v[4],p,650,"right")
        line(d,x+40,610+45*(1-p),x+496,610+45*(1-p),C.border,p,1)
        text(d,v[3],x+40,651+45*(1-p),31,C.muted,p,500)
    end
    say(d,"数据截至 2026 年 10 月 · 累计发行与运营数据由服务方提供",115,797,22,C.muted,t,2.2,400)
end
local function evidence(d,s,t)
    heading(d,s,t)
    local a=reveal(t,0.6)
    card(d,112,369,1070,468,a)
    d.image("image/QQ20261019-104942.png",133,389,1028,421,a)
    local scan=135+1025*smooth((t-1)/6)
    line(d,scan,393,scan,809,C.mint,a*0.8,2)
    local detail=reveal(t,5.5)
    if detail>0 then
        card(d,681,459,467,350,detail,C.gold)
        d.image("image/film/download_evidence.png",698,477,433,314,detail)
    end
    local p=reveal(t,1.2)
    card(d,1220,369,590,260,p,C.mint)
    text(d,"累计新增用户",1252,401,26,C.muted,p,500)
    text(d,"1,153,752",1252,447,76,C.mint,p,800,"left",530)
    text(d,"来自委托方后台原图",1252,558,22,C.muted,p)
    local q=reveal(t,3.1)
    card(d,1220,655,590,182,q)
    text(d,"单日 APK 新增下载完成量",1252,680,24,C.muted,q)
    text(d,"13,720",1252,719,64,C.gold,q,750)
    text(d,"2021-05-03",1776,783,19,C.muted,q,450,"right")
    say(d,"真实记录  /  长期积累  /  可追溯案例",115,878,24,C.white,t,2.1,500)
end
local function ranking(d,s,t)
    local p=reveal(t,0.3,1.4)
    for i=1,5 do circle(d,1335,515,170+i*31+7*math.sin(t*0.4),C.gold,0.06+i*0.012,1) end
    local pts={{995,775},{1090,732},{1150,745},{1210,646},{1285,670},{1370,496},{1450,460},{1540,285},{1690,218}}
    local total=math.max(2,math.floor(2+7*reveal(t,0.5,2.8)))
    local out={}
    for i=1,total do out[#out+1]=pts[i] end
    path(d,out,C.gold,p*0.25,12); path(d,out,C.gold,p*0.85,3)
    say(d,"我们的游戏，曾登上",112,293,47,C.white,t,0.1,600)
    say(d,"热门榜",112,372,99,C.white,t,0.4,800)
    say(d,"第",117,623,70,C.gold,t,0.8,700)
    text(d,"2",308,497+70*(1-p),302,C.gold,p,900,"left",320)
    say(d,"名",578,731,76,C.gold,t,1.1,700)
    say(d,"一次登榜，是产品与发行共同发力的结果。",116,827,29,C.muted,t,2.2,450,"left",1640)
    pill(d,"HISTORICAL MILESTONE",1082,782,630,C.gold,reveal(t,1.8))
end
local function methods(d,s,t)
    heading(d,s,t)
    local titles={"曝光申请","多段测试","REP 福利流量","口碑运维"}
    local kinds={"target","chart","spark","shield"}
    local xs={112,553,994,1435}
    for i=1,4 do
        local p=reveal(t,0.8+(i-1)*0.2)
        card(d,xs[i],418+40*(1-p),375,345,p,i==1 and C.mint or C.border)
        text(d,"0"..i,xs[i]+31,443+40*(1-p),22,C.muted,p,600)
        icon(d,kinds[i],xs[i]+188,556+40*(1-p),1.3,C.mint,p)
        text(d,titles[i],xs[i]+188,677+40*(1-p),31,C.white,p,650,"center",330)
    end
    say(d,"四个关键环节，一个完整发行闭环。",960,843,28,C.muted,t,2.4,450,"center")
end
local function exposure(d,s,t)
    heading(d,s,t)
    local p=reveal(t,0.7)
    card(d,112,377,705,480,p)
    text(d,"01",151,411,104,C.mint,p,800)
    text(d,"匹配品类与发行阶段",153,569,36,C.white,p,650)
    text(d,"准备材料 · 主动申请 · 配合节奏",153,643,27,C.muted,p,500)
    pill(d,"让合适的玩家，更容易遇见你",152,748,593,C.mint,reveal(t,1.6))
    local tags={{"新游推荐","新品上线窗口"},{"编辑精选","内容与品质匹配"},{"品类榜单","找到目标受众"},{"限时活动","配合平台节奏"}}
    for i,v in ipairs(tags) do
        local x=874+((i-1)%2)*479
        local y=377+math.floor((i-1)/2)*252
        local q=reveal(t,1.0+i*0.28)
        card(d,x,y+25*(1-q),444,228,q)
        icon(d,"target",x+51,y+54+25*(1-q),0.55,C.mint,q)
        text(d,v[1],x+31,y+98+25*(1-q),37,C.white,q,650)
        text(d,v[2],x+31,y+163+25*(1-q),24,C.muted,q)
    end
end
local function stages(d,s,t)
    heading(d,s,t)
    local stagesData={{"01","预约期","积累意向玩家","看预约量"},{"02","不限量测试","验证留存与反馈","看真实体验"},{"03","正式首发","集中资源启动","看首日表现"}}
    local p=reveal(t,0.8,4)
    line(d,245,520,1670,520,C.border,1,3)
    line(d,245,520,245+1425*p,520,C.mint,1,4)
    for i,v in ipairs(stagesData) do
        local x=112+(i-1)*580
        local a=reveal(t,0.8+(i-1)*1.05)
        card(d,x,594+30*(1-a),536,252,a)
        circle(d,x+268,520,34,C.panel,1)
        circle(d,x+268,520,34,C.mint,a,2)
        text(d,v[1],x+268,503,26,C.mint,a,650,"center")
        text(d,v[2],x+268,406,42,C.white,a,700,"center")
        text(d,v[3],x+33,628+30*(1-a),32,C.white,a,650)
        text(d,v[4],x+33,706+30*(1-a),25,C.mint,a,500)
        text(d,"设定目标 → 复盘数据 → 调整动作",x+33,784+30*(1-a),20,C.muted,a)
    end
end
local function rep(d,s,t)
    heading(d,s,t)
    local p=reveal(t,0.7)
    circle(d,539,578,190,C.mint,p*0.45,2)
    circle(d,539,578,228+8*math.sin(t),C.mint,p*0.12,1)
    icon(d,"spark",539,578,1.6,C.mint,p)
    text(d,"REP",539,695,54,C.white,p,750,"center")
    local actions={{"核对福利资格","先了解适用范围"},{"规划资源使用","把流量放到重要节点"},{"复盘投放表现","依据实际数据优化"}}
    for i,v in ipairs(actions) do
        local a=reveal(t,1.0+i*0.4)
        local y=378+(i-1)*161
        card(d,990,y+24*(1-a),818,139,a)
        text(d,"0"..i,1021,y+45+24*(1-a),28,C.mint,a,700)
        text(d,v[1],1093,y+21+24*(1-a),33,C.white,a,650)
        text(d,v[2],1093,y+77+24*(1-a),24,C.muted,a)
        arrow(d,785,y+69,151,C.mint,a*0.5)
    end
end
local function reputation(d,s,t)
    heading(d,s,t)
    local p=reveal(t,0.7)
    icon(d,"shield",479,581,3.4,C.mint,p)
    text(d,"口碑，是长期资产",479,800,31,C.white,p,650,"center")
    local data={{"日常跟进","理解玩家真实体验"},{"及时响应","反馈问题，推动修复"},{"合规申诉","按平台规则处理恶意评价"},{"持续维护","鼓励真实反馈，不操控评分"}}
    for i,v in ipairs(data) do
        local a=reveal(t,0.7+i*0.35)
        local x=885+((i-1)%2)*474
        local y=380+math.floor((i-1)/2)*245
        card(d,x,y+30*(1-a),442,220,a)
        circle(d,x+38,y+43+30*(1-a),6,C.mint,a)
        text(d,v[1],x+30,y+79+30*(1-a),34,C.white,a,650)
        text(d,v[2],x+30,y+152+30*(1-a),21,C.muted,a,450,"left",386)
    end
end
local function outcome(d,s,t)
    say(d,"不承诺每一款都是爆款",960,242,76,C.white,t,0.2,750,"center")
    say(d,"只把每个增长机会",960,352,66,C.muted,t,0.7,600,"center")
    say(d,"做得更扎实",960,451,94,C.mint,t,1.1,800,"center")
    local items={"更多有效曝光","更清晰的发行节奏","更可持续的口碑"}
    for i,v in ipairs(items) do
        local p=reveal(t,1.7+(i-1)*0.23)
        local x=170+(i-1)*557
        icon(d,"shield",x+38,725,0.55,C.mint,p)
        text(d,v,x+87,701,31,C.white,p,600)
    end
end
local function cooperation(d,s,t)
    heading(d,s,t)
    local data={{"01 / REVENUE SHARE","合作分成","前期投入发行资源","不先收服务费 · 按约定分成","风险共担，利益绑定",C.mint},{"02 / MANAGED SERVICE","付费服务","一次性支付服务费用","预约 / 测试 / 首发 / 口碑运维","全流程托管，按约定交付",C.gold}}
    for i,v in ipairs(data) do
        local x=112+(i-1)*864
        local a=reveal(t,0.8+(i-1)*0.35)
        card(d,x,382+35*(1-a),832,477,a,v[6])
        text(d,v[1],x+38,418+35*(1-a),22,v[6],a,600)
        text(d,v[2],x+38,476+35*(1-a),63,C.white,a,750)
        line(d,x+38,580+35*(1-a),x+793,580+35*(1-a),C.border,a,1)
        text(d,v[3],x+38,615+35*(1-a),33,C.white,a,600)
        text(d,v[4],x+38,684+35*(1-a),25,C.muted,a,450,"left",760)
        text(d,v[5],x+38,782+35*(1-a),29,v[6],a,650)
    end
end
local function closing(d,s,t)
    pill(d,"下一次增长，从一次沟通开始",686,220,548,C.mint,reveal(t,0.1))
    say(d,"你的下一款游戏",960,322,83,C.white,t,0.2,750,"center")
    say(d,"值得一次专业发行",960,432,94,C.mint,t,0.6,850,"center")
    local a=reveal(t,1.2)
    rect(d,579,620,762,103,C.mint,a,52)
    text(d,"发送游戏信息，免费发行诊断",960,646,37,C.ink,a,750,"center",730)
    say(d,"准备上线，或上线后增长遇阻，都可以先聊聊。",960,781,28,C.muted,t,1.7,450,"center")
    say(d,"9 年实战   /   127 款发行   /   115 万+用户增长经验",960,858,25,C.gold,t,2.1,600,"center")
end
local renderers={opening=opening,problem=problem,pivot=pivot,credentials=credentials,evidence=evidence,ranking=ranking,methods=methods,exposure=exposure,stages=stages,rep=rep,reputation=reputation,outcome=outcome,cooperation=cooperation,closing=closing}

function Motion.Render(d,time)
    local s,t,index=Film.FindScene(time)
    background(d,time,s.id)
    renderers[s.id](d,s,t)
    chrome(d,s,time,index)
    -- 章节之间使用短促的同色遮罩扫场，不以长黑场割裂节奏。
    if index>1 and t<0.38 then
        local p=smooth(t/0.38)
        rect(d,1920*p,0,1920*(1-p),1080,C.ink,1)
        rect(d,1920*p-5,0,5,1080,C.mint,1-p)
    end
    if time<0.8 then rect(d,0,0,1920,1080,C.ink,1-smooth(time/0.8)) end
    if time>127 then rect(d,0,0,1920,1080,C.ink,smooth((time-127)/1)) end
end

return Motion
