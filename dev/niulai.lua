
local GUI_VERSION = "2.0.0 Pro"

local function BuildQuantumGUI()

	----------------------------------------------------------------- services
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local TextService = game:GetService("TextService")

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	-- Safe GUI container (CoreGui / gethui if executor available, fallback to PlayerGui)
	local function getSafeGuiParent()
		local parent = nil
		pcall(function()
			if type(gethui) == "function" then
				parent = gethui()
			elseif type(syn) == "table" and type(syn.protect_gui) == "function" then
				local pg = Instance.new("Folder")
				syn.protect_gui(pg)
				pg.Parent = game:GetService("CoreGui")
				parent = pg
			else
				parent = game:GetService("CoreGui")
			end
		end)
		return parent or playerGui
	end

	------------------------------------------------------------------ helpers
	local function make(className, props)
		local object = Instance.new(className)
		if type(props) == "table" then
			for key, value in pairs(props) do
				if key ~= "Parent" then
					object[key] = value
				end
			end
			if props.Parent then
				object.Parent = props.Parent
			end
		end
		return object
	end

	local function corner(object, radius)
		return make("UICorner", {
			CornerRadius = UDim.new(0, radius or 8),
			Parent = object,
		})
	end

	local function outline(object, color, thickness, transparency)
		return make("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = color or Color3.new(1, 1, 1),
			Thickness = thickness or 1,
			Transparency = transparency or 0.5,
			Parent = object,
		})
	end

	local function inset(object, left, top, right, bottom)
		return make("UIPadding", {
			PaddingLeft = UDim.new(0, left or 0),
			PaddingTop = UDim.new(0, top or 0),
			PaddingRight = UDim.new(0, right or 0),
			PaddingBottom = UDim.new(0, bottom or 0),
			Parent = object,
		})
	end

	local function shade(object, fromColor, toColor, rotation)
		return make("UIGradient", {
			Color = ColorSequence.new(fromColor or Color3.new(1, 1, 1), toColor or fromColor or Color3.new(1, 1, 1)),
			Rotation = rotation or 0,
			Parent = object,
		})
	end

	local function tween(object, props, duration, style, direction)
		local cleanProps = {}
		for k, v in pairs(props or {}) do
			if typeof(v) ~= "EnumItem" and type(v) ~= "boolean" and type(v) ~= "string" then
				cleanProps[k] = v
			else
				pcall(function() object[k] = v end)
			end
		end
		local ok, anim = pcall(function()
			return TweenService:Create(
				object,
				TweenInfo.new(duration or 0.22, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
				cleanProps
			)
		end)
		if ok and anim then
			anim:Play()
			return anim
		end
		local dummy = {}
		dummy.Completed = {
			Connect = function(_, cb)
				task.defer(cb)
				return { Disconnect = function() end }
			end,
		}
		function dummy:Cancel() end
		function dummy:Play() end
		return dummy
	end

	local function formatNumber(value)
		local text = tostring(math.floor(tonumber(value) or 0))
		while true do
			local replaced, count = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
			text = replaced
			if count == 0 then
				break
			end
		end
		return text
	end

	local function formatTime(seconds)
		seconds = math.max(0, math.floor(tonumber(seconds) or 0))
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		local s = seconds % 60
		if h > 0 then
			return string.format("%02d:%02d:%02d", h, m, s)
		else
			return string.format("%02d:%02d", m, s)
		end
	end

	------------------------------------------------------------------- themes
	local THEMES = {
		Purple = {
			Name = "Purple",
			Main = Color3.fromRGB(11, 9, 20),
			Sidebar = Color3.fromRGB(15, 12, 28),
			Topbar = Color3.fromRGB(18, 14, 34),
			Panel = Color3.fromRGB(22, 17, 40),
			Card = Color3.fromRGB(28, 22, 52),
			CardHover = Color3.fromRGB(40, 32, 72),
			Track = Color3.fromRGB(36, 28, 64),
			Border = Color3.fromRGB(64, 50, 105),
			BorderActive = Color3.fromRGB(150, 96, 255),
			Text = Color3.fromRGB(245, 243, 255),
			Sub = Color3.fromRGB(165, 155, 200),
			Accent = Color3.fromRGB(150, 96, 255),
			Accent2 = Color3.fromRGB(216, 122, 255),
			Success = Color3.fromRGB(46, 213, 115),
			Danger = Color3.fromRGB(255, 71, 87),
			Warning = Color3.fromRGB(255, 171, 0),
		},
		Ocean = {
			Name = "Ocean",
			Main = Color3.fromRGB(7, 13, 22),
			Sidebar = Color3.fromRGB(10, 18, 30),
			Topbar = Color3.fromRGB(13, 23, 38),
			Panel = Color3.fromRGB(16, 28, 46),
			Card = Color3.fromRGB(22, 38, 62),
			CardHover = Color3.fromRGB(32, 54, 88),
			Track = Color3.fromRGB(26, 46, 74),
			Border = Color3.fromRGB(44, 78, 120),
			BorderActive = Color3.fromRGB(30, 160, 255),
			Text = Color3.fromRGB(235, 248, 255),
			Sub = Color3.fromRGB(145, 178, 204),
			Accent = Color3.fromRGB(30, 160, 255),
			Accent2 = Color3.fromRGB(0, 225, 255),
			Success = Color3.fromRGB(46, 213, 115),
			Danger = Color3.fromRGB(255, 71, 87),
			Warning = Color3.fromRGB(255, 171, 0),
		},
		Crimson = {
			Name = "Crimson",
			Main = Color3.fromRGB(16, 8, 11),
			Sidebar = Color3.fromRGB(22, 11, 15),
			Topbar = Color3.fromRGB(28, 14, 19),
			Panel = Color3.fromRGB(36, 17, 24),
			Card = Color3.fromRGB(48, 22, 32),
			CardHover = Color3.fromRGB(68, 30, 44),
			Track = Color3.fromRGB(56, 25, 37),
			Border = Color3.fromRGB(96, 38, 56),
			BorderActive = Color3.fromRGB(255, 51, 85),
			Text = Color3.fromRGB(255, 238, 242),
			Sub = Color3.fromRGB(204, 153, 166),
			Accent = Color3.fromRGB(255, 51, 85),
			Accent2 = Color3.fromRGB(255, 115, 140),
			Success = Color3.fromRGB(46, 213, 115),
			Danger = Color3.fromRGB(255, 71, 87),
			Warning = Color3.fromRGB(255, 171, 0),
		},
		Emerald = {
			Name = "Emerald",
			Main = Color3.fromRGB(7, 16, 12),
			Sidebar = Color3.fromRGB(10, 23, 17),
			Topbar = Color3.fromRGB(13, 29, 21),
			Panel = Color3.fromRGB(17, 37, 27),
			Card = Color3.fromRGB(23, 52, 38),
			CardHover = Color3.fromRGB(33, 72, 53),
			Track = Color3.fromRGB(28, 62, 45),
			Border = Color3.fromRGB(46, 102, 75),
			BorderActive = Color3.fromRGB(0, 230, 118),
			Text = Color3.fromRGB(235, 255, 245),
			Sub = Color3.fromRGB(145, 204, 175),
			Accent = Color3.fromRGB(0, 230, 118),
			Accent2 = Color3.fromRGB(105, 255, 174),
			Success = Color3.fromRGB(46, 213, 115),
			Danger = Color3.fromRGB(255, 71, 87),
			Warning = Color3.fromRGB(255, 171, 0),
		},
		Midnight = {
			Name = "Midnight",
			Main = Color3.fromRGB(10, 11, 14),
			Sidebar = Color3.fromRGB(14, 15, 20),
			Topbar = Color3.fromRGB(18, 19, 26),
			Panel = Color3.fromRGB(23, 25, 34),
			Card = Color3.fromRGB(30, 33, 44),
			CardHover = Color3.fromRGB(44, 48, 64),
			Track = Color3.fromRGB(36, 39, 52),
			Border = Color3.fromRGB(60, 65, 86),
			BorderActive = Color3.fromRGB(224, 230, 237),
			Text = Color3.fromRGB(240, 244, 250),
			Sub = Color3.fromRGB(158, 168, 188),
			Accent = Color3.fromRGB(224, 230, 237),
			Accent2 = Color3.fromRGB(136, 146, 176),
			Success = Color3.fromRGB(46, 213, 115),
			Danger = Color3.fromRGB(255, 71, 87),
			Warning = Color3.fromRGB(255, 171, 0),
		},
		Cyberpunk = {
			Name = "Cyberpunk",
			Main = Color3.fromRGB(12, 10, 22),
			Sidebar = Color3.fromRGB(17, 14, 30),
			Topbar = Color3.fromRGB(21, 17, 38),
			Panel = Color3.fromRGB(27, 21, 48),
			Card = Color3.fromRGB(36, 28, 62),
			CardHover = Color3.fromRGB(52, 40, 88),
			Track = Color3.fromRGB(42, 32, 72),
			Border = Color3.fromRGB(78, 56, 126),
			BorderActive = Color3.fromRGB(255, 230, 0),
			Text = Color3.fromRGB(255, 255, 255),
			Sub = Color3.fromRGB(185, 170, 225),
			Accent = Color3.fromRGB(255, 230, 0),
			Accent2 = Color3.fromRGB(255, 0, 128),
			Success = Color3.fromRGB(0, 255, 170),
			Danger = Color3.fromRGB(255, 0, 60),
			Warning = Color3.fromRGB(255, 171, 0),
		},
	}

	local THEME_ORDER = { "Purple", "Ocean", "Crimson", "Emerald", "Midnight", "Cyberpunk" }

	------------------------------------------------------------------- icons
	local ICON_ASSETS = {
		["home"] = "rbxassetid://10723407389",
		["home-quantum"] = "rbxassetid://10723407389",
		["swords"] = "rbxassetid://10734975692",
		["swords-quantum"] = "rbxassetid://10734975692",
		["ship"] = "rbxassetid://10709752906",
		["ship-quantum"] = "rbxassetid://10709752906",
		["user"] = "rbxassetid://10747373176",
		["user-quantum"] = "rbxassetid://10747373176",
		["visual"] = "rbxassetid://10723346959",
		["visual-quantum"] = "rbxassetid://10723346959",
		["raid"] = "rbxassetid://10734950309",
		["raid-quantum"] = "rbxassetid://10734950309",
		["rabbit"] = "rbxassetid://10734975486",
		["rabbit-quantum"] = "rbxassetid://10734975486",
		["map"] = "rbxassetid://10723345518",
		["map-quantum"] = "rbxassetid://10723345518",
		["cart"] = "rbxassetid://10709798547",
		["cart-quantum"] = "rbxassetid://10709798547",
		["misc"] = "rbxassetid://10734950020",
		["misc-quantum"] = "rbxassetid://10734950020",
		["cat"] = "rbxassetid://10709751939",
		["cat-quantum"] = "rbxassetid://10709751939",
		["search"] = "rbxassetid://10734943902",
		["settings"] = "rbxassetid://10734950020",
		["bell"] = "rbxassetid://10709751939",
		["stop"] = "rbxassetid://10747362393",
		["palette"] = "rbxassetid://10734923549",
		["info"] = "rbxassetid://10723415903",
		["minimize"] = "rbxassetid://10734896206",
		["close"] = "rbxassetid://10747384394",
		["chevron-down"] = "rbxassetid://10709790948",
		["chevron-right"] = "rbxassetid://10709791437",
		["check"] = "rbxassetid://10709790644",
	}

	local GLYPH_FALLBACKS = {
		["home"] = "H",
		["swords"] = "S",
		["ship"] = "O",
		["user"] = "P",
		["visual"] = "V",
		["raid"] = "D",
		["rabbit"] = "T",
		["map"] = "M",
		["cart"] = "C",
		["misc"] = "*",
		["cat"] = "W",
	}

	local function makeIcon(parent, iconNameOrId, size, color)
		local isAsset = false
		local assetId = ""
		if type(iconNameOrId) == "string" then
			if iconNameOrId:find("rbxassetid://") or iconNameOrId:find("http") then
				isAsset = true
				assetId = iconNameOrId
			elseif ICON_ASSETS[iconNameOrId:lower()] then
				isAsset = true
				assetId = ICON_ASSETS[iconNameOrId:lower()]
			elseif tonumber(iconNameOrId) then
				isAsset = true
				assetId = "rbxassetid://" .. iconNameOrId
			end
		end

		if isAsset then
			return make("ImageLabel", {
				BackgroundTransparency = 1,
				Image = assetId,
				ImageColor3 = color or Color3.new(1, 1, 1),
				Size = size or UDim2.fromOffset(18, 18),
				Parent = parent,
			})
		else
			local symbol = "◈"
			if type(iconNameOrId) == "string" then
				local clean = iconNameOrId:lower():gsub("%-.*$", "")
				symbol = GLYPH_FALLBACKS[clean] or iconNameOrId
				if #symbol > 3 then
					symbol = symbol:sub(1, 1):upper()
				end
			end
			return make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = symbol,
				TextColor3 = color or Color3.new(1, 1, 1),
				TextSize = (size and size.Y.Offset) or 15,
				Size = size or UDim2.fromOffset(18, 18),
				Parent = parent,
			})
		end
	end

	------------------------------------------------------------------ config
	local Config = { Name = "QuantumOnyxGUI", Data = {} }

	local function configLoad(name)
		local result = {}
		pcall(function()
			if type(readfile) == "function" then
				local path = "QuantumOnyx_" .. tostring(name) .. ".json"
				if type(isfile) == "function" and isfile(path) then
					local raw = readfile(path)
					if type(raw) == "string" and raw ~= "" then
						local decoded = HttpService:JSONDecode(raw)
						if type(decoded) == "table" then
							result = decoded
						end
					end
				end
			end
		end)

		if next(result) == nil then
			pcall(function()
				if type(getgenv) == "function" then
					local env = getgenv()
					if type(env._QUANTUM_CONFIGS) == "table" and type(env._QUANTUM_CONFIGS[name]) == "table" then
						result = env._QUANTUM_CONFIGS[name]
					end
				end
			end)
		end

		return result
	end

	local function configSave(name, data)
		pcall(function()
			if type(getgenv) == "function" then
				local env = getgenv()
				env._QUANTUM_CONFIGS = env._QUANTUM_CONFIGS or {}
				env._QUANTUM_CONFIGS[name] = data
			end
		end)

		pcall(function()
			if type(writefile) == "function" then
				local path = "QuantumOnyx_" .. tostring(name) .. ".json"
				local encoded = HttpService:JSONEncode(data)
				writefile(path, encoded)
			end
		end)
	end

	------------------------------------------------------------ reactive theme
	local function bindTheme(window, object, propertyCallbacks)
		local entry = { Object = object, Callbacks = propertyCallbacks }
		table.insert(window.Painters, entry)
		for prop, fn in pairs(propertyCallbacks) do
			pcall(function()
				object[prop] = fn(window.Theme)
			end)
		end
	end

	------------------------------------------------------------ search index
	local SearchIndex = {}

	local function indexElement(object, keywords, tab, menu, section)
		table.insert(SearchIndex, {
			Object = object,
			Keywords = string.lower(keywords or ""),
			Tab = tab,
			Menu = menu,
			Section = section,
		})
	end

	local function applyFilter(text)
		text = string.lower(text or "")
		local matchedTab = nil

		for _, item in ipairs(SearchIndex) do
			if text == "" then
				item.Object.Visible = true
				if item.Stroke then
					item.Stroke.Color = item.Tab.Window.Theme.Border
				end
			else
				local hit = string.find(item.Keywords, text, 1, true) ~= nil
				item.Object.Visible = hit

				if hit then
					if not matchedTab then
						matchedTab = item.Tab
					end
					if item.Menu and item.Menu.SetOpen then
						item.Menu.SetOpen(true)
					end
					if item.Stroke then
						item.Stroke.Color = item.Tab.Window.Theme.Accent
					end
				end
			end
		end

		return matchedTab
	end

	---------------------------------------------------------------- metatables
	local Window = {}
	Window.__index = Window

	local Tab = {}
	Tab.__index = Tab

	local Section = {}
	Section.__index = Section

	local Menu = {}
	Menu.__index = Menu

	local Element = {}

	------------------------------------------------------------------- controls

	-- [BUTTON]
	function Element:addButton(title, callback, locked)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 38),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local btn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Text = tostring(title or "Button"),
			TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local iconTag = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			Text = "▶",
			TextColor3 = window.Theme.Accent,
			TextSize = 12,
			Parent = btn,
		})

		btn.MouseEnter:Connect(function()
			if not isLocked then
				tween(card, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
				tween(edge, { Color = window.Theme.Accent }, 0.15)
			end
		end)

		btn.MouseLeave:Connect(function()
			tween(card, { BackgroundColor3 = window.Theme.Card }, 0.2)
			tween(edge, { Color = window.Theme.Border }, 0.2)
		end)

		btn.MouseButton1Click:Connect(function()
			if isLocked then return end
			-- Click bounce
			tween(card, { Size = UDim2.new(1, -4, 0, 36) }, 0.08, Enum.EasingStyle.Quad).Completed:Connect(function()
				tween(card, { Size = UDim2.new(1, 0, 0, 38) }, 0.12, Enum.EasingStyle.Back)
			end)
			if type(callback) == "function" then
				pcall(callback)
			end
		end)

		bindTheme(window, card, {
			BackgroundColor3 = function(t) return t.Card end,
		})
		bindTheme(window, edge, {
			Color = function(t) return t.Border end,
		})
		bindTheme(window, btn, {
			TextColor3 = function(t) return isLocked and t.Sub or t.Text end,
		})
		bindTheme(window, iconTag, {
			TextColor3 = function(t) return t.Accent end,
		})

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		local buttonObj = {}
		function buttonObj.SetLocked(val)
			isLocked = val and true or false
			btn.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end
		function buttonObj.Fire()
			if type(callback) == "function" then
				pcall(callback)
			end
		end
		return buttonObj
	end

	-- [TOGGLE]
	function Element:addToggle(title, default, callback, locked, description, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local hasDesc = description and description ~= ""
		local height = hasDesc and 48 or 38
		local state = default and true or false
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, hasDesc and 7 or 0),
			Size = UDim2.new(1, -74, 0, hasDesc and 18 or height),
			Text = tostring(title or "Toggle"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		if hasDesc then
			local descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Position = UDim2.fromOffset(12, 26),
				Size = UDim2.new(1, -74, 0, 14),
				Text = tostring(description),
				TextColor3 = window.Theme.Sub,
				TextSize = 11,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			bindTheme(window, descLabel, { TextColor3 = function(t) return t.Sub end })
		end

		-- Switch Pill
		local switch = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = state and window.Theme.Accent or window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(40, 22),
			Parent = card,
		})
		corner(switch, 11)
		local switchEdge = outline(switch, state and window.Theme.Accent or window.Theme.Border, 1, 0.3)

		-- Knob
		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Parent = switch,
		})
		corner(knob, 8)

		local hitBtn = make("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			Parent = card,
		})

		local function paint(animated)
			local dur = animated and 0.2 or 0
			if state then
				tween(switch, { BackgroundColor3 = window.Theme.Accent }, dur)
				tween(switchEdge, { Color = window.Theme.Accent }, dur)
				tween(knob, { Position = UDim2.new(1, -19, 0.5, 0) }, dur)
			else
				tween(switch, { BackgroundColor3 = window.Theme.Track }, dur)
				tween(switchEdge, { Color = window.Theme.Border }, dur)
				tween(knob, { Position = UDim2.new(0, 3, 0.5, 0) }, dur)
			end
		end

		local function updateState(newState, silent)
			if newState == nil then newState = not state end
			state = newState and true or false
			paint(true)

			if saveKey and not silent then
				Config.Data[saveKey] = state
				configSave(Config.Name, Config.Data)
			end

			if not silent and type(callback) == "function" then
				pcall(callback, state)
			end
		end

		hitBtn.MouseEnter:Connect(function()
			if not isLocked then
				tween(card, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
			end
		end)
		hitBtn.MouseLeave:Connect(function()
			tween(card, { BackgroundColor3 = window.Theme.Card }, 0.2)
		end)

		hitBtn.MouseButton1Click:Connect(function()
			if isLocked then return end
			updateState()
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })
		bindTheme(window, switch, { BackgroundColor3 = function(t) return state and t.Accent or t.Track end })
		bindTheme(window, switchEdge, { Color = function(t) return state and t.Accent or t.Border end })

		indexElement(card, title .. " " .. (description or ""), tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		if saveKey and Config.Data[saveKey] ~= nil then
			updateState(Config.Data[saveKey], true)
		end

		local toggleObj = {}
		function toggleObj.Update(val, silent)
			if val == toggleObj then val = silent; silent = nil end
			updateState(val, silent)
		end
		function toggleObj.GetValue()
			return state
		end
		function toggleObj.SetLocked(val)
			isLocked = val and true or false
			label.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end
		return toggleObj
	end

	-- [CHECKBOX]
	function Element:addCheckbox(title, default, callback, locked, description, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local hasDesc = description and description ~= ""
		local height = hasDesc and 48 or 38
		local state = default and true or false
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, hasDesc and 7 or 0),
			Size = UDim2.new(1, -54, 0, hasDesc and 18 or height),
			Text = tostring(title or "Checkbox"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		if hasDesc then
			local descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Position = UDim2.fromOffset(12, 26),
				Size = UDim2.new(1, -54, 0, 14),
				Text = tostring(description),
				TextColor3 = window.Theme.Sub,
				TextSize = 11,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			bindTheme(window, descLabel, { TextColor3 = function(t) return t.Sub end })
		end

		local box = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = state and window.Theme.Accent or window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			Parent = card,
		})
		corner(box, 5)
		local boxEdge = outline(box, state and window.Theme.Accent or window.Theme.Border, 1, 0.3)

		local mark = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Text = "✓",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = state and 13 or 0,
			Parent = box,
		})

		local hitBtn = make("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			Parent = card,
		})

		local function paint(animated)
			local dur = animated and 0.18 or 0
			if state then
				tween(box, { BackgroundColor3 = window.Theme.Accent }, dur)
				tween(boxEdge, { Color = window.Theme.Accent }, dur)
				tween(mark, { TextSize = 13 }, dur)
			else
				tween(box, { BackgroundColor3 = window.Theme.Track }, dur)
				tween(boxEdge, { Color = window.Theme.Border }, dur)
				tween(mark, { TextSize = 0 }, dur)
			end
		end

		local function updateState(newState, silent)
			if newState == nil then newState = not state end
			state = newState and true or false
			paint(true)

			if saveKey and not silent then
				Config.Data[saveKey] = state
				configSave(Config.Name, Config.Data)
			end

			if not silent and type(callback) == "function" then
				pcall(callback, state)
			end
		end

		hitBtn.MouseEnter:Connect(function()
			if not isLocked then
				tween(card, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
			end
		end)
		hitBtn.MouseLeave:Connect(function()
			tween(card, { BackgroundColor3 = window.Theme.Card }, 0.2)
		end)
		hitBtn.MouseButton1Click:Connect(function()
			if isLocked then return end
			updateState()
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })
		bindTheme(window, box, { BackgroundColor3 = function(t) return state and t.Accent or t.Track end })
		bindTheme(window, boxEdge, { Color = function(t) return state and t.Accent or t.Border end })

		indexElement(card, title .. " " .. (description or ""), tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		if saveKey and Config.Data[saveKey] ~= nil then
			updateState(Config.Data[saveKey], true)
		end

		local checkboxObj = {}
		function checkboxObj.Update(val, silent)
			if val == checkboxObj then val = silent; silent = nil end
			updateState(val, silent)
		end
		function checkboxObj.GetValue()
			return state
		end
		function checkboxObj.SetLocked(val)
			isLocked = val and true or false
			label.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end
		return checkboxObj
	end

	-- [SLIDER]
	function Element:addSlider(title, min, max, default, callback, locked, step, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		min = tonumber(min) or 0
		max = tonumber(max) or 100
		step = tonumber(step) or 1
		default = tonumber(default) or min

		local current = math.clamp(default, min, max)
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 52),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -80, 0, 16),
			Text = tostring(title or "Slider"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		-- Value Badge (Clickable to type exact number)
		local badge = make("TextBox", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -12, 0, 7),
			Size = UDim2.fromOffset(56, 18),
			Text = tostring(current),
			TextColor3 = window.Theme.Accent,
			TextSize = 11,
			Parent = card,
		})
		corner(badge, 4)
		local badgeEdge = outline(badge, window.Theme.Border, 1, 0.3)

		-- Track
		local track = make("Frame", {
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 12, 0, 34),
			Size = UDim2.new(1, -24, 0, 6),
			Parent = card,
		})
		corner(track, 3)

		local fill = make("Frame", {
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			Parent = track,
		})
		corner(fill, 3)
		local fillGrad = shade(fill, window.Theme.Accent, window.Theme.Accent2, 0)

		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Parent = track,
		})
		corner(knob, 7)
		local knobEdge = outline(knob, window.Theme.Accent, 1.5, 0.2)

		local hitArea = make("TextButton", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 24),
			Size = UDim2.new(1, -20, 0, 24),
			Text = "",
			Parent = card,
		})

		local function paint()
			local ratio = (current - min) / math.max(max - min, 0.0001)
			ratio = math.clamp(ratio, 0, 1)
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			knob.Position = UDim2.new(ratio, 0, 0.5, 0)
			badge.Text = tostring(current)
		end

		local function setValue(val, silent)
			val = tonumber(val) or min
			val = math.clamp(val, min, max)
			if step > 0 then
				val = math.floor((val - min) / step + 0.5) * step + min
			end
			current = val
			paint()

			if saveKey and not silent then
				Config.Data[saveKey] = current
				configSave(Config.Name, Config.Data)
			end

			if not silent and type(callback) == "function" then
				pcall(callback, current)
			end
		end

		-- Direct type in badge
		badge.FocusLost:Connect(function()
			local n = tonumber(badge.Text)
			if n then
				setValue(n)
			else
				badge.Text = tostring(current)
			end
		end)

		-- Drag logic
		local dragging = false
		local function updateFromInput(input)
			local absX = track.AbsolutePosition.X
			local absW = track.AbsoluteSize.X
			if absW <= 0 then return end
			local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
			local computed = min + rel * (max - min)
			setValue(computed)
		end

		hitArea.InputBegan:Connect(function(input)
			if isLocked then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromInput(input)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromInput(input)
			end
		end)

		hitArea.MouseEnter:Connect(function()
			if not isLocked then
				tween(card, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
			end
		end)
		hitArea.MouseLeave:Connect(function()
			tween(card, { BackgroundColor3 = window.Theme.Card }, 0.2)
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })
		bindTheme(window, badge, { BackgroundColor3 = function(t) return t.Track end, TextColor3 = function(t) return t.Accent end })
		bindTheme(window, badgeEdge, { Color = function(t) return t.Border end })
		bindTheme(window, track, { BackgroundColor3 = function(t) return t.Track end })
		bindTheme(window, fill, { BackgroundColor3 = function(t) return t.Accent end })
		bindTheme(window, knobEdge, { Color = function(t) return t.Accent end })

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		if saveKey and Config.Data[saveKey] ~= nil then
			setValue(Config.Data[saveKey], true)
		else
			paint()
		end

		local sliderObj = {}
		function sliderObj.Update(val, silent)
			if val == sliderObj then val = silent; silent = nil end
			setValue(val, silent)
		end
		function sliderObj.GetValue()
			return current
		end
		function sliderObj.SetLocked(val)
			isLocked = val and true or false
			label.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end
		return sliderObj
	end

	-- [DROPDOWN]
	function Element:addDropdown(title, default, options, callback, locked, description, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local isLocked = locked and true or false
		local isOpen = false
		local selected = default

		-- Extract options table
		local function parseOptions(raw)
			if type(raw) == "function" then
				raw = raw()
			end
			local list = {}
			for idx, item in ipairs(raw or {}) do
				local name = item
				local val = item
				if type(item) == "table" then
					name = item.Name or item.name or item.Label or item.label or tostring(idx)
					val = item.Value or item.value or item
				end
				table.insert(list, { Name = tostring(name), Value = val })
			end
			return list
		end

		local currentOptions = parseOptions(options)

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 40),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local headerBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 40),
			Text = "",
			Parent = card,
		})

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(0.5, -12, 0, 40),
			Text = tostring(title or "Dropdown"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBtn,
		})

		local selectBadge = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Position = UDim2.new(1, -34, 0.5, 0),
			Size = UDim2.fromOffset(110, 22),
			Text = tostring(selected or "Select..."),
			TextColor3 = window.Theme.Accent,
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = headerBtn,
		})
		corner(selectBadge, 5)
		local badgeStroke = outline(selectBadge, window.Theme.Border, 1, 0.3)

		local chevron = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Text = "▼",
			TextColor3 = window.Theme.Sub,
			TextSize = 10,
			Parent = headerBtn,
		})

		-- Options Container
		local optContainer = make("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(6, 44),
			ScrollBarImageColor3 = window.Theme.Accent,
			ScrollBarThickness = 2,
			Size = UDim2.new(1, -12, 0, 0),
			Visible = false,
			Parent = card,
		})
		local optLayout = make("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = optContainer,
		})

		local dropdownObj = {}

		local function setOpen(val)
			if val then
				if window.OpenDropdown and window.OpenDropdown ~= dropdownObj then
					pcall(function() window.OpenDropdown.Close() end)
				end
				window.OpenDropdown = dropdownObj
			elseif window.OpenDropdown == dropdownObj then
				window.OpenDropdown = nil
			end
			isOpen = val and true or false
			local targetH = isOpen and math.min(#currentOptions * 28 + 50, 160) or 40
			optContainer.Visible = isOpen
			optContainer.Size = UDim2.new(1, -12, 0, targetH - 46)
			tween(chevron, { Rotation = isOpen and 180 or 0 }, 0.2)
			tween(card, { Size = UDim2.new(1, 0, 0, targetH) }, 0.22)
		end

		function dropdownObj.Close()
			if isOpen then
				setOpen(false)
			end
		end

		local function selectItem(item, silent)
			selected = item.Value or item.Name
			selectBadge.Text = tostring(item.Name)
			setOpen(false)

			if saveKey and not silent then
				Config.Data[saveKey] = selected
				configSave(Config.Name, Config.Data)
			end

			if not silent and type(callback) == "function" then
				pcall(callback, selected)
			end
		end

		local function buildOptions()
			for _, child in ipairs(optContainer:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			for idx, item in ipairs(currentOptions) do
				local optBtn = make("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = window.Theme.Track,
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					Size = UDim2.new(1, 0, 0, 25),
					Text = "   " .. item.Name,
					TextColor3 = (selected == item.Value or selected == item.Name) and window.Theme.Accent or window.Theme.Sub,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = optContainer,
				})
				corner(optBtn, 4)

				optBtn.MouseEnter:Connect(function()
					tween(optBtn, { BackgroundColor3 = window.Theme.CardHover, TextColor3 = window.Theme.Text }, 0.15)
				end)
				optBtn.MouseLeave:Connect(function()
					local isSel = (selected == item.Value or selected == item.Name)
					tween(optBtn, { BackgroundColor3 = window.Theme.Track, TextColor3 = isSel and window.Theme.Accent or window.Theme.Sub }, 0.15)
				end)
				optBtn.MouseButton1Click:Connect(function()
					selectItem(item)
				end)
			end
		end

		buildOptions()

		headerBtn.MouseEnter:Connect(function()
			if not isLocked then
				tween(card, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
			end
		end)
		headerBtn.MouseLeave:Connect(function()
			tween(card, { BackgroundColor3 = window.Theme.Card }, 0.2)
		end)
		headerBtn.MouseButton1Click:Connect(function()
			if isLocked then return end
			setOpen(not isOpen)
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })
		bindTheme(window, selectBadge, { BackgroundColor3 = function(t) return t.Track end, TextColor3 = function(t) return t.Accent end })
		bindTheme(window, badgeStroke, { Color = function(t) return t.Border end })
		bindTheme(window, chevron, { TextColor3 = function(t) return t.Sub end })

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		function dropdownObj.Update(val, silent)
			if val == dropdownObj then val = silent; silent = nil end
			selected = val
			selectBadge.Text = tostring(val or "Select...")
			buildOptions()
			if not silent and type(callback) == "function" then
				pcall(callback, selected)
			end
		end
		function dropdownObj.Refresh(newOpts, b)
			local opts = (newOpts == dropdownObj) and b or newOpts
			currentOptions = parseOptions(opts)
			buildOptions()
			if isOpen then
				setOpen(false)
			end
		end
		function dropdownObj.GetValue()
			return selected
		end
		function dropdownObj.SetLocked(val)
			isLocked = val and true or false
			label.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end

		if saveKey and Config.Data[saveKey] ~= nil then
			dropdownObj.Update(Config.Data[saveKey], true)
		end

		return dropdownObj
	end

	-- [MULTI DROPDOWN]
	function Element:addMultiDropdown(title, defaultList, options, callback, locked, description, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local isLocked = locked and true or false
		local isOpen = false
		local selected = {}

		if type(defaultList) == "table" then
			for k, v in pairs(defaultList) do
				if type(k) == "number" then
					selected[tostring(v)] = true
				else
					selected[tostring(k)] = (v and true or false)
				end
			end
		end

		local function parseOptions(raw)
			if type(raw) == "function" then raw = raw() end
			local list = {}
			for idx, item in ipairs(raw or {}) do
				local name = item
				if type(item) == "table" then
					name = item.Name or item.Label or tostring(idx)
				end
				table.insert(list, tostring(name))
			end
			return list
		end

		local currentOptions = parseOptions(options)

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 40),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local headerBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			Text = "",
			Parent = card,
		})

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(0.5, -12, 0, 40),
			Text = tostring(title or "Multi Dropdown"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBtn,
		})

		local countBadge = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -34, 0.5, 0),
			Size = UDim2.fromOffset(90, 22),
			Text = "0 Selected",
			TextColor3 = window.Theme.Accent,
			TextSize = 11,
			Parent = headerBtn,
		})
		corner(countBadge, 5)
		local countEdge = outline(countBadge, window.Theme.Border, 1, 0.3)

		local chevron = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Text = "▼",
			TextColor3 = window.Theme.Sub,
			TextSize = 10,
			Parent = headerBtn,
		})

		local optContainer = make("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(6, 44),
			ScrollBarImageColor3 = window.Theme.Accent,
			ScrollBarThickness = 2,
			Size = UDim2.new(1, -12, 0, 0),
			Visible = false,
			Parent = card,
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = optContainer,
		})

		local function updateBadge()
			local count = 0
			for _, v in pairs(selected) do
				if v then count = count + 1 end
			end
			countBadge.Text = tostring(count) .. " Selected"
		end

		local multiObj = {}

		local function setOpen(val)
			if val then
				if window.OpenDropdown and window.OpenDropdown ~= multiObj then
					pcall(function() window.OpenDropdown.Close() end)
				end
				window.OpenDropdown = multiObj
			elseif window.OpenDropdown == multiObj then
				window.OpenDropdown = nil
			end
			isOpen = val and true or false
			local targetH = isOpen and math.min(#currentOptions * 28 + 50, 160) or 40
			optContainer.Visible = isOpen
			optContainer.Size = UDim2.new(1, -12, 0, targetH - 46)
			tween(chevron, { Rotation = isOpen and 180 or 0 }, 0.2)
			tween(card, { Size = UDim2.new(1, 0, 0, targetH) }, 0.22)
		end

		function multiObj.Close()
			if isOpen then
				setOpen(false)
			end
		end

		local function buildOptions()
			for _, child in ipairs(optContainer:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			for _, name in ipairs(currentOptions) do
				local isSel = selected[name] == true
				local row = make("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = window.Theme.Track,
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					Size = UDim2.new(1, 0, 0, 25),
					Text = "     " .. name,
					TextColor3 = isSel and window.Theme.Text or window.Theme.Sub,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = optContainer,
				})
				corner(row, 4)

				local box = make("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = isSel and window.Theme.Accent or window.Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 6, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					Parent = row,
				})
				corner(box, 3)
				outline(box, isSel and window.Theme.Accent or window.Theme.Border, 1, 0.3)

				local check = make("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					Text = "✓",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = isSel and 10 or 0,
					Parent = box,
				})

				row.MouseButton1Click:Connect(function()
					selected[name] = not selected[name]
					updateBadge()
					buildOptions()

					if saveKey then
						Config.Data[saveKey] = selected
						configSave(Config.Name, Config.Data)
					end

					if type(callback) == "function" then
						local list = {}
						for k, v in pairs(selected) do
							if v then table.insert(list, k) end
						end
						pcall(callback, selected, list)
					end
				end)
			end
			updateBadge()
		end

		buildOptions()

		headerBtn.MouseButton1Click:Connect(function()
			if isLocked then return end
			setOpen(not isOpen)
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })
		bindTheme(window, countBadge, { BackgroundColor3 = function(t) return t.Track end, TextColor3 = function(t) return t.Accent end })
		bindTheme(window, countEdge, { Color = function(t) return t.Border end })
		bindTheme(window, chevron, { TextColor3 = function(t) return t.Sub end })

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		function multiObj.Update(tbl, silent)
			if tbl == multiObj then tbl = silent; silent = nil end
			selected = {}
			if type(tbl) == "table" then
				for k, v in pairs(tbl) do
					if type(k) == "number" then selected[tostring(v)] = true else selected[tostring(k)] = v and true or false end
				end
			end
			buildOptions()
			if not silent and type(callback) == "function" then
				local list = {}
				for k, v in pairs(selected) do if v then table.insert(list, k) end end
				pcall(callback, selected, list)
			end
		end
		function multiObj.Refresh(newOpts)
			currentOptions = parseOptions(newOpts)
			buildOptions()
		end
		function multiObj.GetValue()
			return selected
		end
		function multiObj.SetLocked(val)
			isLocked = val and true or false
			label.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end

		if saveKey and Config.Data[saveKey] ~= nil then
			multiObj.Update(Config.Data[saveKey], true)
		end

		return multiObj
	end

	-- [TEXTBOX / INPUT]
	function Element:addTextbox(title, callback, confirmText, saveKey, defaultText)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local hasConfirm = confirmText and confirmText ~= ""
		local currentText = defaultText or ""

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 42),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(0.4, -12, 1, 0),
			Text = tostring(title or "Input"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local inputContainer = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0.58, 0, 0, 28),
			Parent = card,
		})
		corner(inputContainer, 6)
		local inputEdge = outline(inputContainer, window.Theme.Border, 1, 0.3)

		local boxWidth = hasConfirm and UDim2.new(1, -54, 1, 0) or UDim2.new(1, -8, 1, 0)
		local box = make("TextBox", {
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			Font = Enum.Font.Gotham,
			PlaceholderColor3 = window.Theme.Sub,
			PlaceholderText = "Type here...",
			Position = UDim2.fromOffset(6, 0),
			Size = boxWidth,
			Text = currentText,
			TextColor3 = window.Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = inputContainer,
		})

		local confirmBtn = nil
		if hasConfirm then
			confirmBtn = make("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				AutoButtonColor = false,
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Position = UDim2.new(1, -3, 0.5, 0),
				Size = UDim2.fromOffset(46, 22),
				Text = tostring(confirmText),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 11,
				Parent = inputContainer,
			})
			corner(confirmBtn, 4)
		end

		local function submit(val)
			currentText = tostring(val or box.Text)
			if saveKey then
				Config.Data[saveKey] = currentText
				configSave(Config.Name, Config.Data)
			end
			if type(callback) == "function" then
				pcall(callback, currentText)
			end
		end

		box.Focused:Connect(function()
			tween(inputEdge, { Color = window.Theme.Accent }, 0.15)
		end)

		box.FocusLost:Connect(function(enterPressed)
			tween(inputEdge, { Color = window.Theme.Border }, 0.2)
			if not hasConfirm or enterPressed then
				submit(box.Text)
			end
		end)

		if confirmBtn then
			confirmBtn.MouseButton1Click:Connect(function()
				submit(box.Text)
			end)
		end

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return t.Text end })
		bindTheme(window, inputContainer, { BackgroundColor3 = function(t) return t.Track end })
		bindTheme(window, inputEdge, { Color = function(t) return t.Border end })
		bindTheme(window, box, { TextColor3 = function(t) return t.Text end, PlaceholderColor3 = function(t) return t.Sub end })
		if confirmBtn then
			bindTheme(window, confirmBtn, { BackgroundColor3 = function(t) return t.Accent end })
		end

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		if saveKey and Config.Data[saveKey] ~= nil then
			currentText = tostring(Config.Data[saveKey])
			box.Text = currentText
		end

		local textboxObj = {}
		function textboxObj.Update(val, silent)
			if val == textboxObj then val = silent; silent = nil end
			currentText = tostring(val or "")
			box.Text = currentText
			if not silent and type(callback) == "function" then
				pcall(callback, currentText)
			end
		end
		function textboxObj.GetValue()
			return currentText
		end
		function textboxObj.SetLocked(val)
			box.TextEditable = not val
		end
		return textboxObj
	end

	-- Alias for addInput
	Element.addInput = Element.addTextbox

	-- [KEYBIND]
	function Element:addKeybind(title, defaultKey, callback, locked, description, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local currentKey = defaultKey or Enum.KeyCode.RightShift
		local isListening = false
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 38),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -120, 1, 0),
			Text = tostring(title or "Keybind"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local bindBtn = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(80, 24),
			Text = currentKey and ("[" .. tostring(currentKey.Name or currentKey) .. "]") or "[None]",
			TextColor3 = window.Theme.Accent,
			TextSize = 11,
			Parent = card,
		})
		corner(bindBtn, 5)
		local bindEdge = outline(bindBtn, window.Theme.Border, 1, 0.3)

		local function setKey(newKey, silent)
			currentKey = newKey
			bindBtn.Text = currentKey and ("[" .. tostring(currentKey.Name or currentKey) .. "]") or "[None]"
			isListening = false
			bindBtn.TextColor3 = window.Theme.Accent

			if saveKey and not silent then
				Config.Data[saveKey] = tostring(currentKey.Name or currentKey)
				configSave(Config.Name, Config.Data)
			end

			if not silent and type(callback) == "function" then
				pcall(callback, currentKey)
			end
		end

		bindBtn.MouseButton1Click:Connect(function()
			if isLocked then return end
			isListening = true
			bindBtn.Text = "[...]"
			bindBtn.TextColor3 = window.Theme.Warning
		end)

		UserInputService.InputBegan:Connect(function(input, gpe)
			if isListening then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape then
						setKey(nil)
					else
						setKey(input.KeyCode)
					end
				end
			elseif not gpe and currentKey and input.KeyCode == currentKey then
				if type(callback) == "function" then
					pcall(callback, currentKey)
				end
			end
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })
		bindTheme(window, bindBtn, { BackgroundColor3 = function(t) return t.Track end, TextColor3 = function(t) return isListening and t.Warning or t.Accent end })
		bindTheme(window, bindEdge, { Color = function(t) return t.Border end })

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		local keybindObj = {}
		function keybindObj.Update(k, silent)
			if k == keybindObj then k = silent; silent = nil end
			if type(k) == "string" and Enum.KeyCode[k] then k = Enum.KeyCode[k] end
			setKey(k, silent)
		end
		function keybindObj.GetValue()
			return currentKey
		end
		function keybindObj.SetLocked(val)
			isLocked = val and true or false
			label.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end
		return keybindObj
	end

	-- [COLOR PICKER]
	function Element:addColorPicker(title, defaultColor, callback, locked, description, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local currentColor = defaultColor or Color3.fromRGB(150, 96, 255)
		local isLocked = locked and true or false
		local isOpen = false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 38),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local headerBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 38),
			Text = "",
			Parent = card,
		})

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -70, 0, 38),
			Text = tostring(title or "Color Picker"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBtn,
		})

		local preview = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = currentColor,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(36, 20),
			Parent = headerBtn,
		})
		corner(preview, 4)
		local previewEdge = outline(preview, Color3.new(1, 1, 1), 1, 0.5)

		-- Expandable RGB Sliders
		local paletteContainer = make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 42),
			Size = UDim2.new(1, -24, 0, 90),
			Visible = false,
			Parent = card,
		})

		local rVal, gVal, bVal = math.floor(currentColor.R * 255), math.floor(currentColor.G * 255), math.floor(currentColor.B * 255)

		local function createChannelSlider(channelName, yOffset, getVal, setVal)
			local row = make("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, yOffset),
				Size = UDim2.new(1, 0, 0, 24),
				Parent = paletteContainer,
			})
			local chLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Size = UDim2.fromOffset(20, 24),
				Text = channelName,
				TextColor3 = window.Theme.Sub,
				TextSize = 11,
				Parent = row,
			})
			local chTrack = make("Frame", {
				BackgroundColor3 = window.Theme.Track,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(24, 9),
				Size = UDim2.new(1, -64, 0, 6),
				Parent = row,
			})
			corner(chTrack, 3)
			local chFill = make("Frame", {
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Size = UDim2.new(getVal() / 255, 0, 1, 0),
				Parent = chTrack,
			})
			corner(chFill, 3)
			local chBadge = make("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(34, 20),
				Text = tostring(getVal()),
				TextColor3 = window.Theme.Text,
				TextSize = 11,
				Parent = row,
			})
			local chBtn = make("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "",
				Parent = row,
			})

			local dragging = false
			local function updateFromInput(input)
				local absX = chTrack.AbsolutePosition.X
				local absW = chTrack.AbsoluteSize.X
				local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
				local val = math.floor(rel * 255)
				setVal(val)
				chFill.Size = UDim2.new(rel, 0, 1, 0)
				chBadge.Text = tostring(val)
				currentColor = Color3.fromRGB(rVal, gVal, bVal)
				preview.BackgroundColor3 = currentColor
				if type(callback) == "function" then
					pcall(callback, currentColor)
				end
			end

			chBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromInput(input)
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then dragging = false end
					end)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromInput(input)
				end
			end)
		end

		createChannelSlider("R", 0, function() return rVal end, function(v) rVal = v end)
		createChannelSlider("G", 28, function() return gVal end, function(v) gVal = v end)
		createChannelSlider("B", 56, function() return bVal end, function(v) bVal = v end)

		local function setOpen(val)
			isOpen = val and true or false
			paletteContainer.Visible = isOpen
			tween(card, { Size = UDim2.new(1, 0, 0, isOpen and 136 or 38) }, 0.22)
		end

		headerBtn.MouseButton1Click:Connect(function()
			if isLocked then return end
			setOpen(not isOpen)
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, label, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		local colorObj = {}
		function colorObj.Update(c, silent)
			if c == colorObj then c = silent; silent = nil end
			if typeof(c) == "Color3" then
				currentColor = c
				preview.BackgroundColor3 = currentColor
				rVal, gVal, bVal = math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
				if not silent and type(callback) == "function" then
					pcall(callback, currentColor)
				end
			end
		end
		function colorObj.GetValue()
			return currentColor
		end
		function colorObj.SetLocked(val)
			isLocked = val and true or false
			label.TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text
		end
		return colorObj
	end

	-- [LABEL]
	function Element:addLabel(title, description)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local hasDesc = description and description ~= ""
		local height = hasDesc and 44 or 32

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		local titleLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(12, hasDesc and 6 or 0),
			Size = UDim2.new(1, -24, 0, hasDesc and 16 or height),
			Text = tostring(title or "Label"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local descLabel = nil
		if hasDesc then
			descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Position = UDim2.fromOffset(12, 24),
				Size = UDim2.new(1, -24, 0, 14),
				Text = tostring(description),
				TextColor3 = window.Theme.Sub,
				TextSize = 11,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			bindTheme(window, descLabel, { TextColor3 = function(t) return t.Sub end })
		end

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, titleLabel, { TextColor3 = function(t) return t.Text end })

		indexElement(card, title .. " " .. (description or ""), tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		local labelObj = {}
		function labelObj.RefreshTitle(text, b)
			local t = (text == labelObj) and b or text
			titleLabel.Text = tostring(t or "")
		end
		function labelObj.RefreshDesc(desc, b)
			local d = (desc == labelObj) and b or desc
			if descLabel then
				descLabel.Text = tostring(d or "")
			end
		end
		function labelObj.SetText(t, d)
			labelObj.RefreshTitle(t)
			labelObj.RefreshDesc(d)
		end
		return labelObj
	end

	-- [PARAGRAPH]
	function Element:addParagraph(title, content)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local card = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 56),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)
		inset(card, 12, 10, 12, 10)

		local titleLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(1, 0, 0, 18),
			Text = tostring(title or "Information"),
			TextColor3 = window.Theme.Accent,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local bodyLabel = make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 0, 0),
			Text = tostring(content or ""),
			TextColor3 = window.Theme.Sub,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, titleLabel, { TextColor3 = function(t) return t.Accent end })
		bindTheme(window, bodyLabel, { TextColor3 = function(t) return t.Sub end })

		indexElement(card, title .. " " .. (content or ""), tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		local paraObj = {}
		function paraObj.Update(t, c)
			if t == paraObj then t = c; c = nil end
			if t then titleLabel.Text = tostring(t) end
			if c then bodyLabel.Text = tostring(c) end
		end
		function paraObj.SetTitle(t) titleLabel.Text = tostring(t or "") end
		function paraObj.SetContent(c) bodyLabel.Text = tostring(c or "") end
		return paraObj
	end

	-- [BUTTON GRID]
	function Element:addButtonGrid(title, gridItems)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self

		local items = gridItems or {}
		local count = #items
		local rows = math.ceil(count / 2)
		local totalHeight = rows * 36 + 28

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, totalHeight),
			Parent = parent,
		})
		corner(card, 8)
		local edge = outline(card, window.Theme.Border, 1, 0.4)

		if title and title ~= "" then
			local titleLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromOffset(12, 6),
				Size = UDim2.new(1, -24, 0, 16),
				Text = tostring(title),
				TextColor3 = window.Theme.Accent,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			bindTheme(window, titleLabel, { TextColor3 = function(t) return t.Accent end })
		end

		local gridFrame = make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 24),
			Size = UDim2.new(1, -20, 0, rows * 36),
			Parent = card,
		})

		local layout = make("UIGridLayout", {
			CellPadding = UDim2.fromOffset(6, 6),
			CellSize = UDim2.new(0.5, -3, 0, 30),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = gridFrame,
		})

		for _, item in ipairs(items) do
			local cell = make("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = window.Theme.Track,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamSemibold,
				Text = tostring(item.Label or item.Text or "Action"),
				TextColor3 = window.Theme.Text,
				TextSize = 11,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = gridFrame,
			})
			corner(cell, 6)
			local cellEdge = outline(cell, window.Theme.Border, 1, 0.3)

			cell.MouseEnter:Connect(function()
				tween(cell, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
				tween(cellEdge, { Color = window.Theme.Accent }, 0.15)
			end)
			cell.MouseLeave:Connect(function()
				tween(cell, { BackgroundColor3 = window.Theme.Track }, 0.15)
				tween(cellEdge, { Color = window.Theme.Border }, 0.15)
			end)
			cell.MouseButton1Click:Connect(function()
				tween(cell, { Size = UDim2.new(0.5, -5, 0, 28) }, 0.08).Completed:Connect(function()
					tween(cell, { Size = UDim2.new(0.5, -3, 0, 30) }, 0.1)
				end)
				if type(item.Callback) == "function" then
					pcall(item.Callback)
				end
			end)

			bindTheme(window, cell, {
				BackgroundColor3 = function(t) return t.Track end,
				TextColor3 = function(t) return t.Text end,
			})
			bindTheme(window, cellEdge, { Color = function(t) return t.Border end })
		end

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })

		indexElement(card, title, tab, self.IsMenu and self or nil, self.IsSection and self or nil)

		return card
	end

	---------------------------------------------------------------- containers

	-- Inherit controls on Menu
	for name, fn in pairs(Element) do
		Menu[name] = fn
		-- PascalCase alias
		local pascal = name:sub(1, 1):upper() .. name:sub(2)
		Menu[pascal] = fn
	end

	-- Inherit controls on Section
	for name, fn in pairs(Element) do
		Section[name] = fn
		local pascal = name:sub(1, 1):upper() .. name:sub(2)
		Section[pascal] = fn
	end

	-- Inherit controls on Tab
	for name, fn in pairs(Element) do
		Tab[name] = fn
		local pascal = name:sub(1, 1):upper() .. name:sub(2)
		Tab[pascal] = fn
	end

	------------------------------------------------------------- menu (accordion)
	local function makeMenu(parent, name, window, tab)
		local isOpen = false

		local card = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 38),
			Parent = parent,
		})

		make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = card,
		})

		local headerBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 38),
			Text = "",
			Parent = card,
		})
		corner(headerBtn, 8)
		local headerEdge = outline(headerBtn, window.Theme.Border, 1, 0.4)

		-- Glowing left dot indicator
		local dot = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 19),
			Size = UDim2.fromOffset(6, 6),
			Parent = headerBtn,
		})
		corner(dot, 3)

		local titleLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(26, 0),
			Size = UDim2.new(1, -64, 1, 0),
			Text = tostring(name or "Menu"),
			TextColor3 = window.Theme.Text,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBtn,
		})

		local chevron = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			Text = "▼",
			TextColor3 = window.Theme.Sub,
			TextSize = 11,
			Parent = headerBtn,
		})

		local itemsContainer = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			Parent = card,
		})
		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = itemsContainer,
		})

		local menuObj = setmetatable({
			Card = card,
			Container = itemsContainer,
			Window = window,
			Tab = tab,
			IsMenu = true,
		}, Menu)

		local function setOpen(val)
			if val then
				if tab.OpenMenu and tab.OpenMenu ~= menuObj then
					pcall(function() tab.OpenMenu.Close() end)
				end
				tab.OpenMenu = menuObj
			elseif tab.OpenMenu == menuObj then
				tab.OpenMenu = nil
			end
			isOpen = val and true or false
			itemsContainer.Visible = isOpen
			tween(chevron, { Rotation = isOpen and 180 or 0 }, 0.22)
			tween(headerEdge, { Color = isOpen and window.Theme.Accent or window.Theme.Border }, 0.22)
		end

		function menuObj.Close()
			if isOpen then
				setOpen(false)
			end
		end

		headerBtn.MouseEnter:Connect(function()
			tween(headerBtn, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
		end)
		headerBtn.MouseLeave:Connect(function()
			tween(headerBtn, { BackgroundColor3 = window.Theme.Card }, 0.2)
		end)
		headerBtn.MouseButton1Click:Connect(function()
			setOpen(not isOpen)
		end)

		bindTheme(window, headerBtn, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, headerEdge, { Color = function(t) return isOpen and t.Accent or t.Border end })
		bindTheme(window, dot, { BackgroundColor3 = function(t) return t.Accent end })
		bindTheme(window, titleLabel, { TextColor3 = function(t) return t.Text end })
		bindTheme(window, chevron, { TextColor3 = function(t) return t.Sub end })

		function menuObj.SetOpen(val, b)
			local v = (val == menuObj) and b or val
			setOpen(v)
		end

		return menuObj
	end

	function Section:addMenu(name)
		return makeMenu(self.Container, name, self.Window, self.Tab)
	end
	Section.AddMenu = Section.addMenu

	----------------------------------------------------------------- section
	local function makeSection(parent, name, window, tab)
		local hasTitle = name and name ~= ""

		local sectionFrame = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = parent,
		})

		if hasTitle then
			local header = make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				Parent = sectionFrame,
			})
			local pill = make("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(2, 12),
				Size = UDim2.fromOffset(3, 14),
				Parent = header,
			})
			corner(pill, 2)
			local title = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -20, 1, 0),
				Text = string.upper(tostring(name)),
				TextColor3 = window.Theme.Accent,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = header,
			})
			bindTheme(window, pill, { BackgroundColor3 = function(t) return t.Accent end })
			bindTheme(window, title, { TextColor3 = function(t) return t.Accent end })
		end

		local container = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, hasTitle and 26 or 0),
			Size = UDim2.new(1, 0, 0, 0),
			Parent = sectionFrame,
		})
		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = container,
		})

		local sectionObj = setmetatable({
			Root = sectionFrame,
			Container = container,
			Window = window,
			Tab = tab,
			IsSection = true,
		}, Section)

		return sectionObj
	end

	function Tab:addSection(name)
		return makeSection(self.Container, name, self.Window, self)
	end
	Tab.AddSection = Tab.addSection

	--------------------------------------------------------------------- tab
	local function makeTab(window, name, icon)
		local page = make("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(0, 0),
			ScrollBarImageColor3 = window.Theme.Accent,
			ScrollBarThickness = 3,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = window.ContentArea,
		})
		inset(page, 14, 12, 14, 14)
		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})

		-- Sidebar Button
		local tabBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 36),
			Text = "",
			Parent = window.TabList,
		})
		corner(tabBtn, 8)

		-- Left active indicator bar
		local activeBar = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(2, 18),
			Size = UDim2.fromOffset(3, 0),
			Parent = tabBtn,
		})
		corner(activeBar, 2)

		-- Tab Icon
		local tabIcon = makeIcon(tabBtn, icon or "home", UDim2.fromOffset(18, 18), window.Theme.Sub)
		tabIcon.Position = UDim2.fromOffset(14, 9)

		-- Tab Name Label
		local tabTitle = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Position = UDim2.fromOffset(40, 0),
			Size = UDim2.new(1, -48, 1, 0),
			Text = tostring(name or "Tab"),
			TextColor3 = window.Theme.Sub,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tabBtn,
		})

		local tabObj = setmetatable({
			Name = name,
			Icon = icon,
			Page = page,
			Button = tabBtn,
			ActiveBar = activeBar,
			TabIcon = tabIcon,
			TitleLabel = tabTitle,
			Container = page,
			Window = window,
		}, Tab)

		local function selectTab()
			if window.CurrentTab == tabObj then return end

			if window.OpenDropdown then
				pcall(function() window.OpenDropdown.Close() end)
				window.OpenDropdown = nil
			end

			-- Deselect previous tab
			if window.CurrentTab then
				local prev = window.CurrentTab
				tween(prev.Button, { BackgroundTransparency = 1 }, 0.2)
				tween(prev.ActiveBar, { Size = UDim2.fromOffset(3, 0) }, 0.2)
				tween(prev.TitleLabel, { TextColor3 = window.Theme.Sub }, 0.2)
				if prev.TabIcon:IsA("ImageLabel") then
					tween(prev.TabIcon, { ImageColor3 = window.Theme.Sub }, 0.2)
				else
					tween(prev.TabIcon, { TextColor3 = window.Theme.Sub }, 0.2)
				end
				prev.Page.Visible = false
			end

			-- Select current tab
			window.CurrentTab = tabObj
			tween(tabBtn, { BackgroundTransparency = 0.85, BackgroundColor3 = window.Theme.Accent }, 0.2)
			tween(activeBar, { Size = UDim2.fromOffset(3, 20) }, 0.2)
			tween(tabTitle, { TextColor3 = window.Theme.Text }, 0.2)
			if tabIcon:IsA("ImageLabel") then
				tween(tabIcon, { ImageColor3 = window.Theme.Accent }, 0.2)
			else
				tween(tabIcon, { TextColor3 = window.Theme.Accent }, 0.2)
			end

			-- Update Topbar breadcrumb
			if window.Breadcrumb then
				window.Breadcrumb.Text = tostring(name)
			end

			-- Show page with smooth slide & fade animation
			page.Position = UDim2.fromOffset(16, 0)
			page.Visible = true
			tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.24, Enum.EasingStyle.Quad)
		end

		tabBtn.MouseEnter:Connect(function()
			if window.CurrentTab ~= tabObj then
				tween(tabBtn, { BackgroundTransparency = 0.9, BackgroundColor3 = window.Theme.CardHover }, 0.15)
				tween(tabTitle, { TextColor3 = window.Theme.Text }, 0.15)
			end
		end)

		tabBtn.MouseLeave:Connect(function()
			if window.CurrentTab ~= tabObj then
				tween(tabBtn, { BackgroundTransparency = 1 }, 0.2)
				tween(tabTitle, { TextColor3 = window.Theme.Sub }, 0.2)
			end
		end)

		tabBtn.MouseButton1Click:Connect(selectTab)

		tabObj.Select = selectTab
		table.insert(window.Tabs, tabObj)

		-- Select first tab automatically
		if #window.Tabs == 1 then
			selectTab()
		end

		return tabObj
	end

	function Window:AddTab(name, icon)
		return makeTab(self, name, icon)
	end
	Window.addTab = Window.AddTab

	---------------------------------------------------------- mobile floating toggle
	local function setupMobileToggle(window)
		local toggleBtn = make("ImageButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = window.Theme.Sidebar,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(46, 46),
			ZIndex = 9999,
			AutoButtonColor = false,
			Parent = window.Gui,
		})
		corner(toggleBtn, 23)
		local stroke = outline(toggleBtn, window.Theme.Accent, 1.8, 0.2)
		local grad = shade(toggleBtn, window.Theme.Card, window.Theme.Main, 45)

		-- Inner Quantum Logo
		local icon = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://10734975692", -- Swords / Quantum icon
			ImageColor3 = window.Theme.Accent,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(24, 24),
			ZIndex = 10000,
			Parent = toggleBtn,
		})

		-- Dragging on Mobile Button
		local dragging = false
		local dragStart, startPos
		toggleBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = toggleBtn.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				local cam = workspace.CurrentCamera
				local maxX = cam and cam.ViewportSize.X or 800
				local maxY = cam and cam.ViewportSize.Y or 600
				local newX = math.clamp(startPos.X.Offset + delta.X + (startPos.X.Scale * maxX), 25, maxX - 25)
				local newY = math.clamp(startPos.Y.Offset + delta.Y + (startPos.Y.Scale * maxY), 25, maxY - 25)
				toggleBtn.Position = UDim2.fromOffset(newX, newY)
			end
		end)

		-- Tap to Toggle UI
		local pressStart = 0
		toggleBtn.MouseButton1Down:Connect(function()
			pressStart = tick()
		end)
		toggleBtn.MouseButton1Up:Connect(function()
			if tick() - pressStart < 0.25 then
				window:Toggle()
				tween(toggleBtn, { Size = UDim2.fromOffset(40, 40) }, 0.08).Completed:Connect(function()
					tween(toggleBtn, { Size = UDim2.fromOffset(46, 46) }, 0.12, Enum.EasingStyle.Back)
				end)
			end
		end)

		bindTheme(window, toggleBtn, { BackgroundColor3 = function(t) return t.Sidebar end })
		bindTheme(window, stroke, { Color = function(t) return t.Accent end })
		bindTheme(window, icon, { ImageColor3 = function(t) return t.Accent end })

		window.MobileToggle = toggleBtn
	end

	------------------------------------------------------------ notifications
	local function setupNotifications(window)
		local stack = make("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -20, 0, 20),
			Size = UDim2.new(0, 310, 1, -40),
			ZIndex = 10000,
			Parent = window.Gui,
		})
		make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Parent = stack,
		})

		local toastsById = {}

		local function notify(data, options)
			data = data or {}
			options = options or {}
			local notifId = data.Id or HttpService:GenerateGUID(false)
			local dur = tonumber(options.Time) or 5

			-- If exists, update existing toast
			if toastsById[notifId] then
				local existing = toastsById[notifId]
				if existing.TitleLabel then existing.TitleLabel.Text = tostring(data.Title or "Notification") end
				if existing.DescLabel then existing.DescLabel.Text = tostring(data.Description or "") end
				existing.ResetTimer(dur)
				return existing
			end

			local toast = make("Frame", {
				BackgroundColor3 = window.Theme.Main,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.fromOffset(330, 0),
				Size = UDim2.new(1, 0, 0, 68),
				ZIndex = 10001,
				Parent = stack,
			})
			corner(toast, 10)
			local edge = outline(toast, window.Theme.Border, 1.2, 0.3)

			-- Left Accent Indicator
			local bar = make("Frame", {
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(0, 4, 1, 0),
				ZIndex = 10002,
				Parent = toast,
			})

			local titleLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromOffset(14, 8),
				Size = UDim2.new(1, -38, 0, 18),
				Text = tostring(data.Title or "Notification"),
				TextColor3 = window.Theme.Text,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 10002,
				Parent = toast,
			})

			local descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Position = UDim2.fromOffset(14, 28),
				Size = UDim2.new(1, -28, 0, 24),
				Text = tostring(data.Description or ""),
				TextColor3 = window.Theme.Sub,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 10002,
				Parent = toast,
			})

			-- Close 'X' button
			local closeBtn = make("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.fromOffset(20, 20),
				Text = "×",
				TextColor3 = window.Theme.Sub,
				TextSize = 14,
				ZIndex = 10003,
				Parent = toast,
			})

			-- Time Progress Bar
			local timerBar = make("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 4, 1, 0),
				Size = UDim2.new(1, -4, 0, 2),
				ZIndex = 10002,
				Parent = toast,
			})

			bindTheme(window, toast, { BackgroundColor3 = function(t) return t.Main end })
			bindTheme(window, edge, { Color = function(t) return t.Border end })
			bindTheme(window, bar, { BackgroundColor3 = function(t) return t.Accent end })
			bindTheme(window, titleLabel, { TextColor3 = function(t) return t.Text end })
			bindTheme(window, descLabel, { TextColor3 = function(t) return t.Sub end })
			bindTheme(window, timerBar, { BackgroundColor3 = function(t) return t.Accent end })

			-- Slide In Animation
			tween(toast, { Position = UDim2.fromOffset(0, 0) }, 0.28, Enum.EasingStyle.Back)

			local timerTween = nil
			local function startTimer(seconds)
				if timerTween then timerTween:Cancel() end
				timerBar.Size = UDim2.new(1, -4, 0, 2)
				timerTween = tween(timerBar, { Size = UDim2.new(0, 0, 0, 2) }, seconds, Enum.EasingStyle.Linear)
				timerTween.Completed:Connect(function()
					-- Dismiss
					toastsById[notifId] = nil
					local anim = tween(toast, { Position = UDim2.fromOffset(330, 0) }, 0.2, Enum.EasingStyle.Quad)
					anim.Completed:Connect(function()
						toast:Destroy()
					end)
				end)
			end

			startTimer(dur)

			closeBtn.MouseButton1Click:Connect(function()
				if timerTween then timerTween:Cancel() end
				toastsById[notifId] = nil
				local anim = tween(toast, { Position = UDim2.fromOffset(330, 0) }, 0.2, Enum.EasingStyle.Quad)
				anim.Completed:Connect(function()
					toast:Destroy()
				end)
			end)

			local handle = {
				Toast = toast,
				TitleLabel = titleLabel,
				DescLabel = descLabel,
				ResetTimer = startTimer,
			}
			toastsById[notifId] = handle
			return handle
		end

		window.Toaster = notify
	end

	---------------------------------------------------------------- window build
	local function buildWindow(config)
		config = config or {}

		local themeName = config.Theme
		if THEMES[themeName] == nil then
			themeName = "Purple"
		end

		local saveName = tostring(config.SaveFile or "QuantumOnyxGUI")
		Config.Name = saveName
		Config.Data = configLoad(saveName)

		-- Cleanup any existing window
		pcall(function()
			local oldCore = getSafeGuiParent():FindFirstChild("QuantumOnyxWindow")
			if oldCore then oldCore:Destroy() end
			local oldPg = playerGui:FindFirstChild("QuantumOnyxWindow")
			if oldPg then oldPg:Destroy() end
		end)

		local gui = make("ScreenGui", {
			DisplayOrder = 999,
			IgnoreGuiInset = false,
			Name = "QuantumOnyxWindow",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = getSafeGuiParent(),
		})

		local root = make("Frame", {
			Active = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Parent = gui,
		})

		local window = setmetatable({
			Gui = gui,
			Root = root,
			Theme = THEMES[themeName],
			ThemeName = themeName,
			Tabs = {},
			Painters = {},
			NormalSize = Vector2.new(710, 480),
			IsVisible = true,
			IsMinimized = false,
		}, Window)

		------------------------------------------------------------ main window
		local main = make("Frame", {
			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = window.Theme.Main,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(710, 480),
			ClipsDescendants = true,
			Parent = root,
		})
		corner(main, 12)
		local mainEdge = outline(main, window.Theme.Border, 1.2, 0.25)
		local mainGrad = shade(main, window.Theme.Panel, window.Theme.Main, 90)

		-- Size Constraints
		make("UISizeConstraint", {
			MaxSize = Vector2.new(1200, 900),
			MinSize = Vector2.new(460, 320),
			Parent = main,
		})

		window.Main = main

		---------------------------------------------------------------- sidebar
		local sidebar = make("Frame", {
			BackgroundColor3 = window.Theme.Sidebar,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(0, 185, 1, 0),
			Parent = main,
		})
		local sidebarEdge = outline(sidebar, window.Theme.Border, 1, 0.4)

		-- Brand Section
		local brand = make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 56),
			Parent = sidebar,
		})

		-- Glowing Crystal Logo
		local logo = make("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://10734975692", -- Swords / Crystal
			ImageColor3 = window.Theme.Accent,
			Position = UDim2.fromOffset(14, 28),
			Size = UDim2.fromOffset(26, 26),
			Parent = brand,
		})

		local title = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(48, 12),
			Size = UDim2.new(1, -54, 0, 18),
			Text = tostring(config.Title or "Quantum Onyx"),
			TextColor3 = window.Theme.Text,
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = brand,
		})

		local subtitle = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(48, 30),
			Size = UDim2.new(1, -54, 0, 14),
			Text = tostring(config.Subtitle or "Blox Fruit"),
			TextColor3 = window.Theme.Accent,
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = brand,
		})

		-- Search Bar (Inside Sidebar)
		local searchRow = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 60),
			Size = UDim2.new(1, -24, 0, 30),
			Parent = sidebar,
		})
		corner(searchRow, 6)
		local searchEdge = outline(searchRow, window.Theme.Border, 1, 0.3)

		local searchLens = make("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(8, 15),
			Size = UDim2.fromOffset(14, 14),
			Text = "⚲",
			TextColor3 = window.Theme.Sub,
			TextSize = 12,
			Parent = searchRow,
		})

		local searchBox = make("TextBox", {
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			Font = Enum.Font.Gotham,
			PlaceholderColor3 = window.Theme.Sub,
			PlaceholderText = "Search...",
			Position = UDim2.fromOffset(26, 0),
			Size = UDim2.new(1, -48, 1, 0),
			Text = "",
			TextColor3 = window.Theme.Text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = searchRow,
		})

		local clearSearch = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			Text = "×",
			TextColor3 = window.Theme.Sub,
			TextSize = 12,
			Visible = false,
			Parent = searchRow,
		})

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBox.Text
			clearSearch.Visible = query ~= ""
			local matchedTab = applyFilter(query)
			if matchedTab and matchedTab.Select then
				matchedTab.Select()
			end
		end)

		clearSearch.MouseButton1Click:Connect(function()
			searchBox.Text = ""
		end)

		-- Tab List (ScrollingFrame)
		local tabList = make("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(8, 98),
			ScrollBarImageColor3 = window.Theme.Accent,
			ScrollBarThickness = 2,
			Size = UDim2.new(1, -16, 1, -156),
			Parent = sidebar,
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabList,
		})
		window.TabList = tabList

		-- User Profile Card (Bottom of Sidebar)
		local profileCard = make("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 10, 1, -10),
			Size = UDim2.new(1, -20, 0, 44),
			Parent = sidebar,
		})
		corner(profileCard, 8)
		local profileEdge = outline(profileCard, window.Theme.Border, 1, 0.3)

		local avatar = make("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 22),
			Size = UDim2.fromOffset(28, 28),
			Parent = profileCard,
		})
		corner(avatar, 14)
		pcall(function()
			local content, isReady = Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			avatar.Image = content
		end)

		local userName = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(42, 6),
			Size = UDim2.new(1, -48, 0, 16),
			Text = tostring(localPlayer.DisplayName or localPlayer.Name),
			TextColor3 = window.Theme.Text,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = profileCard,
		})

		local userRole = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(42, 22),
			Size = UDim2.new(1, -48, 0, 14),
			Text = "Quantum " .. tostring(config.Version or "v.Premium"),
			TextColor3 = window.Theme.Accent,
			TextSize = 10,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = profileCard,
		})

		------------------------------------------------------------ content container
		local mainContent = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(185, 0),
			Size = UDim2.new(1, -185, 1, 0),
			Parent = main,
		})

		---------------------------------------------------------------- topbar
		local topbar = make("Frame", {
			BackgroundColor3 = window.Theme.Topbar,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 50),
			Parent = mainContent,
		})
		local topbarEdge = outline(topbar, window.Theme.Border, 1, 0.4)

		-- Breadcrumb Label
		local breadcrumb = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(18, 0),
			Size = UDim2.new(0.4, 0, 1, 0),
			Text = "Home",
			TextColor3 = window.Theme.Text,
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = topbar,
		})
		window.Breadcrumb = breadcrumb

		-- Topbar Controls (Right Side)
		local actionsRow = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(260, 32),
			Parent = topbar,
		})
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = actionsRow,
		})

		-- ⏹ Stop All Button
		local stopBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = window.Theme.Danger,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Size = UDim2.fromOffset(80, 26),
			Text = "⏹ Stop All",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 11,
			Parent = actionsRow,
		})
		corner(stopBtn, 6)

		stopBtn.MouseButton1Click:Connect(function()
			tween(stopBtn, { Size = UDim2.fromOffset(76, 24) }, 0.08).Completed:Connect(function()
				tween(stopBtn, { Size = UDim2.fromOffset(80, 26) }, 0.1)
			end)
			if type(config.OnStopAll) == "function" then
				pcall(config.OnStopAll)
			end
			window:Notify({
				Title = "Quantum Onyx",
				Description = "All running tasks and auto-farms stopped!",
			}, { Time = 3 })
		end)

		-- Topbar Icon Buttons Helper
		local function makeTopButton(text, tooltip, onClick)
			local b = make("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = window.Theme.Card,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Size = UDim2.fromOffset(28, 26),
				Text = text,
				TextColor3 = window.Theme.Sub,
				TextSize = 12,
				Parent = actionsRow,
			})
			corner(b, 6)
			local bStroke = outline(b, window.Theme.Border, 1, 0.3)

			b.MouseEnter:Connect(function()
				tween(b, { BackgroundColor3 = window.Theme.CardHover, TextColor3 = window.Theme.Text }, 0.15)
			end)
			b.MouseLeave:Connect(function()
				tween(b, { BackgroundColor3 = window.Theme.Card, TextColor3 = window.Theme.Sub }, 0.2)
			end)
			b.MouseButton1Click:Connect(onClick)

			bindTheme(window, b, {
				BackgroundColor3 = function(t) return t.Card end,
				TextColor3 = function(t) return t.Sub end,
			})
			bindTheme(window, bStroke, { Color = function(t) return t.Border end })
			return b
		end

		-- Theme Cycler Button
		makeTopButton("🎨", "Change Theme", function()
			local curIdx = 1
			for idx, name in ipairs(THEME_ORDER) do
				if name == window.ThemeName then
					curIdx = idx
					break
				end
			end
			local nextTheme = THEME_ORDER[(curIdx % #THEME_ORDER) + 1]
			window:SetTheme(nextTheme)
		end)

		-- Credits Button
		makeTopButton("ℹ", "Credits", function()
			local lines = {}
			for _, person in ipairs(config.Credits or {}) do
				if type(person) == "table" then
					table.insert(lines, tostring(person.Name or "?") .. " - " .. tostring(person.Role or ""))
				else
					table.insert(lines, tostring(person))
				end
			end
			if #lines == 0 then
				table.insert(lines, "Quantum Onyx Team")
			end
			window:Notify({
				Title = tostring(config.Title or "Quantum Onyx") .. " - Credits",
				Description = table.concat(lines, "\n"),
			}, { Time = 7 })
		end)

		-- Minimize Button
		local minBtn = makeTopButton("-", "Minimize", function()
			window:Minimized(not window.IsMinimized)
		end)
		window.MinBtn = minBtn

		-- Close / Hide Button
		makeTopButton("×", "Close", function()
			window:Hide()
		end)

		------------------------------------------------------------ content area
		local contentArea = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 50),
			Size = UDim2.new(1, 0, 1, -78), -- 50 topbar + 28 footer
			Parent = mainContent,
		})
		window.ContentArea = contentArea

		---------------------------------------------------------------- footer
		local footer = make("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = window.Theme.Topbar,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 28),
			Parent = mainContent,
		})
		local footerEdge = outline(footer, window.Theme.Border, 1, 0.4)

		-- Status Dot
		local statusDot = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.Success,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 14),
			Size = UDim2.fromOffset(7, 7),
			Parent = footer,
		})
		corner(statusDot, 4)

		local statusText = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Position = UDim2.fromOffset(24, 0),
			Size = UDim2.new(0.35, 0, 1, 0),
			Text = "Quantum Active | " .. tostring(config.Version or "v.Premium"),
			TextColor3 = window.Theme.Sub,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = footer,
		})

		-- Telemetry Stats (Right Side: Ping, FPS, Time)
		local telemetry = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.new(0.6, 0, 1, 0),
			Text = "FPS: 60  |  Ping: 45ms  |  00:00",
			TextColor3 = window.Theme.Sub,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = footer,
		})

		-- Telemetry Update Loop
		local startTime = tick()
		local frameCount = 0
		local lastFpsTime = tick()
		local currentFps = 60

		RunService.RenderStepped:Connect(function()
			frameCount = frameCount + 1
			local now = tick()
			if now - lastFpsTime >= 0.5 then
				currentFps = math.floor(frameCount / (now - lastFpsTime))
				frameCount = 0
				lastFpsTime = now

				local ping = 50
				pcall(function()
					local stats = game:GetService("Stats")
					ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)

				local elapsed = formatTime(now - startTime)
				telemetry.Text = string.format("FPS: %d  |  Ping: %dms  |  %s", currentFps, ping, elapsed)
			end
		end)

		------------------------------------------------------------ dragging
		local dragging = false
		local dragStart, startPos
		topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				tween(main, {
					Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
				}, 0.06, Enum.EasingStyle.Linear)
			end
		end)

		------------------------------------------------------------ responsive
		local function updateResponsive()
			local cam = workspace.CurrentCamera
			if not cam then return end
			local viewport = cam.ViewportSize
			if viewport.X < 740 then
				-- Compact Mode for mobile
				main.Size = UDim2.new(0.95, 0, 0.90, 0)
				sidebar.Size = UDim2.new(0, 52, 1, 0)
				brand.Visible = false
				searchRow.Visible = false
				profileCard.Visible = false
				tabList.Position = UDim2.fromOffset(4, 10)
				tabList.Size = UDim2.new(1, -8, 1, -20)
				mainContent.Position = UDim2.fromOffset(52, 0)
				mainContent.Size = UDim2.new(1, -52, 1, 0)
			else
				-- Standard Mode
				main.Size = UDim2.fromOffset(window.NormalSize.X, window.NormalSize.Y)
				sidebar.Size = UDim2.new(0, 185, 1, 0)
				brand.Visible = true
				searchRow.Visible = true
				profileCard.Visible = true
				tabList.Position = UDim2.fromOffset(8, 98)
				tabList.Size = UDim2.new(1, -16, 1, -156)
				mainContent.Position = UDim2.fromOffset(185, 0)
				mainContent.Size = UDim2.new(1, -185, 1, 0)
			end
		end

		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsive)
			updateResponsive()
		end

		-- Setup Extra Systems
		setupMobileToggle(window)
		setupNotifications(window)

		-- Global RightShift Keybind to toggle UI
		UserInputService.InputBegan:Connect(function(input, gpe)
			if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
				window:Toggle()
			end
		end)

		-- Theme Bindings for Main Window
		bindTheme(window, main, { BackgroundColor3 = function(t) return t.Main end })
		bindTheme(window, mainEdge, { Color = function(t) return t.Border end })
		bindTheme(window, sidebar, { BackgroundColor3 = function(t) return t.Sidebar end })
		bindTheme(window, sidebarEdge, { Color = function(t) return t.Border end })
		bindTheme(window, topbar, { BackgroundColor3 = function(t) return t.Topbar end })
		bindTheme(window, topbarEdge, { Color = function(t) return t.Border end })
		bindTheme(window, footer, { BackgroundColor3 = function(t) return t.Topbar end })
		bindTheme(window, footerEdge, { Color = function(t) return t.Border end })
		bindTheme(window, logo, { ImageColor3 = function(t) return t.Accent end })
		bindTheme(window, title, { TextColor3 = function(t) return t.Text end })
		bindTheme(window, subtitle, { TextColor3 = function(t) return t.Accent end })
		bindTheme(window, breadcrumb, { TextColor3 = function(t) return t.Text end })
		bindTheme(window, searchRow, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, searchEdge, { Color = function(t) return t.Border end })
		bindTheme(window, searchBox, { TextColor3 = function(t) return t.Text end, PlaceholderColor3 = function(t) return t.Sub end })
		bindTheme(window, searchLens, { TextColor3 = function(t) return t.Sub end })
		bindTheme(window, profileCard, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, profileEdge, { Color = function(t) return t.Border end })
		bindTheme(window, userName, { TextColor3 = function(t) return t.Text end })
		bindTheme(window, userRole, { TextColor3 = function(t) return t.Accent end })
		bindTheme(window, statusDot, { BackgroundColor3 = function(t) return t.Success end })
		bindTheme(window, statusText, { TextColor3 = function(t) return t.Sub end })
		bindTheme(window, telemetry, { TextColor3 = function(t) return t.Sub end })

		return window
	end

	------------------------------------------------------------- window methods
	function Window:SetTheme(name)
		if THEMES[name] == nil then return end
		self.Theme = THEMES[name]
		self.ThemeName = name

		for _, entry in ipairs(self.Painters) do
			if entry.Object and entry.Object.Parent then
				for prop, fn in pairs(entry.Callbacks) do
					pcall(function()
						local target = fn(self.Theme)
						if typeof(target) == "Color3" then
							tween(entry.Object, { [prop] = target }, 0.22)
						else
							entry.Object[prop] = target
						end
					end)
				end
			end
		end

		self:Notify({
			Title = "Theme Changed",
			Description = "Current palette: " .. name,
		}, { Time = 2 })
	end
	Window.setTheme = Window.SetTheme

	function Window:Notify(data, options)
		if self.Toaster then
			return self.Toaster(data, options)
		end
	end
	Window.notify = Window.Notify

	function Window:Show()
		self.IsVisible = true
		self.Main.Visible = true
		self.Main.Size = UDim2.fromOffset(self.NormalSize.X * 0.9, self.NormalSize.Y * 0.9)
		tween(self.Main, { Size = UDim2.fromOffset(self.NormalSize.X, self.NormalSize.Y) }, 0.24, Enum.EasingStyle.Back)
	end
	Window.show = Window.Show

	function Window:Hide()
		self.IsVisible = false
		local anim = tween(self.Main, { Size = UDim2.fromOffset(self.NormalSize.X * 0.9, self.NormalSize.Y * 0.9) }, 0.18, Enum.EasingStyle.Quad)
		anim.Completed:Connect(function()
			if not self.IsVisible then
				self.Main.Visible = false
			end
		end)
	end
	Window.hide = Window.Hide

	function Window:Toggle()
		if self.IsVisible then
			self:Hide()
		else
			self:Show()
		end
	end
	Window.toggle = Window.Toggle

	function Window:Minimized(val)
		self.IsMinimized = val and true or false
		if self.IsMinimized then
			self.ContentArea.Visible = false
			self.Main.ClipsDescendants = true
			tween(self.Main, { Size = UDim2.fromOffset(self.NormalSize.X, 50) }, 0.22)
			if self.MinBtn then self.MinBtn.Text = "+" end
		else
			self.ContentArea.Visible = true
			tween(self.Main, { Size = UDim2.fromOffset(self.NormalSize.X, self.NormalSize.Y) }, 0.22)
			if self.MinBtn then self.MinBtn.Text = "-" end
		end
	end
	Window.minimized = Window.Minimized

	function Window:SaveConfig()
		configSave(Config.Name, Config.Data)
		self:Notify({
			Title = "Configuration Saved",
			Description = "Settings saved to " .. Config.Name,
		}, { Time = 2 })
	end
	Window.saveConfig = Window.SaveConfig

	function Window:Destroy()
		pcall(function()
			if self.Gui then
				self.Gui:Destroy()
			end
		end)
	end
	Window.destroy = Window.Destroy

	function Window:OpenMenu()
		self:Show()
		return self.Root
	end
	Window.openMenu = Window.OpenMenu

	---------------------------------------------------------------- exports
	local module = {}
	local Notification = {}
	module.Notification = Notification

	function Notification:Notify(data, options)
		if self.Window and self.Window.Notify then
			return self.Window:Notify(data, options)
		end
	end

	function module.CreateWindow(selfOrConfig, maybeConfig)
		local config = (type(selfOrConfig) == "table" and (selfOrConfig.Title ~= nil or selfOrConfig.Theme ~= nil or maybeConfig == nil and selfOrConfig ~= module)) and selfOrConfig or maybeConfig or {}
		local window = buildWindow(config)
		Notification.Window = window
		return window
	end

	module.Themes = THEMES
	module.ThemeOrder = THEME_ORDER
	module.SearchIndex = SearchIndex
	module.Version = GUI_VERSION
	module.Build = BuildQuantumGUI

	return module
end

local defaultBuilt = BuildQuantumGUI()

return {
	Build = BuildQuantumGUI,
	CreateWindow = function(...) return defaultBuilt.CreateWindow(...) end,
	Notification = defaultBuilt.Notification,
	Themes = defaultBuilt.Themes,
	ThemeOrder = defaultBuilt.ThemeOrder,
	Version = defaultBuilt.Version,
}
