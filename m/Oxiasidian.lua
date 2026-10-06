-- ============================================================================
-- Oxiasidian GUI Library - Crimson Night deck (reference reconstruction)
-- Changelog:
--   4.0.4 - auto-fit UIScale to viewport (whole window always fits on screen,
--           phones included) + narrow-screen sidebar collapse
--   4.0.3 - default UIScale 0.85 -> 0.75 (more compact window)
--   4.0.2 - removed all image icons (tabs/rows/hero/search/mobile use text only)
--   4.0.1 - global UI scale (UIScale, default 0.85) so the whole window
--           renders smaller; override via CreateWindow({ UIScale = ... })
--   4.0.0 - full reconstruction from reference image (dark red deck,
--           numbered sidebar tabs, hero banners, pill controls, toasts)
-- ============================================================================
local GUI_VERSION = "4.0.4"

local function BuildOxiasidianGUI()

	----------------------------------------------------------------- services
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local TextService = game:GetService("TextService")

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	-- Safe GUI container (gethui first so game scans cannot see the UI).
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
	-- Signature look: Crimson Night. "Purple" is kept as an alias because
	-- existing scripts request Theme = "Purple".
	local THEMES = {
		Crimson = {
			Name = "Crimson",
			Background = Color3.fromRGB(11, 13, 22),
			Surface = Color3.fromRGB(20, 23, 36),
			Card = Color3.fromRGB(26, 30, 48),
			CardHover = Color3.fromRGB(34, 39, 62),
			Track = Color3.fromRGB(38, 44, 68),
			Border = Color3.fromRGB(42, 48, 72),
			BorderActive = Color3.fromRGB(230, 57, 86),
			Text = Color3.fromRGB(242, 244, 250),
			Sub = Color3.fromRGB(138, 144, 168),
			Mono = Color3.fromRGB(110, 116, 144),
			Accent = Color3.fromRGB(230, 57, 86),
			AccentHi = Color3.fromRGB(255, 77, 109),
			AccentLo = Color3.fromRGB(200, 30, 58),
			Accent2 = Color3.fromRGB(139, 92, 246),
			Accent2Hi = Color3.fromRGB(167, 139, 250),
			Success = Color3.fromRGB(46, 213, 115),
			Danger = Color3.fromRGB(255, 71, 87),
			Warning = Color3.fromRGB(255, 171, 0),
		},
	}

	THEMES.Purple = THEMES.Crimson

	local THEME_ORDER = { "Crimson" }

	------------------------------------------------------------------- icons
	-- Only asset IDs already shipped with the product. Anything else is
	-- ASSET_REQUIRED and must be filled in with real rbxassetid uploads.

	-- Menu-name keyword -> accent pack ("violet" or "red").
	local ACCENT_HINTS = {
		{ "boss", "violet" },
		{ "raid", "violet" },
		{ "dungeon", "violet" },
	}

	local function resolveAccent(explicit, name)
		if explicit == "violet" or explicit == "red" then
			return explicit
		end
		local lowered = string.lower(tostring(name or ""))
		for _, hint in ipairs(ACCENT_HINTS) do
			if string.find(lowered, hint[1], 1, true) then
				return hint[2]
			end
		end
		return "red"
	end

	------------------------------------------------------------------ config
	local Config = { Name = "OxiasidianGUI", Data = {} }
	local CONFIG_FOLDER = "OxiasidianConfigs"
	local configSave

	local function configPath(name)
		return CONFIG_FOLDER .. "/" .. "Oxiasidian_" .. tostring(name) .. ".json"
	end

	local function ensureConfigFolder()
		if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
			return false
		end
		local ok, exists = pcall(isfolder, CONFIG_FOLDER)
		if ok and exists then
			return true
		end
		local made = pcall(makefolder, CONFIG_FOLDER)
		return made
	end

	local function readJsonFile(path)
		if type(readfile) ~= "function" or type(isfile) ~= "function" then
			return nil
		end
		local okFile, exists = pcall(isfile, path)
		if not okFile or not exists then
			return nil
		end
		local okRead, raw = pcall(readfile, path)
		if not okRead or type(raw) ~= "string" or raw == "" then
			return nil
		end
		local okDecode, decoded = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not okDecode or type(decoded) ~= "table" then
			return nil
		end
		return decoded
	end

	local function readSessionData(name)
		local ok, value = pcall(function()
			local env = (type(getgenv) == "function") and getgenv() or nil
			if type(env) == "table" and type(env._Oxiasidian_CONFIGS) == "table" then
				local entry = env._Oxiasidian_CONFIGS[name]
				if type(entry) == "table" then
					return entry
				end
			end
			return nil
		end)
		if ok and type(value) == "table" then
			return value
		end
		return nil
	end

	local function writeSessionData(name, data)
		pcall(function()
			if type(getgenv) == "function" then
				local env = getgenv()
				env._Oxiasidian_CONFIGS = env._Oxiasidian_CONFIGS or {}
				env._Oxiasidian_CONFIGS[name] = data
			end
		end)
	end

	configSave = function(name, data)
		writeSessionData(name, data)

		pcall(function()
			if type(writefile) ~= "function" then
				return
			end
			if not ensureConfigFolder() then
				return
			end
			local encoded = HttpService:JSONEncode(data)
			writefile(configPath(name), encoded)
		end)
	end

	local function configLoad(name)
		local data = readJsonFile(configPath(name))

		if data == nil then
			data = readSessionData(name)
		end

		return data or {}
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
	-- Accent pack for a menu/element ("red" default, "violet" for boss-type groups).
	local function accentPack(window, which)
		local t = window.Theme
		if which == "violet" then
			return { Base = t.Accent2, Hi = t.Accent2, Lo = t.Accent2 }
		end
		return { Base = t.Accent, Hi = t.AccentHi, Lo = t.AccentLo }
	end

	local function menuAccentOf(self)
		if type(self) == "table" and (self.Accent == "violet" or self.Accent == "red") then
			return self.Accent
		end
		return "red"
	end

	-- [BUTTON]
	function Element:addButton(title, callback, locked)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self
		local isLocked = locked and true or false
		local pack = accentPack(window, menuAccentOf(self))

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 56),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local btn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(16, 0),
			Size = UDim2.new(1, -32, 1, 0),
			Text = tostring(title or "Button"),
			TextColor3 = isLocked and window.Theme.Sub or window.Theme.Text,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local goTag = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			Text = "›",
			TextColor3 = pack.Base,
			TextSize = 20,
			Parent = btn,
		})

		btn.MouseEnter:Connect(function()
			if not isLocked then
				tween(card, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
				tween(edge, { Color = pack.Base }, 0.15)
			end
		end)

		btn.MouseLeave:Connect(function()
			tween(card, { BackgroundColor3 = window.Theme.Card }, 0.2)
			tween(edge, { Color = window.Theme.Border }, 0.2)
		end)

		btn.MouseButton1Click:Connect(function()
			if isLocked then return end
			tween(card, { Size = UDim2.new(1, -4, 0, 54) }, 0.08, Enum.EasingStyle.Quad).Completed:Connect(function()
				tween(card, { Size = UDim2.new(1, 0, 0, 56) }, 0.12, Enum.EasingStyle.Back)
			end)
			if type(callback) == "function" then
				pcall(callback)
			end
		end)

		bindTheme(window, card, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, edge, { Color = function(t) return t.Border end })
		bindTheme(window, btn, { TextColor3 = function(t) return isLocked and t.Sub or t.Text end })

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
		local pack = accentPack(window, menuAccentOf(self))

		local hasDesc = description and description ~= ""
		local height = 56
		local state = default and true or false
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, hasDesc and 12 or 0),
			Size = UDim2.new(1, -textX - 92, 0, hasDesc and 22 or height),
			Text = tostring(title or "Toggle"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		if hasDesc then
			local descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Code,
				Position = UDim2.fromOffset(textX, 38),
				Size = UDim2.new(1, -textX - 92, 0, 18),
				Text = tostring(description),
				TextColor3 = window.Theme.Mono,
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			bindTheme(window, descLabel, { TextColor3 = function(t) return t.Mono end })
		end

		local switch = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = state and pack.Base or window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(64, 34),
			Parent = card,
		})
		corner(switch, 17)
		local switchEdge = outline(switch, state and pack.Base or window.Theme.Border, 1, 0.3)

		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = state and UDim2.new(1, -30, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			Parent = switch,
		})
		corner(knob, 13)

		local hitBtn = make("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			Parent = card,
		})

		local accentName = menuAccentOf(self)
		local function paint(animated)
			local dur = animated and 0.2 or 0
			if state then
				tween(switch, { BackgroundColor3 = pack.Base }, dur)
				tween(switchEdge, { Color = pack.Base }, dur)
				tween(knob, { Position = UDim2.new(1, -30, 0.5, 0) }, dur)
			else
				tween(switch, { BackgroundColor3 = window.Theme.Track }, dur)
				tween(switchEdge, { Color = window.Theme.Border }, dur)
				tween(knob, { Position = UDim2.new(0, 4, 0.5, 0) }, dur)
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
		bindTheme(window, switch, { BackgroundColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return state and p.Base or t.Track
		end })
		bindTheme(window, switchEdge, { Color = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return state and p.Base or t.Border
		end })

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
		local pack = accentPack(window, menuAccentOf(self))

		local hasDesc = description and description ~= ""
		local height = 56
		local state = default and true or false
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, hasDesc and 12 or 0),
			Size = UDim2.new(1, -textX - 72, 0, hasDesc and 22 or height),
			Text = tostring(title or "Checkbox"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		if hasDesc then
			local descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Code,
				Position = UDim2.fromOffset(textX, 38),
				Size = UDim2.new(1, -textX - 72, 0, 18),
				Text = tostring(description),
				TextColor3 = window.Theme.Mono,
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			bindTheme(window, descLabel, { TextColor3 = function(t) return t.Mono end })
		end

		local box = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = state and pack.Base or window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			Parent = card,
		})
		corner(box, 7)
		local boxEdge = outline(box, state and pack.Base or window.Theme.Border, 1, 0.3)

		local mark = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Text = "✓",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = state and 15 or 0,
			Parent = box,
		})

		local hitBtn = make("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			Parent = card,
		})

		local accentName = menuAccentOf(self)
		local function paint(animated)
			local dur = animated and 0.18 or 0
			if state then
				tween(box, { BackgroundColor3 = pack.Base }, dur)
				tween(boxEdge, { Color = pack.Base }, dur)
				tween(mark, { TextSize = 15 }, dur)
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
		bindTheme(window, box, { BackgroundColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return state and p.Base or t.Track
		end })
		bindTheme(window, boxEdge, { Color = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return state and p.Base or t.Border
		end })

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
		local pack = accentPack(window, menuAccentOf(self))

		min = tonumber(min) or 0
		max = tonumber(max) or 100
		step = tonumber(step) or 1
		default = tonumber(default) or min

		local current = math.clamp(default, min, max)
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 70),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, 10),
			Size = UDim2.new(1, -textX - 100, 0, 20),
			Text = tostring(title or "Slider"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local badge = make("TextBox", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = pack.Lo,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Enum.Font.Code,
			Position = UDim2.new(1, -16, 0, 10),
			Size = UDim2.fromOffset(72, 24),
			Text = tostring(current),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			Parent = card,
		})
		corner(badge, 6)
		local badgeEdge = outline(badge, pack.Base, 1, 0.3)

		local track = make("Frame", {
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(16, 44),
			Size = UDim2.new(1, -32, 0, 6),
			Parent = card,
		})
		corner(track, 3)

		local fill = make("Frame", {
			BackgroundColor3 = pack.Base,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			Parent = track,
		})
		corner(fill, 3)

		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			Parent = track,
		})
		corner(knob, 10)
		local knobEdge = outline(knob, pack.Base, 2, 0.1)

		local hitArea = make("TextButton", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 32),
			Size = UDim2.new(1, -24, 0, 30),
			Text = "",
			Parent = card,
		})

		local accentName = menuAccentOf(self)
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

		badge.FocusLost:Connect(function()
			local n = tonumber(badge.Text)
			if n then
				setValue(n)
			else
				badge.Text = tostring(current)
			end
		end)

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
		bindTheme(window, badge, { BackgroundColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Lo
		end })
		bindTheme(window, badgeEdge, { Color = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Base
		end })
		bindTheme(window, track, { BackgroundColor3 = function(t) return t.Track end })
		bindTheme(window, fill, { BackgroundColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Base
		end })
		bindTheme(window, knobEdge, { Color = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Base
		end })

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
		local pack = accentPack(window, menuAccentOf(self))

		local isLocked = locked and true or false
		local isOpen = false
		local selected = default

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
			Size = UDim2.new(1, 0, 0, 56),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local headerBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 56),
			Text = "",
			Parent = card,
		})

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(0.45, -textX, 0, 76),
			Text = tostring(title or "Dropdown"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBtn,
		})

		local selectBadge = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = pack.Lo,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Font = Enum.Font.Code,
			Position = UDim2.new(1, -44, 0.5, 0),
			Size = UDim2.fromOffset(150, 30),
			Text = tostring(selected or "Select..."),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = headerBtn,
		})
		corner(selectBadge, 15)
		local badgeStroke = outline(selectBadge, pack.Base, 1, 0.3)

		local chevron = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			Text = "▼",
			TextColor3 = pack.Base,
			TextSize = 14,
			Parent = headerBtn,
		})

		local optContainer = make("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(8, 80),
			ScrollBarImageColor3 = pack.Base,
			ScrollBarThickness = 2,
			Size = UDim2.new(1, -16, 0, 0),
			Visible = false,
			Parent = card,
		})
		local optLayout = make("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = optContainer,
		})

		local dropdownObj = {}
		local accentName = menuAccentOf(self)

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
			local targetH = isOpen and math.min(60 + #currentOptions * 28 + 16, 240) or 56
			optContainer.Visible = isOpen
			optContainer.Size = UDim2.new(1, -16, 0, targetH - 64)
			tween(chevron, { Rotation = isOpen and 180 or 0 }, 0.2)
			tween(edge, { Color = isOpen and pack.Base or window.Theme.Border }, 0.22)
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
					Size = UDim2.new(1, 0, 0, 26),
					Text = "   " .. item.Name,
					TextColor3 = (selected == item.Value or selected == item.Name) and pack.Base or window.Theme.Sub,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = optContainer,
				})
				corner(optBtn, 6)

				optBtn.MouseEnter:Connect(function()
					tween(optBtn, { BackgroundColor3 = window.Theme.CardHover, TextColor3 = window.Theme.Text }, 0.15)
				end)
				optBtn.MouseLeave:Connect(function()
					local isSel = (selected == item.Value or selected == item.Name)
					tween(optBtn, { BackgroundColor3 = window.Theme.Track, TextColor3 = isSel and pack.Base or window.Theme.Sub }, 0.15)
				end)
				optBtn.MouseButton1Click:Connect(function()
					selectItem(item)
				end)
			end
		end

		buildOptions()

		-- QO_DROPDOWN_SEARCH (only for long lists)
		pcall(function()
			local fullOptions = currentOptions

			if #fullOptions < 6 then
				return
			end

			local appliedList = fullOptions
			local searchBox = make("TextBox", {
				BackgroundColor3 = window.Theme.Track,
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				Font = Enum.Font.Code,
				LayoutOrder = -1,
				PlaceholderColor3 = window.Theme.Sub,
				PlaceholderText = "Search...",
				Size = UDim2.new(1, -4, 0, 28),
				Text = "",
				TextColor3 = window.Theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = optContainer,
			})

			corner(searchBox, 6)
			local searchEdge = outline(searchBox, pack.Base, 1, 0.7)

			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				pcall(function()
					local query = string.lower(searchBox.Text or ""):match("^%s*(.-)%s*$") or ""

					if query == "" then
						currentOptions = fullOptions
						appliedList = fullOptions
						buildOptions()
						return
					end

					local filtered = {}

					for _, item in ipairs(fullOptions) do
						if string.find(string.lower(tostring(item.Name)), query, 1, true) then
							table.insert(filtered, item)
						end
					end

					if #filtered == 0 then
						table.insert(filtered, { Name = tostring(selectBadge.Text), Value = selected })
					end

					currentOptions = filtered
					appliedList = filtered
					buildOptions()
				end)
			end)

			local rawSetOpen = setOpen

			setOpen = function(val)
				if val then
					rawSetOpen(true)

					pcall(function()
						if currentOptions ~= fullOptions or searchBox.Text ~= "" then
							searchBox.Text = ""
							currentOptions = fullOptions
							appliedList = fullOptions
							buildOptions()
						end
					end)
				else
					rawSetOpen(false)

					pcall(function()
						if searchBox.Text ~= "" then
							searchBox.Text = ""
						end
					end)
				end
			end

			bindTheme(window, searchBox, {
				BackgroundColor3 = function(t) return t.Track end,
				TextColor3 = function(t) return t.Text end,
				PlaceholderColor3 = function(t) return t.Sub end,
			})
		end)

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
		bindTheme(window, selectBadge, { BackgroundColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Lo
		end })
		bindTheme(window, badgeStroke, { Color = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Base
		end })
		bindTheme(window, chevron, { TextColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Base
		end })

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
		local pack = accentPack(window, menuAccentOf(self))

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
			Size = UDim2.new(1, 0, 0, 56),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local headerBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 56),
			Text = "",
			Parent = card,
		})

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(0.45, -textX, 0, 56),
			Text = tostring(title or "Multi Dropdown"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBtn,
		})

		local countBadge = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = pack.Lo,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Font = Enum.Font.Code,
			Position = UDim2.new(1, -44, 0.5, 0),
			Size = UDim2.fromOffset(110, 30),
			Text = "0 Selected",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			Parent = headerBtn,
		})
		corner(countBadge, 15)
		local countEdge = outline(countBadge, pack.Base, 1, 0.3)

		local chevron = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			Text = "▼",
			TextColor3 = pack.Base,
			TextSize = 14,
			Parent = headerBtn,
		})

		local optContainer = make("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(8, 80),
			ScrollBarImageColor3 = pack.Base,
			ScrollBarThickness = 2,
			Size = UDim2.new(1, -16, 0, 0),
			Visible = false,
			Parent = card,
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 4),
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
		local accentName = menuAccentOf(self)

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
			local targetH = isOpen and math.min(60 + #currentOptions * 28 + 16, 240) or 56
			optContainer.Visible = isOpen
			optContainer.Size = UDim2.new(1, -16, 0, targetH - 64)
			tween(chevron, { Rotation = isOpen and 180 or 0 }, 0.2)
			tween(edge, { Color = isOpen and pack.Base or window.Theme.Border }, 0.22)
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
					Size = UDim2.new(1, 0, 0, 26),
					Text = "     " .. name,
					TextColor3 = isSel and window.Theme.Text or window.Theme.Sub,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = optContainer,
				})
				corner(row, 6)

				local box = make("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = isSel and pack.Base or window.Theme.Card,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					Parent = row,
				})
				corner(box, 4)
				outline(box, isSel and pack.Base or window.Theme.Border, 1, 0.3)

				local check = make("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					Text = "✓",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = isSel and 11 or 0,
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
		bindTheme(window, countBadge, { BackgroundColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Lo
		end })
		bindTheme(window, countEdge, { Color = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Base
		end })
		bindTheme(window, chevron, { TextColor3 = function(t)
			local p = accentPack({ Theme = t }, accentName)
			return p.Base
		end })
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
		local pack = accentPack(window, menuAccentOf(self))

		local hasConfirm = confirmText and confirmText ~= ""
		local currentText = defaultText or ""

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 56),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(0.4, -textX, 1, 0),
			Text = tostring(title or "Input"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local inputContainer = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.new(0.5, 0, 0, 32),
			Parent = card,
		})
		corner(inputContainer, 8)
		local inputEdge = outline(inputContainer, window.Theme.Border, 1, 0.35)

		local boxWidth = hasConfirm and UDim2.new(1, -58, 1, 0) or UDim2.new(1, -10, 1, 0)
		local box = make("TextBox", {
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			Font = Enum.Font.Code,
			PlaceholderColor3 = window.Theme.Sub,
			PlaceholderText = "Type here...",
			Position = UDim2.fromOffset(8, 0),
			Size = boxWidth,
			Text = currentText,
			TextColor3 = window.Theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = inputContainer,
		})

		local confirmBtn = nil
		if hasConfirm then
			confirmBtn = make("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				AutoButtonColor = false,
				BackgroundColor3 = pack.Base,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Position = UDim2.new(1, -4, 0.5, 0),
				Size = UDim2.fromOffset(48, 24),
				Text = tostring(confirmText),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 12,
				Parent = inputContainer,
			})
			corner(confirmBtn, 6)
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
			tween(inputEdge, { Color = pack.Base }, 0.15)
		end)

		box.FocusLost:Connect(function(enterPressed)
			tween(inputEdge, { Color = window.Theme.Border }, 0.2)
			if enterPressed then
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

	Element.addInput = Element.addTextbox

	-- [KEYBIND]
	function Element:addKeybind(title, defaultKey, callback, locked, description, saveKey)
		local parent = self.Container or self.Root
		local window = self.Window
		local tab = self.Tab or self
		local pack = accentPack(window, menuAccentOf(self))

		local currentKey = defaultKey or Enum.KeyCode.RightShift
		local isListening = false
		local isLocked = locked and true or false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 56),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(1, -textX - 130, 1, 0),
			Text = tostring(title or "Keybind"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local bindBtn = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = window.Theme.Track,
			BorderSizePixel = 0,
			Font = Enum.Font.Code,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(110, 30),
			Text = currentKey and ("[" .. tostring(currentKey.Name or currentKey) .. "]") or "[None]",
			TextColor3 = pack.Base,
			TextSize = 13,
			Parent = card,
		})
		corner(bindBtn, 15)
		local bindEdge = outline(bindBtn, pack.Base, 1, 0.4)

		local function setKey(newKey, silent)
			currentKey = newKey
			bindBtn.Text = currentKey and ("[" .. tostring(currentKey.Name or currentKey) .. "]") or "[None]"
			isListening = false
			bindBtn.TextColor3 = pack.Base

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
		bindTheme(window, bindBtn, { BackgroundColor3 = function(t) return t.Track end })

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
		local pack = accentPack(window, menuAccentOf(self))

		local currentColor = defaultColor or Color3.fromRGB(230, 57, 86)
		local isLocked = locked and true or false
		local isOpen = false

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 56),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local headerBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 56),
			Text = "",
			Parent = card,
		})

		local textX = 16

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(1, -textX - 80, 0, 56),
			Text = tostring(title or "Color Picker"),
			TextColor3 = window.Theme.Text,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBtn,
		})

		local preview = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = currentColor,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(48, 26),
			Parent = headerBtn,
		})
		corner(preview, 6)
		local previewEdge = outline(preview, Color3.new(1, 1, 1), 1, 0.5)

		local paletteContainer = make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 60),
			Size = UDim2.new(1, -24, 0, 80),
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
				Font = Enum.Font.Code,
				Size = UDim2.fromOffset(20, 24),
				Text = channelName,
				TextColor3 = window.Theme.Sub,
				TextSize = 12,
				Parent = row,
			})
			local chTrack = make("Frame", {
				BackgroundColor3 = window.Theme.Track,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(24, 9),
				Size = UDim2.new(1, -60, 0, 6),
				Parent = row,
			})
			corner(chTrack, 3)
			local chFill = make("Frame", {
				BackgroundColor3 = pack.Base,
				BorderSizePixel = 0,
				Size = UDim2.new(getVal() / 255, 0, 1, 0),
				Parent = chTrack,
			})
			corner(chFill, 3)
			local chBadge = make("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Font = Enum.Font.Code,
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(38, 22),
				Text = tostring(getVal()),
				TextColor3 = window.Theme.Text,
				TextSize = 12,
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
		createChannelSlider("G", 26, function() return gVal end, function(v) gVal = v end)
		createChannelSlider("B", 52, function() return bVal end, function(v) bVal = v end)

		local function setOpen(val)
			isOpen = val and true or false
			paletteContainer.Visible = isOpen
			tween(card, { Size = UDim2.new(1, 0, 0, isOpen and 160 or 56) }, 0.22)
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
		local height = hasDesc and 56 or 40

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		local textX = 16

		local titleLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(textX, hasDesc and 8 or 0),
			Size = UDim2.new(1, -textX - 12, 0, hasDesc and 20 or height),
			Text = tostring(title or "Label"),
			TextColor3 = window.Theme.Text,
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local descLabel = nil
		if hasDesc then
			descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Position = UDim2.fromOffset(textX, 30),
				RichText = true,
				Size = UDim2.new(1, -textX - 12, 0, 18),
				Text = tostring(description),
				TextColor3 = window.Theme.Sub,
				TextSize = 12,
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
			Size = UDim2.new(1, 0, 0, 48),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)
		inset(card, 12, 10, 12, 10)

		local titleLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(1, 0, 0, 20),
			Text = tostring(title or "Information"),
			TextColor3 = window.Theme.Accent,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local bodyLabel = make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(0, 24),
			RichText = true,
			Size = UDim2.new(1, 0, 0, 0),
			Text = tostring(content or ""),
			TextColor3 = window.Theme.Sub,
			TextSize = 12,
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
		local totalHeight = rows * 40 + 30

		local card = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, totalHeight),
			Parent = parent,
		})
		corner(card, 10)
		local edge = outline(card, window.Theme.Border, 1, 0.5)

		if title and title ~= "" then
			local titleLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromOffset(16, 8),
				Size = UDim2.new(1, -32, 0, 18),
				Text = tostring(title),
				TextColor3 = window.Theme.Accent,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			bindTheme(window, titleLabel, { TextColor3 = function(t) return t.Accent end })
		end

		local gridFrame = make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 26),
			Size = UDim2.new(1, -20, 0, rows * 34),
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
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = gridFrame,
			})
			corner(cell, 8)
			local cellEdge = outline(cell, window.Theme.Border, 1, 0.4)

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

	------------------------------------------------------------- menu (group)
	-- accent: "red" default, "violet" for boss-type groups (or auto by name).
	local function makeMenu(parent, name, window, tab, accent)
		local accentName = accent or resolveAccent(nil, name)
		local pack = accentPack(window, accentName)
		local isOpen = true

		local card = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = parent,
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = card,
		})

		-- Group header: icon + caps title + vents
		local headerRow = make("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			Parent = card,
		})

		local headTitle = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(2, 0),
			Size = UDim2.new(1, -130, 1, 0),
			Text = string.upper(tostring(name or "")),
			TextColor3 = window.Theme.Text,
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerRow,
		})

		-- Vents decoration (three slashes, top-right)
		for i = 1, 3 do
			local vent = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = pack.Base,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -(i - 1) * 14 - 4, 0.5, 0),
				Rotation = 24,
				Size = UDim2.fromOffset(4, 14),
				Parent = headerRow,
			})
			corner(vent, 2)
		end

		local itemsContainer = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = true,
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
			Accent = accentName,
		}, Menu)

		local function setOpen(val)
			isOpen = val and true or false
			itemsContainer.Visible = isOpen
			headerRow.Visible = isOpen
		end

		function menuObj.Close()
			if isOpen then
				setOpen(false)
			end
		end

		function menuObj.SetOpen(val, b)
			local v = (val == menuObj) and b or val
			setOpen(v)
		end

		return menuObj
	end

	function Section:addMenu(name, accent)
		return makeMenu(self.Container, name, self.Window, self.Tab, accent)
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
				Size = UDim2.new(1, 0, 0, 16),
				Parent = sectionFrame,
			})
			local pill = make("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(1, 8),
				Size = UDim2.fromOffset(2, 12),
				Parent = header,
			})
			corner(pill, 1)
			local title = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -16, 1, 0),
				Text = string.upper(tostring(name)),
				TextColor3 = window.Theme.Accent,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = header,
			})
			bindTheme(window, pill, { BackgroundColor3 = function(t) return t.Accent end })
			bindTheme(window, title, { TextColor3 = function(t) return t.Accent end })
		end

		local container = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, hasTitle and 16 or 0),
			Size = UDim2.new(1, 0, 0, 0),
			Parent = sectionFrame,
		})
		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 4),
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
	-- ASSET_REQUIRED: replace "" with a real rbxassetid for the logo avatar.
	local AVATAR_ASSET = ""

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
		inset(page, 14, 10, 14, 12)
		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})

		-- Sidebar Button
		local tabBtn = make("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = window.Theme.Card,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 64),
			Text = "",
			Parent = window.TabList,
		})
		corner(tabBtn, 12)

		-- Active background wash
		local activeBg = make("Frame", {
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = tabBtn,
		})
		corner(activeBg, 12)
		local activeGrad = shade(activeBg, window.Theme.AccentHi, window.Theme.AccentLo, 90)

		-- Tab Number
		local tabNum = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			Position = UDim2.fromOffset(16, 12),
			Size = UDim2.new(1, -32, 0, 14),
			Text = string.format("%02d", #window.Tabs + 1),
			TextColor3 = window.Theme.Mono,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tabBtn,
		})

		-- Tab Name Label
		local tabTitle = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Position = UDim2.fromOffset(16, 24),
			Size = UDim2.new(1, -32, 0, 20),
			Text = tostring(name or "Tab"),
			TextColor3 = window.Theme.Sub,
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tabBtn,
		})

		local tabObj = setmetatable({
			Name = name,
			Icon = icon,
			Page = page,
			Button = tabBtn,
			ActiveBar = activeBg,
			TabIcon = nil,
			TitleLabel = tabTitle,
			NumLabel = tabNum,
			Container = page,
			Window = window,
		}, Tab)

		local function selectTab()
			if window.CurrentTab == tabObj then return end

			if window.OpenDropdown then
				pcall(function() window.OpenDropdown.Close() end)
				window.OpenDropdown = nil
			end

			if window.CurrentTab then
				local prev = window.CurrentTab
				tween(prev.Button, { BackgroundTransparency = 1 }, 0.2)
				tween(prev.ActiveBar, { BackgroundTransparency = 1 }, 0.2)
				tween(prev.TitleLabel, { TextColor3 = window.Theme.Sub }, 0.2)
				tween(prev.NumLabel, { TextColor3 = window.Theme.Mono }, 0.2)
				prev.Page.Visible = false
			end

			window.CurrentTab = tabObj
			tween(activeBg, { BackgroundTransparency = 0 }, 0.2)
			if window.Hero then
				window.Hero.Visible = true
				if window.HeroTitle then
					window.HeroTitle.Text = string.upper(tostring(name or ""))
				end
			end
			tween(tabTitle, { TextColor3 = window.Theme.Text }, 0.2)
			tween(tabNum, { TextColor3 = Color3.new(1, 1, 1) }, 0.2)

			page.Position = UDim2.fromOffset(16, 0)
			page.Visible = true
			tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.24, Enum.EasingStyle.Quad)
		end

		tabBtn.MouseEnter:Connect(function()
			if window.CurrentTab ~= tabObj then
				tween(tabBtn, { BackgroundTransparency = 0.85 }, 0.15)
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

		bindTheme(window, tabBtn, { BackgroundColor3 = function(t) return t.Card end })
		bindTheme(window, activeBg, { BackgroundColor3 = function(t) return t.Accent end })
		bindTheme(window, activeGrad, { Color = function(t) return ColorSequence.new(t.AccentHi, t.AccentLo) end })

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
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(40, 40),
			ZIndex = 9999,
			AutoButtonColor = false,
			Parent = window.Gui,
		})
		corner(toggleBtn, 20)
		local stroke = outline(toggleBtn, window.Theme.AccentHi, 1.5, 0.2)

		local icon = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Text = "Q",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			ZIndex = 10000,
			Parent = toggleBtn,
		})

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

		local pressStart = 0
		toggleBtn.MouseButton1Down:Connect(function()
			pressStart = tick()
		end)
		toggleBtn.MouseButton1Up:Connect(function()
			if tick() - pressStart < 0.25 then
				window:Toggle()
				tween(toggleBtn, { Size = UDim2.fromOffset(36, 36) }, 0.08).Completed:Connect(function()
					tween(toggleBtn, { Size = UDim2.fromOffset(40, 40) }, 0.12, Enum.EasingStyle.Back)
				end)
			end
		end)

		bindTheme(window, toggleBtn, { BackgroundColor3 = function(t) return t.Accent end })
		bindTheme(window, stroke, { Color = function(t) return t.AccentHi end })

		window.MobileToggle = toggleBtn
	end

	------------------------------------------------------------ notifications
	local function setupNotifications(window)
		local stack = make("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -20, 1, -20),
			Size = UDim2.new(0, 340, 0, 400),
			ZIndex = 10000,
			Parent = window.Gui,
		})
		make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Parent = stack,
		})

		local toastsById = {}

		local function notify(data, options)
			data = data or {}
			options = options or {}
			local notifId = data.Id or HttpService:GenerateGUID(false)
			local dur = tonumber(options.Time) or 5

			if toastsById[notifId] then
				local existing = toastsById[notifId]
				if existing.TitleLabel then existing.TitleLabel.Text = tostring(data.Title or "Notification") end
				if existing.DescLabel then existing.DescLabel.Text = tostring(data.Description or "") end
				existing.ResetTimer(dur)
				return existing
			end

local toast = make("Frame", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(320, 0),
			Size = UDim2.new(1, 0, 0, 88),
			ZIndex = 10001,
			Parent = stack,
		})
			corner(toast, 10)
			local edge = outline(toast, window.Theme.Accent, 1.5, 0.35)

			local bar = make("Frame", {
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(0, 4, 1, 0),
				ZIndex = 10002,
				Parent = toast,
			})

			local iconBg = make("Frame", {
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(14, 18),
				Size = UDim2.fromOffset(40, 40),
				ZIndex = 10002,
				Parent = toast,
			})
			corner(iconBg, 20)

			local iconMark = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Size = UDim2.fromScale(1, 1),
				Text = "!",
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 22,
				ZIndex = 10003,
				Parent = iconBg,
			})

			local titleLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromOffset(66, 14),
				Size = UDim2.new(1, -100, 0, 22),
				Text = tostring(data.Title or "Notification"),
				TextColor3 = window.Theme.Text,
				TextSize = 16,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 10002,
				Parent = toast,
			})

			local descLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Code,
				Position = UDim2.fromOffset(66, 40),
				Size = UDim2.new(1, -80, 0, 40),
				Text = tostring(data.Description or ""),
				TextColor3 = window.Theme.Sub,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 10002,
				Parent = toast,
			})

			local closeBtn = make("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.new(1, -6, 0, 8),
				Size = UDim2.fromOffset(22, 22),
				Text = "×",
				TextColor3 = window.Theme.Sub,
				TextSize = 15,
				ZIndex = 10003,
				Parent = toast,
			})

			local timerBar = make("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = window.Theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 4, 1, 0),
				Size = UDim2.new(1, -4, 0, 2),
				ZIndex = 10002,
				Parent = toast,
			})

			bindTheme(window, toast, { BackgroundColor3 = function(t) return t.Card end })
			bindTheme(window, edge, { Color = function(t) return t.Accent end })
			bindTheme(window, bar, { BackgroundColor3 = function(t) return t.Accent end })
			bindTheme(window, iconBg, { BackgroundColor3 = function(t) return t.Accent end })
			bindTheme(window, titleLabel, { TextColor3 = function(t) return t.Text end })
			bindTheme(window, descLabel, { TextColor3 = function(t) return t.Sub end })
			bindTheme(window, timerBar, { BackgroundColor3 = function(t) return t.Accent end })

			tween(toast, { Position = UDim2.fromOffset(0, 0) }, 0.28, Enum.EasingStyle.Back)

			local timerTween = nil
			local function startTimer(seconds)
				if timerTween then timerTween:Cancel() end
				timerBar.Size = UDim2.new(1, -4, 0, 2)
				timerTween = tween(timerBar, { Size = UDim2.new(0, 0, 0, 2) }, seconds, Enum.EasingStyle.Linear)
				timerTween.Completed:Connect(function()
					toastsById[notifId] = nil
local anim = tween(toast, { Position = UDim2.fromOffset(320, 0) }, 0.2, Enum.EasingStyle.Quad)
					anim.Completed:Connect(function()
						toast:Destroy()
					end)
				end)
			end

			startTimer(dur)

			closeBtn.MouseButton1Click:Connect(function()
				if timerTween then timerTween:Cancel() end
				toastsById[notifId] = nil
				local anim = tween(toast, { Position = UDim2.fromOffset(320, 0) }, 0.2, Enum.EasingStyle.Quad)
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
		if themeName == "Purple" then
			themeName = "Crimson"
		end
		if THEMES[themeName] == nil then
			themeName = "Crimson"
		end

		local saveName = tostring(config.SaveFile or "OxiasidianGUI")
		Config.Name = saveName
		Config.Data = configLoad(saveName)

		pcall(function()
			local oldCore = getSafeGuiParent():FindFirstChild("OxiasidianWindow")
			if oldCore then oldCore:Destroy() end
			local oldPg = playerGui:FindFirstChild("OxiasidianWindow")
			if oldPg then oldPg:Destroy() end
		end)

		local gui = make("ScreenGui", {
			DisplayOrder = 999,
			IgnoreGuiInset = false,
			Name = "OxiasidianWindow",
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
			NormalSize = Vector2.new(640, 420),
			IsVisible = true,
			SidebarCollapsed = false,
		}, Window)

		------------------------------------------------------------ main window
		local main = make("Frame", {
			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = window.Theme.Background,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(780, 520),
			ClipsDescendants = true,
			Parent = root,
		})
		corner(main, 14)
		local mainEdge = outline(main, window.Theme.Accent, 1.5, 0.55)
		local mainGrad = shade(main, window.Theme.Surface, window.Theme.Background, 90)

		make("UISizeConstraint", {
			MaxSize = Vector2.new(1200, 800),
			MinSize = Vector2.new(460, 320),
			Parent = main,
		})

		window.Main = main

		-- Global UI scale (compact on PC, auto-scaled to fit on mobile).
		local isTouchDevice = UserInputService.TouchEnabled
		local defaultScale = isTouchDevice and 0.65 or 0.7
		local uiScaleValue = tonumber(config.UIScale) or defaultScale
		if uiScaleValue <= 0 then
			uiScaleValue = 0.7
		end
		local uiScale = make("UIScale", {
			Scale = math.clamp(uiScaleValue, 0.25, 1.2),
			Parent = main,
		})
		window.UIScale = uiScale
		window.BaseUIScale = math.clamp(uiScaleValue, 0.25, 1.2)

		---------------------------------------------------------------- header
		local header = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 88),
			Parent = main,
		})

		-- Angular wing decorations (rotated plates, clipped by header)
		local wingL = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(-40, 44),
			Rotation = -24,
			Size = UDim2.fromOffset(130, 28),
			Parent = header,
		})
		local wingL2 = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.AccentLo,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(-26, 44),
			Rotation = -24,
			Size = UDim2.fromOffset(95, 14),
			Parent = header,
		})
		local wingR = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.Accent,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 280, 0.5, 0),
			Rotation = 24,
			Size = UDim2.fromOffset(110, 26),
			Parent = header,
		})

		-- Logo avatar (ASSET_REQUIRED falls back to solid disc)
		local avatar = make("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(52, 44),
			Size = UDim2.fromOffset(48, 48),
			Parent = header,
		})
		corner(avatar, 24)
		if AVATAR_ASSET ~= "" then
			avatar.Image = AVATAR_ASSET
			avatar.BackgroundTransparency = 1
		end

		local title = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(112, 16),
			Size = UDim2.new(0, 190, 0, 32),
			Text = tostring(config.Title or "Oxiasidian"),
			TextColor3 = window.Theme.Text,
			TextSize = 22,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = header,
		})

		local subtitle = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			Position = UDim2.fromOffset(114, 48),
			Size = UDim2.new(0, 190, 0, 14),
			Text = string.upper(tostring(config.Subtitle or "Blox Fruit") .. " – Field Log v" .. tostring(GUI_VERSION)),
			TextColor3 = window.Theme.Sub,
			TextSize = 9,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = header,
		})

		-- Search box
		local searchRow = make("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = window.Theme.Surface,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -168, 0, 22),
			Size = UDim2.new(0, 200, 0, 40),
			Parent = header,
		})
		corner(searchRow, 10)
		local searchEdge = outline(searchRow, window.Theme.Border, 1, 0.4)

		local searchBox = make("TextBox", {
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			Font = Enum.Font.Gotham,
			PlaceholderColor3 = window.Theme.Sub,
			PlaceholderText = "Search...",
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -32, 1, 0),
			Text = "",
			TextColor3 = window.Theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = searchRow,
		})

		local clearSearch = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			Text = "×",
			TextColor3 = window.Theme.Sub,
			TextSize = 14,
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

		-- Topbar buttons: A = collapse sidebar, i = credits, X = hide
		local actionsRow = make("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 0, 22),
			Size = UDim2.fromOffset(168, 40),
			Parent = header,
		})
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = actionsRow,
		})

		local function makeTopButton(text, tooltip, onClick, danger)
			local b = make("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = danger and window.Theme.Accent or window.Theme.Surface,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Size = UDim2.fromOffset(40, 40),
				Text = text,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 15,
				Parent = actionsRow,
			})
			corner(b, 10)
			local bStroke = outline(b, danger and window.Theme.AccentHi or window.Theme.Border, 1, 0.3)

			b.MouseEnter:Connect(function()
				tween(b, { BackgroundColor3 = danger and window.Theme.AccentHi or window.Theme.CardHover }, 0.15)
			end)
			b.MouseLeave:Connect(function()
				tween(b, { BackgroundColor3 = danger and window.Theme.Accent or window.Theme.Surface }, 0.2)
			end)
			b.MouseButton1Click:Connect(onClick)

			bindTheme(window, b, {
				BackgroundColor3 = function(t) return danger and t.Accent or t.Surface end,
			})
			bindTheme(window, bStroke, { Color = function(t) return danger and t.AccentHi or t.Border end })
			return b
		end

		makeTopButton("A", "Collapse sidebar", function()
			window.SidebarCollapsed = not window.SidebarCollapsed
			if window.SidebarCollapsed then
				tween(window.Sidebar, { Size = UDim2.new(0, 0, 1, -88) }, 0.22)
				tween(mainContent, { Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 1, -88) }, 0.22)
			else
				tween(window.Sidebar, { Size = UDim2.new(0, 140, 1, -88) }, 0.22)
				tween(mainContent, { Position = UDim2.fromOffset(140, 88), Size = UDim2.new(1, -140, 1, -88) }, 0.22)
			end
		end, false)

		makeTopButton("i", "Credits", function()
			local lines = {}
			for _, person in ipairs(config.Credits or {}) do
				if type(person) == "table" then
					table.insert(lines, tostring(person.Name or "?") .. " - " .. tostring(person.Role or ""))
				else
					table.insert(lines, tostring(person))
				end
			end
			if #lines == 0 then
				table.insert(lines, "Oxiasidian Team")
			end
			window:Notify({
				Title = tostring(config.Title or "Oxiasidian") .. " - Credits",
				Description = table.concat(lines, "\n"),
			}, { Time = 7 })
		end, false)

		makeTopButton("×", "Close", function()
			window:Hide()
		end, true)

		---------------------------------------------------------------- sidebar
		local sidebar = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(0, 88),
			Size = UDim2.new(0, 140, 1, -88),
			Parent = main,
		})
		local sidebarEdge = outline(sidebar, window.Theme.Border, 1, 0.6)
		window.Sidebar = sidebar

		local tabList = make("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(10, 6),
			ScrollBarImageColor3 = window.Theme.Accent,
			ScrollBarThickness = 2,
			Size = UDim2.new(1, -20, 1, -20),
			Parent = sidebar,
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabList,
		})
		window.TabList = tabList

		------------------------------------------------------------ content area
		local mainContent = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(140, 88),
			Size = UDim2.new(1, -140, 1, -88),
			Parent = main,
		})

		local contentArea = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(0, 80),
			Size = UDim2.new(1, 0, 1, -80),
			Parent = mainContent,
		})
		window.ContentArea = contentArea

		---------------------------------------------------------------- hero
		local hero = make("Frame", {
			BackgroundColor3 = window.Theme.AccentLo,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 70),
			Visible = false,
			Parent = mainContent,
		})
		corner(hero, 12)
		local heroGrad = shade(hero, window.Theme.Accent, window.Theme.AccentLo, 8)
		for i = 1, 3 do
			local shard = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = window.Theme.AccentLo,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -70 - (i - 1) * 66, 0.5, 0),
				Rotation = 24,
				Size = UDim2.fromOffset(90, 26),
				Parent = hero,
			})
		end
		local heroX1 = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -52, 0.5, 0),
			Rotation = 45,
			Size = UDim2.fromOffset(34, 5),
			Parent = hero,
		})
		local heroX2 = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -52, 0.5, 0),
			Rotation = -45,
			Size = UDim2.fromOffset(34, 5),
			Parent = hero,
		})
		local heroTitle = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(22, 14),
			Size = UDim2.new(1, -220, 0, 30),
			Text = "HOME",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 26,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = hero,
		})
		local heroSub = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(22, 44),
			Size = UDim2.new(1, -220, 0, 18),
			Text = "",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.25,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = hero,
		})
		window.Hero = hero
		window.HeroTitle = heroTitle
		window.HeroSub = heroSub
		window.HeroIconHolder = hero

		------------------------------------------------------------ dragging
		local dragging = false
		local dragStart, startPos
		header.InputBegan:Connect(function(input)
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
				local newX = startPos.X.Offset + delta.X
				local newY = startPos.Y.Offset + delta.Y
				local cam = workspace.CurrentCamera
				if cam then
					local currentScale = uiScale and uiScale.Scale or 1
					local halfW = (window.NormalSize.X * currentScale) / 2
					local halfH = (window.NormalSize.Y * currentScale) / 2
					local vp = cam.ViewportSize
					local limitX = math.max(20, (vp.X / 2) - halfW * 0.3)
					local limitY = math.max(20, (vp.Y / 2) - halfH * 0.3)
					newX = math.clamp(newX, -limitX, limitX)
					newY = math.clamp(newY, -limitY, limitY)
				end
				tween(main, {
					Position = UDim2.new(
						startPos.X.Scale,
						newX,
						startPos.Y.Scale,
						newY
					)
				}, 0.06, Enum.EasingStyle.Linear)
			end
		end)

		------------------------------------------------------------ responsive
		local function updateResponsive()
			local cam = workspace.CurrentCamera
			if not cam then return end
			local viewport = cam.ViewportSize
			local isTouch = UserInputService.TouchEnabled

			main.Size = UDim2.fromOffset(window.NormalSize.X, window.NormalSize.Y)

			-- Safe margins: mobile needs extra margin for Roblox topbar and touch edges
			local marginX = isTouch and 0.92 or 0.96
			local marginY = isTouch and 0.88 or 0.92

			local scaleX = (viewport.X * marginX) / window.NormalSize.X
			local scaleY = (viewport.Y * marginY) / window.NormalSize.Y

			-- PC: cap at window.BaseUIScale (compact ~0.82) so it stays clean and never too big
			-- Mobile: shrink smoothly to fit screen bounds so 100% of UI is visible
			local maxScale = window.BaseUIScale or (isTouch and 0.75 or 0.82)
			local fit = math.min(scaleX, scaleY, maxScale)

			-- Clamp to 0.25 minimum so small phones (including portrait) never crop the UI
			fit = math.clamp(fit, 0.25, 1.2)

			if uiScale then
				uiScale.Scale = fit
			end

			-- Auto-collapse or compact sidebar on narrow screens or mobile portrait to maximize content space
			local isNarrow = (viewport.X < 760) or (isTouch and viewport.X < viewport.Y)
			if isNarrow then
				if not window.SidebarCollapsed then
					tween(sidebar, { Size = UDim2.new(0, 50, 1, -88) }, 0.2)
					tween(mainContent, { Position = UDim2.fromOffset(50, 88), Size = UDim2.new(1, -50, 1, -88) }, 0.2)
				end
			else
				if not window.SidebarCollapsed then
					tween(sidebar, { Size = UDim2.new(0, 140, 1, -88) }, 0.2)
					tween(mainContent, { Position = UDim2.fromOffset(140, 88), Size = UDim2.new(1, -140, 1, -88) }, 0.2)
				end
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

		-- Version toast so every run shows which library build is live
		pcall(function()
			window:Notify({
				Title = "Oxiasidian UI",
				Description = "v" .. tostring(GUI_VERSION) .. " loaded",
			}, { Time = 3 })
		end)

		-- Theme Bindings for Main Window
		bindTheme(window, main, { BackgroundColor3 = function(t) return t.Background end })
		bindTheme(window, mainEdge, { Color = function(t) return t.Accent end })
		bindTheme(window, avatar, { BackgroundColor3 = function(t) return t.Accent end })
		bindTheme(window, title, { TextColor3 = function(t) return t.Text end })
		bindTheme(window, subtitle, { TextColor3 = function(t) return t.Sub end })
		bindTheme(window, searchRow, { BackgroundColor3 = function(t) return t.Surface end })
		bindTheme(window, searchEdge, { Color = function(t) return t.Border end })
		bindTheme(window, searchBox, { TextColor3 = function(t) return t.Text end, PlaceholderColor3 = function(t) return t.Sub end })

		bindTheme(window, heroGrad, { Color = function(t) return ColorSequence.new(t.Accent, t.AccentLo) end })

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
	module.Build = BuildOxiasidianGUI

	return module
end

local defaultBuilt = BuildOxiasidianGUI()

return {
	Build = BuildOxiasidianGUI,
	CreateWindow = function(...) return defaultBuilt.CreateWindow(...) end,
	Notification = defaultBuilt.Notification,
	Themes = defaultBuilt.Themes,
	ThemeOrder = defaultBuilt.ThemeOrder,
	Version = defaultBuilt.Version,
}

