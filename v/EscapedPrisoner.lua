-- ==============================================================================
-- [MODULE: EscapedPrisoner] ระบบตรวจจับและจัดการ Escaped Prisoners (เลเวล 190-209)
-- หมวดหมู่: 14.1 Main Level & Mob Checker
-- รายละเอียด: ปิด Bring Mob ชั่วคราว, Tween วน 3 จุด, กด Dialogue, ตีมอนจนตายทีละจุด
-- ==============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

local EscapedPrisoner = {}

-- รายชื่อ Accessory ที่ใช้ระบุตัวมอนสเตอร์ Escaped Prisoner
EscapedPrisoner.AccessoryNames = {
	["Accessory (OrangeJacket)"] = true,
	["Accessory (Meshes/Hair2 final ver1Accessory)"] = true,
	["Accessory (Big_Chain_Around_Neck_Silver)"] = true,
}

-- พิกัดจุดตรวจจับและฟาร์ม Escaped Prisoner ทั้ง 3 จุด (เกาะคุก Prison ใน Sea 1)
EscapedPrisoner.Points = {
	Vector3.new(5076.79443359375, 10.273427963256836, 451.0428161621094),
	Vector3.new(5351.0439453125, 7.447643756866455, 1100.4482421875),
	Vector3.new(5525.46435546875, 9.008895874023438, 933.4722900390625),
}

EscapedPrisoner.Busy = false
EscapedPrisoner.RoundDone = false
EscapedPrisoner.QuestCompleted = false

-- ตรวจสอบว่าโมเดลมอนสเตอร์ตัวนี้คือ Escaped Prisoner หรือไม่
function EscapedPrisoner.IsEscaped(model)
	if not model or not model:IsA("Model") then
		return false
	end

	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end

	local modelNameLower = model.Name:lower()
	if modelNameLower:find("escaped") then
		return true
	end

	for name in pairs(EscapedPrisoner.AccessoryNames) do
		if model:FindFirstChild(name, true) then
			return true
		end
	end

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") then
			local accName = child.Name:lower()
			if accName:find("orangejacket") or accName:find("hair2") or accName:find("big_chain") or accName:find("escaped") then
				return true
			end
		end
	end

	if modelNameLower:find("prisoner") and not Players:GetPlayerFromCharacter(model) then
		local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		if root then
			for _, pt in ipairs(EscapedPrisoner.Points) do
				if (root.Position - pt).Magnitude <= 80 then
					return true
				end
			end
		end
	end

	return false
end

-- ค้นหามอนสเตอร์ Escaped Prisoners ทั้งหมดที่ยังมีชีวิตอยู่ใน Workspace.Enemies
function EscapedPrisoner.FindTargets()
	local targets = {}
	local enemiesFolder = Workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return targets
	end

	for _, child in ipairs(enemiesFolder:GetChildren()) do
		if EscapedPrisoner.IsEscaped(child) then
			table.insert(targets, child)
		end
	end

	return targets
end

-- ค้นหามอนสเตอร์ Escaped Prisoner ที่อยู่ใกล้พิกัดที่กำหนด
function EscapedPrisoner.FindTargetNear(pos, radius)
	radius = radius or 180
	local enemiesFolder = Workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return nil
	end

	local closest, minDist = nil, radius
	for _, child in ipairs(enemiesFolder:GetChildren()) do
		if EscapedPrisoner.IsEscaped(child) then
			local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
			if root then
				local dist = (root.Position - pos).Magnitude
				if dist < minDist then
					minDist = dist
					closest = child
				end
			end
		end
	end

	return closest
end

-- ตรวจสอบเลเวลผู้เล่น (ช่วงเลเวลที่ต้องล่า Escaped Prisoner: 190 - 209)
function EscapedPrisoner.GetLevel()
	local player = localPlayer or Players.LocalPlayer
	local data = player and player:FindFirstChild("Data")
	local lv = data and data:FindFirstChild("Level")
	return lv and tonumber(lv.Value) or 0
end

-- กดข้ามและเลือก DialogueGui อัตโนมัติ (pageButton, optionsList, "Not this time!")
function EscapedPrisoner.AutoAdvanceDialogue(maxDuration)
	maxDuration = maxDuration or 2.5
	local startTime = tick()
	local player = localPlayer or Players.LocalPlayer

	while tick() - startTime < maxDuration do
		local gui = player and player:FindFirstChild("PlayerGui")
		local dg = gui and gui:FindFirstChild("DialogueGui")
		if not dg or not dg.Enabled then
			break
		end

		local clicked = false

		-- 1. ตรวจสอบ pageButton และ optionsList ภายใน DialogueGui
		for _, c in ipairs(dg:GetChildren()) do
			local pb = c:FindFirstChild("pageButton")
			if pb and pb:IsA("GuiButton") and pb.Visible then
				pcall(function()
					if firesignal then
						firesignal(pb.Activated)
						firesignal(pb.MouseButton1Click)
					end
				end)
				clicked = true
			end

			local ol = c:FindFirstChild("optionsList")
			local sc = ol and ol:FindFirstChild("scroller")
			if sc then
				for _, child in ipairs(sc:GetChildren()) do
					local btn = child:FindFirstChild("button")
					if btn and btn:IsA("GuiButton") and btn.Visible then
						pcall(function()
							if firesignal then
								firesignal(btn.Activated)
								firesignal(btn.MouseButton1Click)
							end
						end)
						clicked = true
					end
				end
			end
		end

		-- 2. ค้นหาปุ่มข้อความตอบรับทั่วไป เช่น "Not this time!", "Claim", "Yes", "Ok"
		for _, d in ipairs(dg:GetDescendants()) do
			if d:IsA("GuiButton") and d.Visible then
				local txt = d:IsA("TextButton") and d.Text:lower() or ""
				if txt == "" then
					local lbl = d:FindFirstChildOfClass("TextLabel")
					txt = lbl and lbl.Text:lower() or ""
				end

				if txt:find("not this time") or txt:find("claim") or txt:find("reward") or txt:find("yes") or txt:find("ok") or txt:find("continue") then
					pcall(function()
						if firesignal then
							firesignal(d.Activated)
							firesignal(d.MouseButton1Click)
						end
					end)
					clicked = true
				end
			end
		end

		task.wait(clicked and 0.25 or 0.3)
	end
end

-- ค้นหา NPC Jail Keeper บนเกาะคุก (Prison Island ใน Sea 1)
function EscapedPrisoner.FindJailKeeper()
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	local candidates = {
		"Jail Keeper",
		"JailKeeper",
		"Prison Adventurer",
		"PrisonAdventurer",
		"Warden",
		"Chief Warden",
	}

	-- 1. ค้นหาใน Workspace.NPCs
	if npcsFolder then
		for _, name in ipairs(candidates) do
			local found = npcsFolder:FindFirstChild(name)
			if found and found:IsA("Model") then
				return found, found:GetPivot().Position
			end
		end

		for _, child in ipairs(npcsFolder:GetChildren()) do
			if child:IsA("Model") then
				local n = child.Name:lower()
				if (n:find("jail") and n:find("keeper")) or (n:find("prison") and n:find("adventurer")) or n:find("warden") then
					return child, child:GetPivot().Position
				end
			end
		end
	end

	-- 2. ค้นหาทั่ว Workspace
	for _, name in ipairs(candidates) do
		local found = Workspace:FindFirstChild(name, true)
		if found and found:IsA("Model") then
			return found, found:GetPivot().Position
		end
	end

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") then
			local n = child.Name:lower()
			if (n:find("jail") and n:find("keeper")) or n == "jail keeper" or n == "jailkeeper" then
				return child, child:GetPivot().Position
			end
		end
	end

	-- 3. Fallback: พิกัดศูนย์กลางเกาะคุก (Prison Courtyard)
	return nil, Vector3.new(4870, 6, 736)
end

-- ค้นหาและคลิกปุ่ม "โต้ตอบ" / "Interact" ใน PlayerGui
function EscapedPrisoner.ClickInteractButton()
	local player = localPlayer or Players.LocalPlayer
	local pGui = player and player:FindFirstChild("PlayerGui")
	if not pGui then
		return false
	end

	local clicked = false

	for _, gui in ipairs(pGui:GetDescendants()) do
		if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
			local text = ""
			if gui:IsA("TextButton") then
				text = gui.Text:lower()
			end

			if text == "" then
				local lbl = gui:FindFirstChildOfClass("TextLabel")
				if lbl and lbl.Text then
					text = lbl.Text:lower()
				end
			end

			local name = gui.Name:lower()

			if text:find("โต้ตอบ") or text:find("interact") or name:find("interact") then
				pcall(function()
					if firesignal then
						firesignal(gui.Activated)
						firesignal(gui.MouseButton1Click)
					end
				end)
				clicked = true
			end
		end
	end

	return clicked
end

-- Tween ไปหา NPC Jail Keeper และกดปุ่ม "โต้ตอบ" / "Interact" พร้อมเคลียร์บทสนทนา
function EscapedPrisoner.InteractWithJailKeeper(env)
	env = env or {}
	local tweenMgr = env.tweenManager or _G.tweenManager
	local settingsObj = env.Settings or _G.Settings or {}
	local advanceDialogue = env.autoAdvanceDialogue or (utils and utils.AutoAdvanceDialogue and function() return utils:AutoAdvanceDialogue() end) or _G.autoAdvanceDialogue or EscapedPrisoner.AutoAdvanceDialogue

	local npcModel, npcPos = EscapedPrisoner.FindJailKeeper()
	local targetCF = nil

	if npcModel then
		local root = npcModel:FindFirstChild("HumanoidRootPart") or npcModel.PrimaryPart or npcModel:FindFirstChildWhichIsA("BasePart")
		if root then
			targetCF = root.CFrame * CFrame.new(0, 0, 3)
		else
			targetCF = npcModel:GetPivot() * CFrame.new(0, 0, 3)
		end
	end

	if not targetCF then
		targetCF = CFrame.new(npcPos + Vector3.new(0, 3, 0))
	end

	-- 1. บิน/Tween ไปหน้า NPC Jail Keeper
	local tweenStart = tick()
	while tick() - tweenStart < 15 do
		if settingsObj.AutoFarm == false then
			return false
		end

		local char = localPlayer and localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - targetCF.Position).Magnitude <= 12 then
			break
		end

		if tweenMgr and tweenMgr.topos then
			tweenMgr:topos(targetCF, true)
		end
		task.wait(0.25)
	end

	task.wait(0.3)

	-- 2. กดโต้ตอบกับ NPC (ProximityPrompt + VirtualInputManager E + ClickDetector + ปุ่ม GUI)
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	-- 2.1 ProximityPrompt รอบตัว
	if hrp then
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("ProximityPrompt") and desc.Enabled then
				local pPos = (desc.Parent:IsA("BasePart") and desc.Parent.Position)
					or (desc.Parent:IsA("Attachment") and desc.Parent.WorldPosition)
					or (desc.Parent:IsA("Model") and desc.Parent:GetPivot().Position)
				if pPos and (pPos - hrp.Position).Magnitude <= 30 then
					pcall(function()
						desc.HoldDuration = 0
						if fireproximityprompt then
							fireproximityprompt(desc, 0)
							fireproximityprompt(desc, math.huge)
						end
						desc:InputHoldBegin()
						task.wait(0.05)
						desc:InputHoldEnd()
					end)
				end
			end
		end
	end

	-- 2.2 ClickDetector ใน NPC
	if npcModel then
		for _, desc in ipairs(npcModel:GetDescendants()) do
			if desc:IsA("ClickDetector") and fireclickdetector then
				pcall(function()
					fireclickdetector(desc)
				end)
			end
		end
	end

	-- 2.3 กดปุ่ม [E]
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		if vim then
			vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.1)
			vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end
	end)

	-- 2.4 คลิกปุ่ม "โต้ตอบ" / "Interact" ใน PlayerGui
	for _ = 1, 6 do
		EscapedPrisoner.ClickInteractButton()
		task.wait(0.12)
	end

	-- 2.5 สำรอง: ยิง Remote BonusMomentsGuide / ClaimReward
	pcall(function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
		if Net then
			local netModule = require(Net)
			local guide = netModule and netModule:RemoteFunction("BonusMomentsGuide")
			if guide then
				local nName = npcModel and npcModel.Name or "Jail Keeper"
				guide:InvokeServer("InteractQuestGiver", nName)
				guide:InvokeServer("InteractQuestGiver", "Jail Keeper")
				guide:InvokeServer("InteractQuestGiver", "Prison Adventurer")
			end
		end
		local bonusMomentsRemoteFunction = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("BonusMomentsRemoteFunction")
		if bonusMomentsRemoteFunction then
			bonusMomentsRemoteFunction:InvokeServer("Escape from Alcatraz", "ClaimReward")
		end
	end)

	-- 2.6 ผ่านบทสนทนา DialogueGui
	if advanceDialogue then
		local diagStart = tick()
		while tick() - diagStart < 4 do
			local clicked = advanceDialogue()
			if not clicked then
				break
			end
			task.wait(0.25)
		end
	end

	return true
end

-- ฟังก์ชันรันวน 3 จุด: ปิด Bring Mob อย่างเดียว -> Tween -> Dialogue -> ตีมอนจนตาย -> ไปจุดถัดไป
function EscapedPrisoner.Run(env)
	env = env or {}
	local tweenMgr = env.tweenManager or _G.tweenManager
	local settingsObj = env.Settings or _G.Settings or {}
	local subFunc = env.subFunction or (OxiasidianAPI and OxiasidianAPI.SubFunction)
	local advanceDialogue = env.autoAdvanceDialogue or (utils and utils.AutoAdvanceDialogue and function() return utils:AutoAdvanceDialogue() end) or _G.autoAdvanceDialogue or EscapedPrisoner.AutoAdvanceDialogue

	EscapedPrisoner.Busy = true

	-- [1. ปิด Bring Mob ไว้ก่อนแค่อย่างเดียว]
	local prevBring = settingsObj.BringMonster
	settingsObj.BringMonster = false

	local ok, err = pcall(function()
		-- [ลูปตรวจเช็ค]: วนกำจัด EscapedPrisoner ให้หมดก่อนไปหา NPC
		local maxRounds = 5
		local currentRound = 0

		while currentRound < maxRounds do
			currentRound += 1
			if settingsObj.AutoFarm == false then
				break
			end

			-- ทำวนให้ครบทั้ง 3 จุด
			for i, point in ipairs(EscapedPrisoner.Points) do
				if settingsObj.AutoFarm == false then
					break
				end

				-- [2. Tween ไปจุดของ escapedPoints]
				local t0 = tick()
				local targetCF = CFrame.new(point)
				while tick() - t0 < 15 do
					if settingsObj.AutoFarm == false then
						break
					end

					local char = localPlayer and localPlayer.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - point).Magnitude <= 18 then
						break
					end

					if tweenMgr and tweenMgr.topos then
						tweenMgr:topos(targetCF, true)
					end
					task.wait(0.25)
				end

				-- [3. รัน AutoAdvanceDialogue() จากไฟล์หลักให้เสร็จ]
				if advanceDialogue then
					local diagStart = tick()
					while tick() - diagStart < 3.5 do
						local clicked = advanceDialogue()
						if not clicked then break end
						task.wait(0.25)
					end
				end
				task.wait(0.2)

				-- [4. ตีมอนจุดนั้นให้ตาย ค่อยไปพิกัดใน escapedPoints จุดต่อไป]
				local killStart = tick()
				local foundAnyMob = false
				while tick() - killStart < 35 do
					if settingsObj.AutoFarm == false then
						break
					end

					local target = EscapedPrisoner.FindTargetNear(point, 180)
					if not target then
						if not foundAnyMob and (tick() - killStart < 2.5) then
							task.wait(0.25)
						else
							-- มอนตายแล้ว หรือไม่มีมอนที่จุดนี้
							break
						end
					else
						foundAnyMob = true
						local hum = target:FindFirstChildOfClass("Humanoid")
						if not hum or hum.Health <= 0 then
							break
						end

						-- โจมตีมอนสเตอร์ (ไม่ Bring Mob)
						if subFunc and subFunc.Attack then
							subFunc:Attack(target, false)
						elseif utils and utils.GetFarmCFrame then
							local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
							if root and tweenMgr and tweenMgr.topos then
								tweenMgr:topos(utils:GetFarmCFrame(root), true)
							end
						end

						task.wait(0.15)
					end
				end

				-- เคลียร์ Hitbox เมื่อกำจัดมอนสเตอร์จุดนี้เสร็จสิ้น
				if utils and utils.ClearHitbox then
					utils:ClearHitbox()
				end

				task.wait(0.3)
			end

			-- เช็คก่อนไปหา NPC ว่ายังมี EscapedPrisoner อยู่ไหม
			local remaining = EscapedPrisoner.FindTargets()
			if #remaining == 0 then
				break -- ไม่มี EscapedPrisoner เหลืออยู่แล้ว พร้อมไปหา NPC
			else
				task.wait(0.5) -- ยังมีเหลืออยู่ ให้วนทำตามขั้นตอนเดิมซ้ำอีกรอบ
			end
		end

		-- [5. ก่อนไปหา NPC: ยืนยันว่าไม่มี EscapedPrisoner เหลืออยู่แล้ว จึง Tween ไปหา NPC Jail Keeper แล้วกดปุ่ม "โต้ตอบ" / "Interact"]
		local finalRemaining = EscapedPrisoner.FindTargets()
		if #finalRemaining == 0 and settingsObj.AutoFarm ~= false then
			EscapedPrisoner.InteractWithJailKeeper(env)
			EscapedPrisoner.QuestCompleted = true
		end
	end)

	if not ok then
		warn("[Escaped Prisoners] error: " .. tostring(err))
	end

	-- คืนค่า Bring Mob เดิมหลังทำครบ 3 จุด (หรือหยุดฟาร์ม)
	settingsObj.BringMonster = prevBring
	EscapedPrisoner.Busy = false
end

-- ฟังก์ชันหลักในการตรวจสอบและเริ่มการจัดการ (Handle)
function EscapedPrisoner.Handle(env)
	env = env or {}
	local isSea1 = env.isSea1
	if isSea1 == nil then
		local attr = Workspace:GetAttribute("MAP")
		isSea1 = attr == "Sea1" or game.PlaceId == 2753915549
	end

	-- ทำเฉพาะใน Sea 1
	if not isSea1 then
		return false
	end

	-- ถ้าทำเควสต์นี้สำเร็จและเคลมรางวัลจาก Jail Keeper เรียบร้อยแล้ว ให้ข้ามเพื่อทำเควสต์ปกติต่อ
	if EscapedPrisoner.QuestCompleted then
		return false
	end

	-- ตรวจสอบจากระบบ Secret Quests Replication ว่าเควสต์ Escape from Alcatraz ผ่านแล้วหรือยัง
	pcall(function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
		if Net then
			local netModule = require(Net)
			local repFunc = netModule and netModule:RemoteFunction("RequestBonusMomentReplication")
			if repFunc then
				local res = repFunc:InvokeServer({ Type = "GetMomentProgress" })
				if res and res.Data and res.Data["Sea1/Prison/Escape from Alcatraz"] == true then
					EscapedPrisoner.QuestCompleted = true
				end
			end
		end
	end)

	if EscapedPrisoner.QuestCompleted then
		return false
	end

	-- ถ้ากำลังรันเควสต์อยู่แล้ว ให้คืนค่า true เพื่อไม่ให้ฟาร์มปกติแทรก
	if EscapedPrisoner.Busy then
		return true
	end

	-- ตรวจสอบระดับเลเวล (เฉพาะเลเวล >= 190 หรือเมื่อยังไม่ได้ข้อมูลเลเวล)
	local lv = EscapedPrisoner.GetLevel()
	if lv > 0 and lv < 190 then
		return false
	end

	-- เริ่มต้นรันกระบวนการล่า Escaped Prisoner วน 3 จุด -> ตรวจเช็ค -> ไปหา Jail Keeper
	EscapedPrisoner.Run(env)

	return true
end

return EscapedPrisoner
