return (function(...)
    local w = "Quantum Onyx Project"
    if type(L) == "table" then
        L["Title"] = w
    end
    if L["SaveFile"] and (type(L["SaveFile"]) == "string" and L["SaveFile"] ~= "") then
        X = c:GetFileName(L["SaveFile"])
        c["Settings"] = {}
        c:Load()
    else
        if not X then
            X = c:GetFileName()
            c:Load()
        end
    end
    local B = L["Subtitle"] or "Untitled"
    local v = L["Version"] or "v1.0"
    local b = L["Theme"] or "Purple"
    local P = L["Credits"] or {}
    local O = {}
    function O.IsDeveloperBuild()
        local e = string["lower"](tostring(v))
        return (e == "developer" or e == "v.developer") or string["find"](e, "developer", 1, true) ~= nil
    end
    local I = u["Themes"][b] or u["Themes"]["Purple"]
    u["Current"] = I
    function ParseKeySetting(e)
        if e == true then
            return true, nil
        end
        if type(e) ~= "table" then
            return false, nil
        end
        local d, L = false, nil
        for e, C in ipairs(e) do
            if C == true then
                d = true
            elseif type(C) == "string" then
                L = C
            end
        end
        return d, L
    end
    local m, f = ParseKeySetting(L["Key"])
    local l = f == "Full"
    local F = {}
    local D = {}
    local K = nil
    local q = false
    local Q = false
    local S = L["Intro"] ~= false
    function LoadKeyValid()
        local e = c["FolderName"] .. "/Key.json"
        if not isfolder(c["FolderName"]) or not isfile(e) then
            return false
        end
        local d, L = pcall(function() return JsonDecode(readfile(e)) end)
        if not d or type(L) ~= "table" then
            return false
        end
        if type(L["key"]) ~= "string" or L["key"] == "" then
            return false
        end
        return L["verified"] == true
    end
    local x = m and LoadKeyValid() or false
    function O.HasKeyAccess()
        if not m then
            return true
        end
        return x
    end
    local y
    function O.CreateDummy()
        local e = {}
        setmetatable(e, {["__index"] = function(d, L) return function() return e end end})
        return e
    end
    y = O["CreateDummy"]()
    function checkCondition(e)
        if e == nil then
            return true
        end
        if type(e) == "function" then
            local d, L = pcall(e)
            return d and L
        end
        if type(e) == "table" and type(e["fn"]) == "function" then
            local d, L = pcall(e["fn"])
            if not (d and L) then
                return false
            end
            return true
        end
        return not (not e)
    end
    function IsFullLocked()
        return m and (l and (not x and not Q))
    end
    function RefreshKeyLock()
        if not x then
            q = false
            return
        end
        if q then
            return
        end
        q = true
        if l and K then
            K["Visible"] = false
        end
        for e, d in ipairs(F) do
            local L = d["frame"]
            if L and L["Parent"] then
                local e = d["blocker"]
                if e and e["Parent"] then
                    e:Destroy()
                end
                for e, d in ipairs(L:GetChildren()) do
                    if d:IsA("ImageLabel") and d["Image"] == "rbxassetid://7733992528" then
                        d:Destroy()
                    end
                end
                L["BackgroundTransparency"] = 0.4
                local C = L:FindFirstChild("AccentBar")
                if C then
                    C["BackgroundTransparency"] = 0
                end
            end
        end
        task["defer"](function() for e, d in ipairs(D) do pcall(function() if d["saveKey"] then local e = c:Get(d["saveKey"], nil); if e ~= nil then c["Settings"][d["saveKey"]] = e end end; if d["UpdateFn"] then d["UpdateFn"]() end end); if e % 12 == 0 then task["wait"]() end end end)
    end
    function RegisterKeyLocked(d, L)
        if not m or not L then
            return
        end
        if O["HasKeyAccess"]() then
            return
        end
        d["BackgroundTransparency"] = 0.55
        local C = d:FindFirstChild("AccentBar")
        if C then
            C["BackgroundTransparency"] = 0.8
        end
        for e, d in ipairs(d:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                if (d["Name"] == "ButtonLabel" or d["Name"] == "ToggleTitle") or d["Name"] == "SliderTitle" then
                    d["TextColor3"] = Color3["fromRGB"](130, 110, 160)
                end
            end
        end
        A("ImageLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0), ["Position"] = UDim2["new"](1, -6, 0, 6), ["Size"] = UDim2["new"](0, 11, 0, 11), ["Image"] = "rbxassetid://7733992528", ["ImageColor3"] = Color3["fromRGB"](140, 110, 190), ["ImageTransparency"] = 0.3, ["ZIndex"] = 10}, d)
        local w = A("TextButton", {["Name"] = "_KeyBlocker", ["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Text"] = "", ["ZIndex"] = 10, ["AutoButtonColor"] = false}, d)
        w["Activated"]:Connect(function() e["Notification"]:Notify({["Title"] = "Key Required", ["Description"] = "Verify your key in the Key System panel to unlock this feature."}, {["Time"] = 3}) end)
        table["insert"](F, {["frame"] = d, ["blocker"] = w})
    end
    local r = {["body"] = nil, ["accentElements"] = {}, ["litGradients"] = {}, ["buttonGradients"] = {}}
    local i, R, H, M
    M = {["List"] = c:Get("_favorites", {}), ["Entries"] = {}, ["Refresh"] = nil}
    function ApplyTheme(e)
        local L = u["Themes"][e]
        if not L then
            return
        end
        u["Current"] = L
        c:Save("_activeTheme", e)
        if r["body"] then
            d:Tween(r["body"], {["BackgroundColor3"] = L["Body"]}, 0.28, Enum["EasingStyle"]["Quint"])
        end
        for e, C in ipairs(r["accentElements"]) do
            local w, U, B = C[1], C[2], C[3]
            local h = L[B] or L["Accent"]
            if w and w["Parent"] then
                d:Tween(w, {[U] = h}, 0.28, Enum["EasingStyle"]["Quint"])
            end
        end
        for e, d in ipairs(r["litGradients"]) do
            if d and d["Parent"] then
                d["Color"] = L["Lit"]
            end
        end
        for e, d in ipairs(r["buttonGradients"]) do
            if d and d["Parent"] then
                d["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, L["AccentLight"]), ColorSequenceKeypoint["new"](1, L["AccentDark"])})
            end
        end
        pcall(function() if R then local e = R:FindFirstChildOfClass("UIStroke"); if e then e["Color"] = L["Accent"] end end; for e, d in ipairs(i or {}) do if d["tabUnderline"] then d["tabUnderline"]["BackgroundColor3"] = L["Accent"] end end; if TopFrame then  end end)
    end
    function RegisterThemeElement(e, d, L)
        table["insert"](r["accentElements"], {e, d, L or "Accent"})
    end
    function RegisterLitGradient(e)
        table["insert"](r["litGradients"], e)
    end
    function RegisterButtonGradient(e)
        table["insert"](r["buttonGradients"], e)
    end
    function CreateAccentBar(e, d)
        d = d or {}
        local L = A("Frame", {["Name"] = "AccentBar", ["BackgroundColor3"] = (ThemeColor("Accent") or d["Color"]) or Color3["fromRGB"](192, 132, 252), ["BackgroundTransparency"] = d["Transparency"] or 0, ["BorderSizePixel"] = 0, ["AnchorPoint"] = Vector2["new"](0, 0.5), ["Position"] = UDim2["new"](0, 0, 0.5, 0), ["Size"] = d["Size"] or UDim2["new"](0, 2, 0, 14), ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, e)
        if d["Gradient"] then
            local e = A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, ThemeColor("AccentLight") or Color3["fromRGB"](216, 180, 254)), ColorSequenceKeypoint["new"](1, ThemeColor("AccentDark") or Color3["fromRGB"](139, 92, 246))}), ["Rotation"] = d["Gradient"] and d["Gradient"]["Rotation"] or 90}, L)
            RegisterButtonGradient(e)
        end
        RegisterThemeElement(L, "BackgroundColor3", "Accent")
        return L
    end
    local p = A("ScreenGui", {["Name"] = g(), ["ZIndexBehavior"] = Enum["ZIndexBehavior"]["Sibling"]}, o)
    local G = U["TouchEnabled"] and not U["KeyboardEnabled"]
    local E = G and 0.45 or 0.5
    local V = 1.8
    local n = G and 0.7 or 1
    local ex = 0.05
    local dx = A("UIScale", {["Name"] = "LibraryUIScale", ["Scale"] = n}, p)
    local Lx = {}
    function UnscaledLayout(e)
        local d = dx["Scale"]
        if d == 0 then
            return e
        end
        return e / d
    end
    function FitScrollCanvas(e, d, L, C)
        if not e or not d then
            return
        end
        C = C or 4
        L = L or "Y"
        local w = L == "X" and d["AbsoluteContentSize"]["X"] or d["AbsoluteContentSize"]["Y"]
        local U = L == "X" and e["AbsoluteSize"]["X"] or e["AbsoluteSize"]["Y"]
        if U < 2 then
            U = L == "X" and e["Size"]["X"]["Offset"] or e["Size"]["Y"]["Offset"]
        end
        w = UnscaledLayout(w)
        U = UnscaledLayout(math["max"](U, 0))
        if w > 0 then
            w = w + C
        end
        local B = math["max"](w, 0)
        local h = w > U + 1
        if L == "X" then
            e["CanvasSize"] = UDim2["new"](0, B, 0, 0)
            if not h then
                e["CanvasPosition"] = Vector2["new"](0, e["CanvasPosition"]["Y"])
            end
        else
            e["CanvasSize"] = UDim2["new"](0, 0, 0, B)
            if not h then
                e["CanvasPosition"] = Vector2["new"](e["CanvasPosition"]["X"], 0)
            end
        end
        e["ScrollingEnabled"] = true
        pcall(function() e["ElasticBehavior"] = h and Enum["ElasticBehavior"]["WhenScrollable"] or Enum["ElasticBehavior"]["Never"] end)
    end
    local Cx = {}
    local wx = false
    function DebouncedFitScrollCanvas(e, d, L, C)
        if not e or not d then
            return
        end
        Cx[e] = {["layout"] = d, ["axis"] = L or "Y", ["pad"] = C or 2}
        if not wx then
            wx = true
            task["defer"](function() wx = false; for e, d in pairs(Cx) do Cx[e] = nil; FitScrollCanvas(e, d["layout"], d["axis"], d["pad"]) end end)
        end
    end
    function RegisterLayoutRefresh(e)
        table["insert"](Lx, e)
    end
    function ScaledFontSize(e, d)
        local L = dx["Scale"]
        if L <= 0 then
            L = 1
        end
        if L < 1 then
            return math["max"](math["floor"](e * L), 4), 1
        end
        local C = math["min"](math["floor"]((L - 1) * 10 + 0.5), 6)
        return math["min"](e + C, 18), 1
    end
    function MakeTextConstraint(e, d)
        local L = select(1, ScaledFontSize(e, d))
        local C = A("UITextSizeConstraint", {["MaxTextSize"] = L, ["MinTextSize"] = 1})
        RegisterLayoutRefresh(function() local L = select(1, ScaledFontSize(e, d)); C["MaxTextSize"] = L; C["MinTextSize"] = 1 end)
        return C
    end
    function BindScaledText(e, d)
        RegisterLayoutRefresh(function() e["TextSize"] = select(1, ScaledFontSize(d)) end)
    end
    local Ux = false
    function RefreshAllLayouts()
        for e, d in ipairs(Lx) do
            pcall(d)
        end
    end
    function ScheduleRefreshAllLayouts()
        if Ux then
            return
        end
        Ux = true
        task["defer"](function() Ux = false; RefreshAllLayouts() end)
    end
    function O.SetUIScalePreview(d)
        d = math["clamp"](d, E, V)
        dx["Scale"] = d
        local L = e["Notification"]["GUI"] and e["Notification"]["GUI"]["Parent"]
        if L then
            local e = L:FindFirstChildOfClass("UIScale")
            if not e then
                e = A("UIScale", {["Name"] = "LibraryUIScale"}, L)
            end
            e["Scale"] = d
        end
        return d
    end
    function O.ApplyUIScale(e)
        e = O["SetUIScalePreview"](e)
        ScheduleRefreshAllLayouts()
        return e
    end
    local Bx = true
    local hx = n
    local function vx()
        if not Bx then
            return
        end
        local e = workspace["CurrentCamera"]
        if not e then
            return
        end
        local d = e["ViewportSize"]
        if d["X"] < 50 or d["Y"] < 50 then
            return
        end
        local L = G and 800 or 1000
        local C = G and 460 or 600
        local w = math["min"](d["X"] / L, d["Y"] / C, 1)
        local U = math["clamp"](hx * w, E, V)
        O["SetUIScalePreview"](U)
        ScheduleRefreshAllLayouts()
    end
    do
        local e = workspace["CurrentCamera"]
        if e then
            e:GetPropertyChangedSignal("ViewportSize"):Connect(vx)
            task["defer"](vx)
        end
    end
    local Wx = O["ApplyUIScale"]
    function O.ApplyUIScale(e)
        hx = e
        return Wx(e)
    end
    local kx = A("Frame", {["BackgroundColor3"] = ThemeColor("Body"), ["BackgroundTransparency"] = 0.05, ["BorderSizePixel"] = 0, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["Size"] = UDim2["new"](0, 510, 0, 330), ["Visible"] = not S, ["Active"] = true, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 10)})}}, p)
    local ox = A("ImageLabel", {["Name"] = "BodyBackground", ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Image"] = "", ["ImageTransparency"] = 0.88, ["ScaleType"] = Enum["ScaleType"]["Crop"], ["ZIndex"] = 0, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 10)})}}, kx)
    local bx = A("Frame", {["Name"] = "BodyVideoHolder", ["BackgroundColor3"] = Color3["fromRGB"](0, 0, 0), ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Visible"] = false, ["ClipsDescendants"] = true, ["ZIndex"] = 0, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 10)})}}, kx)
    local Px = nil
    pcall(function() Px = Instance["new"]("VideoFrame"); Px["Name"] = "BodyVideo"; Px["BackgroundTransparency"] = 1; Px["BorderSizePixel"] = 0; Px["Size"] = UDim2["new"](1, 0, 1, 0); Px["Visible"] = true; Px["Looped"] = true; Px["Volume"] = 0; Px["ZIndex"] = 0; Px["Parent"] = bx end)
    function ClearBackgroundMedia()
        ox["Image"] = ""
        ox["Visible"] = false
        if bx then
            bx["Visible"] = false
        end
        if Px then
            pcall(function() Px["Playing"] = false end)
            pcall(function() Px:Pause() end)
            pcall(function() Px["Video"] = "" end)
        end
    end
    local Ox = nil
    function ApplyBackgroundImage(d, L)
        L = L or c:Get("_opt_BgImageTransparency", 0.88)
        if type(d) ~= "string" or d == "" then
            ClearBackgroundMedia()
            c:Save("_opt_BgImage", "")
            return
        end
        local C = t(d)
        if C then
            ox["Image"] = ""
            ox["Visible"] = false
            local L = T(d)
            if not L then
                e["Notification"]:Notify({["Title"] = "Video BG", ["Description"] = "Could not load video asset. File not found or unsupported."}, {["Time"] = 3})
                ClearBackgroundMedia()
                return
            end
            if not Px or not Px["Parent"] then
                pcall(function() if Px then Px:Destroy() end; Px = Instance["new"]("VideoFrame"); Px["Name"] = "BodyVideo"; Px["BackgroundTransparency"] = 1; Px["BorderSizePixel"] = 0; Px["Size"] = UDim2["new"](1, 0, 1, 0); Px["Visible"] = true; Px["Looped"] = true; Px["Volume"] = 0; Px["ZIndex"] = 0; Px["Parent"] = bx end)
            end
            if bx then
                bx["Visible"] = true
            end
            if Px then
                pcall(function() Px["Visible"] = true; Px["Looped"] = true; Px["Volume"] = 0; Px["Video"] = L; Px["Playing"] = true; Px:Play() end)
                task["spawn"](function() task["wait"](0.08); pcall(function() Px["Playing"] = true; Px:Play() end); local e = tick(); while tick() - e < 5 do local e = false; pcall(function() e = Px["IsLoaded"] end); if e then pcall(function() Px["Playing"] = true; Px:Play() end); break end; task["wait"](0.2) end end)
                if not Ox then
                    Ox = task["spawn"](function() while true do task["wait"](1.5); if bx and (bx["Visible"] and (Px and Px["Parent"])) then local e = false; pcall(function() e = Px["Playing"] end); if not e then pcall(function() Px["Playing"] = true; Px:Play() end) end end end end)
                end
            end
            c:Save("_opt_BgImage", d)
        else
            local e = T(d)
            if not e then
                return
            end
            ClearBackgroundMedia()
            ox["Visible"] = true
            ox["Image"] = e
            ox["ImageTransparency"] = L
            c:Save("_opt_BgImage", d)
        end
    end
    local cx = c:Get("_opt_BgImage", "")
    if cx ~= "" then
        task["defer"](function() ApplyBackgroundImage(cx) end)
    end
    ox["ImageTransparency"] = c:Get("_opt_BgImageTransparency", 0.88)
    do
        local e = c:Get("_opt_UITransparency", 0.05)
        kx["BackgroundTransparency"] = e
    end
    r["body"] = kx
    N(p)
    C:DestroyGui()
    C["_CurrentGui"] = p
    e["Notification"]:Init(kx)
    K = A("Frame", {["Name"] = "FullLockOverlay", ["BackgroundColor3"] = Color3["fromRGB"](6, 4, 12), ["BackgroundTransparency"] = 0.08, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Position"] = UDim2["new"](0, 0, 0, 0), ["Visible"] = false, ["ZIndex"] = 1003, ["Active"] = true, ["Children"] = {A("TextButton", {["Name"] = "ClickBlocker", ["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Position"] = UDim2["new"](0, 0, 0, 0), ["Text"] = "", ["AutoButtonColor"] = false, ["ZIndex"] = 1004, ["Active"] = true}), A("UICorner", {["CornerRadius"] = UDim["new"](0, 10)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 80, 220), ["Transparency"] = 0.55, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("ImageLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.38, 0), ["Size"] = UDim2["new"](0, 28, 0, 28), ["Image"] = "rbxassetid://7733992528", ["ImageColor3"] = Color3["fromRGB"](160, 100, 240), ["ImageTransparency"] = 0.1, ["ZIndex"] = 1004}), A("TextLabel", {["Name"] = "LockTitle", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.52, 0), ["Size"] = UDim2["new"](0.85, 0, 0, 22), ["Font"] = Enum["Font"]["FredokaOne"], ["Text"] = "Premium Privilege Only", ["TextColor3"] = Color3["fromRGB"](210, 160, 255), ["TextSize"] = 14, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 1004}), A("TextLabel", {["Name"] = "LockDesc", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.66, 0), ["Size"] = UDim2["new"](0.88, 0, 0, 36), ["Font"] = Enum["Font"]["Gotham"], ["RichText"] = true, ["Text"] = "Premium features require a valid key.\n<font color=\"#34D399\">Freemium</font> is still available below.", ["TextColor3"] = Color3["fromRGB"](180, 160, 210), ["TextSize"] = 10, ["TextWrapped"] = true, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 1004}), A("TextButton", {["Name"] = "FreemiumBtn", ["BackgroundColor3"] = Color3["fromRGB"](30, 18, 52), ["BackgroundTransparency"] = 0.15, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.82, 0), ["Size"] = UDim2["new"](0.62, 0, 0, 26), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Continue Freemium", ["TextColor3"] = Color3["fromRGB"](130, 230, 180), ["TextSize"] = 11, ["AutoButtonColor"] = false, ["ZIndex"] = 1005, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](80, 200, 140), ["Transparency"] = 0.45, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}), A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](140, 80, 220), ["BackgroundTransparency"] = 0.7, ["BorderSizePixel"] = 0, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.44, 0), ["Size"] = UDim2["new"](0.55, 0, 0, 1), ["ZIndex"] = 1004, ["Children"] = {A("UIGradient", {["Transparency"] = NumberSequence["new"]({NumberSequenceKeypoint["new"](0, 1), NumberSequenceKeypoint["new"](0.2, 0), NumberSequenceKeypoint["new"](0.8, 0), NumberSequenceKeypoint["new"](1, 1)})})}})}}, kx)
    if IsFullLocked() then
        K["Visible"] = true
    end
    local Xx = A("Frame", {["BackgroundColor3"] = ThemeColor("Body"), ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, 0), ["Size"] = UDim2["new"](1, 0, 0, 32), ["ZIndex"] = 1005, ["Active"] = true, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, kx)
    local sx = A("TextLabel", {["Name"] = "TitleHub", ["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 2), ["Size"] = UDim2["new"](1, -255, 0, 16), ["Font"] = Enum["Font"]["FredokaOne"], ["Text"] = w, ["TextColor3"] = Color3["fromRGB"](255, 255, 255), ["TextSize"] = 13, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["TextXAlignment"] = Enum["TextXAlignment"]["Left"]}, Xx)
    local Ix = A("TextLabel", {["Name"] = "SubtitleHub", ["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 18), ["Size"] = UDim2["new"](1, -255, 0, 12), ["Font"] = Enum["Font"]["Gotham"], ["RichText"] = true, ["Text"] = string["format"]("<font color=\"#C084FC\">%s</font> • <font color=\"#FF9E9E\">%s</font>", B, os["date"]("%A")), ["TextColor3"] = Color3["fromRGB"](200, 200, 200), ["TextSize"] = 10, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["TextXAlignment"] = Enum["TextXAlignment"]["Left"]}, Xx)
    function O.SetSubtitleTier()
        if O["IsDeveloperBuild"]() then
            Ix["Text"] = string["format"]("<font color=\"#C084FC\">%s</font> • <font color=\"#7286FF\">v.Developer</font> • <font color=\"#FF9E9E\">%s</font>", B, os["date"]("%A"))
        elseif O["HasKeyAccess"]() then
            Ix["Text"] = string["format"]("<font color=\"#C084FC\">%s</font> • <font color=\"#FFD700\">v.Premium</font> • <font color=\"#FF9E9E\">%s</font>", B, os["date"]("%A"))
        elseif m then
            Ix["Text"] = string["format"]("<font color=\"#C084FC\">%s</font> • <font color=\"#34D399\">v.Freemium</font> • <font color=\"#FF9E9E\">%s</font>", B, os["date"]("%A"))
        else
            Ix["Text"] = string["format"]("<font color=\"#C084FC\">%s</font> • <font color=\"#34D399\">%s</font> • <font color=\"#FF9E9E\">%s</font>", B, v, os["date"]("%A"))
        end
    end
    function SetSubtitlePremium()
        O["SetSubtitleTier"]()
    end
    O["SetSubtitleTier"]()
    local mx = K and K:FindFirstChild("FreemiumBtn", true)
    if mx then
        mx["MouseButton1Click"]:Connect(function() Q = true; K["Visible"] = false; O["SetSubtitleTier"]() end)
    end
    function O.SyncKeyAccess()
        if m then
            x = LoadKeyValid()
        end
        if x then
            RefreshKeyLock()
        end
        O["SetSubtitleTier"]()
    end
    local fx = Enum["KeyCode"]["RightControl"]
    local lx = false
    local Fx = nil
    local Ax = true
    c:RegisterKey("_opt_UIKeybind")
    do
        local e = c:Get("_opt_UIKeybind", "RightControl")
        local d = Enum["KeyCode"][e]
        if d then
            fx = d
        end
    end
    local Nx
    Nx = function() Ax = not Ax; kx["Visible"] = Ax end
    local gx = A("ImageButton", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -34, 0, 16), ["Size"] = UDim2["new"](0, 20, 0, 20), ["ZIndex"] = 1005, ["Image"] = "rbxassetid://92966930061759"}, kx)
    local Dx = A("ImageButton", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -8, 0, 16), ["Size"] = UDim2["new"](0, 20, 0, 20), ["ZIndex"] = 1005, ["Image"] = "rbxassetid://79324227570635"}, kx)
    local Kx = A("TextButton", {["Name"] = "CreditsBtn", ["BackgroundColor3"] = Color3["fromRGB"](14, 10, 22), ["BackgroundTransparency"] = 0, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -62, 0, 16), ["Size"] = UDim2["new"](0, 83, 0, 23), ["Text"] = "", ["AutoButtonColor"] = false, ["ZIndex"] = 1005, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](160, 100, 240), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](160, 100, 240), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0.5, -7), ["Size"] = UDim2["new"](0, 2, 0, 14), ["ZIndex"] = 1006, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](210, 160, 255)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](120, 60, 220))}), ["Rotation"] = 90})}}), A("ImageLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 8, 0.5, -7), ["Size"] = UDim2["new"](0, 14, 0, 14), ["Image"] = "rbxassetid://83474083071373", ["ImageColor3"] = Color3["fromRGB"](185, 140, 255), ["ZIndex"] = 1006}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 27, 0, 0), ["Size"] = UDim2["new"](1, -30, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Credits", ["TextColor3"] = Color3["fromRGB"](195, 155, 255), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 1006})}}, kx)
    local qx = Kx:FindFirstChildOfClass("UIStroke")
    s["BindHover"](Kx, {["BackgroundColor3"] = Color3["fromRGB"](22, 14, 38)}, {["BackgroundColor3"] = Color3["fromRGB"](14, 10, 22)}, {["Transparency"] = 0.38}, {["Transparency"] = 0.72}, qx)
    local Qx = A("TextButton", {["Name"] = "SettingsBtn", ["BackgroundColor3"] = Color3["fromRGB"](14, 10, 22), ["BackgroundTransparency"] = 0, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -153, 0, 16), ["Size"] = UDim2["new"](0, 83, 0, 23), ["Text"] = "", ["AutoButtonColor"] = false, ["ZIndex"] = 1005, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](160, 100, 240), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](160, 100, 240), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0.5, -7), ["Size"] = UDim2["new"](0, 2, 0, 14), ["ZIndex"] = 1006, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](210, 160, 255)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](120, 60, 220))}), ["Rotation"] = 90})}}), A("ImageLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 8, 0.5, -7), ["Size"] = UDim2["new"](0, 14, 0, 14), ["Image"] = "rbxassetid://81151604784579", ["ImageColor3"] = Color3["fromRGB"](185, 140, 255), ["ZIndex"] = 1006}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 27, 0, 0), ["Size"] = UDim2["new"](1, -30, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Settings", ["TextColor3"] = Color3["fromRGB"](195, 155, 255), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 1006})}}, kx)
    local Sx = Qx:FindFirstChildOfClass("UIStroke")
    s["BindHover"](Qx, {["BackgroundColor3"] = Color3["fromRGB"](22, 14, 38)}, {["BackgroundColor3"] = Color3["fromRGB"](14, 10, 22)}, {["Transparency"] = 0.38}, {["Transparency"] = 0.72}, Sx)
    local Tx = false
    function O.MakeOverlay(e, L, C, w, U)
        local B = A("Frame", {["Visible"] = false, ["Active"] = true, ["BackgroundTransparency"] = 0.5, ["BackgroundColor3"] = Color3["fromRGB"](4, 2, 10), ["Size"] = UDim2["new"](1, 0, 1, 0), ["ZIndex"] = 20}, kx)
        local h = A("Frame", {["Visible"] = false, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["BackgroundColor3"] = Color3["fromRGB"](11, 8, 18), ["BackgroundTransparency"] = 0, ["Size"] = UDim2["new"](0, C, 0, w), ["ZIndex"] = 2000, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 12)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.6, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](80, 40, 160), ["BackgroundTransparency"] = 0.92, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0.45, 0), ["Position"] = UDim2["new"](0, 0, 0, 0), ["ZIndex"] = 21, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 12)}), A("UIGradient", {["Transparency"] = NumberSequence["new"]({NumberSequenceKeypoint["new"](0, 0), NumberSequenceKeypoint["new"](1, 1)}), ["Rotation"] = 90})}}), A("ImageLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Position"] = UDim2["new"](0.5, 0, 0, 14), ["Size"] = UDim2["new"](0, 20, 0, 20), ["Image"] = L, ["ImageColor3"] = Color3["fromRGB"](190, 140, 255), ["ZIndex"] = 22}), A("TextLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Position"] = UDim2["new"](0.5, 0, 0, 38), ["Size"] = UDim2["new"](1, -24, 0, 16), ["Font"] = Enum["Font"]["FredokaOne"], ["Text"] = e, ["TextColor3"] = Color3["fromRGB"](210, 175, 255), ["TextSize"] = 15, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 22}), A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](160, 100, 255), ["BackgroundTransparency"] = 0.72, ["BorderSizePixel"] = 0, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Position"] = UDim2["new"](0.5, 0, 0, 57), ["Size"] = UDim2["new"](0.65, 0, 0, 1), ["ZIndex"] = 22, ["Children"] = {A("UIGradient", {["Transparency"] = NumberSequence["new"]({NumberSequenceKeypoint["new"](0, 1), NumberSequenceKeypoint["new"](0.2, 0), NumberSequenceKeypoint["new"](0.8, 0), NumberSequenceKeypoint["new"](1, 1)})})}})}}, kx)
        local v = A("ScrollingFrame", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Position"] = UDim2["new"](0.5, 0, 0, 64), ["Size"] = UDim2["new"](1, -16, 1, -100), ["Active"] = true, ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["ScrollingDirection"] = Enum["ScrollingDirection"]["Y"], ["AutomaticCanvasSize"] = Enum["AutomaticSize"]["Y"], ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ZIndex"] = 22, ["Children"] = {A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)}), A("UIPadding", {["PaddingTop"] = UDim["new"](0, 3), ["PaddingBottom"] = UDim["new"](0, 3), ["PaddingLeft"] = UDim["new"](0, 2), ["PaddingRight"] = UDim["new"](0, 2)})}}, h)
        local W = A("TextButton", {["Name"] = "CloseBtn", ["BackgroundColor3"] = Color3["fromRGB"](30, 18, 52), ["BackgroundTransparency"] = 0, ["AnchorPoint"] = Vector2["new"](0.5, 1), ["Size"] = UDim2["new"](0.52, 0, 0, 24), ["Position"] = UDim2["new"](0.5, 0, 1, -9), ["Text"] = "Close", ["TextColor3"] = Color3["fromRGB"](180, 135, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 11, ["AutoButtonColor"] = false, ["ZIndex"] = 22, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.65, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, h)
        W["MouseEnter"]:Connect(function() d:Tween(W, {["BackgroundColor3"] = Color3["fromRGB"](50, 28, 85)}, 0.15, Enum["EasingStyle"]["Quint"]) end)
        W["MouseLeave"]:Connect(function() d:Tween(W, {["BackgroundColor3"] = Color3["fromRGB"](30, 18, 52)}, 0.2, Enum["EasingStyle"]["Quint"]) end)
        local k = false
        local function o()
            k = true
            B["Visible"] = true
            h["Visible"] = true
            h["Size"] = UDim2["new"](0, C * 0.5, 0, w * 0.5)
            h["BackgroundTransparency"] = 0.6
            d:Tween(h, {["Size"] = UDim2["new"](0, C, 0, w), ["BackgroundTransparency"] = 0}, 0.3, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"])
        end
        local function b()
            if not k then
                return
            end
            k = false
            d:Tween(h, {["Size"] = UDim2["new"](0, C * 0.5, 0, w * 0.5), ["BackgroundTransparency"] = 0.6}, 0.22, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["In"], function() h["Visible"] = false; B["Visible"] = false; h["Size"] = UDim2["new"](0, C, 0, w); h["BackgroundTransparency"] = 0; if U then U() end end)
        end
        local function P()
            return k
        end
        W["MouseButton1Click"]:Connect(b)
        B["InputBegan"]:Connect(function(e) if Tx then return end; if e["UserInputType"] == Enum["UserInputType"]["MouseButton1"] or e["UserInputType"] == Enum["UserInputType"]["Touch"] then b() end end)
        return h, v, B, o, b, P
    end
    local jx, zx, tx, ux, Zx, Yx = O["MakeOverlay"]("Credits", "rbxassetid://83474083071373", 270, 270, nil)
    local ax = { ["ServerOwner"] = Color3["fromRGB"](255, 200, 80), ["MainDeveloper"] = Color3["fromRGB"](175, 115, 255), ["WebDesigner"] = Color3["fromRGB"](100, 200, 255), ["Tester"] = Color3["fromRGB"](80, 225, 160), }
    if #P > 0 then
        A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "TEAM", ["TextColor3"] = Color3["fromRGB"](130, 90, 200), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 23}, zx)
    end
    for L, C in ipairs(P) do
        local w = C["Role"] or "Developer"
        local U = C["Name"] or "Unknown"
        local B = C["Url"] or ""
        local h = C["UrlIcon"] or "rbxassetid://83474083071373"
        local v = C["UrlTag"] or "View Profile"
        local W = ax[w] or Color3["fromRGB"](175, 115, 255)
        local o, b, P = W["R"], W["G"], W["B"]
        local O = B ~= "" and 80 or 60
        local c = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](10, 7, 18), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, O), ["ZIndex"] = 23, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 12)})}}, zx)
        A("Frame", {["BackgroundColor3"] = W, ["BackgroundTransparency"] = 0.86, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 12)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["new"](o * 0.5, b * 0.5, P * 0.5)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](6, 4, 12))}), ["Rotation"] = 135})}}, c)
        local X = A("UIStroke", {["Color"] = W, ["Transparency"] = 0.65, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, c)
        A("Frame", {["BackgroundColor3"] = W, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, 8), ["Size"] = UDim2["new"](0, 3, 1, -16), ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](255, 255, 255)), ColorSequenceKeypoint["new"](1, W)}), ["Rotation"] = 90})}}, c)
        local s = A("Frame", {["BackgroundColor3"] = Color3["new"](o * 0.18, b * 0.18, P * 0.18), ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 12, 0, 10), ["Size"] = UDim2["new"](0, 36, 0, 36), ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = W, ["Transparency"] = 0.4, ["Thickness"] = 1.5, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Font"] = Enum["Font"]["FredokaOne"], ["Text"] = string["upper"](string["sub"](U, 1, 1)), ["TextColor3"] = W, ["TextSize"] = 18, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 26})}}, c)
        A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 58, 0, 10), ["Size"] = UDim2["new"](1, -148, 0, 16), ["Font"] = Enum["Font"]["FredokaOne"], ["Text"] = U, ["TextColor3"] = Color3["fromRGB"](242, 235, 255), ["TextSize"] = 14, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 25}, c)
        local I = A("Frame", {["AnchorPoint"] = Vector2["new"](1, 0), ["BackgroundColor3"] = Color3["new"](o * 0.12, b * 0.12, P * 0.12), ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -8, 0, 10), ["Size"] = UDim2["new"](0, 76, 0, 20), ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = W, ["Transparency"] = 0.5, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["new"](o * 0.24, b * 0.24, P * 0.24)), ColorSequenceKeypoint["new"](1, Color3["new"](o * 0.08, b * 0.08, P * 0.08))}), ["Rotation"] = 90}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = w, ["TextColor3"] = W, ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 26})}}, c)
        A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 58, 0, 28), ["Size"] = UDim2["new"](1, -148, 0, 12), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = string["lower"](w), ["TextColor3"] = Color3["new"](o * 0.82, b * 0.82, P * 0.82), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 25}, c)
        if B ~= "" then
            A("Frame", {["BackgroundColor3"] = W, ["BackgroundTransparency"] = 0.78, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 10, 0, 52), ["Size"] = UDim2["new"](1, -20, 0, 1), ["ZIndex"] = 25, ["Children"] = {A("UIGradient", {["Transparency"] = NumberSequence["new"]({NumberSequenceKeypoint["new"](0, 1), NumberSequenceKeypoint["new"](0.15, 0), NumberSequenceKeypoint["new"](0.85, 0), NumberSequenceKeypoint["new"](1, 1)})})}}, c)
            A("ImageLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 14, 0, 57), ["Size"] = UDim2["new"](0, 13, 0, 13), ["Image"] = h, ["ImageColor3"] = Color3["new"](o * 0.8, b * 0.8, P * 0.8), ["ZIndex"] = 26}, c)
            A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 32, 0, 56), ["Size"] = UDim2["new"](1, -140, 0, 14), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = v, ["TextColor3"] = Color3["new"](o * 0.75, b * 0.75, P * 0.75), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 26}, c)
            local L = A("TextButton", {["AnchorPoint"] = Vector2["new"](1, 0), ["BackgroundColor3"] = Color3["new"](o * 0.12, b * 0.12, P * 0.12), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -8, 0, 55), ["Size"] = UDim2["new"](0, 68, 0, 20), ["AutoButtonColor"] = false, ["Text"] = "", ["ZIndex"] = 26, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = W, ["Transparency"] = 0.5, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["new"](o * 0.26, b * 0.26, P * 0.26)), ColorSequenceKeypoint["new"](1, Color3["new"](o * 0.08, b * 0.08, P * 0.08))}), ["Rotation"] = 90})}}, c)
            local C = A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "COPY LINK", ["TextColor3"] = W, ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 27}, L)
            local w = L:FindFirstChildOfClass("UIStroke")
            L["MouseEnter"]:Connect(function() d:Tween(L, {["BackgroundColor3"] = Color3["new"](o * 0.28, b * 0.28, P * 0.28)}, 0.12, Enum["EasingStyle"]["Quint"]); d:Tween(w, {["Transparency"] = 0.15}, 0.12) end)
            L["MouseLeave"]:Connect(function() d:Tween(L, {["BackgroundColor3"] = Color3["new"](o * 0.12, b * 0.12, P * 0.12)}, 0.18, Enum["EasingStyle"]["Quint"]); d:Tween(w, {["Transparency"] = 0.5}, 0.18) end)
            local O = B
            local X = U
            L["MouseButton1Click"]:Connect(function() CircleClick(L, k["X"], k["Y"]); pcall(function() (setclipboard or toclipboard)(O) end); C["Text"] = "COPIED"; C["TextColor3"] = Color3["fromRGB"](100, 255, 160); d:Tween(L, {["BackgroundColor3"] = Color3["fromRGB"](14, 60, 32)}, 0.12, Enum["EasingStyle"]["Quint"]); task["delay"](1.4, function() C["Text"] = "COPY LINK"; C["TextColor3"] = W; d:Tween(L, {["BackgroundColor3"] = Color3["new"](o * 0.12, b * 0.12, P * 0.12)}, 0.25, Enum["EasingStyle"]["Quint"]) end); e["Notification"]:Notify({["Title"] = X, ["Description"] = "Profile link copied to clipboard!"}, {["Time"] = 2}) end)
        end
        local m = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, B ~= "" and 54 or O), ["Text"] = "", ["ZIndex"] = 28, ["AutoButtonColor"] = false}, c)
        m["MouseEnter"]:Connect(function() d:Tween(c, {["BackgroundColor3"] = Color3["new"](o * 0.06, b * 0.04, P * 0.11)}, 0.14, Enum["EasingStyle"]["Quint"]); d:Tween(X, {["Transparency"] = 0.28}, 0.14); d:Tween(s, {["Size"] = UDim2["new"](0, 39, 0, 39), ["Position"] = UDim2["new"](0, 11, 0, 9)}, 0.18, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"]) end)
        m["MouseLeave"]:Connect(function() d:Tween(c, {["BackgroundColor3"] = Color3["fromRGB"](10, 7, 18)}, 0.2, Enum["EasingStyle"]["Quint"]); d:Tween(X, {["Transparency"] = 0.65}, 0.2); d:Tween(s, {["Size"] = UDim2["new"](0, 36, 0, 36), ["Position"] = UDim2["new"](0, 12, 0, 10)}, 0.2, Enum["EasingStyle"]["Quint"]) end)
    end
    A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](140, 90, 220), ["BackgroundTransparency"] = 0.78, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 1), ["ZIndex"] = 23, ["Children"] = {A("UIGradient", {["Transparency"] = NumberSequence["new"]({NumberSequenceKeypoint["new"](0, 1), NumberSequenceKeypoint["new"](0.12, 0), NumberSequenceKeypoint["new"](0.88, 0), NumberSequenceKeypoint["new"](1, 1)})})}}, zx)
    local xx = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 22), ["ZIndex"] = 23}, zx)
    A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 0, 0, 4), ["Size"] = UDim2["new"](1, 0, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "COMMUNITY", ["TextColor3"] = Color3["fromRGB"](130, 90, 200), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 24}, xx)
    function O.MakePremiumSocialCard(e, L)
        local C = L["AccentColor"]
        local w, U, B = C["R"], C["G"], C["B"]
        local h = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](10, 7, 18), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 72), ["ZIndex"] = 23, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 12)})}}, e)
        A("Frame", {["BackgroundColor3"] = C, ["BackgroundTransparency"] = 0.88, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 12)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["new"](w * 0.6, U * 0.6, B * 0.6)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](6, 4, 12))}), ["Rotation"] = 135})}}, h)
        A("UIStroke", {["Color"] = C, ["Transparency"] = 0.65, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, h)
        A("Frame", {["BackgroundColor3"] = C, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, 10), ["Size"] = UDim2["new"](0, 3, 1, -20), ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](255, 255, 255)), ColorSequenceKeypoint["new"](1, C)}), ["Rotation"] = 90})}}, h)
        local v = A("Frame", {["BackgroundColor3"] = Color3["new"](w * 0.18, U * 0.18, B * 0.18), ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 14, 0.5, -20), ["Size"] = UDim2["new"](0, 40, 0, 40), ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = C, ["Transparency"] = 0.4, ["Thickness"] = 1.5, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("ImageLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["Size"] = UDim2["new"](0, 20, 0, 20), ["Image"] = L["IconImg"], ["ImageColor3"] = C, ["ZIndex"] = 26})}}, h)
        A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 64, 0, 14), ["Size"] = UDim2["new"](1, -160, 0, 18), ["Font"] = Enum["Font"]["FredokaOne"], ["Text"] = L["Label"], ["TextColor3"] = Color3["fromRGB"](240, 235, 255), ["TextSize"] = 15, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 25}, h)
        A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 64, 0, 34), ["Size"] = UDim2["new"](1, -160, 0, 12), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = L["SubLabel"], ["TextColor3"] = Color3["new"](w * 0.8, U * 0.8, B * 0.8), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 25}, h)
        local W = A("TextButton", {["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundColor3"] = Color3["new"](w * 0.14, U * 0.14, B * 0.14), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -10, 0.5, 0), ["Size"] = UDim2["new"](0, 68, 0, 28), ["AutoButtonColor"] = false, ["Text"] = "", ["ZIndex"] = 26, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)}), A("UIStroke", {["Color"] = C, ["Transparency"] = 0.45, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["new"](w * 0.28, U * 0.28, B * 0.28)), ColorSequenceKeypoint["new"](1, Color3["new"](w * 0.1, U * 0.1, B * 0.1))}), ["Rotation"] = 90})}}, h)
        local o = A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = L["BadgeText"] or "COPY", ["TextColor3"] = C, ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 27}, W)
        local b = W:FindFirstChildOfClass("UIStroke")
        local P = h:FindFirstChildOfClass("UIStroke")
        local O = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Text"] = "", ["ZIndex"] = 28, ["AutoButtonColor"] = false}, h)
        O["MouseEnter"]:Connect(function() d:Tween(h, {["BackgroundColor3"] = Color3["new"](w * 0.07, U * 0.04, B * 0.12)}, 0.14, Enum["EasingStyle"]["Quint"]); d:Tween(P, {["Transparency"] = 0.3}, 0.14); d:Tween(v, {["Size"] = UDim2["new"](0, 43, 0, 43), ["Position"] = UDim2["new"](0, 12, 0.5, -21)}, 0.18, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"]) end)
        O["MouseLeave"]:Connect(function() d:Tween(h, {["BackgroundColor3"] = Color3["fromRGB"](10, 7, 18)}, 0.2, Enum["EasingStyle"]["Quint"]); d:Tween(P, {["Transparency"] = 0.65}, 0.2); d:Tween(v, {["Size"] = UDim2["new"](0, 40, 0, 40), ["Position"] = UDim2["new"](0, 14, 0.5, -20)}, 0.2, Enum["EasingStyle"]["Quint"]) end)
        W["MouseEnter"]:Connect(function() d:Tween(W, {["BackgroundColor3"] = Color3["new"](w * 0.28, U * 0.28, B * 0.28)}, 0.12, Enum["EasingStyle"]["Quint"]); d:Tween(b, {["Transparency"] = 0.15}, 0.12) end)
        W["MouseLeave"]:Connect(function() d:Tween(W, {["BackgroundColor3"] = Color3["new"](w * 0.14, U * 0.14, B * 0.14)}, 0.18, Enum["EasingStyle"]["Quint"]); d:Tween(b, {["Transparency"] = 0.45}, 0.18) end)
        local function c()
            CircleClick(W, k["X"], k["Y"])
            pcall(function() (setclipboard or toclipboard)(L["CopyText"]) end)
            o["Text"] = "COPIED"
            o["TextColor3"] = Color3["fromRGB"](100, 255, 160)
            d:Tween(W, {["BackgroundColor3"] = Color3["new"](w * 0.1, U * 0.4, B * 0.25)}, 0.12, Enum["EasingStyle"]["Quint"])
            d:Tween(b, {["Transparency"] = 0}, 0.12)
            d:Tween(P, {["Transparency"] = 0.15}, 0.12)
            task["delay"](1.4, function() o["Text"] = L["BadgeText"] or "COPY"; o["TextColor3"] = C; d:Tween(W, {["BackgroundColor3"] = Color3["new"](w * 0.14, U * 0.14, B * 0.14)}, 0.35, Enum["EasingStyle"]["Quint"]); d:Tween(b, {["Transparency"] = 0.45}, 0.35); d:Tween(P, {["Transparency"] = 0.65}, 0.35) end)
            if L["OnClick"] then
                L["OnClick"](L["CopyText"])
            end
        end
        W["MouseButton1Click"]:Connect(c)
        O["MouseButton1Click"]:Connect(c)
        return h
    end
    O["MakePremiumSocialCard"](zx, {["Label"] = "TikTok", ["SubLabel"] = "@trustmenotcondom", ["IconImg"] = "http://www.roblox.com/asset/?id=14620084334", ["AccentColor"] = Color3["fromRGB"](210, 145, 255), ["BadgeText"] = "COPY", ["CopyText"] = "https://www.tiktok.com/@trustmenotcondom?_t=ZS-8syewdU3Bxq&_r=1", ["OnClick"] = function() e["Notification"]:Notify({["Title"] = "TikTok", ["Description"] = "TikTok link copied to clipboard."}, {["Time"] = 2}) end})
    O["MakePremiumSocialCard"](zx, {["Label"] = "Discord", ["SubLabel"] = "discord.gg/YEvpu5St2Z", ["IconImg"] = "rbxassetid://129297846250682", ["AccentColor"] = Color3["fromRGB"](114, 137, 255), ["BadgeText"] = "COPY", ["CopyText"] = "https://discord.gg/YEvpu5St2Z", ["OnClick"] = function() e["Notification"]:Notify({["Title"] = "Discord", ["Description"] = "Discord invite copied to clipboard."}, {["Time"] = 3}) end})
    local Jx, yx, rx, ix, Rx, Hx = O["MakeOverlay"]("Settings", "rbxassetid://81151604784579", 270, 270, nil)
    local Mx, px, Gx, Ex, Vx, nx = O["MakeOverlay"]("Save Manager", "rbxassetid://7733715400", 270, 270, nil)
    Kx["MouseButton1Click"]:Connect(function() CircleClick(Kx, k["X"], k["Y"]); if Hx and Hx() then Rx() end; if nx and nx() then Vx() end; ux() end)
    function CloseFullLock()
        if IsFullLocked() and K then
            K["Visible"] = true
        end
    end
    function O.MakeMiniToggle(L, C, w, U, B, h, v)
        B = B or 23
        local W = h and not O["HasKeyAccess"]()
        if W then
            c:Save(w, false)
        end
        local k = c:Get(w, U)
        if W then
            k = false
        end
        local o = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](18, 12, 30), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 34), ["ZIndex"] = B, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)})}}, L)
        local b = A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = (k and not W) and 0.45 or 0.82, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, o)
        local P = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](160, 100, 255), ["BackgroundTransparency"] = (k and not W) and 0 or 0.8, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0.5, -10), ["Size"] = UDim2["new"](0, 3, 0, 20), ["ZIndex"] = B + 1, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](220, 170, 255)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](110, 55, 210))}), ["Rotation"] = 90})}}, o)
        local X = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 14, 0, 0), ["Size"] = UDim2["new"](1, -70, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = C .. (W and " (Premium)" or ""), ["TextColor3"] = (k and not W) and Color3["fromRGB"](215, 185, 255) or Color3["fromRGB"](155, 130, 195), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = B + 1}, o)
        if W then
            A("ImageLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -54, 0.5, 0), ["Size"] = UDim2["new"](0, 12, 0, 12), ["Image"] = "rbxassetid://7733992528", ["ImageColor3"] = Color3["fromRGB"](140, 110, 190), ["ZIndex"] = B + 3}, o)
        end
        local s = A("Frame", {["BackgroundColor3"] = (k and not W) and Color3["fromRGB"](90, 45, 170) or Color3["fromRGB"](14, 9, 26), ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -10, 0.5, 0), ["Size"] = UDim2["new"](0, 38, 0, 20), ["BorderSizePixel"] = 0, ["ZIndex"] = B + 2, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, o)
        local I = A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = (k and not W) and 0.4 or 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, s)
        local m = A("Frame", {["AnchorPoint"] = Vector2["new"](0, 0.5), ["Position"] = (k and not W) and UDim2["new"](0, 20, 0.5, 0) or UDim2["new"](0, 3, 0.5, 0), ["Size"] = UDim2["new"](0, 14, 0, 14), ["BorderSizePixel"] = 0, ["ZIndex"] = B + 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, (k and not W) and Color3["fromRGB"](235, 205, 255) or Color3["fromRGB"](120, 100, 150)), ColorSequenceKeypoint["new"](1, (k and not W) and Color3["fromRGB"](170, 105, 255) or Color3["fromRGB"](60, 50, 90))}), ["Rotation"] = 135})}}, s)
        local f = m:FindFirstChildOfClass("UIGradient")
        local l = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Text"] = "", ["ZIndex"] = B + 4}, o)
        local F = k
        l["MouseButton1Click"]:Connect(function() if W then e["Notification"]:Notify({["Title"] = "Premium Only", ["Description"] = "This feature requires a premium key."}, {["Time"] = 3}); return end; F = not F; d:Tween(m, {["Position"] = F and UDim2["new"](0, 20, 0.5, 0) or UDim2["new"](0, 3, 0.5, 0)}, 0.22, Enum["EasingStyle"]["Back"]); d:Tween(s, {["BackgroundColor3"] = F and Color3["fromRGB"](90, 45, 170) or Color3["fromRGB"](14, 9, 26)}, 0.2, Enum["EasingStyle"]["Quint"]); d:Tween(I, {["Transparency"] = F and 0.4 or 0.72}, 0.2); d:Tween(b, {["Transparency"] = F and 0.45 or 0.82}, 0.2); d:Tween(P, {["BackgroundTransparency"] = F and 0 or 0.8}, 0.2); d:Tween(X, {["TextColor3"] = F and Color3["fromRGB"](215, 185, 255) or Color3["fromRGB"](155, 130, 195)}, 0.2); if f then f["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, F and Color3["fromRGB"](235, 205, 255) or Color3["fromRGB"](120, 100, 150)), ColorSequenceKeypoint["new"](1, F and Color3["fromRGB"](170, 105, 255) or Color3["fromRGB"](60, 50, 90))}) end; c:Save(w, F); if typeof(v) == "function" then pcall(v, F) end end)
        return function() return F end
    end
    function O.MakeMiniSlider(e, L, C, w, B, h, v, W, k, o)
        k = k or 23
        v = v or 0.05
        o = o == true
        c:RegisterKey(C)
        local b = c:Get(C, h)
        if b ~= nil then
            h = b
        end
        h = math["clamp"](h, w, B)
        local P = G and 16 or 12
        local O = G and 20 or 14
        local function X(e)
            return math["floor"](e / v + 0.5) * v
        end
        local function s(e)
            return math["floor"](e * 100 + 0.5) .. "%"
        end
        local I
        local m = e
        while m do
            if m:IsA("ScrollingFrame") then
                I = m
                break
            end
            m = m["Parent"]
        end
        local f = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](18, 12, 30), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, G and 52 or 48), ["Active"] = true, ["ZIndex"] = k, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)})}}, e)
        A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.7, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, f)
        A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](160, 100, 255), ["BackgroundTransparency"] = 0.15, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0.5, -12), ["Size"] = UDim2["new"](0, 3, 0, 24), ["ZIndex"] = k + 1, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](220, 170, 255)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](110, 55, 210))}), ["Rotation"] = 90})}}, f)
        A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 14, 0, 6), ["Size"] = UDim2["new"](1, -70, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = L, ["TextColor3"] = Color3["fromRGB"](215, 185, 255), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = k + 1}, f)
        local l = A("TextLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0), ["Position"] = UDim2["new"](1, -10, 0, 6), ["Size"] = UDim2["new"](0, 44, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = s(h), ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Right"], ["ZIndex"] = k + 1}, f)
        local F = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](10, 10, 16), ["BackgroundTransparency"] = 0.1, ["Position"] = UDim2["new"](0, 12, 0, G and 30 or 28), ["Size"] = UDim2["new"](1, -24, 0, G and 14 or 10), ["Active"] = true, ["ZIndex"] = k + 2, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, f)
        local N = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](160, 100, 255), ["BackgroundTransparency"] = 0, ["Size"] = UDim2["new"]((h - w) / (B - w), 0, 1, 0), ["ZIndex"] = k + 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](139, 92, 246)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](216, 180, 254))})})}}, F)
        local g = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](255, 255, 255), ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"]((h - w) / (B - w), 0, 0.5, 0), ["Size"] = UDim2["new"](0, P, 0, P), ["Active"] = true, ["ZIndex"] = k + 4, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 0.3, ["Thickness"] = 1.5, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, F)
        A("TextButton", {["Name"] = "TouchHitbox", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["Size"] = UDim2["new"](0, math["max"](P + 14, 28), 0, math["max"](P + 14, 28)), ["Text"] = "", ["ZIndex"] = k + 5}, g)
        local D = h
        local K = false
        local q = nil
        local function Q(e, d)
            if not W then
                return
            end
            if o then
                W(e, d)
            elseif d then
                W(e, true)
            end
        end
        local function S(e, L)
            L = L ~= false
            e = X(math["clamp"](e, w, B))
            D = e
            local U = (e - w) / (B - w)
            local h = UDim2["new"](U, 0, 1, 0)
            local v = UDim2["new"](U, 0, 0.5, 0)
            if L then
                d:Tween(N, {["Size"] = h}, 0.12, Enum["EasingStyle"]["Quint"])
                d:Tween(g, {["Position"] = v}, 0.12, Enum["EasingStyle"]["Quint"])
            else
                N["Size"] = h
                g["Position"] = v
            end
            l["Text"] = s(e)
            if L then
                c:Save(C, e)
            end
            Q(e, L)
        end
        local function T(e)
            local d = math["clamp"]((e - F["AbsolutePosition"]["X"]) / F["AbsoluteSize"]["X"], 0, 1)
            S(w + (B - w) * d, false)
        end
        local j = nil
        local function z(e)
            if not K then
                return
            end
            if e ~= j then
                return
            end
            K = false
            j = nil
            q = nil
            Tx = false
            if I then
                I["ScrollingEnabled"] = true
            end
            d:Tween(g, {["Size"] = UDim2["new"](0, P, 0, P)}, 0.15, Enum["EasingStyle"]["Quint"])
            c:Save(C, D)
            Q(D, true)
        end
        local function t(e)
            if j ~= nil then
                return
            end
            if e["UserInputType"] == Enum["UserInputType"]["Touch"] or e["UserInputType"] == Enum["UserInputType"]["MouseButton1"] then
                K = true
                j = e
                q = e["UserInputType"]
                Tx = true
                if I then
                    I["ScrollingEnabled"] = false
                end
                T(e["Position"]["X"])
                d:Tween(g, {["Size"] = UDim2["new"](0, O, 0, O)}, 0.12, Enum["EasingStyle"]["Back"])
            end
        end
        F["InputBegan"]:Connect(t)
        g["InputBegan"]:Connect(t)
        local u = g:FindFirstChild("TouchHitbox")
        if u then
            u["InputBegan"]:Connect(t)
        end
        f["InputBegan"]:Connect(function(e) if e["UserInputType"] == Enum["UserInputType"]["Touch"] or e["UserInputType"] == Enum["UserInputType"]["MouseButton1"] then local d = e["Position"]["Y"] - f["AbsolutePosition"]["Y"]; if d >= (G and 26 or 24) then t(e) end end end)
        U["InputChanged"]:Connect(function(e) if not K or not j then return end; if e == j or j["UserInputType"] == Enum["UserInputType"]["MouseButton1"] and e["UserInputType"] == Enum["UserInputType"]["MouseMovement"] then T(e["Position"]["X"]) end end)
        U["InputEnded"]:Connect(function(e) if e == j then z(e) end end)
        S(h, true)
        return function() return D end
    end
    function O.MakeKeybindRow(e, d, L, C)
        local w = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](18, 12, 30), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 34), ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)})}}, e)
        A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.7, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, w)
        A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 14, 0, 0), ["Size"] = UDim2["new"](1, -90, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = d, ["TextColor3"] = Color3["fromRGB"](215, 185, 255), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, w)
        Fx = A("TextLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -10, 0.5, 0), ["Size"] = UDim2["new"](0, 72, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = fx["Name"], ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 10, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["TextXAlignment"] = Enum["TextXAlignment"]["Right"], ["ZIndex"] = 24}, w)
        local U = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Text"] = "", ["ZIndex"] = 25}, w)
        U["MouseButton1Click"]:Connect(function() lx = true; Fx["Text"] = "..." end)
    end
    local eb = O["MakeMiniToggle"](yx, "Auto Save changes", "_opt_AutoSave", true)
    local db = O["MakeMiniToggle"](yx, "Auto Translate UI", "_opt_AutoTranslate", false)
    O["MakeMiniSlider"](yx, "UI Scale", "_opt_UIScale", E, V, n, ex, function(e, d) if d then O["ApplyUIScale"](e) else O["SetUIScalePreview"](e) end end, nil, true)
    O["MakeKeybindRow"](yx, "UI Keybind", "_opt_UIKeybind", "RightControl")
    local Lb = { "English", "Filipino", "Hindi", "Turkish", "Indonesian", "Spanish", "French", "German", "Japanese", "Korean", "Vietnamese", "Thai", "Russian", "Portuguese", "Chinese Simplified", "Chinese Traditional", "Arabic", "Italian", "Polish", "Dutch", "Ukrainian", "Malay", "Bengali", "Urdu", "Persian", "Romanian", "Czech", "Greek", "Swedish", "Hungarian", "Danish", "Finnish", "Norwegian", "Hebrew", "Slovak", "Bulgarian", "Croatian", "Serbian", "Lithuanian", "Latvian", "Slovenian", }
    local Cb = 26
    local wb = 3
    local Ub = 8
    local Bb = 4
    local hb = 30
    local vb = 6
    local Wb = 10
    local kb = ""
    local ob = false
    local bb = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](14, 10, 24), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 34), ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.7, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 14, 0, 0), ["Size"] = UDim2["new"](0.45, 0, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Language", ["TextColor3"] = Color3["fromRGB"](155, 130, 195), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24})}}, yx)
    local Pb = c:Get("_opt_Language", "English")
    local Ob = A("TextLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -30, 0.5, 0), ["Size"] = UDim2["new"](0, 130, 0, 20), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = Pb, ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Right"], ["ZIndex"] = 24}, bb)
    A("TextLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -10, 0.5, 0), ["Size"] = UDim2["new"](0, 14, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "›", ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 14, ["ZIndex"] = 24}, bb)
    local cb = A("Frame", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Position"] = UDim2["new"](0.5, 0, 0, 0), ["Size"] = UDim2["new"](1, -(Wb * 2), 0, 0), ["ClipsDescendants"] = true, ["ZIndex"] = 24}, yx)
    local Xb = A("TextBox", {["BackgroundColor3"] = Color3["fromRGB"](18, 13, 30), ["BackgroundTransparency"] = 0.1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, 0), ["Size"] = UDim2["new"](1, 0, 0, hb), ["Font"] = Enum["Font"]["GothamBold"], ["PlaceholderText"] = "Search language...", ["Text"] = "", ["TextColor3"] = Color3["fromRGB"](230, 230, 230), ["PlaceholderColor3"] = Color3["fromRGB"](120, 110, 145), ["TextSize"] = 11, ["ClearTextOnFocus"] = false, ["Visible"] = false, ["ZIndex"] = 30, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 10), ["PaddingRight"] = UDim["new"](0, 10)})}}, cb)
    local sb = A("ScrollingFrame", {["BackgroundColor3"] = Color3["fromRGB"](14, 10, 20), ["BackgroundTransparency"] = 0.05, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, hb + vb), ["Size"] = UDim2["new"](1, 0, 0, 0), ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["ScrollingDirection"] = Enum["ScrollingDirection"]["Y"], ["AutomaticCanvasSize"] = Enum["AutomaticSize"]["None"], ["ClipsDescendants"] = true, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.55, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, cb)
    A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, wb)}, sb)
    A("UIPadding", {["PaddingTop"] = UDim["new"](0, 4), ["PaddingBottom"] = UDim["new"](0, 4), ["PaddingLeft"] = UDim["new"](0, 4), ["PaddingRight"] = UDim["new"](0, 4)}, sb)
    function O.GetFilteredLanguages()
        if kb == "" then
            return table["clone"](Lb)
        end
        local e = string["lower"](kb)
        local d = {}
        for L, C in ipairs(Lb) do
            if string["find"](string["lower"](C), e, 1, true) then
                table["insert"](d, C)
            end
        end
        return d
    end
    function O.CalcListHeight(e)
        local d = math["min"](e, Bb)
        if d == 0 then
            return 0
        end
        return (Ub + d * Cb) + (d - 1) * wb
    end
    function O.SetCanvasHeight(e)
        local d = (Ub + e * Cb) + math["max"](e - 1, 0) * wb
        local L = UnscaledLayout(sb["AbsoluteSize"]["Y"])
        local C = d > L + 1
        sb["CanvasSize"] = UDim2["new"](0, 0, 0, C and d or 0)
        sb["ScrollingEnabled"] = C
        sb["ElasticBehavior"] = Enum["ElasticBehavior"]["Never"]
        if not C then
            sb["CanvasPosition"] = Vector2["new"](0, 0)
        end
    end
    function O.BuildLangItems()
        for e, d in ipairs(sb:GetChildren()) do
            if d:IsA("TextButton") then
                d:Destroy()
            end
        end
        local e = c:Get("_opt_Language", "English")
        local L = O["GetFilteredLanguages"]()
        for L, C in ipairs(L) do
            local w = C == e
            local U = A("TextButton", {["BackgroundColor3"] = w and Color3["fromRGB"](30, 18, 52) or Color3["fromRGB"](18, 13, 30), ["BackgroundTransparency"] = w and 0.2 or 0.5, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -2, 0, Cb), ["LayoutOrder"] = L, ["Text"] = "", ["AutoButtonColor"] = false, ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = w and 0.42 or 0.82, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](160, 100, 255), ["BackgroundTransparency"] = w and 0 or 1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0.5, -9), ["Size"] = UDim2["new"](0, 3, 0, 18), ["ZIndex"] = 26, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 0), ["Size"] = UDim2["new"](1, -24, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = C, ["TextColor3"] = w and Color3["fromRGB"](215, 185, 255) or Color3["fromRGB"](175, 155, 210), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 26})}}, sb)
            U["MouseButton1Click"]:Connect(function() c:Save("_opt_Language", C); Ob["Text"] = C; ob = false; kb = ""; Xb["Text"] = ""; Xb["Visible"] = false; O["BuildLangItems"](); local e = O["CalcListHeight"](#O["GetFilteredLanguages"]()); sb["Size"] = UDim2["new"](1, 0, 0, e); d:Tween(cb, {["Size"] = UDim2["new"](1, -(Wb * 2), 0, 0)}, 0.22, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["In"]); d:Tween(sb, {["Size"] = UDim2["new"](1, 0, 0, 0)}, 0.22, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["In"]); if db() then local e = Z["Languages"][C]; if e then task["spawn"](ApplyTranslation, e) end end end)
        end
        O["SetCanvasHeight"](#L)
    end
    Xb:GetPropertyChangedSignal("Text"):Connect(function() kb = Xb["Text"]; O["BuildLangItems"](); if ob then local e = O["GetFilteredLanguages"](); local d = O["CalcListHeight"](#e); sb["Size"] = UDim2["new"](1, 0, 0, d); cb["Size"] = UDim2["new"](1, -(Wb * 2), 0, (hb + vb) + d) end end)
    O["BuildLangItems"]()
    local Ib = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Text"] = "", ["ZIndex"] = 25}, bb)
    Ib["MouseButton1Click"]:Connect(function() ob = not ob; kb = ""; Xb["Text"] = ""; Xb["Visible"] = ob; O["BuildLangItems"](); local e = O["GetFilteredLanguages"](); local L = O["CalcListHeight"](#e); local C = ob and (hb + vb) + L or 0; local w = ob and Enum["EasingDirection"]["Out"] or Enum["EasingDirection"]["In"]; d:Tween(cb, {["Size"] = UDim2["new"](1, -(Wb * 2), 0, C)}, 0.25, Enum["EasingStyle"]["Quint"], w); d:Tween(sb, {["Size"] = UDim2["new"](1, 0, 0, L)}, 0.25, Enum["EasingStyle"]["Quint"], w) end)
    local mb = c:Get("_opt_AutoTranslate", false)
    local fb = c:Get("_opt_Language", "English")
    task["spawn"](function() while true do task["wait"](0.45); local e = db(); local d = c:Get("_opt_Language", "English"); if e ~= mb or e and d ~= fb then mb = e; fb = d; local L = Z["Languages"][d]; if e and (L and L ~= "en") then ApplyTranslation(L) elseif not e then ApplyTranslation("en") end end end end)
    task["defer"](function() if c:Get("_opt_AutoTranslate", false) then local e = c:Get("_opt_Language", "English"); local d = Z["Languages"][e]; if d and d ~= "en" then ApplyTranslation(d) end end end)
    A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](100, 60, 180), ["BackgroundTransparency"] = 0.82, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 1), ["ZIndex"] = 23, ["Children"] = {A("UIGradient", {["Transparency"] = NumberSequence["new"]({NumberSequenceKeypoint["new"](0, 1), NumberSequenceKeypoint["new"](0.15, 0), NumberSequenceKeypoint["new"](0.85, 0), NumberSequenceKeypoint["new"](1, 1)})})}}, yx)
    c["IsAutoSave"] = eb
    local lb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](22, 14, 38), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 36), ["Text"] = "", ["AutoButtonColor"] = false, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.55, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 0), ["Size"] = UDim2["new"](1, -40, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Open Save Manager", ["TextColor3"] = Color3["fromRGB"](210, 180, 255), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}), A("TextLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -10, 0.5, 0), ["Size"] = UDim2["new"](0, 16, 0, 16), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "›", ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 14, ["ZIndex"] = 24})}}, yx)
    lb["MouseEnter"]:Connect(function() d:Tween(lb, {["BackgroundColor3"] = Color3["fromRGB"](30, 18, 52)}, 0.15, Enum["EasingStyle"]["Quint"]) end)
    lb["MouseLeave"]:Connect(function() d:Tween(lb, {["BackgroundColor3"] = Color3["fromRGB"](22, 14, 38)}, 0.2, Enum["EasingStyle"]["Quint"]) end)
    lb["MouseButton1Click"]:Connect(function() CircleClick(lb, k["X"], k["Y"]); Rx(); Ex() end)
    A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 28), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "Saves are stored per Roblox account", ["TextColor3"] = Color3["fromRGB"](130, 110, 170), ["TextSize"] = 9, ["TextWrapped"] = true, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 23}, yx)
    local Fb = c:Get("_saveSlots", {})
    local Ab = {}
    local Nb = nil
    local gb = false
    local Db = ""
    local Kb = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](18, 12, 30), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 52), ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.65, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](28, 18, 48)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](14, 10, 24))}), ["Rotation"] = 135})}}, px)
    local qb = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 7), ["Size"] = UDim2["new"](1, -20, 0, 16), ["Font"] = Enum["Font"]["GothamBold"], ["RichText"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["Text"] = string["format"]("Account: <font color=\"#C084FC\"><b>%s</b></font>", c:GetPlayerName()), ["TextColor3"] = Color3["fromRGB"](225, 200, 255), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, Kb)
    local Qb = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 26), ["Size"] = UDim2["new"](1, -20, 0, 16), ["Font"] = Enum["Font"]["Gotham"], ["RichText"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["Text"] = string["format"]("Profile: <font color=\"#C084FC\"><b>%s</b></font>  •  ID: <font color=\"#34D399\">%s</font>", c["ActiveProfile"] or "[Auto]", c:GetGameId()), ["TextColor3"] = Color3["fromRGB"](165, 140, 205), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, Kb)
    local Sb = A("Frame", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 28), ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["FillDirection"] = Enum["FillDirection"]["Horizontal"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)})}}, px)
    local Tb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](70, 35, 150), ["BackgroundTransparency"] = 0.35, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.32, 0, 1, 0), ["Text"] = "Quick Save", ["TextColor3"] = Color3["fromRGB"](215, 185, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["LayoutOrder"] = 1, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](150, 100, 235), ["Transparency"] = 0.6, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Sb)
    local jb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](80, 50, 25), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.32, 0, 1, 0), ["Text"] = "Reset All", ["TextColor3"] = Color3["fromRGB"](255, 190, 110), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["LayoutOrder"] = 2, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](255, 170, 80), ["Transparency"] = 0.65, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Sb)
    local zb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](110, 18, 36), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.33, 0, 1, 0), ["Text"] = "Clear All", ["TextColor3"] = Color3["fromRGB"](255, 110, 130), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["LayoutOrder"] = 3, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](255, 95, 120), ["Transparency"] = 0.65, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Sb)
    Tb["MouseEnter"]:Connect(function() d:Tween(Tb, {["BackgroundTransparency"] = 0.15}, 0.12) end)
    Tb["MouseLeave"]:Connect(function() d:Tween(Tb, {["BackgroundTransparency"] = 0.35}, 0.18) end)
    jb["MouseEnter"]:Connect(function() d:Tween(jb, {["BackgroundTransparency"] = 0.2}, 0.12) end)
    jb["MouseLeave"]:Connect(function() d:Tween(jb, {["BackgroundTransparency"] = 0.4}, 0.18) end)
    zb["MouseEnter"]:Connect(function() d:Tween(zb, {["BackgroundTransparency"] = 0.2}, 0.12) end)
    zb["MouseLeave"]:Connect(function() d:Tween(zb, {["BackgroundTransparency"] = 0.4}, 0.18) end)
    Tb["MouseButton1Click"]:Connect(function() CircleClick(Tb, k["X"], k["Y"]); local d = c:GetSnapshot(); local L = c:Get("_saveSlots", {}); local C = c["ActiveProfile"] or "[Auto]"; local w = false; for e, L in ipairs(L) do if L["name"] == C then L["data"] = d; L["updated"] = os["date"]("%Y-%m-%d %H:%M"); w = true; break end end; if not w then table["insert"](L, {["name"] = C, ["data"] = d, ["created"] = os["date"]("%Y-%m-%d %H:%M"), ["updated"] = os["date"]("%Y-%m-%d %H:%M")}) end; c:Save("_saveSlots", L); e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Saved state to \"" .. (C .. "\".")}, {["Time"] = 2}); RefreshSlots() end)
    jb["MouseButton1Click"]:Connect(function() CircleClick(jb, k["X"], k["Y"]); c:ResetToDefaults(true); e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "All controls have been reset to default values."}, {["Time"] = 3}) end)
    zb["MouseButton1Click"]:Connect(function() CircleClick(zb, k["X"], k["Y"]); c:ClearAll(); c:Save("_saveSlots", {}); c:Save("_autoLoadTarget", nil); c["ActiveProfile"] = "[Auto]"; if Qb then Qb["Text"] = "Active Profile: <font color=\"#C084FC\"><b>[Auto]</b></font>" end; RefreshSlots(); e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "All saved profiles and data have been cleared."}, {["Time"] = 3}) end)
    local tb = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["ZIndex"] = 22, ["Children"] = {A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)}), A("UIPadding", {["PaddingTop"] = UDim["new"](0, 2), ["PaddingBottom"] = UDim["new"](0, 4)})}}, px)
    local ub = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["Visible"] = false, ["ZIndex"] = 22, ["Children"] = {A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)})}}, px)
    local Zb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](20, 14, 34), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 26), ["Text"] = "", ["AutoButtonColor"] = false, ["LayoutOrder"] = 1, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.6, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 8, 0, 0), ["Size"] = UDim2["new"](0, 16, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "‹", ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 16, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 24}), A("TextLabel", {["Name"] = "BackLabel", ["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 28, 0, 0), ["Size"] = UDim2["new"](1, -34, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Back to Profiles", ["TextColor3"] = Color3["fromRGB"](210, 180, 255), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24})}}, ub)
    local Yb = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["LayoutOrder"] = 2, ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)}), A("UIPadding", {["PaddingTop"] = UDim["new"](0, 4), ["PaddingBottom"] = UDim["new"](0, 4)})}}, ub)
    function O.SectionLabel(e, d)
        return A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 13), ["LayoutOrder"] = d, ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = e, ["TextColor3"] = Color3["fromRGB"](140, 105, 200), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, Yb)
    end
    O["SectionLabel"]("PROFILE NAME", 1)
    local ab = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](16, 11, 26), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 28), ["LayoutOrder"] = 2, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](130, 80, 210), ["Transparency"] = 0.68, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Yb)
    local xb = A("TextBox", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 0), ["Size"] = UDim2["new"](1, -70, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "", ["TextColor3"] = Color3["fromRGB"](220, 200, 255), ["PlaceholderText"] = "Enter profile name...", ["PlaceholderColor3"] = Color3["fromRGB"](110, 85, 150), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ClearTextOnFocus"] = false, ["ZIndex"] = 24}, ab)
    local Jb = A("TextButton", {["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundColor3"] = Color3["fromRGB"](80, 45, 160), ["BackgroundTransparency"] = 0.3, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -4, 0.5, 0), ["Size"] = UDim2["new"](0, 54, 0, 20), ["Text"] = "Rename", ["TextColor3"] = Color3["fromRGB"](220, 190, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["Visible"] = false, ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](150, 100, 230), ["Transparency"] = 0.5, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, ab)
    O["SectionLabel"]("AUTO LOAD SETTING", 3)
    local yb = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](16, 11, 26), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 30), ["LayoutOrder"] = 4, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](130, 80, 210), ["Transparency"] = 0.68, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 0), ["Size"] = UDim2["new"](1, -60, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Auto Load this Profile on Game Start", ["TextColor3"] = Color3["fromRGB"](200, 175, 240), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24})}}, Yb)
    local rb = A("Frame", {["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundColor3"] = Color3["fromRGB"](14, 9, 26), ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -8, 0.5, 0), ["Size"] = UDim2["new"](0, 36, 0, 18), ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](130, 80, 210), ["Transparency"] = 0.7, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, yb)
    local ib = A("Frame", {["AnchorPoint"] = Vector2["new"](0, 0.5), ["Position"] = UDim2["new"](0, 3, 0.5, 0), ["Size"] = UDim2["new"](0, 12, 0, 12), ["BorderSizePixel"] = 0, ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](110, 90, 140)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](55, 45, 85))}), ["Rotation"] = 135})}}, rb)
    local Rb = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Text"] = "", ["ZIndex"] = 26}, yb)
    O["SectionLabel"]("DATA INSPECTOR & PREVIEW", 5)
    local Hb = A("TextBox", {["BackgroundColor3"] = Color3["fromRGB"](10, 8, 16), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 22), ["LayoutOrder"] = 6, ["Font"] = Enum["Font"]["Gotham"], ["PlaceholderText"] = "Search saved keys...", ["PlaceholderColor3"] = Color3["fromRGB"](110, 85, 150), ["Text"] = "", ["TextColor3"] = Color3["fromRGB"](215, 190, 255), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ClearTextOnFocus"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](120, 75, 200), ["Transparency"] = 0.75, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 8)})}}, Yb)
    local Mb = A("ScrollingFrame", {["BackgroundColor3"] = Color3["fromRGB"](9, 6, 16), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 74), ["LayoutOrder"] = 7, ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["AutomaticCanvasSize"] = Enum["AutomaticSize"]["Y"], ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](120, 75, 200), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 2)}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 8), ["PaddingRight"] = UDim["new"](0, 6), ["PaddingTop"] = UDim["new"](0, 5), ["PaddingBottom"] = UDim["new"](0, 5)})}}, Yb)
    O["SectionLabel"]("ACTIONS", 8)
    local pb = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 26), ["LayoutOrder"] = 9, ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["FillDirection"] = Enum["FillDirection"]["Horizontal"], ["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["VerticalAlignment"] = Enum["VerticalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)})}}, Yb)
    local Gb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](80, 40, 170), ["BackgroundTransparency"] = 0.25, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.48, 0, 1, 0), ["LayoutOrder"] = 1, ["Text"] = "Load & Apply", ["TextColor3"] = Color3["fromRGB"](230, 205, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](190, 150, 255), ["Transparency"] = 0.5, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, pb)
    local Eb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](40, 80, 140), ["BackgroundTransparency"] = 0.25, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.48, 0, 1, 0), ["LayoutOrder"] = 2, ["Text"] = "Overwrite Current", ["TextColor3"] = Color3["fromRGB"](180, 220, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 190, 255), ["Transparency"] = 0.5, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, pb)
    local Vb = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 26), ["LayoutOrder"] = 10, ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["FillDirection"] = Enum["FillDirection"]["Horizontal"], ["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["VerticalAlignment"] = Enum["VerticalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)})}}, Yb)
    local nb = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](24, 18, 40), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.32, 0, 1, 0), ["LayoutOrder"] = 1, ["Text"] = "Clone", ["TextColor3"] = Color3["fromRGB"](205, 180, 245), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](130, 90, 210), ["Transparency"] = 0.65, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Vb)
    local ep = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](20, 75, 35), ["BackgroundTransparency"] = 0.25, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.32, 0, 1, 0), ["LayoutOrder"] = 2, ["Text"] = "Export Code", ["TextColor3"] = Color3["fromRGB"](120, 240, 160), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](90, 220, 130), ["Transparency"] = 0.6, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Vb)
    local dp = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](110, 18, 36), ["BackgroundTransparency"] = 0.25, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.32, 0, 1, 0), ["LayoutOrder"] = 3, ["Text"] = "Delete", ["TextColor3"] = Color3["fromRGB"](255, 110, 130), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](255, 95, 120), ["Transparency"] = 0.6, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Vb)
    local Lp = A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 16), ["LayoutOrder"] = 9, ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "PROFILES & SLOTS", ["TextColor3"] = Color3["fromRGB"](150, 115, 215), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 23}, tb)
    local Cp = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["LayoutOrder"] = 10, ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)})}}, tb)
    local wp = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](14, 10, 24), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 34), ["LayoutOrder"] = 11, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("UIStroke", {["Color"] = Color3["fromRGB"](140, 90, 220), ["Transparency"] = 0.7, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](30, 18, 55)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](14, 10, 24))}), ["Rotation"] = 135})}}, tb)
    local Up = A("TextBox", {["BackgroundColor3"] = Color3["fromRGB"](8, 6, 14), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["ClearTextOnFocus"] = false, ["Position"] = UDim2["new"](0, 8, 0.5, -10), ["Size"] = UDim2["new"](1, -82, 0, 20), ["PlaceholderText"] = "New profile name...", ["PlaceholderColor3"] = Color3["fromRGB"](110, 85, 150), ["Text"] = "", ["TextColor3"] = Color3["fromRGB"](220, 200, 255), ["Font"] = Enum["Font"]["Gotham"], ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](130, 80, 210), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 6)})}}, wp)
    local Bp = A("TextButton", {["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundColor3"] = Color3["fromRGB"](80, 40, 160), ["BackgroundTransparency"] = 0.25, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -6, 0.5, 0), ["Size"] = UDim2["new"](0, 62, 0, 22), ["Text"] = "+ Create", ["TextColor3"] = Color3["fromRGB"](220, 195, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](140, 80, 255)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](70, 35, 150))}), ["Rotation"] = 90})}}, wp)
    local hp = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](12, 9, 22), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 34), ["LayoutOrder"] = 12, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("UIStroke", {["Color"] = Color3["fromRGB"](80, 180, 120), ["Transparency"] = 0.7, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](20, 38, 28)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](12, 9, 22))}), ["Rotation"] = 135})}}, tb)
    local vp = A("TextBox", {["BackgroundColor3"] = Color3["fromRGB"](8, 6, 14), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["ClearTextOnFocus"] = false, ["Position"] = UDim2["new"](0, 8, 0.5, -10), ["Size"] = UDim2["new"](1, -82, 0, 20), ["PlaceholderText"] = "Paste share code...", ["PlaceholderColor3"] = Color3["fromRGB"](80, 130, 100), ["Text"] = "", ["TextColor3"] = Color3["fromRGB"](160, 240, 200), ["Font"] = Enum["Font"]["Gotham"], ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](80, 180, 120), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 6)})}}, hp)
    local Wp = A("TextButton", {["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundColor3"] = Color3["fromRGB"](30, 120, 70), ["BackgroundTransparency"] = 0.3, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -6, 0.5, 0), ["Size"] = UDim2["new"](0, 62, 0, 22), ["Text"] = "Import", ["TextColor3"] = Color3["fromRGB"](160, 250, 195), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](60, 200, 120)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](20, 100, 60))}), ["Rotation"] = 90})}}, hp)
    function O.ShowSettingsPage()
        ub["Visible"] = false
        tb["Visible"] = true
        px["CanvasPosition"] = Vector2["new"](0, 0)
    end
    function O.ShowSlotPage(e)
        tb["Visible"] = false
        ub["Visible"] = true
        px["CanvasPosition"] = Vector2["new"](0, 0)
        local d = c:Get("_saveSlots", {})
        local L = d[e]
        local C = Zb:FindFirstChild("BackLabel")
        if C and L then
            C["Text"] = L["name"] or "Slot " .. e
        end
    end
    function O.EncodeShareCode(e)
        local d, L = pcall(function() return JsonEncode(e) end)
        if d and L then
            return "QH-SAVE:" .. L
        end
        return nil
    end
    function O.DecodeShareCode(e)
        if not e then
            return nil
        end
        e = e:gsub("^%s+", ""):gsub("%s+$", "")
        if e:match("^QH%-SAVE:") then
            e = e:sub(9)
        end
        local d, L = pcall(function() return JsonDecode(e) end)
        if d and type(L) == "table" then
            return L
        end
        return nil
    end
    function O.UpdatePreview(e, d)
        for e, d in ipairs(Mb:GetChildren()) do
            if d:IsA("TextLabel") or d:IsA("Frame") then
                d:Destroy()
            end
        end
        if not e or not e["data"] then
            A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 16), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "(empty slot)", ["TextColor3"] = Color3["fromRGB"](110, 85, 140), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, Mb)
            return
        end
        d = d and string["lower"](d) or ""
        local L = 0
        for e, C in pairs(e["data"]) do
            if (d == "" or string["find"](string["lower"](tostring(e)), d, 1, true)) or string["find"](string["lower"](tostring(C)), d, 1, true) then
                L = L + 1
                if L > 40 then
                    A("TextLabel", {["BackgroundTransparency"] = 1, ["LayoutOrder"] = L, ["Size"] = UDim2["new"](1, 0, 0, 14), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "… + more items", ["TextColor3"] = Color3["fromRGB"](130, 95, 170), ["TextSize"] = 9, ["ZIndex"] = 24}, Mb)
                    break
                end
                local d = tostring(C)
                if type(C) == "table" then
                    local e, L = pcall(JsonEncode, C)
                    d = e and L or "[table]"
                end
                if #d > 32 then
                    d = d:sub(1, 30) .. "…"
                end
                local w = "#88bb99"
                if type(C) == "boolean" then
                    w = C and "#34D399" or "#F87171"
                elseif type(C) == "number" then
                    w = "#60A5FA"
                elseif type(C) == "table" then
                    w = "#FBBF24"
                end
                A("TextLabel", {["BackgroundTransparency"] = 1, ["LayoutOrder"] = L, ["Size"] = UDim2["new"](1, 0, 0, 14), ["Font"] = Enum["Font"]["Gotham"], ["RichText"] = true, ["Text"] = string["format"]("<font color=\"#C084FC\">%s</font> <font color=\"#6B7280\">=</font> <font color=\"%s\">%s</font>", tostring(e), w, d), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, Mb)
            end
        end
        if L == 0 then
            A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 16), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = d ~= "" and "(no matching keys)" or "(no data keys saved)", ["TextColor3"] = Color3["fromRGB"](110, 85, 140), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, Mb)
        end
    end
    Hb:GetPropertyChangedSignal("Text"):Connect(function() Db = Hb["Text"]; if Nb then local e = c:Get("_saveSlots", {}); local d = e[Nb]; if d then O["UpdatePreview"](d, Db) end end end)
    function O.OpenSlotPanel(e)
        Nb = e
        gb = true
        local d = c:Get("_saveSlots", {})
        local L = d[e]
        if not L then
            return
        end
        xb["Text"] = L["name"] or "Slot " .. e
        Jb["Visible"] = false
        Hb["Text"] = ""
        Db = ""
        local C = c:Get("_autoLoadTarget", nil)
        local w = C == L["name"]
        rb["BackgroundColor3"] = w and Color3["fromRGB"](90, 45, 170) or Color3["fromRGB"](14, 9, 26)
        ib["Position"] = w and UDim2["new"](0, 21, 0.5, 0) or UDim2["new"](0, 3, 0.5, 0)
        local U = ib:FindFirstChildOfClass("UIGradient")
        if U then
            U["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, w and Color3["fromRGB"](235, 205, 255) or Color3["fromRGB"](110, 90, 140)), ColorSequenceKeypoint["new"](1, w and Color3["fromRGB"](170, 105, 255) or Color3["fromRGB"](55, 45, 85))})
        end
        O["UpdatePreview"](L)
        O["ShowSlotPage"](e)
    end
    function O.CloseSlotPanel()
        gb = false
        Nb = nil
        O["ShowSettingsPage"]()
        RefreshSlots()
    end
    Zb["MouseButton1Click"]:Connect(function() CircleClick(Zb, k["X"], k["Y"]); O["CloseSlotPanel"]() end)
    Bp["MouseButton1Click"]:Connect(function() CircleClick(Bp, k["X"], k["Y"]); local d = c:Get("_saveSlots", {}); if #d >= 10 then e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Maximum 10 profiles reached."}, {["Time"] = 2}); return end; local L = Up["Text"] ~= "" and Up["Text"] or "Profile " .. #d + 1; local C = c:GetSnapshot(); local w = {["name"] = L, ["data"] = C, ["created"] = os["date"]("%Y-%m-%d %H:%M"), ["updated"] = os["date"]("%Y-%m-%d %H:%M")}; table["insert"](d, w); c:Save("_saveSlots", d); Up["Text"] = ""; e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Created profile \"" .. (L .. "\".")}, {["Time"] = 2}); RefreshSlots() end)
    xb:GetPropertyChangedSignal("Text"):Connect(function() if not Nb then return end; local e = c:Get("_saveSlots", {}); local d = e[Nb]; if d then Jb["Visible"] = xb["Text"] ~= d["name"] and xb["Text"] ~= "" end end)
    Jb["MouseButton1Click"]:Connect(function() if not Nb then return end; local d = c:Get("_saveSlots", {}); local L = d[Nb]; if not L then return end; local C = L["name"]; local w = xb["Text"] ~= "" and xb["Text"] or C; d[Nb]["name"] = w; if c:Get("_autoLoadTarget", nil) == C then c:Save("_autoLoadTarget", w) end; if c["ActiveProfile"] == C then c["ActiveProfile"] = w; if Qb then Qb["Text"] = string["format"]("Active Profile: <font color=\"#C084FC\"><b>%s</b></font>", w) end end; c:Save("_saveSlots", d); Jb["Visible"] = false; local U = Zb:FindFirstChild("BackLabel"); if U then U["Text"] = w end; e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Renamed to \"" .. (w .. "\".")}, {["Time"] = 2}); RefreshSlots() end)
    Rb["MouseButton1Click"]:Connect(function() if not Nb then return end; local L = c:Get("_saveSlots", {}); local C = L[Nb]; if not C then return end; local w = c:Get("_autoLoadTarget", nil); local U = not (w == C["name"]); c:Save("_autoLoadTarget", U and C["name"] or nil); d:Tween(ib, {["Position"] = U and UDim2["new"](0, 21, 0.5, 0) or UDim2["new"](0, 3, 0.5, 0)}, 0.22, Enum["EasingStyle"]["Back"]); d:Tween(rb, {["BackgroundColor3"] = U and Color3["fromRGB"](90, 45, 170) or Color3["fromRGB"](14, 9, 26)}, 0.2, Enum["EasingStyle"]["Quint"]); local B = ib:FindFirstChildOfClass("UIGradient"); if B then B["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, U and Color3["fromRGB"](235, 205, 255) or Color3["fromRGB"](110, 90, 140)), ColorSequenceKeypoint["new"](1, U and Color3["fromRGB"](170, 105, 255) or Color3["fromRGB"](55, 45, 85))}) end; e["Notification"]:Notify({["Title"] = "Auto Load", ["Description"] = U and "\"" .. (C["name"] .. "\" set as default auto-load profile.") or "Auto Load disabled."}, {["Time"] = 2}); RefreshSlots() end)
    Gb["MouseButton1Click"]:Connect(function() if not Nb then return end; CircleClick(Gb, k["X"], k["Y"]); local d = c:Get("_saveSlots", {}); local L = d[Nb]; if L and L["data"] then c:ApplySnapshot(L["data"], true); c["ActiveProfile"] = L["name"] or "Slot " .. Nb; if Qb then Qb["Text"] = string["format"]("Active Profile: <font color=\"#C084FC\"><b>%s</b></font>", c["ActiveProfile"]) end; e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Applied profile \"" .. ((L["name"] or "Slot") .. "\" to all controls.")}, {["Time"] = 3}); RefreshSlots() end end)
    Eb["MouseButton1Click"]:Connect(function() if not Nb then return end; CircleClick(Eb, k["X"], k["Y"]); local d = c:Get("_saveSlots", {}); local L = d[Nb]; if L then L["data"] = c:GetSnapshot(); L["updated"] = os["date"]("%Y-%m-%d %H:%M"); c:Save("_saveSlots", d); O["UpdatePreview"](L, Db); e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Overwrote \"" .. ((L["name"] or "profile") .. "\" with current state.")}, {["Time"] = 2}); RefreshSlots() end end)
    nb["MouseButton1Click"]:Connect(function() if not Nb then return end; CircleClick(nb, k["X"], k["Y"]); local d = c:Get("_saveSlots", {}); if #d >= 10 then e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Maximum 10 profiles reached."}, {["Time"] = 2}); return end; local L = d[Nb]; if L then local C = {}; for e, d in pairs(L["data"] or {}) do C[e] = d end; table["insert"](d, {["name"] = (L["name"] or "Profile") .. " (Copy)", ["data"] = C, ["created"] = os["date"]("%Y-%m-%d %H:%M"), ["updated"] = os["date"]("%Y-%m-%d %H:%M")}); c:Save("_saveSlots", d); e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Cloned \"" .. ((L["name"] or "profile") .. "\".")}, {["Time"] = 2}); RefreshSlots() end end)
    dp["MouseButton1Click"]:Connect(function() if not Nb then return end; CircleClick(dp, k["X"], k["Y"]); local d = c:Get("_saveSlots", {}); local L = d[Nb] and d[Nb]["name"]; table["remove"](d, Nb); c:Save("_saveSlots", d); if L and c:Get("_autoLoadTarget", nil) == L then c:Save("_autoLoadTarget", nil) end; if L and c["ActiveProfile"] == L then c["ActiveProfile"] = "[Auto]"; if Qb then Qb["Text"] = "Active Profile: <font color=\"#C084FC\"><b>[Auto]</b></font>" end end; e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Profile deleted."}, {["Time"] = 2}); O["CloseSlotPanel"]() end)
    ep["MouseButton1Click"]:Connect(function() if not Nb then return end; CircleClick(ep, k["X"], k["Y"]); local d = c:Get("_saveSlots", {}); local L = d[Nb]; if not L then return end; local C = O["EncodeShareCode"]({["name"] = L["name"], ["data"] = L["data"]}); if C then local d = (setclipboard or toclipboard) or getgenv and getgenv()["setclipboard"]; if d then pcall(d, C) end; e["Notification"]:Notify({["Title"] = "Share Saved", ["Description"] = "Share code copied to clipboard!"}, {["Time"] = 3}) else e["Notification"]:Notify({["Title"] = "Share Saved", ["Description"] = "Failed to encode save."}, {["Time"] = 2}) end end)
    Wp["MouseButton1Click"]:Connect(function() CircleClick(Wp, k["X"], k["Y"]); local d = vp["Text"]:gsub("`", ""); if d == "" then return end; local L = O["DecodeShareCode"](d); if not L then e["Notification"]:Notify({["Title"] = "Import", ["Description"] = "Invalid share code format."}, {["Time"] = 2}); return end; local C = c:Get("_saveSlots", {}); if #C >= 10 then e["Notification"]:Notify({["Title"] = "Import", ["Description"] = "Maximum 10 profiles reached."}, {["Time"] = 2}); return end; local w = (L["name"] or "Imported") .. " (imported)"; table["insert"](C, {["name"] = w, ["data"] = L["data"] or {}, ["created"] = os["date"]("%Y-%m-%d %H:%M"), ["updated"] = os["date"]("%Y-%m-%d %H:%M")}); c:Save("_saveSlots", C); vp["Text"] = ""; e["Notification"]:Notify({["Title"] = "Import", ["Description"] = "Imported profile \"" .. (w .. "\".")}, {["Time"] = 3}); RefreshSlots() end)
    local kp = Rx
    Rx = function() if gb then gb = false; Nb = nil; O["ShowSettingsPage"]() end; kp() end
    local op = Vx
    Vx = function() if gb then gb = false; Nb = nil; O["ShowSettingsPage"]() end; op() end
    function RefreshSlots()
        for e, d in ipairs(Ab) do
            d:Destroy()
        end
        Ab = {}
        Fb = c:Get("_saveSlots", {})
        local L = c:Get("_autoLoadTarget", nil)
        if Lp then
            Lp["Text"] = string["format"]("PROFILES & SLOTS (%d/10)", #Fb)
        end
        if #Fb == 0 then
            local e = A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 24), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "No saved profiles. Create or Quick Save above!", ["TextColor3"] = Color3["fromRGB"](130, 105, 160), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 23}, Cp)
            table["insert"](Ab, e)
        end
        for C, w in ipairs(Fb) do
            local U = L == w["name"]
            local B = c["ActiveProfile"] == w["name"]
            local h = Nb == C and gb
            local v = A("Frame", {["BackgroundColor3"] = h and Color3["fromRGB"](24, 16, 42) or Color3["fromRGB"](15, 10, 26), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 42), ["LayoutOrder"] = C, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("UIStroke", {["Color"] = h and Color3["fromRGB"](190, 130, 255) or (U and Color3["fromRGB"](160, 105, 240) or Color3["fromRGB"](90, 60, 150)), ["Transparency"] = h and 0.2 or (U and 0.4 or 0.75), ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, Cp)
            A("Frame", {["BackgroundColor3"] = U and Color3["fromRGB"](190, 140, 255) or Color3["fromRGB"](120, 70, 200), ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, 6), ["Size"] = UDim2["new"](0, 3, 1, -12), ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, v)
            local W = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](38, 22, 70), ["BackgroundTransparency"] = 0.2, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 10, 0.5, -10), ["Size"] = UDim2["new"](0, 20, 0, 20), ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = tostring(C), ["TextColor3"] = Color3["fromRGB"](200, 160, 255), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 25})}}, v)
            local o = 0
            if w["data"] then
                for e in pairs(w["data"]) do
                    o = o + 1
                end
            end
            local b = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 36, 0, 6), ["Size"] = UDim2["new"](1, -105, 0, 15), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = w["name"] or "Profile " .. C, ["TextColor3"] = h and Color3["fromRGB"](240, 220, 255) or (B and Color3["fromRGB"](225, 195, 255) or Color3["fromRGB"](190, 170, 230)), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["ZIndex"] = 24}, v)
            local P = string["format"]("%d keys", o)
            if U then
                P = P .. "  •  auto load"
            elseif B then
                P = P .. "  •  active"
            end
            local X = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 36, 0, 22), ["Size"] = UDim2["new"](1, -105, 0, 13), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = P, ["TextColor3"] = U and Color3["fromRGB"](180, 130, 255) or (B and Color3["fromRGB"](140, 220, 170) or Color3["fromRGB"](135, 115, 165)), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, v)
            local s = A("TextButton", {["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundColor3"] = Color3["fromRGB"](70, 35, 140), ["BackgroundTransparency"] = 0.35, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -8, 0.5, 0), ["Size"] = UDim2["new"](0, 48, 0, 22), ["Text"] = "Load", ["TextColor3"] = Color3["fromRGB"](215, 185, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 10, ["AutoButtonColor"] = false, ["ZIndex"] = 25, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](150, 100, 230), ["Transparency"] = 0.6, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, v)
            s["MouseEnter"]:Connect(function() d:Tween(s, {["BackgroundTransparency"] = 0.15}, 0.12) end)
            s["MouseLeave"]:Connect(function() d:Tween(s, {["BackgroundTransparency"] = 0.35}, 0.18) end)
            local I = C
            local m = w
            s["MouseButton1Click"]:Connect(function() CircleClick(s, k["X"], k["Y"]); if m and m["data"] then c:ApplySnapshot(m["data"], true); c["ActiveProfile"] = m["name"] or "Slot " .. I; if Qb then Qb["Text"] = string["format"]("Active Profile: <font color=\"#C084FC\"><b>%s</b></font>", c["ActiveProfile"]) end; e["Notification"]:Notify({["Title"] = "Save Manager", ["Description"] = "Loaded profile \"" .. ((m["name"] or "Slot") .. "\".")}, {["Time"] = 2}); RefreshSlots() end end)
            local f = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, -62, 1, 0), ["Position"] = UDim2["new"](0, 0, 0, 0), ["Text"] = "", ["ZIndex"] = 24}, v)
            f["MouseEnter"]:Connect(function() if not h then d:Tween(v, {["BackgroundColor3"] = Color3["fromRGB"](22, 14, 38)}, 0.12) end end)
            f["MouseLeave"]:Connect(function() d:Tween(v, {["BackgroundColor3"] = h and Color3["fromRGB"](24, 16, 42) or Color3["fromRGB"](15, 10, 26)}, 0.18) end)
            f["MouseButton1Click"]:Connect(function() CircleClick(f, k["X"], k["Y"]); if gb and Nb == I then O["CloseSlotPanel"]() else O["OpenSlotPanel"](I); RefreshSlots() end end)
            table["insert"](Ab, v)
        end
    end
    RefreshSlots()
    task["defer"](function() local e = c:Get("_autoLoadTarget", nil); if e then local d = c:Get("_saveSlots", {}); for d, L in ipairs(d) do if L["name"] == e and L["data"] then c:ApplySnapshot(L["data"], true); c["ActiveProfile"] = L["name"]; if Qb then Qb["Text"] = string["format"]("Active Profile: <font color=\"#C084FC\"><b>%s</b></font>", L["name"]) end; break end end end end)
    A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 16), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Theme Manager", ["TextColor3"] = Color3["fromRGB"](150, 105, 220), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 23}, yx)
    local bp = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 5)})}}, yx)
    local Pp = {}
    local Op = c:Get("_activeTheme", b)
    if u["Themes"][Op] then
        u["Current"] = u["Themes"][Op]
        kx["BackgroundColor3"] = u["Current"]["Body"]
    end
    function O.BuildThemeCards()
        for e, d in ipairs(Pp) do
            d:Destroy()
        end
        Pp = {}
        local L = {"Purple", "Crimson", "Ocean", "Emerald", "Sunset"}
        for L, C in ipairs(L) do
            local w = u["Themes"][C]
            local U = Op == C
            local B = w["Accent"]
            local h = w["AccentDark"]
            local v = w["PreviewColors"]
            local W = A("TextButton", {["BackgroundColor3"] = U and Color3["fromRGB"](20, 13, 36) or Color3["fromRGB"](14, 10, 22), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 44), ["Text"] = "", ["AutoButtonColor"] = false, ["ZIndex"] = 23, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 9)})}}, bp)
            local o = A("UIStroke", {["Color"] = U and B or Color3["fromRGB"](90, 60, 140), ["Transparency"] = U and 0.3 or 0.78, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, W)
            A("Frame", {["BackgroundColor3"] = B, ["BackgroundTransparency"] = U and 0 or 0.5, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, 7), ["Size"] = UDim2["new"](0, 3, 1, -14), ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, w["AccentLight"]), ColorSequenceKeypoint["new"](1, h)}), ["Rotation"] = 90})}}, W)
            local b = 12
            for e, d in ipairs(v) do
                A("Frame", {["BackgroundColor3"] = d, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, b, 0.5, -10), ["Size"] = UDim2["new"](0, 20, 0, 20), ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](255, 255, 255), ["Transparency"] = 0.85, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, W)
                b = b + 16
            end
            A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 72, 0, 0), ["Size"] = UDim2["new"](1, -130, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = w["DisplayName"], ["TextColor3"] = U and w["AccentLight"] or Color3["fromRGB"](185, 165, 215), ["TextSize"] = 12, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24}, W)
            local P = A("Frame", {["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundColor3"] = U and Color3["new"](h["R"] * 0.5, h["G"] * 0.5, h["B"] * 0.5) or Color3["fromRGB"](18, 12, 28), ["BackgroundTransparency"] = 0, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -8, 0.5, 0), ["Size"] = UDim2["new"](0, 62, 0, 22), ["ZIndex"] = 24, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = U and B or Color3["fromRGB"](90, 65, 130), ["Transparency"] = U and 0.35 or 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = U and "Active" or "Apply", ["TextColor3"] = U and w["AccentLight"] or Color3["fromRGB"](160, 130, 200), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 25})}}, W)
            table["insert"](Pp, W)
            local c = C
            W["MouseEnter"]:Connect(function() if Op ~= c then d:Tween(W, {["BackgroundColor3"] = Color3["fromRGB"](18, 13, 30)}, 0.15, Enum["EasingStyle"]["Quint"]); d:Tween(o, {["Transparency"] = 0.55}, 0.15) end end)
            W["MouseLeave"]:Connect(function() if Op ~= c then d:Tween(W, {["BackgroundColor3"] = Color3["fromRGB"](14, 10, 22)}, 0.2, Enum["EasingStyle"]["Quint"]); d:Tween(o, {["Transparency"] = 0.78}, 0.2) end end)
            W["MouseButton1Click"]:Connect(function() if Op == c then return end; CircleClick(W, k["X"], k["Y"]); Op = c; ApplyTheme(c); O["BuildThemeCards"](); e["Notification"]:Notify({["Title"] = "Theme Manager", ["Description"] = c .. " theme applied."}, {["Time"] = 2}) end)
        end
    end
    O["BuildThemeCards"]()
    A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 16), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Background Media", ["TextColor3"] = Color3["fromRGB"](150, 105, 220), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 23}, yx)
    A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 28), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "Drop .png/.jpg/.webm/.mp4 into Quantum Onyx Hub folder", ["TextColor3"] = Color3["fromRGB"](130, 110, 170), ["TextSize"] = 9, ["TextWrapped"] = true, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 23}, yx)
    local cp = A("ScrollingFrame", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 72), ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["ScrollingEnabled"] = true, ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 4), ["PaddingRight"] = UDim["new"](0, 4)})}}, yx)
    function O.BuildBgImageCards()
        for e, d in ipairs(cp:GetChildren()) do
            if d:IsA("TextButton") then
                d:Destroy()
            end
        end
        local d = j(c["FolderName"])
        local L = z(c["FolderName"])
        local C = {}
        for e, d in ipairs(d) do
            table["insert"](C, d)
        end
        for e, d in ipairs(L) do
            table["insert"](C, d)
        end
        local w = c:Get("_opt_BgImage", "")
        local U = A("TextButton", {["BackgroundColor3"] = w == "" and Color3["fromRGB"](22, 14, 38) or Color3["fromRGB"](14, 10, 22), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -8, 0, 28), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "None (theme default)", ["TextColor3"] = Color3["fromRGB"](185, 165, 215), ["TextSize"] = 10, ["ZIndex"] = 24, ["LayoutOrder"] = 0, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)})}}, cp)
        U["MouseButton1Click"]:Connect(function() ApplyBackgroundImage(""); c:Save("_opt_BgImage", ""); O["BuildBgImageCards"]() end)
        for d, L in ipairs(C) do
            local C = L:match("([^/\\]+)$") or L
            local U = t(L)
            local B = w == L
            local h = A("TextButton", {["BackgroundColor3"] = B and Color3["fromRGB"](22, 14, 38) or Color3["fromRGB"](14, 10, 22), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -8, 0, 28), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = (B and "✓ " or "") .. ((U and "[VID] " or "") .. C), ["TextColor3"] = B and Color3["fromRGB"](210, 180, 255) or Color3["fromRGB"](160, 140, 200), ["TextSize"] = 10, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 24, ["LayoutOrder"] = d, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 10)})}}, cp)
            local v = L
            h["MouseButton1Click"]:Connect(function() ApplyBackgroundImage(v); O["BuildBgImageCards"](); e["Notification"]:Notify({["Title"] = "Background", ["Description"] = "Applied " .. C}, {["Time"] = 2}) end)
        end
        local B = cp:FindFirstChildOfClass("UIListLayout")
        if B then
            FitScrollCanvas(cp, B, "Y", 4)
        end
    end
    O["BuildBgImageCards"]()
    O["MakeMiniSlider"](yx, "BG Image Fade", "_opt_BgImageTransparency", 0.5, 1, c:Get("_opt_BgImageTransparency", 0.88), 0.02, function(e, d) if ox then ox["ImageTransparency"] = e end; if d then c:Save("_opt_BgImageTransparency", e) end end, nil, true)
    local Xp = { {["Name"] = "Default", ["Regular"] = Enum["Font"]["Gotham"], ["Bold"] = Enum["Font"]["GothamBold"], ["Display"] = Enum["Font"]["FredokaOne"]}, {["Name"] = "Gotham", ["Regular"] = Enum["Font"]["Gotham"], ["Bold"] = Enum["Font"]["GothamBold"], ["Display"] = Enum["Font"]["FredokaOne"]}, {["Name"] = "Source Sans", ["Regular"] = Enum["Font"]["SourceSans"], ["Bold"] = Enum["Font"]["SourceSansBold"], ["Display"] = Enum["Font"]["SourceSansBold"]}, {["Name"] = "Nunito", ["Regular"] = Enum["Font"]["Nunito"], ["Bold"] = Enum["Font"]["Nunito"], ["Display"] = Enum["Font"]["Nunito"]}, {["Name"] = "Oswald", ["Regular"] = Enum["Font"]["Oswald"], ["Bold"] = Enum["Font"]["Oswald"], ["Display"] = Enum["Font"]["Oswald"]}, {["Name"] = "Ubuntu", ["Regular"] = Enum["Font"]["Ubuntu"], ["Bold"] = Enum["Font"]["Ubuntu"], ["Display"] = Enum["Font"]["Ubuntu"]}, {["Name"] = "Roboto", ["Regular"] = Enum["Font"]["Roboto"], ["Bold"] = Enum["Font"]["Roboto"], ["Display"] = Enum["Font"]["RobotoCondensed"]}, {["Name"] = "Arcade", ["Regular"] = Enum["Font"]["Arcade"], ["Bold"] = Enum["Font"]["Arcade"], ["Display"] = Enum["Font"]["Arcade"]}, {["Name"] = "Code", ["Regular"] = Enum["Font"]["Code"], ["Bold"] = Enum["Font"]["Code"], ["Display"] = Enum["Font"]["Code"]}, }
    local sp = { [Enum["Font"]["Gotham"]] = "Regular", [Enum["Font"]["SourceSans"]] = "Regular", [Enum["Font"]["Nunito"]] = "Regular", [Enum["Font"]["Oswald"]] = "Regular", [Enum["Font"]["Ubuntu"]] = "Regular", [Enum["Font"]["Roboto"]] = "Regular", [Enum["Font"]["Arcade"]] = "Regular", [Enum["Font"]["Code"]] = "Regular", [Enum["Font"]["GothamBold"]] = "Bold", [Enum["Font"]["GothamSemibold"]] = "Bold", [Enum["Font"]["SourceSansBold"]] = "Bold", [Enum["Font"]["FredokaOne"]] = "Display", [Enum["Font"]["RobotoCondensed"]] = "Display", }
    function O.ResolveFontPreset(e)
        for d, L in ipairs(Xp) do
            if L["Name"] == e then
                return L
            end
        end
        return Xp[1]
    end
    function O.ApplyUIFont(e)
        local d = O["ResolveFontPreset"](e)
        c:Save("_opt_UIFont", d["Name"])
        local L = {["Regular"] = d["Regular"], ["Bold"] = d["Bold"], ["Display"] = d["Display"]}
        for e, C in ipairs(kx:GetDescendants()) do
            if (C:IsA("TextLabel") or C:IsA("TextButton")) or C:IsA("TextBox") then
                local e = sp[C["Font"]] or "Regular"
                pcall(function() C["Font"] = L[e] or d["Regular"] end)
            end
        end
    end
    A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 16), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "UI Font", ["TextColor3"] = Color3["fromRGB"](150, 105, 220), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 23}, yx)
    local Ip = A("ScrollingFrame", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 90), ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["ScrollingEnabled"] = true, ["ZIndex"] = 23, ["Children"] = {A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 4), ["PaddingRight"] = UDim["new"](0, 4)})}}, yx)
    function O.BuildFontCards()
        for e, d in ipairs(Ip:GetChildren()) do
            if d:IsA("TextButton") then
                d:Destroy()
            end
        end
        local d = c:Get("_opt_UIFont", "Gotham")
        for L, C in ipairs(Xp) do
            local w = d == C["Name"]
            local U = A("TextButton", {["BackgroundColor3"] = w and Color3["fromRGB"](22, 14, 38) or Color3["fromRGB"](14, 10, 22), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -8, 0, 26), ["Font"] = C["Bold"], ["Text"] = (w and "✓ " or "") .. C["Name"], ["TextColor3"] = w and Color3["fromRGB"](210, 180, 255) or Color3["fromRGB"](160, 140, 200), ["TextSize"] = 11, ["ZIndex"] = 24, ["LayoutOrder"] = L, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)})}}, Ip)
            local B = C["Name"]
            U["MouseButton1Click"]:Connect(function() O["ApplyUIFont"](B); O["BuildFontCards"](); e["Notification"]:Notify({["Title"] = "Font", ["Description"] = "Applied " .. B}, {["Time"] = 2}) end)
        end
        local L = Ip:FindFirstChildOfClass("UIListLayout")
        if L then
            FitScrollCanvas(Ip, L, "Y", 4)
        end
    end
    O["BuildFontCards"]()
    task["defer"](function() local e = c:Get("_opt_UIFont", "Default"); if e and (e ~= "Default" and e ~= "Gotham") then O["ApplyUIFont"](e) end end)
    O["MakeMiniSlider"](yx, "UI Transparency", "_opt_UITransparency", 0, 0.55, c:Get("_opt_UITransparency", 0.05), 0.01, function(e, d) if kx then kx["BackgroundTransparency"] = e end; if d then c:Save("_opt_UITransparency", e) end end, nil, true)
    Qx["MouseButton1Click"]:Connect(function() CircleClick(Qx, k["X"], k["Y"]); if Yx and Yx() then Zx() end; if nx and nx() then Vx() end; if O["BuildBgImageCards"] then O["BuildBgImageCards"]() end; ix() end)
    local mp = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](60, 60, 60), ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0.0160791595, 0, 0.219451368, 0), ["Size"] = UDim2["new"](0, 60, 0, 60), ["Visible"] = not S, ["Active"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, p)
    local fp = A("ImageButton", {["Name"] = "ToggleLogo", ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Image"] = "rbxassetid://87383580130479", ["Active"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, mp)
    local lp = {["on"] = false, ["moved"] = false, ["start"] = nil, ["origin"] = nil, ["input"] = nil}
    function O.PinToggleToOffset()
        s["PinAbsToOffset"](mp, p, dx["Scale"])
    end
    do
        local e = G and 12 or 5
        local function d(e)
            if lp["on"] then
                return
            end
            if e["UserInputType"] ~= Enum["UserInputType"]["MouseButton1"] and e["UserInputType"] ~= Enum["UserInputType"]["Touch"] then
                return
            end
            lp["on"] = true
            lp["input"] = e
            lp["moved"] = false
            lp["start"] = e["Position"]
            O["PinToggleToOffset"]()
            lp["origin"] = mp["Position"]
        end
        mp["InputBegan"]:Connect(d)
        fp["InputBegan"]:Connect(d)
        U["InputChanged"]:Connect(function(d) if ((not lp["on"] or not lp["start"]) or not lp["origin"]) or not lp["input"] then return end; if d == lp["input"] or lp["input"]["UserInputType"] == Enum["UserInputType"]["MouseButton1"] and d["UserInputType"] == Enum["UserInputType"]["MouseMovement"] then local L = (dx and dx["Scale"] > 0) and dx["Scale"] or 1; local C = (d["Position"] - lp["start"]) / L; if C["Magnitude"] > e then lp["moved"] = true; mp["Position"] = UDim2["fromOffset"](lp["origin"]["X"]["Offset"] + C["X"], lp["origin"]["Y"]["Offset"] + C["Y"]) end end end)
        U["InputEnded"]:Connect(function(e) if not lp["on"] then return end; if e == lp["input"] then lp["on"] = false; lp["input"] = nil; lp["start"] = nil; lp["origin"] = nil; task["delay"](0.08, function() lp["moved"] = false end) end end)
    end
    local Fp = false
    local function Ap()
        if not Fp then
            return
        end
        local e = kx["Position"]
        kx["Position"] = UDim2["new"](e["X"]["Scale"], e["X"]["Offset"] + 150, e["Y"]["Scale"], e["Y"]["Offset"] + 149)
        kx["Size"] = UDim2["new"](0, 510, 0, 330)
        sx["Size"] = UDim2["new"](1, -255, 0, 16)
        Ix["Size"] = UDim2["new"](1, -255, 0, 12)
        gx["Image"] = "rbxassetid://92966930061759"
        gx["Position"] = UDim2["new"](1, -34, 0, 16)
        Dx["Position"] = UDim2["new"](1, -8, 0, 16)
        Xx["BackgroundTransparency"] = 1
        if TabContainer then
            TabContainer["Visible"] = true
        end
        if MainContainer then
            MainContainer["Visible"] = true
        end
        if Kx then
            Kx["Visible"] = true
        end
        if Qx then
            Qx["Visible"] = true
        end
        if Dx then
            Dx["Visible"] = true
        end
        if Px and (bx and bx["Visible"]) then
            pcall(function() Px["Playing"] = true; Px:Play() end)
        end
        Fp = false
    end
    local function Np()
        if Fp then
            return
        end
        if Yx and Yx() then
            Zx()
        end
        if Hx and Hx() then
            Rx()
        end
        if nx and nx() then
            Vx()
        end
        if TabContainer then
            TabContainer["Visible"] = false
        end
        if MainContainer then
            MainContainer["Visible"] = false
        end
        if Kx then
            Kx["Visible"] = false
        end
        if Qx then
            Qx["Visible"] = false
        end
        gx["Position"] = UDim2["new"](1, -34, 0, 16)
        Dx["Position"] = UDim2["new"](1, -8, 0, 16)
        gx["Image"] = "rbxassetid://124967485209478"
        Xx["BackgroundTransparency"] = 0
        sx["Size"] = UDim2["new"](1, -65, 0, 16)
        Ix["Size"] = UDim2["new"](1, -65, 0, 12)
        local e = kx["Position"]
        kx["Position"] = UDim2["new"](e["X"]["Scale"], e["X"]["Offset"] - 150, e["Y"]["Scale"], e["Y"]["Offset"] - 149)
        kx["Size"] = UDim2["new"](0, 210, 0, 32)
        Fp = true
    end
    gx["MouseButton1Click"]:Connect(function() if Fp then Ap() else Np() end end)
    local gp = A("Frame", {["Name"] = "BlurOverlay", ["BackgroundColor3"] = Color3["fromRGB"](8, 6, 12), ["BackgroundTransparency"] = 0.35, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Position"] = UDim2["new"](0, 0, 0, 0), ["Visible"] = false, ["Active"] = true, ["ZIndex"] = 4000, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 10)}), A("TextButton", {["Name"] = "ClickBlocker", ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Position"] = UDim2["new"](0, 0, 0, 0), ["Text"] = "", ["AutoButtonColor"] = false, ["Active"] = true, ["ZIndex"] = 4000})}}, kx)
    local Dp = A("Frame", {["Name"] = "ComfirmDialog", ["BackgroundColor3"] = Color3["fromRGB"](18, 14, 26), ["BackgroundTransparency"] = 0.02, ["BorderSizePixel"] = 0, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["Size"] = UDim2["new"](0, 240, 0, 112), ["Visible"] = false, ["Active"] = true, ["ZIndex"] = 4001, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 10)})}}, gp)
    A("TextLabel", {["Name"] = "DialogTitle", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Position"] = UDim2["new"](0.5, 0, 0, 16), ["Size"] = UDim2["new"](1, -24, 0, 18), ["Text"] = "Are you sure?", ["TextColor3"] = Color3["fromRGB"](250, 245, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 13, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 4002}, Dp)
    A("TextLabel", {["Name"] = "DialogSubtitle", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Position"] = UDim2["new"](0.5, 0, 0, 36), ["Size"] = UDim2["new"](1, -24, 0, 16), ["Text"] = "Close and destroy interface?", ["TextColor3"] = Color3["fromRGB"](165, 150, 190), ["Font"] = Enum["Font"]["Gotham"], ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 4002}, Dp)
    local Kp = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](225, 45, 75), ["BackgroundTransparency"] = 0.05, ["TextColor3"] = Color3["fromRGB"](255, 255, 255), ["AnchorPoint"] = Vector2["new"](0, 1), ["Position"] = UDim2["new"](0, 16, 1, -14), ["Size"] = UDim2["new"](0, 96, 0, 28), ["Text"] = "Yes", ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 11, ["AutoButtonColor"] = false, ["Active"] = true, ["ZIndex"] = 4002, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, Dp)
    local qp = A("TextButton", {["Name"] = "CancelButton", ["BackgroundColor3"] = Color3["fromRGB"](28, 22, 38), ["BackgroundTransparency"] = 0.05, ["TextColor3"] = Color3["fromRGB"](200, 190, 225), ["AnchorPoint"] = Vector2["new"](1, 1), ["Position"] = UDim2["new"](1, -16, 1, -14), ["Size"] = UDim2["new"](0, 96, 0, 28), ["Text"] = "No", ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 11, ["AutoButtonColor"] = false, ["Active"] = true, ["ZIndex"] = 4002, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, Dp)
    local Qp = false
    Dx["MouseButton1Click"]:Connect(function() if Fp then Ap() end; if Yx and Yx() then Zx() end; if Hx and Hx() then Rx() end; if nx and nx() then Vx() end; gp["Visible"] = true; Dp["Visible"] = true end)
    Kp["MouseButton1Click"]:Connect(function() gp["Visible"] = false; Dp["Visible"] = false; C:DestroyGui() end)
    qp["MouseButton1Click"]:Connect(function() gp["Visible"] = false; Dp["Visible"] = false; if Qp then CloseFullLock() end end)
    U["InputBegan"]:Connect(function(e) if e["UserInputType"] ~= Enum["UserInputType"]["Keyboard"] then return end; if e["KeyCode"] == Enum["KeyCode"]["Unknown"] then return end; if lx then fx = e["KeyCode"]; c:Save("_opt_UIKeybind", e["KeyCode"]["Name"]); lx = false; if Fx then Fx["Text"] = e["KeyCode"]["Name"] end; return end; if U:GetFocusedTextBox() then return end; if e["KeyCode"] == fx then Nx() end end)
    local Sp = true
    Nx = function(e) local d = e; if d == nil then d = not Sp end; if d == Sp then return end; Sp = d; kx["Visible"] = d; mp["Visible"] = true; fp["Visible"] = true; if d then local e = c:Get("_opt_UITransparency", 0.05); kx["BackgroundTransparency"] = e; if Px and (bx and bx["Visible"]) then pcall(function() Px["Playing"] = true; Px:Play() end) end end end
    local Tp = 0
    local function jp()
        if lp["moved"] then
            return
        end
        local e = tick()
        if e - Tp < 0.2 then
            return
        end
        Tp = e
        Nx()
    end
    fp["Activated"]:Connect(jp)
    O["MakeDraggable"] = s["MakeDraggable"]
    s["MakeDraggable"](Xx, kx)
    local zp = A("Frame", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 40), ["Position"] = UDim2["new"](0, 0, 0, 36), ["ClipsDescendants"] = false}, kx)
    R = A("Frame", {["Name"] = "SearchBarFrame", ["BackgroundColor3"] = Color3["fromRGB"](22, 17, 34), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 8, 0, 1), ["Size"] = UDim2["new"](0, 126, 0, 22), ["ZIndex"] = 6, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, zp)
    A("ImageLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 6, 0.5, -6), ["Size"] = UDim2["new"](0, 12, 0, 12), ["Image"] = "rbxassetid://3926305904", ["ImageRectOffset"] = Vector2["new"](964, 324), ["ImageRectSize"] = Vector2["new"](36, 36), ["ImageColor3"] = Color3["fromRGB"](175, 140, 230), ["ZIndex"] = 7}, R)
    local tp = A("TextBox", {["Name"] = "SearchBox", ["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 21, 0, 0), ["Size"] = UDim2["new"](1, -36, 1, 0), ["Font"] = Enum["Font"]["Gotham"], ["PlaceholderText"] = "Search...", ["PlaceholderColor3"] = Color3["fromRGB"](135, 120, 165), ["Text"] = "", ["TextColor3"] = Color3["fromRGB"](235, 230, 250), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ClearTextOnFocus"] = false, ["ZIndex"] = 7}, R)
    local up = A("TextButton", {["Name"] = "SearchClear", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -3, 0.5, 0), ["Size"] = UDim2["new"](0, 14, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "×", ["TextColor3"] = Color3["fromRGB"](175, 145, 215), ["TextSize"] = 12, ["Visible"] = false, ["ZIndex"] = 8, ["AutoButtonColor"] = false}, R)
    local Zp = A("TextLabel", {["Name"] = "SearchCount", ["BackgroundColor3"] = Color3["fromRGB"](110, 60, 190), ["BackgroundTransparency"] = 0.2, ["AnchorPoint"] = Vector2["new"](1, 0), ["Position"] = UDim2["new"](1, -2, 0, -6), ["Size"] = UDim2["new"](0, 22, 0, 13), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "0", ["TextColor3"] = Color3["fromRGB"](240, 225, 255), ["TextSize"] = 9, ["Visible"] = false, ["ZIndex"] = 9, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, R)
    local Yp = A("ScrollingFrame", {["Active"] = true, ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 140, 0, -3), ["Size"] = UDim2["new"](1, -148, 0, 30), ["CanvasPosition"] = Vector2["new"](0, 0), ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["ScrollingDirection"] = Enum["ScrollingDirection"]["X"], ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)})}}, zp)
    local ap = A("UIListLayout", {["FillDirection"] = Enum["FillDirection"]["Horizontal"], ["VerticalAlignment"] = Enum["VerticalAlignment"]["Top"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 5)}, Yp)
    function O.RefreshTabScrollCanvas()
        DebouncedFitScrollCanvas(Yp, ap, "X", 4)
    end
    RegisterLayoutRefresh(function() FitScrollCanvas(Yp, ap, "X", 4) end)
    ap:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(O["RefreshTabScrollCanvas"])
    Yp:GetPropertyChangedSignal("AbsoluteSize"):Connect(O["RefreshTabScrollCanvas"])
    Yp["ChildAdded"]:Connect(O["RefreshTabScrollCanvas"])
    local xp = A("Frame", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0, 590, 0, 400), ["Position"] = UDim2["new"](0, 5, 0, 70)}, kx)
    local Jp = A("Folder", {["Name"] = "Container"}, xp)
    H = {}
    i = {}
    local yp = false
    local rp = nil
    local ip = nil
    local Rp = false
    local Hp = {}
    function O.ActivateScroll(e, L, C, w)
        if not w and Rp then
            return
        end
        if not w and rp == e then
            return
        end
        local U, B = 1, 1
        for d, L in ipairs(i) do
            if L["scrollFrame"] == rp then
                U = d
            end
            if L["scrollFrame"] == e then
                B = d
            end
        end
        local h = B > U and 1 or -1
        for L, C in ipairs(i) do
            d:Tween(C["tabButton"], {["TextColor3"] = Color3["fromRGB"](130, 120, 155)}, 0.2, Enum["EasingStyle"]["Quint"])
            if C["tabUnderline"]["Visible"] then
                d:Tween(C["tabUnderline"], {["Size"] = UDim2["new"](0, 0, 0, 3)}, 0.15, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["In"], function() C["tabUnderline"]["Visible"] = false; C["tabUnderline"]["Size"] = UDim2["new"](0.5, 0, 0, 3) end)
            end
            if C["scrollFrame"]["Visible"] and C["scrollFrame"] ~= e then
                local e = C["scrollFrame"]
                if not w then
                    Rp = true
                    d:Tween(e, {["Position"] = UDim2["new"](-0.04 * h, 0, 0, 0)}, 0.2, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["In"])
                    task["delay"](0.2, function() e["Visible"] = false; e["Position"] = UDim2["new"](0, 0, 0, 0) end)
                else
                    e["Visible"] = false
                    e["Position"] = UDim2["new"](0, 0, 0, 0)
                end
            end
        end
        if not w then
            task["delay"](0.15, function() e["Position"] = UDim2["new"](0.04 * h, 0, 0, 0); e["Visible"] = true; d:Tween(e, {["Position"] = UDim2["new"](0, 0, 0, 0)}, 0.28, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"]); task["delay"](0.28, function() Rp = false end) end)
        else
            e["Position"] = UDim2["new"](0, 0, 0, 0)
            e["Visible"] = true
            Rp = false
        end
        d:Tween(L, {["TextColor3"] = Color3["fromRGB"](255, 255, 255)}, 0.22, Enum["EasingStyle"]["Quint"])
        C["Size"] = UDim2["new"](0, 0, 0, 3)
        C["Visible"] = true
        d:Tween(C, {["Size"] = UDim2["new"](0.5, 0, 0, 3)}, 0.3, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"])
        rp = e
    end
    function O.RefreshSectionVisibility()
        local e, d = {}, {}
        for L, C in ipairs(H) do
            if not d[C["sectionScroll"]] then
                d[C["sectionScroll"]] = true
                table["insert"](e, C["sectionScroll"])
            end
        end
        for e, d in ipairs(e) do
            local L = false
            for e, C in ipairs(d:GetChildren()) do
                if C["Name"] == "Section" then
                    local e = false
                    for L, w in ipairs(H) do
                        if w["sectionScroll"] == d and (w["sectionFrame"] == C and w["elementFrame"]["Visible"]) then
                            e = true
                            break
                        end
                    end
                    C["Visible"] = e
                    if e then
                        L = true
                    end
                end
            end
            d["Visible"] = L
        end
        local L, C = {}, {}
        for e, d in ipairs(H) do
            if not L[d["scrollFrame"]] then
                L[d["scrollFrame"]] = true
                C[d["scrollFrame"]] = {}
            end
        end
        for e, d in ipairs(H) do
            local L = C[d["scrollFrame"]]
            local w = false
            for e, L in ipairs(L) do
                if L == d["sectionScroll"] then
                    w = true
                    break
                end
            end
            if not w then
                table["insert"](L, d["sectionScroll"])
            end
        end
        for e, d in pairs(C) do
            for e, d in ipairs(d) do
                if d["Visible"] then
                    d["Size"] = UDim2["new"](0, 240, 0, 260)
                end
            end
        end
    end
    local Mp = A("Frame", {["Name"] = "SearchHistoryFrame", ["BackgroundColor3"] = Color3["fromRGB"](16, 12, 24), ["BackgroundTransparency"] = 0.08, ["Position"] = UDim2["new"](0, 8, 0, 26), ["Size"] = UDim2["new"](0, 220, 0, 0), ["Visible"] = false, ["ZIndex"] = 50, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)}), A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 2)}), A("UIPadding", {["PaddingTop"] = UDim["new"](0, 6), ["PaddingBottom"] = UDim["new"](0, 6), ["PaddingLeft"] = UDim["new"](0, 6), ["PaddingRight"] = UDim["new"](0, 6)})}}, kx)
    local pp = A("ScrollingFrame", {["Name"] = "SearchTreeScroll", ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -8, 0, 0), ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["ZIndex"] = 51, ["Visible"] = false, ["AutomaticCanvasSize"] = Enum["AutomaticSize"]["None"], ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["ScrollingEnabled"] = true, ["Children"] = {A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 2)})}}, Mp)
    local function Gp()
        Mp["Visible"] = false
        Mp["Size"] = UDim2["new"](0, 220, 0, 0)
        pp["Visible"] = false
        pp["Size"] = UDim2["new"](1, -8, 0, 0)
        pp["CanvasSize"] = UDim2["new"](0, 0, 0, 0)
    end
    function O.fuzzyMatch(e, d)
        e = e:lower()
        d = d:lower()
        local L = 1
        local C = 1
        while L <= #d and C <= #e do
            if d:sub(L, L) == e:sub(C, C) then
                L = L + 1
            end
            C = C + 1
        end
        return L > #d
    end
    function O.SplitWords(e)
        local d = {}
        for e in string["gmatch"](string["lower"](e), "%S+") do
            table["insert"](d, e)
        end
        return d
    end
    function O.ScoreSearchEntry(e, d)
        local L = d:lower()
        local C = (e["title"] or ""):lower()
        local w = (e["menuTitle"] or ""):lower()
        local U = (e["tabTitle"] or ""):lower()
        local B = U .. (" " .. (w .. (" " .. C)))
        local h = 0
        if C == L then
            return 200
        end
        if C:sub(1, #L) == L then
            h = math["max"](h, 160)
        end
        if C:find(L, 1, true) then
            h = math["max"](h, 120)
        end
        if w:find(L, 1, true) then
            h = math["max"](h, 90)
        end
        if U:find(L, 1, true) then
            h = math["max"](h, 70)
        end
        local v = O["SplitWords"](L)
        if #v > 1 then
            local e = true
            local d = 0
            for L, C in ipairs(v) do
                if B:find(C, 1, true) then
                    d = d + 25
                else
                    e = false
                end
            end
            if e then
                h = math["max"](h, 100 + d)
            end
        end
        if O["fuzzyMatch"](C, d) then
            h = math["max"](h, 45)
        end
        if O["fuzzyMatch"](B, d) then
            h = math["max"](h, 35)
        end
        return h
    end
    local Ep = c:Get("_opt_SearchHistory", {})
    function O.SaveSearchToHistory(e)
        e = e:gsub("^%s+", ""):gsub("%s+$", "")
        if e == "" or #e < 2 then
            return
        end
        for d = #Ep, 1, -1 do
            if Ep[d] == e then
                table["remove"](Ep, d)
            end
        end
        table["insert"](Ep, 1, e)
        if #Ep > 8 then
            table["remove"](Ep, 9)
        end
        c:Save("_opt_SearchHistory", Ep)
    end
    function O.NavigateToSearchEntry(e)
        if not e then
            return
        end
        for d, L in ipairs(i) do
            if L["scrollFrame"] == e["scrollFrame"] then
                O["ActivateScroll"](L["scrollFrame"], L["tabButton"], L["tabUnderline"], true)
                break
            end
        end
        e["elementFrame"]["Visible"] = true
        e["sectionFrame"]["Visible"] = true
        e["sectionScroll"]["Visible"] = true
        O["RefreshSectionVisibility"]()
        task["defer"](function() local L = e["elementFrame"]; local C = e["sectionScroll"]; if not (L and (L["Parent"] and (C and C["Parent"]))) then return end; local w = (L["AbsolutePosition"]["Y"] - C["AbsolutePosition"]["Y"]) + C["CanvasPosition"]["Y"]; local U = math["max"](0, w - 40); d:Tween(C, {["CanvasPosition"] = Vector2["new"](0, U)}, 0.28, Enum["EasingStyle"]["Quint"]); local B = A("Frame", {["BackgroundColor3"] = ThemeColor("Accent") or Color3["fromRGB"](180, 120, 255), ["BackgroundTransparency"] = 0.35, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 1, 0), ["ZIndex"] = 50, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, L); d:Tween(B, {["BackgroundTransparency"] = 1}, 0.65, Enum["EasingStyle"]["Quad"], Enum["EasingDirection"]["Out"], function() if B then B:Destroy() end end); local h = L:FindFirstChildOfClass("UIStroke"); if not h then h = A("UIStroke", {["Color"] = ThemeColor("Accent") or Color3["fromRGB"](180, 120, 255), ["Transparency"] = 0.2, ["Thickness"] = 1.5, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, L); task["delay"](0.8, function() if h and h["Parent"] then h:Destroy() end end) else local e = h["Transparency"]; h["Transparency"] = 0.15; task["delay"](0.8, function() if h and h["Parent"] then h["Transparency"] = e end end) end end)
    end
    function O.UpdateSearchTreeUI(e, d)
        for e, d in ipairs(pp:GetChildren()) do
            if d:IsA("GuiObject") then
                d:Destroy()
            end
        end
        local L = 0
        local C = 0
        if (d == "" or not e) or #e == 0 then
            pp["Visible"] = false
            pp["Size"] = UDim2["new"](1, -8, 0, 0)
            pp["CanvasSize"] = UDim2["new"](0, 0, 0, 0)
            return 0
        end
        local w = {}
        for e, d in ipairs(e) do
            local L = d["tabTitle"] or "Tab"
            w[L] = w[L] or {}
            local C = d["menuTitle"] or "Section"
            w[L][C] = w[L][C] or {}
            table["insert"](w[L][C], d)
        end
        for e, d in pairs(w) do
            L = L + 1
            C = (C + 16) + 2
            A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 16), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "" .. e, ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["LayoutOrder"] = L, ["ZIndex"] = 10001}, pp)
            for e, d in pairs(d) do
                L = L + 1
                C = (C + 14) + 2
                A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, -8, 0, 14), ["Font"] = Enum["Font"]["GothamSemibold"], ["Text"] = "  └ " .. e, ["TextColor3"] = Color3["fromRGB"](160, 130, 200), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["LayoutOrder"] = L, ["ZIndex"] = 10001}, pp)
                for e, d in ipairs(d) do
                    L = L + 1
                    C = (C + 20) + 2
                    local w = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](22, 20, 28), ["BackgroundTransparency"] = 0.35, ["Size"] = UDim2["new"](1, -12, 0, 20), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "      • " .. (d["title"] or ""), ["TextColor3"] = Color3["fromRGB"](210, 195, 230), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["LayoutOrder"] = L, ["ZIndex"] = 10001, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 4)})}}, pp)
                    w["MouseButton1Click"]:Connect(function() O["NavigateToSearchEntry"](d); Gp() end)
                end
            end
        end
        if L <= 0 or C <= 0 then
            pp["Visible"] = false
            pp["Size"] = UDim2["new"](1, -8, 0, 0)
            pp["CanvasSize"] = UDim2["new"](0, 0, 0, 0)
            pp["ScrollingEnabled"] = false
            return 0
        end
        local U = math["max"](UnscaledLayout(pp["AbsoluteSize"]["Y"]), 1)
        local B = C > U + 1
        pp["CanvasSize"] = UDim2["new"](0, 0, 0, B and C or 0)
        pp["ScrollingEnabled"] = B
        pp["ElasticBehavior"] = Enum["ElasticBehavior"]["Never"]
        pp["Visible"] = true
        return C
    end
    function O.UpdateHistoryUI(e)
        for e, d in ipairs(Mp:GetChildren()) do
            if d:IsA("TextButton") or d:IsA("TextLabel") then
                if d["Name"] ~= "SearchTreeScroll" and d ~= pp then
                    d:Destroy()
                end
            end
        end
        local d = 0
        if e then
            local e = 0
            if pp["Visible"] then
                e = pp["CanvasSize"]["Y"]["Offset"]
            end
            if e <= 0 then
                Gp()
                return
            end
            local L = math["min"](e, 180)
            pp["Size"] = UDim2["new"](1, -8, 0, L)
            d = L + 12
        else
            pp["Visible"] = false
            pp["Size"] = UDim2["new"](1, -8, 0, 0)
            if #Ep <= 0 then
                Gp()
                return
            end
            A("TextLabel", {["Name"] = "HistoryHeader", ["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "Recent", ["TextColor3"] = Color3["fromRGB"](140, 110, 190), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["LayoutOrder"] = 1, ["ZIndex"] = 10000}, Mp)
            for e, d in ipairs(Ep) do
                local L = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](22, 20, 28), ["BackgroundTransparency"] = 0.5, ["Size"] = UDim2["new"](1, 0, 0, 20), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "  " .. d, ["TextColor3"] = Color3["fromRGB"](180, 160, 200), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["LayoutOrder"] = e + 1, ["ZIndex"] = 10000, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 4)})}}, Mp)
                L["MouseButton1Click"]:Connect(function() tp["Text"] = d; DoSearch(d); Gp() end)
            end
            d = (#Ep + 1) * 22 + 12
        end
        if d <= 0 then
            Gp()
            return
        end
        Mp["Size"] = UDim2["new"](0, 220, 0, d)
        Mp["Visible"] = true
    end
    function DoSearch(e)
        e = e:lower():gsub("^%s+", ""):gsub("%s+$", "")
        up["Visible"] = e ~= ""
        if e == "" then
            yp = false
            Hp = {}
            Zp["Visible"] = false
            O["UpdateSearchTreeUI"]({}, "")
            Gp()
            for e, d in ipairs(H) do
                d["elementFrame"]["Visible"] = true
                d["sectionFrame"]["Visible"] = true
                d["sectionScroll"]["Visible"] = true
                d["sectionScroll"]["Size"] = UDim2["new"](0, 240, 0, 260)
            end
            for e, d in ipairs(i) do
                d["tabButton"]["Visible"] = true
            end
            if ip then
                for e, d in ipairs(i) do
                    if d["scrollFrame"] == ip then
                        O["ActivateScroll"](d["scrollFrame"], d["tabButton"], d["tabUnderline"], true)
                        break
                    end
                end
                ip = nil
            else
                if #i > 0 then
                    local e = i[1]
                    O["ActivateScroll"](e["scrollFrame"], e["tabButton"], e["tabUnderline"])
                end
            end
            return
        end
        if not yp then
            yp = true
            ip = rp
        end
        for e, d in ipairs(H) do
            d["elementFrame"]["Visible"] = false
        end
        for e, d in ipairs(i) do
            d["tabButton"]["Visible"] = false
            d["scrollFrame"]["Visible"] = false
            d["tabButton"]["TextColor3"] = Color3["fromRGB"](200, 200, 200)
            d["tabUnderline"]["Visible"] = false
        end
        local d, L = {}, {}
        local C = {}
        for d, L in ipairs(H) do
            local w = O["ScoreSearchEntry"](L, e)
            if w > 0 then
                table["insert"](C, {["entry"] = L, ["score"] = w})
            end
        end
        table["sort"](C, function(e, d) return e["score"] > d["score"] end)
        Hp = {}
        for e, C in ipairs(C) do
            local w = C["entry"]
            table["insert"](Hp, w)
            w["elementFrame"]["Visible"] = true
            if not L[w["scrollFrame"]] then
                L[w["scrollFrame"]] = true
                table["insert"](d, w["scrollFrame"])
            end
            for e, d in ipairs(i) do
                if d["scrollFrame"] == w["scrollFrame"] then
                    d["tabButton"]["Visible"] = true
                    break
                end
            end
        end
        local w = #Hp
        Zp["Visible"] = w > 0
        Zp["Text"] = tostring(w)
        Zp["Size"] = UDim2["new"](0, math["max"](22, #tostring(w) * 8 + 10), 0, 14)
        local U = O["UpdateSearchTreeUI"](Hp, e)
        if U <= 0 then
            Gp()
        else
            O["UpdateHistoryUI"](true)
        end
        if #d == 0 then
            return
        end
        O["RefreshSectionVisibility"]()
        for e, L in ipairs(i) do
            if L["scrollFrame"] == d[1] then
                O["ActivateScroll"](L["scrollFrame"], L["tabButton"], L["tabUnderline"], true)
                break
            end
        end
    end
    local Vp = 0
    tp:GetPropertyChangedSignal("Text"):Connect(function() local e = tp["Text"]; up["Visible"] = e ~= ""; Vp = Vp + 1; local d = Vp; task["delay"](0.08, function() if d ~= Vp then return end; DoSearch(e); if e == "" then Gp() end end) end)
    up["MouseButton1Click"]:Connect(function() tp["Text"] = ""; DoSearch(""); Gp(); tp:CaptureFocus() end)
    tp["Focused"]:Connect(function() d:Tween(R, {["BackgroundTransparency"] = 0.2}, 0.15); local e = tp["Text"]:gsub("^%s+", ""):gsub("%s+$", ""); if e ~= "" and #Hp > 0 then O["UpdateSearchTreeUI"](Hp, e); O["UpdateHistoryUI"](true) elseif e == "" and #Ep > 0 then O["UpdateHistoryUI"](false) else Gp() end end)
    tp["FocusLost"]:Connect(function(e) d:Tween(R, {["BackgroundTransparency"] = 0.4}, 0.2); if e then O["SaveSearchToHistory"](tp["Text"]) end; task["delay"](0.25, function() if not tp:IsFocused() then Gp() end end) end)
    local np = {}
    local e6 = true
    function np.AddTab(B, L, C, w)
        if not checkCondition(w) then
            return y
        end
        local v = { ["cat-quantum"] = "rbxassetid://82115431450716", ["home-quantum"] = "rbxassetid://130439434919073", ["swords-quantum"] = "rbxassetid://88173691221304", ["rabbit-quantum"] = "rbxassetid://138575837887336", ["ship-quantum"] = "rbxassetid://115481449706054", ["visual-quantum"] = "rbxassetid://102173201308116", ["info-quantum"] = "rbxassetid://88050097561287", ["misc-quantum"] = "rbxassetid://137985950260873", ["cart-quantum"] = "rbxassetid://137995400175306", ["cherry-quantum"] = "rbxassetid://122029349593217", ["map-quantum"] = "rbxassetid://125480398387209", ["raid-quantum"] = "rbxassetid://104575804564229", ["user-quantum"] = "rbxassetid://83474083071373", ["settings-quantum"] = "rbxassetid://81151604784579", ["bio-quantum"] = "rbxassetid://132316362727024", ["craft-quantum"] = "rbxassetid://118197342073112", }
        local W, o, b = 16, 6, 12
        local P = 14
        local X = A("TextButton", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["AutoButtonColor"] = false, ["Font"] = Enum["Font"]["FredokaOne"], ["TextColor3"] = Color3["fromRGB"](200, 200, 200), ["TextSize"] = P, ["TextXAlignment"] = Enum["TextXAlignment"]["Right"], ["Text"] = L, ["ClipsDescendants"] = false, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 7)}), A("ImageLabel", {["Name"] = "TabIcon", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](0, 0.5), ["Size"] = UDim2["new"](0, W, 0, W), ["Position"] = UDim2["new"](0, 5, 0.5, 0), ["Image"] = v[C] or "", ["ScaleType"] = Enum["ScaleType"]["Fit"]})}}, nil)
        local function I()
            local e = h:GetTextSize(L, P, Enum["Font"]["FredokaOne"], Vector2["new"](4096, 24))["X"]
            X["Size"] = UDim2["new"](0, ((o + W) + b) + e, 0, 24)
        end
        RegisterLayoutRefresh(I)
        I()
        local m = A("Frame", {["Name"] = "Tab_Underline", ["BackgroundColor3"] = Color3["fromRGB"](110, 55, 190), ["BorderSizePixel"] = 0, ["AnchorPoint"] = Vector2["new"](0.5, 0), ["Size"] = UDim2["new"](0.5, 0, 0, 3), ["Position"] = UDim2["new"](0.5, 0, 1, 1), ["Visible"] = false, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](160, 100, 255)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](90, 40, 180))}), ["Rotation"] = 0})}}, X)
        X["Parent"] = Yp
        local f = A("ScrollingFrame", {["Name"] = "ScrollingFrame", ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 0, 0, 0), ["Size"] = UDim2["new"](1, 0, 1, 0), ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ScrollBarImageColor3"] = Color3["fromRGB"](0, 0, 0), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["ScrollingDirection"] = Enum["ScrollingDirection"]["X"], ["ElasticBehavior"] = Enum["ElasticBehavior"]["Never"], ["ScrollingEnabled"] = false, ["Visible"] = false, ["ClipsDescendants"] = true}, Jp)
        local l = A("UIListLayout", {["Name"] = "Scrolling_Layout", ["FillDirection"] = Enum["FillDirection"]["Horizontal"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 19)}, f)
        local function F()
            DebouncedFitScrollCanvas(f, l, "X", 4)
        end
        RegisterLayoutRefresh(function() FitScrollCanvas(f, l, "X", 4) end)
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(F)
        f:GetPropertyChangedSignal("AbsoluteSize"):Connect(F)
        f["ChildAdded"]:Connect(F)
        f["ChildRemoved"]:Connect(F)
        table["insert"](i, {["tabButton"] = X, ["tabUnderline"] = m, ["scrollFrame"] = f})
        if e6 then
            e6 = false
            O["ActivateScroll"](f, X, m)
        end
        X["MouseButton1Click"]:Connect(function() if yp then O["ActivateScroll"](f, X, m); O["RefreshSectionVisibility"]() else if tp["Text"] ~= "" then tp["Text"] = "" end; O["ActivateScroll"](f, X, m) end end)
        local N = {}
        function N.addSection(w, C)
            if not checkCondition(C) then
                return y
            end
            local B = A("ScrollingFrame", {["Name"] = "SectionScroll", ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0, 240, 0, 260), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["Active"] = true, ["ClipsDescendants"] = true, ["ScrollingDirection"] = Enum["ScrollingDirection"]["Y"], ["AutomaticCanvasSize"] = Enum["AutomaticSize"]["Y"], ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["ScrollingEnabled"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}}, f)
            local h = A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 7)}, B)
            local function v()
                DebouncedFitScrollCanvas(B, h, "Y", 4)
            end
            RegisterLayoutRefresh(function() FitScrollCanvas(B, h, "Y", 4) end)
            h:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(v)
            B:GetPropertyChangedSignal("AbsoluteSize"):Connect(v)
            B["ChildAdded"]:Connect(v)
            B["ChildRemoved"]:Connect(v)
            local W = {}
            function W.addMenu(h, C, w)
                if not checkCondition(w) then
                    return y
                end
                local v = A("Frame", {["Name"] = "Section", ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.48, 0, 0, 20), ["ClipsDescendants"] = false}, B)
                local W = A("Frame", {["Name"] = "InnerSection", ["BackgroundColor3"] = Color3["fromRGB"](25, 25, 25), ["BackgroundTransparency"] = 0.3, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 5, 0, 0), ["Size"] = UDim2["new"](1, -5, 0, 25), ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, v)
                local o = A("UIListLayout", {["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 3)}, W)
                local b = A("Frame", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 22), ["Children"] = {A("TextLabel", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.6, 0, 1, 0), ["Position"] = UDim2["new"](0.2, 0, 0, 0), ["Font"] = Enum["Font"]["FredokaOne"], ["Text"] = C, ["TextColor3"] = Color3["fromRGB"](255, 255, 255), ["TextSize"] = 15, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["ZIndex"] = 3})}}, W)
                local P = A("UIGradient", {["Color"] = ThemeColor("Lit"), ["Rotation"] = 60})
                local I = A("UIGradient", {["Color"] = ThemeColor("Lit"), ["Rotation"] = 60})
                RegisterLitGradient(P)
                RegisterLitGradient(I)
                local m = A("Frame", {["BackgroundColor3"] = ThemeColor("Accent") or Color3["fromRGB"](150, 100, 255), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.2, 0, 0, 10), ["Position"] = UDim2["new"](0, 0, 0.5, -1), ["ZIndex"] = 2, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0.5)}), P}}, b)
                local l = A("Frame", {["BackgroundColor3"] = ThemeColor("Accent") or Color3["fromRGB"](150, 100, 255), ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](0.2, 0, 0, 10), ["Position"] = UDim2["new"](0.8, 0, 0.5, -1), ["ZIndex"] = 2, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0.5)}), I}}, b)
                RegisterThemeElement(m, "BackgroundColor3", "Accent")
                RegisterThemeElement(l, "BackgroundColor3", "Accent")
                local function F()
                    local e = math["max"](UnscaledLayout(o["AbsoluteContentSize"]["Y"]) + 4, 22)
                    v["Size"] = UDim2["new"](1, 0, 0, e)
                    W["Size"] = UDim2["new"](1, -10, 0, e)
                end
                RegisterLayoutRefresh(F)
                o:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(F)
                F()
                local function N(w, U)
                    w:SetAttribute("STX_SearchElement", true)
                    local h = { ["tabButton"] = X, ["scrollFrame"] = f, ["sectionScroll"] = B, ["sectionFrame"] = v, ["elementFrame"] = w, ["tabTitle"] = L, ["menuTitle"] = C, ["title"] = U or "", ["favKey"] = (L or "") .. ("|" .. ((C or "") .. ("|" .. (U or "")))), }
                    table["insert"](H, h)
                    M["Entries"][h["favKey"]] = h
                    local function W()
                        for e, d in ipairs(M["List"]) do
                            if d == h["favKey"] then
                                return true
                            end
                        end
                        return false
                    end
                    local function k()
                        local L = M["List"]
                        local C
                        for e, d in ipairs(L) do
                            if d == h["favKey"] then
                                C = e
                                break
                            end
                        end
                        if C then
                            table["remove"](L, C)
                            e["Notification"]:Notify({["Title"] = "Favorites", ["Description"] = "Removed " .. (h["title"] or "")}, {["Time"] = 2})
                        else
                            table["insert"](L, h["favKey"])
                            e["Notification"]:Notify({["Title"] = "Favorites", ["Description"] = "Pinned " .. (h["title"] or "")}, {["Time"] = 2})
                        end
                        c:Save("_favorites", L)
                        if M["Refresh"] then
                            M["Refresh"]()
                        end
                        local U = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](255, 200, 80), ["BackgroundTransparency"] = 0.4, ["Size"] = UDim2["new"](1, 0, 1, 0), ["ZIndex"] = 40, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, w)
                        d:Tween(U, {["BackgroundTransparency"] = 1}, 0.4, Enum["EasingStyle"]["Quad"], nil, function() if U then U:Destroy() end end)
                    end
                    local function o()
                        local e = w:FindFirstChild("_FavStar")
                        if e then
                            e:Destroy()
                        end
                        local d = W()
                        local L = A("TextButton", {["Name"] = "_FavStar", ["AnchorPoint"] = Vector2["new"](1, 0.5), ["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -6, 0.5, 0), ["Size"] = UDim2["new"](0, 22, 0, 22), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = d and "★" or "☆", ["TextColor3"] = d and Color3["fromRGB"](255, 210, 90) or Color3["fromRGB"](210, 180, 255), ["TextSize"] = 16, ["ZIndex"] = 60, ["AutoButtonColor"] = false}, w)
                        L["MouseButton1Click"]:Connect(function() k(); if L and L["Parent"] then L:Destroy() end end)
                        task["delay"](3.5, function() if L and L["Parent"] then L:Destroy() end end)
                    end
                    local b = 0
                    local P = Vector2["zero"]
                    w["InputBegan"]:Connect(function(e) if e["UserInputType"] == Enum["UserInputType"]["MouseButton2"] then o(); return end; if e["UserInputType"] == Enum["UserInputType"]["Touch"] then local d = os["clock"](); local L = Vector2["new"](e["Position"]["X"], e["Position"]["Y"]); if d - b <= 0.35 and (L - P)["Magnitude"] < 40 then b = 0; k() else b = d; P = L end end end)
                end
                local g = {}
                function g.addButton(B, e, L, C, w, U)
                    if not checkCondition(w) then
                        return y
                    end
                    L = L or function()  end
                    local h = A("TextButton", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -25, 0, 32), ["AutoButtonColor"] = false, ["Text"] = "", ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("TextLabel", {["Name"] = "ButtonLabel", ["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 0), ["Size"] = UDim2["new"](1, -36, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = e, ["TextColor3"] = Color3["fromRGB"](210, 210, 220), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextWrapped"] = false, ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["ZIndex"] = 3, ["Children"] = {MakeTextConstraint(15, 8)}}), A("TextLabel", {["Name"] = "Arrow", ["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -12, 0.5, 0), ["Size"] = UDim2["new"](0, 14, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "›", ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextScaled"] = true, ["ZIndex"] = 3})}}, W)
                    N(h, e)
                    local v = h:FindFirstChild("Arrow")
                    local o = h:FindFirstChild("ButtonLabel")
                    RegisterTranslatable(o, e)
                    h["MouseEnter"]:Connect(function() d:Tween(h, {["BackgroundTransparency"] = 0.28}, 0.2, Enum["EasingStyle"]["Quint"]); d:Tween(o, {["TextColor3"] = Color3["fromRGB"](235, 235, 245)}, 0.2); d:Tween(v, {["Position"] = UDim2["new"](1, -9, 0.5, 0), ["TextColor3"] = Color3["fromRGB"](216, 180, 254)}, 0.2, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"]) end)
                    h["MouseLeave"]:Connect(function() d:Tween(h, {["BackgroundTransparency"] = 0.4}, 0.25, Enum["EasingStyle"]["Quint"]); d:Tween(o, {["TextColor3"] = Color3["fromRGB"](210, 210, 220)}, 0.25); d:Tween(v, {["Position"] = UDim2["new"](1, -12, 0.5, 0), ["TextColor3"] = Color3["fromRGB"](192, 132, 252)}, 0.25, Enum["EasingStyle"]["Quint"]) end)
                    h["MouseButton1Click"]:Connect(function() CircleClick(h, k["X"], k["Y"]); d:Tween(v, {["Position"] = UDim2["new"](1, -6, 0.5, 0)}, 0.1, Enum["EasingStyle"]["Quart"]); task["delay"](0.1, function() d:Tween(v, {["Position"] = UDim2["new"](1, -9, 0.5, 0)}, 0.25, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"]) end); L() end)
                    RegisterKeyLocked(h, C)
                end
                function g.addToggle(b, e, L, C, w, U, B, h, v, o)
                    if not checkCondition(h) then
                        return y
                    end
                    C = C or function()  end
                    L = L or false
                    if B then
                        c:RegisterKey(B)
                    end
                    if B then
                        if (not w or O["HasKeyAccess"]()) and not IsFullLocked() then
                            local e = c:Get(B, nil)
                            if e ~= nil then
                                L = e
                            end
                        end
                    end
                    local P, X = s["DescMetrics"](U, Enum["Font"]["Gotham"], 11, 150)
                    local I = X > 0 and 28 + X or 32
                    local m = A("TextButton", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.4, ["Size"] = UDim2["new"](1, -25, 0, I), ["Position"] = UDim2["new"](0, 0, 0, 0), ["BorderSizePixel"] = 0, ["AutoButtonColor"] = false, ["Text"] = "", ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, W)
                    N(m, e)
                    local f = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](15, 15, 15), ["Position"] = UDim2["new"](1, -50, 0.5, -9), ["Size"] = UDim2["new"](0, 36, 0, 18), ["BorderSizePixel"] = 0, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](100, 100, 100), ["Transparency"] = 0.8, ["Thickness"] = 2, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, m)
                    local l = A("ImageLabel", {["AnchorPoint"] = Vector2["new"](0, 0.5), ["Size"] = UDim2["fromOffset"](14, 14), ["Position"] = L and UDim2["new"](0, 19, 0.5, 0) or UDim2["new"](0, 2, 0.5, 0), ["Image"] = "http://www.roblox.com/asset/?id=12266946128", ["ImageTransparency"] = L and 0 or 0.5, ["BackgroundTransparency"] = 1, ["ImageColor3"] = Color3["fromRGB"](255, 255, 255)}, f)
                    local F = A("UIGradient", {["Color"] = ThemeColor("Lit"), ["Rotation"] = 90}, l)
                    F["Enabled"] = L
                    RegisterLitGradient(F)
                    local g = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 4), ["Size"] = UDim2["new"](1, -66, 0, 20), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = e, ["TextColor3"] = L and Color3["fromRGB"](220, 220, 220) or Color3["fromRGB"](180, 180, 180), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextWrapped"] = false, ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["Children"] = {MakeTextConstraint(14, 8)}}, m)
                    RegisterTranslatable(g, e)
                    if X > 0 then
                        local e = A("TextLabel", {["Name"] = "DescLabel", ["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 22), ["Size"] = UDim2["new"](1, -60, 0, X), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = P, ["TextColor3"] = Color3["fromRGB"](130, 130, 145), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextYAlignment"] = Enum["TextYAlignment"]["Top"], ["TextWrapped"] = true, ["TextSize"] = 11, ["ZIndex"] = 2}, m)
                        RegisterTranslatable(e, U)
                    end
                    local K = (w and not O["HasKeyAccess"]()) and false or L
                    local q = {}
                    local function Q()
                        for e, d in ipairs(q) do
                            if d["Optional"] then
                                d["Frame"]["Visible"] = K
                            end
                            if d["SetInteractable"] then
                                d["SetInteractable"](K)
                            end
                        end
                    end
                    local function S()
                        d:Tween(l, {["Position"] = K and UDim2["new"](0, 19, 0.5, 0) or UDim2["new"](0, 2, 0.5, 0), ["ImageTransparency"] = K and 0 or 0.5, ["ImageColor3"] = Color3["fromRGB"](255, 255, 255)}, 0.3, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["Out"])
                        F["Enabled"] = K
                        d:Tween(g, {["TextColor3"] = K and Color3["fromRGB"](230, 230, 230) or Color3["fromRGB"](120, 120, 120)}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                        if B and (not w or O["HasKeyAccess"]()) then
                            c:ElementSave(B, K)
                        end
                        C(K)
                        Q()
                    end
                    if B then
                        c:RegisterControl(B, {["Type"] = "Toggle", ["Default"] = L, ["Set"] = function(e, L) K = e == true; d:Tween(l, {["Position"] = K and UDim2["new"](0, 19, 0.5, 0) or UDim2["new"](0, 2, 0.5, 0), ["ImageTransparency"] = K and 0 or 0.5, ["ImageColor3"] = Color3["fromRGB"](255, 255, 255)}, 0.3, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["Out"]); F["Enabled"] = K; d:Tween(g, {["TextColor3"] = K and Color3["fromRGB"](230, 230, 230) or Color3["fromRGB"](120, 120, 120)}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"]); Q(); if L ~= false then pcall(C, K) end end, ["Get"] = function() return K end})
                    end
                    S()
                    m["Activated"]:Connect(function() CircleClick(m, k["X"], k["Y"]); K = not K; S() end)
                    if w and B then
                        table["insert"](D, {["saveKey"] = B, ["UpdateFn"] = function() if O["HasKeyAccess"]() then local e = c:Get(B, nil); K = e ~= nil and e or L; S() end end})
                    end
                    RegisterKeyLocked(m, w)
                    if type(v) == "table" then
                        local L = B or e:lower():gsub("%s+", "")
                        for C, U in ipairs(v) do
                            local B = (U["Title"] or U[1]) or "Sub Toggle"
                            local h = (U["Default"] or U[2]) or false
                            local v = (U["Callback"] or U[3]) or function()  end
                            local o = (U["SaveKey"] or U["savekey"]) or L .. ("_sub" .. C)
                            local b = U["Optional"] == true
                            c:RegisterKey(o)
                            if (not w or O["HasKeyAccess"]()) and not IsFullLocked() then
                                local e = c:Get(o, nil)
                                if e ~= nil then
                                    h = e
                                end
                            end
                            local P = A("TextButton", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.48, ["Size"] = UDim2["new"](1, -38, 0, 28), ["BorderSizePixel"] = 0, ["AutoButtonColor"] = false, ["Text"] = "", ["Active"] = K, ["Visible"] = not b or K, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, W)
                            N(P, B .. (" (" .. (e .. ")")))
                            local X = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](12, 12, 12), ["Position"] = UDim2["new"](1, -40, 0.5, -8), ["Size"] = UDim2["new"](0, 30, 0, 16), ["BorderSizePixel"] = 0, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](100, 100, 100), ["Transparency"] = 0.8, ["Thickness"] = 2, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, P)
                            local s = X["UIStroke"]
                            local I = A("ImageLabel", {["AnchorPoint"] = Vector2["new"](0, 0.5), ["Size"] = UDim2["fromOffset"](12, 12), ["Position"] = h and UDim2["new"](0, 16, 0.5, 0) or UDim2["new"](0, 2, 0.5, 0), ["Image"] = "http://www.roblox.com/asset/?id=12266946128", ["ImageTransparency"] = h and 0 or 0.5, ["BackgroundTransparency"] = 1, ["ImageColor3"] = Color3["fromRGB"](255, 255, 255)}, X)
                            local m = A("UIGradient", {["Color"] = ThemeColor("Lit"), ["Rotation"] = 90}, I)
                            m["Enabled"] = h
                            RegisterLitGradient(m)
                            local f = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 0), ["Size"] = UDim2["new"](1, -54, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = B, ["TextColor3"] = h and Color3["fromRGB"](205, 205, 210) or Color3["fromRGB"](145, 145, 150), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextWrapped"] = false, ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["Children"] = {MakeTextConstraint(13, 8)}}, P)
                            RegisterTranslatable(f, B)
                            local l = h
                            local function F()
                                d:Tween(I, {["Position"] = l and UDim2["new"](0, 16, 0.5, 0) or UDim2["new"](0, 2, 0.5, 0), ["ImageTransparency"] = l and 0 or 0.5}, 0.3, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["Out"])
                                m["Enabled"] = l
                                d:Tween(f, {["TextColor3"] = l and Color3["fromRGB"](205, 205, 210) or Color3["fromRGB"](145, 145, 150)}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                                d:Tween(P, {["BackgroundTransparency"] = l and 0.35 or 0.48}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                                if not w or O["HasKeyAccess"]() then
                                    c:ElementSave(o, l)
                                end
                                v(l)
                            end
                            if o then
                                c:RegisterControl(o, {["Type"] = "SubToggle", ["Default"] = (U["Default"] or U[2]) or false, ["Set"] = function(e, L) l = e == true; d:Tween(I, {["Position"] = l and UDim2["new"](0, 16, 0.5, 0) or UDim2["new"](0, 2, 0.5, 0), ["ImageTransparency"] = l and 0 or 0.5}, 0.3, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["Out"]); m["Enabled"] = l; d:Tween(f, {["TextColor3"] = l and Color3["fromRGB"](205, 205, 210) or Color3["fromRGB"](145, 145, 150)}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"]); d:Tween(P, {["BackgroundTransparency"] = l and 0.35 or 0.48}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"]); if L ~= false then pcall(v, l) end end, ["Get"] = function() return l end})
                            end
                            local function g(e)
                                P["Active"] = e
                                d:Tween(P, {["BackgroundTransparency"] = e and (l and 0.35 or 0.48) or 0.75}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                                d:Tween(f, {["TextTransparency"] = e and 0 or 0.6, ["TextColor3"] = e and (l and Color3["fromRGB"](205, 205, 210) or Color3["fromRGB"](145, 145, 150)) or Color3["fromRGB"](100, 100, 105)}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                                d:Tween(X, {["BackgroundTransparency"] = e and 0 or 0.65}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                                d:Tween(I, {["ImageTransparency"] = e and (l and 0 or 0.5) or 0.75}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                                d:Tween(s, {["Transparency"] = e and 0.8 or 0.9}, 0.3, Enum["EasingStyle"]["Sine"], Enum["EasingDirection"]["Out"])
                            end
                            P["Activated"]:Connect(function() if not K then return end; CircleClick(P, k["X"], k["Y"]); l = not l; F() end)
                            F()
                            g(K)
                            table["insert"](q, {["Frame"] = P, ["Optional"] = b, ["SetInteractable"] = g})
                        end
                    end
                    return {["Update"] = function(e) K = e; S() end, ["Get"] = function() return K end, ["Frame"] = m}
                end
                function g.addSlider(P, e, L, C, w, B, h, v, k, o, b)
                    if not checkCondition(o) then
                        return y
                    end
                    B = B or function()  end
                    L = L or 0
                    C = C or 100
                    v = v or 1
                    if k then
                        c:RegisterKey(k)
                    end
                    if k then
                        if not h or O["HasKeyAccess"]() then
                            local e = c:Get(k, nil)
                            if e ~= nil then
                                w = e
                            end
                        end
                    end
                    w = math["clamp"](w or L, L, C)
                    local X = select(2, tostring(v):find("%.")) and #tostring(v) - tostring(v):find("%.") or 0
                    local s = "%." .. (X .. "f")
                    local function I(e)
                        return math["floor"](e / v + 0.5) * v
                    end
                    local m = A("Frame", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.4, ["Size"] = UDim2["new"](1, -25, 0, 54), ["Position"] = UDim2["new"](0, 0, 0, 0), ["BorderSizePixel"] = 0, ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, W)
                    local f = A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 1, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, m)
                    local l = A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, -70, 0, 18), ["Position"] = UDim2["new"](0, 12, 0, 8), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = e, ["TextSize"] = 13, ["TextColor3"] = Color3["fromRGB"](220, 220, 230), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextWrapped"] = false, ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["ZIndex"] = 3, ["Children"] = {MakeTextConstraint(15, 8)}}, m)
                    RegisterTranslatable(l, e)
                    N(m, e)
                    local F = A("TextBox", {["BackgroundColor3"] = Color3["fromRGB"](12, 12, 18), ["BackgroundTransparency"] = 0.2, ["Position"] = UDim2["new"](1, -56, 0, 6), ["Size"] = UDim2["new"](0, 46, 0, 20), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = string["format"](s, w), ["TextSize"] = 12, ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextXAlignment"] = Enum["TextXAlignment"]["Center"], ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["ClipsDescendants"] = true, ["ClearTextOnFocus"] = false, ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, m)
                    local g = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](10, 10, 16), ["BackgroundTransparency"] = 0.1, ["Position"] = UDim2["new"](0, 12, 0, 34), ["Size"] = UDim2["new"](1, -24, 0, 10), ["ZIndex"] = 2, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 0.82, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, m)
                    local K = A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](139, 92, 246)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](216, 180, 254))}), ["Rotation"] = 0})
                    RegisterButtonGradient(K)
                    local q = A("Frame", {["BackgroundTransparency"] = 0, ["Size"] = UDim2["new"]((w - L) / (C - L), 0, 1, 0), ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), K}}, g)
                    local Q = A("Frame", {["Name"] = "Thumb", ["BackgroundColor3"] = Color3["fromRGB"](255, 255, 255), ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"]((w - L) / (C - L), 0, 0.5, 0), ["Size"] = UDim2["new"](0, 13, 0, 13), ["ZIndex"] = 5, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 0.3, ["Thickness"] = 1.5, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](192, 132, 252), ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["Size"] = UDim2["new"](0, 5, 0, 5), ["ZIndex"] = 6, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)})}})}}, g)
                    local S = false
                    local function T(e)
                        local w = (e - L) / (C - L)
                        q:TweenSize(UDim2["new"](w, 0, 1, 0), Enum["EasingDirection"]["Out"], Enum["EasingStyle"]["Quint"], 0.15, true)
                        d:Tween(Q, {["Position"] = UDim2["new"](w, 0, 0.5, 0)}, 0.15, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["Out"])
                        F["Text"] = string["format"](s, e)
                        if k and (not h or O["HasKeyAccess"]()) then
                            c:ElementSave(k, e)
                        end
                        B(e)
                    end
                    local function j(e)
                        local d = math["clamp"]((e - g["AbsolutePosition"]["X"]) / g["AbsoluteSize"]["X"], 0, 1)
                        T(I(L + (C - L) * d))
                    end
                    T(w)
                    local z = nil
                    local function t(e)
                        if z ~= nil then
                            return
                        end
                        if e["UserInputType"] == Enum["UserInputType"]["Touch"] or e["UserInputType"] == Enum["UserInputType"]["MouseButton1"] then
                            S = true
                            z = e
                            j(e["Position"]["X"])
                            d:Tween(f, {["Transparency"] = 0.45}, 0.15)
                            d:Tween(Q, {["Size"] = UDim2["new"](0, 15, 0, 15)}, 0.15, Enum["EasingStyle"]["Back"], Enum["EasingDirection"]["Out"])
                        end
                    end
                    g["InputBegan"]:Connect(t)
                    Q["InputBegan"]:Connect(t)
                    m["InputBegan"]:Connect(function(e) if e["UserInputType"] == Enum["UserInputType"]["Touch"] or e["UserInputType"] == Enum["UserInputType"]["MouseButton1"] then local d = e["Position"]["Y"] - m["AbsolutePosition"]["Y"]; if d >= 28 then t(e) end end end)
                    U["InputChanged"]:Connect(function(e) if not S or not z then return end; if e == z or z["UserInputType"] == Enum["UserInputType"]["MouseButton1"] and e["UserInputType"] == Enum["UserInputType"]["MouseMovement"] then j(e["Position"]["X"]) end end)
                    U["InputEnded"]:Connect(function(e) if e == z then S = false; z = nil; d:Tween(f, {["Transparency"] = 1}, 0.3); d:Tween(Q, {["Size"] = UDim2["new"](0, 13, 0, 13)}, 0.2, Enum["EasingStyle"]["Quint"]) end end)
                    F["FocusLost"]:Connect(function() local e = tonumber(F["Text"]); if e then T(I(math["clamp"](e, L, C))) else T(w) end end)
                    if k then
                        c:RegisterControl(k, {["Type"] = "Slider", ["Default"] = w, ["Set"] = function(e, U) e = tonumber(e) or w; e = math["clamp"](e, L, C); local h = (e - L) / (C - L); q:TweenSize(UDim2["new"](h, 0, 1, 0), Enum["EasingDirection"]["Out"], Enum["EasingStyle"]["Quint"], 0.15, true); d:Tween(Q, {["Position"] = UDim2["new"](h, 0, 0.5, 0)}, 0.15, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["Out"]); F["Text"] = string["format"](s, e); if U ~= false then pcall(B, e) end end, ["Get"] = function() return tonumber(F["Text"]) or w end})
                    end
                    if h and k then
                        table["insert"](D, {["saveKey"] = k, ["UpdateFn"] = function() if O["HasKeyAccess"]() then local e = c:Get(k, nil); T(math["clamp"](e ~= nil and e or w, L, C)) else T(w) end end})
                    end
                    RegisterKeyLocked(m, h)
                end
                function g.addDropdown(b, e, L, C, w, U, B, h, v, o)
                    if not checkCondition(v) then
                        return y
                    end
                    L = L or 1
                    C = C or {}
                    w = w or function()  end
                    if h then
                        c:RegisterKey(h)
                    end
                    if h then
                        if not U or O["HasKeyAccess"]() then
                            local e = c:Get(h, nil)
                            if e ~= nil then
                                L = e
                            end
                        end
                    end
                    local P = {}
                    local X = {}
                    local function s(e)
                        if not table["find"](P, e) then
                            table["insert"](P, e)
                        end
                    end
                    local function I(e)
                        for d, L in ipairs(P) do
                            if L == e then
                                table["remove"](P, d)
                                return
                            end
                        end
                    end
                    local function m()
                        local e = {}
                        for d, L in ipairs(P) do
                            e[#e + 1] = C[L]
                        end
                        return e
                    end
                    local function f(e, d)
                        d = d or 2
                        if #e == 0 then
                            return "None"
                        elseif #e <= d then
                            return table["concat"](e, ", ")
                        else
                            local L = {}
                            for d = 1, d, 1 do
                                L[d] = e[d]
                            end
                            return table["concat"](L, ", ") .. ("  +" .. #e - d)
                        end
                    end
                    local function l()
                        local function e(e)
                            if #C < 1 then
                                return
                            end
                            local d = type(e) == "number" and math["clamp"](e, 1, #C) or type(e) == "string" and table["find"](C, e)
                            if d then
                                s(d)
                            end
                        end
                        if B then
                            if typeof(L) == "table" then
                                for d, L in ipairs(L) do
                                    e(L)
                                end
                            else
                                e(L)
                            end
                            if #P == 0 and #C > 0 then
                                s(1)
                            end
                        else
                            e(L)
                            if #P == 0 and #C > 0 then
                                s(1)
                            end
                        end
                    end
                    l()
                    local F = A("Frame", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -25, 0, 32), ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, W)
                    local g = A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 1, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, F)
                    N(F, e)
                    local K = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 0), ["Size"] = UDim2["new"](1, -95, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["TextColor3"] = Color3["fromRGB"](220, 220, 230), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["Text"] = e, ["TextWrapped"] = false, ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["ZIndex"] = 3, ["Children"] = {MakeTextConstraint(15, 8)}}, F)
                    local q = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](12, 12, 18), ["BackgroundTransparency"] = 0.15, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](1, -90, 0.5, -11), ["Size"] = UDim2["new"](0, 68, 0, 22), ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 0.75, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, F)
                    local Q = A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, -8, 1, 0), ["Position"] = UDim2["new"](0, 6, 0, 0), ["Font"] = Enum["Font"]["GothamBold"], ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["Text"] = B and f(m(), 2) or (C[P[1]] or "None"), ["ZIndex"] = 4, ["Children"] = {MakeTextConstraint(13, 10)}}, q)
                    local S = A("ImageButton", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -8, 0.5, 0), ["Size"] = UDim2["new"](0, 16, 0, 16), ["Image"] = "rbxassetid://95968409641902", ["ImageColor3"] = Color3["fromRGB"](192, 132, 252), ["ZIndex"] = 3}, F)
                    local T = A("Frame", {["Visible"] = false, ["Active"] = true, ["BackgroundTransparency"] = 0.6, ["BackgroundColor3"] = Color3["fromRGB"](0, 0, 0), ["Size"] = UDim2["new"](1, 0, 1, 0), ["ZIndex"] = 9}, kx)
                    local j = A("Frame", {["Visible"] = false, ["AnchorPoint"] = Vector2["new"](0.5, 0.5), ["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["BackgroundTransparency"] = 0.18, ["Size"] = UDim2["new"](0, 250, 0, 0), ["BackgroundColor3"] = Color3["fromRGB"](14, 14, 20), ["ZIndex"] = 10, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 10)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 0.72, ["Thickness"] = 1})}}, kx)
                    A("TextLabel", {["Size"] = UDim2["new"](1, -40, 0, 20), ["Position"] = UDim2["new"](0, 12, 0, 8), ["BackgroundTransparency"] = 1, ["Text"] = e, ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 13, ["TextColor3"] = Color3["fromRGB"](220, 220, 230), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 11}, j)
                    local z = A("TextButton", {["Text"] = "×", ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["TextSize"] = 18, ["Font"] = Enum["Font"]["GothamBold"], ["Size"] = UDim2["new"](0, 22, 0, 22), ["Position"] = UDim2["new"](1, -28, 0, 5), ["BackgroundColor3"] = Color3["fromRGB"](192, 132, 252), ["BackgroundTransparency"] = 0.88, ["AutoButtonColor"] = false, ["ZIndex"] = 12, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)})}}, j)
                    local t = A("TextBox", {["Text"] = "", ["PlaceholderText"] = "Search options...", ["PlaceholderColor3"] = Color3["fromRGB"](120, 100, 150), ["Size"] = UDim2["new"](1, -16, 0, 26), ["Position"] = UDim2["new"](0, 8, 0, 34), ["TextSize"] = 12, ["Font"] = Enum["Font"]["Gotham"], ["TextColor3"] = Color3["fromRGB"](220, 220, 230), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["BackgroundColor3"] = Color3["fromRGB"](10, 10, 16), ["BackgroundTransparency"] = 0.1, ["ClearTextOnFocus"] = true, ["ZIndex"] = 11, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = 0.78, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 8)})}}, j)
                    local u = A("ScrollingFrame", {["Size"] = UDim2["new"](1, -8, 1, -70), ["Position"] = UDim2["new"](0, 4, 0, 66), ["CanvasSize"] = UDim2["new"](0, 0, 0, 0), ["ScrollBarThickness"] = 0, ["ScrollBarImageTransparency"] = 1, ["AutomaticCanvasSize"] = Enum["AutomaticSize"]["Y"], ["ElasticBehavior"] = Enum["ElasticBehavior"]["WhenScrollable"], ["BackgroundTransparency"] = 1, ["Active"] = true, ["ZIndex"] = 11, ["Children"] = {A("UIListLayout", {["Padding"] = UDim["new"](0, 4), ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"]}), A("UIPadding", {["PaddingLeft"] = UDim["new"](0, 2), ["PaddingRight"] = UDim["new"](0, 2), ["PaddingTop"] = UDim["new"](0, 2), ["PaddingBottom"] = UDim["new"](0, 4)})}}, j)
                    local Z = UDim2["new"](0, 250, 0, 230)
                    local function x(e, d)
                        local L = e["AbsolutePosition"]
                        local C = d["AbsolutePosition"]
                        return UDim2["new"](0, L["X"] - C["X"], 0, L["Y"] - C["Y"])
                    end
                    local function r()
                        local e = x(S, kx)
                        local L = S["AbsoluteSize"]
                        d:Tween(j, {["Position"] = e, ["Size"] = UDim2["new"](0, L["X"], 0, L["Y"])}, 0.25, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["In"])
                        d:Tween(S, {["Rotation"] = 0}, 0.25, Enum["EasingStyle"]["Quint"])
                        d:Tween(g, {["Transparency"] = 1}, 0.3)
                        task["delay"](0.25, function() j["Visible"] = false; T["Visible"] = false end)
                    end
                    local function i(e)
                        for e, d in ipairs(u:GetChildren()) do
                            if d:IsA("Frame") then
                                d:Destroy()
                            end
                        end
                        X = {}
                        for d, L in ipairs(C) do
                            if (not e or e == "") or string["find"](string["lower"](L), string["lower"](e), 1, true) then
                                table["insert"](X, {["index"] = d, ["value"] = L})
                            end
                        end
                        for e, L in ipairs(X) do
                            local v, W = L["index"], L["value"]
                            local o = table["find"](P, v) ~= nil
                            local b = A("Frame", {["Name"] = "Item_" .. v, ["BackgroundColor3"] = Color3["fromRGB"](22, 22, 32), ["BackgroundTransparency"] = o and 0.3 or 0.55, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 30), ["LayoutOrder"] = e, ["ZIndex"] = 12, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](192, 132, 252), ["Transparency"] = o and 0.55 or 0.9, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, u)
                            local X = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](192, 132, 252), ["BackgroundTransparency"] = o and 0 or 1, ["AnchorPoint"] = Vector2["new"](0, 0.5), ["Position"] = UDim2["new"](0, 6, 0.5, 0), ["Size"] = UDim2["new"](0, 3, 0, 14), ["ZIndex"] = 13, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](1, 0)}), A("UIGradient", {["Color"] = ColorSequence["new"]({ColorSequenceKeypoint["new"](0, Color3["fromRGB"](216, 180, 254)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](139, 92, 246))}), ["Rotation"] = 90})}}, b)
                            local l = A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 16, 0, 0), ["Size"] = UDim2["new"](1, -24, 1, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = W, ["TextSize"] = 12, ["TextColor3"] = o and Color3["fromRGB"](216, 180, 254) or Color3["fromRGB"](190, 190, 205), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 13}, b)
                            local F
                            if B then
                                F = A("TextLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -8, 0.5, 0), ["Size"] = UDim2["new"](0, 14, 0, 14), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = o and "★" or "", ["TextSize"] = 11, ["TextColor3"] = Color3["fromRGB"](192, 132, 252), ["ZIndex"] = 13}, b)
                            end
                            local N = A("TextButton", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 1, 0), ["Text"] = "", ["ZIndex"] = 14}, b)
                            N["MouseEnter"]:Connect(function() d:Tween(b, {["BackgroundTransparency"] = 0.35}, 0.15); d:Tween(l, {["TextColor3"] = Color3["fromRGB"](230, 220, 255)}, 0.15) end)
                            N["MouseLeave"]:Connect(function() local e = table["find"](P, v) ~= nil; d:Tween(b, {["BackgroundTransparency"] = e and 0.3 or 0.55}, 0.15); d:Tween(l, {["TextColor3"] = e and Color3["fromRGB"](216, 180, 254) or Color3["fromRGB"](190, 190, 205)}, 0.15) end)
                            N["MouseButton1Click"]:Connect(function() CircleClick(b, k["X"], k["Y"]); if B then local e; if table["find"](P, v) then I(v); e = false else s(v); e = true end; d:Tween(X, {["BackgroundTransparency"] = e and 0 or 1}, 0.2); d:Tween(b, {["BackgroundTransparency"] = e and 0.3 or 0.55}, 0.2); d:Tween(l, {["TextColor3"] = e and Color3["fromRGB"](216, 180, 254) or Color3["fromRGB"](190, 190, 205)}, 0.2); if F then F["Text"] = e and "✓" or "" end; local L = m(); Q["Text"] = f(L, 2); if h and (not U or O["HasKeyAccess"]()) then c:ElementSave(h, L) end; w(L) else table["clear"](P); table["insert"](P, v); Q["Text"] = C[v]; if h and (not U or O["HasKeyAccess"]()) then c:ElementSave(h, C[v]) end; w(C[v]); r() end end)
                        end
                        if B then
                            Q["Text"] = f(m(), 2)
                        else
                            Q["Text"] = C[P[1]] or "None"
                        end
                    end
                    local function R()
                        t["Text"] = ""
                        i()
                        local e = x(S, kx)
                        local L = S["AbsoluteSize"]
                        j["Position"] = e
                        j["Size"] = UDim2["new"](0, L["X"], 0, L["Y"])
                        j["Visible"] = true
                        T["Visible"] = true
                        d:Tween(j, {["Position"] = UDim2["new"](0.5, 0, 0.5, 0), ["Size"] = Z}, 0.32, Enum["EasingStyle"]["Quint"], Enum["EasingDirection"]["Out"])
                        d:Tween(S, {["Rotation"] = 180}, 0.25, Enum["EasingStyle"]["Quint"])
                        d:Tween(g, {["Transparency"] = 0.4}, 0.2)
                    end
                    t:GetPropertyChangedSignal("Text"):Connect(function() i(t["Text"]) end)
                    S["MouseButton1Click"]:Connect(R)
                    z["MouseButton1Click"]:Connect(r)
                    T["InputBegan"]:Connect(function(e) if e["UserInputType"] == Enum["UserInputType"]["MouseButton1"] then r() end end)
                    w((B and m() or C[P[1]]) or "None")
                    if U and h then
                        table["insert"](D, {["saveKey"] = h, ["UpdateFn"] = function() table["clear"](P); local function e(e) if #C < 1 then return end; local d = type(e) == "number" and math["clamp"](e, 1, #C) or type(e) == "string" and table["find"](C, e); if d then s(d) end end; if O["HasKeyAccess"]() then local d = c:Get(h, nil); if B then if typeof(d) == "table" then for d, L in ipairs(d) do e(L) end end; if #P == 0 and #C > 0 then s(1) end; Q["Text"] = f(m(), 2); w(m()) else local U = d and table["find"](C, d); if U then s(U) else e(L) end; if #P == 0 and #C > 0 then s(1) end; Q["Text"] = C[P[1]] or "None"; w(C[P[1]] or "None") end else if B then if typeof(L) == "table" then for d, L in ipairs(L) do e(L) end else e(L) end; if #P == 0 and #C > 0 then s(1) end; Q["Text"] = f(m(), 2); w(m()) else e(L); if #P == 0 and #C > 0 then s(1) end; Q["Text"] = C[P[1]] or "None"; w(C[P[1]] or "None") end end end})
                    end
                    if h then
                        c:RegisterControl(h, {["Type"] = "Dropdown", ["Default"] = L, ["Set"] = function(e, d) if B then table["clear"](P); if type(e) == "table" then for e, d in ipairs(e) do local L = table["find"](C, d); if L then s(L) end end end; Q["Text"] = f(m(), 2); if d ~= false then pcall(w, m()) end else table["clear"](P); local L = type(e) == "string" and table["find"](C, e) or type(e) == "number" and e; if L and C[L] then table["insert"](P, L); Q["Text"] = C[L]; if d ~= false then pcall(w, C[L]) end end end end, ["Get"] = function() return B and m() or (C[P[1]] or "None") end})
                    end
                    RegisterKeyLocked(F, U)
                    RegisterTranslatable(K, e)
                    return { ["Clear"] = function() for e, d in ipairs(u:GetChildren()) do if d:IsA("Frame") then d:Destroy() end end; P = {}; X = {}; Q["Text"] = "None"; w(B and {} or "None") end, ["Refresh"] = function(e, d) d = d or {}; C = d; local L = m(); table["clear"](P); local function w(e) if e then local d = table["find"](C, e); if d then s(d) end end end; if B then for e, d in ipairs(L) do w(d) end; if #P == 0 and #C > 0 then s(1) end else w(L[1]); if #P == 0 and #C > 0 then s(1) end end; Q["Text"] = B and f(m(), 2) or (C[P[1]] or "None"); i(t["Text"]) end, }
                end
                function g.addTextbox(h, e, L, C, w, U, B)
                    if not checkCondition(U) then
                        return y
                    end
                    L = L or function()  end
                    if w then
                        c:RegisterKey(w)
                    end
                    local v = w and c:Get(w, "") or ""
                    local o = A("Frame", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -25, 0, 96), ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 8)})}}, W)
                    N(o, e or "Textbox")
                    A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 6), ["Size"] = UDim2["new"](1, -20, 0, 20), ["Font"] = Enum["Font"]["GothamBold"], ["TextColor3"] = Color3["fromRGB"](220, 220, 230), ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["Text"] = e or "Textbox", ["TextWrapped"] = false, ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["ZIndex"] = 3, ["Children"] = {MakeTextConstraint(15, 8)}}, o)
                    A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](110, 55, 190), ["BackgroundTransparency"] = 0.82, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 10, 0, 30), ["Size"] = UDim2["new"](1, -20, 0, 1), ["ZIndex"] = 3}, o)
                    local b = A("Frame", {["BackgroundColor3"] = Color3["fromRGB"](10, 10, 16), ["BackgroundTransparency"] = 0.1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 10, 0, 38), ["Size"] = UDim2["new"](1, -20, 0, 24), ["ClipsDescendants"] = true, ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, o)
                    local P = A("UIStroke", {["Color"] = Color3["fromRGB"](110, 55, 190), ["Transparency"] = 0.78, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}, b)
                    local O = A("TextBox", {["BackgroundTransparency"] = 1, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](0, 10, 0, 0), ["Size"] = UDim2["new"](1, -18, 1, 0), ["Font"] = Enum["Font"]["GothamSemibold"], ["TextColor3"] = Color3["fromRGB"](210, 195, 255), ["PlaceholderColor3"] = Color3["fromRGB"](110, 85, 150), ["PlaceholderText"] = e or "Enter here...", ["TextSize"] = 12, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["Text"] = v, ["ClearTextOnFocus"] = false, ["ZIndex"] = 4}, b)
                    local X = A("Frame", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 70), ["Size"] = UDim2["new"](1, -20, 0, 20), ["ZIndex"] = 3, ["Children"] = {A("UIListLayout", {["FillDirection"] = Enum["FillDirection"]["Horizontal"], ["Padding"] = UDim["new"](0, 6), ["HorizontalAlignment"] = Enum["HorizontalAlignment"]["Right"], ["VerticalAlignment"] = Enum["VerticalAlignment"]["Center"], ["SortOrder"] = Enum["SortOrder"]["LayoutOrder"]})}}, o)
                    local s = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](110, 55, 190), ["BackgroundTransparency"] = 0.84, ["BorderSizePixel"] = 0, ["LayoutOrder"] = 1, ["Size"] = UDim2["new"](0, 54, 0, 20), ["Text"] = "Clear", ["TextColor3"] = Color3["fromRGB"](170, 120, 240), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 11, ["AutoButtonColor"] = false, ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](110, 55, 190), ["Transparency"] = 0.72, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, X)
                    local I = A("TextButton", {["BackgroundColor3"] = Color3["fromRGB"](110, 55, 190), ["BackgroundTransparency"] = 0.45, ["BorderSizePixel"] = 0, ["LayoutOrder"] = 2, ["Size"] = UDim2["new"](0, 60, 0, 20), ["Text"] = C or "Confirm", ["TextColor3"] = Color3["fromRGB"](200, 170, 255), ["Font"] = Enum["Font"]["GothamBold"], ["TextSize"] = 11, ["AutoButtonColor"] = false, ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 5)}), A("UIStroke", {["Color"] = Color3["fromRGB"](110, 55, 190), ["Transparency"] = 0.6, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]})}}, X)
                    O["Focused"]:Connect(function() d:Tween(P, {["Transparency"] = 0.42}, 0.2); d:Tween(b, {["BackgroundTransparency"] = 0}, 0.2) end)
                    O["FocusLost"]:Connect(function() d:Tween(P, {["Transparency"] = 0.78}, 0.28); d:Tween(b, {["BackgroundTransparency"] = 0.1}, 0.28) end)
                    s["MouseEnter"]:Connect(function() d:Tween(s, {["BackgroundTransparency"] = 0.6}, 0.15) end)
                    s["MouseLeave"]:Connect(function() d:Tween(s, {["BackgroundTransparency"] = 0.84}, 0.2) end)
                    I["MouseEnter"]:Connect(function() d:Tween(I, {["BackgroundTransparency"] = 0.25}, 0.15) end)
                    I["MouseLeave"]:Connect(function() d:Tween(I, {["BackgroundTransparency"] = 0.45}, 0.2) end)
                    s["MouseButton1Click"]:Connect(function() CircleClick(s, k["X"], k["Y"]); O["Text"] = ""; if w then c:ElementSave(w, "") end; O:CaptureFocus() end)
                    I["MouseButton1Click"]:Connect(function() CircleClick(I, k["X"], k["Y"]); if O["Text"] ~= "" then if w then c:ElementSave(w, O["Text"]) end; L(O["Text"]) end end)
                    O["FocusLost"]:Connect(function(e) if e and O["Text"] ~= "" then if w then c:ElementSave(w, O["Text"]) end; L(O["Text"]) end end)
                    if v ~= "" then
                        task["defer"](function() L(v) end)
                    end
                    if w then
                        c:RegisterControl(w, {["Type"] = "Textbox", ["Default"] = "", ["Set"] = function(e, d) e = tostring(e or ""); O["Text"] = e; if d ~= false then pcall(L, e) end end, ["Get"] = function() return O["Text"] end})
                    end
                    return { ["TextBox"] = O, ["Clear"] = s, ["Join"] = I, ["Frame"] = o, ["SetText"] = function(e, d) O["Text"] = d or "" end, ["GetText"] = function() return O["Text"] end, }
                end
                function g.addLabel(C, e, d, L)
                    local w = {}
                    local U, B = Enum["Font"]["GothamBold"], Enum["Font"]["Gotham"]
                    local h, v = 13, 11
                    local k = A("Frame", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -24, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["ClipsDescendants"] = false, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("UIStroke", {["Color"] = Color3["fromRGB"](110, 55, 190), ["Transparency"] = 0.88, ["Thickness"] = 1, ["ApplyStrokeMode"] = Enum["ApplyStrokeMode"]["Border"]}), A("UIPadding", {["PaddingTop"] = UDim["new"](0, 10), ["PaddingBottom"] = UDim["new"](0, 10), ["PaddingLeft"] = UDim["new"](0, 14), ["PaddingRight"] = UDim["new"](0, 14)}), A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 6)})}}, W)
                    RegisterKeyLocked(k, L)
                    local o = A("TextLabel", {["Name"] = "TitleLabel", ["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["LayoutOrder"] = 1, ["Font"] = U, ["TextColor3"] = Color3["fromRGB"](230, 230, 240), ["TextSize"] = h, ["TextWrapped"] = true, ["RichText"] = true, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextYAlignment"] = Enum["TextYAlignment"]["Top"], ["Text"] = e or "Default Title", ["ZIndex"] = 3}, k)
                    local b = d and d ~= ""
                    local P = A("Frame", {["Name"] = "Divider", ["BackgroundColor3"] = Color3["fromRGB"](110, 55, 190), ["BackgroundTransparency"] = 0.78, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, 0, 0, 1), ["LayoutOrder"] = 2, ["Visible"] = b, ["ZIndex"] = 3, ["Children"] = {A("UIGradient", {["Transparency"] = NumberSequence["new"]({NumberSequenceKeypoint["new"](0, 0), NumberSequenceKeypoint["new"](0.7, 0), NumberSequenceKeypoint["new"](1, 1)})})}}, k)
                    local O = A("TextLabel", {["Name"] = "DescLabel", ["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, 0, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["LayoutOrder"] = 3, ["Font"] = B, ["TextColor3"] = Color3["fromRGB"](165, 165, 185), ["TextSize"] = v, ["TextWrapped"] = true, ["RichText"] = true, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextYAlignment"] = Enum["TextYAlignment"]["Top"], ["Text"] = d or "", ["Visible"] = b, ["ZIndex"] = 3}, k)
                    RegisterTranslatable(o, e)
                    RegisterTranslatable(O, d)
                    function w.RefreshTitle(L, d)
                        e = d
                        o["Text"] = d or ""
                    end
                    function w.RefreshDesc(L, e)
                        d = e
                        O["Text"] = e or ""
                        local C = e and e ~= ""
                        P["Visible"] = C
                        O["Visible"] = C
                    end
                    return w
                end
                function g.addButtonGrid(w, L, C)
                    C = C or {}
                    local U = math["ceil"](#C / 3)
                    local B = ((8 + ((L and L ~= "") and 26 or 0)) + (U * 26 + math["max"](U - 1, 0) * 4)) + 8
                    local h = A("Frame", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.4, ["BorderSizePixel"] = 0, ["Size"] = UDim2["new"](1, -25, 0, B), ["ClipsDescendants"] = true, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)})}}, W)
                    N(h, L or "ButtonGrid")
                    if L and L ~= "" then
                        A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 12, 0, 8), ["Size"] = UDim2["new"](1, -20, 0, 20), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = L, ["TextColor3"] = Color3["fromRGB"](210, 200, 230), ["TextSize"] = 12, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["ZIndex"] = 3}, h)
                    end
                    for C, w in ipairs(C) do
                        local U = (C - 1) % 3
                        local B = math["floor"]((C - 1) / 3)
                        local v = w["Locked"] == true
                        local W = A("TextButton", {["BackgroundColor3"] = v and Color3["fromRGB"](30, 18, 50) or Color3["fromRGB"](55, 28, 100), ["BackgroundTransparency"] = v and 0.55 or 0.3, ["BorderSizePixel"] = 0, ["Position"] = UDim2["new"](U / 3, U == 0 and 10 or 2, 0, (8 + ((L and L ~= "") and 26 or 0)) + B * 30), ["Size"] = UDim2["new"](0.33333333333333, (U == 0 and -12 or U == 2 and -12) or -4, 0, 26), ["AutoButtonColor"] = false, ["ClipsDescendants"] = true, ["Text"] = "", ["ZIndex"] = 3, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 3)}), A("TextLabel", {["Name"] = "BtnLabel", ["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, v and -18 or -4, 1, 0), ["Position"] = UDim2["new"](0, 2, 0, 0), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = w["Label"] or "Button " .. C, ["TextColor3"] = v and Color3["fromRGB"](130, 110, 160) or Color3["fromRGB"](210, 185, 255), ["TextScaled"] = true, ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"], ["ZIndex"] = 4, ["Children"] = {MakeTextConstraint(12, 8)}})}}, h)
                        if v then
                            A("ImageLabel", {["BackgroundTransparency"] = 1, ["AnchorPoint"] = Vector2["new"](1, 0.5), ["Position"] = UDim2["new"](1, -4, 0.5, 0), ["Size"] = UDim2["new"](0, 10, 0, 10), ["Image"] = "rbxassetid://7733992528", ["ImageColor3"] = Color3["fromRGB"](140, 110, 190), ["ImageTransparency"] = 0.3, ["ZIndex"] = 5}, W)
                        end
                        local o = W:FindFirstChild("BtnLabel")
                        if v then
                            W["MouseButton1Click"]:Connect(function() CircleClick(W, k["X"], k["Y"]); if typeof(w["LockedCallback"]) == "function" then w["LockedCallback"]() else e["Notification"]:Notify({["Title"] = "Locked", ["Description"] = (w["Label"] or "This button") .. " is currently locked."}, {["Time"] = 2}) end end)
                        else
                            W["MouseEnter"]:Connect(function() d:Tween(W, {["BackgroundTransparency"] = 0.1}, 0.15, Enum["EasingStyle"]["Quint"]); if o then d:Tween(o, {["TextColor3"] = Color3["fromRGB"](235, 220, 255)}, 0.15) end end)
                            W["MouseLeave"]:Connect(function() d:Tween(W, {["BackgroundTransparency"] = 0.3}, 0.2, Enum["EasingStyle"]["Quint"]); if o then d:Tween(o, {["TextColor3"] = Color3["fromRGB"](210, 185, 255)}, 0.2) end end)
                            W["MouseButton1Click"]:Connect(function() CircleClick(W, k["X"], k["Y"]); if typeof(w["Callback"]) == "function" then w["Callback"]() end end)
                        end
                    end
                    return h
                end
                g["AddButton"] = g["addButton"]
                g["AddToggle"] = g["addToggle"]
                g["AddSlider"] = g["addSlider"]
                g["AddDropdown"] = g["addDropdown"]
                g["AddTextBox"] = g["addTextbox"]
                g["AddTextbox"] = g["addTextbox"]
                g["AddLabel"] = g["addLabel"]
                g["AddKeybind"] = g["addKeybind"]
                g["AddLine"] = g["addLine"]
                g["AddParagraph"] = g["addParagraph"]
                g["AddButtonGrid"] = g["addButtonGrid"]
                return g
            end
            W["AddMenu"] = W["addMenu"]
            return W
        end
        N["AddSection"] = N["addSection"]
        return N
    end
    np["addTab"] = np["AddTab"]
    do
        local e = "Standard"
        if O["IsDeveloperBuild"]() then
            e = "Developer"
        elseif O["HasKeyAccess"]() then
            e = "Premium"
        elseif m then
            e = "Freemium"
        end
        local d = "Not required"
        if m then
            d = O["HasKeyAccess"]() and "Verified" or "Not verified"
        end
        local L = np:AddTab("Main", "info-quantum")
        local C = L:addSection()
        local U = L:addSection()
        local h = C:addMenu("Information")
        h:addLabel("Script Information", string["format"]("Hub: %s\nGame: %s\nAccount: %s\nStatus: %s", w, tostring(B), W and W["Name"] or "Unknown", e))
        h:addLabel("Key Information", string["format"]("Key Status: %s\nKey Mode: %s\nExpires: —\nPlan: —\nHWID: —\nNote: Key details will appear here later.", d, tostring(f or (m and "Optional" or "None"))))
        local v = U:addMenu("Favorites / Pinned")
        v:addLabel("Tip", "PC: right-click a function, then tap ★\nMobile: double-tap to pin")
        local k
        task["defer"](function() for e, d in ipairs(H) do if d["tabTitle"] == "Main" and d["menuTitle"] == "Favorites / Pinned" then k = d["sectionFrame"] and d["sectionFrame"]:FindFirstChild("InnerSection"); if k then break end end end; if not k then for e, d in ipairs(i) do if d["tabButton"] and (d["tabButton"]["Text"] == "Main" and d["scrollFrame"]) then local e = {}; for d, L in ipairs(d["scrollFrame"]:GetChildren()) do if L["Name"] == "SectionScroll" then table["insert"](e, L) end end; local L = e[2] or e[1]; if L then k = A("Frame", {["Name"] = "FavHost", ["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, -10, 0, 0), ["AutomaticSize"] = Enum["AutomaticSize"]["Y"], ["Children"] = {A("UIListLayout", {["SortOrder"] = Enum["SortOrder"]["LayoutOrder"], ["Padding"] = UDim["new"](0, 4)})}}, L) end; break end end end; if M["Refresh"] then M["Refresh"]() end; task["delay"](1.5, function() if M["Refresh"] then M["Refresh"]() end end) end)
        M["Refresh"] = function() if not k or not k["Parent"] then return end; for e, d in ipairs(k:GetChildren()) do if d:IsA("TextButton") or d:IsA("TextLabel") and d["Text"] == "No favorites yet" then d:Destroy() end end; local e = M["List"]; if #e == 0 then A("TextLabel", {["BackgroundTransparency"] = 1, ["Size"] = UDim2["new"](1, -8, 0, 18), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = "No favorites yet", ["TextColor3"] = Color3["fromRGB"](140, 120, 170), ["TextSize"] = 10, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"]}, k); return end; for e, d in ipairs(e) do local L = M["Entries"][d]; local C = L and L["title"] or (d:match("([^|]+)$") or d); local w = L and (L["tabTitle"] or "") .. (" › " .. (L["menuTitle"] or "")) or ""; local U = A("TextButton", {["BackgroundColor3"] = ThemeColor("Primary"), ["BackgroundTransparency"] = 0.35, ["Size"] = UDim2["new"](1, -8, 0, 36), ["Text"] = "", ["AutoButtonColor"] = false, ["LayoutOrder"] = e, ["Children"] = {A("UICorner", {["CornerRadius"] = UDim["new"](0, 6)}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 2), ["Size"] = UDim2["new"](1, -20, 0, 16), ["Font"] = Enum["Font"]["GothamBold"], ["Text"] = "★  " .. C, ["TextColor3"] = Color3["fromRGB"](255, 220, 140), ["TextSize"] = 11, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"]}), A("TextLabel", {["BackgroundTransparency"] = 1, ["Position"] = UDim2["new"](0, 10, 0, 18), ["Size"] = UDim2["new"](1, -20, 0, 14), ["Font"] = Enum["Font"]["Gotham"], ["Text"] = w, ["TextColor3"] = Color3["fromRGB"](160, 140, 190), ["TextSize"] = 9, ["TextXAlignment"] = Enum["TextXAlignment"]["Left"], ["TextTruncate"] = Enum["TextTruncate"]["AtEnd"]})}}, k); U["MouseButton1Click"]:Connect(function() if L then O["NavigateToSearchEntry"](L) end end) end end
    end
    task["defer"](function() pcall(O["SyncKeyAccess"]) end)
    ScheduleRefreshAllLayouts()
    kx["Visible"] = true
    mp["Visible"] = true
    Sp = true
    ScheduleRefreshAllLayouts()
    np["IsDeveloper"] = O["IsDeveloperBuild"]
    np["IsPremium"] = O["HasKeyAccess"]
    np["ToggleUI"] = Nx
    np["Favorites"] = M
    np["Destroy"] = function() e:DestroyGui() end
    return np
end)(...)
