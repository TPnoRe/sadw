-- ==============================================================================
-- [MODULE: EscapedPrisoner] ระบบตรวจจับและจัดการ Escaped Prisoners (เลเวล 190-209)
-- หมวดหมู่: 14.1 Main Level & Mob Checker
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

EscapedPrisoner.Stay = 4 -- ระยะเวลาหยุดรอในแต่ละจุด (วินาที)
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

-- ตรวจสอบเลเวลผู้เล่น (ช่วงเลเวลที่ต้องล่า Escaped Prisoner: 190 - 209)
function EscapedPrisoner.GetLevel()
	local player = localPlayer or Players.LocalPlayer
	local data = player and player:FindFirstChild("Data")
	local lv = data and data:FindFirstChild("Level")
	return lv and tonumber(lv.Value) or 0
end

-- คุย DialogueGui 2 ขั้น เพื่อกด "Not this time!"
function EscapedPrisoner.ClickNotThisTime()
	local player = localPlayer or Players.LocalPlayer
	local gui = player and player:FindFirstChild("PlayerGui")
	local dg = gui and gui:FindFirstChild("DialogueGui")

	if dg then
		local frame = nil
		for _, c in ipairs(dg:GetChildren()) do
			if c:FindFirstChild("pageButton") or c:FindFirstChild("optionsList") then
				frame = c
				break
			end
		end

		if frame then
			-- ขั้นที่ 1: คลิก pageButton (หน้ายังไม่ครบ)
			local pb = frame:FindFirstChild("pageButton")
			if pb and pb:IsA("GuiButton") and pb.Visible then
				pcall(function()
					firesignal(pb.Activated)
				end)
				return true, true
			end

			-- ขั้นที่ 2: เลือก option จาก text "Not this time!" ใน optionsList.scroller
			local ol = frame:FindFirstChild("optionsList")
			local sc = ol and ol:FindFirstChild("scroller")
			if sc then
				for _, child in ipairs(sc:GetChildren()) do
					local btn = child:FindFirstChild("button")
					if btn and btn:IsA("GuiButton") then
						local txt = btn:IsA("TextButton") and btn.Text
						if type(txt) ~= "string" then
							for _, sub in ipairs(child:GetDescendants()) do
								if sub:IsA("TextLabel") and type(sub.Text) == "string" and sub.Text ~= "" then
									txt = sub.Text
									break
								end
							end
						end

						if type(txt) == "string" and txt:lower():find("not this time") then
							pcall(function()
								firesignal(btn.Activated)
							end)
							return true, false
						end
					end
				end
			end
		end
	end

	-- Fallback: ค้นหาทั้ง PlayerGui
	if gui then
		for _, d in ipairs(gui:GetDescendants()) do
			local txt = d:IsA("TextButton") and d.Text
			if type(txt) ~= "string" then
				local ok, lbl = pcall(function()
					return d:FindFirstChildOfClass("TextLabel")
				end)
				txt = ok and lbl and lbl.Text
			end

			if type(txt) == "string" and txt:lower():find("not this time") then
				local btn = d:IsA("GuiButton") and d or d.Parent
				if btn and btn:IsA("GuiButton") then
					pcall(function()
						firesignal(btn.Activated)
					end)
					return true, false
				end
			end
		end
	end

	return false, false
end

-- ฟังก์ชันรันการวน 3 จุด (รับ env สำหรับ tweenManager และ Settings)
function EscapedPrisoner.Run(env)
	env = env or {}
	local tweenMgr = env.tweenManager or _G.tweenManager
	local settingsObj = env.Settings or _G.Settings or {}

	EscapedPrisoner.Busy = true

	local prevBring = settingsObj.BringMonster
	local prevAttack = settingsObj.AutoAttack
	local prevDouble = settingsObj.DoubleAttack

	settingsObj.BringMonster = false
	settingsObj.AutoAttack = false
	settingsObj.DoubleAttack = false

	local ok, err = pcall(function()
		for _, point in ipairs(EscapedPrisoner.Points) do
			local t0 = tick()
			while tick() - t0 < EscapedPrisoner.Stay do
				if settingsObj.AutoFarm == false then
					return
				end

				if tweenMgr and tweenMgr.topos then
					tweenMgr:topos(point)
				end

				local clicked = EscapedPrisoner.ClickNotThisTime()
				task.wait(clicked and 0.25 or 0.4)
			end
		end
	end)

	if not ok then
		warn("[Escaped Prisoners] error: " .. tostring(err))
	end

	settingsObj.BringMonster = prevBring
	settingsObj.AutoAttack = prevAttack
	settingsObj.DoubleAttack = prevDouble
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
