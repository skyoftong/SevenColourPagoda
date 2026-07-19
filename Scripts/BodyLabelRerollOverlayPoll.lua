-- 淬体无限刷新：第一项覆盖版 v1
-- 不修改真实 data.Labels。
-- 不依赖 WindowEvent。
-- 不依赖键盘或控制台。
-- 通过 OnUpdate 轮询当前淬体窗口，并覆盖第一个候选词条。

local Mod = GameMain:GetMod("BodyLabelRerollOverlayPoll")
local currentWindow = nil
local overlay = nil
local lastCheck = 0

xlua.private_accessible(CS.XiaWorld.Wnd_BodyRollLabel)

local function SafeCall(func)
    local ok, result = pcall(func)
    if ok then
        return result
    end
    return nil
end

local function FindBodyRollWindow()
    -- 依次尝试当前版本中常见的窗口管理器入口。
    local wnd = SafeCall(function()
        return CS.XiaWorld.InGame.Instance:GetWindow(CS.XiaWorld.Wnd_BodyRollLabel)
    end)
    if wnd ~= nil then
        return wnd
    end

    wnd = SafeCall(function()
        return CS.XiaWorld.InGame.Instance:GetWnd("Wnd_BodyRollLabel")
    end)
    if wnd ~= nil then
        return wnd
    end

    wnd = SafeCall(function()
        return CS.XiaWorld.InGame.Instance.Wnd_BodyRollLabel
    end)
    if wnd ~= nil then
        return wnd
    end

    wnd = SafeCall(function()
        return CS.XiaWorld.Wnd_BodyRollLabel.Instance
    end)
    if wnd ~= nil then
        return wnd
    end

    return nil
end

local function FindFirstCandidate(window)
    if window == nil or window.contentPane == nil then
        return nil
    end

    local pane = window.contentPane

    -- 尝试常见固定命名。
    local names = {
        "m_n76", "m_n75", "m_n74", "m_n73",
        "n76", "n75", "n74", "n73",
        "item0", "Item0", "btn0", "Btn0"
    }

    for _, name in ipairs(names) do
        local child = SafeCall(function()
            return pane:GetChild(name)
        end)
        if child ~= nil and child.visible then
            return child
        end
    end

    -- 找不到固定名字时，从所有子控件中选取中部、宽度较大的第一个可点击项。
    local best = nil
    local bestY = 999999

    local count = SafeCall(function()
        return pane.numChildren
    end) or 0

    for i = 0, count - 1 do
        local child = SafeCall(function()
            return pane:GetChildAt(i)
        end)

        if child ~= nil then
            local width = tonumber(child.width) or 0
            local height = tonumber(child.height) or 0
            local x = tonumber(child.x) or 0
            local y = tonumber(child.y) or 0

            if child.visible
                and width > 240
                and height > 25
                and height < 100
                and x > 20
                and y > 40
                and y < bestY then
                best = child
                bestY = y
            end
        end
    end

    return best
end

local function GenerateNewCandidates(window)
    if window == nil then
        return
    end

    local data = window.data
    if data == nil or data.QData == nil then
        return
    end

    local qdata = data.QData
    local mgr = CS.XiaWorld.PracticeMgr.Instance
    local methodDef = mgr:GetBodyQuenchingMethodDef(qdata.method)

    if methodDef == nil then
        return
    end

    local moreCount = tonumber(methodDef.LabelMoreCount) or 0
    local count = CS.XiaWorld.World.RandomRange(
        CS.XiaWorld.GMathUtl.RandomType.emBodyPractice,
        0,
        moreCount + 1
    )

    data.Labels = mgr:GetRandomQuenchingLabelList(
        qdata.method,
        qdata.part,
        qdata.item,
        count
    )

    window:ShowOrUpdate(data)

    -- ShowOrUpdate 可能重建候选列表，下一帧重新创建覆盖层。
    overlay = nil
end

local function RemoveOverlay()
    if overlay ~= nil then
        SafeCall(function()
            overlay:RemoveFromParent()
            overlay:Dispose()
        end)
    end

    overlay = nil
    currentWindow = nil
end

local function EnsureOverlay(window)
    if window == nil or window.contentPane == nil then
        RemoveOverlay()
        return
    end

    local first = FindFirstCandidate(window)
    if first == nil then
        return
    end

    if overlay ~= nil
        and overlay.parent ~= nil
        and currentWindow == window
        and math.abs((overlay.x or 0) - (first.x or 0)) < 2
        and math.abs((overlay.y or 0) - (first.y or 0)) < 2 then
        return
    end

    RemoveOverlay()
    currentWindow = window

    local pane = window.contentPane
    local button = CS.XiaWorld.InGame.UI_Button.CreateInstance()

    button.name = "BodyRerollOverlay"
    button.title = "↻ 重新随机"
    button.x = first.x
    button.y = first.y
    button.width = first.width
    button.height = first.height

    pane:AddChild(button)
    pane:SetChildIndex(button, pane.numChildren - 1)

    button.onClick:Add(function()
        GenerateNewCandidates(window)
    end)

    overlay = button
end

function Mod:OnInit()
    RemoveOverlay()
end

function Mod:OnEnter()
    RemoveOverlay()
end

function Mod:OnLoad(tbLoad)
    RemoveOverlay()
end

function Mod:OnUpdate()
    -- 降低轮询频率，避免每帧遍历 UI。
    local now = CS.UnityEngine.Time.unscaledTime
    if now - lastCheck < 0.15 then
        return
    end
    lastCheck = now

    local window = FindBodyRollWindow()

    if window == nil then
        if overlay ~= nil then
            RemoveOverlay()
        end
        return
    end

    local visible = SafeCall(function()
        return window.visible
    end)

    if visible == false then
        RemoveOverlay()
        return
    end

    EnsureOverlay(window)
end
