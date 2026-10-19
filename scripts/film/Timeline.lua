-- 发行讲解片分镜与字幕：所有经营数据均采用委托方提供口径。
local Film = {
    width = 1920,
    height = 1080,
    fps = 30,
    duration = 138,
    title = "让好游戏，被更多玩家看见",
    music = "audio/music/publishing_theme_procedural.wav",
    output = "video/publishing_explainer_1080p.mp4",
    scenes = {
        { id = "opening", start = 0, duration = 4, chapter = "先说个实话", title = "说真的，你的游戏", subtitle = "应该被更多玩家看见", caption = "做完了，不等于有人看见。" },
        { id = "problem", start = 4, duration = 13, chapter = "为什么会这样", title = "一天 200 多款新游，前 20 个才有人看", subtitle = "大部分游戏，上架就被淹了", caption = "这是我们看到的现状，不是平台官方统计 · 图形只表示数量关系" },
        { id = "pivot", start = 17, duration = 6, chapter = "换个思路", title = "所以，别急着上架", subtitle = "先把发行节奏跑通", caption = "让人看见、愿意试、留下来，缺一不可。" },
        { id = "credentials", start = 23, duration = 10, chapter = "我们是谁", title = "我们也是开发者出身", subtitle = "在 TapTap 上，一干就是 9 年", caption = "魔塔、三消、放置、RPG、模拟经营，我们都做过。" },
        { id = "evidence", start = 33, duration = 11, chapter = "看真实数据", title = "光说没用，给你看后台", subtitle = "真实数据，不是概念效果图", caption = "原始后台截图局部展示 · 不同指标、时间窗口不可直接比较" },
        { id = "ranking", start = 44, duration = 9, chapter = "一个高光时刻", title = "我们做的一款游戏", subtitle = "上过热门榜第 2 名", caption = "历史成绩由服务方提供 · 非当前榜单截图 · 不构成排名承诺" },
        { id = "methods", start = 53, duration = 7, chapter = "其实就四件事", title = "增长，没有什么一键开关", subtitle = "它是一整套配合起来的动作", caption = "从被看见，到被选择，再到被留下。" },
        { id = "exposure", start = 60, duration = 8, chapter = "第一件事 · 曝光", title = "先让玩家看见你", subtitle = "曝光位不是等来的，是申请来的", caption = "申请与展示结果以平台实际规则、审核及资源安排为准" },
        { id = "stages", start = 68, duration = 16, chapter = "第二件事 · 节奏", title = "别把上线，当成一锤子买卖", subtitle = "预约、反馈、限量测试、不限量测试，最后才是首发", caption = "每一步设定目标 → 收集反馈 → 复盘数据 → 决定下一步" },
        { id = "comparison", start = 84, duration = 10, chapter = "第二件事 · 对比", title = "多期预约测试，和直接上线差在哪？", subtitle = "同样的游戏，起跑线不一样", caption = "示意曲线 · 非真实后台数据 · 实际效果因产品、品类与执行而异" },
        { id = "rep", start = 94, duration = 8, chapter = "第三件事 · 福利流量", title = "REP 的福利流量，别乱撒", subtitle = "留到关键节点，再集中用", caption = "福利资格、额度及使用条件以平台实时政策为准" },
        { id = "reputation", start = 102, duration = 10, chapter = "第四件事 · 口碑", title = "流量来了，口碑更得守住", subtitle = "跟玩家好好说话，长期做", caption = "尊重真实评价 · 不刷评 · 不承诺固定评分" },
        { id = "outcome", start = 112, duration = 8, chapter = "先把预期说清楚", title = "我们不敢说，每款都能爆", subtitle = "但每个增长机会，都能做得更扎实", caption = "效果因产品品质、品类、平台政策及执行情况而异" },
        { id = "cooperation", start = 120, duration = 10, chapter = "怎么合作", title = "合作方式，就这两种", subtitle = "你按自己的阶段和预算来选", caption = "具体服务范围、资源投入、分成比例及费用以合同约定为准" },
        { id = "closing", start = 130, duration = 8, chapter = "那就聊聊吧", title = "下一款游戏", subtitle = "咱们认真做一次发行", caption = "独立发行服务介绍 · 非 TapTap 官方服务或效果保证" },
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
