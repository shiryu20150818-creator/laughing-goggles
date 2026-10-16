--[[
  ★ NEKO EXECUTOR ★
  アップロードされた Script Manager (SMUI) をベースに、本物のエグゼキューターのような
  見た目・演出に全面強化した統合スクリプトです。

  機能:
  - 起動スプラッシュ(ロゴ+プログレスバー+起動音)
  - エディタタブ: 行番号ガター + 簡易シンタックスハイライト + 実行/クリア/保存
  - スクリプトタブ: 保存済みスクリプトの一覧・実行・長押し削除・エディタへ読込
  - Hubタブ: ScriptBlox検索 → 実行/保存/エディタへ読込
  - コンソールタブ: 実行ログ(色分け・タイムスタンプ付き)
  - 設定タブ: アクセントカラー切替・起動音ON/OFF
  - 最小化/復元・ウィンドウオープンのアニメーション
]]

local P = game:GetService("Players")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")
local T = game:GetService("TweenService")
local SS = game:GetService("SoundService")
local LP = P.LocalPlayer

local SND = "rbxassetid://9085027122"

local function N(t, d)
	pcall(function() SG:SetCore("SendNotification", {Title = t, Text = d or "", Duration = 3}) end)
end

-- ==============================
-- ★ カラーテーマ ★
-- ==============================
local ACC1 = Color3.fromRGB(150, 100, 255)
local ACC2 = Color3.fromRGB(80, 200, 255)
local BG1 = Color3.fromRGB(12, 12, 18)
local BG2 = Color3.fromRGB(18, 18, 26)
local BG3 = Color3.fromRGB(26, 26, 36)
local BG4 = Color3.fromRGB(40, 40, 55)
local TXT = Color3.fromRGB(230, 230, 245)
local SUB = Color3.fromRGB(150, 150, 170)
local GOOD = Color3.fromRGB(90, 220, 140)
local BAD = Color3.fromRGB(255, 100, 120)
local WARN = Color3.fromRGB(255, 200, 90)

local PRESETS = {
	{Color3.fromRGB(150,100,255), Color3.fromRGB(80,200,255)},
	{Color3.fromRGB(90,220,140), Color3.fromRGB(80,255,200)},
	{Color3.fromRGB(255,100,140), Color3.fromRGB(255,170,80)},
	{Color3.fromRGB(255,200,60), Color3.fromRGB(255,120,60)},
	{Color3.fromRGB(80,200,255), Color3.fromRGB(80,255,220)},
}

-- ==============================
-- ★ 永続データ (再実行してもセッション内で保持) ★
-- ==============================
getgenv().SM = getgenv().SM or {}
local S = getgenv().SM
getgenv().SMSettings = getgenv().SMSettings or {BootSound=true, AccentIndex=1}
local Settings = getgenv().SMSettings

-- ==============================
-- ★ 起動音 + スプラッシュ ★
-- ==============================
local function PlayBootSound()
	if not Settings.BootSound then return end
	local ok = pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = SND
		s.Volume = 0.55
		s.Parent = SS
		if not s.IsLoaded then pcall(function() s.Loaded:Wait() end) end
		s:Play()
		task.delay(6, function() pcall(function() s:Destroy() end) end)
	end)
	if not ok then
		pcall(function()
			local s2 = Instance.new("Sound")
			s2.SoundId = SND
			s2.Volume = 0.55
			s2.Parent = SS
			s2:Play()
			task.delay(6, function() pcall(function() s2:Destroy() end) end)
		end)
	end
end

local function ShowBootSplash(onDone)
	PlayBootSound()
	local boot = Instance.new("ScreenGui")
	boot.Name = "NEBoot"
	boot.ResetOnSpawn = false
	boot.Parent = LP:WaitForChild("PlayerGui")

	local bg = Instance.new("Frame", boot)
	bg.Size = UDim2.new(1,0,1,0)
	bg.BackgroundColor3 = Color3.fromRGB(6,6,10)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	T:Create(bg, TweenInfo.new(.35), {BackgroundTransparency=0}):Play()

	local logo = Instance.new("TextLabel", bg)
	logo.AnchorPoint = Vector2.new(.5,.5)
	logo.Position = UDim2.new(.5,0,.42,0)
	logo.Size = UDim2.new(0,10,0,10)
	logo.BackgroundTransparency = 1
	logo.Text = "NEKO EXECUTOR"
	logo.TextColor3 = TXT
	logo.Font = Enum.Font.GothamBlack
	logo.TextScaled = true
	logo.TextTransparency = 1
	local lg = Instance.new("UIGradient", logo)
	lg.Color = ColorSequence.new(ACC1, ACC2)
	lg.Rotation = 45
	T:Create(logo, TweenInfo.new(.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size=UDim2.new(0,300,0,56), TextTransparency=0}):Play()

	local sub = Instance.new("TextLabel", bg)
	sub.AnchorPoint = Vector2.new(.5,.5)
	sub.Position = UDim2.new(.5,0,.52,0)
	sub.Size = UDim2.new(0,340,0,20)
	sub.BackgroundTransparency = 1
	sub.Text = "コアモジュールを初期化中..."
	sub.TextColor3 = SUB
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 13
	sub.TextTransparency = 1
	task.delay(.3, function() T:Create(sub, TweenInfo.new(.4), {TextTransparency=0}):Play() end)

	local barBg = Instance.new("Frame", bg)
	barBg.AnchorPoint = Vector2.new(.5,.5)
	barBg.Position = UDim2.new(.5,0,.6,0)
	barBg.Size = UDim2.new(0,300,0,6)
	barBg.BackgroundColor3 = BG4
	barBg.BorderSizePixel = 0
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)
	local barFill = Instance.new("Frame", barBg)
	barFill.Size = UDim2.new(0,0,1,0)
	barFill.BackgroundColor3 = ACC1
	barFill.BorderSizePixel = 0
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)
	local bg2 = Instance.new("UIGradient", barFill)
	bg2.Color = ColorSequence.new(ACC1, ACC2)

	task.spawn(function()
		task.wait(.4)
		local steps = {
			{20, "スクリプトライブラリを読み込み中..."},
			{45, "エディタをレンダリング中..."},
			{70, "保存データを復元中..."},
			{90, "UIを構築中..."},
			{100, "準備完了!"},
		}
		for _, st in ipairs(steps) do
			T:Create(barFill, TweenInfo.new(.25, Enum.EasingStyle.Quad), {Size=UDim2.new(st[1]/100,0,1,0)}):Play()
			sub.Text = st[2]
			task.wait(.28)
		end
		task.wait(.25)
		local fo = T:Create(bg, TweenInfo.new(.4), {BackgroundTransparency=1})
		T:Create(logo, TweenInfo.new(.3), {TextTransparency=1}):Play()
		T:Create(sub, TweenInfo.new(.3), {TextTransparency=1}):Play()
		fo:Play()
		fo.Completed:Wait()
		pcall(function() boot:Destroy() end)
		if onDone then onDone() end
	end)
end

-- ==============================
-- ★ 簡易シンタックスハイライト ★
-- ==============================
local KEYWORDS = {"function","local","end","if","then","else","elseif","return","for","while","do",
	"repeat","until","break","and","or","not","nil","true","false","in"}

local function EscapeRich(s)
	s = s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
	return s
end

local function Highlight(text)
	local esc = EscapeRich(text)
	esc = esc:gsub('(%-%-[^\n]*)', function(c) return '<font color="#6A9955">'..c..'</font>' end)
	esc = esc:gsub('(".-")', function(c) return '<font color="#CE9178">'..c..'</font>' end)
	for _, kw in ipairs(KEYWORDS) do
		esc = esc:gsub('%f[%w]'..kw..'%f[%W]', '<font color="#C586C0">'..kw..'</font>')
	end
	return esc
end

-- ==============================
-- ★ コンソールログ ★
-- ==============================
local ConsoleEntries = {}
local RenderConsole -- 後で定義 (UI構築後に差し替え)
RenderConsole = function() end

local function Log(kind, text)
	local color = BAD
	if kind == "success" then color = GOOD
	elseif kind == "warn" then color = WARN
	elseif kind == "info" then color = TXT end
	table.insert(ConsoleEntries, {text=tostring(text), color=color, time=os.date("%H:%M:%S")})
	if #ConsoleEntries > 200 then table.remove(ConsoleEntries, 1) end
	pcall(RenderConsole)
end

-- ==============================
-- ★ 実行ロジック ★
-- ==============================
local function executeScript(code, name)
	N("実行中", name)
	Log("info", "["..name.."] 実行を開始しました")
	task.spawn(function()
		local ok, err = pcall(function()
			local f = loadstring(code)
			if f then
				f()
				N("完了", name)
				Log("success", "["..name.."] 実行完了")
			else
				N("エラー", "loadstring失敗")
				Log("error", "["..name.."] loadstring失敗")
			end
		end)
		if not ok then
			N("エラー", tostring(err))
			Log("error", "["..name.."] "..tostring(err))
		end
	end)
end

local function executeFromURL(url, name)
	N("実行中", name)
	Log("info", "["..name.."] URLから取得して実行中...")
	task.spawn(function()
		local ok, err = pcall(function()
			local s = game:HttpGet(url)
			local f = loadstring(s)
			if f then
				f()
				N("完了", name)
				Log("success", "["..name.."] 実行完了")
			else
				N("エラー", "loadstring失敗")
				Log("error", "["..name.."] loadstring失敗")
			end
		end)
		if not ok then
			N("エラー", tostring(err))
			Log("error", "["..name.."] "..tostring(err))
		end
	end)
end

-- ==============================
-- ★ UI構築 ★
-- ==============================
local function BuildUI()
	if LP:WaitForChild("PlayerGui"):FindFirstChild("NEUI") then LP.PlayerGui.NEUI:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "NEUI"
	gui.ResetOnSpawn = false
	gui.Parent = LP:WaitForChild("PlayerGui")

	local M = Instance.new("Frame")
	M.Size = UDim2.new(0, 420, 0, 600)
	M.Position = UDim2.new(0.5, -210, 0.5, -300)
	M.BackgroundColor3 = BG1
	M.BorderSizePixel = 0
	M.Active = true
	M.Draggable = true
	M.ClipsDescendants = true
	M.Parent = gui
	Instance.new("UICorner", M).CornerRadius = UDim.new(0, 14)
	local ms = Instance.new("UIStroke", M)
	ms.Color = ACC1
	ms.Thickness = 1.8
	ms.Transparency = 0.3
	local msg = Instance.new("UIGradient", ms)
	msg.Color = ColorSequence.new(ACC1, ACC2)
	msg.Rotation = 45

	-- オープンアニメーション
	M.Size = UDim2.new(0, 360, 0, 500)
	M.Position = UDim2.new(0.5, -180, 0.5, -250)
	T:Create(M, TweenInfo.new(.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size=UDim2.new(0,420,0,600), Position=UDim2.new(0.5,-210,0.5,-300)}):Play()

	-- タイトルバー
	local TB = Instance.new("Frame", M)
	TB.Size = UDim2.new(1, 0, 0, 44)
	TB.BackgroundColor3 = BG2
	TB.BorderSizePixel = 0
	Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 14)
	local tf = Instance.new("Frame", TB)
	tf.Size = UDim2.new(1, 0, 0, 14)
	tf.Position = UDim2.new(0, 0, 1, -14)
	tf.BackgroundColor3 = BG2
	tf.BorderSizePixel = 0

	local TL = Instance.new("TextLabel", TB)
	TL.Size = UDim2.new(1, -110, 1, 0)
	TL.Position = UDim2.new(0, 16, 0, 0)
	TL.BackgroundTransparency = 1
	TL.Text = "NEKO EXECUTOR"
	TL.TextColor3 = TXT
	TL.TextSize = 16
	TL.Font = Enum.Font.GothamBlack
	TL.TextXAlignment = Enum.TextXAlignment.Left
	local tlg = Instance.new("UIGradient", TL)
	tlg.Color = ColorSequence.new(ACC1, ACC2)
	tlg.Rotation = 45

	local MinB = Instance.new("TextButton", TB)
	MinB.Size = UDim2.new(0, 28, 0, 28)
	MinB.Position = UDim2.new(1, -66, 0, 8)
	MinB.BackgroundColor3 = BG4
	MinB.TextColor3 = ACC2
	MinB.Text = "—"
	MinB.Font = Enum.Font.GothamBold
	MinB.BorderSizePixel = 0
	Instance.new("UICorner", MinB).CornerRadius = UDim.new(0, 8)

	local CB = Instance.new("TextButton", TB)
	CB.Size = UDim2.new(0, 28, 0, 28)
	CB.Position = UDim2.new(1, -34, 0, 8)
	CB.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
	CB.TextColor3 = BAD
	CB.Text = "X"
	CB.Font = Enum.Font.GothamBold
	CB.BorderSizePixel = 0
	Instance.new("UICorner", CB).CornerRadius = UDim.new(0, 8)
	CB.MouseButton1Click:Connect(function() gui:Destroy() end)

	-- タブバー
	local TabNames = {"エディタ","スクリプト","Hub","コンソール","設定"}
	local TabBar = Instance.new("Frame", M)
	TabBar.Size = UDim2.new(1, -20, 0, 34)
	TabBar.Position = UDim2.new(0, 10, 0, 52)
	TabBar.BackgroundTransparency = 1

	local Indicator = Instance.new("Frame", TabBar)
	Indicator.Size = UDim2.new(0, 70, 0, 3)
	Indicator.Position = UDim2.new(0, 0, 1, -3)
	Indicator.BackgroundColor3 = ACC1
	Indicator.BorderSizePixel = 0
	Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

	local TabBtns = {}
	local tabW = 400 / #TabNames
	for i, name in ipairs(TabNames) do
		local b = Instance.new("TextButton", TabBar)
		b.Size = UDim2.new(0, tabW, 1, -4)
		b.Position = UDim2.new(0, (i-1)*tabW, 0, 0)
		b.BackgroundTransparency = 1
		b.Text = name
		b.TextColor3 = SUB
		b.TextSize = 12
		b.Font = Enum.Font.GothamBold
		TabBtns[i] = b
	end

	local Content = Instance.new("Frame", M)
	Content.Size = UDim2.new(1, -20, 1, -140)
	Content.Position = UDim2.new(0, 10, 0, 92)
	Content.BackgroundTransparency = 1

	-- ========== エディタタブ ==========
	local EditorFrame = Instance.new("Frame", Content)
	EditorFrame.Size = UDim2.new(1, 0, 1, 0)
	EditorFrame.BackgroundTransparency = 1

	local NB = Instance.new("TextBox", EditorFrame)
	NB.Size = UDim2.new(1, 0, 0, 32)
	NB.BackgroundColor3 = BG3
	NB.BorderSizePixel = 0
	NB.Text = ""
	NB.PlaceholderText = "スクリプト名"
	NB.TextColor3 = TXT
	NB.PlaceholderColor3 = SUB
	NB.TextSize = 13
	NB.Font = Enum.Font.Gotham
	NB.ClearTextOnFocus = false
	Instance.new("UICorner", NB).CornerRadius = UDim.new(0, 8)
	local nbp = Instance.new("UIPadding", NB)
	nbp.PaddingLeft = UDim.new(0, 10)

	local EditorScroll = Instance.new("ScrollingFrame", EditorFrame)
	EditorScroll.Size = UDim2.new(1, 0, 1, -78)
	EditorScroll.Position = UDim2.new(0, 0, 0, 40)
	EditorScroll.BackgroundColor3 = BG2
	EditorScroll.BorderSizePixel = 0
	EditorScroll.ScrollBarThickness = 4
	EditorScroll.ScrollBarImageColor3 = ACC1
	EditorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	EditorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Instance.new("UICorner", EditorScroll).CornerRadius = UDim.new(0, 8)

	local Gutter = Instance.new("TextLabel", EditorScroll)
	Gutter.Size = UDim2.new(0, 30, 0, 0)
	Gutter.AutomaticSize = Enum.AutomaticSize.Y
	Gutter.Position = UDim2.new(0, 0, 0, 0)
	Gutter.BackgroundColor3 = BG3
	Gutter.BorderSizePixel = 0
	Gutter.Text = "1"
	Gutter.TextColor3 = SUB
	Gutter.TextSize = 13
	Gutter.Font = Enum.Font.Code
	Gutter.TextXAlignment = Enum.TextXAlignment.Right
	Gutter.TextYAlignment = Enum.TextYAlignment.Top
	local gp = Instance.new("UIPadding", Gutter)
	gp.PaddingTop = UDim.new(0, 6)
	gp.PaddingRight = UDim.new(0, 6)

	local HighlightLabel = Instance.new("TextLabel", EditorScroll)
	HighlightLabel.Size = UDim2.new(1, -36, 0, 0)
	HighlightLabel.AutomaticSize = Enum.AutomaticSize.Y
	HighlightLabel.Position = UDim2.new(0, 34, 0, 0)
	HighlightLabel.BackgroundTransparency = 1
	HighlightLabel.Text = ""
	HighlightLabel.RichText = true
	HighlightLabel.TextColor3 = TXT
	HighlightLabel.TextSize = 13
	HighlightLabel.Font = Enum.Font.Code
	HighlightLabel.TextXAlignment = Enum.TextXAlignment.Left
	HighlightLabel.TextYAlignment = Enum.TextYAlignment.Top
	HighlightLabel.TextWrapped = true
	local hp = Instance.new("UIPadding", HighlightLabel)
	hp.PaddingTop = UDim.new(0, 6)
	hp.PaddingLeft = UDim.new(0, 4)

	local CodeBox = Instance.new("TextBox", EditorScroll)
	CodeBox.Size = UDim2.new(1, -36, 0, 0)
	CodeBox.AutomaticSize = Enum.AutomaticSize.Y
	CodeBox.Position = UDim2.new(0, 34, 0, 0)
	CodeBox.BackgroundTransparency = 1
	CodeBox.Text = ""
	CodeBox.PlaceholderText = "-- ここにLuaコードを入力..."
	CodeBox.TextColor3 = TXT
	CodeBox.TextTransparency = 0.97
	CodeBox.PlaceholderColor3 = SUB
	CodeBox.TextSize = 13
	CodeBox.Font = Enum.Font.Code
	CodeBox.MultiLine = true
	CodeBox.TextWrapped = true
	CodeBox.ClearTextOnFocus = false
	CodeBox.TextXAlignment = Enum.TextXAlignment.Left
	CodeBox.TextYAlignment = Enum.TextYAlignment.Top
	local cp = Instance.new("UIPadding", CodeBox)
	cp.PaddingTop = UDim.new(0, 6)
	cp.PaddingLeft = UDim.new(0, 4)

	local function UpdateEditor()
		local text = CodeBox.Text
		local _, n = text:gsub("\n", "\n")
		local lineCount = n + 1
		local nums = {}
		for i = 1, lineCount do nums[i] = tostring(i) end
		Gutter.Text = table.concat(nums, "\n")
		HighlightLabel.Text = Highlight(text)
	end
	CodeBox:GetPropertyChangedSignal("Text"):Connect(UpdateEditor)
	UpdateEditor()

	local BtnRow = Instance.new("Frame", EditorFrame)
	BtnRow.Size = UDim2.new(1, 0, 0, 36)
	BtnRow.Position = UDim2.new(0, 0, 1, -36)
	BtnRow.BackgroundTransparency = 1

	local function mkActionBtn(parent, text, pos, size, color)
		local b = Instance.new("TextButton", parent)
		b.Size = size
		b.Position = pos
		b.BackgroundColor3 = color
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.BorderSizePixel = 0
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		b.MouseEnter:Connect(function() T:Create(b, TweenInfo.new(.12), {BackgroundTransparency=.2}):Play() end)
		b.MouseLeave:Connect(function() T:Create(b, TweenInfo.new(.12), {BackgroundTransparency=0}):Play() end)
		return b
	end

	local ExecBtn = mkActionBtn(BtnRow, "▶ 実行", UDim2.new(0,0,0,0), UDim2.new(0.46,0,1,0), GOOD)
	local ClearBtn = mkActionBtn(BtnRow, "クリア", UDim2.new(0.48,0,0,0), UDim2.new(0.24,0,1,0), BG4)
	local SaveBtn = mkActionBtn(BtnRow, "💾 保存", UDim2.new(0.74,0,0,0), UDim2.new(0.26,0,1,0), ACC1)

	ExecBtn.MouseButton1Click:Connect(function()
		if CodeBox.Text == "" then N("エラー", "コードが空です") return end
		executeScript(CodeBox.Text, NB.Text ~= "" and NB.Text or "Editor")
	end)
	ClearBtn.MouseButton1Click:Connect(function()
		CodeBox.Text = ""
		NB.Text = ""
	end)
	SaveBtn.MouseButton1Click:Connect(function()
		if NB.Text == "" or CodeBox.Text == "" then N("エラー", "名前とコードを入力") return end
		table.insert(S, {name = NB.Text, code = CodeBox.Text})
		N("保存", "スクリプトを保存しました")
		Log("success", "「"..NB.Text.."」を保存しました")
	end)

	-- ========== スクリプトタブ (保存済み一覧) ==========
	local ScriptsFrame = Instance.new("Frame", Content)
	ScriptsFrame.Size = UDim2.new(1, 0, 1, 0)
	ScriptsFrame.BackgroundTransparency = 1
	ScriptsFrame.Visible = false

	local function mkScroll(par)
		local s = Instance.new("ScrollingFrame", par)
		s.Size = UDim2.new(1, 0, 1, 0)
		s.BackgroundColor3 = BG2
		s.BorderSizePixel = 0
		s.ScrollBarThickness = 4
		s.ScrollBarImageColor3 = ACC1
		s.CanvasSize = UDim2.new(0, 0, 0, 0)
		s.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Instance.new("UICorner", s).CornerRadius = UDim.new(0, 8)
		local l = Instance.new("UIListLayout", s)
		l.Padding = UDim.new(0, 4)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		local p = Instance.new("UIPadding", s)
		p.PaddingTop = UDim.new(0, 6)
		p.PaddingLeft = UDim.new(0, 6)
		p.PaddingRight = UDim.new(0, 6)
		p.PaddingBottom = UDim.new(0, 6)
		return s
	end

	local LF = mkScroll(ScriptsFrame)

	local function renderList()
		for _, c in ipairs(LF:GetChildren()) do
			if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
		end
		if #S == 0 then
			local e = Instance.new("TextLabel", LF)
			e.Size = UDim2.new(1, 0, 0, 40)
			e.BackgroundTransparency = 1
			e.Text = "保存されたスクリプトはありません"
			e.TextColor3 = SUB
			e.TextSize = 12
			e.Font = Enum.Font.Gotham
			return
		end
		for i, d in ipairs(S) do
			local it = Instance.new("Frame", LF)
			it.Size = UDim2.new(1, 0, 0, 52)
			it.BackgroundColor3 = BG4
			it.BackgroundTransparency = .3
			it.BorderSizePixel = 0
			it.LayoutOrder = i
			Instance.new("UICorner", it).CornerRadius = UDim.new(0, 8)
			local nl = Instance.new("TextLabel", it)
			nl.Size = UDim2.new(1, -130, 0, 20)
			nl.Position = UDim2.new(0, 10, 0, 6)
			nl.BackgroundTransparency = 1
			nl.Text = d.name
			nl.TextColor3 = TXT
			nl.TextSize = 13
			nl.Font = Enum.Font.GothamBold
			nl.TextXAlignment = Enum.TextXAlignment.Left
			nl.TextTruncate = Enum.TextTruncate.AtEnd
			local sl = Instance.new("TextLabel", it)
			sl.Size = UDim2.new(1, -130, 0, 16)
			sl.Position = UDim2.new(0, 10, 0, 28)
			sl.BackgroundTransparency = 1
			sl.Text = #d.code .. " 文字"
			sl.TextColor3 = SUB
			sl.TextSize = 10
			sl.Font = Enum.Font.Gotham
			sl.TextXAlignment = Enum.TextXAlignment.Left

			local rb = Instance.new("TextButton", it)
			rb.Size = UDim2.new(0, 40, 0, 40)
			rb.Position = UDim2.new(1, -46, 0, 6)
			rb.BackgroundColor3 = GOOD
			rb.TextColor3 = Color3.new(1,1,1)
			rb.TextSize = 11
			rb.Font = Enum.Font.GothamBold
			rb.Text = "実行"
			rb.BorderSizePixel = 0
			Instance.new("UICorner", rb).CornerRadius = UDim.new(0, 6)
			rb.MouseButton1Click:Connect(function() executeScript(d.code, d.name) end)

			local eb = Instance.new("TextButton", it)
			eb.Size = UDim2.new(0, 40, 0, 40)
			eb.Position = UDim2.new(1, -90, 0, 6)
			eb.BackgroundColor3 = ACC1
			eb.TextColor3 = Color3.new(1,1,1)
			eb.TextSize = 10
			eb.Font = Enum.Font.GothamBold
			eb.Text = "編集"
			eb.BorderSizePixel = 0
			Instance.new("UICorner", eb).CornerRadius = UDim.new(0, 6)
			eb.MouseButton1Click:Connect(function()
				NB.Text = d.name
				CodeBox.Text = d.code
				N("読込", d.name .. " をエディタに読み込みました")
			end)

			local ht = nil
			it.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
					ht = task.delay(1.5, function()
						table.remove(S, i)
						renderList()
						N("削除", d.name)
						Log("warn", "「"..d.name.."」を削除しました")
					end)
				end
			end)
			it.InputEnded:Connect(function()
				if ht then task.cancel(ht); ht = nil end
			end)
		end
	end

	-- ========== Hubタブ (ScriptBlox検索) ==========
	local HubFrame = Instance.new("Frame", Content)
	HubFrame.Size = UDim2.new(1, 0, 1, 0)
	HubFrame.BackgroundTransparency = 1
	HubFrame.Visible = false

	local SB = Instance.new("TextBox", HubFrame)
	SB.Size = UDim2.new(1, -90, 0, 34)
	SB.BackgroundColor3 = BG3
	SB.BorderSizePixel = 0
	SB.Text = ""
	SB.PlaceholderText = "キーワードを入力..."
	SB.TextColor3 = TXT
	SB.PlaceholderColor3 = SUB
	SB.TextSize = 12
	SB.Font = Enum.Font.Gotham
	SB.ClearTextOnFocus = false
	Instance.new("UICorner", SB).CornerRadius = UDim.new(0, 8)
	local sbp = Instance.new("UIPadding", SB)
	sbp.PaddingLeft = UDim.new(0, 10)

	local SBtn = Instance.new("TextButton", HubFrame)
	SBtn.Size = UDim2.new(0, 80, 0, 34)
	SBtn.Position = UDim2.new(1, -80, 0, 0)
	SBtn.BackgroundColor3 = ACC1
	SBtn.TextColor3 = Color3.new(1,1,1)
	SBtn.TextSize = 12
	SBtn.Font = Enum.Font.GothamBold
	SBtn.Text = "検索"
	SBtn.BorderSizePixel = 0
	Instance.new("UICorner", SBtn).CornerRadius = UDim.new(0, 8)

	local SRFWrap = Instance.new("Frame", HubFrame)
	SRFWrap.Size = UDim2.new(1, 0, 1, -42)
	SRFWrap.Position = UDim2.new(0, 0, 0, 42)
	SRFWrap.BackgroundTransparency = 1
	local SRF = mkScroll(SRFWrap)

	local function clearSearch()
		for _, c in ipairs(SRF:GetChildren()) do
			if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
		end
	end

	local function searchSB(q)
		clearSearch()
		if q == "" then N("エラー", "キーワードを入力") return end
		N("検索中", "ScriptBlox...")
		Log("info", "ScriptBloxで検索中: "..q)
		task.spawn(function()
			local ok, res = pcall(function()
				local r = request({Url = "https://scriptblox.com/api/script/search?q=" .. HS:UrlEncode(q), Method = "GET"})
				if r and r.Body then return HS:JSONDecode(r.Body) end
			end)
			if not ok or not res then N("エラー", "検索失敗"); Log("error", "検索失敗"); return end
			local scripts = res.result and res.result.scripts
			if not scripts or #scripts == 0 then N("検索", "結果なし"); Log("warn", "結果なし"); return end
			for i, d in ipairs(scripts) do
				if i > 30 then break end
				local it = Instance.new("Frame", SRF)
				it.Size = UDim2.new(1, 0, 0, 64)
				it.BackgroundColor3 = BG4
				it.BackgroundTransparency = .3
				it.BorderSizePixel = 0
				it.LayoutOrder = i
				Instance.new("UICorner", it).CornerRadius = UDim.new(0, 8)
				local tl = Instance.new("TextLabel", it)
				tl.Size = UDim2.new(1, -140, 0, 22)
				tl.Position = UDim2.new(0, 10, 0, 6)
				tl.BackgroundTransparency = 1
				tl.Text = d.title or "No Title"
				tl.TextColor3 = TXT
				tl.TextSize = 12
				tl.Font = Enum.Font.GothamBold
				tl.TextXAlignment = Enum.TextXAlignment.Left
				tl.TextTruncate = Enum.TextTruncate.AtEnd
				local vl = Instance.new("TextLabel", it)
				vl.Size = UDim2.new(1, -140, 0, 16)
				vl.Position = UDim2.new(0, 10, 0, 30)
				vl.BackgroundTransparency = 1
				vl.Text = "👁 " .. tostring(d.views or 0)
				vl.TextColor3 = SUB
				vl.TextSize = 10
				vl.Font = Enum.Font.Gotham
				vl.TextXAlignment = Enum.TextXAlignment.Left

				local eb = Instance.new("TextButton", it)
				eb.Size = UDim2.new(0, 38, 0, 38)
				eb.Position = UDim2.new(1, -44, 0, 13)
				eb.BackgroundColor3 = GOOD
				eb.TextColor3 = Color3.new(1,1,1)
				eb.TextSize = 10
				eb.Font = Enum.Font.GothamBold
				eb.Text = "実行"
				eb.BorderSizePixel = 0
				Instance.new("UICorner", eb).CornerRadius = UDim.new(0, 6)
				eb.MouseButton1Click:Connect(function()
					if d.script and d.script ~= "" then executeFromURL(d.script, d.title or "SB") end
				end)

				local sbtn = Instance.new("TextButton", it)
				sbtn.Size = UDim2.new(0, 38, 0, 38)
				sbtn.Position = UDim2.new(1, -86, 0, 13)
				sbtn.BackgroundColor3 = ACC1
				sbtn.TextColor3 = Color3.new(1,1,1)
				sbtn.TextSize = 10
				sbtn.Font = Enum.Font.GothamBold
				sbtn.Text = "保存"
				sbtn.BorderSizePixel = 0
				Instance.new("UICorner", sbtn).CornerRadius = UDim.new(0, 6)
				sbtn.MouseButton1Click:Connect(function()
					if d.script and d.script ~= "" then
						table.insert(S, {name = d.title or "SB", code = "loadstring(game:HttpGet(\"" .. d.script .. "\"))()"})
						N("保存", d.title)
						Log("success", "「"..(d.title or "SB").."」を保存しました")
					end
				end)

				local lb = Instance.new("TextButton", it)
				lb.Size = UDim2.new(0, 38, 0, 38)
				lb.Position = UDim2.new(1, -128, 0, 13)
				lb.BackgroundColor3 = BG3
				lb.TextColor3 = TXT
				lb.TextSize = 9
				lb.Font = Enum.Font.GothamBold
				lb.Text = "編集"
				lb.BorderSizePixel = 0
				Instance.new("UICorner", lb).CornerRadius = UDim.new(0, 6)
				lb.MouseButton1Click:Connect(function()
					if d.script and d.script ~= "" then
						NB.Text = d.title or "SB"
						CodeBox.Text = "loadstring(game:HttpGet(\"" .. d.script .. "\"))()"
						N("読込", "エディタに読み込みました")
					end
				end)
			end
			N("検索完了", #scripts .. "件")
			Log("success", #scripts.."件のスクリプトが見つかりました")
		end)
	end
	SBtn.MouseButton1Click:Connect(function() searchSB(SB.Text) end)

	-- ========== コンソールタブ ==========
	local ConsoleFrame = Instance.new("Frame", Content)
	ConsoleFrame.Size = UDim2.new(1, 0, 1, 0)
	ConsoleFrame.BackgroundTransparency = 1
	ConsoleFrame.Visible = false
	local ConsoleScroll = mkScroll(ConsoleFrame)

	RenderConsole = function()
		for _, c in ipairs(ConsoleScroll:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		for i, e in ipairs(ConsoleEntries) do
			local l = Instance.new("TextLabel", ConsoleScroll)
			l.Size = UDim2.new(1, 0, 0, 18)
			l.BackgroundTransparency = 1
			l.Text = "["..e.time.."] "..e.text
			l.TextColor3 = e.color
			l.TextSize = 11
			l.Font = Enum.Font.Code
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.TextWrapped = true
			l.LayoutOrder = i
		end
	end
	RenderConsole()

	local ClearLogBtn = Instance.new("TextButton", ConsoleFrame)
	ClearLogBtn.Size = UDim2.new(0, 90, 0, 26)
	ClearLogBtn.Position = UDim2.new(1, -90, 0, -30)
	ClearLogBtn.AnchorPoint = Vector2.new(0, 1)
	ClearLogBtn.BackgroundColor3 = BG4
	ClearLogBtn.TextColor3 = TXT
	ClearLogBtn.Text = "ログ消去"
	ClearLogBtn.TextSize = 11
	ClearLogBtn.Font = Enum.Font.GothamBold
	ClearLogBtn.BorderSizePixel = 0
	Instance.new("UICorner", ClearLogBtn).CornerRadius = UDim.new(0, 6)
	ClearLogBtn.MouseButton1Click:Connect(function()
		ConsoleEntries = {}
		RenderConsole()
	end)

	-- ========== 設定タブ ==========
	local SettingsFrame = Instance.new("Frame", Content)
	SettingsFrame.Size = UDim2.new(1, 0, 1, 0)
	SettingsFrame.BackgroundTransparency = 1
	SettingsFrame.Visible = false

	local themeLbl = Instance.new("TextLabel", SettingsFrame)
	themeLbl.Size = UDim2.new(1, 0, 0, 20)
	themeLbl.BackgroundTransparency = 1
	themeLbl.Text = "アクセントカラー"
	themeLbl.TextColor3 = SUB
	themeLbl.TextSize = 12
	themeLbl.Font = Enum.Font.GothamBold
	themeLbl.TextXAlignment = Enum.TextXAlignment.Left

	local ThemeRow = Instance.new("Frame", SettingsFrame)
	ThemeRow.Size = UDim2.new(1, 0, 0, 36)
	ThemeRow.Position = UDim2.new(0, 0, 0, 26)
	ThemeRow.BackgroundTransparency = 1

	local function ApplyAccent(c1, c2)
		ACC1, ACC2 = c1, c2
		for _, grad in ipairs({msg, tlg, lg, bg2}) do
			pcall(function() grad.Color = ColorSequence.new(c1, c2) end)
		end
		pcall(function() ms.Color = c1 end)
		pcall(function() Indicator.BackgroundColor3 = c1 end)
		pcall(function() barFill.BackgroundColor3 = c1 end)
		pcall(function() SBtn.BackgroundColor3 = c1 end)
		pcall(function() SaveBtn.BackgroundColor3 = c1 end)
		pcall(function() EditorScroll.ScrollBarImageColor3 = c1 end)
		pcall(function() LF.ScrollBarImageColor3 = c1 end)
		pcall(function() SRF.ScrollBarImageColor3 = c1 end)
		pcall(function() ConsoleScroll.ScrollBarImageColor3 = c1 end)
	end

	for i, pr in ipairs(PRESETS) do
		local b = Instance.new("TextButton", ThemeRow)
		b.Size = UDim2.new(0, 36, 0, 36)
		b.Position = UDim2.new(0, (i-1)*44, 0, 0)
		b.BackgroundColor3 = pr[1]
		b.Text = ""
		b.BorderSizePixel = 0
		Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
		b.MouseButton1Click:Connect(function()
			Settings.AccentIndex = i
			ApplyAccent(pr[1], pr[2])
		end)
	end

	local soundLbl = Instance.new("TextLabel", SettingsFrame)
	soundLbl.Size = UDim2.new(1, -60, 0, 30)
	soundLbl.Position = UDim2.new(0, 0, 0, 76)
	soundLbl.BackgroundTransparency = 1
	soundLbl.Text = "起動音"
	soundLbl.TextColor3 = TXT
	soundLbl.TextSize = 13
	soundLbl.Font = Enum.Font.GothamMedium
	soundLbl.TextXAlignment = Enum.TextXAlignment.Left

	local soundToggle = Instance.new("TextButton", SettingsFrame)
	soundToggle.Size = UDim2.new(0, 46, 0, 22)
	soundToggle.Position = UDim2.new(1, -46, 0, 80)
	soundToggle.BackgroundColor3 = Settings.BootSound and GOOD or BG4
	soundToggle.Text = Settings.BootSound and "ON" or "OFF"
	soundToggle.TextColor3 = Color3.new(1,1,1)
	soundToggle.TextSize = 11
	soundToggle.Font = Enum.Font.GothamBold
	soundToggle.BorderSizePixel = 0
	Instance.new("UICorner", soundToggle).CornerRadius = UDim.new(0, 11)
	soundToggle.MouseButton1Click:Connect(function()
		Settings.BootSound = not Settings.BootSound
		soundToggle.BackgroundColor3 = Settings.BootSound and GOOD or BG4
		soundToggle.Text = Settings.BootSound and "ON" or "OFF"
	end)

	-- ========== タブ切替ロジック ==========
	local Frames = {EditorFrame, ScriptsFrame, HubFrame, ConsoleFrame, SettingsFrame}
	local function selectTab(idx)
		for i, f in ipairs(Frames) do f.Visible = (i == idx) end
		for i, b in ipairs(TabBtns) do
			T:Create(b, TweenInfo.new(.15), {TextColor3 = (i==idx) and TXT or SUB}):Play()
		end
		T:Create(Indicator, TweenInfo.new(.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0,(idx-1)*tabW,1,-3)}):Play()
		if idx == 2 then renderList() end
	end
	for i, b in ipairs(TabBtns) do
		b.MouseButton1Click:Connect(function() selectTab(i) end)
	end
	selectTab(1)

	-- ========== 最小化 / 復元 ==========
	local MI = Instance.new("TextButton", gui)
	MI.Size = UDim2.new(0, 56, 0, 56)
	MI.Position = UDim2.new(0, 30, 0.5, -28)
	MI.BackgroundColor3 = BG1
	MI.TextColor3 = Color3.new(1, 1, 1)
	MI.TextSize = 28
	MI.Font = Enum.Font.GothamBlack
	MI.Text = "🥷"
	MI.Visible = false
	MI.Active = true
	MI.Draggable = true
	MI.BorderSizePixel = 0
	Instance.new("UICorner", MI).CornerRadius = UDim.new(0, 14)
	local mis = Instance.new("UIStroke", MI)
	mis.Color = ACC1
	mis.Thickness = 2
	local mig = Instance.new("UIGradient", MI)
	mig.Color = ColorSequence.new(ACC1, ACC2)
	mig.Rotation = 45

	MinB.MouseButton1Click:Connect(function()
		local tw = T:Create(M, TweenInfo.new(.2, Enum.EasingStyle.Quad), {Size=UDim2.new(0,0,0,0)})
		tw:Play()
		tw.Completed:Wait()
		M.Visible = false
		M.Size = UDim2.new(0,420,0,600)
		MI.Visible = true
		MI.Size = UDim2.new(0,0,0,0)
		T:Create(MI, TweenInfo.new(.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,56,0,56)}):Play()
	end)
	MI.MouseButton1Click:Connect(function()
		MI.Visible = false
		M.Visible = true
		M.Size = UDim2.new(0,0,0,0)
		T:Create(M, TweenInfo.new(.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,420,0,600)}):Play()
	end)

	Log("info", "NEKO EXECUTOR を起動しました")
	N("NEKO EXECUTOR", "読み込み完了")

	gui.Destroying:Connect(function()
		-- 片付け (現状常駐処理なし。将来的な拡張用フック)
	end)
end

-- ==============================
-- ★ 起動シーケンス ★
-- ==============================
ShowBootSplash(function()
	BuildUI()
end)
