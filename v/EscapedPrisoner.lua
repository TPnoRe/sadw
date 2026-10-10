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

-- ตรวจสอบว่าโมเดลมอนสเตอร์ตัวนี้คือ Escaped Prisoner หรือไม่
function EscapedPrisoner.IsEscaped(model)
	if not model or not model:IsA("Model") then
		return false
	end

	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end

	for name in pairs(EscapedPrisoner.AccessoryNames) do
		if model:FindFirstChild(name, true) then
			return true
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
			while tick() - killStart < 35 do
				if settingsObj.AutoFarm == false then
					break
				end

				local target = EscapedPrisoner.FindTargetNear(point, 180)
				if not target then
					-- มอนตายแล้ว หรือไม่มีมอนที่จุดนี้
					break
				end

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

			-- เคลียร์ Hitbox เมื่อกำจัดมอนสเตอร์จุดนี้เสร็จสิ้น
			if utils and utils.ClearHitbox then
				utils:ClearHitbox()
			end

			task.wait(0.3)
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

	if EscapedPrisoner.Busy then
		return true
	end

	if not isSea1 then
		return false
	end

	local lv = EscapedPrisoner.GetLevel()
	if lv < 190 or lv > 209 then
		return false
	end

	local targets = EscapedPrisoner.FindTargets()
	if #targets == 0 then
		EscapedPrisoner.RoundDone = false
		return false
	end

	if EscapedPrisoner.RoundDone then
		return false
	end

	EscapedPrisoner.Run(env)
	EscapedPrisoner.RoundDone = true
	return true
end

return EscapedPrisoner
