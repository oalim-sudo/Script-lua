-- LocalScript di StarterPlayerScripts
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- KONFIGURASI
---------------------------------------------------------------------
local PANEL_W, PANEL_H, HEADER_H = 230, 320, 36
local BTN_SIZE = 52
local DRAG_THRESHOLD = 6
local HOTKEY = Enum.KeyCode.M

-- Mode Tween
local TWEEN_SPEEDS = { 60, 120, 200, 350 } -- studs/detik
local TWEEN_MIN = 0.3
local TWEEN_MAX = 11
local TWEEN_LIFT = 14

-- Mode Lari
local RUN_LEVELS = { 22, 28, 36 } -- HARUS sama dengan RunServer
local RUN_STOP_DIST = 6           -- berhenti saat sedekat ini
local RUN_TIMEOUT = 40            -- detik

local C = {
	bg = Color3.fromRGB(20, 22, 32),
	surface = Color3.fromRGB(32, 36, 50),
	surfaceHover = Color3.fromRGB(52, 62, 95),
	list = Color3.fromRGB(16, 18, 26),
	accent = Color3.fromRGB(88, 130, 255),
	accentHover = Color3.fromRGB(115, 155, 255),
	grad1 = Color3.fromRGB(70, 110, 235),
	grad2 = Color3.fromRGB(150, 90, 235),
	text = Color3.fromRGB(235, 238, 248),
	subtext = Color3.fromRGB(140, 150, 175),
	stroke = Color3.fromRGB(60, 70, 100),
	success = Color3.fromRGB(90, 210, 140),
	warn = Color3.fromRGB(240, 190, 80),
	danger = Color3.fromRGB(235, 90, 90),
}

---------------------------------------------------------------------
-- HELPER
---------------------------------------------------------------------
local function new(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then inst[k] = v end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

local function tween(obj, t, props)
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(800, 600)
end

local function clampPos(x, y, w, h)
	local vp = viewport()
	return Vector2.new(
		math.clamp(x, 0, math.max(0, vp.X - w)),
		math.clamp(y, 0, math.max(0, vp.Y - h))
	)
end

local function hover(obj, normal, over)
	obj.MouseEnter:Connect(function()
		if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then return end
		tween(obj, 0.15, { BackgroundColor3 = over })
	end)
	obj.MouseLeave:Connect(function()
		tween(obj, 0.15, { BackgroundColor3 = normal })
	end)
end

---------------------------------------------------------------------
-- SCREEN GUI
---------------------------------------------------------------------
local screenGui = new("ScreenGui", {
	Name = "TeleportPlayerUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 10,
	Parent = playerGui,
})

---------------------------------------------------------------------
-- TOMBOL BULAT
---------------------------------------------------------------------
local toggleBtn = new("TextButton", {
	Name = "ToggleBtn",
	Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE),
	Position = UDim2.fromOffset(15, math.floor(viewport().Y / 2 - BTN_SIZE / 2)),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Text = "💎",
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Active = true,
	Parent = screenGui,
}, {
	corner(BTN_SIZE),
	new("UIGradient", { Color = ColorSequence.new(C.grad1, C.grad2), Rotation = 45 }),
	new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.6, Thickness = 2 }),
})

---------------------------------------------------------------------
-- PANEL
---------------------------------------------------------------------
local panel = new("CanvasGroup", {
	Name = "Panel",
	Size = UDim2.fromOffset(PANEL_W, PANEL_H),
	Position = UDim2.fromOffset(80, 100),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	GroupTransparency = 1,
	Visible = false,
	Active = true,
	Parent = screenGui,
}, {
	corner(12),
	new("UIStroke", { Color = C.stroke, Thickness = 1 }),
})

local header = new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Parent = panel,
}, {
	new("UIGradient", { Color = ColorSequence.new(C.grad1, C.grad2), Rotation = 0 }),
})

new("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0),
	Position = UDim2.fromOffset(12, 0),
	BackgroundTransparency = 1,
	Text = "🎯 Teleport",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
})

local minBtn = new("TextButton", {
	Size = UDim2.fromOffset(20, 20),
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, -52, 0.5, 0),
	BackgroundColor3 = C.warn,
	Text = "–",
	TextColor3 = Color3.fromRGB(40, 30, 10),
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Parent = header,
}, { corner(10) })

local closeBtn = new("TextButton", {
	Size = UDim2.fromOffset(20, 20),
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, -28, 0.5, 0),
	BackgroundColor3 = C.danger,
	Text = "×",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Parent = header,
}, { corner(10) })

-- KONTEN (ukuran TETAP supaya tidak negatif saat minimize)
local konten = new("Frame", {
	Name = "Konten",
	Size = UDim2.new(1, 0, 0, PANEL_H - HEADER_H),
	Position = UDim2.fromOffset(0, HEADER_H),
	BackgroundTransparency = 1,
	Parent = panel,
})

local searchBox = new("TextBox", {
	Size = UDim2.new(1, -62, 0, 28),
	Position = UDim2.fromOffset(8, 8),
	BackgroundColor3 = C.surface,
	BorderSizePixel = 0,
	PlaceholderText = "🔍 Cari / ketik username...",
	PlaceholderColor3 = C.subtext,
	Text = "",
	TextColor3 = C.text,
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	Parent = konten,
}, {
	corner(8),
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
})

local goBtn = new("TextButton", {
	Size = UDim2.fromOffset(42, 28),
	Position = UDim2.new(1, -50, 0, 8),
	BackgroundColor3 = C.accent,
	Text = "GO",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Parent = konten,
}, { corner(8) })
hover(goBtn, C.accent, C.accentHover)

local scroll = new("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -100),
	Position = UDim2.fromOffset(8, 44),
	BackgroundColor3 = C.list,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.stroke,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = konten,
}, {
	corner(8),
	new("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6),
	}),
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local emptyLabel = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.fromOffset(0, 50),
	BackgroundTransparency = 1,
	Text = "Tidak ada pemain",
	TextColor3 = C.subtext,
	TextSize = 11,
	Font = Enum.Font.Gotham,
	Visible = false,
	Parent = konten,
})

-- Baris status (di atas tombol mode)
local statusLabel = new("TextLabel", {
	Size = UDim2.new(1, -16, 0, 20),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 8, 1, -34),
	BackgroundColor3 = C.surface,
	Text = "",
	TextColor3 = C.subtext,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Parent = konten,
}, { corner(6) })

-- Baris tombol: Mode (kiri) + Kecepatan (kanan)
local modeBtn = new("TextButton", {
	Size = UDim2.new(0.5, -12, 0, 22),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 8, 1, -6),
	BackgroundColor3 = C.surface,
	Text = "",
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Parent = konten,
}, { corner(6) })
hover(modeBtn, C.surface, C.surfaceHover)

local speedBtn = new("TextButton", {
	Size = UDim2.new(0.5, -12, 0, 22),
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -8, 1, -6),
	BackgroundColor3 = C.surface,
	Text = "",
	TextColor3 = C.text,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Parent = konten,
}, { corner(6) })
hover(speedBtn, C.surface, C.surfaceHover)

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------
local panelOpen = false
local minimized = false
local popupOpen = false
local teleporting = false
local runCancel = false
local fadeToken = 0
local statusToken = 0
local rows = {}

local MODES = { "tween", "instan", "lari" }
local MODE_NAMES = { tween = "Tween (meluncur)", instan = "Instan", lari = "Lari (berjalan)" }
local modeIdx = 1
local mode = MODES[modeIdx]
local tweenIdx = 2
local runIdx = 2
local TWEEN_SPEED = TWEEN_SPEEDS[tweenIdx]

local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

---------------------------------------------------------------------
-- STATUS / NOTIFIKASI
---------------------------------------------------------------------
local function defaultStatus()
	local n = 0
	for _, d in pairs(rows) do
		if d.frame.Visible then n += 1 end
	end
	statusLabel.Text = "👥 " .. n .. " pemain"
	statusLabel.TextColor3 = C.subtext
end

local function notify(text, color)
	statusToken += 1
	local token = statusToken
	statusLabel.Text = text
	statusLabel.TextColor3 = color or C.text
	task.delay(2.5, function()
		if token == statusToken then defaultStatus() end
	end)
end

---------------------------------------------------------------------
-- TOMBOL MODE & KECEPATAN
---------------------------------------------------------------------
local function refreshButtons()
	if mode == "tween" then
		modeBtn.Text = "✨ Tween"
		modeBtn.TextColor3 = C.accent
		speedBtn.Visible = true
		speedBtn.Text = "⏩ " .. TWEEN_SPEEDS[tweenIdx]
	elseif mode == "instan" then
		modeBtn.Text = "⚡ Instan"
		modeBtn.TextColor3 = C.warn
		speedBtn.Visible = false
	else
		modeBtn.Text = "🏃 Lari"
		modeBtn.TextColor3 = C.success
		speedBtn.Visible = true
		speedBtn.Text = "⏩ " .. RUN_LEVELS[runIdx]
	end
end

modeBtn.MouseButton1Click:Connect(function()
	if teleporting then
		notify("Tunggu proses selesai.", C.warn)
		return
	end
	modeIdx = modeIdx % #MODES + 1
	mode = MODES[modeIdx]
	refreshButtons()
	notify("Mode: " .. MODE_NAMES[mode], C.text)
end)

speedBtn.MouseButton1Click:Connect(function()
	if mode == "tween" then
		tweenIdx = tweenIdx % #TWEEN_SPEEDS + 1
		TWEEN_SPEED = TWEEN_SPEEDS[tweenIdx]
		notify("Kecepatan tween: " .. TWEEN_SPEED, C.text)
	elseif mode == "lari" then
		runIdx = runIdx % #RUN_LEVELS + 1
		notify("Kecepatan lari: " .. RUN_LEVELS[runIdx], C.text)
	end
	refreshButtons()
end)

refreshButtons()

---------------------------------------------------------------------
-- POSISI PANEL
---------------------------------------------------------------------
local function placePanel()
	local bx, by = toggleBtn.Position.X.Offset, toggleBtn.Position.Y.Offset
	local vp = viewport()
	local x = bx + BTN_SIZE + 10
	if x + PANEL_W > vp.X then x = bx - PANEL_W - 10 end
	local h = minimized and HEADER_H or PANEL_H
	local p = clampPos(x, by, PANEL_W, h)
	panel.Position = UDim2.fromOffset(p.X, p.Y)
end

local function setPanelOpen(open)
	panelOpen = open
	fadeToken += 1
	local token = fadeToken
	if open then
		placePanel()
		panel.Visible = true
		TweenService:Create(panel, fadeInfo, { GroupTransparency = 0 }):Play()
	else
		local tw = TweenService:Create(panel, fadeInfo, { GroupTransparency = 1 })
		tw:Play()
		tw.Completed:Connect(function()
			if token == fadeToken then panel.Visible = false end
		end)
	end
end

local function toggleMinimize()
	minimized = not minimized
	minBtn.Text = minimized and "+" or "–"
	if minimized then
		local tw = tween(panel, 0.2, { Size = UDim2.fromOffset(PANEL_W, HEADER_H) })
		tw.Completed:Connect(function()
			if minimized then konten.Visible = false end
		end)
	else
		konten.Visible = true
		local p = clampPos(panel.Position.X.Offset, panel.Position.Y.Offset, PANEL_W, PANEL_H)
		tween(panel, 0.2, {
			Size = UDim2.fromOffset(PANEL_W, PANEL_H),
			Position = UDim2.fromOffset(p.X, p.Y),
		})
	end
end

---------------------------------------------------------------------
-- DRAG
---------------------------------------------------------------------
local function makeDraggable(handle, target, onMoved, onClick)
	local dragging, moved, dragInput, startMouse, startPos = false, false, nil, nil, nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved, dragInput = true, false, input
			startMouse = input.Position
			startPos = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput then
			local d = input.Position - startMouse
			local delta = Vector2.new(d.X, d.Y)
			if not moved and delta.Magnitude < DRAG_THRESHOLD then return end
			moved = true
			local size = target.AbsoluteSize
			local p = clampPos(startPos.X + delta.X, startPos.Y + delta.Y, size.X, size.Y)
			target.Position = UDim2.fromOffset(p.X, p.Y)
			if onMoved then onMoved() end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false
			if not moved and onClick then onClick() end
		end
	end)
end

makeDraggable(header, panel)
makeDraggable(toggleBtn, toggleBtn, function()
	if panelOpen then placePanel() end
end, function()
	setPanelOpen(not panelOpen)
end)

hover(toggleBtn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 225, 255))

---------------------------------------------------------------------
-- TELEPORT: helper
---------------------------------------------------------------------
local function getRoots(target)
	local myChar, tChar = player.Character, target.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
	return myRoot, tRoot
end

-- Cari model kendaraan jika pemain sedang menyetir (VehicleSeat)
local function getVehicle(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not seat or not seat:IsA("VehicleSeat") then return nil end

	local model = seat:FindFirstAncestorOfClass("Model")
	while model and model.Parent and model.Parent:IsA("Model") do
		model = model.Parent
	end
	return model, seat
end

local function destinationCF(targetRoot, isVehicle)
	if isVehicle then
		return targetRoot.CFrame * CFrame.new(0, 3, 10)
	end
	return targetRoot.CFrame * CFrame.new(0, 0, 3)
end

local function resetVelocity(char, seat)
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if seat then
		seat.AssemblyLinearVelocity = Vector3.zero
		seat.AssemblyAngularVelocity = Vector3.zero
	end
end

---------------------------------------------------------------------
-- MODE INSTAN (layar fade hitam)
---------------------------------------------------------------------
local function runInstant(target)
	local fade = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 999,
		Parent = screenGui,
	})
	tween(fade, 0.2, { BackgroundTransparency = 0 })
	task.wait(0.25)

	local myRoot, tRoot = getRoots(target)
	if myRoot and tRoot and target.Parent == Players then
		local char = myRoot.Parent
		local vehicle, seat = getVehicle(char)
		if vehicle then
			vehicle:PivotTo(destinationCF(tRoot, true))
			resetVelocity(char, seat)
			notify("✔ Teleport (+kendaraan) ke " .. target.DisplayName, C.success)
		else
			char:PivotTo(destinationCF(tRoot, false))
			notify("✔ Teleport ke " .. target.DisplayName, C.success)
		end
	else
		notify("Gagal: karakter berubah.", C.danger)
	end

	task.wait(0.1)
	tween(fade, 0.3, { BackgroundTransparency = 1 })
	task.wait(0.3)
	fade:Destroy()
end

---------------------------------------------------------------------
-- MODE TWEEN (meluncur mulus, mengikuti target yang bergerak)
---------------------------------------------------------------------
local function runTween(target)
	local myRoot, tRoot = getRoots(target)
	if not myRoot or not tRoot then
		notify("Karakter belum siap.", C.danger)
		return
	end

	local char = myRoot.Parent
	local hum = char:FindFirstChildOfClass("Humanoid")
	local vehicle, seat = getVehicle(char)
	local mover = vehicle or char
	local isVehicle = vehicle ~= nil

	local startCF = mover:GetPivot()
	local dist = (destinationCF(tRoot, isVehicle).Position - startCF.Position).Magnitude
	local duration = math.clamp(dist / TWEEN_SPEED, TWEEN_MIN, TWEEN_MAX)

	local anchoredState = {}
	local function lock(model)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				anchoredState[d] = d.Anchored
				d.Anchored = true
			end
		end
	end
	lock(char)
	if vehicle then lock(vehicle) end

	notify("✨ Meluncur ke " .. target.DisplayName .. "...", C.accent)

	local completed = false
	local ok = pcall(function()
		local elapsed = 0
		while elapsed < duration do
			elapsed += RunService.Heartbeat:Wait()

			local _, tr = getRoots(target)
			if not tr or target.Parent ~= Players or not char.Parent or (hum and hum.Health <= 0) then
				return
			end

			local a = TweenService:GetValue(
				math.min(elapsed / duration, 1),
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut
			)
			local destCF = destinationCF(tr, isVehicle)
			local pos = startCF.Position:Lerp(destCF.Position, a)
				+ Vector3.new(0, math.sin(a * math.pi) * TWEEN_LIFT, 0)
			local rot = startCF.Rotation:Lerp(destCF.Rotation, a)
			mover:PivotTo(CFrame.new(pos) * rot)
		end
		completed = true
	end)

	for part, was in pairs(anchoredState) do
		if part.Parent then part.Anchored = was end
	end
	if char.Parent then resetVelocity(char, seat) end

	if ok and completed then
		notify("✔ Sampai di " .. target.DisplayName, C.success)
	else
		notify("Dibatalkan: target/karakter berubah.", C.danger)
	end
end

---------------------------------------------------------------------
-- MODE LARI (berjalan lewat pathfinding, speed diberikan server)
---------------------------------------------------------------------
local function runWalk(target)
	local myRoot, tRoot = getRoots(target)
	if not myRoot or not tRoot then
		notify("Karakter belum siap.", C.danger)
		return
	end

	local char = myRoot.Parent
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		notify("Karakter kamu belum siap.", C.danger)
		return
	end
	if hum.SeatPart then
		notify("Turun dari kendaraan dulu.", C.warn)
		return
	end

	-- Minta server menaikkan speed (server yang menentukan angkanya)
	local rfRun = ReplicatedStorage:FindFirstChild("RunRequest")
	if rfRun then
		local okInv, allowed, info = pcall(function()
			return rfRun:InvokeServer("start", runIdx)
		end)
		if not okInv or not allowed then
			notify(tostring(okInv and info or "Gagal menghubungi server."), C.danger)
			return
		end
else
		notify("RunRequest belum ada, lari dengan speed normal")
end
   
runCancel = false
	local startT = os.clock()
	local reached = false
	local waypoints, wpIndex, lastPath = nil, 2, 0
	local path = PathfindingService:CreatePath({
		AgentRadius = 2, AgentHeight = 5, AgentCanJump = true,
	})

	notify("🏃 Lari ke " .. target.DisplayName .. " (ketuk lagi = batal)", C.accent)

	while not runCancel and os.clock() - startT < RUN_TIMEOUT do
		local _, tr = getRoots(target)
		if not tr or target.Parent ~= Players or not char.Parent
			or not myRoot.Parent or hum.Health <= 0 then
			break
		end

		local myPos = myRoot.Position
		if (tr.Position - myPos).Magnitude <= RUN_STOP_DIST then
			reached = true
			break
		end

		-- hitung ulang rute tiap ~1 detik (target bisa bergerak)
		if os.clock() - lastPath > 1 then
			lastPath = os.clock()
			local okP = pcall(function() path:ComputeAsync(myPos, tr.Position) end)
			if okP and path.Status == Enum.PathStatus.Success then
				waypoints = path:GetWaypoints()
				wpIndex = 2
			else
				waypoints = nil
			end
		end

		if waypoints and waypoints[wpIndex] then
			local wp = waypoints[wpIndex]
			hum:MoveTo(wp.Position)
			if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
			local flat = Vector3.new(wp.Position.X - myPos.X, 0, wp.Position.Z - myPos.Z).Magnitude
			if flat < 4 then wpIndex += 1 end
		else
			hum:MoveTo(tr.Position) -- cadangan: lurus ke target
		end

		RunService.Heartbeat:Wait()
	end

	if myRoot.Parent and hum.Parent then hum:MoveTo(myRoot.Position) end
	if rfRun then pcall(function() rfRun:InvokeServer("stop") end) end

	if reached then
		notify("✔ Sampai di " .. target.DisplayName, C.success)
	elseif runCancel then
		notify("Lari dibatalkan.", C.warn)
	else
		notify("Gagal sampai (target hilang / waktu habis).", C.danger)
	end
end

---------------------------------------------------------------------
-- TELEPORT UTAMA
---------------------------------------------------------------------
local function teleportTo(target)
	if teleporting then
		if mode == "lari" then runCancel = true end -- ketuk lagi = batal
		return
	end
	if not target or target == player or target.Parent ~= Players then
		notify("Pemain tidak valid.", C.danger)
		return
	end

	local myRoot, tRoot = getRoots(target)
	if not myRoot then notify("Karakter kamu belum siap.", C.danger) return end
	if not tRoot then
		notify(target.DisplayName .. " belum dimuat / terlalu jauh.", C.warn)
		return
	end

	teleporting = true

	if mode == "lari" then
		runWalk(target)
	else
		-- izin teleport dari server (jika script AntiCheat dipasang)
		local rf = ReplicatedStorage:FindFirstChild("TeleportRequest")
		if rf then
			local okInv, allowed, info = pcall(function() return rf:InvokeServer(target) end)
			if not okInv or not allowed then
				notify(tostring(okInv and info or "Gagal menghubungi server."), C.danger)
				teleporting = false
				return
			end
		end

		if mode == "tween" then
			runTween(target)
		else
			runInstant(target)
		end
	end

	teleporting = false
end

---------------------------------------------------------------------
-- DAFTAR PEMAIN
---------------------------------------------------------------------
local function applyFilter()
	local q = searchBox.Text:lower()
	local list = {}
	for plr, d in pairs(rows) do
		local match = q == "" or d.search:find(q, 1, true) ~= nil
		d.frame.Visible = match
		table.insert(list, plr)
	end
	table.sort(list, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
	for i, plr in ipairs(list) do rows[plr].frame.LayoutOrder = i end

	local any = false
	for _, d in pairs(rows) do
		if d.frame.Visible then any = true break end
	end
	emptyLabel.Visible = not any
	defaultStatus()
end

local function addRow(plr)
	if plr == player or rows[plr] then return end

	local row = new("TextButton", {
		Name = "Player_" .. plr.Name,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.surface,
		Text = "",
		AutoButtonColor = false,
		Parent = scroll,
	}, { corner(8) })

	new("ImageLabel", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 6, 0.5, -13),
		BackgroundColor3 = C.stroke,
		BorderSizePixel = 0,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48",
		Parent = row,
	}, { corner(13) })

	new("TextLabel", {
		Size = UDim2.new(1, -66, 0, 16),
		Position = UDim2.fromOffset(38, 4),
		BackgroundTransparency = 1,
		Text = plr.DisplayName,
		TextColor3 = C.text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -66, 0, 12),
		Position = UDim2.fromOffset(38, 20),
		BackgroundTransparency = 1,
		Text = "@" .. plr.Name,
		TextColor3 = C.subtext,
		TextSize = 10,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	new("TextLabel", {
		Size = UDim2.fromOffset(20, 38),
		Position = UDim2.new(1, -24, 0, 0),
		BackgroundTransparency = 1,
		Text = "➤",
		TextColor3 = C.accent,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Parent = row,
	})

	hover(row, C.surface, C.surfaceHover)
	row.MouseButton1Click:Connect(function() teleportTo(plr) end)

	rows[plr] = { frame = row, search = (plr.Name .. " " .. plr.DisplayName):lower() }
	applyFilter()
end

local function removeRow(plr)
	local d = rows[plr]
	if d then
		d.frame:Destroy()
		rows[plr] = nil
		applyFilter()
	end
end

for _, p in ipairs(Players:GetPlayers()) do addRow(p) end
Players.PlayerAdded:Connect(addRow)
Players.PlayerRemoving:Connect(removeRow)

searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

---------------------------------------------------------------------
-- PENCARIAN TOMBOL GO
---------------------------------------------------------------------
local function findPlayer(query)
	query = query:lower()
	if query == "" then return nil end
	local prefix, contains
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local n, d = p.Name:lower(), p.DisplayName:lower()
			if n == query or d == query then return p end
			if not prefix and (n:sub(1, #query) == query or d:sub(1, #query) == query) then prefix = p end
			if not contains and (n:find(query, 1, true) or d:find(query, 1, true)) then contains = p end
		end
	end
	return prefix or contains
end

local function goSearch()
	if teleporting then
		if mode == "lari" then runCancel = true end
		return
	end
	if searchBox.Text == "" then
		notify("Ketik username dulu.", C.warn)
		return
	end
	local target = findPlayer(searchBox.Text)
	if target then
		teleportTo(target)
	else
		notify("Pemain tidak ditemukan.", C.danger)
	end
end

goBtn.MouseButton1Click:Connect(goSearch)
searchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then goSearch() end
end)

---------------------------------------------------------------------
-- POPUP KONFIRMASI
---------------------------------------------------------------------
local function showConfirm(onYes)
	if popupOpen then return end
	popupOpen = true

	local overlay = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Parent = screenGui,
	})

	local box = new("Frame", {
		Size = UDim2.fromOffset(240, 120),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C.bg,
		BorderSizePixel = 0,
		ZIndex = 51,
		Parent = screenGui,
	}, {
		corner(12),
		new("UIStroke", { Color = C.stroke, Thickness = 1.5 }),
	})

	new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 52),
		Position = UDim2.fromOffset(12, 10),
		BackgroundTransparency = 1,
		Text = "Hilangkan UI sepenuhnya?\nTekan " .. HOTKEY.Name .. " untuk memunculkan lagi.",
		TextColor3 = C.text,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		ZIndex = 52,
		Parent = box,
	})

	local function makeBtn(text, color, pos)
		return new("TextButton", {
			Size = UDim2.fromOffset(90, 28),
			Position = pos,
			BackgroundColor3 = color,
			Text = text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			ZIndex = 52,
			Parent = box,
		}, { corner(8) })
	end

	local yesBtn = makeBtn("Ya", C.danger, UDim2.new(0, 20, 1, -40))
	local noBtn = makeBtn("Batal", C.accent, UDim2.new(1, -110, 1, -40))

	local function close()
		popupOpen = false
		overlay:Destroy()
		box:Destroy()
	end

	yesBtn.MouseButton1Click:Connect(function() close() onYes() end)
	noBtn.MouseButton1Click:Connect(close)
	overlay.MouseButton1Click:Connect(close)
end

---------------------------------------------------------------------
-- TOMBOL HEADER
---------------------------------------------------------------------
minBtn.MouseButton1Click:Connect(toggleMinimize)

closeBtn.MouseButton1Click:Connect(function()
	showConfirm(function()
		runCancel = true
		setPanelOpen(false)
		minimized = false
		konten.Visible = true
		panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
		minBtn.Text = "–"
		screenGui.Enabled = false
	end)
end)

---------------------------------------------------------------------
-- HOTKEY
---------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or popupOpen then return end
	if input.KeyCode ~= HOTKEY then return end

	if not screenGui.Enabled then
		screenGui.Enabled = true
		return
	end
	setPanelOpen(not panelOpen)
end)

applyFilter()
