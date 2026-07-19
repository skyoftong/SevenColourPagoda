-- 淬体效果重置：源码重写测试版
-- 依赖游戏/前置 MOD 提供的 WindowEvent 模块。
-- 功能：在体修淬体结果窗口加入“刷新”按钮，每次淬体最多刷新 3 次。

local Mod = GameMain:NewMod("BodyLabelRerollSource")
local WindowEvent = GameMain:GetMod("WindowEvent")

local MAX_REROLL = 3
local currentWindow = nil
local rerollCount = 0

-- 允许 Lua 访问淬体结果窗口的非公开成员。
xlua.private_accessible(CS.XiaWorld.Wnd_BodyRollLabel)

local function ShowMessage(text)
    CS.XiaWorld.InGame.UI_WndMessage:Show(text)
end

local function GetWindowData(window)
    if window == nil then
        return nil
    end
    return window.data
end

local function Reroll(window)
    local data = GetWindowData(window)
    if data == nil or data.QData == nil then
        ShowMessage("未能读取当前淬体数据。")
        return
    end

    if rerollCount >= MAX_REROLL then
        ShowMessage("本次淬体的刷新次数已经用尽。")
        return
    end

    local practiceMgr = CS.XiaWorld.PracticeMgr.Instance
    local methodDef = practiceMgr:GetBodyQuenchingMethodDef(data.QData.method)

    if methodDef == nil then
        ShowMessage("未能读取当前淬体方法。")
        return
    end

    -- 原 MOD 使用同一套体修随机类型重新生成词条。
    -- LabelMoreCount 决定本次额外词条数量；不额外提高品质和数量。
    local labelMoreCount = methodDef.LabelMoreCount
    local randomValue = CS.XiaWorld.World.RandomRange(
        CS.XiaWorld.GMathUtl.RandomType.emBodyPractice,
        0,
        labelMoreCount + 1
    )

    data.Labels = practiceMgr:GetRandomQuenchingLabelList(
        data.QData.method,
        data.QData.part,
        data.QData.item,
        randomValue
    )

    rerollCount = rerollCount + 1

    -- 用新生成的 Labels 刷新当前结果窗口。
    window:ShowOrUpdate(data)
end

local function AddRerollButton(window)
    if window == nil or window.contentPane == nil then
        return
    end

    currentWindow = window
    rerollCount = 0

    local oldButton = window.contentPane:GetChild("RerollBtn")
    if oldButton ~= nil then
        return
    end

    local button = CS.XiaWorld.InGame.UI_Button.CreateInstance()
    button.name = "RerollBtn"
    button.title = "刷新（0/" .. tostring(MAX_REROLL) .. "）"

    window.contentPane:AddChild(button)

    -- 尽量放到原窗口底部按钮区域附近。
    local anchor = window.contentPane:GetChild("m_n76")
    if anchor ~= nil then
        button.x = anchor.x + anchor.width + 10
        button.y = anchor.y
        button.width = anchor.width
        button.height = anchor.height
    end

    button.onClick:Add(function()
        Reroll(window)
        button.title = "刷新（" .. tostring(rerollCount) .. "/" .. tostring(MAX_REROLL) .. "）"
    end)
end

function Mod:OnInit()
    if WindowEvent == nil then
        print("[BodyLabelRerollSource] 缺少 WindowEvent 模块。")
        return
    end

    -- WindowEvent 的公开事件注册方式。
    -- 回调仅处理 Wnd_BodyRollLabel 淬体结果窗口。
    WindowEvent._Event:RegisterEvent(
        g_emEvent.WindowEvent,
        "BodyLabelRerollSource",
        function(window)
            if window ~= nil and window:GetType().Name == "Wnd_BodyRollLabel" then
                AddRerollButton(window)
            end
        end
    )

    print("[BodyLabelRerollSource] MOD loaded.")
end
