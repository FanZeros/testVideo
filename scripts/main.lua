-- 以 scaffold-2d.lua 为起点：播放已经离线合成的发行讲解片。
local UI = require("urhox-libs/UI")
local Video = require("urhox-libs/Video")
local Film = require("film.Timeline")

---@type VideoPlayerWidget?
local player = nil
---@type Button?
local playButton = nil
---@type Label?
local timeLabel = nil

local function FormatTime(seconds)
    return string.format("%02d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

function Start()
    graphics.windowTitle = Film.title
    input.mouseMode = MM_ABSOLUTE
    UI.Init({ theme = "default-dark", scale = UI.Scale.DEFAULT })
    print("[发行讲解片] 初始化播放器，时长=" .. Film.duration .. "，比例=16:9")

    playButton = UI.Button {
        text = "播放影片", width = 120, height = 42,
        onClick = function()
            if not player then return end
            if player:IsPlaying() then player:Pause() else player:Play() end
        end,
    }
    timeLabel = UI.Label { text = "00:00 / 02:08", fontSize = 14 }
    player = Video.VideoPlayer {
        src = "video/publishing_explainer_1080p.mp4",
        width = "100%", flex = 1, flexShrink = 1,
        textureWidth = 1920, textureHeight = 1080,
        autoPlay = false, muted = false, loop = false, volume = 0.85,
        objectFit = "contain", backgroundColor = { 7, 15, 23, 255 },
        onReady = function() print("[发行讲解片] 视频已就绪") end,
        onPlay = function() if playButton then playButton:SetText("暂停") end end,
        onPause = function() if playButton then playButton:SetText("继续播放") end end,
        onEnded = function() if playButton then playButton:SetText("重新播放") end end,
        onTimeUpdate = function(_, currentTime, duration)
            if timeLabel then timeLabel:SetText(FormatTime(currentTime) .. " / " .. FormatTime(duration)) end
        end,
    }
    local root = UI.Panel {
        width = "100%", height = "100%", backgroundColor = { 7, 15, 23, 255 },
        children = {
            player,
            UI.SafeAreaView {
                width = "100%", padding = 16,
                children = {
                    UI.Panel {
                        flexDirection = "row", alignItems = "center", justifyContent = "space-between", gap = 16,
                        children = {
                            UI.Label { text = "让好游戏，被更多玩家看见", fontSize = 16, flexShrink = 1 },
                            timeLabel,
                            playButton,
                        },
                    },
                },
            },
        },
    }
    UI.SetRoot(root)
    if not Video.isSupported then print("[发行讲解片] 当前环境不支持视频播放，请在预览端打开或直接下载 MP4。") end
end

function Stop()
    if player then player:Stop() end
    UI.Shutdown()
    print("[发行讲解片] 播放器已释放")
end
