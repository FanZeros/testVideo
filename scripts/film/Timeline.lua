-- 发行讲解片分镜与字幕：所有经营数据均采用委托方提供口径。
local Film = {
    width = 1920,
    height = 1080,
    fps = 30,
    duration = 128,
    title = "让好游戏，被更多玩家看见",
    music = "audio/music/publishing_theme_procedural.wav",
    output = "video/publishing_explainer_1080p.mp4",
    scenes = {
        { id = "opening", start = 0, duration = 4, chapter = "序章", title = "你的游戏", subtitle = "值得被更多玩家看见", caption = "从开发完成，到真正被发现。" },
        { id = "problem", start = 4, duration = 13, chapter = "当下困境", title = "200 多款游戏，只有前 20 个", subtitle = "达到三位数流量", caption = "服务方提供的当下观察口径 · 非平台官方统计 · 图形为数量关系示意" },
        { id = "pivot", start = 17, duration = 6, chapter = "破局思路", title = "不只把游戏上架", subtitle = "更要把发行节奏跑通", caption = "曝光入口 × 测试节奏 × 流量使用 × 口碑运营" },
        { id = "credentials", start = 23, duration = 10, chapter = "实战经验", title = "开发者出身，发行实战派", subtitle = "2017—2026 · 持续深耕 TapTap", caption = "魔塔 / 三消 / 放置 / RPG / 休闲模拟" },
        { id = "evidence", start = 33, duration = 11, chapter = "真实案例", title = "经验，让数据说话", subtitle = "后台数据，不是概念效果图", caption = "原始后台截图局部展示 · 不同指标、时间窗口不可直接比较" },
        { id = "ranking", start = 44, duration = 9, chapter = "历史高光", title = "我们的游戏，曾登上", subtitle = "热门榜第 2 名", caption = "历史成绩由服务方提供 · 非当前榜单截图 · 不构成排名承诺" },
        { id = "methods", start = 53, duration = 7, chapter = "发行方法", title = "增长不是一个按钮", subtitle = "而是一套协同运作的发行方法", caption = "从被看见，到被选择，再到被留下。" },
        { id = "exposure", start = 60, duration = 8, chapter = "方法 01", title = "把握曝光入口", subtitle = "精准申请，而不是被动等待", caption = "申请与展示结果以平台实际规则、审核及资源安排为准" },
        { id = "stages", start = 68, duration = 16, chapter = "方法 02", title = "不是一次上线，是五步推进", subtitle = "预约期 → 玩家预约反馈 → 限量测试 → 不限量测试 → 首发", caption = "每一步设定目标 → 收集反馈 → 复盘数据 → 决定下一步" },
        { id = "rep", start = 84, duration = 8, chapter = "方法 03", title = "让福利流量，用在关键节点", subtitle = "REP 福利资源规划", caption = "福利资格、额度及使用条件以平台实时政策为准" },
        { id = "reputation", start = 92, duration = 10, chapter = "方法 04", title = "增长之后，更要守住口碑", subtitle = "真实沟通，长期运营", caption = "尊重真实评价 · 不刷评 · 不承诺固定评分" },
        { id = "outcome", start = 102, duration = 8, chapter = "合作价值", title = "不承诺每一款都是爆款", subtitle = "只把每个增长机会，做得更扎实", caption = "效果因产品品质、品类、平台政策及执行情况而异" },
        { id = "cooperation", start = 110, duration = 10, chapter = "合作方式", title = "两种合作，按需选择", subtitle = "同一个目标：让发行更有章法", caption = "具体服务范围、资源投入、分成比例及费用以合同约定为准" },
        { id = "closing", start = 120, duration = 8, chapter = "开始合作", title = "你的下一款游戏", subtitle = "值得一次专业发行", caption = "独立发行服务介绍 · 非 TapTap 官方服务或效果保证" },
    },
}

function Film.FindScene(time)
    local t = math.max(0, math.min(time, Film.duration - 0.00001))
    for i = #Film.scenes, 1, -1 do
        local s = Film.scenes[i]
        if t >= s.start then return s, t - s.start, i end
    end
    return Film.scenes[1], 0, 1
end

return Film
