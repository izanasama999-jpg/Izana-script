local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- SETTINGS❤️
local SPEED_ON_VALUE = 290
local SPEED_OFF_VALUE = 105
local FLY_SPEED = 320

-- DASH SETTINGS❤️
local DASH_POWER = 450
local DASH_TIME = 0.4
local DASH_COOLDOWN = 0.1

-- VARS❤️
local flyOn = false
local speedOn = false
local noclipOn = false
local infJumpOn = false
local fixDashOn = false
local dayOn = false
local speedLoopConn
local dashCooldown = false
local lightingLoopConn
local dodgeOn = false
local dodgeCooldown = false
local dodgeConnections = {}

-- Fly objects❤️
local att, lv, ao
local flyLoopConn = nil
local flyCharacter = nil

-- FUNCTIONS❤️
local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
	return getChar():WaitForChild("Humanoid")
end

local function getHRP()
	return getChar():WaitForChild("HumanoidRootPart")
end


-- SPEED LOOP❤️
local function startSpeedLoop()
	if speedLoopConn then speedLoopConn:Disconnect() end

	speedLoopConn = RunService.RenderStepped:Connect(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		hum.WalkSpeed = speedOn and SPEED_ON_VALUE or SPEED_OFF_VALUE
	end)
end

-- DASH FUNCTION (THEO HƯỚNG DI CHUYỂN)❤️
local function doDash()
	if dashCooldown then return end
	dashCooldown = true

	local char = player.Character
	if not char then dashCooldown = false return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then dashCooldown = false return end

	local dir = hum.MoveDirection
	if dir.Magnitude <= 0 then
		dir = hrp.CFrame.LookVector
	end

	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude <= 0 then dashCooldown = false return end
	dir = dir.Unit

	-- dùng LinearVelocity để dash (skill không phá)
	local dashAtt = Instance.new("Attachment", hrp)

	local dashLV = Instance.new("LinearVelocity", hrp)
	dashLV.Attachment0 = dashAtt
	dashLV.MaxForce = math.huge
	dashLV.VectorVelocity = dir * DASH_POWER

	task.wait(DASH_TIME)

	if dashLV then dashLV:Destroy() end
	if dashAtt then dashAtt:Destroy() end

	task.wait(DASH_COOLDOWN)
	dashCooldown = false
end

-- STOP FLY❤️
local function stopFly()
	if flyLoopConn then
		flyLoopConn:Disconnect()
		flyLoopConn = nil
	end

	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.AutoRotate = true
		end
	end

	if lv then
		lv:Destroy()
		lv = nil
	end

	if ao then
		ao:Destroy()
		ao = nil
	end

	if att then
		att:Destroy()
		att = nil
	end

	flyCharacter = nil
end

-- START FLY (ANTI SKILL RESET)❤️
local function startFly()
	stopFly()

	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	if not hrp or not hum then return end

	flyCharacter = char
	hum.AutoRotate = false

	att = Instance.new("Attachment")
	att.Parent = hrp

	lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.Parent = hrp

	ao = Instance.new("AlignOrientation")
	ao.Attachment0 = att
	ao.MaxTorque = math.huge
	ao.Responsiveness = 200
	ao.Parent = hrp

	flyLoopConn = RunService.RenderStepped:Connect(function()
		if not flyOn then return end

		-- Không điều khiển nhân vật cũ sau khi respawn
		if player.Character ~= flyCharacter then
			return
		end

		local currentHRP = flyCharacter:FindFirstChild("HumanoidRootPart")
		local currentHum = flyCharacter:FindFirstChildOfClass("Humanoid")

		if not currentHRP or not currentHum then return end
		if not lv or not lv.Parent then return end

		local cam = workspace.CurrentCamera
		if not cam then return end

		local move = currentHum.MoveDirection

		if move.Magnitude > 0 then
			local camCF = cam.CFrame

			local forward = camCF.LookVector
			local right = camCF.RightVector

			local x = move:Dot(right)
			local z = move:Dot(forward)

			local flyDir = (right * x) + (forward * z)

			local vertical = camCF.LookVector.Y * z

			flyDir = Vector3.new(
				flyDir.X,
				vertical,
				flyDir.Z
			)

			if flyDir.Magnitude > 0 then
				lv.VectorVelocity = flyDir.Unit * FLY_SPEED
			else
				lv.VectorVelocity = Vector3.zero
			end
		else
			lv.VectorVelocity = Vector3.zero
		end

		local look = cam.CFrame.LookVector

		local flatLook = Vector3.new(
			look.X,
			0,
			look.Z
		)

		if flatLook.Magnitude > 0 then
			ao.CFrame = CFrame.lookAt(
				currentHRP.Position,
				currentHRP.Position + flatLook.Unit
			)
		end
	end)
end


-- GUI❤️
local function setDay()
	Lighting.ClockTime = 12
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(150,150,150)
	Lighting.OutdoorAmbient = Color3.fromRGB(150,150,150)
	Lighting.FogEnd = 1000000
	Lighting.GlobalShadows = true
end

local function setNight()
	Lighting.ClockTime = 0
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(70,70,70)
	Lighting.OutdoorAmbient = Color3.fromRGB(70,70,70)
	Lighting.FogEnd = 1000
	Lighting.GlobalShadows = true
end

local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

pcall(function()
	if CoreGui:FindFirstChild("BloxFruitHub") then
		CoreGui.BloxFruitHub:Destroy()
	end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxFruitHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- MENU
local Frame = Instance.new("ScrollingFrame")
Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0,180,0,300)
Frame.Position = UDim2.new(0.02,0,0.22,0)
Frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
Frame.BorderSizePixel = 0
Frame.ScrollBarThickness = 6
Frame.CanvasSize = UDim2.new(0,0,0,450)
Frame.Active = true
Frame.Visible = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = Frame

local layout = Instance.new("UIListLayout")
layout.Parent = Frame
layout.Padding = UDim.new(0,5)

local padding = Instance.new("UIPadding")
padding.Parent = Frame
padding.PaddingTop = UDim.new(0,5)
padding.PaddingBottom = UDim.new(0,5)
padding.PaddingLeft = UDim.new(0,5)
padding.PaddingRight = UDim.new(0,5)

local function createBtn(text)
	local btn = Instance.new("TextButton")
	btn.Parent = Frame
	btn.Size = UDim2.new(1,0,0,40)
	btn.Text = text
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BackgroundColor3 = Color3.fromRGB(60,60,60)

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,8)
	c.Parent = btn

	return btn
end

-- local❤️
local flyBtn = createBtn("Fly: OFF")
local speedBtn = createBtn("Speed: OFF")
local noclipBtn = createBtn("Noclip: OFF")
local infJumpBtn = createBtn("Inf Jump: OFF")
local fixDashBtn = createBtn("Fix Dash: OFF")
local dayBtn = createBtn("Day: OFF")
local dodgeBtn = createBtn("Dodge: OFF")

Frame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+200)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Frame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+200)
end)

-- NÚT IZ
local toggleMenuBtn = Instance.new("TextButton")
toggleMenuBtn.Parent = ScreenGui
toggleMenuBtn.Size = UDim2.new(0,60,0,60)
toggleMenuBtn.Position = UDim2.new(0.02,0,0.12,0)
toggleMenuBtn.Text = "IZ"
toggleMenuBtn.Font = Enum.Font.GothamBlack
toggleMenuBtn.TextScaled = true
toggleMenuBtn.TextColor3 = Color3.new(1,1,1)
toggleMenuBtn.BackgroundColor3 = Color3.fromRGB(90,40,220)

local c2 = Instance.new("UICorner")
c2.CornerRadius = UDim.new(1,0)
c2.Parent = toggleMenuBtn

local stroke = Instance.new("UIStroke")
stroke.Parent = toggleMenuBtn
stroke.Thickness = 2
stroke.Color = Color3.new(1,1,1)

local gradient = Instance.new("UIGradient")
gradient.Parent = toggleMenuBtn
gradient.Rotation = 45
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,170)),
	ColorSequenceKeypoint.new(0.5,Color3.fromRGB(130,0,255)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(0,170,255))
}

toggleMenuBtn.MouseButton1Click:Connect(function()
	Frame.Visible = not Frame.Visible
end)

-- Kéo nút IZ
local dragging = false
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	toggleMenuBtn.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

toggleMenuBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = toggleMenuBtn.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

toggleMenuBtn.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.Touch then
		update(input)
	end
end)

speedBtn.MouseButton1Click:Connect(function()
	speedOn = not speedOn
	speedBtn.Text = "Speed: "..(speedOn and "ON" or "OFF")
end)

flyBtn.MouseButton1Click:Connect(function()
	flyOn = not flyOn
	flyBtn.Text = "Fly: "..(flyOn and "ON" or "OFF")

	if flyOn then
		startFly()
	else
		stopFly()
	end
end)

noclipBtn.MouseButton1Click:Connect(function()
	noclipOn = not noclipOn
	noclipBtn.Text = "Noclip: "..(noclipOn and "ON" or "OFF")
end)

infJumpBtn.MouseButton1Click:Connect(function()
	infJumpOn = not infJumpOn
	infJumpBtn.Text = "Inf Jump: "..(infJumpOn and "ON" or "OFF")
end)

fixDashBtn.MouseButton1Click:Connect(function()
	fixDashOn = not fixDashOn
	fixDashBtn.Text = "Fix Dash: "..(fixDashOn and "ON" or "OFF")
end)

dodgeBtn.MouseButton1Click:Connect(function()
	dodgeOn = not dodgeOn
	dodgeBtn.Text = "Dodge: " .. (dodgeOn and "ON" or "OFF")

	if dodgeOn and player.Character then
		setupDodge(player.Character)
	end
end)


-- SET DAY❤️
dayBtn.MouseButton1Click:Connect(function()
	dayOn = not dayOn
	dayBtn.Text = "Day: " .. (dayOn and "ON" or "OFF")

	if dayOn then
		if not lightingLoopConn then
			lightingLoopConn = RunService.RenderStepped:Connect(function()
				if dayOn then
					setDay()
				end
			end)
		end
	else
		if lightingLoopConn then
			lightingLoopConn:Disconnect()
			lightingLoopConn = nil
		end
		restoreLighting()
	end
end)

-- NOCLIP LOOP❤️
RunService.Stepped:Connect(function()
	if not noclipOn then return end

	local char = player.Character
	if not char then return end

	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
end)

-- INF JUMP❤️
UIS.JumpRequest:Connect(function()
	if infJumpOn then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
      hum.UseJumpPower = true
			hum.JumpPower = 80 -- tăng hoặc giảm số này
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- DASH BUTTON❤️
local DashGui = Instance.new("ScreenGui", game.CoreGui)
DashGui.Name = "DashButtonGui"
DashGui.ResetOnSpawn = false

local dashBtn = Instance.new("TextButton", DashGui)
dashBtn.Size = UDim2.new(0, 55, 0, 55)
dashBtn.Position = UDim2.new(0.92, 0, 0.30, 0)
dashBtn.Text = "DASH"
dashBtn.BackgroundTransparency = 0.4
dashBtn.TextScaled = true

local corner = Instance.new("UICorner", dashBtn)
corner.CornerRadius = UDim.new(1,0)

dashBtn.MouseButton1Click:Connect(function()
	doDash()
end)

-- DRAG DASH BUTTON❤️
local dragging, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	dashBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

dashBtn.InputBegan:Connect(function(input)
	if fixDashOn then return end

	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = dashBtn.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

dashBtn.InputChanged:Connect(function(input)
	if fixDashOn then return end
	if dragging then update(input) end
end)

-- AUTO FIX WHEN CHARACTER RESET❤️
player.CharacterAdded:Connect(function(char)
	if flyOn then
		task.wait(1)

		if player.Character == char then
			startFly()
		end
	end
end)

-- START❤️
startSpeedLoop()

task.spawn(function()
	while true do
		task.wait(0.1) -- nhanh hơn để thắng game reset

		if dayOn then
			setDay()
		end
	end
end)

local function getEnemyData(hrp)
	local closestDist = math.huge
	local closestPos = nil

	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local pos = plr.Character.HumanoidRootPart.Position
			local dist = (pos - hrp.Position).Magnitude

			if dist < closestDist then
				closestDist = dist
				closestPos = pos
			end
		end
	end

	return closestPos, closestDist
end

-- smartdodge ❤️
local function smartDodge(hrp, hum)
	if dodgeCooldown then return end
	dodgeCooldown = true

	local _, dist = getEnemyData(hrp)

	if dist and dist < 40 then
		hrp.CFrame = hrp.CFrame + Vector3.new(0, 111, 0)
	elseif dist then
		local dir = Vector3.new(math.random(-1,1),0,math.random(-1,1))
		if dir.Magnitude == 0 then dir = Vector3.new(1,0,0) end
		hrp.CFrame = hrp.CFrame + dir.Unit * 120 + Vector3.new(0, 150, 0)
	end

	task.delay(1, function()
		dodgeCooldown = false
	end)
end

-- kích hoạt khi bị mất máu❤️
local function setupDodge(char)
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	local lastHp = hum.Health

	table.insert(dodgeConnections,
		hum.HealthChanged:Connect(function(hp)
			if not dodgeOn then
				lastHp = hp
				return
			end

			if hp < lastHp then
				smartDodge(hrp, hum)
			end

			lastHp = hp
		end)
	)
end

-- auto reset khi respam❤️
player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	setupDodge(char)
end)

if player.Character then
	setupDodge(player.Character)
end
