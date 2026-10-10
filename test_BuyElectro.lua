-- ==============================================================================
-- [STANDALONE TEST SCRIPT: BuyElectro & NPC Streaming Diagnostics]
-- วัตถุประสงค์: ทดสอบการซื้อหมัด Electro จาก Mad Scientist แยกเดี่ยว
-- ตรวจสอบ: ปัญหา NPC ไม่โหลดจากระยะไกล (StreamingEnabled), การยิง Remote, และการวาป/บินไปซื้อ
-- ==============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
if not localPlayer then
	localPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

-- ข้อมูลสเปกของหมัด Electro / Mad Scientist
local NPC_NAME = "Mad Scientist"
local REMOTE_NAME = "BuyElectro"
local PRICE = 500000 -- ราคา 500,000 Beli
local FALLBACK_CFRAME = CFrame.new(-4842.112, 717.670, -2623.149) -- Skylands ล่าง

-- ตัวแปรสถานะ
local originalCFrame = nil
local isTweening = false
local currentTween = nil
local noclipConn = nil

-- ค้นหา Remote CommF_
local function getCommF()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local commF = remotes and remotes:FindFirstChild("CommF_")
	if not commF then
		commF = ReplicatedStorage:FindFirstChild("CommF_", true)
	end
	return commF
end

-- ค้นหาโมเดล NPC Mad Scientist
local function getNPCModel()
	local npc = Workspace:FindFirstChild(NPC_NAME, true)
	if not npc then
		local npcsFolder = Workspace:FindFirstChild("NPCs") or ReplicatedStorage:FindFirstChild("NPCs")
		npc = npcsFolder and npcsFolder:FindFirstChild(NPC_NAME, true)
	end
	return npc
end

-- ดึงพิกัด CFrame ของ NPC (รองรับทั้ง GetPivot, HumanoidRootPart, และ Fallback)
local function getNPCCFrame()
	local npc = getNPCModel()
	if npc then
		if npc:IsA("Model") then
			local pivot = npc:GetPivot()
			if pivot and pivot.Position ~= Vector3.zero then
				return pivot, npc
			end
		end
		local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
		if hrp then
			return hrp.CFrame, npc
		end
	end
	return FALLBACK_CFRAME, npc
end

-- ตรวจสอบว่าผู้เล่นมีหมัด Electro แล้วหรือไม่
local function checkMeleeOwned()
	local char = localPlayer.Character
	local bp = localPlayer:FindFirstChild("Backpack")
	local names = { "Electro", "Electric" }
	for _, n in ipairs(names) do
		if (char and char:FindFirstChild(n)) or (bp and bp:FindFirstChild(n)) then
			return true, n
		end
	end
	return false, nil
end

-- ดึงจำนวนเงิน Beli ของผู้เล่น
local function getBeli()
	local data = localPlayer:FindFirstChild("Data")
	local beli = data and data:FindFirstChild("Beli")
	return beli and beli.Value or 0
end

-- ==============================================================================
-- [GUI INTERFACE: แสดงผลและปุ่มกดทดสอบบนหน้าจอ]
-- ==============================================================================
local guiName = "ElectroTestGui"
local existingGui = CoreGui:FindFirstChild(guiName) or localPlayer.PlayerGui:FindFirstChild(guiName)
if existingGui then
	existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
pcall(function()
	screenGui.Parent = CoreGui
end)
if not screenGui.Parent then
	screenGui.Parent = localPlayer.PlayerGui
end

-- หน้าต่างหลัก (Draggable)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 430, 0, 520)
mainFrame.Position = UDim2.new(0.5, -215, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 65, 80)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- หัวข้อ Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 38)
titleLabel.BackgroundColor3 = Color3.fromRGB(32, 35, 45)
titleLabel.Text = "  ⚡ Mad Scientist / BuyElectro Diagnostic Test"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleLabel

-- กล่องสถานะ (Info Box)
local infoBox = Instance.new("Frame")
infoBox.Position = UDim2.new(0, 12, 0, 46)
infoBox.Size = UDim2.new(1, -24, 0, 105)
infoBox.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
infoBox.BorderSizePixel = 0
infoBox.Parent = mainFrame

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 8)
infoCorner.Parent = infoBox

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -16, 1, -8)
infoLabel.Position = UDim2.new(0, 8, 0, 4)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextColor3 = Color3.fromRGB(200, 210, 225)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Text = "กำลังโหลดข้อมูลสถานะ..."
infoLabel.Parent = infoBox

-- กล่องข้อความ Logs
local logBox = Instance.new("ScrollingFrame")
logBox.Position = UDim2.new(0, 12, 0, 158)
logBox.Size = UDim2.new(1, -24, 0, 165)
logBox.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
logBox.BorderSizePixel = 0
logBox.ScrollBarThickness = 5
logBox.CanvasSize = UDim2.new(0, 0, 0, 0)
logBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
logBox.Parent = mainFrame

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 8)
logCorner.Parent = logBox

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -12, 0, 0)
logLabel.Position = UDim2.new(0, 6, 0, 4)
logLabel.BackgroundTransparency = 1
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 11
logLabel.TextColor3 = Color3.fromRGB(150, 220, 150)
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.AutomaticSize = Enum.AutomaticSize.Y
logLabel.Text = "[LOG SYSTEM READY - ELECTRO TEST]\n"
logLabel.Parent = logBox

local function addLog(msg)
	local timeStr = os.date("%H:%M:%S")
	logLabel.Text = logLabel.Text .. string.format("[%s] %s\n", timeStr, tostring(msg))
	print(string.format("[ElectroTest %s] %s", timeStr, tostring(msg)))
	logBox.CanvasPosition = Vector2.new(0, 999999)
end

-- ==============================================================================
-- [SYSTEM LOGIC: ฟังก์ชันทดสอบระบบ]
-- ==============================================================================

-- อัปเดตข้อมูลบนหน้าจอ
local function updateStatus()
	local npc = getNPCModel()
	local targetCF = getNPCCFrame()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	local dist = hrp and (hrp.Position - targetCF.Position).Magnitude or 99999
	local owned, ownedName = checkMeleeOwned()
	local beli = getBeli()

	local npcStatus = "❌ ไม่พบใน Workspace"
	local streamStatus = "Streamed Out"
	if npc then
		local partsCount = 0
		for _, child in ipairs(npc:GetDescendants()) do
			if child:IsA("BasePart") then
				partsCount = partsCount + 1
			end
		end

		if partsCount > 0 then
			streamStatus = string.format("✅ โหลดสมบูรณ์ (%d ชิ้นส่วน)", partsCount)
		else
			streamStatus = "⚠️ โมเดลว่างเปล่า (ชิ้นส่วนยังไม่ Stream เข้ามา)"
		end
		npcStatus = string.format("✅ พบโมเดล (%s)", npc.Name)
	end

	infoLabel.Text = string.format(
		"• เงิน Beli: %s / $500,000 %s\n" ..
		"• ครอบครองหมัด: %s\n" ..
		"• ระยะห่างถึง Mad Scientist: %d studs\n" ..
		"• โมเดล NPC: %s\n" ..
		"• Streaming สถานะ: %s",
		tostring(beli), (beli >= PRICE and "(เพียงพอ)" or "(❌ ไม่พอ)"),
		(owned and ("✅ มีแล้ว (" .. ownedName .. ")") or "❌ ยังไม่มี"),
		math.floor(dist),
		npcStatus,
		streamStatus
	)
end

-- รันอัปเดตสถานะทุกๆ 0.5 วินาที
task.spawn(function()
	while screenGui.Parent do
		pcall(updateStatus)
		task.wait(0.5)
	end
end)

-- ฟังก์ชันตรวจสอบการ Streaming เชิงลึก
local function inspectStreaming()
	addLog("--- เริ่มการตรวจสอบ Mad Scientist Streaming ---")
	local npc = getNPCModel()
	if not npc then
		addLog("❌ ไม่พบ Mad Scientist ใน Workspace หรือ ReplicatedStorage!")
		addLog("ลองขอ Stream ด้วย RequestStreamAroundAsync...")
		pcall(function()
			Workspace:RequestStreamAroundAsync(FALLBACK_CFRAME.Position)
		end)
		task.wait(1)
		npc = getNPCModel()
		if npc then
			addLog("✅ พบ NPC หลัง RequestStreamAroundAsync!")
		else
			addLog("❌ ยังคงไม่พบ NPC (อาจต้องบิน/วาปเข้าไปใกล้ๆ บนเกาะลอยฟ้า)")
		end
		return
	end

	addLog("ชื่อโมเดล: " .. npc:GetFullName())
	addLog("Class: " .. npc.ClassName)
	pcall(function()
		addLog("ModelStreamingMode: " .. tostring(npc.ModelStreamingMode))
	end)
	addLog("PrimaryPart: " .. tostring(npc.PrimaryPart))
	local pivot = npc:GetPivot()
	addLog(string.format("GetPivot Position: (%.2f, %.2f, %.2f)", pivot.Position.X, pivot.Position.Y, pivot.Position.Z))

	local children = npc:GetChildren()
	addLog("จำนวน Children ในโมเดล: " .. tostring(#children))
	for i, c in ipairs(children) do
		addLog(string.format("  [%d] %s (%s)", i, c.Name, c.ClassName))
	end

	if #children == 0 then
		addLog("💡 วิเคราะห์: โมเดลมีตัวตนใน Explorer แต่ชิ้นส่วนภายในถูก Stream Out ออกไป เพราะตัวละครอยู่ไกลเกินรัศมี Streaming ของ Roblox!")
	else
		addLog("💡 วิเคราะห์: ชิ้นส่วน NPC โหลดอยู่ในหน่วยความจำ Client ครบถ้วน!")
	end
end

-- ฟังก์ชันยิง Remote ซื้อหมัดตรงนี้
local function testDirectRemote()
	local commF = getCommF()
	if not commF then
		addLog("❌ ไม่พบ Remote CommF_!")
		return
	end

	local targetCF = getNPCCFrame()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local dist = hrp and (hrp.Position - targetCF.Position).Magnitude or 99999

	addLog(string.format("🚀 กำลังส่งคำสั่ง InvokeServer('BuyElectro')... (ระยะห่าง: %d studs)", math.floor(dist)))
	local startT = tick()
	local ok, result = pcall(function()
		return commF:InvokeServer(REMOTE_NAME)
	end)
	local elapsed = tick() - startT

	if not ok then
		addLog("❌ เกิด Error ขณะ InvokeServer: " .. tostring(result))
		return
	end

	addLog(string.format("📩 ผลลัพธ์จาก Server (ใช้เวลา %.2fs): %s", elapsed, tostring(result)))

	task.wait(0.3)
	local owned, ownedName = checkMeleeOwned()
	if owned then
		addLog("🎉 สำเร็จ! ผู้เล่นได้รับหมัด " .. tostring(ownedName) .. " แล้ว!")
	else
		if dist > 30 then
			addLog("⚠️ ยังไม่ได้รับหมัด: สาเหตุเนื่องจากระยะห่างไกลเกิน 30 studs (ติด Anti-Cheat Distance Check ของเซิร์ฟเวอร์)")
		else
			addLog("⚠️ ยังไม่ได้รับหมัด: ตรวจสอบเงิน ($500k) หรือสถานะตัวละคร")
		end
	end
end

-- ฟังก์ชัน Noclip ป้องกันการติดกำแพง
local function startNoclip()
	if noclipConn then return end
	noclipConn = RunService.Stepped:Connect(function()
		local char = localPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end)
end

local function stopNoclip()
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
end

-- ==============================================================================
-- [ACTION: วาปไปหา Mad Scientist ก่อน แล้วค่อยยิงซื้อ (Warp First -> Then Buy)]
-- ==============================================================================
local function testInstantWarpAndBuy()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		addLog("❌ ไม่พบ HumanoidRootPart ของผู้เล่น")
		return
	end

	local commF = getCommF()
	if not commF then
		addLog("❌ ไม่พบ Remote CommF_!")
		return
	end

	originalCFrame = hrp.CFrame
	local targetCF = getNPCCFrame()
	local destination = targetCF * CFrame.new(0, 0, -3.5)
	local dist = (hrp.Position - destination.Position).Magnitude

	-- ขั้นที่ 1: วาปไปก่อน
	addLog(string.format("⚡ [ขั้นที่ 1] วาปไปหน้า Mad Scientist ก่อน... (ระยะทาง %d studs)", math.floor(dist)))
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = destination

	-- โหลดแมพ/ชิ้นส่วน NPC เข้ามา
	pcall(function()
		Workspace:RequestStreamAroundAsync(destination.Position)
	end)

	-- ขั้นที่ 2: รอให้พิกัดตัวละครซิงค์ขึ้น Server ก่อน
	addLog("⏳ วาปถึงแล้ว! กำลังรอ Server ซิงค์พิกัดตัวละคร (0.3 วินาที)...")
	task.wait(0.3)

	-- ขั้นที่ 3: พอตัวละครยืนอยู่หน้า NPC บน Server แล้ว ค่อยยิงซื้อ!
	addLog("🛒 [ขั้นที่ 2] ยิงคำสั่งซื้อ InvokeServer('BuyElectro')...")
	local startT = tick()
	local ok, result = pcall(function()
		return commF:InvokeServer(REMOTE_NAME)
	end)
	local elapsed = tick() - startT

	if not ok then
		addLog("❌ เกิด Error ขณะ InvokeServer: " .. tostring(result))
		return
	end

	addLog(string.format("📩 ผลลัพธ์จาก Server (ใช้เวลา %.2fs): %s", elapsed, tostring(result)))

	task.wait(0.3)
	local owned, ownedName = checkMeleeOwned()
	if owned then
		addLog("🎉 สำเร็จ 100%! วาปก่อนแล้วซื้อสำเร็จ ได้รับหมัด " .. tostring(ownedName) .. " แล้ว!")
	else
		addLog(string.format("⚠️ ผลลัพธ์: %s (หากยังไม่ได้รับ ตรวจสอบเงิน Beli ต้องมีอย่างน้อย $500,000)", tostring(result)))
	end
end

-- ==============================================================================
-- [ACTION: บินไปหา Mad Scientist แบบ Tween (Safe Flight)]
-- ==============================================================================
local function testTweenAndBuy()
	if isTweening then
		addLog("⚠️ กำลังเดินทางอยู่แล้ว...")
		return
	end

	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		addLog("❌ ไม่พบ HumanoidRootPart ของผู้เล่น")
		return
	end

	originalCFrame = hrp.CFrame
	local targetCF = getNPCCFrame()
	local destination = targetCF * CFrame.new(0, 0, -3.5)
	local dist = (hrp.Position - destination.Position).Magnitude

	addLog(string.format("🛫 เริ่มต้นบินไปหา Mad Scientist บนเกาะลอยฟ้า (%d studs)...", math.floor(dist)))
	isTweening = true
	startNoclip()

	local speed = 300
	local duration = math.clamp(dist / speed, 0.5, 30)

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	currentTween = TweenService:Create(hrp, tweenInfo, { CFrame = destination })
	currentTween:Play()

	currentTween.Completed:Connect(function()
		stopNoclip()
		isTweening = false
		currentTween = nil

		addLog("🛬 บินถึงพิกัดหน้า Mad Scientist แล้ว!")
		task.wait(0.5)

		-- ตรวจสอบ Streaming อีกครั้งเมื่อถึงที่หมาย
		inspectStreaming()
		task.wait(0.3)

		-- ยิงคำสั่งซื้อหมัด
		addLog("🛒 กำลังยิง Remote 'BuyElectro' ที่หน้า NPC...")
		testDirectRemote()
	end)
end

-- ==============================================================================
-- [ACTION: วาปกลับจุดเริ่มต้นทันที (Instant Return)]
-- ==============================================================================
local function returnToOrigin()
	if not originalCFrame then
		addLog("⚠️ ไม่มีพิกัดเดิมที่บันทึกไว้")
		return
	end

	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	addLog("🔙 วาปกลับจุดเริ่มต้นทันที (Instant Return)...")
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = originalCFrame
	addLog("✅ กลับถึงจุดเดิมเรียบร้อยแล้ว!")
end

-- ==============================================================================
-- [BUTTONS UI: สร้างปุ่มกด 5 ปุ่ม]
-- ==============================================================================
local function createButton(text, posIndex, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -24, 0, 27)
	btn.Position = UDim2.new(0, 12, 0, 334 + (posIndex - 1) * 31)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		pcall(callback)
	end)
	return btn
end

createButton("1. 🔍 ตรวจสอบ NPC Mad Scientist & Streaming", 1, Color3.fromRGB(45, 80, 150), inspectStreaming)
createButton("2. 📡 เทสยิง Remote BuyElectro ตรงนี้ (ระยะไกล)", 2, Color3.fromRGB(160, 60, 60), testDirectRemote)
createButton("3. ⚡ วาปไปหา Mad Scientist ทันที + ยิงซื้อ (Instant Warp)", 3, Color3.fromRGB(200, 120, 20), testInstantWarpAndBuy)
createButton("4. 🚀 บินไปหา Mad Scientist แบบ Tween (Safe Flight)", 4, Color3.fromRGB(40, 140, 75), testTweenAndBuy)
createButton("5. 🔙 วาปกลับจุดเริ่มต้น (Instant Return)", 5, Color3.fromRGB(80, 85, 95), returnToOrigin)

addLog("สคริปต์ทดสอบ BuyElectro พร้อมทำงาน!")
addLog("พิกัดเป้าหมาย: Mad Scientist @ Skylands (-4842, 717, -2623)")
