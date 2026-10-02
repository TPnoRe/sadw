-- ==============================================================================
--  Quantum Onyx - NEW GUI LIBRARY  (QuantumOnyxGUI.lua)
-- ==============================================================================
--  หน้าต่างเมนูแบบใหม่ ทำงานได้ครบทุกฟังก์ชันเหมือนเดิม แต่หน้าตาดีกว่า
--  ไม่ต้องโหลดไฟล์รูปไอคอนจากอินเทอร์เน็ต และไม่ต้องพึ่งไลบรารีภายนอก
--
--  API ที่รองรับ (ตรงกับที่สคริปต์เดิมเรียกใช้ทั้งหมด)
--    QN:CreateWindow(cfg)             -> window
--    window:AddTab(name, icon)        -> tab
--    tab:addSection(name?)            -> section
--    section:addMenu(name)            -> menu (อะคอร์เดียน เปิด/ปิดได้)
--    menu:addToggle(title, def, cb, locked, desc, saveKey)   -> toggle .Update(v)
--    menu:addSlider(title, def, min, max, cb, locked, step, saveKey) -> slider .Update(v)
--    menu:addDropdown(title, def, opts, cb, locked, desc, saveKey)     -> dropdown .Refresh(opts)
--    menu:addTextbox(title, cb, confirmText, saveKey)       -> textbox .Update(v)
--    menu:addButton(title, cb, locked)                      -> button
--    menu:addButtonGrid(title, items)                       -> grid
--    menu:addLabel(title, desc)                             -> label .RefreshTitle/.RefreshDesc
--    QN.Notification:Notify({Title,Description,Buttons,Id}, {Time})
--
--  ของใหม่ที่เพิ่มเข้ามา
--    1. ช่องค้นหา กรองไอเทมทุกแท็บแบบทันที + สลับไปแท็บที่เจอคำที่ค้น
--    2. สลับธีมสี 5 แบบสด ๆ (Purple / Ocean / Crimson / Emerald / Midnight)
--    3. ลากย้ายหน้าต่าง, ปรับขนาด, ย่อ/ขยาย, ปุ่มซ่อนหน้าต่าง, คีย์ลัด RightShift
--    4. HUD ล่างหน้าต่าง แสดง เลเวล / เบลี / เศษเศษ / FPS แบบเรียลไทม์
--    5. ระบบแจ้งเตือน Toast มีปุ่มกด มีแถบเวลา ตัวเดิมไม่ซ้ำให้อัตโนมัติ
--    6. ปุ่ม Stop All หยุดฟาร์มทุกอันพร้อมกัน
--    7. บันทึก/จดค่าตั้งอัตโนมัติ (writefile/readfile ไม่มีก็ใช้ getgenv แทน)
-- ==============================================================================

local GUI_VERSION = "1.0.0"

local function BuildQuantumGUI()

	----------------------------------------------------------------- services
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	------------------------------------------------------------------ helpers
	local function make(className, props)
		local object = Instance.new(className)

		if type(props) == "table" then
			for key, value in pairs(props) do
				object[key] = value
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

	local function shade(object, from, to, rotation)
		return make("UIGradient", {
			Color = ColorSequence.new(from or Color3.new(1, 1, 1), to or from or Color3.new(1, 1, 1)),
			Rotation = rotation or 0,
			Parent = object,
		})
	end

	local function tween(object, props, time, style, direction)
		local anim = TweenService:Create(
			object,
			TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
			props
		)

		anim:Play()

		return anim
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

	------------------------------------------------------------------- themes
	local THEMES = {
		Purple = {
			Main = Color3.fromRGB(15, 13, 26),
			Panel = Color3.fromRGB(23, 20, 40),
			Card = Color3.fromRGB(31, 27, 52),
			CardHover = Color3.fromRGB(44, 38, 74),
			Track = Color3.fromRGB(40, 35, 64),
			Border = Color3.fromRGB(58, 50, 92),
			Text = Color3.fromRGB(238, 236, 249),
			Sub = Color3.fromRGB(154, 147, 184),
			Accent = Color3.fromRGB(150, 96, 255),
			Accent2 = Color3.fromRGB(216, 122, 255),
		},
		Ocean = {
			Main = Color3.fromRGB(9, 17, 25),
			Panel = Color3.fromRGB(14, 28, 39),
			Card = Color3.fromRGB(20, 38, 52),
			CardHover = Color3.fromRGB(29, 55, 73),
			Track = Color3.fromRGB(27, 48, 64),
			Border = Color3.fromRGB(42, 74, 98),
			Text = Color3.fromRGB(232, 244, 250),
			Sub = Color3.fromRGB(138, 168, 186),
			Accent = Color3.fromRGB(45, 190, 255),
			Accent2 = Color3.fromRGB(125, 235, 255),
		},
		Crimson = {
			Main = Color3.fromRGB(23, 12, 14),
			Panel = Color3.fromRGB(34, 16, 19),
			Card = Color3.fromRGB(47, 22, 26),
			CardHover = Color3.fromRGB(67, 31, 36),
			Track = Color3.fromRGB(59, 28, 32),
			Border = Color3.fromRGB(94, 41, 46),
			Text = Color3.fromRGB(250, 236, 236),
			Sub = Color3.fromRGB(189, 151, 153),
			Accent = Color3.fromRGB(255, 74, 92),
			Accent2 = Color3.fromRGB(255, 155, 125),
		},
		Emerald = {
			Main = Color3.fromRGB(9, 24, 19),
			Panel = Color3.fromRGB(13, 34, 27),
			Card = Color3.fromRGB(18, 46, 36),
			CardHover = Color3.fromRGB(27, 65, 50),
			Track = Color3.fromRGB(25, 56, 44),
			Border = Color3.fromRGB(39, 86, 66),
			Text = Color3.fromRGB(232, 250, 240),
			Sub = Color3.fromRGB(141, 185, 163),
			Accent = Color3.fromRGB(46, 220, 140),
			Accent2 = Color3.fromRGB(150, 255, 190),
		},
		Midnight = {
			Main = Color3.fromRGB(10, 11, 14),
			Panel = Color3.fromRGB(17, 19, 24),
			Card = Color3.fromRGB(24, 27, 34),
			CardHover = Color3.fromRGB(35, 39, 48),
			Track = Color3.fromRGB(31, 34, 42),
			Border = Color3.fromRGB(50, 55, 66),
			Text = Color3.fromRGB(232, 235, 242),
			Sub = Color3.fromRGB(139, 147, 164),
			Accent = Color3.fromRGB(120, 165, 255),
			Accent2 = Color3.fromRGB(190, 210, 255),
		},
	}

	local THEME_ORDER = { "Purple", "Ocean", "Crimson", "Emerald", "Midnight" }

	-- ไอคอนใช้สัญลักษณ์ Geometric Shapes (เรนเดอร์ได้แน่นอน ไม่ต้องพึ่งไฟล์รูป)
	local GLYPHS = {
		home = "◈",
		swords = "◆",
		ship = "▲",
		user = "◉",
		visual = "◐",
		raid = "▣",
		rabbit = "◑",
		map = "◍",
		cart = "◎",
		misc = "◕",
		cat = "◔",
	}

	local function glyphFor(icon)
		if type(icon) ~= "string" then
			return "◈"
		end

		local key = string.lower(icon)
		key = key:gsub("%-.*$", "")
		key = key:gsub("_", "")

		if GLYPHS[key] then
			return GLYPHS[key]
		end

		for name in pairs(GLYPHS) do
			if string.find(key, name, 1, true) then
				return GLYPHS[name]
			end
		end

		return string.upper(string.sub(icon, 1, 1))
	end

	------------------------------------------------------------------ config
	local Config = { Name = "QuantumOnyxGUI", Data = {} }

	local function configLoad(name)
		local result = {}

		if type(writefile) == "function" and type(readfile) == "function" then
			local ok, raw = pcall(readfile, name .. ".json")

			if ok and type(raw) == "string" and raw ~= "" then
				local decodedOk, decoded = pcall(function()
					return HttpService:JSONDecode(raw)
				end)

				if decodedOk and type(decoded) == "table" then
					result = decoded
				end
			end
		end

		if next(result) == nil and type(getgenv) == "function" then
			local shared = getgenv()
			local saved = shared["QN_CFG_" .. name]

			if type(saved) == "table" then
				result = saved
			end
		end

		return result
	end

	local function configSave(name, data)
		if type(writefile) == "function" then
			pcall(function()
				writefile(name .. ".json", HttpService:JSONEncode(data))
			end)
		end

		if type(getgenv) == "function" then
			pcall(function()
				getgenv()["QN_CFG_" .. name] = data
			end)
		end
	end

	------------------------------------------------------------ search index
	-- ทุกไอเทมที่สร้างจะถูกลงทะเบียนไว้ เพื่อให้ช่องค้นหากรองได้ทันที
	local SearchIndex = {}
	local CurrentTab = nil

	local function indexElement(object, keywords, tab)
		table.insert(SearchIndex, {
			Object = object,
			Keywords = string.lower(keywords or ""),
			Tab = tab,
		})
	end

	local function applyFilter(text)
		local needle = string.lower(text or "")
		local firstHit = nil

		for _, entry in ipairs(SearchIndex) do
			local hit = (needle == "") or (string.find(entry.Keywords, needle, 1, true) ~= nil)

			if entry.Object and entry.Object.Parent then
				entry.Object.Visible = hit
			end

			if hit and not firstHit and entry.Tab then
				firstHit = entry.Tab
			end
		end

		return firstHit
	end

	------------------------------------------------------- slider drag (once)
	local activeSlider = nil

	UserInputService.InputChanged:Connect(function(input)
		if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local step = activeSlider()

			if step then
				step()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			activeSlider = nil
		end
	end)

	-- ================================================================ ELEMENTS
	local Element = {}
	Element.__index = Element

	-- ลงทะเบียนตัวเลขสีไว้กับหน้าต่าง เพื่อให้สลับธีมแล้วทุกชิ้นเปลี่ยนสีพร้อมกัน
	local function bind(window, object, props)
		if object == nil then
			return
		end

		local painter = function(theme)
			for key, getter in pairs(props) do
				object[key] = getter(theme)
			end
		end

		window.Painters[#window.Painters + 1] = painter

		painter(window.Theme)
	end

	------------------------------------------------------------------ toggle
	function Element:addToggle(title, default, callback, locked, description, saveKey)
		local window = self.Window
		local theme = window.Theme

		local descriptionText = (type(description) == "string") and description or nil
		local height = descriptionText and 46 or 34

		local row = make("TextButton", {
			AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = theme.Main,
			BackgroundTransparency = 0.96,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, height),
			Parent = self.Body,
		})

		corner(row, 7)

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Size = UDim2.new(1, -68, 0, 20),
			Text = tostring(title),
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 10, 0, descriptionText and 4 or 0.5),
			AnchorPoint = descriptionText and Vector2.new(0, 0) or Vector2.new(0, 0.5),
			Parent = row,
		})

		local desc = nil

		if descriptionText then
			desc = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				RichText = true,
				Size = UDim2.new(1, -68, 0, 26),
				Position = UDim2.new(0, 10, 0, 20),
				Text = descriptionText,
				TextSize = 11,
				TextTransparency = 0.4,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
		end

		local track = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = theme.Track,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(46, 24),
			Parent = row,
		})

		corner(track, 12)

		local fill = make("Frame", {
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 1, -4),
			Parent = track,
		})

		corner(fill, 10)

		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			Parent = track,
		})

		corner(knob, 9)

		local halo = make("UIStroke", {
			Color = theme.Accent,
			Thickness = 3,
			Transparency = 1,
			Parent = track,
		})

		local state = default and true or false
		local isLocked = locked and true or false

		bind(window, row, {
			BackgroundColor3 = function(t) return t.Main end,
		})

		bind(window, label, {
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, desc, {
			TextColor3 = function(t) return t.Sub end,
		})

		bind(window, track, {
			BackgroundColor3 = function(t) return state and t.Accent or t.Track end,
		})

		bind(window, fill, {
			BackgroundColor3 = function(t) return t.Accent end,
		})

		bind(window, halo, {
			Color = function(t) return t.Accent end,
		})

		local function paint()
			knob.Position = state and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			halo.Transparency = state and 0.5 or 1
		end

		local toggle = {}

		function toggle.Update(a, b)
			local value, silent

			if a == toggle then
				value = b
			else
				value = a
				silent = b
			end

			state = value and true or false

			paint()
			track.BackgroundColor3 = state and window.Theme.Accent or window.Theme.Track

			if saveKey then
				Config.Data[saveKey] = state
				configSave(Config.Name, Config.Data)
			end

			if not silent and type(callback) == "function" then
				pcall(callback, state)
			end

			return state
		end

		function toggle.GetValue()
			return state
		end

		function toggle.SetLocked(value)
			isLocked = value and true or false

			label.TextTransparency = isLocked and 0.45 or 0
			track.BackgroundTransparency = isLocked and 0.5 or 0
		end

		if isLocked then
			label.TextTransparency = 0.45
			track.BackgroundTransparency = 0.5
		end

		row.MouseEnter:Connect(function()
			if not isLocked then
				tween(row, { BackgroundTransparency = 0.9 }, 0.14)
			end
		end)

		row.MouseLeave:Connect(function()
			tween(row, { BackgroundTransparency = 0.96 }, 0.2)
		end)

		row.MouseButton1Click:Connect(function()
			if isLocked then
				return
			end

			toggle.Update(not state)
		end)

		paint()

		indexElement(row, tostring(title), CurrentTab)

		-- ค่าที่เคยบันทึกไว้: ใช้ค่าเดิมแล้วสั่ง callback ให้ฟาร์มทำงานต่อ
		if saveKey and Config.Data[saveKey] ~= nil then
			local saved = Config.Data[saveKey] and true or false

			if saved ~= state then
				state = saved

				paint()
				track.BackgroundColor3 = state and window.Theme.Accent or window.Theme.Track

				if type(callback) == "function" then
					task.defer(function()
						pcall(callback, state)
					end)
				end
			end
		end

		return toggle
	end

	---------------------------------------------------------------- dropdown
	function Element:addDropdown(title, default, options, callback, locked, description, saveKey)
		local window = self.Window
		local theme = window.Theme

		local descriptionText = (type(description) == "string") and description or nil
		local multi = type(default) == "table"
		local items = (type(options) == "table") and options or {}

		local labels = {}
		local values = {}

		for index, value in ipairs(items) do
			local label = value

			if type(value) == "table" then
				label = value.Label or value.Name or value.name or tostring(index)
			end

			labels[index] = tostring(label)
			values[index] = value
		end

		local selectedIndex = 1
		local selected = nil

		if multi then
			selected = {}

			if type(default) == "table" then
				for _, value in ipairs(default) do
					table.insert(selected, value)
				end
			end
		else
			if type(default) == "number" and items[default] ~= nil then
				selectedIndex = default
			elseif type(default) == "string" then
				for index, label in ipairs(labels) do
					if label == default then
						selectedIndex = index
						break
					end
				end
			end

			selected = labels[selectedIndex] or (labels[1] or "None")
		end

		local row = make("TextButton", {
			AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = theme.Main,
			BackgroundTransparency = 0.96,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, descriptionText and 46 or 34),
			Parent = self.Body,
		})

		corner(row, 7)

		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Size = UDim2.new(1, -170, 0, 20),
			Text = tostring(title),
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 10, 0, descriptionText and 4 or 0.5),
			AnchorPoint = descriptionText and Vector2.new(0, 0) or Vector2.new(0, 0.5),
			Parent = row,
		})

		local desc = nil

		if descriptionText then
			desc = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				RichText = true,
				Size = UDim2.new(1, -170, 0, 26),
				Position = UDim2.new(0, 10, 0, 20),
				Text = descriptionText,
				TextSize = 11,
				TextTransparency = 0.4,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
		end

		local pill = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = theme.Card,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(150, 26),
			Text = tostring(selected),
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})

		corner(pill, 7)
		inset(pill, 10, 0, 20, 0)

		local pillStroke = outline(pill, theme.Border, 1, 0.2)

		local chevron = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Text = "▾",
			TextColor3 = theme.Sub,
			TextSize = 12,
			Parent = pill,
		})

		-- ลิสต์ตัวเลือกลอยอยู่บนหน้าต่าง ไม่ใช่ในสกรอลลิสต์ จะได้ไม่ถูกตัดขอบ
		local list = make("ScrollingFrame", {
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.Panel,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ClipsDescendants = true,
			ScrollBarImageColor3 = theme.Accent,
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.fromOffset(156, 40),
			Visible = false,
			ZIndex = window.ZIndex + 30,
			Parent = window.Root,
		})

		corner(list, 8)
		inset(list, 4, 4, 4, 4)

		local listStroke = outline(list, theme.Accent, 1, 0.35)

		make("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = list,
		})

		make("UISizeConstraint", {
			MaxSize = Vector2.new(156, 200),
			MinSize = Vector2.new(156, 30),
			Parent = list,
		})

		local optionButtons = {}
		local isOpen = false

		local function setOpen(value)
			isOpen = value and true or false
			list.Visible = isOpen

			tween(chevron, { Rotation = isOpen and 180 or 0 }, 0.2)

			if not isOpen then
				return
			end

			local rootSize = window.Root.AbsoluteSize
			local originX = pill.AbsolutePosition.X + pill.AbsoluteSize.X - 156
			local originY = pill.AbsolutePosition.Y + pill.AbsoluteSize.Y + 6

			list.Position = UDim2.fromOffset(
				math.clamp(originX, 6, math.max(6, rootSize.X - 162)),
				math.clamp(originY, 6, math.max(6, rootSize.Y - math.min(#labels * 29, 200) - 12))
			)

			list.Size = UDim2.fromOffset(156, math.min(math.max(#labels * 29, 30), 200))

			tween(pill, { BackgroundColor3 = theme.CardHover }, 0.15)
		end

		local function highlight()
			for index, button in ipairs(optionButtons) do
				button.BackgroundTransparency = (not multi and index == selectedIndex) and 0.05 or 0.55
				button.TextColor3 = (not multi and index == selectedIndex) and window.Theme.Accent2 or window.Theme.Text
			end
		end

		local function commit(index)
			if multi then
				local raw = values[index]
				local key = (type(raw) == "table") and (raw.Name or raw.Label or tostring(index)) or raw
				local position = nil

				for k, existing in ipairs(selected) do
					if tostring(existing) == tostring(key) then
						position = k
						break
					end
				end

				if position then
					table.remove(selected, position)
				else
					table.insert(selected, key)
				end

				if #selected == 0 then
					pill.Text = "None"
				else
					local shown = {}

					for _, value in ipairs(selected) do
						table.insert(shown, tostring(value))
					end

					pill.Text = table.concat(shown, ", ")
				end
			else
				selectedIndex = index
				selected = labels[index]
				pill.Text = selected

				highlight()
				setOpen(false)
			end

			if saveKey then
				Config.Data[saveKey] = selected
				configSave(Config.Name, Config.Data)
			end

			if type(callback) == "function" then
				pcall(callback, selected)
			end
		end

		local function buildOptions()
			optionButtons = {}

			for _, child in ipairs(list:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			for index = 1, #labels do
				local option = make("TextButton", {
					BackgroundColor3 = theme.Card,
					BorderSizePixel = 0,
					Font = Enum.Font.GothamMedium,
					LayoutOrder = index,
					Size = UDim2.new(1, -6, 0, 26),
					Text = labels[index],
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = window.ZIndex + 31,
					Parent = list,
				})

				corner(option, 6)
				inset(option, 8, 0, 8, 0)

				option.MouseEnter:Connect(function()
					tween(option, { BackgroundTransparency = 0.15 }, 0.12)
				end)

				option.MouseLeave:Connect(function()
					tween(option, { BackgroundTransparency = 0.55 }, 0.18)
				end)

				option.MouseButton1Click:Connect(function()
					commit(index)
				end)

				optionButtons[index] = option
			end

			highlight()
		end

		buildOptions()

		bind(window, row, {
			BackgroundColor3 = function(t) return t.Main end,
		})

		bind(window, label, {
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, desc, {
			TextColor3 = function(t) return t.Sub end,
		})

		bind(window, pill, {
			BackgroundColor3 = function(t) return (isOpen) and t.CardHover or t.Card end,
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, pillStroke, {
			Color = function(t) return t.Border end,
		})

		bind(window, chevron, {
			TextColor3 = function(t) return t.Sub end,
		})

		bind(window, list, {
			BackgroundColor3 = function(t) return t.Panel end,
		})

		bind(window, listStroke, {
			Color = function(t) return t.Accent end,
		})

		row.MouseEnter:Connect(function()
			tween(row, { BackgroundTransparency = 0.9 }, 0.14)
		end)

		row.MouseLeave:Connect(function()
			tween(row, { BackgroundTransparency = 0.96 }, 0.2)
		end)

		local function toggleOpen()
			if locked then
				return
			end

			setOpen(not isOpen)
		end

		pill.MouseButton1Click:Connect(toggleOpen)
		row.MouseButton1Click:Connect(toggleOpen)

		if locked then
			label.TextTransparency = 0.45
			pill.TextTransparency = 0.45
			pill.Active = false
			row.Active = false
		end

		-- ปิดลิสต์เมื่อคลิกที่อื่น
		UserInputService.InputBegan:Connect(function(input)
			if not isOpen or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local point = Vector2.new(input.Position.X, input.Position.Y)
			local inside = false

			for _, object in ipairs({ pill, list }) do
				local box = object.AbsolutePosition
				local size = object.AbsoluteSize

				if point.X >= box.X and point.X <= box.X + size.X and point.Y >= box.Y and point.Y <= box.Y + size.Y then
					inside = true
					break
				end
			end

			if not inside then
				setOpen(false)
			end
		end)

		indexElement(row, tostring(title), CurrentTab)

		local dropdown = {}

		function dropdown.Update(a, b)
			local value

			if a == dropdown then
				value = b
			else
				value = a
			end
			if type(value) == "number" and labels[value] then
				selectedIndex = value
				selected = labels[value]
			elseif type(value) == "table" then
				selected = value
			elseif type(value) == "string" then
				selected = value

				for index, label in ipairs(labels) do
					if label == value then
						selectedIndex = index
						break
					end
				end
			else
				return
			end

			if multi then
				local shown = {}

				for _, item in ipairs(selected) do
					table.insert(shown, tostring(item))
				end

				pill.Text = #shown == 0 and "None" or table.concat(shown, ", ")
			else
				pill.Text = tostring(selected)
			end

			highlight()
		end

		function dropdown.Refresh(a)
			local newOptions

			if a == dropdown then
				newOptions = nil
			else
				newOptions = a
			end

			labels = {}
			values = {}

			for index, value in ipairs(newOptions or {}) do
				local label = value

				if type(value) == "table" then
					label = value.Label or value.Name or value.name or tostring(index)
				end

				labels[index] = tostring(label)
				values[index] = value
			end

			buildOptions()
			setOpen(false)
		end

		function dropdown.GetValue()
			return selected
		end

		if saveKey and Config.Data[saveKey] ~= nil then
			dropdown.Update(Config.Data[saveKey])
		end

		return dropdown
	end

	------------------------------------------------------------------ slider
	function Element:addSlider(title, default, min, max, callback, locked, step, saveKey)
		local window = self.Window
		local theme = window.Theme

		min = tonumber(min) or 0
		max = tonumber(max) or 100
		step = tonumber(step) or 1

		if max < min then
			max = min
		end

		local value = math.clamp(tonumber(default) or min, min, max)
		local isLocked = locked and true or false

		local row = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 52),
			Parent = self.Body,
		})

		local wash = make("TextButton", {
			BackgroundColor3 = theme.Main,
			BackgroundTransparency = 0.96,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = row,
		})

		corner(wash, 7)

		local name = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Size = UDim2.new(0.6, -10, 0, 18),
			Position = UDim2.fromOffset(10, 4),
			Text = tostring(title),
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = wash,
		})

		local readout = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -10, 0, 5),
			Size = UDim2.new(0.4, -10, 0, 18),
			Text = "",
			TextColor3 = theme.Accent2,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = wash,
		})

		local hit = make("TextButton", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Position = UDim2.new(0, 4, 1, -20),
			Size = UDim2.new(1, -8, 0, 20),
			Parent = row,
		})

		local track = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = theme.Track,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 6),
			Parent = hit,
		})

		corner(track, 3)

		local fill = make("Frame", {
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.5, 1),
			Parent = track,
		})

		corner(fill, 3)

		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(14, 14),
			Parent = track,
		})

		corner(knob, 7)

		local knobStroke = outline(knob, theme.Accent, 2, 0.2)

		bind(window, wash, {
			BackgroundColor3 = function(t) return t.Main end,
		})

		bind(window, name, {
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, readout, {
			TextColor3 = function(t) return t.Accent2 end,
		})

		bind(window, track, {
			BackgroundColor3 = function(t) return t.Track end,
		})

		bind(window, fill, {
			BackgroundColor3 = function(t) return t.Accent end,
		})

		bind(window, knobStroke, {
			Color = function(t) return t.Accent end,
		})

		local function paint()
			local ratio = 0

			if max > min then
				ratio = math.clamp((value - min) / (max - min), 0, 1)
			end

			fill.Size = UDim2.new(ratio, 0, 1, 0)
			knob.Position = UDim2.new(ratio, 0, 0.5, 0)

			if step < 1 then
				readout.Text = string.format("%g", value)
			else
				readout.Text = tostring(math.floor(value + 0.5))
			end
		end

		local function setValue(newValue, silent)
			value = math.clamp(tonumber(newValue) or min, min, max)

			if step and step > 0 and step < 1 then
				value = min + math.floor((value - min) / step + 0.5) * step
			end

			paint()

			if saveKey then
				Config.Data[saveKey] = value
				configSave(Config.Name, Config.Data)
			end

			if not silent and type(callback) == "function" then
				pcall(callback, value)
			end
		end

		local function readPointer()
			local width = hit.AbsoluteSize.X

			if width <= 0 then
				return
			end

			local mouse = UserInputService:GetMouseLocation()
			local ratio = math.clamp((mouse.X - hit.AbsolutePosition.X) / width, 0, 1)

			setValue(min + ratio * (max - min))
		end

		hit.MouseButton1Down:Connect(function()
			if isLocked then
				return
			end

			activeSlider = readPointer

			readPointer()
		end)

		wash.MouseEnter:Connect(function()
			if not isLocked then
				tween(wash, { BackgroundTransparency = 0.9 }, 0.14)
			end
		end)

		wash.MouseLeave:Connect(function()
			tween(wash, { BackgroundTransparency = 0.96 }, 0.2)
		end)

		if isLocked then
			name.TextTransparency = 0.45
			readout.TextTransparency = 0.45
			hit.Active = false
		end

		paint()

		indexElement(row, tostring(title), CurrentTab)

		local slider = {}

		function slider.Update(a, b)
			local newValue

			if a == slider then
				newValue = b
			else
				newValue = a
			end

			setValue(newValue, true)
		end

		function slider.GetValue()
			return value
		end

		if saveKey and tonumber(Config.Data[saveKey]) ~= nil then
			setValue(tonumber(Config.Data[saveKey]), true)
		end

		return slider
	end

	----------------------------------------------------------------- textbox
	function Element:addTextbox(title, callback, confirmText, saveKey)
		local window = self.Window
		local theme = window.Theme

		local row = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 42),
			Parent = self.Body,
		})

		local name = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Size = UDim2.new(1, 0, 0, 16),
			Text = tostring(title),
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local box = make("TextBox", {
			BackgroundColor3 = theme.Main,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Enum.Font.Gotham,
			PlaceholderColor3 = theme.Sub,
			PlaceholderText = "type here...",
			Size = UDim2.new(1, -68, 0, 28),
			Text = "",
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		corner(box, 7)
		inset(box, 10, 0, 10, 0)

		local boxStroke = outline(box, theme.Border, 1, 0.2)

		local confirm = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, 0, 0, 20),
			Size = UDim2.fromOffset(58, 28),
			Text = tostring(confirmText or "Save"),
			TextSize = 12,
			TextColor3 = Color3.new(1, 1, 1),
			Parent = row,
		})

		corner(confirm, 7)

		local function submit()
			if saveKey then
				Config.Data[saveKey] = box.Text
				configSave(Config.Name, Config.Data)
			end

			if type(callback) == "function" then
				pcall(callback, box.Text)
			end
		end

		confirm.MouseButton1Click:Connect(submit)
		box.FocusLost:Connect(function(entered)
			if entered then
				submit()
			end
		end)

		bind(window, name, {
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, box, {
			BackgroundColor3 = function(t) return t.Main end,
			TextColor3 = function(t) return t.Text end,
			PlaceholderColor3 = function(t) return t.Sub end,
		})

		bind(window, boxStroke, {
			Color = function(t) return t.Border end,
		})

		bind(window, confirm, {
			BackgroundColor3 = function(t) return t.Accent end,
		})

		indexElement(row, tostring(title), CurrentTab)

		local textbox = {}

		function textbox.Update(a, b)
			local value

			if a == textbox then
				value = b
			else
				value = a
			end

			box.Text = tostring(value or "")
		end

		function textbox.GetValue()
			return box.Text
		end

		if saveKey and type(Config.Data[saveKey]) == "string" then
			box.Text = Config.Data[saveKey]
		end

		return textbox
	end

	------------------------------------------------------------------ button
	function Element:addButton(title, callback, locked)
		local window = self.Window
		local theme = window.Theme

		local button = make("TextButton", {
			BackgroundColor3 = theme.Card,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamSemibold,
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 30),
			Text = "        " .. tostring(title),
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = self.Body,
		})

		corner(button, 7)
		inset(button, 6, 0, 10, 0)

		local edge = outline(button, theme.Border, 1, 0.55)

		local dot = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.fromOffset(6, 6),
			Parent = button,
		})

		corner(dot, 3)

		bind(window, button, {
			BackgroundColor3 = function(t) return t.Card end,
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, edge, {
			Color = function(t) return t.Border end,
		})

		bind(window, dot, {
			BackgroundColor3 = function(t) return t.Accent end,
		})

		button.MouseEnter:Connect(function()
			tween(button, { BackgroundTransparency = 0.08 }, 0.14)
			tween(dot, { Size = UDim2.fromOffset(10, 10) }, 0.18, Enum.EasingStyle.Back)
		end)

		button.MouseLeave:Connect(function()
			tween(button, { BackgroundTransparency = 0 }, 0.2)
			tween(dot, { Size = UDim2.fromOffset(6, 6) }, 0.2)
		end)

		if locked then
			button.TextTransparency = 0.5
			button.Active = false
		else
			button.MouseButton1Click:Connect(function()
				tween(button, { BackgroundTransparency = 0.35 }, 0.08)

				task.delay(0.1, function()
					if button.Parent then
						tween(button, { BackgroundTransparency = 0 }, 0.22)
					end
				end)

				if type(callback) == "function" then
					pcall(callback)
				end
			end)
		end

		indexElement(button, tostring(title), CurrentTab)

		return button
	end

	----------------------------------------------------------- button grid
	function Element:addButtonGrid(title, gridItems)
		local window = self.Window
		local theme = window.Theme

		local block = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = self.Body,
		})

		if type(title) == "string" and title ~= "" then
			local head = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Size = UDim2.new(1, 0, 0, 16),
				Text = string.upper(title),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = block,
			})

			bind(window, head, {
				TextColor3 = function(t) return t.Sub end,
			})
		end

		make("UIGridLayout", {
			CellPadding = UDim2.fromOffset(6, 6),
			CellSize = UDim2.new(0.5, -3, 0, 30),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = block,
		})

		for index, item in ipairs(gridItems or {}) do
			local entry = item

			if type(entry) == "string" then
				entry = { Label = entry }
			elseif type(entry) == "table" and type(entry.Label) ~= "string" and type(entry[1]) == "string" then
				entry = { Label = entry[1], Callback = entry[2], Tooltip = entry[3] }
			end

			local cell = make("TextButton", {
				BackgroundColor3 = theme.Card,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamSemibold,
				AutoButtonColor = false,
				LayoutOrder = index,
				Size = UDim2.fromScale(1, 1),
				Text = tostring(entry.Label or entry.Name or entry.Text or index),
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = block,
			})

			corner(cell, 7)
			inset(cell, 8, 0, 8, 0)

			local edge = outline(cell, theme.Border, 1, 0.55)

			bind(window, cell, {
				BackgroundColor3 = function(t) return t.Card end,
				TextColor3 = function(t) return t.Text end,
			})

			bind(window, edge, {
				Color = function(t) return t.Border end,
			})

			cell.MouseEnter:Connect(function()
				tween(cell, { BackgroundTransparency = 0.08 }, 0.14)
			end)

			cell.MouseLeave:Connect(function()
				tween(cell, { BackgroundTransparency = 0 }, 0.2)
			end)

			cell.MouseButton1Click:Connect(function()
				if type(entry.Callback) == "function" then
					pcall(entry.Callback)
				end
			end)
		end

		indexElement(block, tostring(title), CurrentTab)

		return block
	end

	------------------------------------------------------------------- label
	function Element:addLabel(title, description)
		local window = self.Window
		local theme = window.Theme

		local block = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = self.Body,
		})

		corner(block, 8)
		inset(block, 12, 9, 12, 9)

		local head = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			RichText = true,
			Size = UDim2.new(1, 0, 0, 16),
			Text = tostring(title or ""),
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = block,
		})

		local body = make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			RichText = true,
			Size = UDim2.new(1, 0, 0, 0),
			Text = tostring(description or ""),
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = block,
		})

		bind(window, block, {
			BackgroundColor3 = function(t) return t.Card end,
		})

		bind(window, head, {
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, body, {
			TextColor3 = function(t) return t.Sub end,
		})

		indexElement(block, tostring(title or ""), CurrentTab)

		local label = {}

		function label.RefreshTitle(a, b)
			local text

			if a == label then
				text = b
			else
				text = a
			end

			if head.Parent then
				head.Text = tostring(text or "")
			end
		end

		function label.RefreshDesc(a, b)
			local text

			if a == label then
				text = b
			else
				text = a
			end

			if body.Parent then
				body.Text = tostring(text or "")
			end
		end

		return label
	end

	-- ================================================================= MENU
	local Menu = {}
	Menu.__index = Menu

	function Menu:addToggle(...)
		return Element.addToggle(self, ...)
	end

	function Menu:addButton(...)
		return Element.addButton(self, ...)
	end

	function Menu:addLabel(...)
		return Element.addLabel(self, ...)
	end

	function Menu:addButtonGrid(...)
		return Element.addButtonGrid(self, ...)
	end

	function Menu:addDropdown(...)
		return Element.addDropdown(self, ...)
	end

	function Menu:addSlider(...)
		return Element.addSlider(self, ...)
	end

	function Menu:addTextbox(...)
		return Element.addTextbox(self, ...)
	end

	local function makeMenu(parent, name, window)
		local theme = window.Theme

		local block = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = parent,
		})

		corner(block, 10)
		inset(block, 10, 6, 10, 10)

		local edge = outline(block, theme.Border, 1, 0.65)

		make("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = block,
		})

		local header = make("TextButton", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 26),
			Parent = block,
		})

		local bar = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(4, 0),
			Size = UDim2.fromOffset(3, 14),
			Parent = header,
		})

		corner(bar, 2)

		local title = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -40, 1, 0),
			Text = tostring(name or "Menu"),
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = header,
		})

		local chevron = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -4, 0.5, 0),
			Rotation = 0,
			Size = UDim2.fromOffset(16, 16),
			Text = "▾",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = header,
		})

		local body = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = block,
		})

		make("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = body,
		})

		inset(body, 0, 4, 0, 2)

		local clip = make("UISizeConstraint", {
			MaxSize = Vector2.new(10000, 0),
			MinSize = Vector2.new(0, 0),
			Parent = body,
		})

		bind(window, block, {
			BackgroundColor3 = function(t) return t.Card end,
		})

		bind(window, edge, {
			Color = function(t) return t.Border end,
		})

		bind(window, title, {
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, chevron, {
			TextColor3 = function(t) return t.Sub end,
		})

		local menu = setmetatable({
			Frame = block,
			Body = body,
			Header = header,
			Title = title,
			Window = window,
			Theme = window.Theme,
			Open = false,
			Clip = clip,
			Chevron = chevron,
			Bar = bar,
		}, Menu)

		local function setOpen(value)
			menu.Open = value and true or false

			tween(clip, { MaxSize = Vector2.new(10000, menu.Open and 10000 or 0) }, 0.24)
			tween(chevron, { Rotation = menu.Open and 180 or 0 }, 0.24)
			tween(bar, { BackgroundTransparency = menu.Open and 0 or 0.75 }, 0.2)
		end

		function menu.SetOpen(a, b)
			local value

			if a == menu then
				value = b
			else
				value = a
			end

			setOpen(value)
		end

		header.MouseButton1Click:Connect(function()
			setOpen(not menu.Open)
		end)

		indexElement(block, tostring(name or "menu"), CurrentTab)

		return menu
	end

	-- ============================================================== SECTION
	local Section = {}
	Section.__index = Section

	function Section:addMenu(name)
		return makeMenu(self.Body, name, self.Window)
	end

	local function makeSection(parent, name, window)
		local theme = window.Theme

		local block = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = parent,
		})

		make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = block,
		})

		local header = nil

		if type(name) == "string" and name ~= "" then
			header = make("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Size = UDim2.new(1, 0, 0, 16),
				Text = string.upper(name),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = block,
			})

			bind(window, header, {
				TextColor3 = function(t) return t.Sub end,
			})

			local rule = make("Frame", {
				BackgroundColor3 = theme.Border,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1),
				Parent = block,
			})

			bind(window, rule, {
				BackgroundColor3 = function(t) return t.Border end,
			})
		end

		local body = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = block,
		})

		make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = body,
		})

		return setmetatable({
			Frame = block,
			Body = body,
			Header = header,
			Window = window,
			Theme = window.Theme,
		}, Section)
	end

	-- ================================================================== TAB
	local Tab = {}
	Tab.__index = Tab

	function Tab:addSection(name)
		return makeSection(self.Body, name, self.Window)
	end

	local function makeTab(window, name, icon)
		local frame = make("ScrollingFrame", {
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarImageColor3 = window.Theme.Accent,
			ScrollBarThickness = 4,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = window.Content,
		})

		inset(frame, 10, 10, 10, 10)

		local body = make("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = frame,
		})

		make("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = body,
		})

		local tab = setmetatable({
			Name = name,
			Icon = icon,
			Frame = frame,
			Body = body,
			Window = window,
			Theme = window.Theme,
		}, Tab)

		CurrentTab = tab

		table.insert(window.Tabs, tab)

		return tab
	end

	-- ========================================================= NOTIFICATIONS
	local function buildToaster(window)
		local function notify(data, options)
			data = data or {}
			options = options or {}

			local id = data.Id
			local duration = math.max(tonumber(options.Time) or 5, 1.5)
			local buttons = data.Buttons
			local theme = window.Theme

			if id and window.Toasts[id] then
				pcall(function()
					window.Toasts[id]:Destroy()
				end)

				window.Toasts[id] = nil
			end

			local toast = make("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = theme.Panel,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Size = UDim2.fromOffset(320, 0),
				Visible = false,
				ZIndex = window.ZIndex + 40,
				Parent = window.ToastHost,
			})

			corner(toast, 10)

			local toastEdge = outline(toast, theme.Border, 1, 0.2)

			make("UISizeConstraint", {
				MaxSize = Vector2.new(320, 320),
				MinSize = Vector2.new(320, 54),
				Parent = toast,
			})

			-- กรอบเลื่อนเข้า: UIListLayout ของ toastHost จัดตำแหน่งให้อยู่แล้ว
			-- การเลื่อนจึงทำบนกรอบนี้แทน เพื่อไม่ให้ชนกับ layout
			local slide = make("Frame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(26, 0),
				Size = UDim2.new(1, 0, 0, 0),
				Parent = toast,
			})

			make("UISizeConstraint", {
				MaxSize = Vector2.new(10000, 320),
				MinSize = Vector2.new(0, 54),
				Parent = slide,
			})

			local accent = make("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = theme.Accent,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.fromOffset(4, 0),
				Parent = slide,
			})

			make("UISizeConstraint", {
				MaxSize = Vector2.new(4, 60),
				MinSize = Vector2.new(4, 22),
				Parent = accent,
			})

			corner(accent, 2)

			local stack = make("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(22, 10),
				Size = UDim2.new(1, -34, 0, 0),
				Parent = slide,
			})

			make("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = stack,
			})

			local head = make("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				LayoutOrder = 1,
				RichText = true,
				Size = UDim2.new(1, 0, 0, 16),
				Text = tostring(data.Title or "Quantum"),
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = stack,
			})

			local message = make("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				LayoutOrder = 2,
				RichText = true,
				Size = UDim2.new(1, 0, 0, 0),
				Text = tostring(data.Description or ""),
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = stack,
			})

			if type(buttons) == "table" and #buttons > 0 then
				local row = make("Frame", {
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Size = UDim2.new(1, 0, 0, 26),
					Parent = stack,
				})

				make("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = row,
				})

				for index, entry in ipairs(buttons) do
					local item = entry

					if type(item) == "string" then
						item = { Text = item }
					end

					local cell = make("TextButton", {
						AutoButtonColor = false,
						BackgroundColor3 = theme.Accent,
						BorderSizePixel = 0,
						Font = Enum.Font.GothamBold,
						LayoutOrder = index,
						Size = UDim2.fromOffset(0, 26),
						Text = tostring(item.Text or "OK"),
						TextSize = 12,
						TextColor3 = Color3.new(1, 1, 1),
						Parent = row,
					})

					corner(cell, 6)
					inset(cell, 14, 0, 14, 0)

					make("UISizeConstraint", {
						MaxSize = Vector2.new(240, 26),
						MinSize = Vector2.new(58, 26),
						Parent = cell,
					})

					cell.MouseButton1Click:Connect(function()
						if type(item.Callback) == "function" then
							pcall(item.Callback)
						end

						pcall(function()
							toast:Destroy()
						end)
					end)
				end
			end

			local progress = make("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = theme.Accent,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 3),
				Parent = slide,
			})

			corner(progress, 2)

			bind(window, toast, {
				BackgroundColor3 = function(t) return t.Panel end,
			})

			bind(window, toastEdge, {
				Color = function(t) return t.Border end,
			})

			bind(window, accent, {
				BackgroundColor3 = function(t) return t.Accent end,
			})

			bind(window, head, {
				TextColor3 = function(t) return t.Text end,
			})

			bind(window, message, {
				TextColor3 = function(t) return t.Sub end,
			})

			bind(window, progress, {
				BackgroundColor3 = function(t) return t.Accent end,
			})

			if id then
				window.Toasts[id] = toast
			end

			task.delay(0.04, function()
				if toast.Parent then
					toast.Visible = true

					tween(slide, { Position = UDim2.fromOffset(0, 0) }, 0.32)
				end
			end)

			tween(progress, { Size = UDim2.new(0, 0, 0, 3) }, duration, Enum.EasingStyle.Linear)

			task.delay(duration, function()
				if not toast.Parent then
					return
				end

				tween(slide, { Position = UDim2.fromOffset(26, 0) }, 0.25)
				tween(toast, { BackgroundTransparency = 1 }, 0.25)

				task.delay(0.3, function()
					pcall(function()
						toast:Destroy()
					end)

					if id then
						window.Toasts[id] = nil
					end
				end)
			end)

			return toast
		end

		return notify
	end

	-- ================================================================ WINDOW
	local Window = {}
	Window.__index = Window

	function Window:AddTab(name, icon)
		local window = self
		local theme = window.Theme
		local tab = makeTab(window, tostring(name), glyphFor(icon))

		local cell = make("TextButton", {
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = theme.Card,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamSemibold,
			Size = UDim2.fromOffset(0, 32),
			Text = tab.Icon .. "   " .. tostring(name),
			TextSize = 12,
			Parent = window.TabStrip,
		})

		corner(cell, 8)
		inset(cell, 12, 0, 12, 0)

		local edge = outline(cell, theme.Border, 1, 0.5)

		local function select()
			window.ActiveTab = tab

			for _, other in ipairs(window.Tabs) do
				other.Frame.Visible = false

				if other.Cell then
					tween(other.Cell, {
						BackgroundColor3 = window.Theme.Card,
						TextColor3 = window.Theme.Sub,
					}, 0.15)
				end
			end

			tab.Frame.Visible = true

			tween(cell, {
				BackgroundColor3 = window.Theme.CardHover,
				TextColor3 = window.Theme.Text,
			}, 0.15)
		end

		bind(window, cell, {
			BackgroundColor3 = function(t) return (window.ActiveTab == tab) and t.CardHover or t.Card end,
			TextColor3 = function(t) return (window.ActiveTab == tab) and t.Text or t.Sub end,
		})

		bind(window, edge, {
			Color = function(t) return t.Border end,
		})

		cell.MouseButton1Click:Connect(select)

		cell.MouseEnter:Connect(function()
			tween(cell, { BackgroundTransparency = 0.1 }, 0.15)
		end)

		cell.MouseLeave:Connect(function()
			tween(cell, { BackgroundTransparency = 0 }, 0.2)
		end)

		tab.Cell = cell
		tab.Select = select

		return tab
	end

	function Window:SetTheme(name)
		if THEMES[name] == nil then
			return
		end

		self.Theme = THEMES[name]
		self.ThemeName = name

		for _, painter in ipairs(self.Painters) do
			pcall(painter, self.Theme)
		end

		if type(writefile) == "function" then
			pcall(function()
				writefile("QuantumOnyxTheme.txt", name)
			end)
		end
	end

	function Window:Notify(data, options)
		return self.Toaster(data or {}, options or {})
	end

	function Window:Show()
		self.Root.Visible = true
		self.Restore.Visible = false
	end

	function Window:Hide()
		self.Root.Visible = false
		self.Restore.Visible = true
	end

	function Window:Toggle()
		if self.Root.Visible then
			self:Hide()
		else
			self:Show()
		end
	end

	function Window:Destroy()
		if self.Gui and self.Gui.Parent then
			self.Gui:Destroy()
		end
	end

	function Window:Minimized(value)
		if type(self.Minimizer) == "function" then
			self.Minimizer(value)
		end
	end

	function Window:SaveConfig()
		return configSave(Config.Name, Config.Data)
	end

	function Window:OpenMenu()
		self:Show()

		return self.Root
	end

	------------------------------------------------------------------ build
	local function buildWindow(config)
		config = config or {}

		local themeName = config.Theme

		if THEMES[themeName] == nil then
			themeName = "Purple"
		end

		local saveName = tostring(config.SaveFile or "QuantumOnyxGUI")

		Config.Name = saveName
		Config.Data = configLoad(saveName)

		local old = playerGui:FindFirstChild("QuantumOnyxWindow")

		if old then
			old:Destroy()
		end

		local gui = make("ScreenGui", {
			DisplayOrder = 999,
			IgnoreGuiInset = false,
			Name = "QuantumOnyxWindow",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		})

		gui.Parent = playerGui

		local root = make("Frame", {
			Active = true,
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
			ZIndex = 10,
			Tabs = {},
			Toasts = {},
			Painters = {},
			NormalSize = Vector2.new(540, 660),
		}, Window)

		---------------------------------------------------------------- panel
		local main = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = window.Theme.Main,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(540, 660),
			Parent = root,
		})

		corner(main, 14)
		local mainGradient = shade(main, window.Theme.Card, window.Theme.Main, 90)
		window.MainEdge = outline(main, window.Theme.Border, 1, 0.15)

		make("UISizeConstraint", {
			MaxSize = Vector2.new(1000, 1000),
			MinSize = Vector2.new(400, 320),
			Parent = main,
		})

		make("UIDropShadow", {
			BlurRadius = 26,
			Color = Color3.new(0, 0, 0),
			Intensity = 0.45,
			Offset = Vector2.new(0, 10),
			SpreadRadius = 0,
			Transparency = 0.45,
			Parent = main,
		})

		window.Main = main

		------------------------------------------------------------- top bar
		local bar = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 54),
			Parent = main,
		})

		local accentBar = make("Frame", {
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 16, 1, -7),
			Size = UDim2.new(1, -32, 0, 3),
			Parent = bar,
		})

		corner(accentBar, 2)
		local accentGradient = shade(accentBar, window.Theme.Accent, window.Theme.Accent2, 0)

		local title = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(18, 9),
			Size = UDim2.fromOffset(280, 20),
			Text = tostring(config.Title or "Quantum Onyx"),
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = bar,
		})

		local subtitle = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(19, 28),
			Size = UDim2.fromOffset(280, 16),
			Text = tostring(config.Subtitle or ""),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = bar,
		})

		local version = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -18, 0, 16),
			Size = UDim2.fromOffset(86, 22),
			Text = tostring(config.Version or "v1.0"),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = bar,
		})

		corner(version, 6)

		local function iconButton(symbol, offset)
			local cell = make("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				AutoButtonColor = false,
				BackgroundColor3 = window.Theme.Card,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Position = UDim2.new(1, offset, 0, 16),
				Size = UDim2.fromOffset(28, 22),
				Text = symbol,
				TextSize = 13,
				Parent = bar,
			})

			corner(cell, 6)

			cell.MouseEnter:Connect(function()
				tween(cell, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
			end)

			cell.MouseLeave:Connect(function()
				tween(cell, { BackgroundColor3 = window.Theme.Card }, 0.2)
			end)

			bind(window, cell, {
				BackgroundColor3 = function(t) return t.Card end,
				TextColor3 = function(t) return t.Sub end,
			})

			return cell
		end

		local infoButton = iconButton("◔", -244)
		local themeButton = iconButton("◑", -210)
		local minimizeButton = iconButton("—", -176)
		local closeButton = iconButton("✕", -142)

		themeButton.MouseButton1Click:Connect(function()
			local index = 1

			for i, name in ipairs(THEME_ORDER) do
				if name == window.ThemeName then
					index = i
					break
				end
			end

			local nextTheme = THEME_ORDER[(index % #THEME_ORDER) + 1]

			window:SetTheme(nextTheme)
			mainGradient.Color = ColorSequence.new(window.Theme.Card, window.Theme.Main)
			accentGradient.Color = ColorSequence.new(window.Theme.Accent, window.Theme.Accent2)
		end)

		infoButton.MouseButton1Click:Connect(function()
			local lines = {}

			for _, person in ipairs(config.Credits or {}) do
				local entry = person

				if type(entry) == "string" then
					table.insert(lines, entry)
				elseif type(entry) == "table" then
					table.insert(lines, tostring(entry.Name or "?") .. " - " .. tostring(entry.Role or ""))
				end
			end

			if #lines == 0 then
				table.insert(lines, "Quantum Onyx GUI " .. GUI_VERSION)
			end

			window:Notify({
				Title = tostring(config.Title or "Quantum Onyx") .. " - Credits",
				Description = table.concat(lines, "\n"),
			}, { Time = 9 })
		end)

		local minimized = false

		local function setMinimized(value)
			minimized = value and true or false

			window.NormalSize = main.AbsoluteSize

			if minimized then
				tween(main, { Size = UDim2.fromOffset(window.NormalSize.X, 54) }, 0.24)
				window.TabStrip.Visible = false
				window.SearchRow.Visible = false
				window.Content.Visible = false
				window.Footer.Visible = false
			else
				tween(main, { Size = UDim2.fromOffset(window.NormalSize.X, window.NormalSize.Y) }, 0.24)
				window.TabStrip.Visible = true
				window.SearchRow.Visible = true
				window.Content.Visible = true
				window.Footer.Visible = true
			end

			minimizeButton.Text = minimized and "□" or "—"
		end

		minimizeButton.MouseButton1Click:Connect(function()
			setMinimized(not minimized)
		end)

		window.Minimizer = setMinimized

		closeButton.MouseButton1Click:Connect(function()
			window:Hide()
		end)

		---------------------------------------------------------------- tabs
		local tabStrip = make("ScrollingFrame", {
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0, 12, 0, 58),
			ScrollBarImageColor3 = window.Theme.Accent,
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.X,
			Size = UDim2.new(1, -24, 0, 40),
			Parent = main,
		})

		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabStrip,
		})

		inset(tabStrip, 2, 2, 2, 2)

		window.TabStrip = tabStrip

		--------------------------------------------------------------- search
		local searchRow = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 12, 0, 102),
			Size = UDim2.new(1, -24, 0, 30),
			Parent = main,
		})

		local searchBox = make("TextBox", {
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Enum.Font.Gotham,
			PlaceholderColor3 = window.Theme.Sub,
			PlaceholderText = "search 300+ options...",
			Size = UDim2.new(1, -32, 1, 0),
			Text = "",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = searchRow,
		})

		corner(searchBox, 8)
		inset(searchBox, 34, 0, 30, 0)

		local searchEdge = outline(searchBox, window.Theme.Border, 1, 0.3)

		local magnifier = make("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(0, 13, 0.5, 0),
			Rotation = 90,
			Size = UDim2.fromOffset(14, 14),
			Text = "▸",
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = searchBox,
		})

		local clearButton = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Text = "✕",
			TextSize = 11,
			Visible = false,
			Parent = searchBox,
		})

		bind(window, searchBox, {
			BackgroundColor3 = function(t) return t.Card end,
			TextColor3 = function(t) return t.Text end,
			PlaceholderColor3 = function(t) return t.Sub end,
		})

		bind(window, searchEdge, {
			Color = function(t) return t.Border end,
		})

		bind(window, magnifier, {
			TextColor3 = function(t) return t.Sub end,
		})

		bind(window, clearButton, {
			TextColor3 = function(t) return t.Sub end,
		})

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local value = searchBox.Text

			clearButton.Visible = value ~= ""

			local hit = applyFilter(value)

			if hit and hit.Select then
				hit.Select()
			end
		end)

		clearButton.MouseButton1Click:Connect(function()
			searchBox.Text = ""
			applyFilter("")
		end)

		window.SearchRow = searchRow
		window.SearchBox = searchBox

		------------------------------------------------------------- content
		local content = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 12, 0, 138),
			Size = UDim2.new(1, -24, 1, -182),
			Parent = main,
		})

		window.Content = content

		--------------------------------------------------------------- footer
		local footer = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 14, 1, -42),
			Size = UDim2.new(1, -28, 0, 30),
			Parent = main,
		})

		local hud = make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			RichText = true,
			Size = UDim2.new(1, -110, 1, 0),
			Text = "loading status...",
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = footer,
		})

		local stopAll = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = window.Theme.Card,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(96, 24),
			Text = "STOP ALL",
			TextSize = 11,
			Parent = footer,
		})

		corner(stopAll, 6)

		bind(window, hud, {
			TextColor3 = function(t) return t.Sub end,
		})

		bind(window, stopAll, {
			BackgroundColor3 = function(t) return t.Card end,
			TextColor3 = function(t) return t.Sub end,
		})

		stopAll.MouseEnter:Connect(function()
			tween(stopAll, { BackgroundColor3 = window.Theme.CardHover }, 0.15)
		end)

		stopAll.MouseLeave:Connect(function()
			tween(stopAll, { BackgroundColor3 = window.Theme.Card }, 0.2)
		end)

		stopAll.MouseButton1Click:Connect(function()
			if type(config.OnStopAll) == "function" then
				pcall(config.OnStopAll)
			end

			window:Notify({
				Title = "Quantum",
				Description = "Stopped every running farm.",
			}, { Time = 4 })
		end)

		window.Footer = footer
		window.Hud = hud

		---------------------------------------------------------- toast host
		local toastHost = make("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -16, 0, 66),
			Size = UDim2.fromOffset(330, 360),
			ZIndex = window.ZIndex + 40,
			Parent = root,
		})

		make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 8),
			Parent = toastHost,
		})

		window.ToastHost = toastHost

		-------------------------------------------------------- restore bubble
		local restore = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			AutoButtonColor = false,
			BackgroundColor3 = window.Theme.Accent,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(1, -18, 0, 18),
			Size = UDim2.fromOffset(150, 34),
			Text = "Quantum Onyx",
			TextSize = 13,
			TextColor3 = Color3.new(1, 1, 1),
			Visible = false,
			ZIndex = window.ZIndex + 5,
			Parent = root,
		})

		corner(restore, 9)
		local restoreGradient = shade(restore, window.Theme.Accent, window.Theme.Accent2, 25)

		bind(window, restore, {
			BackgroundColor3 = function(t) return t.Accent end,
		})

		restore.MouseButton1Click:Connect(function()
			window:Show()
		end)

		window.Restore = restore

		----------------------------------------------------------- drag & drop
		local dragging = false
		local dragStart = Vector2.new(0, 0)
		local originStart = UDim2.new()

		bar.InputBegan:Connect(function(input)
			-- ปุ่มบนแถบหัวเรื่องไม่ลากหน้าต่าง
			if input.Target and input.Target ~= bar and input.Target:IsA("TextButton") then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true

				dragStart = input.Position
				originStart = main.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				local limit = root.AbsoluteSize

				main.Position = UDim2.new(
					originStart.X.Scale,
					math.clamp(originStart.X.Offset + delta.X, -originStart.X.Offset, math.max(0, limit.X - main.AbsoluteSize.X + 60)),
					originStart.Y.Scale,
					math.clamp(originStart.Y.Offset + delta.Y, -originStart.Y.Offset, math.max(0, limit.Y - main.AbsoluteSize.Y + 60))
				)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		------------------------------------------------------------- resizing
		local grip = make("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Size = UDim2.fromOffset(20, 20),
			Text = "◢",
			TextSize = 12,
			TextTransparency = 0.45,
			Parent = main,
		})

		local resizing = false
		local resizeStart = Vector2.new(0, 0)
		local sizeStart = UDim2.new()

		grip.MouseButton1Down:Connect(function()
			resizing = true

			resizeStart = UserInputService:GetMouseLocation()
			sizeStart = main.Size
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not resizing then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = UserInputService:GetMouseLocation() - resizeStart
				local limit = root.AbsoluteSize

				main.Size = UDim2.fromOffset(
					math.clamp(sizeStart.X.Offset + delta.X, 400, math.max(400, limit.X - 24)),
					math.clamp(sizeStart.Y.Offset + delta.Y, 320, math.max(320, limit.Y - 24))
				)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if resizing then
					resizing = false

					task.defer(function()
						window.NormalSize = main.AbsoluteSize
					end)
				end
			end
		end)

		bind(window, grip, {
			TextColor3 = function(t) return t.Sub end,
		})

		------------------------------------------------------------- hotkeys
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end

			if input.KeyCode == Enum.KeyCode.RightShift then
				window:Toggle()
			end
		end)

		bind(window, main, {
			BackgroundColor3 = function(t) return t.Main end,
		})

		bind(window, mainGradient, {
			Color = function(t) return ColorSequence.new(t.Card, t.Main) end,
		})

		bind(window, window.MainEdge, {
			Color = function(t) return t.Border end,
		})

		bind(window, accentBar, {
			BackgroundColor3 = function(t) return t.Accent end,
		})

		bind(window, accentGradient, {
			Color = function(t) return ColorSequence.new(t.Accent, t.Accent2) end,
		})

		bind(window, title, {
			TextColor3 = function(t) return t.Text end,
		})

		bind(window, subtitle, {
			TextColor3 = function(t) return t.Sub end,
		})

		bind(window, version, {
			BackgroundColor3 = function(t) return t.Card end,
			TextColor3 = function(t) return t.Accent2 end,
		})

		bind(window, tabStrip, {
			ScrollBarImageColor3 = function(t) return t.Accent end,
		})

		bind(window, restoreGradient, {
			Color = function(t) return ColorSequence.new(t.Accent, t.Accent2) end,
		})

		window.Toaster = buildToaster(window)

		------------------------------------------------------------------ HUD
		local hudTick = 0

		local function cssColor(color)
			return string.format(
				"rgb(%d,%d,%d)",
				math.floor((color.R or 0) * 255),
				math.floor((color.G or 0) * 255),
				math.floor((color.B or 0) * 255)
			)
		end

		local function hudTag(text, themeColor)
			return string.format('<font color="%s">%s</font>', cssColor(themeColor), text)
		end

		RunService.Heartbeat:Connect(function()
			hudTick = hudTick + 1

			if hudTick < 30 then
				return
			end

			hudTick = 0

			local theme = window.Theme
			local data = localPlayer:FindFirstChild("Data")
			local level = data and data:FindFirstChild("Level")
			local beli = data and data:FindFirstChild("Beli")
			local fragments = data and data:FindFirstChild("Fragments")

			hud.Text = string.format(
				"%s %s      %s %s      %s %s      %s %d",
				hudTag("LEVEL", theme.Sub),
				level and formatNumber(level.Value) or "-",
				hudTag("BELI", theme.Sub),
				beli and formatNumber(beli.Value) or "-",
				hudTag("FRAGMENTS", theme.Sub),
				fragments and formatNumber(fragments.Value) or "-",
				hudTag("FPS", theme.Sub),
				math.floor(1 / math.max(RunService:GetProperty("DeltaTime"), 0.0001))
			)
		end)

		-- เลือกแท็บแรกให้อัตโนมัติ เผื่อสคริปต์ไม่ได้เรียก Select เอง
		task.defer(function()
			for _, item in ipairs(window.Tabs) do
				if type(item.Select) == "function" then
					item.Select()
					break
				end
			end
		end)

		return window
	end

	---------------------------------------------------------------- exports
	local module = {}
	local Notification = {}

	module.Notification = Notification

	function Notification:Notify(data, options)
		if self.Window == nil then
			return nil
		end

		return self.Window:Notify(data or {}, options or {})
	end

	function module.CreateWindow(config)
		local window = buildWindow(config or {})

		Notification.Window = window

		return window
	end

	module.Themes = THEMES
	module.ThemeOrder = THEME_ORDER
	module.SearchIndex = SearchIndex
	module.Version = GUI_VERSION

	return module
end

return { Build = BuildQuantumGUI }
