-- ==============================================================================
-- GUI.lua  (OXIASIDIAN deck ตามภาพอ้างอิง, mobile-safe, compact)
-- เข้ากับ MainScript_Original.lua แบบ drop-in (ไม่ต้องแก้ MainScript)
-- เลย์เอาต์ตามภาพ: header จุดม่วง + OXIASIDIAN / Blox Fruit · v.Premium,
--   nav ซ้าย (NAVIGATION + tab มีแถบ accent เมื่อ active + Config แยกด้านล่าง),
--   เนื้อขวามี breadcrumb "OVERVIEW / TAB" + ชื่อ tab ตัวใหญ่,
--   การ์ดมีแถบ accent ซ้าย + หัวข้อพิมพ์ใหญ่, toggle ทรง iOS ไร้กรอบ,
--   dropdown มีเชvron "v" + search, มี addProgress แบบ RUNTIME STATUS
--
-- โครง:
--  1. Library Core      (Library / Theme / Config / Utility)
--  2. Window            (CreateWindow / Title / Minimize / Close / Drag+Resize)
--  3. Tabs              (CreateTab / TabButton / TabContent, ซ้าย + แยก Config)
--  4. Sections          (CreateSection / Section Layout + page header)
--  5. UI Components     (Button/Toggle/Checkbox/Slider/Dropdown/MultiDropdown/
--                        Textbox/Label/Keybind/Colorpicker/Paragraph/Progress)
--  6. Notifications     (Notify / Success / Warning / Error)
--  7. Interaction       (Mouse / Keyboard / Touch / Hover / Click)
--  8. Animation         (Tween / Fade / Open-Close / Hover)
--  9. Theme System      -> แยกไฟล์: Oxiasidian/ThemeSystem.lua
--  10. Configuration    -> แยกไฟล์: Oxiasidian/Configuration.lua
--  11. Cleanup          (Destroy / Disconnect)
--
-- วิธีใช้ executor:
--   local Library = loadstring(game:HttpGet(".../QuantumOnyxGUI.lua"))()
--   local win = Library:CreateWindow({Title="Oxiasidian",Subtitle="Blox Fruit",
--     Version="v.Premium",Theme="Purple",SaveFile="BloxFruits",OnStopAll=function() end})
--   local tab = win:AddTab("Home","home-oxiasidian")
--   local menu = tab:addSection():addMenu("Main Farm")
--   menu:addToggle("Auto Farm", false, function(v) print(v) end, nil, nil, "AutoFarm")
--   menu:addProgress("Speed", 66, 100, "Farming...")
--
-- มือถือ: หน้าต่าง clamp ตาม viewport + UIScale อัตโนมัติ, ปุ่มแตะ >= 40px,
--   dropdown popup อยู่ในจอ, slider ลากด้วยนิ้ว, มีปุ่มลอย OX เปิด/ปิด
-- ==============================================================================

local Library = {}
Library.Version = "3.2.7"
Library.Name = "GUI"

-- ============================ 1. Library Core ================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function GetUIParent()
	local ok, hui = pcall(function()
		if gethui ~= nil then return gethui() end
		return nil
	end)
	if ok and typeof(hui) == "Instance" then return hui end
	local ok2, pg = pcall(function()
		if LocalPlayer then return LocalPlayer:FindFirstChildOfClass("PlayerGui") end
		return nil
	end)
	if ok2 and pg then return pg end
	return CoreGui
end

local function IsTouchOnly()
	local ok, r = pcall(function()
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end)
	if ok then return r end
	return false
end

local function Viewport()
	local ok, cam = pcall(function() return workspace.CurrentCamera end)
	if ok and cam then
		local ok2, vs = pcall(function() return cam.ViewportSize end)
		if ok2 then return vs end
	end
	return Vector2.new(1280, 720)
end

-- ---- utility ----
local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end
local function toStr(v)
	if v == nil then return "" end
	return tostring(v)
end
local function isTbl(v) return type(v) == "table" end
local function isFn(v) return type(v) == "function" end
local function isStr(v) return type(v) == "string" end
local function isNum(v) return type(v) == "number" end

local function New(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		pcall(function() inst[k] = v end)
	end
	if parent then inst.Parent = parent end
	return inst
end
local function Corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r or 6) }, p) end
local function Stroke(p, c, t, tr)
	return New("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end
local function Pad(p, t, l, b, r)
	return New("UIPadding", { PaddingTop = UDim.new(0, t or 6), PaddingLeft = UDim.new(0, l or 8),
		PaddingBottom = UDim.new(0, b or 6), PaddingRight = UDim.new(0, r or 8) }, p)
end
local function List(p, gap)
	return New("UIListLayout", { Padding = UDim.new(0, gap or 6),
		FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder }, p)
end

-- ============================ 8. Animation ===================================
local T_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local T_INST = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Tween(obj, props, info)
	if not obj or not obj.Parent then
		pcall(function() for k, v in pairs(props) do obj[k] = v end end)
		return nil
	end
	local ok, tw = pcall(function() return TweenService:Create(obj, info or T_FAST, props) end)
	if ok and tw then pcall(function() tw:Play() end) return tw end
	pcall(function() for k, v in pairs(props) do obj[k] = v end end)
	return nil
end
local function Fade(obj, visible)
	if visible then
		obj.Visible = true
		Tween(obj, { BackgroundTransparency = 0 })
	else
		local tw = Tween(obj, { BackgroundTransparency = 1 })
		if tw then task.delay(0.15, function() pcall(function() obj.Visible = false end) end)
		else obj.Visible = false end
	end
end

-- ---- dot/colon-safe args (MainScript เรียก toggle.Update(false) แบบ dot) ----
local function Pack(owner, ...)
	local n = select("#", ...)
	local t = {}
	for i = 1, n do t[i] = select(i, ...) end
	if n >= 1 and t[1] == owner then
		for i = 1, n - 1 do t[i] = t[i + 1] end
		t[n] = nil n = n - 1
	end
	t.n = n
	return t
end
-- หมายเหตุ: ทุก SetValue/Update ใช้แพทเทิร์น function(a,b) -> (b ~= nil and b or a)
-- เพื่อรองรับทั้ง dot-call (Update(false)) และ colon-call (:Update(false))

local function Track(owner, conn)
	owner._conns = owner._conns or {}
	table.insert(owner._conns, conn)
	return conn
end
local function AddChild(owner, child)
	owner._children = owner._children or {}
	table.insert(owner._children, child)
end
local function DisconnectAll(owner)
	if owner._conns then
		for _, c in ipairs(owner._conns) do pcall(function() c:Disconnect() end) end
		table.clear(owner._conns)
	end
	if owner._children then
		for _, ch in ipairs(owner._children) do
			pcall(function() if ch.Destroy then ch:Destroy() end end)
		end
		table.clear(owner._children)
	end
end

-- ==================== 9. Theme System (แยกไฟล์) =============================
-- พยายามโหลด Oxiasidian/ThemeSystem.lua ก่อน, ไม่ได้ค่อยใช้ embedded
local EmbeddedThemes = {
	Purple = { Name="Purple", Background=Color3.fromRGB(10,10,16), Surface=Color3.fromRGB(17,17,26),
		Surface2=Color3.fromRGB(24,24,36), Surface3=Color3.fromRGB(30,30,45),
		Border=Color3.fromRGB(48,44,72), BorderSoft=Color3.fromRGB(34,32,52),
		Text=Color3.fromRGB(235,235,245), TextMuted=Color3.fromRGB(150,148,175), TextDim=Color3.fromRGB(110,108,135),
		Accent=Color3.fromRGB(139,92,246), AccentHover=Color3.fromRGB(167,139,250), AccentDark=Color3.fromRGB(76,29,149),
		Success=Color3.fromRGB(52,211,153), Warning=Color3.fromRGB(251,191,36),
		Error=Color3.fromRGB(248,113,113), Info=Color3.fromRGB(96,165,250) },
	Midnight = { Name="Midnight", Background=Color3.fromRGB(6,10,20), Surface=Color3.fromRGB(11,17,32),
		Surface2=Color3.fromRGB(17,25,44), Surface3=Color3.fromRGB(23,33,57),
		Border=Color3.fromRGB(38,54,88), BorderSoft=Color3.fromRGB(26,38,62),
		Text=Color3.fromRGB(226,232,240), TextMuted=Color3.fromRGB(148,163,184), TextDim=Color3.fromRGB(100,116,139),
		Accent=Color3.fromRGB(59,130,246), AccentHover=Color3.fromRGB(96,165,250), AccentDark=Color3.fromRGB(30,58,138),
		Success=Color3.fromRGB(52,211,153), Warning=Color3.fromRGB(251,191,36),
		Error=Color3.fromRGB(248,113,113), Info=Color3.fromRGB(34,211,238) },
	Dark = { Name="Dark", Background=Color3.fromRGB(12,12,12), Surface=Color3.fromRGB(20,20,20),
		Surface2=Color3.fromRGB(28,28,28), Surface3=Color3.fromRGB(36,36,36),
		Border=Color3.fromRGB(58,58,58), BorderSoft=Color3.fromRGB(40,40,40),
		Text=Color3.fromRGB(240,240,240), TextMuted=Color3.fromRGB(170,170,170), TextDim=Color3.fromRGB(120,120,120),
		Accent=Color3.fromRGB(200,200,200), AccentHover=Color3.fromRGB(255,255,255), AccentDark=Color3.fromRGB(90,90,90),
		Success=Color3.fromRGB(74,222,128), Warning=Color3.fromRGB(250,204,21),
		Error=Color3.fromRGB(248,113,113), Info=Color3.fromRGB(147,197,253) },
	Crimson = { Name="Crimson", Background=Color3.fromRGB(14,8,10), Surface=Color3.fromRGB(22,13,16),
		Surface2=Color3.fromRGB(32,19,23), Surface3=Color3.fromRGB(42,25,30),
		Border=Color3.fromRGB(80,36,44), BorderSoft=Color3.fromRGB(54,24,30),
		Text=Color3.fromRGB(255,235,238), TextMuted=Color3.fromRGB(190,150,158), TextDim=Color3.fromRGB(140,105,112),
		Accent=Color3.fromRGB(244,63,94), AccentHover=Color3.fromRGB(251,113,133), AccentDark=Color3.fromRGB(136,19,55),
		Success=Color3.fromRGB(52,211,153), Warning=Color3.fromRGB(251,191,36),
		Error=Color3.fromRGB(248,113,113), Info=Color3.fromRGB(96,165,250) },
}
local ThemeSystem = nil
do
	local ok, mod = pcall(function()
		if typeof(script) == "Instance" then
			local f = script.Parent and script.Parent:FindFirstChild("Oxiasidian")
			if f then
				local m = f:FindFirstChild("ThemeSystem")
				if m and m:IsA("ModuleScript") then return require(m) end
			end
			local m2 = script:FindFirstChild("ThemeSystem")
			if m2 and m2:IsA("ModuleScript") then return require(m2) end
		end
		return nil
	end)
	if ok and isTbl(mod) and isTbl(mod.Themes) then
		ThemeSystem = mod
	else
		ThemeSystem = {
			Themes = EmbeddedThemes,
			Resolve = function(name)
				if isStr(name) then
					if EmbeddedThemes[name] then return EmbeddedThemes[name] end
					local l = string.lower(name)
					for k, v in pairs(EmbeddedThemes) do
						if string.lower(k) == l then return v end
					end
				end
				return EmbeddedThemes.Purple
			end,
			List = function()
				local o = {}
				for k in pairs(EmbeddedThemes) do table.insert(o, k) end
				table.sort(o)
				return o
			end,
		}
	end
end
Library.Themes = ThemeSystem.Themes
Library.ThemeSystem = ThemeSystem

-- icon ที่ Roblox รองรับอย่างเป็นทางการ (Official Lucide & CoreGui asset IDs โหลดติดชัวร์ทุกแพลตฟอร์ม)
local RobloxIcons = {
	["bell"] = "rbxassetid://6031075931",
	["info"] = "rbxassetid://6031086208",
	["success"] = "rbxassetid://6031094678",
	["check"] = "rbxassetid://6031094678",
	["warning"] = "rbxassetid://6031084226",
	["alert"] = "rbxassetid://6031084226",
	["error"] = "rbxassetid://6031094687",
	["close"] = "rbxassetid://6031094687",
	["home"] = "rbxassetid://6031075929",
	["swords"] = "rbxassetid://6031088661",
	["sword"] = "rbxassetid://6031088661",
	["ship"] = "rbxassetid://6031082533",
	["user"] = "rbxassetid://6031088673",
	["player"] = "rbxassetid://6031088673",
	["visual"] = "rbxassetid://6031079895",
	["eye"] = "rbxassetid://6031079895",
	["raid"] = "rbxassetid://6031097225",
	["shield"] = "rbxassetid://6031097225",
	["rabbit"] = "rbxassetid://6031077360",
	["zap"] = "rbxassetid://6031077360",
	["map"] = "rbxassetid://6031086221",
	["cart"] = "rbxassetid://6031075938",
	["shop"] = "rbxassetid://6031075938",
	["misc"] = "rbxassetid://6031082525",
	["cat"] = "rbxassetid://6031075931",
	["config"] = "rbxassetid://6031097229",
	["settings"] = "rbxassetid://6031097229",
}

local function ResolveIcon(id, fallback)
	if not isStr(id) or id == "" then return fallback or RobloxIcons["bell"] end
	if id:find("rbxasset") then return id end
	local num = tonumber(id)
	if num then return "rbxassetid://" .. tostring(num) end
	local l = string.lower(id)
	if RobloxIcons[l] then return RobloxIcons[l] end
	local trimmed = l:gsub("%-oxiasidian$", "")
	if RobloxIcons[trimmed] then return RobloxIcons[trimmed] end
	return fallback or RobloxIcons["bell"]
end

local IconMap = { ["home-oxiasidian"]="●", ["swords-oxiasidian"]="×", ["ship-oxiasidian"]="~",
	["user-oxiasidian"]="○", ["visual-oxiasidian"]="*", ["raid-oxiasidian"]="#",
	["rabbit-oxiasidian"]="◆", ["map-oxiasidian"]="@", ["cart-oxiasidian"]="$",
	["misc-oxiasidian"]="?", ["cat-oxiasidian"]="!", home="●", swords="×", ship="~", user="○",
	rabbit="◆", cart="$", cat="!", config="◉" }
local function IconText(id)
	if not isStr(id) or id == "" then return "-" end
	if IconMap[id] then return IconMap[id] end
	local l = string.lower(id)
	if IconMap[l] then return IconMap[l] end
	local ch = id:match("%w")
	if ch then return string.upper(ch) end
	return "-"
end

-- ================== 10. Lightweight Auto-Config System ==================
local MemoryFiles = {}
local function SafeIsFile(path)
	local ok, res = pcall(function()
		if isfile then return isfile(path) end
		return MemoryFiles[path] ~= nil
	end)
	return ok and (res == true)
end

local function SafeReadFile(path)
	local ok, res = pcall(function()
		if readfile then return readfile(path) end
		return MemoryFiles[path]
	end)
	if ok and isStr(res) then return res end
	return MemoryFiles[path] or ""
end

local function SafeWriteFile(path, data)
	pcall(function()
		if writefile then writefile(path, data) end
		MemoryFiles[path] = data
	end)
end

local function SafeMakeFolder(folder)
	pcall(function()
		if isfolder and isfolder(folder) then return end
		if makefolder then makefolder(folder) end
	end)
end

local function SerializeConfigValue(v)
	if v == nil then return nil end
	if typeof(v) == "Color3" then
		return { __type = "Color3", R = math.floor(v.R * 255 + 0.5), G = math.floor(v.G * 255 + 0.5), B = math.floor(v.B * 255 + 0.5) }
	elseif typeof(v) == "EnumItem" then
		return { __type = "EnumItem", Name = v.Name }
	elseif isTbl(v) then
		local isArray = true
		local n = #v
		for k, _ in pairs(v) do
			if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
				isArray = false
				break
			end
		end
		if isArray then
			local arr = {}
			for i = 1, n do arr[i] = SerializeConfigValue(v[i]) end
			return arr
		else
			local copy = {}
			for k, val in pairs(v) do copy[toStr(k)] = SerializeConfigValue(val) end
			return copy
		end
	else
		return v
	end
end

local function DeserializeConfigValue(v, compType)
	if v == nil then return nil end
	if isTbl(v) then
		if v.__type == "Color3" then
			return Color3.fromRGB(v.R or 255, v.G or 255, v.B or 255)
		elseif v.__type == "EnumItem" and v.Name then
			return v.Name
		elseif compType == "Colorpicker" and #v == 3 then
			return Color3.fromRGB(v[1] or 255, v[2] or 255, v[3] or 255)
		elseif compType == "MultiDropdown" then
			local list = {}
			for _, item in pairs(v) do table.insert(list, toStr(item)) end
			return list
		else
			return v
		end
	end
	if compType == "Colorpicker" and isStr(v) and v:match("^#%x%x%x%x%x%x$") then
		return Color3.fromRGB(tonumber(v:sub(2,3), 16), tonumber(v:sub(4,5), 16), tonumber(v:sub(6,7), 16))
	end
	return v
end

local function GetPlayerName()
	local pName = nil
	pcall(function()
		if Players and Players.LocalPlayer and Players.LocalPlayer.Name then
			pName = Players.LocalPlayer.Name
		end
	end)
	if not pName or pName == "" then
		pcall(function()
			pName = game:GetService("Players").LocalPlayer.Name
		end)
	end
	return (pName and pName ~= "") and pName or "playername"
end

local function DetectGameName(override, fallbackSaveFile)
	if override and isStr(override) and override ~= "" then
		return override:gsub("[^%w%-%_]", "")
	end
	if fallbackSaveFile and isStr(fallbackSaveFile) and fallbackSaveFile ~= "" and fallbackSaveFile ~= "OxiasidianConfig" then
		return fallbackSaveFile:gsub("[^%w%-%_]", "")
	end
	local name = nil
	pcall(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		local info = MarketplaceService:GetProductInfo(game.PlaceId)
		if info and info.Name and #info.Name > 0 then
			name = info.Name
		end
	end)
	if not name or name == "" then
		pcall(function()
			name = tostring(game.Name or "")
		end)
	end
	if not name or name == "" or name == "Game" then
		name = tostring(game.GameId or game.PlaceId or "BloxFruits")
	end
	name = toStr(name):gsub("%s+", "_"):gsub("[^%w%-%_]", ""):gsub("_+", "_")
	return (name ~= "" and name) or "BloxFruits"
end

-- ================== 10.1 Known Settings Keys (14 Categories) ==================
local KnownSettingsKeys = {
	AcceptQuests = true, AutoCollectBones = true, AutoFarm = true, AutoFarmBones = true,
	AutoFarmMagnetTokens = true, AutoFarmWeapon = true, AutoMasterySwords = true, AutoRollMagnetGacha = true,
	AutoSetSpawnPoint = true, AutoSlap = true, AutoTryLuck = true, Auto_Random_Surprise = true,
	BypassGetQuest = true, DoubleAttack = true, DummyTraining = true, FarmMode = true,
	HealthMob = true, MasteryFarm = true, PosMethod = true, PosY = true,
	QuestDebounce = true, QuestFarmMode = true, ScrollCraftAmount = true, SelectSwordMastery = true,
	SelectWeapon = true, SendWebhookDataLog = true, SendWebhookFarmsAll = true, SendWebhookInventory = true,
	SendWebhookKitsune = true, SendWebhookLevelUp = true, SendWebhookMirage = true, SendWebhookPrehistoric = true,
	SendWebhookRolledFruit = true, SendWebhookStoreFruit = true, SetAzureEmber = true, ShootAmount = true,
	ShootGunBlaze = true, ShootGunTyrant = true, ShootGunVolcano = true, SpeedBoat = true,
	StartObsHop = true, StopChest = true, StopHopChestIfChalice = true, TradeAzureEmber = true,
	TrainMethod = true, Tweenfruit = true, UseDragonSforSeabeasts = true, WalkSpeed = true,
	Water = true, WebhookPingOnEvents = true, WebhookPingOnMythical = true, White_Screen = true,
	XrayVision = true, attackplayers = true, checknearestdist = true,
	Aimbot = true, AutoActivateObservationHaki = true, AutoAttack = true, AutoBuyEnchancementColor = true,
	AutoFarmObservation = true, AutoKenV2 = true, AutoOpenColorsTask = true, BringAttackMaxFrom = true,
	BringMonster = true, BringMonsterRadius = true, BringSmoothSpeed = true, BringCircleRadius = true,
	BringFlySpeed = true, CamLock = true, CircleRadius = true, EnableAimbot = true,
	GetRainbowHaki = true, oxiasidianAttack = true, RemoveAnimationFast = true, RemoveObservationEffect = true,
	attackmobs = true,
	AutoAttackGun = true, AutoSkills = true, BloxFruitDelay = true, BloxFruitKeys = true,
	DragonstormMode = true, GunDelay = true, GunKeys = true, HoldTime_C = true,
	HoldTime_F = true, HoldTime_V = true, HoldTime_X = true, HoldTime_Z = true,
	MeleeDelay = true, MeleeKeys = true, SelectSkills = true, SwordDelay = true,
	SwordKeys = true,
	AutoCursedCaptain = true, AutoDarkbeard = true, AutoDoughKing = true, AutoFarmBoss = true,
	AutoFarmPrince = true, AutoGreybeard = true, AutoKillAllBosses = true, AutoRipIndra = true,
	AutoSoulReaper = true, AutoTaskEliteHunter = true, AutoTyrantOfTheSkies = true, GetBossQuest = true,
	IgnoreCakePrince = true, IgnoreDoughChaliceFarm = true, SelectBoss = true, SelectBosstoHop = true,
	SelectGunTyrant = true, StopHopEliteIfChalice = true,
	AutoBlueMoonFarm = true, AutoBuyNewBoatWhendies = true, AutoFarmSeaEvents = true, AutoFindKitsuneIsland = true,
	AutoFindLeviatan = true, AutoFindMirageIsland = true, AutoFindPrehistoricIsland = true, AutoIgnoreSeaEventsLeviathan = true,
	AutoKillLeviathan = true, AutoLookMoon = true, AutoPray = true, AutoSail = true,
	AutoSailbacktoTiki = true, AutoTeleportKitsune = true, AutoTeleportMirage = true, AutoTeleportPrehistoric = true,
	BoatPosY = true, BoatSelected = true, CollectAzure = true, DodgeTerror = true,
	DodgefSeabeast = true, ManualBoatSpeed = true, ManualIncreaseBoatSpeed = true, ProtectBoat = true,
	ResetPlayerdestroyboat = true, SailTargetBoat = true, SeaEventTargets = true, SeaLevelSelected = true,
	BypassTP = true, ForceAnchoredY = true, JumpPower = true, NpcTween = true,
	SelectPlayer = true, SpectatePlayer = true, TPtoNPC = true, TeleportIslandSelect = true,
	TeleportToIsland = true, TeleporttoPlayer = true, TweenSpeed = true,
	AntiAFK = true, AutoAfkJoinBossRaid = true, AutoAfkJoinCastleRaid = true, AutoAfkJoinEliteHunter = true,
	AutoAfkJoinFactoryRaid = true, AutoAfkJoinFruit = true, AutoHopChest = true, AutoHopwhen30mins = true,
	ChestHopCount = true, HopDelay = true, HopIfNoBerries = true, HopIfNoChest = true,
	HopIfNoFruit = true, HopWhenAdmin = true,
	AutoBartiloQuest = true, AutoCDKQuest = true, AutoCompleteSecretQuests = true, AutoCraftScrolls = true,
	AutoGetCDK = true, AutoGetDBV2 = true, AutoGetSkullGuitar = true, AutoMaterial = true,
	AutoRengoku = true, AutoSecondSea = true, AutoSharkAnchor = true, AutoTTK = true,
	AutoThirdSea = true, AutoTushita = true, AutoUnlockSaber = true, AutoYama = true,
	BuyLegendSword = true, BuyTTK = true, FinishedSecretQuestsTracker = true, IgnoreMaterialFarmGuitar = true,
	SelectLegendarySword = true, SelectMaterial = true, SelectScrollType = true,
	AutoActiveRaceV4 = true, AutoActiveRacenear = true, AutoAgility = true, AutoChooseGear = true,
	AutoCompleteDracoTrial = true, AutoFinishTrial = true, AutoFullyPullLever = true, AutoGetCyborgRace = true,
	AutoGetGhoulRace = true, AutoKillPlayerinTrial = true, AutoStartRaceV2 = true, AutoStartRaceV3 = true,
	AutoTrainGear = true, AutoTrialDracoTP = true, BuyGear = true, TweenMGear = true,
	AutoAwaken = true, AutoBuyChip = true, AutoCardsDungeon = true, AutoDungeonFull = true,
	AutoDungeonShrine = true, AutoFactoryRaid = true, AutoFarmPirateRaid = true, AutoLawRaid = true,
	AutoRaidFull = true, AutoUnlockDifficulties = true, Autostopraid = true, CardsSelection = true,
	FragsCap = true, InstantKillLateIslands = true, SelectRaid = true,
	AutoBuyMelee = true, AutoDeathStep = true, AutoDragonTalon = true, AutoElectricClaw = true,
	AutoSharkmanKarate = true, AutoUpgradeDragonTalon = true, SelectMelee = true,
	AutoBerrySafe = true, AutoBuyFruitDealer = true, AutoBuyMirageFruitDealer = true, AutoBuyTrinkets = true,
	AutoChest = true, AutoCollectEgg = true, AutoCollectFireFlowers = true, AutoCraftBait = true,
	AutoFuseTrinkets = true, AutoGetAnglerQuest = true, AutoGetChest = true, AutoPurpleBelt = true,
	AutoQuestBlaze = true, AutoRefineTrinkets = true, AutoScrapTrinkets = true, AutoSellFish = true,
	AutoStoreFruit = true, AutoUnstoreBelowFruit = true, AutoUseRodSkill = true, AutoVolcanicEvent = true,
	AutoWhiteBelt = true, Auto_Fishing = true, BuyAbility = true, BuyAccessories = true,
	ChestFilterType = true, CompleteCitizenQuest = true, FruitCheck = true, GunSelect = true,
	LastCastLocation = true, Random_Auto = true, SelectFruitDealerFruit = true, SelectGunBlaze = true,
	SelectGunVolcano = true, SelectMirageDealerFruit = true, SelectedBait = true, SelectedRod = true,
	DevilFruitESP = true, ESPChest = true, ESPIsland = true, ESPMyBoat = true,
	ESPPlayer = true, ESP_Berries = true, ESP_RealFruits = true,
	AutoAggressiveGC = true, AutoCleanMemory = true, AutoClearDebris = true, AutoFastMode = true,
	AutoLoadScriptonLoad = true, AutoStats = true, AutoWebhook = true, BlackScreen = true,
	DataLogInterval = true, DataLogWebhookUrl = true, Defense = true, DemonFruit = true,
	DisableDamageCounter = true, DisableNotifications = true, Gun = true, InfiniteZoom = true,
	Melee = true, NoFog = true, PointsSlider = true, Sword = true,
	TeamSelectLoad = true, Webhook = true, WebhookPingId = true,
}

-- ================== 10.2 Player & Function Config (playername_BloxFruits.json) ==================
local PlayerConfig = {
	FileName = "playername_BloxFruits",
	Data = {},
	BoundSettings = nil,
	_saveThread = nil,
	_isSaving = false,
}

function PlayerConfig:Path()
	return "OxiasidianUI/" .. self.FileName .. ".json"
end

function PlayerConfig:Init(gameName, saveFile)
	local pName = GetPlayerName()
	local gName = DetectGameName(gameName, saveFile)
	self.FileName = pName .. "_" .. gName
	self.Data = {}
	self:AutoLoad()
end

function PlayerConfig:AutoLoad()
	local path = self:Path()
	if not SafeIsFile(path) then
		-- Fallback aliases: playername_<game>.json or Player_<game>.json
		local pName = GetPlayerName()
		local cand1 = "OxiasidianUI/playername_" .. self.FileName:match("_(.+)$") .. ".json"
		local cand2 = "OxiasidianUI/Player_" .. self.FileName:match("_(.+)$") .. ".json"
		if SafeIsFile(cand1) then path = cand1
		elseif SafeIsFile(cand2) then path = cand2 end
	end
	if SafeIsFile(path) then
		local content = SafeReadFile(path)
		if isStr(content) and #content > 1 then
			local ok, dec = pcall(function() return HttpService:JSONDecode(content) end)
			if ok and isTbl(dec) then
				self.Data = dec
				if isTbl(self.BoundSettings) then
					for k, v in pairs(dec) do
						pcall(function() self.BoundSettings[k] = DeserializeConfigValue(v) end)
					end
				end
				return true
			end
		end
	end
	self.Data = {}
	return false
end

function PlayerConfig:Has(key)
	if not key then return false end
	key = toStr(key)
	if KnownSettingsKeys[key] == true then return true end
	if isTbl(self.BoundSettings) and self.BoundSettings[key] ~= nil then return true end
	if self.Data and self.Data[key] ~= nil then return true end
	if getgenv and isTbl(getgenv().Settings) and getgenv().Settings[key] ~= nil then return true end
	if _G and isTbl(_G.Settings) and _G.Settings[key] ~= nil then return true end
	return false
end

function PlayerConfig:BindSettings(tbl)
	if not isTbl(tbl) then return end
	self.BoundSettings = tbl
	for k, v in pairs(self.Data) do
		pcall(function() tbl[k] = DeserializeConfigValue(v) end)
	end
	for k, v in pairs(tbl) do
		if self.Data[toStr(k)] == nil then
			self.Data[toStr(k)] = SerializeConfigValue(v)
		end
	end
end

function PlayerConfig:Get(key, defaultVal, compType)
	if not key then return defaultVal end
	key = toStr(key)
	local v = self.Data[key]
	if v ~= nil then
		return DeserializeConfigValue(v, compType)
	end
	if isTbl(self.BoundSettings) and self.BoundSettings[key] ~= nil then
		return self.BoundSettings[key]
	end
	if getgenv and isTbl(getgenv().Settings) and getgenv().Settings[key] ~= nil then
		return getgenv().Settings[key]
	end
	if _G and isTbl(_G.Settings) and _G.Settings[key] ~= nil then
		return _G.Settings[key]
	end
	return defaultVal
end

function PlayerConfig:Set(key, val)
	if not key then return end
	key = toStr(key)
	self.Data[key] = SerializeConfigValue(val)
	if isTbl(self.BoundSettings) then
		pcall(function() self.BoundSettings[key] = val end)
	end
	if getgenv and isTbl(getgenv().Settings) then
		pcall(function() getgenv().Settings[key] = val end)
	end
	if _G and isTbl(_G.Settings) then
		pcall(function() _G.Settings[key] = val end)
	end
	self:QueueSave()
end

function PlayerConfig:QueueSave()
	if self._saveThread then
		pcall(function() task.cancel(self._saveThread) end)
		self._saveThread = nil
	end
	self._saveThread = task.delay(0.35, function()
		self._saveThread = nil
		self:Save()
	end)
end

function PlayerConfig:Save()
	if self._isSaving then return end
	self._isSaving = true
	pcall(function()
		SafeMakeFolder("OxiasidianUI")
		local enc = HttpService:JSONEncode(self.Data)
		SafeWriteFile(self:Path(), enc)
	end)
	self._isSaving = false
end

function PlayerConfig:Flush()
	if self._saveThread then
		pcall(function() task.cancel(self._saveThread) end)
		self._saveThread = nil
	end
	self:Save()
end

function PlayerConfig:Reset()
	self.Data = {}
	self:Flush()
end

function PlayerConfig:Load()
	return self:AutoLoad()
end

PlayerConfig.GetFunction = PlayerConfig.Get
PlayerConfig.SetFunction = PlayerConfig.Set
PlayerConfig.GetState = PlayerConfig.Get
PlayerConfig.SetState = PlayerConfig.Set

-- ================== 10.3 UI Config System (OxiasidianUI/Config/<SaveFile>.json) ==================
local ConfigSystem = {
	File = "Configs",
	Data = {},              -- [key] = serializedValue (UI controls ONLY: Theme, Hotkey)
	Registry = {},          -- [key] = component
	_saveThread = nil,
	_isSaving = false,
}

function ConfigSystem:Path()
	return "OxiasidianUI/Config/" .. self.File .. ".json"
end

function ConfigSystem:Init(fileName)
	fileName = toStr(fileName or "Configs")
	if fileName == "" or fileName == "OxiasidianConfig" then fileName = "Configs" end
	self.File = fileName:gsub("[^%w%-%_]", "_")
	self.Data = {}
	self:AutoLoad()
end

function ConfigSystem:AutoLoad()
	local path = self:Path()
	if not SafeIsFile(path) then
		local cand1 = "OxiasidianUI/Config/Configs.json"
		local cand2 = "OxiasidianUI/Config/Conifgs.json"
		local cand3 = "OxiasidianUI/Config/BloxFruits.json"
		local cand4 = "OxiasidianUI/Configs.json"
		if SafeIsFile(cand1) then path = cand1
		elseif SafeIsFile(cand2) then path = cand2
		elseif SafeIsFile(cand3) then path = cand3
		elseif SafeIsFile(cand4) then path = cand4 end
	end
	if SafeIsFile(path) then
		local content = SafeReadFile(path)
		if isStr(content) and #content > 1 then
			local ok, dec = pcall(function() return HttpService:JSONDecode(content) end)
			if ok and isTbl(dec) then
				self.Data = dec
				return true
			end
		end
	end
	self.Data = {}
	return false
end

function ConfigSystem:Get(key, defaultVal, compType)
	if not key then return defaultVal end
	key = toStr(key)
	if PlayerConfig:Has(key) then
		return PlayerConfig:Get(key, defaultVal, compType)
	end
	local v = self.Data[key]
	if v ~= nil then
		return DeserializeConfigValue(v, compType)
	end
	return defaultVal
end

function ConfigSystem:Set(key, val)
	if not key then return end
	key = toStr(key)
	if PlayerConfig:Has(key) then
		PlayerConfig:Set(key, val)
		return
	end
	self.Data[key] = SerializeConfigValue(val)
	self:QueueSave()
end

function ConfigSystem:QueueSave()
	if self._saveThread then
		pcall(function() task.cancel(self._saveThread) end)
		self._saveThread = nil
	end
	self._saveThread = task.delay(0.35, function()
		self._saveThread = nil
		self:Save()
	end)
end

function ConfigSystem:Save()
	if self._isSaving then return end
	self._isSaving = true
	pcall(function()
		SafeMakeFolder("OxiasidianUI")
		SafeMakeFolder("OxiasidianUI/Config")
		local enc = HttpService:JSONEncode(self.Data)
		SafeWriteFile(self:Path(), enc)
	end)
	self._isSaving = false
end

function ConfigSystem:Flush()
	if self._saveThread then
		pcall(function() task.cancel(self._saveThread) end)
		self._saveThread = nil
	end
	self:Save()
end

function ConfigSystem:Register(key, comp)
	if not key or not comp then return end
	self.Registry[toStr(key)] = comp
end

function ConfigSystem:Reset()
	self.Data = {}
	self:Flush()
end

function ConfigSystem:Load()
	return self:AutoLoad()
end

Library.Config = ConfigSystem
Library.ConfigSystem = ConfigSystem
Library.UIConfig = ConfigSystem
Library.PlayerConfig = PlayerConfig
Library.FunctionConfig = PlayerConfig

-- ============================ 6. Notifications ===============================
local NotifGui, NotifHolder, NotifById, CardTokens, ActiveNotifs = nil, nil, {}, {}, {}
local function RemoveActiveNotif(card)
	for i = #ActiveNotifs, 1, -1 do
		if ActiveNotifs[i] == card then
			table.remove(ActiveNotifs, i)
			break
		end
	end
end
local function EnsureNotif()
	if NotifGui and NotifGui.Parent then return NotifGui end
	local parent = GetUIParent()
	NotifGui = New("ScreenGui", { Name = "OxiasidianNotif", ResetOnSpawn = false,
		IgnoreGuiInset = true, DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, parent)
	NotifHolder = New("Frame", { Name = "Holder", AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12), Size = UDim2.new(0, 290, 1, -24),
		BackgroundTransparency = 1 }, NotifGui)
	local notifLayout = List(NotifHolder, 8)
	notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	return NotifGui
end
local function ParseNotify(args)
	if #args == 0 then return { Title = "Oxiasidian", Description = "", Time = 8 } end
	if isTbl(args[1]) and (args[1].Title ~= nil or args[1].Description ~= nil or args[1].description ~= nil) then
		local d, o = args[1], (isTbl(args[2]) and args[2] or {})
		local t = tonumber(o.Time or o.time or o.Duration or 8) or 8
		if isNum(args[2]) then t = args[2] end
		return { Title = toStr(d.Title or d.title or "Oxiasidian"),
			Description = toStr(d.Description or d.description or d.Desc or ""),
			Buttons = d.Buttons or d.buttons, Id = d.Id or d.id, Time = clamp(t, 1, 30) }
	end
	return { Title = toStr(args[1]), Description = toStr(args[2] or ""),
		Time = clamp(tonumber(args[3]) or 8, 1, 30), Buttons = (isTbl(args[4]) and args[4] or nil),
		Id = (args[5] ~= nil and toStr(args[5]) or nil) }
end
local function ShowNotif(parsed, theme, kind)
	EnsureNotif()
	theme = theme or ThemeSystem.Resolve("Purple")

	local function StartTimer(notifCard, totalTime, token)
		local progFill = notifCard:FindFirstChild("ProgFill", true)
		local tLbl = notifCard:FindFirstChild("TimerLabel", true)

		task.spawn(function()
			local startTime = tick()
			local endTime = startTime + totalTime

			while notifCard and notifCard.Parent and CardTokens[notifCard] == token do
				local now = tick()
				local remaining = math.max(0, endTime - now)
				local alpha = math.clamp(remaining / totalTime, 0, 1)

				if progFill and progFill.Parent then
					progFill.Size = UDim2.new(alpha, 0, 1, 0)
				end
				if tLbl and tLbl.Parent then
					tLbl.Text = string.format("%.1fs", remaining)
				end

				if remaining <= 0 then
					break
				end

				task.wait(0.03)
			end

			if notifCard and notifCard.Parent and CardTokens[notifCard] == token then
				RemoveActiveNotif(notifCard)
				if progFill and progFill.Parent then
					progFill.Size = UDim2.new(0, 0, 1, 0)
				end
				if tLbl and tLbl.Parent then
					tLbl.Text = "0.0s"
				end
				Tween(notifCard, { BackgroundTransparency = 1 })
				task.delay(0.16, function()
					pcall(function() notifCard:Destroy() end)
					CardTokens[notifCard] = nil
				end)
				if parsed.Id and NotifById[parsed.Id] == notifCard then
					NotifById[parsed.Id] = nil
				end
			end
		end)
	end

	if parsed.Id and parsed.Id ~= "" and NotifById[parsed.Id] then
		local existing = NotifById[parsed.Id]
		if existing and existing.Parent then
			local tLbl = existing:FindFirstChild("TitleLabel", true)
			local dLbl = existing:FindFirstChild("DescLabel", true)
			local iLbl = existing:FindFirstChild("IconLabel", true)
			if tLbl then tLbl.Text = parsed.Title end
			if dLbl then dLbl.Text = parsed.Description end
			if iLbl then
				local newIcon = ResolveIcon(parsed.Icon, (kind == "Success" and RobloxIcons["success"]) or (kind == "Warning" and RobloxIcons["warning"]) or (kind == "Error" and RobloxIcons["error"]) or RobloxIcons["bell"])
				iLbl.Image = newIcon
				iLbl.ImageColor3 = accent
			end
			RemoveActiveNotif(existing)
			table.insert(ActiveNotifs, existing)
			CardTokens[existing] = (CardTokens[existing] or 0) + 1
			StartTimer(existing, parsed.Time, CardTokens[existing])
			return existing
		end
		NotifById[parsed.Id] = nil
	end

	-- มือถือจอแคบ: การ์ดเต็มความกว้าง
	local vs = Viewport()
	local w = (vs.X < 560) and math.max(220, vs.X - 24) or 290
	local accent = theme.Accent
	if kind == "Success" then accent = theme.Success
	elseif kind == "Warning" then accent = theme.Warning
	elseif kind == "Error" then accent = theme.Error end

	local card = New("Frame", { Name = "Notif", Size = UDim2.new(0, w, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = theme.Surface, BorderSizePixel = 0 }, NotifHolder)
	Corner(card, 7)
	Stroke(card, theme.Border, 1)
	Pad(card, 8, 10, 8, 10)
	local list = List(card, 5)

	-- แถวบนสุด (Header Row): ไอคอน Roblox + ข้อความหัวข้อ + เวลานับถอยหลัง อยู่ในแถวเดียวกัน
	local headRow = New("Frame", { Name = "HeadRow", Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1, LayoutOrder = 1 }, card)
	local headLayout = New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6) }, headRow)

	local iconAsset = ResolveIcon(parsed.Icon, (kind == "Success" and RobloxIcons["success"]) or (kind == "Warning" and RobloxIcons["warning"]) or (kind == "Error" and RobloxIcons["error"]) or RobloxIcons["bell"])

	local iconImg = New("ImageLabel", { Name = "IconLabel", Size = UDim2.new(0, 16, 0, 16),
		BackgroundTransparency = 1, Image = iconAsset, ImageColor3 = accent,
		ScaleType = Enum.ScaleType.Fit, LayoutOrder = 1 }, headRow)

	local titleLbl = New("TextLabel", { Name = "TitleLabel", Size = UDim2.new(1, -72, 1, 0),
		BackgroundTransparency = 1, Text = parsed.Title, Font = Enum.Font.GothamBold, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = theme.Text, LayoutOrder = 2 }, headRow)

	local timerLbl = New("TextLabel", { Name = "TimerLabel", Size = UDim2.new(0, 45, 1, 0),
		BackgroundTransparency = 1, Text = string.format("%.1fs", parsed.Time),
		Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = theme.TextMuted, LayoutOrder = 3 }, headRow)

	-- ข้อความรายละเอียด (Description)
	local descLbl = New("TextLabel", { Name = "DescLabel", Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = parsed.Description,
		Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = theme.TextMuted, LayoutOrder = 2 }, card)

	-- ปุ่ม (Buttons ถ้ามี)
	if isTbl(parsed.Buttons) and #parsed.Buttons > 0 then
		local row = New("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 3 }, card)
		local hl = New("UIListLayout", { Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder }, row)
		hl.VerticalAlignment = Enum.VerticalAlignment.Center
		for i, b in ipairs(parsed.Buttons) do
			local txt, cb = "OK", nil
			if isTbl(b) then txt, cb = toStr(b.Text or b.text or b.Label or ("Option "..i)), (b.Callback or b.callback)
			elseif isStr(b) then txt = b end
			local btn = New("TextButton", { Size = UDim2.new(0, 0, 0, 28), AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = theme.Surface2, Text = "  " .. txt .. "  ",
				Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = theme.Text }, row)
			Corner(btn, 5)
			Stroke(btn, theme.Border, 1)
			Pad(btn, 0, 6, 0, 6)
			btn.MouseButton1Click:Connect(function()
				pcall(function() if isFn(cb) then cb() end end)
				RemoveActiveNotif(card)
				CardTokens[card] = -1
				pcall(function() card:Destroy() end)
				if parsed.Id then NotifById[parsed.Id] = nil end
			end)
		end
	end

	-- เส้นบอกเวลาที่เหลือ (Countdown Progress Bar)
	local progTrack = New("Frame", { Name = "ProgTrack", Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = theme.Surface2, BorderSizePixel = 0, LayoutOrder = 4 }, card)
	Corner(progTrack, 1)
	local progFill = New("Frame", { Name = "ProgFill", Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = accent, BorderSizePixel = 0 }, progTrack)
	Corner(progFill, 1)

	CardTokens[card] = 1
	if parsed.Id and parsed.Id ~= "" then NotifById[parsed.Id] = card end

	table.insert(ActiveNotifs, card)
	while #ActiveNotifs > 5 do
		local oldest = table.remove(ActiveNotifs, 1)
		if oldest and oldest.Parent then
			CardTokens[oldest] = -1
			Tween(oldest, { BackgroundTransparency = 1 })
			task.delay(0.15, function()
				pcall(function() oldest:Destroy() end)
				CardTokens[oldest] = nil
			end)
		end
	end

	StartTimer(card, parsed.Time, 1)
	return card
end
Library.Notification = {}
Library.Notification.Notify = function(...)
	local a = { ... }
	if a[1] == Library.Notification or a[1] == Library then table.remove(a, 1) end
	return ShowNotif(ParseNotify(a), ThemeSystem.Resolve("Purple"))
end
Library.Notification.Success = function(...)
	local a = { ... }
	if a[1] == Library.Notification or a[1] == Library then table.remove(a, 1) end
	return ShowNotif(ParseNotify(a), ThemeSystem.Resolve("Purple"), "Success")
end
Library.Notification.Warning = function(...)
	local a = { ... }
	if a[1] == Library.Notification or a[1] == Library then table.remove(a, 1) end
	return ShowNotif(ParseNotify(a), ThemeSystem.Resolve("Purple"), "Warning")
end
Library.Notification.Error = function(...)
	local a = { ... }
	if a[1] == Library.Notification or a[1] == Library then table.remove(a, 1) end
	return ShowNotif(ParseNotify(a), ThemeSystem.Resolve("Purple"), "Error")
end
Library.Notify = Library.Notification.Notify

-- ---- 7. Interaction: drag (mouse+touch) ----
local function MakeDraggable(handle, target, owner)
	local dragging, startPos, startInput = false, nil, nil
	Track(owner, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, input.Position, target.Position
			local c1
			c1 = UserInputService.InputChanged:Connect(function(inp)
				if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
					local d = inp.Position - startInput
					target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
						startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end)
			local c2
			c2 = UserInputService.InputEnded:Connect(function(inp)
				if inp.UserInputType == input.UserInputType then
					dragging = false
					pcall(function() c1:Disconnect() end)
					pcall(function() c2:Disconnect() end)
				end
			end)
		end
	end))
end

-- ============================ 2. Window ======================================
function Library:CreateWindow(...)
	local _self = (...)
	local cfg
	if _self == Library then cfg = select(2, ...) else cfg = _self end
	if not isTbl(cfg) then cfg = {} end
	local title = toStr(cfg.Title or cfg.title or "Oxiasidian")
	local subtitle = toStr(cfg.Subtitle or cfg.subtitle or "Blox Fruit")
	local version = toStr(cfg.Version or cfg.version or "v.Premium")
	-- ---- Init ConfigSystem (UI Config: Theme, Hotkey, UI controls) ----
	local uiConfigFile = toStr(cfg.ConfigFile or cfg.configFile or cfg.UIConfig or "Configs")
	ConfigSystem:Init(uiConfigFile)
	-- ---- Init PlayerConfig (Function Config: Settings) ----
	local saveFile = toStr(cfg.SaveFile or cfg.saveFile or cfg.savefile or "BloxFruits")
	local gameName = cfg.GameName or cfg.gameName or cfg.Game or cfg.game or saveFile
	PlayerConfig:Init(gameName, saveFile)
	local boundSettings = cfg.Settings or cfg.settings
	if not boundSettings then
		if getgenv and isTbl(getgenv().Settings) then boundSettings = getgenv().Settings
		elseif isTbl(_G.Settings) then boundSettings = _G.Settings end
	end
	if boundSettings then
		PlayerConfig:BindSettings(boundSettings)
	end
	local defaultTheme = cfg.Theme or cfg.theme or ConfigSystem:Get("UITheme", "Purple")
	local theme = ThemeSystem.Resolve(defaultTheme)
	local themeName = theme.Name
	local onStopAll = cfg.OnStopAll or cfg.onStopAll

	local parent = GetUIParent()
	pcall(function()
		for _, ch in ipairs(parent:GetChildren()) do
			if ch.Name == "QuantumOnyx" and ch:IsA("ScreenGui") then ch:Destroy() end
		end
	end)
	local gui = New("ScreenGui", { Name = "QuantumOnyx", ResetOnSpawn = false,
		IgnoreGuiInset = true, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, parent)

	-- ขนาด compact + clamp มือถือให้เห็นทั้งหมด
	local touch = IsTouchOnly()
	local vs = Viewport()
	local reqW = touch and 500 or 560
	local reqH = touch and 340 or 400
	local winW = math.min(reqW, math.max(300, vs.X - 16))
	local winH = math.min(reqH, math.max(260, vs.Y - 48))
	local navW = (vs.X < 560 or touch) and 118 or 140

	local main = New("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, winW, 0, winH),
		BackgroundColor3 = theme.Background, BorderSizePixel = 0, Active = true }, gui)
	Corner(main, 9)
	local mainStroke = Stroke(main, theme.Border, 1)
	New("Frame", { Size = UDim2.new(1, -24, 0, 2), Position = UDim2.new(0, 12, 0, 0),
		BackgroundColor3 = theme.Accent, BorderSizePixel = 0 }, main)

	-- auto-scale จอเล็กมาก (มือถือแนวตั้ง)
	local uiScale = New("UIScale", {}, main)
	local function FitScale()
		local v = Viewport()
		local s = 1
		if v.X < 420 then s = math.max(0.8, v.X / 420) end
		pcall(function() uiScale.Scale = s end)
	end
	FitScale()
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam then
			Track(Window, cam:GetPropertyChangedSignal("ViewportSize"):Connect(FitScale))
		end
	end)

	-- header 44px (compact)
	local header = New("Frame", { Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = theme.Surface, BorderSizePixel = 0 }, main)
	Corner(header, 9)
	New("Frame", { Size = UDim2.new(1, 0, 0, 9), Position = UDim2.new(0, 0, 1, -9),
		BackgroundColor3 = theme.Surface, BorderSizePixel = 0 }, header)
	New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = theme.BorderSoft, BorderSizePixel = 0 }, header)
	local brandDot = New("Frame", { Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 12, 0.5, -5),
		BackgroundColor3 = theme.Accent, BorderSizePixel = 0 }, header)
	Corner(brandDot, 5)
	New("TextLabel", { Position = UDim2.new(0, 29, 0, 5), Size = UDim2.new(0, 200, 0, 18),
		BackgroundTransparency = 1, Text = string.upper(title), Font = Enum.Font.GothamBlack,
		TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = theme.Text }, header)
	New("TextLabel", { Position = UDim2.new(0, 29, 0, 22), Size = UDim2.new(0, 220, 0, 14),
		BackgroundTransparency = 1, Text = subtitle .. " · " .. version, Font = Enum.Font.Gotham,
		TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = theme.TextMuted }, header)
	local function HBtn(txt, x)
		local b = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0),
			Size = UDim2.new(0, 30, 0, 30), BackgroundColor3 = theme.Surface2, Text = txt,
			Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = theme.TextMuted }, header)
		Corner(b, 6)
		Stroke(b, theme.BorderSoft, 1)
		return b
	end
	local minBtn = HBtn("-", -46)
	local closeBtn = HBtn("X", -10)
	closeBtn.TextSize = 12

	-- body: nav ซ้าย + content
	local body = New("Frame", { Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -44), BackgroundTransparency = 1 }, main)
	local nav = New("Frame", { Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(0, navW, 1, -16), BackgroundColor3 = theme.Surface, BorderSizePixel = 0 }, body)
	Corner(nav, 7)
	Stroke(nav, theme.BorderSoft, 1)
	Pad(nav, 5, 5, 5, 5)
	-- tabs ปกติด้านบน (scroll) + Config แยกด้านล่าง
	local topWrap = New("Frame", { Size = UDim2.new(1, 0, 1, -52), BackgroundTransparency = 1 }, nav)
	local navScroll = New("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		ScrollBarThickness = 3, ScrollBarImageColor3 = theme.Border,
		ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y }, topWrap)
	List(navScroll, 4)
	local navLabel = New("TextLabel", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
		Text = "NAVIGATION", Font = Enum.Font.Gotham, TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = theme.TextDim, LayoutOrder = 0 }, navScroll)
	Pad(navLabel, 0, 4, 0, 0)
	local sep = New("Frame", { Position = UDim2.new(0, 0, 1, -46), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.BorderSoft, BorderSizePixel = 0, BackgroundTransparency = 0.3 }, nav)
	local cfgWrap = New("Frame", { Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1 }, nav)

	local contentWrap = New("Frame", { Position = UDim2.new(0, navW + 16, 0, 8),
		Size = UDim2.new(1, -(navW + 24), 1, -16), BackgroundColor3 = theme.Surface, BorderSizePixel = 0 }, body)
	Corner(contentWrap, 7)
	Stroke(contentWrap, theme.BorderSoft, 1)

	-- ปุ่มลอย OX (มือถือลากได้, แตะเพื่อเปิด)
	local floatBtn = New("TextButton", { AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0, 50, 0, 50),
		BackgroundColor3 = theme.Surface, Text = "OX", Font = Enum.Font.GothamBlack,
		TextSize = 15, TextColor3 = theme.AccentHover, Visible = false }, gui)
	Corner(floatBtn, 12)
	Stroke(floatBtn, theme.Accent, 1)

	local Window = {
		_gui = gui, _main = main, _navScroll = navScroll, _cfgWrap = cfgWrap,
		_contentWrap = contentWrap, _float = floatBtn, _theme = theme, _themeName = themeName,
		_tabs = {}, _activeTab = nil, _open = true,
		_conns = {}, _children = {}, _themed = {}, _onStopAll = onStopAll,
		Title = title, Subtitle = subtitle, Version = version,
		Config = ConfigSystem,
		UIConfig = ConfigSystem,
		PlayerConfig = PlayerConfig,
		FunctionConfig = PlayerConfig,
	}
	local function OnTheme(fn) table.insert(Window._themed, fn) end
	Window._OnTheme = OnTheme
	OnTheme(function(t)
		brandDot.BackgroundColor3 = t.Accent
		navLabel.TextColor3 = t.TextDim
	end)
	MakeDraggable(header, main, Window)

	-- resize มุมขวาล่าง (mouse + touch)
	local grip = New("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.new(0, touch and 34 or 22, 0, touch and 34 or 22),
		BackgroundTransparency = 1, Text = "", ZIndex = 20 }, main)
	Track(Window, grip.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local s0, p0 = main.AbsoluteSize, input.Position
		local v = Viewport()
		local minW, minH = 300, 240
		local maxW = math.max(minW, v.X - 12)
		local maxH = math.max(minH, v.Y - 30)
		local c1 = UserInputService.InputChanged:Connect(function(ci)
			if ci.UserInputType ~= Enum.UserInputType.MouseMovement and ci.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = ci.Position - p0
			winW = clamp(s0.X + d.X, minW, maxW)
			winH = clamp(s0.Y + d.Y, minH, maxH)
			main.Size = UDim2.new(0, winW, 0, winH)
		end)
		local c2
		c2 = UserInputService.InputEnded:Connect(function(ei)
			if ei.UserInputType == input.UserInputType then
				pcall(function() c1:Disconnect() end)
				pcall(function() c2:Disconnect() end)
			end
		end)
	end))

	-- float: ลาก vs แตะ
	do
		local dragging, sp, sg, moved = false, nil, nil, 0
		Track(Window, floatBtn.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			dragging, sp, sg, moved = true, input.Position, floatBtn.Position, 0
			local c1 = UserInputService.InputChanged:Connect(function(inp)
				if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
					local d = inp.Position - sp
					moved = math.abs(d.X) + math.abs(d.Y)
					floatBtn.Position = UDim2.new(sg.X.Scale, sg.X.Offset + d.X, sg.Y.Scale, sg.Y.Offset + d.Y)
				end
			end)
			local c2
			c2 = UserInputService.InputEnded:Connect(function(inp)
				if inp.UserInputType == input.UserInputType then
					dragging = false
					pcall(function() c1:Disconnect() end)
					pcall(function() c2:Disconnect() end)
					if moved < 12 then pcall(function() Window:Open() end) end
				end
			end)
		end))
	end

	function Window:_ApplyVisible(v)
		self._open = v and true or false
		self._main.Visible = self._open
		self._float.Visible = not self._open
		if not self._open then
			-- ซ่อน UI หลัก -> พับ colorpicker ที่กางอยู่ไปด้วย
			for _, ch in ipairs(self._children or {}) do
				pcall(function()
					if isTbl(ch) and ch.Type == "Colorpicker" and ch._open and isFn(ch.ClosePicker) then
						ch.ClosePicker()
					end
				end)
			end
		end
	end
	function Window:Open(...) self:_ApplyVisible(true) end
	-- ซ่อน UI อย่างเดียว ไม่ดับฟังก์ชัน (OnStopAll ย้ายไปอยู่ใน Destroy + ปุ่ม Stop All)
	function Window:Close(...)
		self:_ApplyVisible(false)
	end
	function Window:Toggle(...)
		if self._open then self:Close() else self:Open() end
	end
	function Window:Minimize(...) self:_ApplyVisible(false) end
	-- โหลดและอัปเดต Config ใหม่ทั้งหมดจากดิสก์ พร้อมซิงค์ UI Components ทุกตัว
	function Window:ReloadConfig()
		local pOk = false
		pcall(function() pOk = PlayerConfig:AutoLoad() end)
		local cOk = false
		pcall(function() cOk = ConfigSystem:AutoLoad() end)

		-- อัปเดตธีมใหม่จาก Config
		pcall(function()
			local th = ConfigSystem:Get("UITheme", Window._themeName)
			if th and ThemeSystem.Resolve(th) then
				Window:SetTheme(th)
			end
		end)

		-- วนลูปอัปเดตค่าไปยัง UI Components ทั้งหมดในหน้าต่างให้ตรงกับ Config ล่าสุด
		local updatedCount = 0
		if Window._children then
			for _, comp in ipairs(Window._children) do
				if comp and comp._saveKey then
					local key = comp._saveKey
					local val = ConfigSystem:Get(key, nil)
					if val == nil then
						val = PlayerConfig:Get(key, nil)
					end
					if val == nil and isTbl(PlayerConfig.BoundSettings) and PlayerConfig.BoundSettings[key] ~= nil then
						val = PlayerConfig.BoundSettings[key]
					end

					if val ~= nil and isFn(comp.SetValue) then
						pcall(function()
							comp:SetValue(val)
							updatedCount = updatedCount + 1
						end)
					end
				end
			end
		end

		return true, updatedCount
	end

	-- ระบบ Re-open Window: โหลด config ใหม่ทั้งหมด แล้วเปิดหน้าต่าง
	function Window:Reopen(...)
		self:ReloadConfig()
		self:Open()
	end
	Window.Show = Window.Open
	Window.Hide = Window.Minimize
	Library._lastWindow = Window
	Library.Reopen = function(...)
		local w = Library._lastWindow
		if w then
			pcall(function() w:Reopen() end)
			return true
		end
		return false
	end
	Library.ToggleUI = function(...)
		local w = Library._lastWindow
		if w then pcall(function() w:Toggle() end) return true end
		return false
	end
	-- ไฟล์สคริปต์ตั้งต้นที่ใช้สร้าง UI (MainScript/EXAMPLE) — ปรับได้ก่อนเรียก HardReload
	Library.BootstrapFile = "MainScript_Original.lua"
	-- Reload UI ทั้งหมด: เซฟค่า -> หยุด+ทำลายหน้าต่างเก่า -> รันไฟล์ใหม่จากดิสก์
	-- โค้ดจุดไหนถูกแก้ไขจะถูกโหลดใหม่ทั้งหมด (ต้องรันสคริปต์ใหม่สถานเดียว lib สลับโค้ดให้ UI ที่สร้างแล้วไม่ได้)
	Library.HardReload = function(a)
		local path = nil
		if a ~= nil and a ~= Library then path = a end
		if path == nil then path = Library.BootstrapFile end
		path = toStr(path or "")
		if path == "" then return false, "no bootstrap file" end

		pcall(function()
			local w = Library._lastWindow
			if w then
				pcall(function() ConfigSystem:Flush() end)
				pcall(function() PlayerConfig:Flush() end)
				w:Destroy()
			end
		end)
		task.wait(0.3)
		pcall(function()
			if getgenv then
				getgenv().OxiasidianActive = nil
				getgenv().QuantumOnyxGUI = nil
			end
		end)
		local src = nil
		if readfile then
			pcall(function() src = readfile(path) end)
			if type(src) ~= "string" or #src < 100 then
				pcall(function() src = readfile("C:\\Users\\KaChini\\Downloads\\new2\\" .. path) end)
			end
		end
		if type(src) ~= "string" or #src < 100 then return false, "read failed: " .. path end
		local fn, lerr = loadstring(src, "reload:" .. path)
		if not fn then return false, tostring(lerr) end
		task.spawn(function()
			local ok, r = pcall(fn)
			if not ok then
				pcall(function()
					Library.Notification.Error("Reload", "รีโหลดล้มเหลว: " .. tostring(r))
				end)
			end
		end)
		return true
	end
	Track(Window, minBtn.MouseButton1Click:Connect(function() Window:Minimize() end))
	Track(Window, closeBtn.MouseButton1Click:Connect(function() Window:Close() end))
	-- ปุ่มลัดซ่อน/เปิด UI ย้ายไปเป็น keybind "Toggle UI Key" ใน Tab Settings
	-- (ค่า default RightShift + จำค่าที่ตั้งไว้) จึงลบ listener ซ้ำตรงนี้ออกกัน toggle เบิ้ล

	function Window:BindSettings(tbl)
		PlayerConfig:BindSettings(tbl)
	end
	function Window:SetTheme(...)
		local a = Pack(Window, ...)
		local t = ThemeSystem.Resolve(a[1])
		Window._theme, Window._themeName = t, t.Name
		main.BackgroundColor3 = t.Background
		mainStroke.Color = t.Border
		header.BackgroundColor3 = t.Surface
		contentWrap.BackgroundColor3 = t.Surface
		nav.BackgroundColor3 = t.Surface
		floatBtn.BackgroundColor3 = t.Surface
		floatBtn.TextColor3 = t.AccentHover
		for _, fn in ipairs(Window._themed) do pcall(fn, t) end
	end

	function Window:Notify(...)
		local a = Pack(Window, ...)
		return ShowNotif(ParseNotify(a), Window._theme)
	end
	Window.Notify = Window.Notify

	-- ======================== 3. Tabs ====================================
	function Window:AddTab(...)
		local a = Pack(Window, ...)
		return self:CreateTab(toStr(a[1] or ("Tab " .. (#self._tabs + 1))), a[2])
	end
	function Window:CreateTab(...)
		local raw = { ... }
		if raw[1] == Window then table.remove(raw, 1) end
		local name = toStr(raw[1] or ("Tab " .. (#Window._tabs + 1)))
		local iconId = raw[2]
		local ln = string.lower(name)
		local isConfig = (ln == "config" or ln == "settings")
		local holder = isConfig and Window._cfgWrap or Window._navScroll
		local th = Window._theme
		local btn = New("TextButton", { Name = "Tab_" .. name,
			Size = UDim2.new(1, 0, 0, isConfig and 40 or 36),
			BackgroundColor3 = th.Surface2, BackgroundTransparency = 1, Text = "" }, holder)
		Corner(btn, 6)
		local bs = Stroke(btn, th.BorderSoft, 1)
		bs.Transparency = 1
		if not isConfig then btn.LayoutOrder = #Window._tabs + 1 end
		local ind = New("Frame", { Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 0, 0, 6),
			BackgroundColor3 = th.Accent, BorderSizePixel = 0, Visible = false }, btn)
		Corner(ind, 1)
		-- badge หลัง icon ให้ดูมีมิติ (active = พื้น accent + glyph ขาว)
		local badge = New("Frame", { Position = UDim2.new(0, 6, 0.5, -12),
			Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = th.Surface3,
			BackgroundTransparency = 0.4, BorderSizePixel = 0 }, btn)
		Corner(badge, 6)
		local badgeStroke = Stroke(badge, th.BorderSoft, 1)
		badgeStroke.Transparency = 0.5
		local ic = New("TextLabel", { Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1, Text = (isConfig and "◉" or IconText(iconId)), Font = Enum.Font.GothamBlack,
			TextSize = 13, TextColor3 = th.TextDim }, badge)
		local nm = New("TextLabel", { Position = UDim2.new(0, 33, 0, 0), Size = UDim2.new(1, -37, 1, 0),
			BackgroundTransparency = 1, Text = name, Font = isConfig and Enum.Font.GothamBlack or Enum.Font.Gotham,
			TextSize = isConfig and 12 or 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = isConfig and th.Text or th.TextMuted }, btn)
		local page = New("ScrollingFrame", { Name = "Page_" .. name,
			Size = UDim2.new(1, -12, 1, -12), Position = UDim2.new(0, 6, 0, 6),
			BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = th.Border,
			ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, Window._contentWrap)
		List(page, 7)
		Pad(page, 2, 2, 8, 2)
		-- ส่วนหัวหน้าเพจตามภาพ: breadcrumb + ชื่อ tab + คำอธิบาย
		local ph = New("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 0 }, page)
		local crumb = New("TextLabel", { Position = UDim2.new(0, 2, 0, 0), Size = UDim2.new(1, -4, 0, 11),
			BackgroundTransparency = 1, Text = "OVERVIEW / " .. string.upper(name),
			Font = Enum.Font.Gotham, TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Window._theme.TextDim }, ph)
		local ptitle = New("TextLabel", { Position = UDim2.new(0, 2, 0, 11), Size = UDim2.new(1, -4, 0, 19),
			BackgroundTransparency = 1, Text = name,
			Font = Enum.Font.GothamBlack, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = Window._theme.Text }, ph)
		local psub = New("TextLabel", { Position = UDim2.new(0, 2, 0, 31), Size = UDim2.new(1, -4, 0, 13),
			BackgroundTransparency = 1, Text = "Compact controls, clear status, independent scrolling.",
			Font = Enum.Font.Gotham, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = Window._theme.TextMuted }, ph)
		OnTheme(function(t)
			crumb.TextColor3 = t.TextDim
			ptitle.TextColor3 = t.Text
			psub.TextColor3 = t.TextMuted
		end)

		local Tab = { _window = Window, _button = btn, _page = page, _sections = {},
			_conns = {}, _children = {}, Name = name, Icon = iconId, _isConfig = isConfig }
		local function Paint(active)
			if active then
				btn.BackgroundTransparency = 0
				bs.Transparency = 1
				ind.Visible = true
				badge.BackgroundColor3 = th.Accent
				badge.BackgroundTransparency = 0.15
				badgeStroke.Color = th.AccentHover
				badgeStroke.Transparency = 0
				ic.TextColor3 = Color3.fromRGB(255, 255, 255)
				nm.TextColor3 = th.Text
				nm.Font = Enum.Font.GothamBold
			else
				btn.BackgroundTransparency = 1
				bs.Transparency = 1
				ind.Visible = false
				badge.BackgroundColor3 = th.Surface3
				badge.BackgroundTransparency = 0.4
				badgeStroke.Color = th.BorderSoft
				badgeStroke.Transparency = 0.5
				ic.TextColor3 = th.TextDim
				nm.TextColor3 = isConfig and th.Text or th.TextMuted
				nm.Font = isConfig and Enum.Font.GothamBlack or Enum.Font.Gotham
			end
		end
		Tab._Paint = Paint
		OnTheme(function(t)
			th = t
			btn.BackgroundColor3 = t.Surface2
			ind.BackgroundColor3 = t.Accent
			page.ScrollBarImageColor3 = t.Border
			badgeStroke.Color = (Tab == Window._activeTab) and t.AccentHover or t.BorderSoft
			Paint(Tab == Window._activeTab)
		end)
		function Tab:Select()
			for _, o in ipairs(Window._tabs) do
				local act = (o == Tab)
				o._page.Visible = act
				pcall(function() o._Paint(act) end)
			end
			Window._activeTab = Tab
		end
		Track(Tab, btn.MouseButton1Click:Connect(function()
			Tab:Select()
			Tween(btn, { BackgroundTransparency = 0.3 }, T_INST)
			task.delay(0.12, function()
				pcall(function()
					btn.BackgroundTransparency = (Tab == Window._activeTab) and 0 or 1
				end)
			end)
		end))
		Track(Tab, btn.MouseEnter:Connect(function()
			if Tab ~= Window._activeTab then Tween(btn, { BackgroundTransparency = 0.6 }, T_INST) end
		end))
		Track(Tab, btn.MouseLeave:Connect(function()
			if Tab ~= Window._activeTab then Tween(btn, { BackgroundTransparency = 1 }, T_INST) end
		end))

		-- ==================== 4. Sections ====================
		function Tab:addSection(...)
			local a = Pack(Tab, ...)
			local secTitle = nil
			if isStr(a[1]) and a[1] ~= "" then secTitle = a[1]
			elseif isTbl(a[1]) then secTitle = a[1].Title or a[1].title or a[1].Name end
			local holder2 = New("Frame", { Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
				LayoutOrder = #Tab._sections + 1 }, page)
			List(holder2, 7)
			if secTitle then
				local h = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 }, holder2)
				New("Frame", { Size = UDim2.new(0, 12, 0, 2), Position = UDim2.new(0, 0, 0.5, -1),
					BackgroundColor3 = Window._theme.Accent, BorderSizePixel = 0 }, h)
				New("TextLabel", { Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -18, 1, 0),
					BackgroundTransparency = 1, Text = string.upper(toStr(secTitle)),
					Font = Enum.Font.GothamBold, TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Window._theme.TextMuted }, h)
			end
			local Section = { _tab = Tab, _holder = holder2, _menus = {}, _conns = {}, _children = {}, Title = secTitle or "" }
			function Section:addMenu(...)
				local ma = Pack(Section, ...)
				local mName = "Menu"
				if isStr(ma[1]) then mName = ma[1]
				elseif isTbl(ma[1]) then mName = toStr(ma[1].Title or ma[1].Name or "Menu") end
				local box = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Window._theme.Surface2, BorderSizePixel = 0,
					LayoutOrder = #Section._menus + 1 }, holder2)
				Corner(box, 6)
				local mStroke = Stroke(box, Window._theme.BorderSoft, 1)
				Pad(box, 7, 9, 7, 9)
				List(box, 4)
				local mh = New("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 0 }, box)
				-- แถบ accent ข้างหัวข้อการ์ด (fixed offset ปลอดภัยกับ auto-size layout)
				local mtick = New("Frame", { Size = UDim2.new(0, 3, 0, 12), Position = UDim2.new(0, 0, 0.5, -6),
					BackgroundColor3 = Window._theme.Accent, BorderSizePixel = 0 }, mh)
				Corner(mtick, 1)
				local mt = New("TextLabel", { Position = UDim2.new(0, 9, 0, 0), Size = UDim2.new(1, -9, 1, 0),
					BackgroundTransparency = 1, Text = string.upper(mName), Font = Enum.Font.GothamBold, TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					TextColor3 = Window._theme.Text }, mh)
				New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Window._theme.BorderSoft,
					BorderSizePixel = 0, BackgroundTransparency = 0.25, LayoutOrder = 1 }, box)
				OnTheme(function(t)
					box.BackgroundColor3 = t.Surface2
					mStroke.Color = t.BorderSoft
					mt.TextColor3 = t.Text
					mtick.BackgroundColor3 = t.Accent
				end)
				local Menu = { _section = Section, _window = Window, _box = box,
					_order = 2, _conns = {}, _children = {}, Name = mName }
				local function NextOrder()
					Menu._order = Menu._order + 1
					return Menu._order
				end

				-- ============ 5. UI Components ============
				-- ---- Toggle / Checkbox (compact 32px) ----
				local function BuildToggle(label, default, callback, locked, desc, saveKey, square)
					label = toStr(label ~= nil and label or "Toggle")
					-- auto-generate saveKey when not provided
					if not saveKey or saveKey == "" then
						saveKey = (Menu.Name or "General") .. "_" .. label:gsub("[^%w%-%_]", "")
					end
					local init = (default == true or default == 1)
					-- restore from config if available
					init = ConfigSystem:Get(saveKey, init, "Toggle")
					local h = (desc and desc ~= "") and 38 or 32
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, h),
						BackgroundColor3 = Window._theme.Surface, BackgroundTransparency = 1,
						BorderSizePixel = 0, LayoutOrder = NextOrder() }, box)
					local tl = New("TextLabel", { Position = UDim2.new(0, 9, 0, (desc and desc ~= "") and 2 or 0),
						Size = UDim2.new(1, -62, 0, (desc and desc ~= "") and 16 or h),
						BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					if desc and desc ~= "" then
						New("TextLabel", { Position = UDim2.new(0, 9, 0, 17), Size = UDim2.new(1, -62, 0, 13),
							BackgroundTransparency = 1, Text = toStr(desc), Font = Enum.Font.Gotham, TextSize = 10,
							TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
							TextColor3 = Window._theme.TextMuted }, row)
					end
					local sw = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0),
						Size = square and UDim2.new(0, 22, 0, 22) or UDim2.new(0, 40, 0, 20),
						BackgroundColor3 = Window._theme.Surface3, BorderSizePixel = 0 }, row)
					Corner(sw, square and 5 or 10)
					Stroke(sw, Window._theme.Border, 1)
					local knob
					if square then
						knob = New("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
							Text = "X", Font = Enum.Font.GothamBlack, TextSize = 13,
							TextColor3 = Color3.fromRGB(255, 255, 255), Visible = false }, sw)
					else
						knob = New("Frame", { Size = UDim2.new(0, 14, 0, 14),
							Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = Window._theme.TextDim,
							BorderSizePixel = 0 }, sw)
						Corner(knob, 7)
					end
					local hit = New("TextButton", { Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1, Text = "" }, row)
					local comp = { _window = Window, _row = row, _value = init, _callback = callback,
						_locked = (locked == true), _saveKey = saveKey, _conns = {}, Type = "Toggle" }
					OnTheme(function(t)
						row.BackgroundColor3 = t.Surface
						tl.TextColor3 = t.Text
						if comp._value then sw.BackgroundColor3 = t.Accent
						else sw.BackgroundColor3 = t.Surface3 end
					end)
					local function Paint(anim)
						local on = comp._value
						local bg = on and Window._theme.Accent or Window._theme.Surface3
						if square then
							if anim then Tween(sw, { BackgroundColor3 = bg }) else sw.BackgroundColor3 = bg end
							knob.Visible = on
						else
							local pos = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
							local kc = on and Color3.fromRGB(255, 255, 255) or Window._theme.TextDim
							if anim then
								Tween(sw, { BackgroundColor3 = bg })
								Tween(knob, { Position = pos, BackgroundColor3 = kc })
							else
								sw.BackgroundColor3, knob.Position, knob.BackgroundColor3 = bg, pos, kc
							end
						end
						if comp._locked then tl.TextColor3 = Window._theme.TextDim end
					end
					Paint(false)
					local function Apply(v, fire)
						if v == nil then return end
						local b = (v == true or v == 1)
						if isNum(v) then b = (v ~= 0) end
						if isStr(v) then local l = string.lower(v) b = (l == "true" or l == "1") end
						comp._value = b
						Paint(true)
						ConfigSystem:Set(comp._saveKey, b)
						if fire ~= false and isFn(comp._callback) then
							task.spawn(function() pcall(comp._callback, b) end)
						end
					end
					comp.GetValue = function() return comp._value end
					comp.Get = comp.GetValue
					comp.SetValue = function(a, b) Apply((b ~= nil and b or a), true) end
					comp.Update = comp.SetValue
					comp.Set = comp.SetValue
					comp.Destroy = function() DisconnectAll(comp) pcall(function() row:Destroy() end) end
					Track(comp, hit.MouseButton1Click:Connect(function()
						if comp._locked then return end
						Apply(not comp._value, true)
					end))
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.addToggle = function(...)
					local a = Pack(Menu, ...)
					return BuildToggle(a[1], a[2], a[3], a[4], a[5], a[6], false)
				end
				Menu.AddToggle, Menu.CreateToggle, Menu.addtoggle = Menu.addToggle, Menu.addToggle, Menu.addToggle
				Menu.addCheckbox = function(...)
					local a = Pack(Menu, ...)
					return BuildToggle(a[1], a[2], a[3], a[4], a[5], a[6], true)
				end
				Menu.AddCheckbox, Menu.CreateCheckbox = Menu.addCheckbox, Menu.addCheckbox
				Menu.addCheckBox = Menu.addCheckbox

				-- ---- Button (28px, touch 40px hit via padding) ----
				Menu.addButton = function(...)
					local a = Pack(Menu, ...)
					local label, cb, locked, desc = toStr(a[1] or "Button"), nil, false, nil
					for i = 2, a.n do
						local v = a[i]
						if isFn(v) and cb == nil then cb = v
						elseif type(v) == "boolean" and v == true then locked = true
						elseif isStr(v) and desc == nil and v:find(" ") then desc = v end
					end
					local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 30),
						BackgroundColor3 = Window._theme.Surface, Text = label,
						Font = Enum.Font.GothamBold, TextSize = 12,
						TextColor3 = locked and Window._theme.TextDim or Window._theme.Text,
						LayoutOrder = NextOrder() }, box)
					Corner(b, 5)
					local bs2 = Stroke(b, Window._theme.BorderSoft, 1)
					OnTheme(function(t)
						b.BackgroundColor3 = t.Surface
						b.TextColor3 = locked and t.TextDim or t.Text
						bs2.Color = t.BorderSoft
					end)
					local comp = { _window = Window, _btn = b, _callback = cb,
						_locked = locked, _conns = {}, Type = "Button" }
					comp.Fire, comp.Click = function() if not comp._locked and isFn(cb) then task.spawn(function() pcall(cb) end) end end, nil
					comp.Click = comp.Fire
					comp.Destroy = function() DisconnectAll(comp) pcall(function() b:Destroy() end) end
					Track(comp, b.MouseButton1Click:Connect(function()
						if locked then return end
						Tween(b, { BackgroundTransparency = 0.4 }, T_INST)
						task.delay(0.1, function() pcall(function() b.BackgroundTransparency = 0 end) end)
						if isFn(cb) then task.spawn(function() pcall(cb) end) end
					end))
					Track(comp, b.MouseEnter:Connect(function()
						if not locked then Tween(b, { BackgroundColor3 = Window._theme.Surface3 }, T_INST) end
					end))
					Track(comp, b.MouseLeave:Connect(function()
						if not locked then Tween(b, { BackgroundColor3 = Window._theme.Surface }, T_INST) end
					end))
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddButton, Menu.CreateButton, Menu.addbutton = Menu.addButton, Menu.addButton, Menu.addButton

				-- ---- ButtonGrid (2 คอลัมน์, แบบ Fake Admin: {Label, Callback}) ----
				Menu.addButtonGrid = function(...)
					local a = Pack(Menu, ...)
					local items = nil
					for i = 1, a.n do
						if isTbl(a[i]) then items = a[i] break end
					end
					if not isTbl(items) then items = {} end
					local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 0),
						BackgroundTransparency = 1, LayoutOrder = NextOrder() }, box)
					List(wrap, 4)
					local comp = { _window = Window, _box = wrap, _conns = {}, Type = "ButtonGrid" }
					local function MakeBtn(text, cb, locked, parent, w)
						local b = New("TextButton", { Size = w,
							BackgroundColor3 = Window._theme.Surface, Text = toStr(text),
							Font = Enum.Font.GothamBold, TextSize = 12,
							TextColor3 = locked and Window._theme.TextDim or Window._theme.Text }, parent)
						Corner(b, 5)
						Stroke(b, Window._theme.BorderSoft, 1)
						Track(comp, b.MouseButton1Click:Connect(function()
							if locked then return end
							if isFn(cb) then task.spawn(function() pcall(cb) end) end
						end))
						return b
					end
					local function Build(list)
						for _, ch in ipairs(wrap:GetChildren()) do
							if ch:IsA("GuiObject") then pcall(function() ch:Destroy() end) end
						end
						local n = #list
						local rows = math.ceil(n / 2)
						if rows < 1 then rows = 1 end
						for r = 1, rows do
							local rowF = New("Frame", { Size = UDim2.new(1, 0, 0, 30),
								BackgroundTransparency = 1, LayoutOrder = r }, wrap)
							local e1 = list[(r - 1) * 2 + 1]
							local e2 = list[(r - 1) * 2 + 2]
							local function Parse(e)
								if isStr(e) then return e, nil, false end
								if isTbl(e) then
									return toStr(e.Label or e.Text or e.Title or e.Name or "Button"),
										(e.Callback or e.callback or e.Func or e.func or e.OnClick),
										(e.locked == true or e.Locked == true)
								end
								return "Button", nil, false
							end
							if e1 ~= nil then
								local t1, c1, l1 = Parse(e1)
								if e2 == nil then
									MakeBtn(t1, c1, l1, rowF, UDim2.new(1, 0, 0, 30))
								else
									local t2, c2, l2 = Parse(e2)
									MakeBtn(t1, c1, l1, rowF, UDim2.new(0.5, -2, 0, 30))
									local b2 = MakeBtn(t2, c2, l2, rowF, UDim2.new(0.5, -2, 0, 30))
									b2.Position = UDim2.new(0.5, 2, 0, 0)
								end
							end
						end
						wrap.Size = UDim2.new(1, 0, 0, rows * 30 + math.max(0, rows - 1) * 4)
					end
					Build(items)
					comp.Refresh = function(a2, b2)
						local v = (b2 ~= nil and b2 or a2)
						if v == comp then return end
						if isTbl(v) then Build(v) end
					end
					comp.SetOptions = comp.Refresh
					comp.Destroy = function() DisconnectAll(comp) pcall(function() wrap:Destroy() end) end
					OnTheme(function(t)
						for _, d in ipairs(wrap:GetDescendants()) do
							if d:IsA("TextButton") then
								d.BackgroundColor3 = t.Surface
								d.TextColor3 = t.Text
							end
						end
					end)
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddButtonGrid, Menu.CreateButtonGrid = Menu.addButtonGrid, Menu.addButtonGrid
				Menu.addGrid, Menu.AddGrid, Menu.addgrid = Menu.addButtonGrid, Menu.addButtonGrid, Menu.addButtonGrid

				-- ---- Slider (compact, touch drag) ----
				Menu.addSlider = function(...)
					local a = Pack(Menu, ...)
					local label = toStr(a[1] or "Slider")
					local min, max, def = tonumber(a[2]) or 0, tonumber(a[3]) or 100, tonumber(a[4])
					local cb, locked, step, saveKey = nil, false, 1, nil
					for i = 5, a.n do
						local v = a[i]
						if isFn(v) and cb == nil then cb = v
						elseif type(v) == "boolean" and v == true then locked = true
						elseif isNum(v) then if step == 1 then step = v end
						elseif isStr(v) and saveKey == nil and not v:find(" ") then saveKey = v end
					end
					if max < min then min, max = max, min end
					if def == nil then def = min end
					def = clamp(def, min, max)
					if step <= 0 then step = 1 end
					-- auto-generate saveKey when not provided
					if not saveKey or saveKey == "" then
						saveKey = (Menu.Name or "General") .. "_" .. label:gsub("[^%w%-%_]", "")
					end
					-- restore from config if available
					local savedDef = ConfigSystem:Get(saveKey, def, "Slider")
					if type(savedDef) == "number" then def = clamp(savedDef, min, max) end
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, 48),
						BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0, LayoutOrder = NextOrder() }, box)
					Corner(row, 5)
					Stroke(row, Window._theme.BorderSoft, 1).Transparency = 0.4
					local tl = New("TextLabel", { Position = UDim2.new(0, 9, 0, 5), Size = UDim2.new(1, -75, 0, 16),
						BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					local val = New("TextBox", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -9, 0, 4),
						Size = UDim2.new(0, 52, 0, 18), BackgroundColor3 = Window._theme.Surface2,
						BackgroundTransparency = 0, BorderSizePixel = 0, Text = toStr(def),
						Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center,
						TextColor3 = Window._theme.AccentHover, ClearTextOnFocus = false,
						TextEditable = not locked }, row)
					Corner(val, 4)
					local valStroke = Stroke(val, Window._theme.Border, 1)
					local bar = New("TextButton", { Position = UDim2.new(0, 9, 0, 26), Size = UDim2.new(1, -18, 0, 18),
						BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, row)
					local track = New("Frame", { Position = UDim2.new(0, 0, 0.5, -2), Size = UDim2.new(1, 0, 0, 4),
						BackgroundColor3 = Window._theme.Surface3, BorderSizePixel = 0, Active = false }, bar)
					Corner(track, 2)
					local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0),
						BackgroundColor3 = Window._theme.Accent, BorderSizePixel = 0, Active = false }, track)
					Corner(fill, 2)
					local dot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0, Active = false }, track)
					Corner(dot, 6)
					local comp = { _window = Window, _row = row, _box = val, _value = def, _callback = cb,
						_locked = locked, _saveKey = saveKey, _conns = {}, Type = "Slider",
						Min = min, Max = max, Step = step }
					OnTheme(function(t)
						row.BackgroundColor3 = t.Surface
						tl.TextColor3 = comp._locked and t.TextDim or t.Text
						val.BackgroundColor3 = t.Surface2
						val.TextColor3 = comp._locked and t.TextDim or t.AccentHover
						valStroke.Color = t.Border
						track.BackgroundColor3 = t.Surface3
						fill.BackgroundColor3 = t.Accent
					end)
					local function Render()
						local r = (max - min) <= 0 and 0 or (comp._value - min) / (max - min)
						fill.Size = UDim2.new(r, 0, 1, 0)
						dot.Position = UDim2.new(r, 0, 0.5, 0)
						if not val:IsFocused() then
							local fmt = (step < 1) and ("%.1f") or ("%d")
							val.Text = string.format(fmt, comp._value)
						end
					end
					Render()
					local function Apply(v, fire)
						v = tonumber(v)
						if v == nil then return end
						if step > 0 then v = math.floor((v - min) / step + 0.5) * step + min end
						v = clamp(v, min, max)
						comp._value = v
						Render()
						ConfigSystem:Set(comp._saveKey, v)
						if fire ~= false and isFn(comp._callback) then
							task.spawn(function() pcall(comp._callback, v) end)
						end
					end
					comp.GetValue = function() return comp._value end
					comp.Get = comp.GetValue
					comp.SetValue = function(a2, b2) Apply((b2 ~= nil and b2 or a2), true) end
					comp.Update = comp.SetValue
					comp.Set = comp.SetValue
					comp.Destroy = function() DisconnectAll(comp) pcall(function() row:Destroy() end) end

					-- รองรับการพิมพ์ตัวเลขลงในช่องโดยตรง
					Track(comp, val.Focused:Connect(function()
						val.TextColor3 = Color3.fromRGB(255, 255, 255)
						valStroke.Color = Window._theme.Accent
					end))
					Track(comp, val:GetPropertyChangedSignal("Text"):Connect(function()
						if val:IsFocused() then
							local cleaned = val.Text:gsub("[^%d%.%-]", "")
							if cleaned ~= val.Text then
								val.Text = cleaned
							end
						end
					end))
					Track(comp, val.FocusLost:Connect(function(enter)
						val.TextColor3 = Window._theme.AccentHover
						valStroke.Color = Window._theme.Border
						local num = tonumber(val.Text)
						if num ~= nil then
							Apply(num, true)
						else
							Render()
						end
					end))

					-- รองรับการคลิกลาก Slider ตามปกติ
					local dragging = false
					local function ToVal(x)
						local ax = track.AbsolutePosition.X
						local aw = math.max(1, track.AbsoluteSize.X)
						local r = clamp((x - ax) / aw, 0, 1)
						return min + r * (max - min)
					end
					Track(comp, bar.InputBegan:Connect(function(input)
						if comp._locked then return end
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragging = true
							Apply(ToVal(input.Position.X), true)
						end
					end))
					Track(comp, UserInputService.InputChanged:Connect(function(input)
						if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							Apply(ToVal(input.Position.X), true)
						end
					end))
					Track(comp, UserInputService.InputEnded:Connect(function(input)
						if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
							dragging = false
						end
					end))
					ConfigSystem:Register(comp._saveKey, comp)
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddSlider, Menu.CreateSlider, Menu.addslider = Menu.addSlider, Menu.addSlider, Menu.addSlider

				-- ---- Progress / status bar (แบบ RUNTIME STATUS ในภาพ) ----
				-- menu:addProgress(label, value, max, statusText, saveKey)
				-- แถวบน: ● label ............ value/max | หลอด fill accent | ล่าง: statusText
				Menu.addProgress = function(...)
					local a = Pack(Menu, ...)
					local label = toStr(a[1] or "Progress")
					local val = tonumber(a[2]) or 0
					local max = tonumber(a[3]) or 100
					local statusText, saveKey = "", nil
					for i = 4, a.n do
						local v = a[i]
						if isStr(v) then
							if v:find(" ") or statusText ~= "" then
								if statusText == "" then statusText = v end
							elseif saveKey == nil then saveKey = v end
						end
					end
					if max <= 0 then max = 100 end
					if not saveKey or saveKey == "" then
						saveKey = (Menu.Name or "General") .. "_" .. label:gsub("[^%w%-%_]", "")
					end
					local savedVal = ConfigSystem:Get(saveKey, nil, "Progress")
					if type(savedVal) == "number" then val = clamp(savedVal, 0, max) end
					val = clamp(val, 0, max)
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, 54),
						BackgroundTransparency = 1, LayoutOrder = NextOrder() }, box)
					local dot = New("Frame", { Size = UDim2.new(0, 8, 0, 8),
						Position = UDim2.new(0, 2, 0, 5), BackgroundColor3 = Window._theme.Success,
						BorderSizePixel = 0 }, row)
					Corner(dot, 4)
					local tl = New("TextLabel", { Position = UDim2.new(0, 16, 0, 0),
						Size = UDim2.new(1, -90, 0, 18), BackgroundTransparency = 1, Text = label,
						Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					local vr = New("TextLabel", { AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, -2, 0, 0), Size = UDim2.new(0, 86, 0, 18),
						BackgroundTransparency = 1, Text = "",
						Font = Enum.Font.GothamBold, TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Window._theme.TextMuted }, row)
					local track = New("Frame", { Position = UDim2.new(0, 0, 0, 24),
						Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Window._theme.Surface3,
						BorderSizePixel = 0 }, row)
					Corner(track, 3)
					local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0),
						BackgroundColor3 = Window._theme.Accent, BorderSizePixel = 0 }, track)
					Corner(fill, 3)
					local bl = New("TextLabel", { Position = UDim2.new(0, 0, 0, 34),
						Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = statusText,
						Font = Enum.Font.Gotham, TextSize = 10,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.TextMuted }, row)
					local comp = { _window = Window, _row = row, _value = val, _max = max,
						_saveKey = saveKey, _conns = {}, Type = "Progress" }
					OnTheme(function(t)
						tl.TextColor3 = t.Text
						vr.TextColor3 = t.TextMuted
						bl.TextColor3 = t.TextMuted
						track.BackgroundColor3 = t.Surface3
						fill.BackgroundColor3 = t.Accent
						dot.BackgroundColor3 = t.Success
					end)
					local function Render()
						local r = (comp._max <= 0) and 0 or (comp._value / comp._max)
						fill.Size = UDim2.new(clamp(r, 0, 1), 0, 1, 0)
						vr.Text = string.format("%d / %d", math.floor(comp._value + 0.5), comp._max)
					end
					Render()
					local function Apply(v, fire)
						v = tonumber(v)
						if v == nil then return end
						comp._value = clamp(v, 0, comp._max)
						Render()
						ConfigSystem:Set(comp._saveKey, comp._value)
					end
					comp.GetValue = function() return comp._value end
					comp.Get = comp.GetValue
					comp.SetValue = function(a2, b2) Apply((b2 ~= nil and b2 or a2), true) end
					comp.Update = comp.SetValue
					comp.Set = comp.SetValue
					comp.SetMax = function(a2, b2)
						local m = tonumber(b2 ~= nil and b2 or a2)
						if m and m > 0 then comp._max = m comp._value = clamp(comp._value, 0, m) Render() end
					end
					comp.SetStatus = function(a2, b2) bl.Text = toStr(b2 ~= nil and b2 or a2) end
					comp.RefreshDesc = comp.SetStatus
					comp.Destroy = function() DisconnectAll(comp) pcall(function() row:Destroy() end) end
					ConfigSystem:Register(comp._saveKey, comp)
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddProgress, Menu.CreateProgress, Menu.addprogress = Menu.addProgress, Menu.addProgress, Menu.addProgress
				Menu.addStatus, Menu.AddStatus = Menu.addProgress, Menu.addProgress

				-- ---- Dropdown / MultiDropdown (search + mobile popup) ----
				local function NormList(c)
					if isFn(c) then local ok, r = pcall(c) if ok then c = r end end
					if not isTbl(c) then return (c == nil) and {} or { toStr(c) } end
					local out = {}
					if #c > 0 or next(c) == nil then
						for _, v in ipairs(c) do table.insert(out, toStr(v)) end
					else
						for _, v in pairs(c) do table.insert(out, toStr(v)) end
						table.sort(out)
					end
					return out
				end
				local function NormDef(d, opts)
					if d == nil then return opts[1] end
					if isTbl(d) then
						if #d == 0 then return opts[1] end
						for _, cand in ipairs(d) do
							for _, o in ipairs(opts) do if o == toStr(cand) then return o end end
						end
						return toStr(d[1])
					end
					if isNum(d) then
						local i = math.floor(d)
						if opts[i] then return opts[i] end
					end
					local s = toStr(d)
					for _, o in ipairs(opts) do if string.lower(o) == string.lower(s) then return o end end
					-- default ไม่ตรง option ใดเลย (เช่น index เกินช่วง) -> ใช้ตัวแรกแทน
					-- ดีกว่าคืน string ดิบที่ไม่มีในลิสต์ (กัน Settings ได้ค่าผิด type)
					if #opts > 0 then return opts[1] end
					return s
				end
				local function BuildDropdown(label, default, choices, callback, locked, desc, saveKey, multi)
					if not isStr(desc) then desc = nil end
					if not isStr(saveKey) then saveKey = nil end
					label = toStr(label or "Dropdown")
					local opts = NormList(choices)
					-- auto-generate saveKey when not provided
					if not saveKey or saveKey == "" then
						saveKey = (Menu.Name or "General") .. "_" .. label:gsub("[^%w%-%_]", "")
					end
					local compType = multi and "MultiDropdown" or "Dropdown"
					local init = multi and {} or NormDef(default, opts)
					-- restore from config if available
					local savedVal = ConfigSystem:Get(saveKey, nil, compType)
					if multi then
						if isTbl(savedVal) then init = savedVal end
					else
						if savedVal ~= nil then init = NormDef(savedVal, opts) end
					end
					local rowH = (desc and desc ~= "") and 62 or 50
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, rowH),
						BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0, LayoutOrder = NextOrder() }, box)
					Corner(row, 5)
					Stroke(row, Window._theme.BorderSoft, 1).Transparency = 0.4
					New("TextLabel", { Position = UDim2.new(0, 9, 0, 3), Size = UDim2.new(1, -18, 0, 15),
						BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					if desc and desc ~= "" then
						New("TextLabel", { Position = UDim2.new(0, 9, 0, 17), Size = UDim2.new(1, -18, 0, 12),
							BackgroundTransparency = 1, Text = toStr(desc), Font = Enum.Font.Gotham, TextSize = 10,
							TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
							TextColor3 = Window._theme.TextMuted }, row)
					end
					local selY = (desc and desc ~= "") and 32 or 20
					local sel = New("TextButton", { Position = UDim2.new(0, 7, 0, selY),
						Size = UDim2.new(1, -14, 0, 24), BackgroundColor3 = Window._theme.Surface2, Text = "",
						LayoutOrder = 10 }, row)
					Corner(sel, 5)
					Stroke(sel, Window._theme.Border, 1)
					local st = New("TextLabel", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -28, 1, 0),
						BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, sel)
					local chev = New("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
						Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 1, Text = "v",
						Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Window._theme.TextMuted }, sel)
					-- แผงติดใต้ dropdown โดยตรง (กางในแถวเดียวกันตามภาพ ไม่ลอย)
					local panelY = selY + 24 + 4
					local popup = New("Frame", { Position = UDim2.new(0, 7, 0, panelY),
						Size = UDim2.new(1, -14, 0, 0), Visible = false,
						BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0,
						ClipsDescendants = true }, row)
					Corner(popup, 5)
					Stroke(popup, Window._theme.Border, 1)
					Pad(popup, 4, 5, 4, 5)
					local search = New("TextBox", { Size = UDim2.new(1, 0, 0, 26),
						BackgroundColor3 = Window._theme.Surface2, PlaceholderText = "Search...",
						Text = "", Font = Enum.Font.Gotham, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Window._theme.Text,
						PlaceholderColor3 = Window._theme.TextDim, ClearTextOnFocus = false }, popup)
					Corner(search, 5)
					Stroke(search, Window._theme.BorderSoft, 1)
					Pad(search, 0, 8, 0, 8)
					local scr = New("ScrollingFrame", { Position = UDim2.new(0, 0, 0, 30),
						Size = UDim2.new(1, 0, 1, -30), BackgroundTransparency = 1,
						ScrollBarThickness = 3, ScrollBarImageColor3 = Window._theme.Border,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, popup)
					List(scr, 3)
					local empty = New("TextLabel", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
						Text = "No results", Font = Enum.Font.Gotham, TextSize = 12,
						TextColor3 = Window._theme.TextDim, Visible = false }, scr)
					local comp = { _window = Window, _row = row, _popup = popup, _options = opts,
						_value = multi and nil or init, _multi = multi and {} or nil,
						_callback = callback, _locked = (locked == true), _saveKey = saveKey,
						_open = false, _pool = {}, _conns = {},
						Type = multi and "MultiDropdown" or "Dropdown" }
					if multi then
						if isTbl(init) then for _, v in ipairs(init) do comp._multi[toStr(v)] = true end
						elseif isStr(init) and init ~= "" then comp._multi[init] = true end
					end
					OnTheme(function(t)
						row.BackgroundColor3 = t.Surface
						sel.BackgroundColor3 = t.Surface2
						popup.BackgroundColor3 = t.Surface
						search.BackgroundColor3 = t.Surface2
					end)
					local function DispText()
						if multi then
							local s = {}
							for k in pairs(comp._multi) do table.insert(s, k) end
							table.sort(s)
							if #s == 0 then return "Select..." end
							local t = table.concat(s, ", ")
							if #t > 30 then return #s .. " selected" end
							return t
						end
						return toStr(comp._value or "Select...")
					end
					local function PaintSel() st.Text = DispText() end
					PaintSel()
					local RefreshPool
					local function Close()
						comp._open = false
						popup.Visible = false
						row.Size = UDim2.new(1, 0, 0, rowH)
						chev.Text = "v"
					end
					local function Open()
						if comp._locked then return end
						comp._open = true
						popup.Visible = true
						chev.Text = "^"
						search.Text = ""
						RefreshPool("")
					end
					-- ปรับแผง+แถวให้สูงพอดีจำนวนผลที่เจอ (เจอกี่คำเหลือแค่นั้น)
					local function FitPopup(shown)
						if not comp._open then return end
						local rows = math.min(shown, 6)
						local rowsH = (shown == 0) and 26 or (rows * 27 + math.max(0, rows - 1) * 3)
						local panelH = rowsH + 38
						popup.Size = UDim2.new(1, -14, 0, panelH)
						row.Size = UDim2.new(1, 0, 0, rowH + 4 + panelH)
					end
					RefreshPool = function(q)
						q = string.lower(toStr(q or ""))
						for _, b in pairs(comp._pool) do b:Destroy() end
						table.clear(comp._pool)
						empty.Visible = false
						local shown = 0
						for i, opt in ipairs(comp._options) do
							if q == "" or string.find(string.lower(opt), q, 1, true) then
								shown = shown + 1
								local ob = New("TextButton", { Size = UDim2.new(1, 0, 0, 27),
									BackgroundColor3 = Window._theme.Surface2, Text = "",
									LayoutOrder = i }, scr)
								Corner(ob, 5)
								local selNow = multi and comp._multi[opt] or (opt == comp._value)
								if selNow then Stroke(ob, Window._theme.Accent, 1)
								else Stroke(ob, Window._theme.BorderSoft, 1) end
								New("TextLabel", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0),
									BackgroundTransparency = 1, Text = opt, Font = Enum.Font.Gotham, TextSize = 12,
									TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
									TextColor3 = Window._theme.Text }, ob)
								comp._pool[opt] = ob
								Track(comp, ob.MouseButton1Click:Connect(function()
									if multi then
										if comp._multi[opt] then comp._multi[opt] = nil else comp._multi[opt] = true end
										local arr = {}
										for k in pairs(comp._multi) do table.insert(arr, k) end
										table.sort(arr)
										PaintSel()
										ConfigSystem:Set(comp._saveKey, arr)
										if isFn(comp._callback) then task.spawn(function() pcall(comp._callback, arr) end) end
										RefreshPool(search.Text)
									else
										comp._value = opt
										PaintSel()
										ConfigSystem:Set(comp._saveKey, opt)
										Close()
										if isFn(comp._callback) then task.spawn(function() pcall(comp._callback, opt) end) end
									end
								end))
							end
						end
						empty.Visible = (shown == 0)
						FitPopup(shown)
					end
					Track(comp, sel.MouseButton1Click:Connect(function()
						if comp._open then Close() else Open() end
					end))
					Track(comp, search:GetPropertyChangedSignal("Text"):Connect(function()
						RefreshPool(search.Text)
					end))
					-- แผงอยู่ในแถวเดียวกันอยู่แล้ว scroll/drag ตามเอง
					-- แตะนอกแถวเพื่อพับเก็บ
					Track(comp, UserInputService.InputBegan:Connect(function(input)
						if not comp._open then return end
						if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
						local rp, rs2 = row.AbsolutePosition, row.AbsoluteSize
						local x, y = input.Position.X, input.Position.Y
						local inRow = (x >= rp.X and x <= rp.X + rs2.X and y >= rp.Y and y <= rp.Y + rs2.Y)
						if not inRow then Close() end
					end))
					comp.GetValue = function()
						if multi then
							local a = {}
							for k in pairs(comp._multi) do table.insert(a, k) end
							table.sort(a)
							return a
						end
						return comp._value
					end
					comp.Get = comp.GetValue
					comp.SetValue = function(a2, b2)
						local v = (b2 ~= nil and b2 or a2)
						if multi then
							table.clear(comp._multi)
							if isTbl(v) then for _, x in ipairs(v) do comp._multi[toStr(x)] = true end
							elseif v ~= nil then comp._multi[toStr(v)] = true end
							PaintSel()
							if isFn(comp._callback) then task.spawn(function() pcall(comp._callback, comp.GetValue()) end) end
						else
							comp._value = NormDef(v, comp._options)
							PaintSel()
							if isFn(comp._callback) then task.spawn(function() pcall(comp._callback, comp._value) end) end
						end
					end
					comp.Update = comp.SetValue
					comp.Set = comp.SetValue
					comp.Refresh = function(a2, b2)
						local v = (b2 ~= nil and b2 or a2)
						if v == comp then return end
						comp._options = NormList(v)
						if not multi and comp._value then
							local keep = false
							for _, o in ipairs(comp._options) do if o == comp._value then keep = true break end end
							if not keep then comp._value = comp._options[1] end
							PaintSel()
						end
						if comp._open then RefreshPool(search.Text) end
					end
					comp.SetOptions = comp.Refresh
					comp.AddOption = function(a2, b2)
						local v = toStr(b2 ~= nil and b2 or a2)
						if v == "" then return end
						for _, o in ipairs(comp._options) do if o == v then return end end
						table.insert(comp._options, v)
						if comp._open then RefreshPool(search.Text) end
					end
					comp.RemoveOption = function(a2, b2)
						local v = toStr(b2 ~= nil and b2 or a2)
						for i, o in ipairs(comp._options) do
							if o == v then table.remove(comp._options, i) break end
						end
						if multi then comp._multi[v] = nil
						elseif comp._value == v then comp._value = comp._options[1] PaintSel() end
						if comp._open then RefreshPool(search.Text) end
					end
					comp.Clear = function()
						table.clear(comp._options)
						if multi then table.clear(comp._multi) else comp._value = nil end
						PaintSel()
						if comp._open then RefreshPool(search.Text) end
					end
					comp.Destroy = function() DisconnectAll(comp) pcall(function() row:Destroy() end) pcall(function() popup:Destroy() end) end
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.addDropdown = function(...)
					local a = Pack(Menu, ...)
					return BuildDropdown(a[1], a[2], a[3], a[4], a[5], a[6], a[7], false)
				end
				Menu.AddDropdown, Menu.CreateDropdown, Menu.adddropdown = Menu.addDropdown, Menu.addDropdown, Menu.addDropdown
				Menu.addMultiDropdown = function(...)
					local a = Pack(Menu, ...)
					return BuildDropdown(a[1], a[2], a[3], a[4], a[5], a[6], a[7], true)
				end
				Menu.AddMultiDropdown, Menu.CreateMultiDropdown = Menu.addMultiDropdown, Menu.addMultiDropdown
				Menu.addMultidropdown, Menu.addmultiDropdown = Menu.addMultiDropdown, Menu.addMultiDropdown

				-- ---- Textbox (คีย์บอร์ดมือถือ) ----
				Menu.addTextbox = function(...)
					local a = Pack(Menu, ...)
					local label = toStr(a[1] or "Textbox")
					local cb, confirmText, saveKey, def = nil, nil, nil, ""
					-- MainScript: (label, callback, confirmText, saveKey, default)
					if isFn(a[2]) then
						cb, confirmText = a[2], (isStr(a[3]) and a[3] or nil)
						if isStr(a[4]) and not a[4]:find(" ") then saveKey = a[4]
						elseif isStr(a[4]) then confirmText = a[4] end
						if a[5] ~= nil then def = toStr(a[5]) end
					else
						for i = 2, a.n do
							local v = a[i]
							if isFn(v) and cb == nil then cb = v
							elseif isStr(v) and def == "" then def = v end
						end
					end
					if not saveKey or saveKey == "" then
						saveKey = (Menu.Name or "General") .. "_" .. label:gsub("[^%w%-%_]", "")
					end
					local savedDef = ConfigSystem:Get(saveKey, nil, "Textbox")
					if savedDef ~= nil then def = toStr(savedDef) end
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, 50),
						BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0, LayoutOrder = NextOrder() }, box)
					Corner(row, 5)
					Stroke(row, Window._theme.BorderSoft, 1).Transparency = 0.4
					New("TextLabel", { Position = UDim2.new(0, 9, 0, 3), Size = UDim2.new(1, -18, 0, 15),
						BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					local tb = New("TextBox", { Position = UDim2.new(0, 7, 0, 20), Size = UDim2.new(1, -14, 0, 24),
						BackgroundColor3 = Window._theme.Surface2, Text = def,
						PlaceholderText = confirmText or ("Enter " .. label .. "..."),
						Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = Window._theme.Text, PlaceholderColor3 = Window._theme.TextDim,
						ClearTextOnFocus = false }, row)
					Corner(tb, 5)
					Stroke(tb, Window._theme.Border, 1)
					Pad(tb, 0, 8, 0, 8)
					local comp = { _window = Window, _row = row, _box = tb, _value = def,
						_callback = cb, _saveKey = saveKey, _conns = {}, Type = "Textbox" }
					OnTheme(function(t)
						row.BackgroundColor3 = t.Surface
						tb.BackgroundColor3 = t.Surface2
						tb.TextColor3 = t.Text
					end)
					local function Apply(v, fire)
						comp._value = toStr(v or "")
						if tb.Text ~= comp._value then tb.Text = comp._value end
						ConfigSystem:Set(comp._saveKey, comp._value)
						if fire ~= false and isFn(comp._callback) then
							task.spawn(function() pcall(comp._callback, comp._value) end)
						end
					end
					comp.GetValue = function() return comp._value end
					comp.Get = comp.GetValue
					comp.SetValue = function(a2, b2) Apply((b2 ~= nil and b2 or a2), true) end
					comp.Update = comp.SetValue
					comp.Destroy = function() DisconnectAll(comp) pcall(function() row:Destroy() end) end
					Track(comp, tb.FocusLost:Connect(function(enter)
						if enter then Apply(tb.Text, true) else Apply(tb.Text, true) end
					end))
					ConfigSystem:Register(comp._saveKey, comp)
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddTextbox, Menu.CreateTextbox, Menu.addtextbox = Menu.addTextbox, Menu.addTextbox, Menu.addTextbox
				Menu.addTextBox, Menu.AddTextBox = Menu.addTextbox, Menu.addTextbox

				-- ---- Label / Paragraph ----
				Menu.addLabel = function(...)
					local a = Pack(Menu, ...)
					local titleT, descT = toStr(a[1] or "Label"), toStr(a[2] or "")
					if isTbl(a[1]) then
						local t = a[1]
						titleT = toStr(t.Title or t.title or t.Text or titleT)
						descT = toStr(t.Description or t.description or t.Desc or "")
					end
					local h = (descT ~= "") and 40 or 26
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, h),
						BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0, LayoutOrder = NextOrder() }, box)
					Corner(row, 5)
					Stroke(row, Window._theme.BorderSoft, 1).Transparency = 0.55
					local t1 = New("TextLabel", { Position = UDim2.new(0, 9, 0, 3), Size = UDim2.new(1, -18, 0, 15),
						BackgroundTransparency = 1, Text = titleT, Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					local t2 = New("TextLabel", { Position = UDim2.new(0, 9, 0, 18), Size = UDim2.new(1, -18, 0, 16),
						BackgroundTransparency = 1, Text = descT, Font = Enum.Font.Gotham, TextSize = 11,
						RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.TextMuted, Visible = (descT ~= "") }, row)
					OnTheme(function(t)
						row.BackgroundColor3 = t.Surface
						t1.TextColor3 = t.Text
						t2.TextColor3 = t.TextMuted
					end)
					local comp = { _window = Window, _row = row, _conns = {}, Type = "Label" }
					comp.RefreshDesc = function(a2, b2)
						local v = toStr(b2 ~= nil and b2 or a2)
						t2.Text, t2.Visible = v, true
						row.Size = UDim2.new(1, 0, 0, 40)
					end
					comp.RefreshTitle = function(a2, b2)
						t1.Text = toStr(b2 ~= nil and b2 or a2)
					end
					comp.SetDescription, comp.SetTitle, comp.Refresh = comp.RefreshDesc, comp.RefreshTitle, comp.RefreshDesc
					comp.GetValue = function() return t2.Text end
					comp.Destroy = function() DisconnectAll(comp) pcall(function() row:Destroy() end) end
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddLabel, Menu.CreateLabel, Menu.addlabel = Menu.addLabel, Menu.addLabel, Menu.addLabel
				Menu.addParagraph = function(...)
					local a = Pack(Menu, ...)
					local c = Menu.addLabel(a[1], a[2])
					c.Type = "Paragraph"
					pcall(function()
						local r = c._row
						r.Size = UDim2.new(1, 0, 0, 0)
						r.AutomaticSize = Enum.AutomaticSize.Y
					end)
					return c
				end
				Menu.AddParagraph, Menu.CreateParagraph = Menu.addParagraph, Menu.addParagraph

				-- ---- Keybind ----
				Menu.addKeybind = function(...)
					local a = Pack(Menu, ...)
					local label = toStr(a[1] or "Keybind")
					local def, cb, saveKey = "F", nil, nil
					for i = 2, a.n do
						local v = a[i]
						if isFn(v) and cb == nil then cb = v
						elseif isStr(v) and #v <= 12 and def == "F" then def = v
						elseif isStr(v) and saveKey == nil and not v:find(" ") then saveKey = v end
					end
					if not saveKey or saveKey == "" then
						saveKey = (Menu.Name or "General") .. "_" .. label:gsub("[^%w%-%_]", "")
					end
					local savedKB = ConfigSystem:Get(saveKey, nil, "Keybind")
					if isStr(savedKB) and savedKB ~= "" then def = savedKB end
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, 32),
						BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0, LayoutOrder = NextOrder() }, box)
					Corner(row, 5)
					Stroke(row, Window._theme.BorderSoft, 1).Transparency = 0.4
					New("TextLabel", { Position = UDim2.new(0, 9, 0, 0), Size = UDim2.new(1, -90, 1, 0),
						BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					local keyBtn = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.new(0, 66, 0, 24),
						BackgroundColor3 = Window._theme.Surface2, Text = "[" .. toStr(def) .. "]",
						Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Window._theme.Text }, row)
					Corner(keyBtn, 5)
					Stroke(keyBtn, Window._theme.Border, 1)
					local comp = { _window = Window, _row = row, _value = toStr(def), _callback = cb,
						_saveKey = saveKey, _conns = {}, _binding = false, Type = "Keybind" }
					local function SetKey(name, fire)
						comp._value = toStr(name)
						keyBtn.Text = "[" .. comp._value .. "]"
						ConfigSystem:Set(comp._saveKey, comp._value)
						if fire and isFn(comp._callback) then
							task.spawn(function() pcall(comp._callback, comp._value) end)
						end
					end
					comp.GetValue = function() return comp._value end
					comp.SetValue = function(a2, b2) SetKey((b2 ~= nil and b2 or a2), true) end
					comp.Update = comp.SetValue
					comp.Destroy = function() DisconnectAll(comp) pcall(function() row:Destroy() end) end
					Track(comp, keyBtn.MouseButton1Click:Connect(function()
						comp._binding = true
						keyBtn.Text = "[...]"
					end))
					Track(comp, UserInputService.InputBegan:Connect(function(input, gpe)
						if comp._binding and input.UserInputType == Enum.UserInputType.Keyboard then
							comp._binding = false
							if input.KeyCode ~= Enum.KeyCode.Unknown then
								SetKey(input.KeyCode.Name, true)
							else
								keyBtn.Text = "[" .. comp._value .. "]"
							end
						elseif not comp._binding and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
							if input.KeyCode.Name == comp._value and isFn(comp._callback) then
								task.spawn(function() pcall(comp._callback, comp._value) end)
							end
						end
					end))
					ConfigSystem:Register(comp._saveKey, comp)
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddKeybind, Menu.CreateKeybind, Menu.addkeybind = Menu.addKeybind, Menu.addKeybind, Menu.addKeybind
				Menu.addBind, Menu.AddBind = Menu.addKeybind, Menu.addKeybind

				-- ---- Colorpicker (compact + RGB textboxes) ----
				Menu.addColorpicker = function(...)
					local a = Pack(Menu, ...)
					local label = toStr(a[1] or "Color")
					local def, cb, locked, saveKey = Color3.fromRGB(139, 92, 246), nil, false, nil
					for i = 2, a.n do
						local v = a[i]
						if typeof(v) == "Color3" then def = v
						elseif isStr(v) and v:match("^#%x%x%x%x%x%x$") then
							def = Color3.fromRGB(tonumber(v:sub(2, 3), 16), tonumber(v:sub(4, 5), 16), tonumber(v:sub(6, 7), 16))
						elseif isFn(v) and cb == nil then cb = v
						elseif type(v) == "boolean" and v == true then locked = true
						elseif isStr(v) and saveKey == nil and not v:find(" ") then saveKey = v end
					end
					if not saveKey or saveKey == "" then
						saveKey = (Menu.Name or "General") .. "_" .. label:gsub("[^%w%-%_]", "")
					end
					local savedCP = ConfigSystem:Get(saveKey, nil, "Colorpicker")
					if typeof(savedCP) == "Color3" then def = savedCP end
					local row = New("Frame", { Size = UDim2.new(1, 0, 0, 32),
						BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0, LayoutOrder = NextOrder() }, box)
					Corner(row, 5)
					Stroke(row, Window._theme.BorderSoft, 1).Transparency = 0.4
					New("TextLabel", { Position = UDim2.new(0, 9, 0, 0), Size = UDim2.new(1, -70, 1, 0),
						BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamBold, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = Window._theme.Text }, row)
					local prev = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.new(0, 48, 0, 22),
						BackgroundColor3 = def, Text = "" }, row)
					Corner(prev, 5)
					Stroke(prev, Window._theme.Border, 1)
				local comp = { _window = Window, _row = row, _value = def, _callback = cb,
					_locked = locked, _saveKey = saveKey, _conns = {}, _open = false, Type = "Colorpicker" }
				-- แผงกางในแถว (ไม่ใช้ popup): จาน SV + Hue + hex + OK
				local PANEL_H = 164
				local h, s, v = Color3.toHSV(def)
				local panel = New("Frame", { Position = UDim2.new(0, 7, 0, 36),
					Size = UDim2.new(1, -14, 0, PANEL_H), Visible = false,
					BackgroundColor3 = Window._theme.Surface, BorderSizePixel = 0,
					ClipsDescendants = true }, row)
				Corner(panel, 5)
				local panelStroke = Stroke(panel, Window._theme.Border, 1)
				Pad(panel, 5, 6, 5, 6)
				local svBox, svDot, hueBar, hueDot, hex, okBtn
				local function CurColor() return Color3.fromHSV(h, s, v) end
				local function commit(fire)
					local c = CurColor()
					comp._value = c
					prev.BackgroundColor3 = c
					ConfigSystem:Set(comp._saveKey, c)
					if fire ~= false and isFn(comp._callback) then
						task.spawn(function() pcall(comp._callback, c) end)
					end
				end
				local function render()
					local c = CurColor()
					prev.BackgroundColor3 = c
					svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					svDot.Position = UDim2.new(s, 0, 1 - v, 0)
					hueDot.Position = UDim2.new(h, 0, 0.5, 0)
					if hex and not hex:IsFocused() then
						local r = math.floor(c.R * 255 + 0.5)
						local g = math.floor(c.G * 255 + 0.5)
						local b = math.floor(c.B * 255 + 0.5)
						hex.Text = string.format("#%02X%02X%02X", r, g, b)
					end
				end
				local function Apply(c, fire)
					if typeof(c) ~= "Color3" then return end
					h, s, v = Color3.toHSV(c)
					render()
					commit(fire)
				end
				local function Close()
					if not comp._open then return end
					comp._open = false
					panel.Visible = false
					row.Size = UDim2.new(1, 0, 0, 32)
				end
				do
					-- จาน SV: base สี hue + ไล่ขาว(ซ้าย) + ไล่ดำ(ล่าง)
					svBox = New("Frame", { Size = UDim2.new(1, 0, 0, 106),
						BackgroundColor3 = Color3.fromHSV(h, 1, 1),
						BorderSizePixel = 0, ClipsDescendants = true }, panel)
					Corner(svBox, 5)
					Stroke(svBox, Window._theme.Border, 1)
					svBase = svBox
					local satLyr = New("Frame", { Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, svBox)
					local satG = New("UIGradient", { Rotation = 90 }, satLyr)
					satG.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
					local valLyr = New("Frame", { Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0 }, svBox)
					local valG = New("UIGradient", { Rotation = 0 }, valLyr)
					valG.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					})
					svDot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0, ZIndex = 3 }, svBox)
					Corner(svDot, 6)
					Stroke(svDot, Color3.fromRGB(0, 0, 0), 2)
					-- แถบ Hue สายรุ้ง
					hueBar = New("Frame", { Position = UDim2.new(0, 0, 0, 110),
						Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0, ClipsDescendants = true }, panel)
					Corner(hueBar, 4)
					Stroke(hueBar, Window._theme.Border, 1)
					local hueG = New("UIGradient", { Rotation = 90 }, hueBar)
					hueG.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
						ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
						ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
						ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
						ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
					})
					hueDot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0, 5, 0, 18), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0, ZIndex = 3 }, hueBar)
					Corner(hueDot, 2)
					Stroke(hueDot, Color3.fromRGB(0, 0, 0), 1)
					hex = New("TextBox", { Position = UDim2.new(0, 0, 0, 128),
						Size = UDim2.new(1, -88, 0, 26), BackgroundColor3 = Window._theme.Surface2,
						Text = "", PlaceholderText = "#RRGGBB", Font = Enum.Font.Gotham, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Window._theme.Text,
						PlaceholderColor3 = Window._theme.TextDim, ClearTextOnFocus = false }, panel)
					Corner(hex, 5)
					Stroke(hex, Window._theme.BorderSoft, 1)
					Pad(hex, 0, 8, 0, 8)
					Track(comp, hex.FocusLost:Connect(function(enter)
						if not enter then render() return end
						local t = toStr(hex.Text):gsub("%s+", ""):gsub("^#", "")
						if #t == 6 and t:match("^%x+$") then
							Apply(Color3.fromRGB(tonumber(t:sub(1, 2), 16),
								tonumber(t:sub(3, 4), 16), tonumber(t:sub(5, 6), 16)), true)
						else
							render()
						end
					end))
					okBtn = New("TextButton", { AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, 0, 0, 128), Size = UDim2.new(0, 80, 0, 26),
						BackgroundColor3 = Window._theme.Accent,
						Text = "OK", Font = Enum.Font.GothamBold, TextSize = 13,
						TextColor3 = Color3.fromRGB(255, 255, 255) }, panel)
					Corner(okBtn, 5)
					OnTheme(function(t)
						panel.BackgroundColor3 = t.Surface
						panelStroke.Color = t.Border
						hex.BackgroundColor3 = t.Surface2
						hex.TextColor3 = t.Text
						okBtn.BackgroundColor3 = t.Accent
					end)
					-- ลากบนจาน SV
					local dragSV = false
					local function fromSV(x, y)
						s = clamp((x - svBox.AbsolutePosition.X) / math.max(1, svBox.AbsoluteSize.X), 0, 1)
						v = 1 - clamp((y - svBox.AbsolutePosition.Y) / math.max(1, svBox.AbsoluteSize.Y), 0, 1)
						render()
						commit(true)
					end
					Track(comp, svBox.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragSV = true
							fromSV(input.Position.X, input.Position.Y)
						end
					end))
					-- ลากบนแถบ Hue
					local dragH = false
					local function fromHue(x)
						h = clamp((x - hueBar.AbsolutePosition.X) / math.max(1, hueBar.AbsoluteSize.X), 0, 0.999)
						render()
						commit(true)
					end
					Track(comp, hueBar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragH = true
							fromHue(input.Position.X)
						end
					end))
					Track(comp, UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
						if dragSV then fromSV(input.Position.X, input.Position.Y)
						elseif dragH then fromHue(input.Position.X) end
					end))
					Track(comp, UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragSV, dragH = false, false
						end
					end))
					Track(comp, okBtn.MouseButton1Click:Connect(function() Close() end))
				end
				render()
				comp.GetValue = function() return comp._value end
				comp.Collapse = function() Close() end
				comp.ClosePicker = function() Close() end
				comp.IsOpen = function() return comp._open end
				comp.SetValue = function(a2, b2)
					local v = (b2 ~= nil and b2 or a2)
					if typeof(v) == "Color3" then Apply(v, true)
					elseif isTbl(v) and #v == 3 then Apply(Color3.fromRGB(v[1], v[2], v[3]), true)
					elseif isStr(v) then
						local t = v:gsub("%s+", ""):gsub("^#", "")
						if #t == 6 and t:match("^%x+$") then
							Apply(Color3.fromRGB(tonumber(t:sub(1, 2), 16), tonumber(t:sub(3, 4), 16), tonumber(t:sub(5, 6), 16)), true)
						end
					end
				end
				comp.Update = comp.SetValue
				comp.Destroy = function()
					DisconnectAll(comp)
					pcall(function() row:Destroy() end)
				end
				Track(comp, prev.MouseButton1Click:Connect(function()
					if comp._locked then return end
					if comp._open then Close() return end
					-- เปิดตัวนี้ พับตัวอื่นก่อน (ไม่มี popup ซ้อนกัน)
					for _, ch in ipairs(Window._children or {}) do
						pcall(function()
							if isTbl(ch) and ch ~= comp and ch.Type == "Colorpicker" and ch._open and isFn(ch.Collapse) then
								ch.Collapse()
							end
						end)
					end
					h, s, v = Color3.toHSV(comp._value)
					render()
					panel.Visible = true
					row.Size = UDim2.new(1, 0, 0, 32 + 4 + PANEL_H)
					comp._open = true
				end))
					ConfigSystem:Register(comp._saveKey, comp)
					AddChild(Menu, comp)
					AddChild(Window, comp)
					return comp
				end
				Menu.AddColorpicker, Menu.CreateColorpicker, Menu.addcolorpicker = Menu.addColorpicker, Menu.addColorpicker, Menu.addColorpicker
				Menu.addColorPicker, Menu.AddColorPicker, Menu.addColourpicker = Menu.addColorpicker, Menu.addColorpicker, Menu.addColorpicker

				return Menu
			end
			Section.AddMenu, Section.CreateMenu, Section.addmenu = Section.addMenu, Section.addMenu, Section.addMenu
			AddChild(Tab, Section)
			AddChild(Window, Section)
			return Section
		end
		Tab.AddSection, Tab.CreateSection, Tab.addsection = Tab.addSection, Tab.addSection, Tab.addSection
		table.insert(Window._tabs, Tab)
		AddChild(Window, Tab)
		-- เลือกหน้า Home เท่านั้น (หรือ tab แรกที่ไม่ใช่ Settings/Config)
		if tostring(name):lower() == "home" then
			task.defer(function() pcall(function() Tab:Select() end) end)
		elseif #Window._tabs == 1 and not isConfig then
			task.defer(function() pcall(function() Tab:Select() end) end)
		end
		return Tab
	end
	Window.AddTab, Window.addTab = Window.AddTab, Window.AddTab
	Window.CreateTab = Window.CreateTab

	-- ---- Tab Settings แยกด้านล่างซ้าย (auto) ----
	local function BuildConfigTab()
		local cfgTab = Window:CreateTab("Settings", "misc-oxiasidian")
		local m1 = cfgTab:addSection():addMenu("Appearance")
		local thDD = m1:addDropdown("Theme", Window._themeName,
			ThemeSystem.List and ThemeSystem.List() or { "Purple", "Midnight", "Dark", "Crimson" },
			function(n)
				Window:SetTheme(n)
				ConfigSystem:Set("UITheme", n)
			end, nil, nil, "UITheme")
		thDD.Type = "ThemePicker"

		local cfgMenu = cfgTab:addSection():addMenu("Config Manager")
		cfgMenu:addLabel("UI Config (Theme/Hotkey)", ConfigSystem:Path())
		cfgMenu:addLabel("Settings Config", PlayerConfig:Path())
		cfgMenu:addLabel("Auto-Save Status", "Active (Instant Auto-Save)")
		cfgMenu:addButton("Save Now (Manual Backup)", function()
			ConfigSystem:Flush()
			PlayerConfig:Flush()
			Window:Notify({ Title = "Config", Description = "Configs flushed to disk" })
		end)
		cfgMenu:addButton("Reset UI Config", function()
			ConfigSystem:Reset()
			Window:Notify({ Title = "Config", Description = "UI Config has been reset" })
		end)
		cfgMenu:addButton("Reset Settings Config", function()
			PlayerConfig:Reset()
			Window:Notify({ Title = "Config", Description = "Settings Config has been reset" })
		end)

		local hk = cfgTab:addSection():addMenu("Hotkey")
		hk:addKeybind("Toggle UI Key", "RightShift", function()
			Window:Toggle()
		end, nil, "UIToggleKey")
		hk:addButton("Stop All Functions", function()
			if isFn(Window._onStopAll) then
				pcall(Window._onStopAll)
				Window:Notify({ Title = "Oxiasidian", Description = "All functions stopped" })
			end
		end)
		hk:addButton("Re-open window", function()
			Window:Notify({ Title = "Config", Description = "กำลังโหลดและอัปเดต Config ใหม่ทั้งหมด..." })
			local ok, count = Window:ReloadConfig()
			Window:Notify({
				Title = "Config Updated",
				Description = "อัปเดต Config เรียบร้อยแล้ว (" .. tostring(count or 0) .. " รายการ)",
			})
			pcall(function() Window:Open() end)
		end)
		return cfgTab
	end
	Window._configTab = BuildConfigTab()
	Window._settingsTab = Window._configTab

	-- ======================= 11. Cleanup =====================================
	function Window:Destroy(...)
		local stop = self._onStopAll
		if isFn(stop) then pcall(stop) end
		-- flush pending config saves before GUI is gone
		pcall(function() ConfigSystem:Flush() end)
		pcall(function() PlayerConfig:Flush() end)
		for _, t in ipairs(self._tabs) do DisconnectAll(t) end
		DisconnectAll(self)
		pcall(function() self._gui:Destroy() end)
		table.clear(self._tabs)
		if Library._lastWindow == self then Library._lastWindow = nil end
	end
	Window.Close2 = Window.Close
	Window.Remove = Window.Destroy
	Window.Delete = Window.Destroy

	return Window
end
Library.CreateWindow, Library.createWindow, Library.NewWindow =
	Library.CreateWindow, Library.CreateWindow, Library.CreateWindow

-- จำตัวเองลง getgenv ทุกครั้งที่ไฟล์นี้ถูกรัน (รัน lib ก่อน 1 ครั้ง
-- แล้วสคริปต์อื่น/EXAMPLE ที่รันทีหลังจะเจอผ่าน getgenv().QuantumOnyxGUI ทันที)
pcall(function()
	if getgenv then getgenv().QuantumOnyxGUI = Library end
end)

return Library
