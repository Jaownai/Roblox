if getgenv().SimpleSpyExecuted and type(getgenv().SimpleSpyShutdown) == "function" then
    getgenv().SimpleSpyShutdown()
end

local realconfigs = {
    logcheckcaller = false,
    autoblock = false,
    funcEnabled = true,
    advancedinfo = false,
    supersecretdevtoggle = false
}

local configs = newproxy(true)
local configsmetatable = getmetatable(configs)
configsmetatable.__index = function(self, index) return realconfigs[index] end

local oth = syn and syn.oth
local unhook = oth and oth.unhook
local hook = oth and oth.hook
local lower = string.lower
local byte = string.byte
local running = coroutine.running
local resume = coroutine.resume
local status = coroutine.status
local yield = coroutine.yield
local create = coroutine.create
local close = coroutine.close
local OldDebugId = game.GetDebugId
local info = debug.info
local IsA = game.IsA
local tostring = tostring
local tonumber = tonumber
local delay = task.delay
local spawn = task.spawn
local clear = table.clear
local clone = table.clone

local function blankfunction(...) return ... end

local get_thread_identity = (syn and syn.get_thread_identity) or getidentity or getthreadidentity
local set_thread_identity = (syn and syn.set_thread_identity) or setidentity
local islclosure = islclosure or is_l_closure
local threadfuncs = (get_thread_identity and set_thread_identity) and true or false
local getinfo = getinfo or blankfunction
local getupvalues = getupvalues or debug.getupvalues or blankfunction
local getconstants = getconstants or debug.getconstants or blankfunction
local getcustomasset = getsynasset or getcustomasset
local getcallingscript = getcallingscript or blankfunction
local newcclosure = newcclosure or blankfunction
local clonefunction = clonefunction or blankfunction
local cloneref = cloneref or blankfunction
local request = request or syn and syn.request
local makewritable = makewriteable or function(tbl) setreadonly(tbl, false) end
local makereadonly = makereadonly or function(tbl) setreadonly(tbl, true) end
local isreadonly = isreadonly or table.isfrozen

local setclipboard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) or function(...)
    return ErrorPrompt("Attempted to set clipboard: " .. (...), true)
end

local hookmetamethod = hookmetamethod or (makewriteable and makereadonly and getrawmetatable) and function(obj, metamethod, func)
    local old = getrawmetatable(obj)
    if hookfunction then
        return hookfunction(old[metamethod], func)
    else
        local oldmeta = old[metamethod]
        makewriteable(old)
        old[metamethod] = func
        makereadonly(old)
        return oldmeta
    end
end

local function SafeGetService(service)
    return cloneref(game:GetService(service))
end

local function IsCyclicTable(tbl)
    local checked = {}
    local function Search(t)
        table.insert(checked, t)
        for _, v in t do
            if type(v) == "table" then
                if table.find(checked, v) then return true end
                if Search(v) then return true end
            end
        end
    end
    return Search(tbl)
end

local function deepclone(args, copies)
    local copy
    copies = copies or {}
    if type(args) == "table" then
        if copies[args] then
            copy = copies[args]
        else
            copy = {}
            copies[args] = copy
            for i, v in next, args do
                copy[deepclone(i, copies)] = deepclone(v, copies)
            end
        end
    elseif typeof(args) == "Instance" then
        copy = cloneref(args)
    else
        copy = args
    end
    return copy
end

local function rawtostring(userdata)
    if type(userdata) == "table" or typeof(userdata) == "userdata" then
        local rawmeta = getrawmetatable(userdata)
        local cached = rawmeta and rawget(rawmeta, "__tostring")
        if cached then
            local wasreadonly = isreadonly(rawmeta)
            if wasreadonly then makewritable(rawmeta) end
            rawset(rawmeta, "__tostring", nil)
            local s = tostring(userdata)
            rawset(rawmeta, "__tostring", cached)
            if wasreadonly then makereadonly(rawmeta) end
            return s
        end
    end
    return tostring(userdata)
end

local CoreGui = SafeGetService("CoreGui")
local Players = SafeGetService("Players")
local RunService = SafeGetService("RunService")
local UserInputService = SafeGetService("UserInputService")
local TweenService = SafeGetService("TweenService")
local TextService = SafeGetService("TextService")
local http = SafeGetService("HttpService")

local function jsone(str) return http:JSONEncode(str) end
local function jsond(str)
    local suc, err = pcall(http.JSONDecode, http, str)
    return suc and err or suc
end

function ErrorPrompt(Message, state)
    if getrenv then
        local EP = getrenv().require(CoreGui:WaitForChild("RobloxGui"):WaitForChild("Modules"):WaitForChild("ErrorPrompt"))
        local prompt = EP.new("Default", { HideErrorCode = true })
        local Storage2 = Instance.new("ScreenGui")
        Storage2.Parent = CoreGui
        Storage2.ResetOnSpawn = false
        local thread = state and running()
        prompt:setParent(Storage2)
        prompt:setErrorTitle("Simple Spy Error")
        prompt:updateButtons({{
            Text = "Proceed",
            Callback = function()
                prompt:_close()
                Storage2:Destroy()
                if thread then resume(thread) end
            end,
            Primary = true
        }}, "Default")
        prompt:_open(Message)
        if thread then yield(thread) end
    else
        warn(Message)
    end
end

local G2L = {}

G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
G2L["1"]["Name"] = "SimpleSpy"
G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling
G2L["1"]["ResetOnSpawn"] = false

G2L["2"] = Instance.new("Frame", G2L["1"])
G2L["2"]["BorderSizePixel"] = 0
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(101, 101, 101)
G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["2"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["2"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["2"]["Name"] = "Canvas"
G2L["2"]["BackgroundTransparency"] = 1

G2L["3"] = Instance.new("Frame", G2L["2"])
G2L["3"]["BorderSizePixel"] = 0
G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["3"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["3"]["Size"] = UDim2.new(0.29182, 0, 0.4037, 0)
G2L["3"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["3"]["Name"] = "Main"
G2L["3"]["BackgroundTransparency"] = 1

G2L["4"] = Instance.new("ImageLabel", G2L["3"])
G2L["4"]["BorderSizePixel"] = 0
G2L["4"]["SliceCenter"] = Rect.new(256, 256, 256, 256)
G2L["4"]["SliceScale"] = 0.0625
G2L["4"]["ScaleType"] = Enum.ScaleType.Slice
G2L["4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["4"]["ImageColor3"] = Color3.fromRGB(17, 17, 17)
G2L["4"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["4"]["Image"] = "rbxassetid://80999662900595"
G2L["4"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["4"]["BackgroundTransparency"] = 1
G2L["4"]["Name"] = "Background"
G2L["4"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["5"] = Instance.new("Frame", G2L["4"])
G2L["5"]["BorderSizePixel"] = 0
G2L["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["5"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["5"]["Size"] = UDim2.new(0.05517, 0, 0.06957, 0)
G2L["5"]["Position"] = UDim2.new(1, 0, 1, 0)
G2L["5"]["Name"] = "Resize"
G2L["5"]["BackgroundTransparency"] = 1

G2L["6"] = Instance.new("ImageButton", G2L["5"])
G2L["6"]["BorderSizePixel"] = 0
G2L["6"]["ImageTransparency"] = 0.8
G2L["6"]["BackgroundTransparency"] = 1
G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["6"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["6"]["Image"] = "rbxassetid://120997033468887"
G2L["6"]["Size"] = UDim2.new(2.79682, 0, 3, 0)
G2L["6"]["Name"] = "Icon"
G2L["6"]["Position"] = UDim2.new(0.2202, 0, 0.03343, 0)

G2L["7"] = Instance.new("ImageButton", G2L["4"])
G2L["7"]["SliceScale"] = 0.38672
G2L["7"]["BorderSizePixel"] = 0
G2L["7"]["SliceCenter"] = Rect.new(256, 256, 256, 256)
G2L["7"]["ScaleType"] = Enum.ScaleType.Slice
G2L["7"]["ImageTransparency"] = 0.8
G2L["7"]["BackgroundTransparency"] = 1
G2L["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["7"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["7"]["Image"] = "rbxassetid://80999662900595"
G2L["7"]["Size"] = UDim2.new(0.27586, 0, 0.01237, 0)
G2L["7"]["Name"] = "Drag"
G2L["7"]["Position"] = UDim2.new(0.5, 0, 1.015, 0)

G2L["8"] = Instance.new("ImageLabel", G2L["3"])
G2L["8"]["ZIndex"] = 0
G2L["8"]["BorderSizePixel"] = 0
G2L["8"]["SliceCenter"] = Rect.new(99, 99, 99, 99)
G2L["8"]["ScaleType"] = Enum.ScaleType.Slice
G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["8"]["ImageTransparency"] = 0.6
G2L["8"]["ImageColor3"] = Color3.fromRGB(0, 0, 0)
G2L["8"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["8"]["Image"] = "rbxassetid://8992230677"
G2L["8"]["Size"] = UDim2.new(1.17241, 0, 1.21739, 0)
G2L["8"]["BackgroundTransparency"] = 1
G2L["8"]["Name"] = "Blur"
G2L["8"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["9"] = Instance.new("UICorner", G2L["3"])
G2L["9"]["CornerRadius"] = UDim.new(0.03478, 0)

G2L["a"] = Instance.new("CanvasGroup", G2L["3"])
G2L["a"]["BorderSizePixel"] = 0
G2L["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["a"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["a"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["a"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["a"]["BackgroundTransparency"] = 1

G2L["b"] = Instance.new("UICorner", G2L["a"])
G2L["b"]["CornerRadius"] = UDim.new(0.03478, 0)

G2L["c"] = Instance.new("CanvasGroup", G2L["a"])
G2L["c"]["BorderSizePixel"] = 0
G2L["c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["c"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["c"]["Size"] = UDim2.new(0.99915, 0, 0.88732, 0)
G2L["c"]["Position"] = UDim2.new(0.49958, 0, 0.55634, 0)
G2L["c"]["Name"] = "Content"
G2L["c"]["LayoutOrder"] = 1
G2L["c"]["BackgroundTransparency"] = 1

G2L["d"] = Instance.new("CanvasGroup", G2L["c"])
G2L["d"]["BorderSizePixel"] = 0
G2L["d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["d"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["d"]["Size"] = UDim2.new(0.35, 0, 1, 0)
G2L["d"]["Position"] = UDim2.new(0.17599, 0, 0.54891, 0)
G2L["d"]["Name"] = "Selection"
G2L["d"]["BackgroundTransparency"] = 1

G2L["e"] = Instance.new("ScrollingFrame", G2L["d"])
G2L["e"]["Active"] = true
G2L["e"]["BorderSizePixel"] = 0
G2L["e"]["CanvasSize"] = UDim2.new(0, 0, 0, 0)
G2L["e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["e"]["VerticalScrollBarPosition"] = Enum.VerticalScrollBarPosition.Left
G2L["e"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["e"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y
G2L["e"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["e"]["ScrollBarImageColor3"] = Color3.fromRGB(166, 166, 166)
G2L["e"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["e"]["ScrollBarThickness"] = 0
G2L["e"]["LayoutOrder"] = 1
G2L["e"]["BackgroundTransparency"] = 1

G2L["f"] = Instance.new("UIPadding", G2L["e"])
G2L["f"]["PaddingRight"] = UDim.new(0.02499, 0)
G2L["f"]["PaddingLeft"] = UDim.new(0.02499, 0)

G2L["10"] = Instance.new("Frame", G2L["e"])
G2L["10"]["BorderSizePixel"] = 0
G2L["10"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["10"]["AnchorPoint"] = Vector2.new(0.5, 0)
G2L["10"]["AutomaticSize"] = Enum.AutomaticSize.Y
G2L["10"]["Size"] = UDim2.new(1, 0, 0, 0)
G2L["10"]["Position"] = UDim2.new(0.5, 0, 0, 0)
G2L["10"]["Name"] = "Content"
G2L["10"]["BackgroundTransparency"] = 1

G2L["11"] = Instance.new("UIListLayout", G2L["10"])
G2L["11"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["12"] = Instance.new("UIPadding", G2L["10"])
G2L["12"]["PaddingBottom"] = UDim.new(0, 7)

G2L["13"] = Instance.new("ImageButton", G2L["10"])
G2L["13"]["SliceScale"] = 0.03516
G2L["13"]["BorderSizePixel"] = 0
G2L["13"]["SliceCenter"] = Rect.new(256, 256, 256, 256)
G2L["13"]["ScaleType"] = Enum.ScaleType.Slice
G2L["13"]["ImageTransparency"] = 1
G2L["13"]["BackgroundTransparency"] = 1
G2L["13"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["13"]["Image"] = "rbxassetid://80999662900595"
G2L["13"]["AutomaticSize"] = Enum.AutomaticSize.Y
G2L["13"]["Size"] = UDim2.new(1, -7, 0, 0)
G2L["13"]["Name"] = "Template"

G2L["14"] = Instance.new("ImageLabel", G2L["13"])
G2L["14"]["BorderSizePixel"] = 0
G2L["14"]["SliceCenter"] = Rect.new(512, 512, 512, 512)
G2L["14"]["SliceScale"] = 0.01758
G2L["14"]["ScaleType"] = Enum.ScaleType.Slice
G2L["14"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["14"]["ImageTransparency"] = 0.75
G2L["14"]["Image"] = "rbxassetid://95071123641270"
G2L["14"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["14"]["Visible"] = false
G2L["14"]["BackgroundTransparency"] = 1
G2L["14"]["Name"] = "Outline"

G2L["15"] = Instance.new("CanvasGroup", G2L["13"])
G2L["15"]["BorderSizePixel"] = 0
G2L["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["15"]["AutomaticSize"] = Enum.AutomaticSize.Y
G2L["15"]["Size"] = UDim2.new(1, 0, 0, 0)
G2L["15"]["Name"] = "Content"
G2L["15"]["BackgroundTransparency"] = 1

G2L["16"] = Instance.new("UIListLayout", G2L["15"])
G2L["16"]["Padding"] = UDim.new(0, 9)
G2L["16"]["VerticalAlignment"] = Enum.VerticalAlignment.Center
G2L["16"]["SortOrder"] = Enum.SortOrder.LayoutOrder
G2L["16"]["FillDirection"] = Enum.FillDirection.Horizontal

G2L["17"] = Instance.new("UIPadding", G2L["15"])
G2L["17"]["PaddingTop"] = UDim.new(0, 5)
G2L["17"]["PaddingRight"] = UDim.new(0, 9)
G2L["17"]["PaddingLeft"] = UDim.new(0, 9)
G2L["17"]["PaddingBottom"] = UDim.new(0, 5)

G2L["18"] = Instance.new("ImageLabel", G2L["15"])
G2L["18"]["BorderSizePixel"] = 0
G2L["18"]["SliceCenter"] = Rect.new(256, 256, 256, 256)
G2L["18"]["SliceScale"] = 0.0332
G2L["18"]["ScaleType"] = Enum.ScaleType.Slice
G2L["18"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["18"]["ImageColor3"] = Color3.fromRGB(78, 33, 255)
G2L["18"]["Image"] = "rbxassetid://80999662900595"
G2L["18"]["Size"] = UDim2.new(0, 26, 0, 26)
G2L["18"]["BackgroundTransparency"] = 1
G2L["18"]["Name"] = "Icon"

G2L["19"] = Instance.new("ImageLabel", G2L["18"])
G2L["19"]["BorderSizePixel"] = 0
G2L["19"]["SliceCenter"] = Rect.new(512, 512, 512, 512)
G2L["19"]["SliceScale"] = 0.0166
G2L["19"]["ScaleType"] = Enum.ScaleType.Slice
G2L["19"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["19"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["19"]["Image"] = "rbxassetid://95071123641270"
G2L["19"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["19"]["BackgroundTransparency"] = 1
G2L["19"]["Name"] = "Outline"
G2L["19"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["1a"] = Instance.new("Frame", G2L["18"])
G2L["1a"]["BorderSizePixel"] = 0
G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["1a"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["1a"]["Size"] = UDim2.new(0.61538, 0, 0.61538, 0)
G2L["1a"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["1a"]["Name"] = "Content"
G2L["1a"]["BackgroundTransparency"] = 1

G2L["1b"] = Instance.new("ImageLabel", G2L["1a"])
G2L["1b"]["BorderSizePixel"] = 0
G2L["1b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["1b"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["1b"]["Image"] = "rbxassetid://117906088481880"
G2L["1b"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["1b"]["BackgroundTransparency"] = 1
G2L["1b"]["Name"] = "Icon"
G2L["1b"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["1c"] = Instance.new("TextLabel", G2L["15"])
G2L["1c"]["BorderSizePixel"] = 0
G2L["1c"]["TextSize"] = 14
G2L["1c"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["1c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["1c"]["FontFace"] = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
G2L["1c"]["TextColor3"] = Color3.fromRGB(123, 123, 123)
G2L["1c"]["BackgroundTransparency"] = 1
G2L["1c"]["Size"] = UDim2.new(1, -35, 0, 0)
G2L["1c"]["Text"] = "Example"
G2L["1c"]["LayoutOrder"] = 1
G2L["1c"]["AutomaticSize"] = Enum.AutomaticSize.Y
G2L["1c"]["Name"] = "Title"

G2L["1d"] = Instance.new("UIPadding", G2L["1c"])
G2L["1d"]["PaddingTop"] = UDim.new(0, 5)
G2L["1d"]["PaddingBottom"] = UDim.new(0, 5)

G2L["1e"] = Instance.new("UIListLayout", G2L["e"])
G2L["1e"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center
G2L["1e"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["1f"] = Instance.new("UIListLayout", G2L["d"])
G2L["1f"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center
G2L["1f"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["20"] = Instance.new("CanvasGroup", G2L["c"])
G2L["20"]["BorderSizePixel"] = 0
G2L["20"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["20"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["20"]["Size"] = UDim2.new(0.65, 0, 1, 0)
G2L["20"]["Position"] = UDim2.new(0.67599, 0, 0.54891, 0)
G2L["20"]["Name"] = "Tab"
G2L["20"]["BackgroundTransparency"] = 1

G2L["21"] = Instance.new("ImageLabel", G2L["20"])
G2L["21"]["ZIndex"] = 3
G2L["21"]["BorderSizePixel"] = 0
G2L["21"]["SliceCenter"] = Rect.new(256, 256, 256, 256)
G2L["21"]["SliceScale"] = 0.03516
G2L["21"]["ScaleType"] = Enum.ScaleType.Slice
G2L["21"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["21"]["ImageTransparency"] = 0.95
G2L["21"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["21"]["Image"] = "rbxassetid://80999662900595"
G2L["21"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["21"]["BackgroundTransparency"] = 1
G2L["21"]["Name"] = "Background"
G2L["21"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["22"] = Instance.new("UIPadding", G2L["20"])
G2L["22"]["PaddingRight"] = UDim.new(0, 7)
G2L["22"]["PaddingLeft"] = UDim.new(0, 7)
G2L["22"]["PaddingBottom"] = UDim.new(0, 7)

G2L["23"] = Instance.new("Frame", G2L["20"])
G2L["23"]["BorderSizePixel"] = 0
G2L["23"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["23"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["23"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["23"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["23"]["Name"] = "Content"
G2L["23"]["BackgroundTransparency"] = 1

G2L["24"] = Instance.new("Frame", G2L["23"])
G2L["24"]["BorderSizePixel"] = 0
G2L["24"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["24"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["24"]["Size"] = UDim2.new(1, 0, 0.6, 0)
G2L["24"]["Position"] = UDim2.new(0.5, 0, 0.3, 0)
G2L["24"]["Name"] = "Code"
G2L["24"]["BackgroundTransparency"] = 1

G2L["25"] = Instance.new("ScrollingFrame", G2L["24"])
G2L["25"]["Active"] = true
G2L["25"]["BorderSizePixel"] = 0
G2L["25"]["CanvasSize"] = UDim2.new(0, 0, 0, 0)
G2L["25"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["25"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["25"]["AutomaticCanvasSize"] = Enum.AutomaticSize.XY
G2L["25"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["25"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["25"]["ScrollBarThickness"] = 4
G2L["25"]["BackgroundTransparency"] = 1

G2L["26"] = Instance.new("Frame", G2L["25"])
G2L["26"]["BorderSizePixel"] = 0
G2L["26"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["26"]["AutomaticSize"] = Enum.AutomaticSize.Y
G2L["26"]["Size"] = UDim2.new(0.10256, 0, 1, 0)
G2L["26"]["Name"] = "list"
G2L["26"]["BackgroundTransparency"] = 1

G2L["27"] = Instance.new("TextLabel", G2L["26"])
G2L["27"]["BorderSizePixel"] = 0
G2L["27"]["TextSize"] = 14
G2L["27"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["27"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["27"]["FontFace"] = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
G2L["27"]["TextColor3"] = Color3.fromRGB(123, 123, 123)
G2L["27"]["BackgroundTransparency"] = 1
G2L["27"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["27"]["Text"] = "1"
G2L["27"]["LayoutOrder"] = 1
G2L["27"]["AutomaticSize"] = Enum.AutomaticSize.XY
G2L["27"]["Name"] = "Number"
G2L["27"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["27"]["Visible"] = false

G2L["28"] = Instance.new("UIPadding", G2L["27"])
G2L["28"]["PaddingTop"] = UDim.new(0, 10)

G2L["29"] = Instance.new("UIListLayout", G2L["26"])
G2L["29"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center
G2L["29"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["2a"] = Instance.new("UIListLayout", G2L["25"])
G2L["2a"]["SortOrder"] = Enum.SortOrder.LayoutOrder
G2L["2a"]["FillDirection"] = Enum.FillDirection.Horizontal

G2L["2b"] = Instance.new("Frame", G2L["25"])
G2L["2b"]["BorderSizePixel"] = 0
G2L["2b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["2b"]["AutomaticSize"] = Enum.AutomaticSize.XY
G2L["2b"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["2b"]["Name"] = "Code"
G2L["2b"]["BackgroundTransparency"] = 1

G2L["2c"] = Instance.new("TextLabel", G2L["2b"])
G2L["2c"]["BorderSizePixel"] = 0
G2L["2c"]["TextSize"] = 14
G2L["2c"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["2c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["2c"]["FontFace"] = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
G2L["2c"]["TextColor3"] = Color3.fromRGB(123, 123, 123)
G2L["2c"]["BackgroundTransparency"] = 1
G2L["2c"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["2c"]["Text"] = ""
G2L["2c"]["LayoutOrder"] = 1
G2L["2c"]["AutomaticSize"] = Enum.AutomaticSize.XY
G2L["2c"]["Name"] = "Text"
G2L["2c"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["2d"] = Instance.new("UIPadding", G2L["2c"])
G2L["2d"]["PaddingTop"] = UDim.new(0, 10)

G2L["2e"] = Instance.new("UIListLayout", G2L["2b"])
G2L["2e"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["2f"] = Instance.new("Frame", G2L["23"])
G2L["2f"]["BorderSizePixel"] = 0
G2L["2f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["2f"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["2f"]["Size"] = UDim2.new(1, 0, 0.4, 0)
G2L["2f"]["Position"] = UDim2.new(0.5, 0, 0.8, 0)
G2L["2f"]["Name"] = "Buttons"
G2L["2f"]["LayoutOrder"] = 1
G2L["2f"]["BackgroundTransparency"] = 1

G2L["30"] = Instance.new("ScrollingFrame", G2L["2f"])
G2L["30"]["Active"] = true
G2L["30"]["BorderSizePixel"] = 0
G2L["30"]["CanvasSize"] = UDim2.new(0, 0, 0, 0)
G2L["30"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["30"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["30"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y
G2L["30"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["30"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["30"]["ScrollBarThickness"] = 4
G2L["30"]["BackgroundTransparency"] = 1

G2L["31"] = Instance.new("UIGridLayout", G2L["30"])
G2L["31"]["CellSize"] = UDim2.new(0, 72, 0, 30)
G2L["31"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["32"] = Instance.new("UIPadding", G2L["30"])
G2L["32"]["PaddingTop"] = UDim.new(0, 5)
G2L["32"]["PaddingLeft"] = UDim.new(0, 5)

G2L["33"] = Instance.new("ImageLabel", G2L["30"])
G2L["33"]["BorderSizePixel"] = 0
G2L["33"]["SliceCenter"] = Rect.new(256, 256, 256, 256)
G2L["33"]["SliceScale"] = 0.02
G2L["33"]["ScaleType"] = Enum.ScaleType.Slice
G2L["33"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["33"]["ImageTransparency"] = 0.9
G2L["33"]["Image"] = "rbxassetid://80999662900595"
G2L["33"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["33"]["BackgroundTransparency"] = 1
G2L["33"]["Name"] = "Template"
G2L["33"]["Visible"] = false

G2L["34"] = Instance.new("ImageLabel", G2L["33"])
G2L["34"]["BorderSizePixel"] = 0
G2L["34"]["SliceCenter"] = Rect.new(512, 512, 512, 512)
G2L["34"]["SliceScale"] = 0.01
G2L["34"]["ScaleType"] = Enum.ScaleType.Slice
G2L["34"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["34"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["34"]["Image"] = "rbxassetid://95071123641270"
G2L["34"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["34"]["BackgroundTransparency"] = 1
G2L["34"]["Name"] = "Outline"
G2L["34"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["35"] = Instance.new("CanvasGroup", G2L["33"])
G2L["35"]["BorderSizePixel"] = 0
G2L["35"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["35"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["35"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["35"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["35"]["BackgroundTransparency"] = 1

G2L["36"] = Instance.new("TextLabel", G2L["35"])
G2L["36"]["BorderSizePixel"] = 0
G2L["36"]["TextSize"] = 12
G2L["36"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["36"]["FontFace"] = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
G2L["36"]["TextColor3"] = Color3.fromRGB(123, 123, 123)
G2L["36"]["BackgroundTransparency"] = 1
G2L["36"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["36"]["Size"] = UDim2.new(1, 0, 0, 0)
G2L["36"]["Text"] = "Button"
G2L["36"]["LayoutOrder"] = 1
G2L["36"]["AutomaticSize"] = Enum.AutomaticSize.Y
G2L["36"]["Name"] = "Title"
G2L["36"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["37"] = Instance.new("UIListLayout", G2L["23"])
G2L["37"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["38"] = Instance.new("UIListLayout", G2L["c"])
G2L["38"]["SortOrder"] = Enum.SortOrder.LayoutOrder
G2L["38"]["FillDirection"] = Enum.FillDirection.Horizontal

G2L["39"] = Instance.new("UIListLayout", G2L["a"])
G2L["39"]["SortOrder"] = Enum.SortOrder.LayoutOrder

G2L["3a"] = Instance.new("CanvasGroup", G2L["a"])
G2L["3a"]["BorderSizePixel"] = 0
G2L["3a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["3a"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["3a"]["Size"] = UDim2.new(1, 0, 0.11468, 0)
G2L["3a"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["3a"]["Name"] = "Topbar"
G2L["3a"]["BackgroundTransparency"] = 1

G2L["3b"] = Instance.new("UIListLayout", G2L["3a"])
G2L["3b"]["Padding"] = UDim.new(0, 8)
G2L["3b"]["VerticalAlignment"] = Enum.VerticalAlignment.Center
G2L["3b"]["SortOrder"] = Enum.SortOrder.LayoutOrder
G2L["3b"]["FillDirection"] = Enum.FillDirection.Horizontal

G2L["3c"] = Instance.new("UIPadding", G2L["3a"])
G2L["3c"]["PaddingTop"] = UDim.new(0, 0)
G2L["3c"]["PaddingRight"] = UDim.new(0, 8)
G2L["3c"]["PaddingLeft"] = UDim.new(0, 8)
G2L["3c"]["PaddingBottom"] = UDim.new(0, 0)

G2L["3d"] = Instance.new("Frame", G2L["3a"])
G2L["3d"]["BorderSizePixel"] = 0
G2L["3d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["3d"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["3d"]["AutomaticSize"] = Enum.AutomaticSize.XY
G2L["3d"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["3d"]["Name"] = "Center"
G2L["3d"]["LayoutOrder"] = 1
G2L["3d"]["BackgroundTransparency"] = 1

G2L["3e"] = Instance.new("UIPadding", G2L["3d"])
G2L["3e"]["PaddingLeft"] = UDim.new(0, 0)

G2L["3f"] = Instance.new("UIListLayout", G2L["3d"])
G2L["3f"]["Padding"] = UDim.new(0, 4)
G2L["3f"]["VerticalAlignment"] = Enum.VerticalAlignment.Center
G2L["3f"]["SortOrder"] = Enum.SortOrder.LayoutOrder
G2L["3f"]["FillDirection"] = Enum.FillDirection.Horizontal

G2L["40"] = Instance.new("Frame", G2L["3d"])
G2L["40"]["BorderSizePixel"] = 0
G2L["40"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["40"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["40"]["AutomaticSize"] = Enum.AutomaticSize.XY
G2L["40"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["40"]["Name"] = "Title"
G2L["40"]["LayoutOrder"] = 1
G2L["40"]["BackgroundTransparency"] = 1

G2L["41"] = Instance.new("TextLabel", G2L["40"])
G2L["41"]["BorderSizePixel"] = 0
G2L["41"]["TextSize"] = 13
G2L["41"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["41"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["41"]["FontFace"] = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
G2L["41"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["41"]["BackgroundTransparency"] = 1
G2L["41"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["41"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["41"]["Text"] = "Jaownai | Simple Spy Custom"
G2L["41"]["AutomaticSize"] = Enum.AutomaticSize.XY
G2L["41"]["Name"] = "Title"
G2L["41"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["42"] = Instance.new("UIListLayout", G2L["40"])
G2L["42"]["SortOrder"] = Enum.SortOrder.LayoutOrder
G2L["42"]["FillDirection"] = Enum.FillDirection.Horizontal
G2L["42"]["VerticalAlignment"] = Enum.VerticalAlignment.Center
G2L["42"]["Padding"] = UDim.new(0, 6)

G2L["44"] = Instance.new("Frame", G2L["3a"])
G2L["44"]["BorderSizePixel"] = 0
G2L["44"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["44"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["44"]["AutomaticSize"] = Enum.AutomaticSize.XY
G2L["44"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["44"]["Name"] = "Left"
G2L["44"]["BackgroundTransparency"] = 1

G2L["45"] = Instance.new("UIListLayout", G2L["44"])
G2L["45"]["SortOrder"] = Enum.SortOrder.LayoutOrder
G2L["45"]["FillDirection"] = Enum.FillDirection.Horizontal

G2L["46"] = Instance.new("Frame", G2L["44"])
G2L["46"]["BorderSizePixel"] = 0
G2L["46"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["46"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["46"]["Size"] = UDim2.new(0, 24, 0, 24)
G2L["46"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["46"]["Name"] = "Close"
G2L["46"]["BackgroundTransparency"] = 1

G2L["47"] = Instance.new("ImageButton", G2L["46"])
G2L["47"]["BorderSizePixel"] = 0
G2L["47"]["BackgroundTransparency"] = 1
G2L["47"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["47"]["ImageColor3"] = Color3.fromRGB(245, 106, 96)
G2L["47"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["47"]["Image"] = "rbxassetid://80999662900595"
G2L["47"]["Size"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["47"]["Name"] = "Icon"
G2L["47"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["4b"] = Instance.new("Frame", G2L["44"])
G2L["4b"]["BorderSizePixel"] = 0
G2L["4b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["4b"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["4b"]["Size"] = UDim2.new(0, 24, 0, 24)
G2L["4b"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["4b"]["Name"] = "Hide"
G2L["4b"]["LayoutOrder"] = 1
G2L["4b"]["BackgroundTransparency"] = 1

G2L["4c"] = Instance.new("ImageButton", G2L["4b"])
G2L["4c"]["BorderSizePixel"] = 0
G2L["4c"]["BackgroundTransparency"] = 1
G2L["4c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["4c"]["ImageColor3"] = Color3.fromRGB(245, 202, 73)
G2L["4c"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["4c"]["Image"] = "rbxassetid://80999662900595"
G2L["4c"]["Size"] = UDim2.new(0.58333, 0, 0.58333, 0)
G2L["4c"]["Name"] = "Icon"
G2L["4c"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["50"] = Instance.new("Frame", G2L["44"])
G2L["50"]["BorderSizePixel"] = 0
G2L["50"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["50"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["50"]["Size"] = UDim2.new(0, 24, 0, 24)
G2L["50"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["50"]["Name"] = "Minimize"
G2L["50"]["LayoutOrder"] = 2
G2L["50"]["BackgroundTransparency"] = 1

G2L["51"] = Instance.new("ImageButton", G2L["50"])
G2L["51"]["BorderSizePixel"] = 0
G2L["51"]["BackgroundTransparency"] = 1
G2L["51"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["51"]["ImageColor3"] = Color3.fromRGB(97, 200, 99)
G2L["51"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["51"]["Image"] = "rbxassetid://80999662900595"
G2L["51"]["Size"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["51"]["Name"] = "Icon"
G2L["51"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

G2L["55"] = Instance.new("ImageLabel", G2L["3"])
G2L["55"]["ZIndex"] = 999
G2L["55"]["BorderSizePixel"] = 0
G2L["55"]["SliceCenter"] = Rect.new(256, 256, 256, 256)
G2L["55"]["SliceScale"] = 0.0625
G2L["55"]["ScaleType"] = Enum.ScaleType.Slice
G2L["55"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["55"]["ImageTransparency"] = 0.65
G2L["55"]["ImageColor3"] = Color3.fromRGB(0, 0, 0)
G2L["55"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["55"]["Image"] = "rbxassetid://80999662900595"
G2L["55"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["55"]["Visible"] = false
G2L["55"]["BackgroundTransparency"] = 1
G2L["55"]["Name"] = "Active"
G2L["55"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

local Storage = Instance.new("Folder")

local SimpleSpy3    = G2L["1"]
local Background    = G2L["3"]
local TopBar        = G2L["3a"]
local LeftPanel     = G2L["d"]
local LogList       = G2L["10"]
local UIListLayout  = G2L["11"]
local RightPanel    = G2L["20"]
local CodeBox       = G2L["24"]
local ScrollingFrame = G2L["30"]
local UIGridLayout  = G2L["31"]
local CloseButton   = G2L["47"]
local MaximizeButton = G2L["4c"]
local MinimizeButton = G2L["51"]
local RemoteTemplate = G2L["13"]
local ButtonTemplate = G2L["33"]

local Simple = Instance.new("TextButton")
Simple.Size = UDim2.new(1, 0, 1, 0)
Simple.BackgroundTransparency = 1
Simple.Text = ""
Simple.ZIndex = 10
Simple.AutoButtonColor = false
Simple.Parent = G2L["40"]

local ToolTip = Instance.new("Frame")
ToolTip.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
ToolTip.BackgroundTransparency = 0.1
ToolTip.BorderColor3 = Color3.new(1, 1, 1)
ToolTip.Size = UDim2.new(0, 200, 0, 50)
ToolTip.ZIndex = 100
ToolTip.Visible = false
ToolTip.Parent = SimpleSpy3

local TextLabel = Instance.new("TextLabel")
TextLabel.BackgroundTransparency = 1
TextLabel.Position = UDim2.new(0, 2, 0, 2)
TextLabel.Size = UDim2.new(0, 196, 0, 46)
TextLabel.ZIndex = 100
TextLabel.Font = Enum.Font.SourceSans
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.TextSize = 14
TextLabel.TextWrapped = true
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.TextYAlignment = Enum.TextYAlignment.Top
TextLabel.Parent = ToolTip

RemoteTemplate.Visible = false
ButtonTemplate.Visible = false

local layoutOrderNum = 999999999
local closed = false
local sideClosed = false
local maximized = false
local logs = {}
local selected = nil
local blacklist = {}
local blocklist = {}
local connectedRemotes = {}
local toggle = false
local prevTables = {}
local remoteLogs = {}
getgenv().SIMPLESPYCONFIG_MaxRemotes = 300
local indent = 4
local scheduled = {}
local schedulerconnect
local SimpleSpy = {}
local topstr = ""
local bottomstr = ""
local codebox
local getnilrequired = false
local history = {}
local excluding = {}
local connections = {}
local DecompiledScripts = {}
local generation = {}
local running_threads = {}
local originalnamecall

local remoteEvent = Instance.new("RemoteEvent", Storage)
local remoteFunction = Instance.new("RemoteFunction", Storage)
local GetDebugIdHandler = Instance.new("BindableFunction", Storage)

local originalEvent = remoteEvent.FireServer
local originalFunction = remoteFunction.InvokeServer
local GetDebugIDInvoke = GetDebugIdHandler.Invoke

function GetDebugIdHandler.OnInvoke(obj)
    return OldDebugId(obj)
end

local function ThreadGetDebugId(obj)
    return GetDebugIDInvoke(GetDebugIdHandler, obj)
end

local synv3 = false
if syn and identifyexecutor then
    local _, version = identifyexecutor()
    if version and version:sub(1, 2) == "v3" then synv3 = true end
end

xpcall(function()
    if isfile and readfile and isfolder and makefolder then
        local cachedconfigs = isfile("SimpleSpy//Settings.json") and jsond(readfile("SimpleSpy//Settings.json"))
        if cachedconfigs then
            for i, v in next, realconfigs do
                if cachedconfigs[i] == nil then cachedconfigs[i] = v end
            end
            realconfigs = cachedconfigs
        end
        if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
        if not isfolder("SimpleSpy//Assets") then makefolder("SimpleSpy//Assets") end
        if not isfile("SimpleSpy//Settings.json") then writefile("SimpleSpy//Settings.json", jsone(realconfigs)) end
        configsmetatable.__newindex = function(self, index, newindex)
            realconfigs[index] = newindex
            writefile("SimpleSpy//Settings.json", jsone(realconfigs))
        end
    else
        configsmetatable.__newindex = function(self, index, newindex)
            realconfigs[index] = newindex
        end
    end
end, function(err)
    ErrorPrompt(("An error has occured: (%s)"):format(err))
end)

local function logthread(thread)
    table.insert(running_threads, thread)
end

function clean()
    local max = getgenv().SIMPLESPYCONFIG_MaxRemotes
    if not typeof(max) == "number" and math.floor(max) ~= max then max = 500 end
    if #remoteLogs > max then
        for i = 100, #remoteLogs do
            local v = remoteLogs[i]
            if typeof(v[1]) == "RBXScriptConnection" then v[1]:Disconnect() end
            if typeof(v[2]) == "Instance" then v[2]:Destroy() end
        end
        local newLogs = {}
        for i = 1, 100 do table.insert(newLogs, remoteLogs[i]) end
        remoteLogs = newLogs
    end
end

local function ThreadIsNotDead(thread)
    return not status(thread) == "dead"
end

function scaleToolTip()
    local size = TextService:GetTextSize(TextLabel.Text, TextLabel.TextSize, TextLabel.Font, Vector2.new(196, math.huge))
    TextLabel.Size = UDim2.new(0, size.X, 0, size.Y)
    ToolTip.Size = UDim2.new(0, size.X + 4, 0, size.Y + 4)
end

function onToggleButtonHover()
    if not toggle then
        TweenService:Create(G2L["41"], TweenInfo.new(0.5), { TextColor3 = Color3.fromRGB(252, 51, 51) }):Play()
    else
        TweenService:Create(G2L["41"], TweenInfo.new(0.5), { TextColor3 = Color3.fromRGB(68, 206, 91) }):Play()
    end
end

function onToggleButtonUnhover()
    TweenService:Create(G2L["41"], TweenInfo.new(0.5), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end

function onToggleButtonClick()
    if toggle then
        TweenService:Create(G2L["41"], TweenInfo.new(0.5), { TextColor3 = Color3.fromRGB(252, 51, 51) }):Play()
    else
        TweenService:Create(G2L["41"], TweenInfo.new(0.5), { TextColor3 = Color3.fromRGB(68, 206, 91) }):Play()
    end
    toggleSpyMethod()
end

function bringBackOnResize()
    local currentX = Background.AbsolutePosition.X
    local currentY = Background.AbsolutePosition.Y
    local viewportSize = workspace.CurrentCamera.ViewportSize
    currentX = math.clamp(currentX, 0, viewportSize.X - Background.AbsoluteSize.X)
    currentY = math.clamp(currentY, 0, viewportSize.Y - Background.AbsoluteSize.Y)
    TweenService:Create(Background, TweenInfo.new(0.1), { Position = UDim2.new(0, currentX, 0, currentY) }):Play()
end

function connectResize()
    if not workspace.CurrentCamera then
        workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
    end
    local lastCam = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(bringBackOnResize)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        lastCam:Disconnect()
        lastCam = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(bringBackOnResize)
    end)
end

local dragging = false
local dragOffset = Vector2.zero
local resizing = false
local resizeStart = Vector2.zero
local resizeStartSz = Vector2.zero

G2L["7"].MouseButton1Down:Connect(function()
    local abs = Background.AbsolutePosition
    Background.AnchorPoint = Vector2.zero
    Background.Position = UDim2.fromOffset(abs.X, abs.Y)
    dragging = true
    dragOffset = abs - UserInputService:GetMouseLocation()
end)

G2L["3a"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local abs = Background.AbsolutePosition
        Background.AnchorPoint = Vector2.zero
        Background.Position = UDim2.fromOffset(abs.X, abs.Y)
        dragging = true
        dragOffset = abs - UserInputService:GetMouseLocation()
    end
end)

G2L["6"].MouseButton1Down:Connect(function()
    local abs = Background.AbsolutePosition
    Background.AnchorPoint = Vector2.zero
    Background.Position = UDim2.fromOffset(abs.X, abs.Y)
    resizing = true
    resizeStart = UserInputService:GetMouseLocation()
    resizeStartSz = Background.AbsoluteSize
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if dragging then
        local mp = UserInputService:GetMouseLocation()
        local vp = workspace.CurrentCamera.ViewportSize
        local x = math.clamp(mp.X + dragOffset.X, 0, vp.X - Background.AbsoluteSize.X)
        local y = math.clamp(mp.Y + dragOffset.Y, 0, vp.Y - Background.AbsoluteSize.Y)
        Background.Position = UDim2.fromOffset(x, y)
    elseif resizing then
        local delta = UserInputService:GetMouseLocation() - resizeStart
        local newW = math.max(resizeStartSz.X + delta.X, 420)
        local newH = math.max(resizeStartSz.Y + delta.Y, 260)
        Background.Size = UDim2.fromOffset(newW, newH)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        resizing = false
    end
end)

function toggleSideTray(override)
    if maximized then return end
    sideClosed = not sideClosed
    TweenService:Create(RightPanel, TweenInfo.new(0.3), {
        GroupTransparency = sideClosed and 1 or 0
    }):Play()
    RightPanel.Interactable = not sideClosed
end

function toggleMinimize(override)
    if maximized then return end
    closed = not closed
    TweenService:Create(G2L["c"], TweenInfo.new(0.3), {
        GroupTransparency = closed and 1 or 0
    }):Play()
    G2L["c"].Interactable = not closed
end

function getPlayerFromInstance(instance)
    for _, v in next, Players:GetPlayers() do
        if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then
            return v
        end
    end
end

function eventSelect(frame)
    if selected and selected.Log then
        if selected.Button then
            local outline = selected.Button:FindFirstChild("Outline")
            if outline then
                TweenService:Create(selected.Button, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
                outline.Visible = false
            end
        end
        selected = nil
    end
    for _, v in next, logs do
        if frame == v.Log then selected = v end
    end
    if selected and selected.Log then
        local outline = frame:FindFirstChild("Outline")
        if outline then
            outline.Visible = true
            TweenService:Create(frame, TweenInfo.new(0.3), { ImageTransparency = 0.75 }):Play()
        end
        codebox:setRaw(selected.GenScript)
    end
    if sideClosed then toggleSideTray() end
end

function makeToolTip(enable, text)
    if enable and text then
        if ToolTip.Visible then
            ToolTip.Visible = false
            local tt = connections["ToolTip"]
            if tt then tt:Disconnect() end
        end
        local first = true
        connections["ToolTip"] = RunService.RenderStepped:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()
            local topLeft = mousePos + Vector2.new(20, -15)
            local bottomRight = topLeft + ToolTip.AbsoluteSize
            local vp = workspace.CurrentCamera.ViewportSize
            if topLeft.X < 0 then topLeft = Vector2.new(0, topLeft.Y)
            elseif bottomRight.X > vp.X then topLeft = Vector2.new(vp.X - ToolTip.AbsoluteSize.X, topLeft.Y) end
            if topLeft.Y < 0 then topLeft = Vector2.new(topLeft.X, 0)
            elseif bottomRight.Y > vp.Y - 35 then topLeft = Vector2.new(topLeft.X, vp.Y - ToolTip.AbsoluteSize.Y - 35) end
            if topLeft.X <= mousePos.X and topLeft.Y <= mousePos.Y then
                topLeft = Vector2.new(mousePos.X - ToolTip.AbsoluteSize.X - 2, mousePos.Y - ToolTip.AbsoluteSize.Y - 2)
            end
            if first then
                ToolTip.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
                first = false
            else
                ToolTip:TweenPosition(UDim2.fromOffset(topLeft.X, topLeft.Y), "Out", "Linear", 0.1)
            end
        end)
        TextLabel.Text = text
        TextLabel.TextScaled = true
        ToolTip.Visible = true
    else
        if ToolTip.Visible then
            ToolTip.Visible = false
            local tt = connections["ToolTip"]
            if tt then tt:Disconnect() end
        end
    end
end

function newButton(name, description, onClick)
    local btn = ButtonTemplate:Clone()
    btn.Visible = true
    btn.Name = "Btn_" .. name

    local lbl = btn:FindFirstChild("CanvasGroup") and btn.CanvasGroup:FindFirstChild("Title")
    if lbl then lbl.Text = name end

    local click = Instance.new("TextButton")
    click.Size = UDim2.new(1, 0, 1, 0)
    click.BackgroundTransparency = 1
    click.Text = ""
    click.ZIndex = btn.ZIndex + 5
    click.Parent = btn

    click.MouseEnter:Connect(function()
        makeToolTip(true, description())
        TweenService:Create(btn, TweenInfo.new(0.15), { ImageTransparency = 0.75 }):Play()
    end)
    click.MouseLeave:Connect(function()
        makeToolTip(false)
        TweenService:Create(btn, TweenInfo.new(0.15), { ImageTransparency = 0.9 }):Play()
    end)
    btn.AncestryChanged:Connect(function() makeToolTip(false) end)
    click.MouseButton1Click:Connect(function(...)
        logthread(running())
        onClick(btn, ...)
    end)

    btn.Parent = ScrollingFrame
end

local Icons = {
    RemoteEvent      = "rbxassetid://76849082320169",
    RemoteFunction   = "rbxassetid://109202898110957",
    BindableEvent    = "rbxassetid://98849709807755",
    BindableFunction = "rbxassetid://96448937828710",
}

local IconColors = {
    RemoteEvent      = Color3.fromRGB(78, 33, 255),
    RemoteFunction   = Color3.fromRGB(33, 150, 243),
    BindableEvent    = Color3.fromRGB(255, 140, 0),
    BindableFunction = Color3.fromRGB(0, 180, 120),
}

function newRemote(type, data)
    if layoutOrderNum < 1 then layoutOrderNum = 999999999 end
    local remote = data.remote
    local callingscript = data.callingscript

    local item = RemoteTemplate:Clone()
    item.Visible = true
    item.LayoutOrder = layoutOrderNum
    item.Name = "Remote_" .. layoutOrderNum

    local className = remote.ClassName
    local iconFrame = item:FindFirstChild("Content") and item.Content:FindFirstChild("Icon")
    if iconFrame then
        iconFrame.ImageColor3 = IconColors[className] or IconColors.RemoteEvent
        iconFrame.BackgroundTransparency = 1
        local innerIcon = iconFrame:FindFirstChild("Content") and iconFrame.Content:FindFirstChild("Icon")
        if innerIcon then
            innerIcon.Image = Icons[className] or Icons.RemoteEvent
            innerIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    local titleLabel = item:FindFirstChild("Content") and item.Content:FindFirstChild("Title")
    if titleLabel then titleLabel.Text = remote.Name end

    local log = {
        Name = remote.Name,
        Function = data.infofunc or "--Function Info is disabled",
        Remote = remote,
        DebugId = data.id,
        metamethod = data.metamethod,
        args = data.args,
        Log = item,
        Button = item,
        Blocked = data.blocked,
        Source = callingscript,
        returnvalue = data.returnvalue,
        GenScript = "-- Generating, please wait...\n-- (If this message persists, the remote args are likely extremely long)"
    }

    logs[#logs + 1] = log

    item.MouseEnter:Connect(function()
        if item ~= (selected and selected.Log) then
            TweenService:Create(item, TweenInfo.new(0.15), { ImageTransparency = 0.85 }):Play()
        end
    end)
    item.MouseLeave:Connect(function()
        if item ~= (selected and selected.Log) then
            TweenService:Create(item, TweenInfo.new(0.15), { ImageTransparency = 1 }):Play()
        end
    end)

    local connect = item.MouseButton1Click:Connect(function()
        logthread(running())
        eventSelect(item)
        log.GenScript = genScript(log.Remote, log.args)
        if data.blocked then
            log.GenScript = "-- THIS REMOTE WAS PREVENTED FROM FIRING TO THE SERVER BY SIMPLESPY\n\n" .. log.GenScript
        end
        if selected == log and item then
            eventSelect(item)
        end
    end)

    layoutOrderNum -= 1
    table.insert(remoteLogs, 1, { connect, item })
    item.Parent = LogList
    clean()
end

function genScript(remote, args)
    prevTables = {}
    local gen = ""
    if #args > 0 then
        xpcall(function()
            gen = v2v({ args = args }) .. "\n"
        end, function(err)
            gen ..= "-- An error has occured:\n--" .. err .. "\n-- TableToString failure!\nlocal args = {"
            xpcall(function()
                for i, v in next, args do
                    if type(i) ~= "Instance" and type(i) ~= "userdata" then
                        gen = gen .. "\n    [object] = "
                    elseif type(i) == "string" then
                        gen = gen .. '\n    ["' .. i .. '"] = '
                    elseif type(i) == "userdata" and typeof(i) ~= "Instance" then
                        gen = gen .. "\n    [" .. string.format("nil --[[%s]]", typeof(v)) .. ")] = "
                    elseif type(i) == "userdata" then
                        gen = gen .. "\n    [game." .. i:GetFullName() .. ")] = "
                    end
                    if type(v) ~= "Instance" and type(v) ~= "userdata" then
                        gen = gen .. "object"
                    elseif type(v) == "string" then
                        gen = gen .. '"' .. v .. '"'
                    elseif type(v) == "userdata" and typeof(v) ~= "Instance" then
                        gen = gen .. string.format("nil --[[%s]]", typeof(v))
                    elseif type(v) == "userdata" then
                        gen = gen .. "game." .. v:GetFullName()
                    end
                end
                gen ..= "\n}\n\n"
            end, function()
                gen ..= "}\n-- Legacy tableToString failure!"
            end)
        end)
        if not remote:IsDescendantOf(game) and not getnilrequired then
            gen = "function getNil(name,class) for _,v in next, getnilinstances()do if v.ClassName==class and v.Name==name then return v;end end end\n\n" .. gen
        end
        if remote:IsA("RemoteEvent") then
            gen ..= v2s(remote) .. ":FireServer(unpack(args))"
        elseif remote:IsA("RemoteFunction") then
            gen = gen .. v2s(remote) .. ":InvokeServer(unpack(args))"
        end
    else
        if remote:IsA("RemoteEvent") then
            gen ..= v2s(remote) .. ":FireServer()"
        elseif remote:IsA("RemoteFunction") then
            gen ..= v2s(remote) .. ":InvokeServer()"
        end
    end
    prevTables = {}
    return gen
end

local CustomGeneration = {
    Vector3 = (function()
        local temp = {}
        for i, v in Vector3 do
            if type(v) == "vector" then temp[v] = `Vector3.{i}` end
        end
        return temp
    end)(),
    Vector2 = (function()
        local temp = {}
        for i, v in Vector2 do
            if type(v) == "userdata" then temp[v] = `Vector2.{i}` end
        end
        return temp
    end)(),
    CFrame = { [CFrame.identity] = "CFrame.identity" }
}

local number_table = {
    ["inf"] = "math.huge",
    ["-inf"] = "-math.huge",
    ["nan"] = "0/0"
}

local ufunctions
ufunctions = {
    TweenInfo = function(u)
        return `TweenInfo.new({u.Time}, {u.EasingStyle}, {u.EasingDirection}, {u.RepeatCount}, {u.Reverses}, {u.DelayTime})`
    end,
    Ray = function(u)
        return `Ray.new({ufunctions["Vector3"](u.Origin)}, {ufunctions["Vector3"](u.Direction)})`
    end,
    BrickColor = function(u) return `BrickColor.new({u.Number})` end,
    NumberRange = function(u) return `NumberRange.new({u.Min}, {u.Max})` end,
    Region3 = function(u)
        local c = u.CFrame.Position
        local hs = u.Size / 2
        return `Region3.new({ufunctions["Vector3"](c - hs)}, {ufunctions["Vector3"](c + hs)})`
    end,
    Faces = function(u)
        local faces = {}
        if u.Top then table.insert(faces, "Top") end
        if u.Bottom then table.insert(faces, "Enum.NormalId.Bottom") end
        if u.Left then table.insert(faces, "Enum.NormalId.Left") end
        if u.Right then table.insert(faces, "Enum.NormalId.Right") end
        if u.Back then table.insert(faces, "Enum.NormalId.Back") end
        if u.Front then table.insert(faces, "Enum.NormalId.Front") end
        return `Faces.new({table.concat(faces, ", ")})`
    end,
    EnumItem = function(u) return tostring(u) end,
    Enums = function(u) return "Enum" end,
    Enum = function(u) return `Enum.{u}` end,
    Vector3 = function(u) return CustomGeneration.Vector3[u] or `Vector3.new({u})` end,
    Vector2 = function(u) return CustomGeneration.Vector2[u] or `Vector2.new({u})` end,
    CFrame = function(u) return CustomGeneration.CFrame[u] or `CFrame.new({table.concat({u:GetComponents()}, ", ")})` end,
    PathWaypoint = function(u) return `PathWaypoint.new({ufunctions["Vector3"](u.Position)}, {u.Action}, "{u.Label}")` end,
    UDim = function(u) return `UDim.new({u})` end,
    UDim2 = function(u) return `UDim2.new({u})` end,
    Rect = function(u) return `Rect.new({ufunctions["Vector2"](u.Min)}, {ufunctions["Vector2"](u.Max)})` end,
    Color3 = function(u) return `Color3.new({u.R}, {u.G}, {u.B})` end,
    RBXScriptSignal = function(u) return "RBXScriptSignal --[[not supported]]" end,
    RBXScriptConnection = function(u) return "RBXScriptConnection --[[not supported]]" end,
}

local typeofv2sfunctions = {
    number = function(v) local n = tostring(v); return number_table[n] or n end,
    boolean = function(v) return tostring(v) end,
    string = function(v, l) return formatstr(v, l) end,
    ["function"] = function(v) return f2s(v) end,
    table = function(v, l, p, n, vtv, i, pt, path, tables, tI)
        return t2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    end,
    Instance = function(v) return i2p(v, generation[OldDebugId(v)]) end,
    userdata = function(v)
        if configs.advancedinfo then
            return getrawmetatable(v) and "newproxy(true)" or "newproxy(false)"
        end
        return "newproxy(true)"
    end
}

local typev2sfunctions = {
    userdata = function(v, vtypeof)
        if ufunctions[vtypeof] then return ufunctions[vtypeof](v) end
        return `{vtypeof}({rawtostring(v)}) --[[Generation Failure]]`
    end,
    vector = ufunctions["Vector3"]
}

function v2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    local vtypeof = typeof(v)
    local vtypeoffunc = typeofv2sfunctions[vtypeof]
    local vtypefunc = typev2sfunctions[type(v)]
    if not tI then tI = { 0 } else tI[1] += 1 end
    if vtypeoffunc then return vtypeoffunc(v, l, p, n, vtv, i, pt, path, tables, tI)
    elseif vtypefunc then return vtypefunc(v, vtypeof) end
    return `{vtypeof}({rawtostring(v)}) --[[Generation Failure]]`
end

function v2v(t)
    topstr = ""
    bottomstr = ""
    getnilrequired = false
    local ret = ""
    local count = 1
    for i, v in next, t do
        if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. i .. " = " .. v2s(v, nil, nil, i, true) .. "\n"
        elseif rawtostring(i):match("^[%a_]+[%w_]*$") then
            local name = lower(rawtostring(i)) .. "_" .. rawtostring(count)
            ret = ret .. "local " .. name .. " = " .. v2s(v, nil, nil, name, true) .. "\n"
        else
            local name = type(v) .. "_" .. rawtostring(count)
            ret = ret .. "local " .. name .. " = " .. v2s(v, nil, nil, name, true) .. "\n"
        end
        count = count + 1
    end
    if getnilrequired then
        topstr = "function getNil(name,class) for _,v in next, getnilinstances() do if v.ClassName==class and v.Name==name then return v;end end end\n" .. topstr
    end
    if #topstr > 0 then ret = topstr .. "\n" .. ret end
    if #bottomstr > 0 then ret = ret .. bottomstr end
    return ret
end

function t2s(t, l, p, n, vtv, i, pt, path, tables, tI)
    local globalIndex = table.find(getgenv(), t)
    if type(globalIndex) == "string" then return globalIndex end
    if not tI then tI = { 0 } end
    path = path or ""
    if not l then l = 0; tables = {} end
    p = p or t
    for _, v in next, tables do
        if n and rawequal(v, t) then
            bottomstr = bottomstr .. "\n" .. rawtostring(n) .. rawtostring(path) .. " = " .. rawtostring(n) .. rawtostring(({ v2p(v, p) })[2])
            return "{} --[[DUPLICATE]]"
        end
    end
    table.insert(tables, t)
    local s = "{"
    local size = 0
    l += indent
    for k, v in next, t do
        size = size + 1
        if size > (getgenv().SimpleSpyMaxTableSize or 1000) then
            s = s .. "\n" .. string.rep(" ", l) .. "-- MAXIMUM TABLE SIZE REACHED"
            break
        end
        if rawequal(k, t) then
            bottomstr ..= `\n{n}{path}[{n}{path}] = {(rawequal(v, k) and `{n}{path}` or v2s(v, l, p, n, vtv, k, t, `{path}[{n}{path}]`, tables))}`
            size -= 1
            continue
        end
        local currentPath
        if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then
            currentPath = "." .. k
        else
            currentPath = "[" .. v2s(k, l, p, n, vtv, k, t, path, tables, tI) .. "]"
        end
        if size % 100 == 0 then scheduleWait() end
        s = s .. "\n" .. string.rep(" ", l) .. "[" .. v2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. "] = " .. v2s(v, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. ","
    end
    if #s > 1 then s = s:sub(1, #s - 1) end
    if size > 0 then s = s .. "\n" .. string.rep(" ", l - indent) end
    return s .. "}"
end

function f2s(f)
    for k, x in next, getgenv() do
        local isgucci, gpath
        if rawequal(x, f) then
            isgucci, gpath = true, ""
        elseif type(x) == "table" then
            isgucci, gpath = v2p(f, x)
        end
        if isgucci and type(k) ~= "function" then
            if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then
                return k .. gpath
            else
                return "getgenv()[" .. v2s(k) .. "]" .. gpath
            end
        end
    end
    if configs.funcEnabled then
        local funcname = info(f, "n")
        if funcname and funcname:match("^[%a_]+[%w_]*$") then
            return `function {funcname}() end -- Function Called: {funcname}`
        end
    end
    return tostring(f)
end

function i2p(i, customgen)
    if customgen then return customgen end
    local player = getplayer(i)
    local parent = i
    local out = ""
    if parent == nil then return "nil" end
    if player then
        while true do
            if parent and parent == player.Character then
                if player == Players.LocalPlayer then
                    return 'game:GetService("Players").LocalPlayer.Character' .. out
                else
                    return i2p(player) .. ".Character" .. out
                end
            else
                if parent.Name:match("[%a_]+[%w+]*") ~= parent.Name then
                    out = ':FindFirstChild(' .. formatstr(parent.Name) .. ')' .. out
                else
                    out = "." .. parent.Name .. out
                end
            end
            task.wait()
            parent = parent.Parent
        end
    elseif parent ~= game then
        while true do
            if parent and parent.Parent == game then
                if SafeGetService(parent.ClassName) then
                    if lower(parent.ClassName) == "workspace" then
                        return `workspace{out}`
                    else
                        return 'game:GetService("' .. parent.ClassName .. '")' .. out
                    end
                else
                    if parent.Name:match("[%a_]+[%w_]*") then
                        return "game." .. parent.Name .. out
                    else
                        return 'game:FindFirstChild(' .. formatstr(parent.Name) .. ')' .. out
                    end
                end
            elseif not parent.Parent then
                getnilrequired = true
                return 'getNil(' .. formatstr(parent.Name) .. ', "' .. parent.ClassName .. '")' .. out
            else
                if parent.Name:match("[%a_]+[%w_]*") ~= parent.Name then
                    out = ':WaitForChild(' .. formatstr(parent.Name) .. ')' .. out
                else
                    out = ':WaitForChild("' .. parent.Name .. '")' .. out
                end
            end
            if i:IsDescendantOf(Players.LocalPlayer) then
                return 'game:GetService("Players").LocalPlayer' .. out
            end
            parent = parent.Parent
            task.wait()
        end
    else
        return "game"
    end
end

function getplayer(instance)
    for _, v in next, Players:GetPlayers() do
        if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then
            return v
        end
    end
end

function v2p(x, t, path, prev)
    path = path or ""
    prev = prev or {}
    if rawequal(x, t) then return true, "" end
    for i, v in next, t do
        if rawequal(v, x) then
            if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                return true, path .. "." .. i
            else
                return true, path .. "[" .. v2s(i) .. "]"
            end
        end
        if type(v) == "table" then
            local dup = false
            for _, y in next, prev do
                if rawequal(y, v) then dup = true; break end
            end
            if not dup then
                table.insert(prev, t)
                local found, p2 = v2p(x, v, path, prev)
                if found then
                    if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                        return true, "." .. i .. p2
                    else
                        return true, "[" .. v2s(i) .. "]" .. p2
                    end
                end
            end
        end
    end
    return false, ""
end

function formatstr(s, indentation)
    indentation = indentation or 0
    local handled, reachedMax = handlespecials(s, indentation)
    return '"' .. handled .. '"' .. (reachedMax and " --[[ MAXIMUM STRING SIZE REACHED ]]" or "")
end

local function isFinished(coroutines)
    for _, v in next, coroutines do
        if status(v) == "running" then return false end
    end
    return true
end

local specialstrings = {
    ["\n"] = function(thread, index) resume(thread, index, "\\n") end,
    ["\t"] = function(thread, index) resume(thread, index, "\\t") end,
    ["\\"] = function(thread, index) resume(thread, index, "\\\\") end,
    ['"'] = function(thread, index) resume(thread, index, '\\"') end,
}

function handlespecials(s, indentation)
    local i = 0
    local n = 1
    local coroutines = {}
    local coroutineFunc = function(i, r)
        s = s:sub(0, i - 1) .. r .. s:sub(i + 1, -1)
    end
    local timeout = 0
    repeat
        i += 1
        if timeout >= 10 then task.wait(); timeout = 0 end
        local char = s:sub(i, i)
        if byte(char) then
            timeout += 1
            local c = create(coroutineFunc)
            table.insert(coroutines, c)
            local specialfunc = specialstrings[char]
            if specialfunc then
                specialfunc(c, i)
                i += 1
            elseif byte(char) > 126 or byte(char) < 32 then
                resume(c, i, "\\" .. byte(char))
                i += #rawtostring(byte(char))
            end
            if i >= n * 100 then
                local extra = string.format('" ..\n%s"', string.rep(" ", indentation + indent))
                s = s:sub(0, i) .. extra .. s:sub(i + 1, -1)
                i += #extra
                n += 1
            end
        end
    until char == "" or i > (getgenv().SimpleSpyMaxStringSize or 10000)
    while not isFinished(coroutines) do RunService.Heartbeat:Wait() end
    clear(coroutines)
    if i > (getgenv().SimpleSpyMaxStringSize or 10000) then
        s = string.sub(s, 0, getgenv().SimpleSpyMaxStringSize or 10000)
        return s, true
    end
    return s, false
end

function schedule(f, ...)
    table.insert(scheduled, { f, ... })
end

function scheduleWait()
    local thread = running()
    schedule(function() resume(thread) end)
    yield()
end

local function taskscheduler()
    if not toggle then scheduled = {}; return end
    if #scheduled > SIMPLESPYCONFIG_MaxRemotes + 100 then
        table.remove(scheduled, #scheduled)
    end
    if #scheduled > 0 then
        local currentf = scheduled[1]
        table.remove(scheduled, 1)
        if type(currentf) == "table" and type(currentf[1]) == "function" then
            pcall(unpack(currentf))
        end
    end
end

local function tablecheck(tbl, instance, id)
    return tbl[id] or tbl[instance.Name]
end

function remoteHandler(data)
    if configs.autoblock then
        local id = data.id
        if excluding[id] then return end
        if not history[id] then history[id] = { badOccurances = 0, lastCall = tick() } end
        if tick() - history[id].lastCall < 1 then
            history[id].badOccurances += 1
            return
        else
            history[id].badOccurances = 0
        end
        if history[id].badOccurances > 3 then excluding[id] = true; return end
        history[id].lastCall = tick()
    end
    if data.remote:IsA("RemoteEvent") and lower(data.method) == "fireserver" then
        newRemote("event", data)
    elseif data.remote:IsA("RemoteFunction") and lower(data.method) == "invokeserver" then
        newRemote("function", data)
    end
end

local newindex = function(method, originalfunction, ...)
    if typeof(...) == "Instance" then
        local remote = cloneref(...)
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if not configs.logcheckcaller and checkcaller() then return originalfunction(...) end
            local id = ThreadGetDebugId(remote)
            local blockcheck = tablecheck(blocklist, remote, id)
            local args = { select(2, ...) }
            if not tablecheck(blacklist, remote, id) and not IsCyclicTable(args) then
                local data = {
                    method = method,
                    remote = remote,
                    args = deepclone(args),
                    infofunc = nil,
                    callingscript = nil,
                    metamethod = "__index",
                    blockcheck = blockcheck,
                    id = id,
                    returnvalue = {}
                }
                args = nil
                if configs.funcEnabled then
                    data.infofunc = info(2, "f")
                    local calling = getcallingscript()
                    data.callingscript = calling and cloneref(calling) or nil
                end
                schedule(remoteHandler, data)
            end
            if blockcheck then return end
        end
    end
    return originalfunction(...)
end

local newnamecall = newcclosure(function(...)
    local method = getnamecallmethod()
    if method and (method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer") then
        if typeof(...) == "Instance" then
            local remote = cloneref(...)
            if IsA(remote, "RemoteEvent") or IsA(remote, "RemoteFunction") then
                if not configs.logcheckcaller and checkcaller() then return originalnamecall(...) end
                local id = ThreadGetDebugId(remote)
                local blockcheck = tablecheck(blocklist, remote, id)
                local args = { select(2, ...) }
                if not tablecheck(blacklist, remote, id) and not IsCyclicTable(args) then
                    local data = {
                        method = method,
                        remote = remote,
                        args = deepclone(args),
                        infofunc = nil,
                        callingscript = nil,
                        metamethod = "__namecall",
                        blockcheck = blockcheck,
                        id = id,
                        returnvalue = {}
                    }
                    args = nil
                    if configs.funcEnabled then
                        data.infofunc = info(2, "f")
                        local calling = getcallingscript()
                        data.callingscript = calling and cloneref(calling) or nil
                    end
                    schedule(remoteHandler, data)
                end
                if blockcheck then return end
            end
        end
    end
    return originalnamecall(...)
end)

local newFireServer = newcclosure(function(...)
    return newindex("FireServer", originalEvent, ...)
end)

local newInvokeServer = newcclosure(function(...)
    return newindex("InvokeServer", originalFunction, ...)
end)

local function disablehooks()
    if synv3 then
        unhook(getrawmetatable(game).__namecall, originalnamecall)
        unhook(Instance.new("RemoteEvent").FireServer, originalEvent)
        unhook(Instance.new("RemoteFunction").InvokeServer, originalFunction)
        restorefunction(originalnamecall)
        restorefunction(originalEvent)
        restorefunction(originalFunction)
    else
        if hookmetamethod then
            hookmetamethod(game, "__namecall", originalnamecall)
        else
            hookfunction(getrawmetatable(game).__namecall, originalnamecall)
        end
        hookfunction(Instance.new("RemoteEvent").FireServer, originalEvent)
        hookfunction(Instance.new("RemoteFunction").InvokeServer, originalFunction)
    end
end

function toggleSpy()
    if not toggle then
        local oldnamecall
        if synv3 then
            oldnamecall = hook(getrawmetatable(game).__namecall, clonefunction(newnamecall))
            originalEvent = hook(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
            originalFunction = hook(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
        else
            if hookmetamethod then
                oldnamecall = hookmetamethod(game, "__namecall", clonefunction(newnamecall))
            else
                oldnamecall = hookfunction(getrawmetatable(game).__namecall, clonefunction(newnamecall))
            end
            originalEvent = hookfunction(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
            originalFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
        end
        originalnamecall = originalnamecall or function(...) return oldnamecall(...) end
    else
        disablehooks()
    end
end

function toggleSpyMethod()
    toggleSpy()
    toggle = not toggle
end

local function shutdown()
    if schedulerconnect then schedulerconnect:Disconnect() end
    for _, connection in next, connections do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    for _, v in next, running_threads do
        if ThreadIsNotDead(v) then close(v) end
    end
    clear(running_threads)
    clear(connections)
    clear(logs)
    clear(remoteLogs)
    disablehooks()
    SimpleSpy3:Destroy()
    Storage:Destroy()
    getgenv().SimpleSpyExecuted = false
end

local Highlight = (isfile and loadfile and isfile("Highlight.lua") and loadfile("Highlight.lua")()) or loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/Highlight.lua"))()

if not getgenv().SimpleSpyExecuted then
    local succeeded, err = pcall(function()
        if not RunService:IsClient() then
            error("SimpleSpy cannot run on the server!")
        end
        getgenv().SimpleSpyShutdown = shutdown
        onToggleButtonClick()
        if not hookmetamethod then
            ErrorPrompt("Simple Spy will not function to its fullest due to your executor not supporting hookmetamethod.", true)
        end
        codebox = Highlight.new(CodeBox)
        logthread(spawn(function()
            local suc, res = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/78n/SimpleSpy/main/UpdateLog.lua")
            codebox:setRaw((suc and res) or "")
        end))
        getgenv().SimpleSpy = SimpleSpy
        getgenv().getNil = function(name, class)
            for _, v in next, getnilinstances() do
                if v.ClassName == class and v.Name == name then return v end
            end
        end
        TextLabel:GetPropertyChangedSignal("Text"):Connect(scaleToolTip)
        MinimizeButton.MouseButton1Click:Connect(toggleSideTray)
        MaximizeButton.MouseButton1Click:Connect(toggleMinimize)
        Simple.MouseButton1Click:Connect(onToggleButtonClick)
        Simple.MouseEnter:Connect(onToggleButtonHover)
        Simple.MouseLeave:Connect(onToggleButtonUnhover)
        CloseButton.MouseButton1Click:Connect(shutdown)
        connectResize()
        SimpleSpy3.Enabled = true
        logthread(spawn(function()
            delay(1, onToggleButtonUnhover)
        end))
        schedulerconnect = RunService.Heartbeat:Connect(taskscheduler)
        SimpleSpy3.Parent = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(SimpleSpy3)) or CoreGui
        logthread(spawn(function()
            local lp = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
            generation = {
                [OldDebugId(lp)] = 'game:GetService("Players").LocalPlayer',
                [OldDebugId(lp:GetMouse())] = 'game:GetService("Players").LocalPlayer:GetMouse',
                [OldDebugId(game)] = "game",
                [OldDebugId(workspace)] = "workspace"
            }
        end))
    end)
    if succeeded then
        getgenv().SimpleSpyExecuted = true
    else
        shutdown()
        ErrorPrompt("An error has occured:\n" .. rawtostring(err))
        return
    end
else
    SimpleSpy3:Destroy()
    return
end

function SimpleSpy:newButton(name, description, onClick)
    return newButton(name, description, onClick)
end

newButton("Copy Code", function() return "Click to copy code" end, function()
    setclipboard(codebox:getString())
    TextLabel.Text = "Copied successfully!"
end)

newButton("Copy Remote", function() return "Click to copy the path of the remote" end, function()
    if selected and selected.Remote then
        setclipboard(v2s(selected.Remote))
        TextLabel.Text = "Copied!"
    end
end)

newButton("Run Code", function() return "Click to execute code" end, function()
    local Remote = selected and selected.Remote
    if Remote then
        TextLabel.Text = "Executing..."
        xpcall(function()
            local returnvalue
            if Remote:IsA("RemoteEvent") then
                returnvalue = Remote:FireServer(unpack(selected.args))
            else
                returnvalue = Remote:InvokeServer(unpack(selected.args))
            end
            TextLabel.Text = ("Executed!\n%s"):format(v2s(returnvalue))
        end, function(err)
            TextLabel.Text = ("Error!\n%s"):format(err)
        end)
        return
    end
    TextLabel.Text = "Source not found"
end)

newButton("Get Script", function() return "Click to copy calling script\nWARNING: Not super reliable" end, function()
    if selected then
        if not selected.Source then
            selected.Source = rawget(getfenv(selected.Function), "script")
        end
        setclipboard(v2s(selected.Source))
        TextLabel.Text = "Done!"
    end
end)

newButton("Func Info", function() return "Click to view calling function information" end, function()
    local func = selected and selected.Function
    if func then
        local typeoffunc = typeof(func)
        if typeoffunc ~= "string" then
            codebox:setRaw("--[[Generating Function Info]]")
            RunService.Heartbeat:Wait()
            local lclosure = islclosure(func)
            local SourceScript = rawget(getfenv(func), "script")
            local CallingScript = selected.Source or nil
            local funcinfo = {
                info = getinfo(func),
                constants = lclosure and deepclone(getconstants(func)) or "N/A",
                upvalues = deepclone(getupvalues(func)),
                script = {
                    SourceScript = SourceScript or "nil",
                    CallingScript = CallingScript or "nil"
                }
            }
            if configs.advancedinfo then
                local Remote = selected.Remote
                funcinfo["advancedinfo"] = {
                    Metamethod = selected.metamethod,
                    DebugId = {
                        SourceScriptDebugId = SourceScript and typeof(SourceScript) == "Instance" and OldDebugId(SourceScript) or "N/A",
                        CallingScriptDebugId = CallingScript and typeof(SourceScript) == "Instance" and OldDebugId(CallingScript) or "N/A",
                        RemoteDebugId = OldDebugId(Remote)
                    },
                    Protos = lclosure and getprotos(func) or "N/A"
                }
                if Remote:IsA("RemoteFunction") then
                    funcinfo["advancedinfo"]["OnClientInvoke"] = getcallbackmember and (getcallbackmember(Remote, "OnClientInvoke") or "N/A") or "N/A"
                elseif getconnections then
                    funcinfo["advancedinfo"]["OnClientEvents"] = {}
                    for i, v in next, getconnections(Remote.OnClientEvent) do
                        funcinfo["advancedinfo"]["OnClientEvents"][i] = {
                            Function = v.Function or "N/A",
                            State = v.State or "N/A"
                        }
                    end
                end
            end
            codebox:setRaw("--[[Converting table]]")
            selected.Function = v2v({ functionInfo = funcinfo })
        end
        codebox:setRaw("-- Calling function info\n-- Generated by SimpleSpy\n\n" .. selected.Function)
        TextLabel.Text = "Done!"
    else
        TextLabel.Text = "Error! Function not found."
    end
end)

newButton("Clr Logs", function() return "Click to clear logs" end, function()
    TextLabel.Text = "Clearing..."
    clear(logs)
    for _, v in next, LogList:GetChildren() do
        if not v:IsA("UIListLayout") and not v:IsA("UIPadding") and v ~= RemoteTemplate then
            v:Destroy()
        end
    end
    codebox:setRaw("")
    selected = nil
    TextLabel.Text = "Logs cleared!"
end)

newButton("Excl (i)", function() return "Click to exclude this Remote by ID." end, function()
    if selected then
        blacklist[OldDebugId(selected.Remote)] = true
        TextLabel.Text = "Excluded!"
    end
end)

newButton("Excl (n)", function() return "Click to exclude all remotes with this name." end, function()
    if selected then
        blacklist[selected.Name] = true
        TextLabel.Text = "Excluded!"
    end
end)

newButton("Clr Excl", function() return "Click to clear the exclusion list." end, function()
    blacklist = {}
    TextLabel.Text = "Exclusion list cleared!"
end)

newButton("Block (i)", function() return "Click to stop this remote from firing." end, function()
    if selected then
        blocklist[OldDebugId(selected.Remote)] = true
        TextLabel.Text = "Blocked!"
    end
end)

newButton("Block (n)", function() return "Click to stop remotes with this name from firing." end, function()
    if selected then
        blocklist[selected.Name] = true
        TextLabel.Text = "Blocked!"
    end
end)

newButton("Clr Block", function() return "Click to stop blocking remotes." end, function()
    blocklist = {}
    TextLabel.Text = "Blocklist cleared!"
end)

newButton("Decompile", function() return "Decompile source script" end, function()
    if decompile then
        if selected and selected.Source then
            local Source = selected.Source
            if not DecompiledScripts[Source] then
                codebox:setRaw("--[[Decompiling]]")
                xpcall(function()
                    local decompiledsource = decompile(Source):gsub("-- Decompiled with the Synapse X Luau decompiler.", "")
                    local Sourcev2s = v2s(Source)
                    if decompiledsource:find("script") and Sourcev2s then
                        DecompiledScripts[Source] = ("local script = %s\n%s"):format(Sourcev2s, decompiledsource)
                    end
                end, function(err)
                    return codebox:setRaw(("--[[\nError\n%s\n]]"):format(err))
                end)
            end
            codebox:setRaw(DecompiledScripts[Source] or "--No Source Found")
            TextLabel.Text = "Done!"
        else
            TextLabel.Text = "Source not found!"
        end
    else
        TextLabel.Text = "Missing function (decompile)"
    end
end)

newButton("Func Toggle", function()
    return string.format("[%s] Toggle function info", configs.funcEnabled and "ON" or "OFF")
end, function()
    configs.funcEnabled = not configs.funcEnabled
    TextLabel.Text = string.format("[%s] Function info", configs.funcEnabled and "ON" or "OFF")
end)

newButton("Autoblock", function()
    return string.format("[%s] Auto-block spammy remotes", configs.autoblock and "ON" or "OFF")
end, function()
    configs.autoblock = not configs.autoblock
    TextLabel.Text = string.format("[%s] Autoblock", configs.autoblock and "ON" or "OFF")
    history = {}
    excluding = {}
end)

newButton("LogCaller", function()
    return ("[%s] Log client-fired remotes"):format(configs.logcheckcaller and "ON" or "OFF")
end, function()
    configs.logcheckcaller = not configs.logcheckcaller
    TextLabel.Text = ("[%s] LogCaller"):format(configs.logcheckcaller and "ON" or "OFF")
end)

newButton("Adv Info", function()
    return ("[%s] Advanced remote info"):format(configs.advancedinfo and "ON" or "OFF")
end, function()
    configs.advancedinfo = not configs.advancedinfo
    TextLabel.Text = ("[%s] Advanced Info"):format(configs.advancedinfo and "ON" or "OFF")
end)

newButton("Discord", function() return "Copy SimpleSpy Discord invite" end, function()
    setclipboard("https://discord.gg/U8VMBKvG5t")
    TextLabel.Text = "Copied invite!"
    if request then
        request({ Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST", Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" }, Body = http:JSONEncode({ cmd = "INVITE_BROWSER", nonce = http:GenerateGUID(false), args = { code = "AWS6ez9" } }) })
    end
end)
