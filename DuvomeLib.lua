-- Duvome | Standalone

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
-- Safe tween wrapper - silently ignores "not in workspace" errors
local _realTS = TweenService
TweenService = setmetatable({}, {
	__index = function(_, k)
		if k == "Create" then
			return function(_, obj, info, props)
				local ok, tween = pcall(function()
					return _realTS:Create(obj, info, props)
				end)
				if ok and tween then
					return setmetatable({}, {
						__index = function(_, m)
							if m == "Play" then
								return function()
									pcall(function() tween:Play() end)
								end
							end
							return tween[m]
						end
					})
				end
				return setmetatable({}, {__index = function() return function() end end})
			end
		end
		return _realTS[k]
	end
})
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local BICONS_PATH = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"

local function SafeFont(path, weight, style)
	local ok, f = pcall(Font.new, path, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
	return ok and f or Font.fromEnum(Enum.Font.GothamBold)
end

local function SetFontFace(obj, path)
	pcall(function()
		obj.FontFace = Font.new(path or BICONS_PATH, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	end)
end

local function MakeBIconFont()
	local ok, f = pcall(Font.new, BICONS_PATH, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	return ok and f or nil
end


-- -- Executor Detection ------------------------------------------------------
local function GetExecutor()
	if identifyexecutor then
		local ok, name = pcall(identifyexecutor)
		if ok and name then return tostring(name):split(" ")[1] end
	end
	if syn then return "Synapse" end
	if KRNL_LOADED then return "Krnl" end
	if getexecutorname then
		local ok, name = pcall(getexecutorname)
		if ok and name then return tostring(name) end
	end
	return "Unknown"
end



local OrionLib = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Themes = {
		Default = {
			Main    = Color3.fromRGB(10, 4, 20),
			Second  = Color3.fromRGB(20, 8, 36),
			Stroke  = Color3.fromRGB(60, 20, 100),
			Divider = Color3.fromRGB(60, 20, 100),
			Text    = Color3.fromRGB(235, 210, 255),
			TextDark = Color3.fromRGB(140, 90, 190)
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false
}

local Icons = {}

pcall(function()
	local raw = game:HttpGet("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")
	if raw and #raw > 10 then
		local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok and decoded and decoded.icons then
			Icons = decoded.icons
		end
	end
end)

local function GetIcon(IconName)
	if Icons[IconName] ~= nil then
		return Icons[IconName]
	else
		return nil
	end
end

local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
pcall(function()
	if typeof(syn) == "table" and syn.protect_gui then
		syn.protect_gui(Orion)
		Orion.Parent = game.CoreGui
	end
end)
if not Orion.Parent then
	Orion.Parent = (typeof(gethui) == "function" and gethui()) or game.CoreGui
end

if typeof(gethui) == "function" then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Orion.Name and Interface ~= Orion then
			Interface:Destroy()
		end
	end
else
	for _, Interface in ipairs(game.CoreGui:GetChildren()) do
		if Interface.Name == Orion.Name and Interface ~= Orion then
			Interface:Destroy()
		end
	end
end

function OrionLib:IsRunning()
	return Orion ~= nil and Orion.Parent ~= nil
end

local function AddConnection(Signal, Function)
	if not OrionLib:IsRunning() then
		return
	end
	local SignalConnect = Signal:Connect(Function)
	table.insert(OrionLib.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while OrionLib:IsRunning() do
		wait()
	end
	for _, Connection in next, OrionLib.Connections do
		Connection:Disconnect()
	end
end)

local function AddDraggingFunctionality(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos = false
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				DragInput = Input
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)}):Play()
			end
		end)
	end)
end

local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do
		pcall(function() Object[i] = v end)
	end
	for i, v in next, Children or {} do
		pcall(function() v.Parent = Object end)
	end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	OrionLib.Elements[ElementName] = function(...)
		return ElementFunction(...)
	end
end

local function MakeElement(ElementName, ...)
	local NewElement = OrionLib.Elements[ElementName](...)
	return NewElement
end

local function SetProps(Element, Props)
	table.foreach(Props, function(Property, Value)
		Element[Property] = Value
	end)
	return Element
end

local function SetChildren(Element, Children)
	table.foreach(Children, function(_, Child)
		Child.Parent = Element
	end)
	return Element
end

local function Round(Number, Factor)
	local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
	if Result < 0 then Result = Result + Factor end
	return Result
end

local function ReturnProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then
		return "BackgroundColor3"
	end
	if Object:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	end
	if Object:IsA("UIStroke") then
		return "Color"
	end
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then
		return "TextColor3"
	end
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		return "ImageColor3"
	end
end

local function AddThemeObject(Object, Type)
	if not OrionLib.ThemeObjects[Type] then
		OrionLib.ThemeObjects[Type] = {}
	end
	table.insert(OrionLib.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
	return Object
end

local function SetTheme()
	for Name, Type in pairs(OrionLib.ThemeObjects) do
		for _, Object in pairs(Type) do
			Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Name]
		end
	end
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
	local Data = HttpService:JSONDecode(Config)
	table.foreach(Data, function(a, b)
		if OrionLib.Flags[a] then
			spawn(function()
				if OrionLib.Flags[a].Type == "Colorpicker" then
					OrionLib.Flags[a]:Set(UnpackColor(b))
				else
					OrionLib.Flags[a]:Set(b)
				end
			end)
		else
			warn("Orion Library Config Loader - Could not find ", a, b)
		end
	end)
end

local function SaveCfg(Name)
	if not OrionLib.SaveCfg then return end
	pcall(function()
		local Data = {}
		for i, v in pairs(OrionLib.Flags) do
			if v.Save then
				if v.Type == "Colorpicker" then
					Data[i] = PackColor(v.Value)
				else
					Data[i] = v.Value
				end
			end
		end
		writefile(OrionLib.Folder .. "/" .. Name .. ".txt", tostring(HttpService:JSONEncode(Data)))
	end)
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
	for _, v in next, Table do
		if v == Key then
			return true
		end
	end
end

CreateElement("Corner", function(Scale, Offset)
	return Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 10)})
end)

CreateElement("Stroke", function(Color, Thickness)
	return Create("UIStroke", {Color = Color or Color3.fromRGB(255, 255, 255), Thickness = Thickness or 1})
end)

CreateElement("List", function(Scale, Offset)
	return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 0)})
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	return Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft   = UDim.new(0, Left   or 4),
		PaddingRight  = UDim.new(0, Right  or 4),
		PaddingTop    = UDim.new(0, Top    or 4)
	})
end)

CreateElement("TFrame", function()
	return Create("Frame", {BackgroundTransparency = 1})
end)

CreateElement("Frame", function(Color)
	return Create("Frame", {BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0})
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	return Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0
	}, {
		Create("UICorner", {CornerRadius = UDim.new(Scale, Offset)})
	})
end)

CreateElement("Button", function()
	return Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
end)

CreateElement("ScrollFrame", function(Color, Width)
	return Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage    = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage    = "rbxassetid://7445543667",
		ScrollBarImageColor3  = Color,
		BorderSizePixel       = 0,
		ScrollBarThickness    = Width,
		CanvasSize            = UDim2.new(0, 0, 0, 0)
	})
end)

CreateElement("Image", function(ImageID)
	local ImageNew = Create("ImageLabel", {Image = ImageID, BackgroundTransparency = 1})
	if GetIcon(ImageID) ~= nil then
		ImageNew.Image = GetIcon(ImageID)
	end
	return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
	return Create("ImageButton", {Image = ImageID, BackgroundTransparency = 1})
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	return Create("TextLabel", {
		Text              = Text or "",
		TextColor3        = Color3.fromRGB(240, 240, 240),
		TextTransparency  = Transparency or 0,
		TextSize          = TextSize or 15,
		Font              = Enum.Font.Gotham,
		RichText          = true,
		BackgroundTransparency = 1,
		TextXAlignment    = Enum.TextXAlignment.Left
	})
end)

local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		VerticalAlignment   = Enum.VerticalAlignment.Bottom,
		Padding             = UDim.new(0, 5)
	})
}), {
	Position    = UDim2.new(1, -25, 1, -25),
	Size        = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	Parent      = Orion
})

function OrionLib:MakeNotification(NotificationConfig)
	spawn(function()
		NotificationConfig.Name    = NotificationConfig.Name    or "Notification"
		NotificationConfig.Content = NotificationConfig.Content or "Test"
		NotificationConfig.Image   = NotificationConfig.Image   or "rbxassetid://4384403532"
		NotificationConfig.Time    = NotificationConfig.Time    or 15

		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size          = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent        = NotificationHolder
		})

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(12, 4, 24), 0, 10), {
			Parent              = NotificationParent,
			Size                = UDim2.new(1, 0, 0, 0),
			Position            = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize       = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", Color3.fromRGB(110, 40, 180), 1.5),
			MakeElement("Padding", 12, 12, 12, 12),
			SetProps(MakeElement("Image", NotificationConfig.Image), {
				Size        = UDim2.new(0, 18, 0, 18),
				ImageColor3 = Color3.fromRGB(180, 120, 255),
				Name        = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 14), {
				Size      = UDim2.new(1, -30, 0, 20),
				Position  = UDim2.new(0, 26, 0, 0),
				Font      = Enum.Font.GothamBold,
				TextColor3 = Color3.fromRGB(220, 180, 255),
				Name      = "Title"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 13), {
				Size          = UDim2.new(1, 0, 0, 0),
				Position      = UDim2.new(0, 0, 0, 24),
				Font          = Enum.Font.GothamSemibold,
				Name          = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3    = Color3.fromRGB(170, 130, 210),
				TextWrapped   = true
			})
		})

		local function nfAlive() return NotificationFrame and NotificationFrame.Parent end
		if nfAlive() then pcall(function() TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play() end) end
		wait(NotificationConfig.Time - 0.88)
		if nfAlive() then
			pcall(function()
				local icon = NotificationFrame:FindFirstChild("Icon")
				if icon then TweenService:Create(icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play() end
				TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
			end)
		end
		wait(0.3)
		if nfAlive() then
			pcall(function()
				local stroke = NotificationFrame:FindFirstChildOfClass("UIStroke")
				local title  = NotificationFrame:FindFirstChild("Title")
				local body   = NotificationFrame:FindFirstChild("Content")
				if stroke then TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play() end
				if title  then TweenService:Create(title,  TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play() end
				if body   then TweenService:Create(body,   TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play() end
			end)
		end
		wait(0.05)
		if nfAlive() then
			pcall(function()
				local curY = NotificationFrame.Position.Y.Offset
				TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 0, curY)}):Play()
			end)
		end
		wait(1.35)
		if nfAlive() then pcall(function() NotificationFrame:Destroy() end) end
	end)
end

function OrionLib:Init()
	if OrionLib.SaveCfg then
		pcall(function()
			if isfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt") then
				LoadCfg(readfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt"))
				OrionLib:MakeNotification({
					Name    = "Configuration",
					Content = "Auto-loaded configuration for the game " .. game.GameId .. ".",
					Time    = 5
				})
			end
		end)
	end
end

function OrionLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local Loaded = false
	local UIHidden = false
	local ToggleKey = Enum.KeyCode.RightShift  -- changeable from settings panel

	WindowConfig = WindowConfig or {}
	WindowConfig.Name         = WindowConfig.Name         or "Duvome"
	WindowConfig.IconFont     = WindowConfig.IconFont or nil  -- set to BuilderIcons path in example
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig   = WindowConfig.SaveConfig   or false
	WindowConfig.HidePremium  = WindowConfig.HidePremium  or false
	if WindowConfig.IntroEnabled == nil then
		WindowConfig.IntroEnabled = true
	end
	WindowConfig.IntroText     = WindowConfig.IntroText     or "Orion Library"
	WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
	WindowConfig.ShowIcon      = WindowConfig.ShowIcon      or false
	WindowConfig.Icon          = WindowConfig.Icon          or "rbxassetid://8834748103"
	WindowConfig.IntroIcon     = WindowConfig.IntroIcon     or "rbxassetid://8834748103"
	OrionLib.Folder  = WindowConfig.ConfigFolder
	local _iconFont = WindowConfig.IconFont
	OrionLib.SaveCfg = WindowConfig.SaveConfig

	if WindowConfig.SaveConfig then
		pcall(function()
			if not isfolder(WindowConfig.ConfigFolder) then
				makefolder(WindowConfig.ConfigFolder)
			end
		end)
	end

	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 4), {
		Size     = UDim2.new(1, 0, 1, -120),
		Position = UDim2.new(0, 0, 0, 32)
	}), {
		MakeElement("List"),
		MakeElement("Padding", 8, 0, 0, 8)
	}), "Divider")

	-- Search bar above tab list
	-- Search: magnifying glass icon, click to expand input
	local TabSearchBG = Create("Frame", {
		BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
		BackgroundTransparency = 0,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, -8, 0, 24),
		Position         = UDim2.new(0, 4, 0, 4),
		ZIndex           = 5,
		ClipsDescendants = true,
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = TabSearchBG})
	Create("UIStroke", {Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke, Thickness = 1, Parent = TabSearchBG})

	-- magnifying glass button (always visible, centered in bar)
	local SearchIcon = Create("TextButton", {
		Text = "magnifying-glass",
		FontFace = MakeBIconFont(),
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = Color3.fromRGB(140, 80, 200),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 26, 1, 0),
		Position = UDim2.new(0, 5, 0.5, 0),
		ZIndex = 7, Parent = TabSearchBG
	})

	local TabSearchBox = Create("TextBox", {
		Text             = "",
		PlaceholderText  = "Search tabs...",
		PlaceholderColor3 = Color3.fromRGB(90, 55, 130),
		Font             = Enum.Font.GothamSemibold,
		TextSize         = 11,
		TextColor3       = Color3.fromRGB(210, 175, 255),
		BackgroundTransparency = 1,
		Size             = UDim2.new(1, -33, 1, 0),
		Position         = UDim2.new(0, 32, 0, 0),
		TextXAlignment   = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex           = 6,
		Visible          = false,
		Parent           = TabSearchBG
	})

	local _searchOpen = false
	local function openSearch()
		if _searchOpen then return end
		_searchOpen = true

		TabSearchBox.PlaceholderText = ""
		TabSearchBox.Visible = true
		TabSearchBox.Text = ""
		SearchIcon.TextColor3 = Color3.fromRGB(190, 120, 255)
		-- typewriter placeholder
		task.spawn(function()
			local ph = "Search features..."
			for i = 1, #ph do
				if not _searchOpen then break end
				TabSearchBox.PlaceholderText = ph:sub(1, i)
				task.wait(0.04)
			end
		end)
		TabSearchBox:CaptureFocus()
	end
	local function closeSearch()
		if not _searchOpen then return end
		_searchOpen = false
		TabSearchBox.Text = ""
		TabSearchBox.PlaceholderText = ""
		TabSearchBox.Visible = false
		SearchIcon.TextColor3 = Color3.fromRGB(140, 80, 200)
		-- restore all hidden items
		for _, entry in ipairs(OrionLib._tabRegistry or {}) do
			if entry.Container then
				for _, desc in ipairs(entry.Container:GetDescendants()) do
					if desc:IsA("Frame") then desc.Visible = true end
				end
			end
		end
	end

	-- SearchIcon click wired after setSidebar defined (below)

	TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = TabSearchBox.Text:lower():match("^%s*(.-)%s*$")
		local registry = OrionLib._tabRegistry or {}

		local function restoreAll()
			for _, entry in ipairs(registry) do
				if entry.Container then
					for _, d in ipairs(entry.Container:GetDescendants()) do
						if d:IsA("Frame") then d.Visible = true end
					end
				end
			end
		end

		if q == "" then restoreAll() return end

		for _, entry in ipairs(registry) do
			if entry.Container then
				local hadParent = entry.Container.Parent ~= nil
				if not hadParent then entry.Container.Parent = Orion end

				-- chain: colFrame > SectionFrame > HolderFrame(Name="Holder") > ItemFrame > Content
				local items = {}
				local hasMatch = false

				for _, desc in ipairs(entry.Container:GetDescendants()) do
					if desc:IsA("TextLabel") and desc.Name == "Content" and #desc.Text > 1 then
						local itemFrame    = desc.Parent
						local holderFrame  = itemFrame and itemFrame.Parent
						local sectionFrame = holderFrame and holderFrame.Parent
						-- handle both: inside section (holderFrame.Name=="Holder") and direct in tab
						if itemFrame and holderFrame and sectionFrame then
							local matches = desc.Text:lower():find(q, 1, true) ~= nil
							local sf = holderFrame.Name == "Holder" and sectionFrame or holderFrame
							table.insert(items, {item=itemFrame, section=sf, matches=matches})
							if matches then hasMatch = true end
						end
					end
				end

				if not hadParent then entry.Container.Parent = nil end

				if hasMatch then
					restoreAll()
					if entry.ClickFn then entry.ClickFn() end
					local sectionHasMatch = {}
					for _, v in ipairs(items) do
						v.item.Visible = v.matches
						if v.matches then sectionHasMatch[v.section] = true end
					end
					for _, v in ipairs(items) do
						if not sectionHasMatch[v.section] then
							v.section.Visible = false
						end
					end
					break
				end
			end
		end
	end)


	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		task.defer(function()
			if TabHolder.Parent then
				TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
			end
		end)
	end)

	-- Purple pill badge - sits right beside the window title text
	local PillBadge = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(90, 30, 150),
		Size             = UDim2.new(0, 160, 0, 30),
		Position         = UDim2.new(0, 120, 0.5, -15),
		BorderSizePixel  = 0,
		ZIndex           = 3
	})
	Create("UICorner",  {CornerRadius = UDim.new(1, 0), Parent = PillBadge})
	Create("UIStroke",  {Color = Color3.fromRGB(160, 60, 255), Thickness = 1.5, Parent = PillBadge})
	Create("TextLabel", {
		Text             = os.date("%m/%d/%Y %I:%M %p"),
		Font             = Enum.Font.GothamBold,
		TextSize         = 16,
		TextColor3       = Color3.fromRGB(220, 180, 255),
		BackgroundTransparency = 1,
		Size             = UDim2.new(1, 0, 1, 0),
		TextXAlignment   = Enum.TextXAlignment.Center,
		ZIndex           = 4,
		Parent           = PillBadge
	})



	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size                = UDim2.new(0, 35, 1, 0),
		Position            = UDim2.new(0, 70, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size     = UDim2.new(0, 18, 0, 18)
		}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size                = UDim2.new(0, 35, 1, 0),
		Position            = UDim2.new(0, 35, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size     = UDim2.new(0, 18, 0, 18),
			Name     = "Ico"
		}), "Text")
	})

	-- DragPoint lives inside TopBar so it never blocks content
	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, -80, 1, 0)  -- leaves room for the close/minimize buttons
	})

	local ExecutorLbl = Create("TextLabel", {
		Name             = "ExecutorLbl",
		Text             = GetExecutor(),
		Font             = Enum.Font.Gotham,
		TextSize         = 12,
		TextColor3       = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
		BackgroundTransparency = 1,
		Size             = UDim2.new(0, 0, 0, 13),
		Position         = UDim2.new(0, 40, 0, 27),
		TextXAlignment   = Enum.TextXAlignment.Left,
		ClipsDescendants = true
	})

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Size                  = UDim2.new(0, 44, 1, -50),
		Position              = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 0
	}), {
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size     = UDim2.new(1, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 0)
		}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size     = UDim2.new(0, 10, 1, 0),
			Position = UDim2.new(1, -10, 0, 0)
		}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size     = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, -1, 0, 0)
		}), "Stroke"),
		TabSearchBG,
		TabHolder,
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size     = UDim2.new(1, 0, 0, 50),
			Position = UDim2.new(0, 0, 1, -50)
		}), {
			AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(1, 0, 0, 1)
			}), "Stroke"),
			AddThemeObject(SetChildren(SetProps(Create("TextButton", {
				Text = "", BackgroundTransparency = 0, AutoButtonColor = false,
				AnchorPoint = Vector2.new(0, 0.5),
				Size        = UDim2.new(0, 32, 0, 32),
				Position    = UDim2.new(0, 4, 0.5, 0),
				BorderSizePixel = 0,
				Name = "AvatarBtn"
			}), {}), {
				SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"), {
					Size = UDim2.new(1, 0, 1, 0)
				}),
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
					Size = UDim2.new(1, 0, 1, 0)
				}), "Second"),
				MakeElement("Corner", 1)
			}), "Divider"),
			SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size        = UDim2.new(0, 32, 0, 32),
				Position    = UDim2.new(0, 4, 0.5, 0),
				Name        = "GlowRing"
			}), {
				Create("UIStroke", {
					Color     = Color3.fromRGB(0, 220, 255),
					Thickness = 1.8,
					Name      = "GlowStroke"
				}),
				MakeElement("Corner", 1)
			}),
			AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, 15), {
				Size             = UDim2.new(0, 0, 0, 16),
				Position         = UDim2.new(0, 40, 0, 10),
				Font             = Enum.Font.GothamBold,
				ClipsDescendants = true,
				Name             = "DisplayNameLbl"
			}), "Text"),
			ExecutorLbl
		})
	}), "Second")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
		Size     = UDim2.new(0, 250, 0, 26),
		Position = UDim2.new(0, 15, 0, 8),
		Font     = Enum.Font.GothamBlack,
		TextSize = 18
	}), "Text")

	local TopbarStats = Create("TextLabel", {
		Name             = "TopbarStats",
		Text             = "FPS: -- | Ping: --",
		Font             = Enum.Font.Gotham,
		TextSize         = 10,
		TextColor3       = Color3.fromRGB(140, 90, 190),
		BackgroundTransparency = 1,
		Size             = UDim2.new(0, 200, 0, 12),
		Position         = UDim2.new(0, 15, 0, 33),
		TextXAlignment   = Enum.TextXAlignment.Left
	})

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size     = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1)
	}), "Stroke")

	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, -80, 1, 0)
	})

	local SettingsBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size                   = UDim2.new(0, 35, 1, 0),
		Position               = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(Create("TextLabel", {
			Text        = "gear",
			FontFace = MakeBIconFont(),
			TextSize    = 16,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			BackgroundTransparency = 1,
			Size        = UDim2.new(0, 22, 0, 22),
			Position    = UDim2.new(0.5, -11, 0.5, -11),
			Name        = "Ico"
		}), {}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size                = UDim2.new(0, 35, 1, 0),
		Position            = UDim2.new(0, 35, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size     = UDim2.new(0, 18, 0, 18),
			Name     = "Ico"
		}), "Text")
	})

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Parent                = Orion,
		Position              = UDim2.new(0.5, -307, 0.5, -172),
		Size                  = UDim2.new(0, 615, 0, 344),
		ClipsDescendants      = true,
		BackgroundTransparency = 0
	}), {
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar"
		}), {
			WindowName,
			TopbarStats,
			WindowTopBarLine,
			DragPoint,
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
				Size     = UDim2.new(0, 105, 0, 30),
				Position = UDim2.new(1, -120, 0, 10)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				AddThemeObject(SetProps(MakeElement("Frame"), {
					Size     = UDim2.new(0, 1, 1, 0),
					Position = UDim2.new(0, 35, 0, 0)
				}), "Stroke"),
				AddThemeObject(SetProps(MakeElement("Frame"), {
					Size     = UDim2.new(0, 1, 1, 0),
					Position = UDim2.new(0, 70, 0, 0)
				}), "Stroke"),
				SettingsBtn,
				CloseBtn,
				MinimizeBtn
			}), "Second")
		}),
		WindowStuff
	}), "Main")

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color     = Color3.fromRGB(0, 0, 0)
	MainStroke.Thickness = 5
	MainStroke.Parent    = MainWindow

	AddDraggingFunctionality(DragPoint, MainWindow)

	-- Pencil config button inside sidebar
	local PencilCfgBtn = Instance.new("TextButton")
	PencilCfgBtn.Text = ""
	PencilCfgBtn.AutoButtonColor = false
	PencilCfgBtn.BackgroundColor3 = Color3.fromRGB(30, 10, 60)
	PencilCfgBtn.BackgroundTransparency = 0.3
	PencilCfgBtn.BorderSizePixel = 0
	PencilCfgBtn.AnchorPoint = Vector2.new(0, 0)
	PencilCfgBtn.Size = UDim2.new(0, 30, 0, 30)
	PencilCfgBtn.Position = UDim2.new(0, 7, 1, -88)
	PencilCfgBtn.ZIndex = 8
	PencilCfgBtn.Parent = WindowStuff
	local _pc = Instance.new("UICorner", PencilCfgBtn); _pc.CornerRadius = UDim.new(0, 6)
	local _ps = Instance.new("UIStroke", PencilCfgBtn); _ps.Color = Color3.fromRGB(90, 30, 150); _ps.Thickness = 1
	local PencilIco = Instance.new("TextLabel", PencilCfgBtn)
	PencilIco.Text = "pencil-square"
	SetFontFace(PencilIco, BICONS_PATH)
	PencilIco.TextSize = 15
	PencilIco.TextWrapped = true
	PencilIco.TextColor3 = Color3.fromRGB(160, 100, 220)
	PencilIco.BackgroundTransparency = 1
	PencilIco.Size = UDim2.new(1, 0, 1, 0)
	PencilIco.TextXAlignment = Enum.TextXAlignment.Center
	PencilIco.TextYAlignment = Enum.TextYAlignment.Center
	PencilIco.ZIndex = 9

	-- Config panel - same size/animation as avatar panel
	local CfgPanel = Create("Frame", {
		Name                   = "CfgPanel",
		BackgroundColor3       = Color3.fromRGB(12, 4, 24),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, 175, 0, 344),
		Position               = UDim2.new(0, 0, 0, 0),
		Visible                = false,
		ZIndex                 = 100,
		Parent                 = Orion,
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = CfgPanel})
	Create("UIStroke", {Color = Color3.fromRGB(90, 30, 140), Thickness = 1.5, Parent = CfgPanel})

	-- Title
	Create("TextLabel", {
		Text = "Configs", Font = Enum.Font.GothamBlack, TextSize = 16,
		TextColor3 = Color3.fromRGB(220, 180, 255), BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 24), Position = UDim2.new(0, 8, 0, 10),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101, Parent = CfgPanel,
	})
	Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(80, 25, 130), BorderSizePixel = 0,
		Size = UDim2.new(0.9, 0, 0, 1), Position = UDim2.new(0.05, 0, 0, 38),
		ZIndex = 102, Parent = CfgPanel,
	})

	-- Config name input
	local refreshCfgList -- forward declared, defined below
	local CfgNameBG = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 6, 36), BackgroundTransparency = 0,
		BorderSizePixel = 0, Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.new(0, 8, 0, 48), ZIndex = 101, Parent = CfgPanel,
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = CfgNameBG})
	Create("UIStroke", {Color = Color3.fromRGB(80, 25, 130), Thickness = 1, Parent = CfgNameBG})
	local CfgNameBox = Create("TextBox", {
		Text = "", PlaceholderText = "Config name...",
		PlaceholderColor3 = Color3.fromRGB(90, 55, 130),
		Font = Enum.Font.GothamSemibold, TextSize = 11,
		TextColor3 = Color3.fromRGB(210, 175, 255),
		BackgroundTransparency = 1, ClearTextOnFocus = false,
		Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 6, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 102, Parent = CfgNameBG,
	})

	-- Save button
	local CfgSaveBtn = Create("TextButton", {
		Text = "Save Config", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(220, 180, 255),
		BackgroundColor3 = Color3.fromRGB(70, 20, 120),
		BackgroundTransparency = 0, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, 84),
		ZIndex = 101, Parent = CfgPanel,
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = CfgSaveBtn})
	CfgSaveBtn.MouseEnter:Connect(function() TweenService:Create(CfgSaveBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(100,35,160)}):Play() end)
	CfgSaveBtn.MouseLeave:Connect(function() TweenService:Create(CfgSaveBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(70,20,120)}):Play() end)
	CfgSaveBtn.MouseButton1Click:Connect(function()
		local name = CfgNameBox.Text:match("^%s*(.-)%s*$")
		if name == "" then name = "config_"..os.time() end
		name = name:gsub("[^%w_%-]", "_")
		local data = {}
		for flag, elem in pairs(OrionLib.Flags) do
			if elem.Value ~= nil then data[flag] = elem.Value end
		end
		pcall(function()
			if not isfolder("DuvomeConfigs") then makefolder("DuvomeConfigs") end
			writefile("DuvomeConfigs/"..name..".json", game:GetService("HttpService"):JSONEncode(data))
		end)
		OrionLib:MakeNotification({Name="Config Saved", Content="'"..name.."'", Time=3})
		CfgNameBox.Text = ""
		refreshCfgList()
	end)

	-- Divider
	Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(80, 25, 130), BorderSizePixel = 0,
		Size = UDim2.new(0.9, 0, 0, 1), Position = UDim2.new(0.05, 0, 0, 120),
		ZIndex = 102, Parent = CfgPanel,
	})
	Create("TextLabel", {
		Text = "Saved Configs", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(140, 90, 200), BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 128),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101, Parent = CfgPanel,
	})

	-- Config list scroll
	local CfgScroll = Create("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, -8, 0, 175), Position = UDim2.new(0, 4, 0, 148),
		ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(100,40,160),
		CanvasSize = UDim2.new(0,0,0,0), ZIndex = 101, Parent = CfgPanel,
	})
	Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4), Parent=CfgScroll})
	Create("UIPadding", {PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), PaddingTop=UDim.new(0,2), Parent=CfgScroll})

	refreshCfgList = function()
		for _, c in ipairs(CfgScroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		local files = {}
		pcall(function()
			if isfolder("DuvomeConfigs") then
				for _, f in ipairs(listfiles("DuvomeConfigs")) do
					local n = f:match("([^/\\]+)%.json$")
					if n then table.insert(files, n) end
				end
			end
		end)
		for i, name in ipairs(files) do
			local row = Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(18,6,36), BackgroundTransparency=0.3,
				BorderSizePixel=0, Size=UDim2.new(1,0,0,26), LayoutOrder=i, ZIndex=102, Parent=CfgScroll,
			})
			Create("UICorner", {CornerRadius=UDim.new(0,4), Parent=row})
			Create("TextLabel", {
				Text=name, Font=Enum.Font.GothamSemibold, TextSize=11,
				TextColor3=Color3.fromRGB(200,160,255), BackgroundTransparency=1,
				Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,6,0,0),
				TextXAlignment=Enum.TextXAlignment.Left, ZIndex=103, Parent=row,
			})
			-- load button
			local loadBtn = Create("TextButton", {
				Text="arrow-small-down",
				FontFace = MakeBIconFont(),
				TextSize=14, TextWrapped=true,
				TextColor3=Color3.fromRGB(140,90,200), BackgroundTransparency=1,
				Size=UDim2.new(0,22,1,0), Position=UDim2.new(1,-44,0,0),
				ZIndex=103, Parent=row,
			})
			-- delete button (red x)
			local delBtn = Create("TextButton", {
				Text="x", Font=Enum.Font.GothamBold, TextSize=12,
				TextColor3=Color3.fromRGB(220,80,80), BackgroundTransparency=1,
				Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-22,0,0),
				ZIndex=103, Parent=row,
			})
			delBtn.MouseEnter:Connect(function() delBtn.TextColor3=Color3.fromRGB(255,100,100) end)
			delBtn.MouseLeave:Connect(function() delBtn.TextColor3=Color3.fromRGB(220,80,80) end)
			local _dn = name
			delBtn.MouseButton1Click:Connect(function()
				pcall(function() delfile("DuvomeConfigs/".._dn..".json") end)
				refreshCfgList()
			end)
			local _n = name
			loadBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local raw = readfile("DuvomeConfigs/".._n..".json")
					local data = game:GetService("HttpService"):JSONDecode(raw)
					for flag, val in pairs(data) do
						if OrionLib.Flags[flag] then pcall(function() OrionLib.Flags[flag]:Set(val) end) end
					end
				end)
				OrionLib:MakeNotification({Name="Config Loaded", Content="'"..name.."'", Time=3})
			end)
		end
		local ll = CfgScroll:FindFirstChildOfClass("UIListLayout")
		if ll then CfgScroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8) end
	end

	local CfgPanelOpen = false
	local function openCfgPanel()
		CfgPanelOpen = true
		refreshCfgList()
		local wp  = MainWindow.AbsolutePosition
		local ws  = MainWindow.AbsoluteSize
		local pw  = CfgPanel.AbsoluteSize.X
		local ph  = CfgPanel.AbsoluteSize.Y
		local centY = wp.Y + (ws.Y - ph) / 2
		local landX = wp.X - pw - 20
		local startX = landX - pw - 40
		CfgPanel.Position = UDim2.new(0, startX, 0, centY)
		CfgPanel.BackgroundTransparency = 1
		CfgPanel.Visible = true
		TweenService:Create(CfgPanel, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position=UDim2.new(0,landX,0,centY), BackgroundTransparency=0.05}):Play()
	end
	local function closeCfgPanel()
		CfgPanelOpen = false
		local curX = CfgPanel.Position.X.Offset
		local curY = CfgPanel.Position.Y.Offset
		local pw = CfgPanel.AbsoluteSize.X
		local t = TweenService:Create(CfgPanel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{Position=UDim2.new(0,curX-pw-40,0,curY), BackgroundTransparency=1})
		t:Play()
		t.Completed:Connect(function() CfgPanel.Visible = false end)
	end

	PencilCfgBtn.MouseEnter:Connect(function()
		TweenService:Create(PencilCfgBtn, TweenInfo.new(0.15), {BackgroundTransparency=0.1}):Play()
		TweenService:Create(PencilIco, TweenInfo.new(0.15), {TextColor3=Color3.fromRGB(200,140,255)}):Play()
	end)
	PencilCfgBtn.MouseLeave:Connect(function()
		TweenService:Create(PencilCfgBtn, TweenInfo.new(0.15), {BackgroundTransparency=0.3}):Play()
		TweenService:Create(PencilIco, TweenInfo.new(0.15), {TextColor3=Color3.fromRGB(160,100,220)}):Play()
	end)
	PencilCfgBtn.MouseButton1Click:Connect(function()
		if CfgPanelOpen then closeCfgPanel() else openCfgPanel() end
	end)

	-- Drag CfgPanel
	local _cfgDragging = false
	local _cfgDragStart, _cfgStartPos
	local CfgDragBtn = Create("TextButton", {
		Text="", BackgroundTransparency=1, BorderSizePixel=0,
		Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,0),
		ZIndex=110, Parent=CfgPanel,
	})
	CfgDragBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			_cfgDragging = true
			_cfgDragStart = inp.Position
			_cfgStartPos = CfgPanel.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if _cfgDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = inp.Position - _cfgDragStart
			CfgPanel.Position = UDim2.new(0, _cfgStartPos.X.Offset+delta.X, 0, _cfgStartPos.Y.Offset+delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			_cfgDragging = false
		end
	end)

	-- Follow MainWindow when UI is dragged
	local function updateCfgPanelPos()
		if CfgPanelOpen then
			local wp = MainWindow.AbsolutePosition
			local ws = MainWindow.AbsoluteSize
			local pw = CfgPanel.AbsoluteSize.X
			local ph = CfgPanel.AbsoluteSize.Y
			local centY = wp.Y + (ws.Y - ph) / 2
			local landX = wp.X - pw - 20
			TweenService:Create(CfgPanel, TweenInfo.new(0.1), {Position=UDim2.new(0,landX,0,centY)}):Play()
		end
	end
	MainWindow:GetPropertyChangedSignal("Position"):Connect(updateCfgPanelPos)
	MainWindow:GetPropertyChangedSignal("Size"):Connect(updateCfgPanelPos)
	MainWindow:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCfgPanelPos)

	-- Pencil config button - sits in sidebar above avatar
	local _keybindListening = false
	local _keybindCancel    = nil
	local _keybindRegistry  = {}
	local _keybindBlocking  = false  -- blocks triggers while setting a keybind

	local function abbrKey(kc)
		if not kc then return "---" end
		local names = {
			Return="Ent", BackSpace="Bsp", Space="Spc",
			Delete="Del", Escape="Esc", CapsLock="Cap",
			LeftControl="LCtrl", RightControl="RCtrl",
			LeftShift="LSft", RightShift="RSft",
			LeftAlt="LAlt", RightAlt="RAlt",
		}
		local n = kc.Name
		return names[n] or (n:len() > 4 and n:sub(1,4) or n)
	end

	local function makeKeybindBox(parent, posX, defaultKey, _, flagId, callback)
		local boundKey = defaultKey  -- nil means no keybind set
		local function kbWidth(kc)
			if not kc then return 28 end
			return math.max(28, #abbrKey(kc) * 7 + 8)
		end
		local kbBox = Create("TextButton", {
			Text             = abbrKey(boundKey),
			Font             = Enum.Font.GothamBold,
			TextSize         = 10,
			TextColor3       = Color3.fromRGB(180, 120, 255),
			BackgroundColor3 = Color3.fromRGB(25, 8, 48),
			BackgroundTransparency = 0,
			BorderSizePixel  = 0,
			Size             = UDim2.new(0, kbWidth(boundKey), 0, 24),
			Position         = UDim2.new(1, posX, 0.5, -12),
			ZIndex           = 6,
			Name             = "KeybindBox",
			Parent           = parent
		})
		Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = kbBox})
		Create("UIStroke", {Color = Color3.fromRGB(80, 30, 130), Thickness = 1, Parent = kbBox})

		kbBox.MouseButton1Click:Connect(function()
			if _keybindListening then
				if _keybindCancel then _keybindCancel() end
			end
			_keybindListening = true
			_keybindBlocking  = true
			kbBox.Text = "..."
			kbBox.TextColor3 = Color3.fromRGB(255, 200, 80)
			local conn
			local function cancel(newKey)
				_keybindListening = false
				_keybindCancel    = nil
				task.delay(0.05, function() _keybindBlocking = false end)
				if newKey then
					local dupe = false
					for id, k in pairs(_keybindRegistry) do
						if id ~= flagId and k == newKey then dupe = true break end
					end
					if dupe then
						kbBox.Text = abbrKey(boundKey)
						kbBox.TextColor3 = Color3.fromRGB(180, 120, 255)
						OrionLib:MakeNotification({
							Name    = "Keybind Taken",
							Content = abbrKey(newKey) .. " is already bound to another action.",
							Time    = 3
						})
					else
						boundKey = newKey
						_keybindRegistry[flagId] = boundKey
						kbBox.Text = abbrKey(boundKey)
						kbBox.Size = UDim2.new(0, kbWidth(boundKey), 0, 24)
						kbBox.TextColor3 = Color3.fromRGB(180, 120, 255)
					end
				else
					kbBox.Text = abbrKey(boundKey)
					kbBox.TextColor3 = Color3.fromRGB(180, 120, 255)
				end
				pcall(function() conn:Disconnect() end)
			end
			_keybindCancel = function() cancel(nil) end
			conn = UserInputService.InputBegan:Connect(function(inp, gp)
				if gp then return end
				if inp.UserInputType == Enum.UserInputType.Keyboard then
					-- ignore keys that shouldn't be bindable
					local _blocked = {
						[Enum.KeyCode.Escape] = true,
						[Enum.KeyCode.Tab]    = true,
						[Enum.KeyCode.Space]  = true,
					}
					if inp.KeyCode == Enum.KeyCode.Backspace then
						-- Backspace clears the keybind
						_keybindListening = false
						_keybindCancel    = nil
						_keybindRegistry[flagId] = nil
						boundKey = nil
						kbBox.Text = "---"
						kbBox.Size = UDim2.new(0, 28, 0, 24)
						kbBox.TextColor3 = Color3.fromRGB(180, 120, 255)
						pcall(function() conn:Disconnect() end)
						task.delay(0.05, function() _keybindBlocking = false end)
						OrionLib:MakeNotification({Name = "Keybind Removed", Content = "Keybind cleared.", Time = 2})
					elseif _blocked[inp.KeyCode] then
						cancel(nil)
					else
						cancel(inp.KeyCode)
					end
				end
			end)
		end)

		-- right-click to clear keybind (use UserInputService to bypass click overlay)
		UserInputService.InputBegan:Connect(function(inp, gp)
			if gp then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
			if not kbBox or not kbBox.Parent then return end
			local mp = inp.Position
			local ap = kbBox.AbsolutePosition
			local as = kbBox.AbsoluteSize
			if mp.X >= ap.X and mp.X <= ap.X+as.X and mp.Y >= ap.Y and mp.Y <= ap.Y+as.Y then
				if _keybindListening then return end
				if boundKey then
					_keybindRegistry[flagId] = nil
					boundKey = nil
					kbBox.Text = "---"
					kbBox.Size = UDim2.new(0, 28, 0, 24)
					kbBox.TextColor3 = Color3.fromRGB(180, 120, 255)
					OrionLib:MakeNotification({Name = "Keybind Removed", Content = "Keybind cleared.", Time = 2})
				else
					OrionLib:MakeNotification({Name = "No Keybind", Content = "Left-click to set one.", Time = 2})
				end
			end
		end)

		UserInputService.InputBegan:Connect(function(inp, gp)
			if gp or _keybindListening or _keybindBlocking then return end
			if not boundKey then return end
			if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if inp.KeyCode == Enum.KeyCode.Space then return end
			if inp.KeyCode == boundKey then
				callback()
			end
		end)

		if flagId and boundKey then _keybindRegistry[flagId] = boundKey end
		return kbBox
	end

	-- Collapsible sidebar (after MainWindow is defined)
	local SB_WIDE = 150
	local SB_THIN = 44
	local sbOpen  = false  -- starts collapsed, expands on hover

	local function setSidebar(open)
		sbOpen = open
		local tw = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local _w = open and SB_WIDE or SB_THIN
		local _t = open and 0 or 1

		TweenService:Create(WindowStuff, tw, {Size = UDim2.new(0, _w, 1, -50)}):Play()

		for _, c in ipairs(MainWindow:GetChildren()) do
			if c.Name == "ItemContainer" then
				TweenService:Create(c, tw, {
					Position = UDim2.new(0, _w, 0, 50),
					Size     = UDim2.new(1, -_w, 1, -50)
				}):Play()
			end
		end

		for _, tab in ipairs(TabHolder:GetChildren()) do
			if tab:IsA("TextButton") then
				local title = tab:FindFirstChild("Title")
				local ico   = tab:FindFirstChild("Ico")
				if title then
					title.ClipsDescendants = true
					if open then
						TweenService:Create(title, tw, {Size = UDim2.new(1, -36, 1, 0), TextTransparency = 0.4}):Play()
					else
						TweenService:Create(title, tw, {Size = UDim2.new(0, 0, 1, 0), TextTransparency = 0.4}):Play()
					end
				end
				-- icons stay at fixed position, never move
			end
		end

		local _nameW = open and UDim2.new(0, 100, 0, 14) or UDim2.new(0, 0, 0, 14)
		local _execW = open and UDim2.new(0, 100, 0, 13) or UDim2.new(0, 0, 0, 13)
		local dnl = WindowStuff:FindFirstChild("DisplayNameLbl", true)
		local exl = WindowStuff:FindFirstChild("ExecutorLbl", true)
		if dnl then dnl.ClipsDescendants = true TweenService:Create(dnl, tw, {Size = _nameW}):Play() end
		if exl then exl.ClipsDescendants = true TweenService:Create(exl, tw, {Size = _execW}):Play() end


	end

	local sbPinned = false

	WindowStuff.MouseEnter:Connect(function() if not sbPinned then setSidebar(true)  end end)
	WindowStuff.MouseLeave:Connect(function() if not sbPinned and not _searchOpen then setSidebar(false) end end)

	-- now that setSidebar exists, wire search to expand sidebar on open
	SearchIcon.MouseButton1Click:Connect(function()
		if _searchOpen then
			closeSearch()
		else
			setSidebar(true)
			openSearch()
		end
	end)

	-- close search when clicking anywhere outside search bar
	AddConnection(UserInputService.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not _searchOpen then return end
		local mp = UserInputService:GetMouseLocation()
		local ap = TabSearchBG.AbsolutePosition
		local as = TabSearchBG.AbsoluteSize
		local overBar = mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
		if not overBar then
			closeSearch()
			if not sbPinned then setSidebar(false) end
		end
	end)

	local _bgBtn = Create("TextButton", {
		Text = "", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 4, Parent = TabSearchBG
	})
	_bgBtn.MouseButton1Click:Connect(function()
		if not _searchOpen then setSidebar(true) openSearch() end
	end)

	-- Simple pill line below the window, parented to ScreenGui (not inside UI)
	local BottomPill = Create("Frame", {
		BackgroundColor3       = Color3.fromRGB(180, 80, 255),
		BackgroundTransparency = 0.3,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, 180, 0, 4),
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0, 0, 0, 0),
		ZIndex                 = 20,
		Parent                 = Orion
	})
	Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = BottomPill})

	-- keep it centered below the window as it moves
	RunService.RenderStepped:Connect(function()
		if MainWindow and MainWindow.Parent then
			local wp = MainWindow.AbsolutePosition
			local ws = MainWindow.AbsoluteSize
			BottomPill.Position = UDim2.new(0, wp.X + ws.X / 2, 0, wp.Y + ws.Y + 8)
		end
	end)

	-- hover brighten + expand
	BottomPill.MouseEnter:Connect(function()
		TweenService:Create(BottomPill, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(210, 100, 255)}):Play()
	end)
	BottomPill.MouseLeave:Connect(function()
		TweenService:Create(BottomPill, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.3, BackgroundColor3 = Color3.fromRGB(180, 80, 255)}):Play()
	end)

	-- drag the window from the pill
	AddDraggingFunctionality(BottomPill, MainWindow)

	-- get/create the persistent UIScale for animations
	local function getUIScale()
		local s = MainWindow:FindFirstChildOfClass("UIScale")
		if not s then s = Instance.new("UIScale"); s.Parent = MainWindow end
		return s
	end

	-- -- Snow background animation ----------------------------------------
	do
		local SnowCanvas = Create("Frame", {
			Name                   = "SnowCanvas",
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 1, 0),
			Position               = UDim2.new(0, 0, 0, 0),
			ZIndex                 = 0,
			ClipsDescendants       = true,
			Parent                 = MainWindow
		})

		local MAX_FLAKES = 45

		-- each flake is a small rounded square, slightly varied in size
		local function makeFlake()
			local sz = 3 + math.random(0, 3)   -- 3-6 px, feels like snow not rain
			local f = Create("Frame", {
				BackgroundColor3       = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.2 + math.random() * 0.5,
				BorderSizePixel        = 0,
				Size                   = UDim2.new(0, sz, 0, sz),
				Position               = UDim2.new(math.random(), 0, math.random(), 0),
				ZIndex                 = 1,
				Parent                 = SnowCanvas
			})
			Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = f})
			return f, sz
		end

		local function animateFlake(f, sz)
			-- random starting position along top
			local startX  = math.random() * 0.98
			-- slow drift: 4-9 seconds to cross the full height
			local fallTime = 4 + math.random() * 5
			-- gentle horizontal sway offset (-20 to +20 px)
			local sway     = (math.random() - 0.5) * 40

			f.BackgroundTransparency = 0.2 + math.random() * 0.5
			f.Size     = UDim2.new(0, sz, 0, sz)
			f.Position = UDim2.new(startX, 0, -0.04, 0)

			-- fall tween
			TweenService:Create(f,
				TweenInfo.new(fallTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{Position = UDim2.new(startX, sway, 1.04, 0)}
			):Play()

			-- fade out near bottom
			local fadeDelay = fallTime * 0.75
			task.delay(fadeDelay, function()
				if f and f.Parent then
					TweenService:Create(f,
						TweenInfo.new(fallTime * 0.25, Enum.EasingStyle.Quint),
						{BackgroundTransparency = 1}
					):Play()
				end
			end)

			-- reset when done
			task.delay(fallTime + 0.1, function()
				if f and f.Parent then
					f.BackgroundTransparency = 0.2 + math.random() * 0.5
					animateFlake(f, 3 + math.random(0, 3))
				end
			end)
		end

		-- stagger all flakes so the window feels naturally filled
		task.spawn(function()
			for i = 1, MAX_FLAKES do
				local f, sz = makeFlake()
				-- half start mid-screen so it doesn't look empty at launch
				if i <= MAX_FLAKES / 2 then
					f.Position = UDim2.new(math.random(), 0, math.random() * 0.8, 0)
				end
				animateFlake(f, sz)
				task.wait(0.05)
			end
		end)
	end

	-- -- 3D Avatar Viewport (shows when avatar pic is clicked) ---------------
	local ViewportOpen = false

	local ViewportFrame = Create("Frame", {
		Name                   = "AvatarViewport",
		BackgroundColor3       = Color3.fromRGB(12, 4, 24),
		BackgroundTransparency = 0.05,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, 175, 0, 344),
		Position               = UDim2.new(0, 0, 0, 0),
		Visible                = false,
		ZIndex                 = 100,
		Parent                 = Orion
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = ViewportFrame})
	Create("UIStroke", {Color = Color3.fromRGB(90, 30, 140), Thickness = 1.5, Parent = ViewportFrame})

	-- Full body avatar image (top half of panel)
	Create("ImageLabel", {
		Image                  = "https://www.roblox.com/avatar-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png&thumbnailType=AvatarThumbnail",
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 145),
		Position               = UDim2.new(0, 0, 0, 20),
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 101,
		Parent                 = ViewportFrame
	})

	local function loadViewportChar() end

	-- Divider line
	Create("Frame", {
		BackgroundColor3       = Color3.fromRGB(80, 25, 130),
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0.9, 0, 0, 1),
		Position               = UDim2.new(0.05, 0, 0, 170),
		ZIndex                 = 102,
		Parent                 = ViewportFrame
	})

	-- Info rows helper
	local function InfoRow(label, value, yPos)
		Create("TextLabel", {
			Text             = label,
			Font             = Enum.Font.GothamBold,
			TextSize         = 10,
			TextColor3       = Color3.fromRGB(140, 90, 200),
			BackgroundTransparency = 1,
			Size             = UDim2.new(0.45, 0, 0, 16),
			Position         = UDim2.new(0, 8, 0, yPos),
			TextXAlignment   = Enum.TextXAlignment.Left,
			ZIndex           = 103,
			Parent           = ViewportFrame
		})
		local valLbl = Create("TextLabel", {
			Text             = tostring(value),
			Font             = Enum.Font.Gotham,
			TextSize         = 10,
			TextColor3       = Color3.fromRGB(220, 190, 255),
			BackgroundTransparency = 1,
			Size             = UDim2.new(0.55, -4, 0, 16),
			Position         = UDim2.new(0.45, 0, 0, yPos),
			TextXAlignment   = Enum.TextXAlignment.Left,
			ZIndex           = 103,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			Parent           = ViewportFrame
		})
		return valLbl
	end

	local yStart = 178

	-- Display name + username
	InfoRow("Display", LocalPlayer.DisplayName, yStart)
	InfoRow("Username", "@" .. LocalPlayer.Name, yStart + 18)
	InfoRow("User ID", LocalPlayer.UserId, yStart + 36)
	InfoRow("Account Age", LocalPlayer.AccountAge .. "d", yStart + 54)
	InfoRow("Executor", GetExecutor(), yStart + 72)

	-- Ping (live update)
	local pingRow = InfoRow("Ping", "--ms", yStart + 90)
	local fpsRow  = InfoRow("FPS", "--", yStart + 108)
	local gameRow = InfoRow("Game ID", game.GameId, yStart + 126)
	local placeRow = InfoRow("Place ID", game.PlaceId, yStart + 144)

	-- Update ping+fps live
	RunService.RenderStepped:Connect(function(dt)
		if ViewportFrame.Visible then
			pcall(function()
				pingRow.Text = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms"
			end)
			fpsRow.Text = math.floor(1/dt) .. " fps"
		end
	end)



-- avatar shown via ImageLabel thumbnail

	-- Rotate character in viewport


	-- Track which side panel is on and follow MainWindow when it moves
	local vpSide     = "right"  -- "left" or "right"
	local vpDragging = false    -- declared here so RenderStepped can read it

	local function resetViewportPos()
		local wp  = MainWindow.AbsolutePosition
		local ws  = MainWindow.AbsoluteSize
		local vpH = ViewportFrame.AbsoluteSize.Y
		vpSide = "right"
		-- center vertically on the UI
		ViewportFrame.Position = UDim2.new(0, wp.X + ws.X + 20, 0, wp.Y + (ws.Y - vpH) / 2)
	end

	-- Smoothly follow MainWindow using lerp
	RunService.RenderStepped:Connect(function()
		if ViewportFrame.Visible and not vpDragging then
			local wp  = MainWindow.AbsolutePosition
			local ws  = MainWindow.AbsoluteSize
			local vpw = ViewportFrame.AbsoluteSize.X
			local vpH     = ViewportFrame.AbsoluteSize.Y
			local targetX = vpSide == "right" and (wp.X + ws.X + 20) or (wp.X - vpw - 20)
			local targetY = wp.Y + (ws.Y - vpH) / 2
			local curX = ViewportFrame.Position.X.Offset
			local curY = ViewportFrame.Position.Y.Offset
			-- smooth lerp toward target
			local newX = curX + (targetX - curX) * 0.12
			local newY = curY + (targetY - curY) * 0.12
			ViewportFrame.Position = UDim2.new(0, newX, 0, newY)
		end
	end)

	-- Toggle on avatar click
	-- Single persistent UIScale for viewport animation
	local VPScale = Instance.new("UIScale")
	VPScale.Scale  = 1
	VPScale.Parent = ViewportFrame  -- kept at 1, animation uses position instead

	local function openViewport()
		ViewportOpen = true
		loadViewportChar()
		local wp    = MainWindow.AbsolutePosition
		local ws    = MainWindow.AbsoluteSize
		local vpW   = ViewportFrame.AbsoluteSize.X
		local vpH   = ViewportFrame.AbsoluteSize.Y
		local centY = wp.Y + (ws.Y - vpH) / 2
		-- land position based on vpSide
		local landX = vpSide == "left" and (wp.X - vpW - 20) or (wp.X + ws.X + 20)
		-- start offscreen on same side
		local startX = vpSide == "left" and (landX - vpW - 40) or (landX + vpW + 40)
		ViewportFrame.Position               = UDim2.new(0, startX, 0, centY)
		ViewportFrame.BackgroundTransparency = 1
		ViewportFrame.Visible                = true
		VPScale.Scale = 1
		TweenService:Create(ViewportFrame,
			TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = UDim2.new(0, landX, 0, centY), BackgroundTransparency = 0.05}
		):Play()
	end

	local function closeViewport()
		ViewportOpen = false
		local curY  = ViewportFrame.Position.Y.Offset
		local curX  = ViewportFrame.Position.X.Offset
		local vpW   = ViewportFrame.AbsoluteSize.X
		-- exit direction matches which side it's on
		local exitX = vpSide == "left" and (curX - vpW - 40) or (curX + vpW + 40)
		local t = TweenService:Create(ViewportFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{Position = UDim2.new(0, exitX, 0, curY), BackgroundTransparency = 1}
		)
		t:Play()
		t.Completed:Connect(function()
			ViewportFrame.Visible = false
		end)
	end

	local AvatarBtn = MainWindow:FindFirstChild("AvatarBtn", true)
	if AvatarBtn then
		AvatarBtn.MouseButton1Click:Connect(function()
			if ViewportOpen then closeViewport() else openViewport() end
		end)
	end



	-- Hide viewport when UI hides
	-- Drag with magnet snap: releases to left or right side of MainWindow
	local VPDragBtn = Create("TextButton", {
		Text                = "",
		BackgroundTransparency = 1,
		Size                = UDim2.new(1, -30, 0, 20),
		Position            = UDim2.new(0, 0, 0, 0),
		ZIndex              = 110,
		Parent              = ViewportFrame
	})

	local vpDragStart, vpFrameStart = nil, nil

	VPDragBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			vpDragging   = true
			vpDragStart  = Vector2.new(input.Position.X, input.Position.Y)
			vpFrameStart = Vector2.new(ViewportFrame.Position.X.Offset, ViewportFrame.Position.Y.Offset)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if vpDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - vpDragStart
			ViewportFrame.Position = UDim2.new(0, vpFrameStart.X + delta.X, 0, vpFrameStart.Y + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and vpDragging then
			vpDragging = false
			-- magnet snap: find closest side of MainWindow
			local wp  = MainWindow.AbsolutePosition
			local ws  = MainWindow.AbsoluteSize
			local vpw = ViewportFrame.AbsoluteSize.X
			local vpX = ViewportFrame.Position.X.Offset
			local vpY = ViewportFrame.Position.Y.Offset

			-- magnet snap left or right, vertically centered on UI
			local vpH    = ViewportFrame.AbsoluteSize.Y
			local snapY  = wp.Y + (ws.Y - vpH) / 2
			local leftX  = wp.X - vpw - 20
			local rightX = wp.X + ws.X + 20
			if math.abs(vpX - leftX) < math.abs(vpX - rightX) then
				vpSide = "left"
				TweenService:Create(ViewportFrame,
					TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{Position = UDim2.new(0, leftX, 0, snapY)}
				):Play()
			else
				vpSide = "right"
				TweenService:Create(ViewportFrame,
					TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{Position = UDim2.new(0, rightX, 0, snapY)}
				):Play()
			end
		end
	end)

	-- -- Topbar FPS/Ping live update --------------------------------------
	do
		local fpsBuffer = {}
		RunService.RenderStepped:Connect(function(dt)
			table.insert(fpsBuffer, dt)
			if #fpsBuffer > 20 then table.remove(fpsBuffer, 1) end
			if TopbarStats and TopbarStats.Parent then
				local avg = 0
				for _, v in ipairs(fpsBuffer) do avg = avg + v end
				avg = avg / #fpsBuffer
				local fps  = math.floor(1 / avg)
				local ping = 0
				pcall(function()
					ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				TopbarStats.Text = "FPS: " .. fps .. "  |  Ping: " .. ping .. "ms"
			end
		end)
	end

	-- -- Cyan blink glow on avatar ----------------------------------------
	task.spawn(function()
		local glowStroke = nil
		-- find GlowStroke after window is built
		for _, desc in ipairs(MainWindow:GetDescendants()) do
			if desc.Name == "GlowStroke" and desc:IsA("UIStroke") then
				glowStroke = desc
				break
			end
		end
		if not glowStroke then return end
		local bright = Color3.fromRGB(0, 220, 255)
		local dim    = Color3.fromRGB(0, 80, 120)
		local on     = true
		while MainWindow and MainWindow.Parent do
			local target = on and bright or dim
			TweenService:Create(glowStroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Color = target}):Play()
			on = not on
			task.wait(0.9)
		end
	end)

	-- -- Initial open animation (scale from 0 to 1 from center) -----------
	do
		MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
		MainWindow.Position    = UDim2.new(0.5, 0, 0.5, 0)
		MainWindow.Visible     = true
		local uiScale = getUIScale()
		uiScale.Scale = 0
		TweenService:Create(uiScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end

	-- -- Inline Settings Panel -----------------------------------------------
	local SettingsPanelOpen = false

	-- Panel sits just below topbar, right-aligned
	local SettingsPanel = SetChildren(SetProps(MakeElement("RoundFrame",
		OrionLib.Themes[OrionLib.SelectedTheme].Main, 0, 8), {
		Size             = UDim2.new(0, 200, 0, 0),
		Position         = UDim2.new(1, -210, 0, 52),
		ZIndex           = 50,
		Visible          = false,
		ClipsDescendants = true,
		Parent           = Orion
	}), {
		AddThemeObject(MakeElement("Stroke"), "Stroke"),
		MakeElement("Padding", 6, 6, 6, 6),
		MakeElement("List", 0, 2)
	})

	-- Lock Tabs toggle in settings
	local PinRow = Create("Frame", {
		BackgroundColor3       = OrionLib.Themes[OrionLib.SelectedTheme].Second,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 0, 32),
		ZIndex                 = 51,
		Parent                 = SettingsPanel
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = PinRow})
	Create("TextLabel", {
		Text = "Lock Tabs", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Color3.fromRGB(220, 180, 255), BackgroundTransparency = 1,
		Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52, Parent = PinRow
	})
	local PinTrack = Create("Frame", {
		BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Divider,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 36, 0, 20),
		Position         = UDim2.new(1, -44, 0.5, -10),
		ZIndex           = 52, Parent = PinRow
	})
	Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = PinTrack})
	local PinKnob = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(160, 160, 180),
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 14, 0, 14),
		Position         = UDim2.new(0, 3, 0.5, -7),
		ZIndex           = 53, Parent = PinTrack
	})
	Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = PinKnob})
	local PinClickBtn = Create("TextButton", {
		Text = "", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 54, Parent = PinRow
	})
	PinClickBtn.MouseButton1Click:Connect(function()
		sbPinned = not sbPinned
		local tw = TweenInfo.new(0.2, Enum.EasingStyle.Quint)
		if sbPinned then
			TweenService:Create(PinTrack, tw, {BackgroundColor3 = Color3.fromRGB(120, 50, 200)}):Play()
			TweenService:Create(PinKnob,  tw, {Position = UDim2.new(0, 19, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
			setSidebar(true)
		else
			TweenService:Create(PinTrack, tw, {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Divider}):Play()
			TweenService:Create(PinKnob,  tw, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = Color3.fromRGB(160,160,180)}):Play()
			setSidebar(false)
		end
	end)

	local function MakeSettingBtn(text, cb)
		local f = Create("Frame", {
			BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
			Size             = UDim2.new(1, 0, 0, 32),
			BorderSizePixel  = 0,
			ZIndex           = 51,
			Parent           = SettingsPanel
		})
		Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = f})
		local lbl = Create("TextLabel", {
			Text             = text,
			Font             = Enum.Font.GothamSemibold,
			TextSize         = 13,
			TextColor3       = OrionLib.Themes[OrionLib.SelectedTheme].Text,
			BackgroundTransparency = 1,
			Size             = UDim2.new(1, -12, 1, 0),
			Position         = UDim2.new(0, 12, 0, 0),
			TextXAlignment   = Enum.TextXAlignment.Left,
			ZIndex           = 52,
			Name             = "Content",
			Parent           = f
		})
		local click = Create("TextButton", {
			Text                = "",
			BackgroundTransparency = 1,
			Size                = UDim2.new(1, 0, 1, 0),
			ZIndex              = 53,
			Parent              = f
		})
		local base = OrionLib.Themes[OrionLib.SelectedTheme].Second
		local hover = Color3.fromRGB(
			math.clamp(base.R*255+8, 0, 255),
			math.clamp(base.G*255+8, 0, 255),
			math.clamp(base.B*255+8, 0, 255)
		)
		click.MouseEnter:Connect(function()
			TweenService:Create(f,   TweenInfo.new(0.12, Enum.EasingStyle.Quint), {BackgroundColor3 = hover}):Play()
			TweenService:Create(lbl, TweenInfo.new(0.12, Enum.EasingStyle.Quint), {TextSize = 14}):Play()
		end)
		click.MouseLeave:Connect(function()
			TweenService:Create(f,   TweenInfo.new(0.12, Enum.EasingStyle.Quint), {BackgroundColor3 = base}):Play()
			TweenService:Create(lbl, TweenInfo.new(0.12, Enum.EasingStyle.Quint), {TextSize = 13}):Play()
		end)
		click.MouseButton1Click:Connect(function() spawn(cb) end)
	end

	-- Settings helpers (need folder/flags)
	local function SPGetFolder() return OrionLib.Folder or "OrionConfig" end
	local function SPGetPath(n) return SPGetFolder().."/"..n..".json" end
	local function SPEnsureFolder() pcall(function() if not isfolder(SPGetFolder()) then makefolder(SPGetFolder()) end end) end

	local function SPSave(name)
		SPEnsureFolder()
		local data={}
		for flag,elem in pairs(OrionLib.Flags) do
			if elem.Type=="Colorpicker" then data[flag]={R=elem.Value.R*255,G=elem.Value.G*255,B=elem.Value.B*255}
			elseif elem.Value~=nil then data[flag]=elem.Value end
		end
		local ok,err=pcall(writefile,SPGetPath(name),HttpService:JSONEncode(data))
		OrionLib:MakeNotification({Name=ok and "Config Saved" or "Save Failed",Content=ok and "Saved '"..name.."'" or tostring(err),Time=4})
	end

	local function SPLoad(name)
		local ok,raw=pcall(readfile,SPGetPath(name))
		if not ok or not raw or raw=="" then OrionLib:MakeNotification({Name="Load Failed",Content="No config: "..name,Time=4}) return end
		local dok,data=pcall(function() return HttpService:JSONDecode(raw) end)
		if not dok then OrionLib:MakeNotification({Name="Load Failed",Content="Bad JSON",Time=4}) return end
		for flag,val in pairs(data) do
			if OrionLib.Flags[flag] then spawn(function()
				if OrionLib.Flags[flag].Type=="Colorpicker" then OrionLib.Flags[flag]:Set(Color3.fromRGB(val.R,val.G,val.B))
				else OrionLib.Flags[flag]:Set(val) end
			end) end
		end
		OrionLib:MakeNotification({Name="Config Loaded",Content="Loaded '"..name.."'",Time=4})
	end

	-- default config name comes from WindowConfig
	local cfgName = (WindowConfig.ConfigFolder or "OrionConfig"):gsub("[^%w_]","_")

	-- -- Keybind row (top of panel) --------------------------------------
	-- Shows current key, click to rebind
	local kbRow = Create("Frame", {
		BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
		Size             = UDim2.new(1, 0, 0, 32),
		BorderSizePixel  = 0,
		ZIndex           = 51,
		Parent           = SettingsPanel
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = kbRow})

	local kbLabel = Create("TextLabel", {
		Text             = "Toggle Key",
		Font             = Enum.Font.GothamSemibold,
		TextSize         = 13,
		TextColor3       = OrionLib.Themes[OrionLib.SelectedTheme].Text,
		BackgroundTransparency = 1,
		Size             = UDim2.new(0, 90, 1, 0),
		Position         = UDim2.new(0, 12, 0, 0),
		TextXAlignment   = Enum.TextXAlignment.Left,
		ZIndex           = 52,
		Parent           = kbRow
	})

	local kbBox = Create("Frame", {
		BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
		Size             = UDim2.new(0, 80, 0, 22),
		Position         = UDim2.new(1, -88, 0.5, -11),
		BorderSizePixel  = 0,
		ZIndex           = 52,
		Parent           = kbRow
	})
	Create("UICorner",  {CornerRadius = UDim.new(0, 4), Parent = kbBox})
	Create("UIStroke",  {Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke, Thickness = 1, Parent = kbBox})

	local kbText = Create("TextLabel", {
		Text             = "RightShift",
		Font             = Enum.Font.GothamBold,
		TextSize         = 11,
		TextColor3       = OrionLib.Themes[OrionLib.SelectedTheme].Text,
		BackgroundTransparency = 1,
		Size             = UDim2.new(1, -4, 1, 0),
		Position         = UDim2.new(0, 2, 0, 0),
		TextXAlignment   = Enum.TextXAlignment.Center,
		ZIndex           = 53,
		Parent           = kbBox
	})

	-- Click anywhere on the row to start listening for new key
	local kbListening = false
	local kbClick = Create("TextButton", {
		Text = "", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 54, Parent = kbRow
	})

	kbClick.MouseButton1Click:Connect(function()
		if kbListening then return end
		kbListening = true
		kbText.Text = "..."
		-- flash the box
		TweenService:Create(kbBox, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 80, 120)}):Play()
		-- wait for next key press
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == Enum.KeyCode.Unknown then return end
			-- set the new key
			ToggleKey = input.KeyCode
			kbText.Text = input.KeyCode.Name
			TweenService:Create(kbBox, TweenInfo.new(0.15), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main}):Play()
			kbListening = false
			conn:Disconnect()
			OrionLib:MakeNotification({
				Name    = "Keybind Set",
				Content = "Toggle key set to " .. input.KeyCode.Name,
				Time    = 3
			})
		end)
	end)

	-- separator line between keybind and config buttons
	Create("Frame", {
		BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
		Size             = UDim2.new(1, 0, 0, 1),
		BorderSizePixel  = 0,
		ZIndex           = 51,
		Parent           = SettingsPanel
	})

	MakeSettingBtn("  Export (Copy)",  function()
		local data={}
		for flag,elem in pairs(OrionLib.Flags) do
			if elem.Type=="Colorpicker" then data[flag]={R=elem.Value.R*255,G=elem.Value.G*255,B=elem.Value.B*255}
			elseif elem.Value~=nil then data[flag]=elem.Value end
		end
		pcall(setclipboard,HttpService:JSONEncode(data))
		OrionLib:MakeNotification({Name="Exported",Content="Config copied to clipboard.",Time=4})
	end)
	MakeSettingBtn("  Reset All",      function()
		for _,elem in pairs(OrionLib.Flags) do
			if elem.Type=="Toggle" then pcall(function() elem:Set(false) end)
			elseif elem.Type=="Colorpicker" then pcall(function() elem:Set(Color3.fromRGB(255,255,255)) end) end
		end
		OrionLib:MakeNotification({Name="Reset",Content="All settings reset.",Time=4})
	end)
	MakeSettingBtn("  Destroy UI",     function()
		OrionLib:MakeNotification({Name="Goodbye",Content="UI destroyed.",Time=2})
		task.wait(2.2); OrionLib:Destroy()
	end)

	-- Size panel to fit buttons, then hook up toggle
	task.defer(function()
		task.wait()
		local ll = SettingsPanel:FindFirstChild("UIListLayout")
		if ll then
			SettingsPanel.Size = UDim2.new(0, 200, 0, ll.AbsoluteContentSize.Y + 12)
		end
	end)

	local function openSettingsPanel()
		SettingsPanelOpen = true
		local ll = SettingsPanel:FindFirstChild("UIListLayout")
		local fullH = ll and ll.AbsoluteContentSize.Y + 12 or 200
		-- position below gear button using screen coords
		local bp = SettingsBtn.AbsolutePosition
		local bs = SettingsBtn.AbsoluteSize
		SettingsPanel.Position = UDim2.new(0, bp.X - 165, 0, bp.Y + bs.Y + 4)
		SettingsPanel.Size     = UDim2.new(0, 200, 0, 0)
		SettingsPanel.Visible  = true
		TweenService:Create(SettingsPanel,
			TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 200, 0, fullH)}
		):Play()
		TweenService:Create(SettingsBtn.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Rotation = 90}):Play()
	end

	local function closeSettingsPanel()
		SettingsPanelOpen = false
		TweenService:Create(SettingsPanel,
			TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 200, 0, 0)}
		):Play()
		TweenService:Create(SettingsBtn.Ico, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
		task.delay(0.22, function()
			SettingsPanel.Visible = false
		end)
	end

	AddConnection(SettingsBtn.MouseButton1Click, function()
		if SettingsPanelOpen then closeSettingsPanel() else openSettingsPanel() end
	end)

	-- close panel when clicking outside both the panel and the button
	AddConnection(UserInputService.InputBegan, function(Input)
		if not SettingsPanelOpen then return end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local pos = Input.Position
		-- check panel bounds
		local sp = SettingsPanel.AbsolutePosition
		local ss = SettingsPanel.AbsoluteSize
		local inPanel = pos.X >= sp.X and pos.X <= sp.X+ss.X and pos.Y >= sp.Y and pos.Y <= sp.Y+ss.Y
		-- check button bounds
		local bp = SettingsBtn.AbsolutePosition
		local bs = SettingsBtn.AbsoluteSize
		local inBtn = pos.X >= bp.X and pos.X <= bp.X+bs.X and pos.Y >= bp.Y and pos.Y <= bp.Y+bs.Y
		if not inPanel and not inBtn then
			closeSettingsPanel()
		end
	end)

	-- auto-load config on start
	task.defer(function()
		pcall(function()
			if isfile and isfile(SPGetPath(cfgName)) then
				SPLoad(cfgName)
			end
		end)
	end)

	-- -- FPS / Ping live update ---------------------------------------------


	-- -- Resizable UI -------------------------------------------------------
	-- Resize arc: circle with UIStroke, clipped to show only bottom-right quarter
	local ResizeArcClip = Create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants       = true,
		Size                   = UDim2.new(0, 40, 0, 40),
		Position               = UDim2.new(0, 0, 0, 0),
		ZIndex                 = 20,
		Parent                 = Orion
	})
	-- full circle, offset so only bottom-right quarter shows through the clip
	local ResizeArc = Create("Frame", {
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 80, 0, 80),
		Position               = UDim2.new(0, -40, 0, -40),
		ZIndex                 = 21,
		Parent                 = ResizeArcClip
	})
	Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ResizeArc})
	local ArcStroke = Create("UIStroke", {
		Color        = Color3.fromRGB(180, 80, 255),
		Thickness    = 4,
		Transparency = 0.3,
		Parent       = ResizeArc
	})

	-- invisible button over the clip area for interaction
	local RCBtn = Create("TextButton", {
		Text = "", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 22, Parent = ResizeArcClip
	})

	-- keep anchored just outside bottom-right corner of window
	RunService.RenderStepped:Connect(function()
		if MainWindow and MainWindow.Parent then
			local wp = MainWindow.AbsolutePosition
			local ws = MainWindow.AbsoluteSize
			ResizeArcClip.Position = UDim2.new(0, wp.X + ws.X - 22, 0, wp.Y + ws.Y - 22)
		end
	end)

	-- hover highlight
	RCBtn.MouseEnter:Connect(function()
		TweenService:Create(ArcStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Transparency = 0, Color = Color3.fromRGB(210, 100, 255)}):Play()
	end)
	RCBtn.MouseLeave:Connect(function()
		TweenService:Create(ArcStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Transparency = 0.3, Color = Color3.fromRGB(180, 80, 255)}):Play()
	end)

	-- resize logic
	local resizing = false
	local resizeStart, resizeStartSize
	local minW, minH = 400, 250

	RCBtn.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing        = true
			resizeStart     = Vector2.new(Input.Position.X, Input.Position.Y)
			resizeStartSize = Vector2.new(MainWindow.AbsoluteSize.X, MainWindow.AbsoluteSize.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if resizing and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Vector2.new(Input.Position.X, Input.Position.Y) - resizeStart
			local newW  = math.max(minW, resizeStartSize.X + delta.X)
			local newH  = math.max(minH, resizeStartSize.Y + delta.Y)
			MainWindow.Size  = UDim2.new(0, newW, 0, newH)
			local _sw = sbOpen and SB_WIDE or SB_THIN
			WindowStuff.Size     = UDim2.new(0, _sw, 1, -50)
			WindowStuff.Position = UDim2.new(0, 0, 0, 50)
			for _, c in ipairs(MainWindow:GetChildren()) do
				if c.Name == "ItemContainer" then
					c.Position = UDim2.new(0, _sw, 0, 50)
					c.Size     = UDim2.new(1, -_sw, 1, -50)
				end
			end
		end
	end)

	-- -- Hide / Show UI ---------------------------------------------------
	local toggleDebounce = false

	local function HideUI()
		if toggleDebounce then return end
		toggleDebounce = true
		UIHidden = true
		local uiScale = getUIScale()
		TweenService:Create(uiScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play()
		task.delay(0.28, function()
			MainWindow.Visible    = false
			BottomPill.Visible    = false
			ResizeArcClip.Visible = false
			if ViewportOpen then
				ViewportOpen = false
				ViewportFrame.Visible = false
			end
			uiScale.Scale = 1
			toggleDebounce = false
		end)
	end

	local function ShowUI()
		if toggleDebounce then return end
		toggleDebounce = true
		UIHidden = false
		local uiScale = getUIScale()
		uiScale.Scale = 0
		-- always reopen centered
		MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
		MainWindow.Position    = UDim2.new(0.5, 0, 0.5, 0)
		MainWindow.Visible     = true
		BottomPill.Visible     = true
		ResizeArcClip.Visible  = true
		TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		task.delay(0.45, function()
			toggleDebounce = false
		end)
	end

	AddConnection(CloseBtn.MouseButton1Up, function()
		HideUI()
		OrionLib:MakeNotification({
			Name    = "Interface Hidden",
			Content = "Press " .. ToggleKey.Name .. " to reopen",
			Time    = 4
		})
		WindowConfig.CloseCallback()
	end)

	-- Use both InputBegan and a key-held poll to catch RightShift on all executors
	UserInputService.InputBegan:Connect(function(Input)
		if Input.KeyCode == ToggleKey then
			if UIHidden then ShowUI() else HideUI() end
		end
	end)
	-- Fallback: poll every frame in case InputBegan is swallowed by the executor
	local lastKeyState = false
	RunService.Heartbeat:Connect(function()
		local pressed = UserInputService:IsKeyDown(ToggleKey)
		if pressed and not lastKeyState then
			if UIHidden then ShowUI() else HideUI() end
		end
		lastKeyState = pressed
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 615, 0, 344)}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			task.wait(0.02)
			WindowStuff.Visible   = true
			WindowTopBarLine.Visible = true
			BottomPill.Visible    = true
			ResizeArcClip.Visible = true
		else
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
			local minWidth = math.max(400, WindowName.TextBounds.X + 320)
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, minWidth, 0, 50)}):Play()
			task.wait(0.1)
			WindowStuff.Visible   = false
			BottomPill.Visible    = false
			ResizeArcClip.Visible = false
		end
		Minimized = not Minimized
	end)

	local TabFunction = {}
	OrionLib._tabRegistry = OrionLib._tabRegistry or {}

	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name       = TabConfig.Name       or "Tab"
		TabConfig.Icon       = TabConfig.Icon       or ""
		TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

		-- Icon: uses Roblox BuilderIcons font (same as NeverLose UI)
		local iconChar = (TabConfig.Icon ~= "" and TabConfig.Icon) or "three-dots-horizontal"
		local TabIconLbl = Create("TextLabel", {
			Text             = iconChar,
			FontFace = MakeBIconFont(),
			TextSize         = 16,
			TextColor3       = Color3.fromRGB(160, 80, 255),
			TextTransparency = 0.2,
			BackgroundTransparency = 1,
			AnchorPoint      = Vector2.new(0, 0.5),
			Size             = UDim2.new(0, 22, 0, 22),
			Position         = UDim2.new(0, 11, 0.5, 0),
			TextXAlignment   = Enum.TextXAlignment.Center,
			TextWrapped      = true,
			Name             = "Ico"
		})

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size   = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder
		}), {
			TabIconLbl,
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size             = UDim2.new(0, 0, 1, 0),
				Position         = UDim2.new(0, 34, 0, 0),
				Font             = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				ClipsDescendants = true,
				Name             = "Title"
			}), "Text")
		})

		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
			Size             = UDim2.new(1, -44, 1, -50),
			Position         = UDim2.new(0, 44, 0, 50),
			Parent           = MainWindow,
			Visible          = false,
			Name             = "ItemContainer",
			ScrollingEnabled = true,
			ScrollingDirection = Enum.ScrollingDirection.Y
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")

		-- only connect UIListLayout canvas updater if NOT columns mode
		-- (columns mode destroys UIListLayout and manages its own canvas)
		if not TabConfig.Columns then
			local function _updateCanvas()
				if not Container or not Container.Parent then return end
				local ll = Container:FindFirstChildOfClass("UIListLayout")
				if not ll then return end
				local newH = ll.AbsoluteContentSize.Y + 30
				if math.abs(Container.CanvasSize.Y.Offset - newH) > 1 then
					Container.CanvasSize = UDim2.new(0, 0, 0, newH)
				end
			end
			AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), _updateCanvas)
			task.defer(_updateCanvas)
		end

		-- Two-column layout: two independent ScrollingFrames inside a wrapper
		local ColLeft, ColRight = nil, nil
		local colIndex = 0
		if TabConfig.Columns then
			-- wrapper fills same space as normal Container
			local ColWrapper = Create("Frame", {
				BackgroundTransparency = 1,
				Size                   = UDim2.new(1, -44, 1, -50),
				Position               = UDim2.new(0, 44, 0, 50),
				Visible                = false,
				Name                   = "ItemContainer",
				Parent                 = MainWindow
			})

			ColLeft = Create("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Size                   = UDim2.new(0.5, -6, 1, 0),
				Position               = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness     = 0,
				ScrollBarImageColor3   = Color3.fromRGB(0, 0, 0),
				CanvasSize             = UDim2.new(0, 0, 0, 0),
				ScrollingDirection     = Enum.ScrollingDirection.Y,
				Parent                 = ColWrapper
			})
			Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = ColLeft})
			Create("UIPadding",    {PaddingLeft = UDim.new(0,8), PaddingTop = UDim.new(0,10), PaddingRight = UDim.new(0,4), PaddingBottom = UDim.new(0,10), Parent = ColLeft})

			ColRight = Create("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Size                   = UDim2.new(0.5, -6, 1, 0),
				Position               = UDim2.new(0.5, 6, 0, 0),
				ScrollBarThickness     = 0,
				ScrollBarImageColor3   = Color3.fromRGB(0, 0, 0),
				CanvasSize             = UDim2.new(0, 0, 0, 0),
				ScrollingDirection     = Enum.ScrollingDirection.Y,
				Parent                 = ColWrapper
			})
			Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = ColRight})
			Create("UIPadding",    {PaddingLeft = UDim.new(0,4), PaddingTop = UDim.new(0,10), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,10), Parent = ColRight})



			local function updateCol(col)
				local ll = col:FindFirstChildOfClass("UIListLayout")
				if ll then col.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 20) end
			end
			ColLeft:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() updateCol(ColLeft) end)
			ColRight:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() updateCol(ColRight) end)

			-- reference ColWrapper as Container for show/hide purposes
			Container = ColWrapper
		end

		local _TabTitle = TabFrame:FindFirstChild("Title")
		local _TabIco   = TabFrame:FindFirstChild("Ico")
		local si = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		if FirstTab then
			FirstTab = false
			TabIconLbl.TextTransparency = 0
			if _TabTitle then
				_TabTitle.TextTransparency = 0
				_TabTitle.Font = Enum.Font.GothamBlack
			end
			-- snap to correct sidebar position immediately on open
			local _fcx = sbOpen and SB_WIDE or SB_THIN
			Container.Size     = UDim2.new(1, -_fcx, 1, -50)
			Container.Position = UDim2.new(0, _fcx, 0, 50)
			Container.Visible  = true
		end
		AddConnection(TabFrame.MouseEnter, function()
			if not Container.Visible then
				if _TabTitle then TweenService:Create(_TabTitle, si, {TextSize = 14.3, TextTransparency = 0.1}):Play() end
				if _TabIco   then TweenService:Create(_TabIco,   si, {TextSize = 15.3, TextTransparency = 0.05}):Play() end

			end
		end)
		AddConnection(TabFrame.MouseLeave, function()
			if not Container.Visible then
				if _TabTitle then TweenService:Create(_TabTitle, si, {TextSize = 14, TextTransparency = 0.4}):Play() end
				if _TabIco   then TweenService:Create(_TabIco,   si, {TextSize = 15, TextTransparency = 0.2}):Play() end

			end
		end)

		-- register this tab for search (ClickFn set after AddConnection below)
		local _regEntry = {
			TabFrame = TabFrame,
			Container = Container,
			Name = TabConfig.Name,
			ClickFn = nil,
		}
		table.insert(OrionLib._tabRegistry, _regEntry)

		local function _doTabClick()
			-- Deactivate all tabs
			for _, Tab in next, TabHolder:GetChildren() do
				if Tab:IsA("TextButton") then
					local TabTitle = Tab:FindFirstChild("Title")
					local TabIco   = Tab:FindFirstChild("Ico")
					if TabTitle then
						TabTitle.Font = Enum.Font.GothamSemibold
						TweenService:Create(TabTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4, TextSize = 14}):Play()
					end
					if TabIco then
						TweenService:Create(TabIco, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4, TextSize = 15, TextColor3 = Color3.fromRGB(160, 80, 255)}):Play()
					end
				end
			end

			-- hide all containers
			for _, ItemContainer in next, MainWindow:GetChildren() do
				if ItemContainer.Name == "ItemContainer" then
					ItemContainer.Visible = false
				end
			end

			-- Activate this tab
			if _TabTitle then
				TweenService:Create(_TabTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, TextSize = 14}):Play()
				_TabTitle.Font = Enum.Font.GothamBlack
			end
			if _TabIco then
				TweenService:Create(_TabIco, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, TextSize = 16, TextColor3 = Color3.fromRGB(190, 100, 255)}):Play()
			end

			-- slide down from slightly above + fade in simultaneously
			local _cx = sbOpen and SB_WIDE or SB_THIN
			Container.Size     = UDim2.new(1, -_cx, 1, -50)
			Container.Position = UDim2.new(0, _cx, 0, 38)
			Container.Visible  = true
			if not TabConfig.Columns then
				task.defer(function()
					local ll = Container:FindFirstChildOfClass("UIListLayout")
					if ll then Container.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 30) end
				end)
			end
			-- slide to final position
			TweenService:Create(Container,
				TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{Position = UDim2.new(0, _cx, 0, 50)}
			):Play()
			-- slide down + fade in: overlay parented to MainWindow so it's not clipped by ScrollingFrame
			local _fade = MainWindow:FindFirstChild("__FadeOverlay")
			if not _fade then
				_fade = Create("Frame", {
					Name                   = "__FadeOverlay",
					BackgroundColor3       = OrionLib.Themes[OrionLib.SelectedTheme].Main,
					BackgroundTransparency = 0,
					BorderSizePixel        = 0,
					Size                   = UDim2.new(1, -_cx, 1, -50),
					Position               = UDim2.new(0, _cx, 0, 50),
					ZIndex                 = 200,
					Parent                 = MainWindow
				})
			end
			_fade.Size                   = UDim2.new(1, -_cx, 1, -50)
			_fade.Position               = UDim2.new(0, _cx, 0, 50)
			_fade.BackgroundTransparency = 0
			_fade.Visible                = true
			TweenService:Create(_fade,
				TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{BackgroundTransparency = 1}
			):Play()
			task.delay(0.32, function() if _fade and _fade.Parent then _fade.Visible = false end end)
		end
		AddConnection(TabFrame.MouseButton1Click, _doTabClick)
		if _regEntry then _regEntry.ClickFn = _doTabClick end

		local function GetElements(ItemParent)
			local ElementFunction = {}

			function ElementFunction:AddLabel(Text)
				local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size                = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent              = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size     = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font     = Enum.Font.GothamBold,
						Name     = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")
				local LabelFunction = {}
				function LabelFunction:Set(ToChange) LabelFrame.Content.Text = ToChange end
				return LabelFunction
			end

			function ElementFunction:AddParagraph(Text, Content)
				Text    = Text    or "Text"
				Content = Content or "Content"
				local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size                = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent              = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size     = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font     = Enum.Font.GothamBold,
						Name     = "Title"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", "", 13), {
						Size        = UDim2.new(1, -24, 0, 0),
						Position    = UDim2.new(0, 12, 0, 26),
						Font        = Enum.Font.GothamSemibold,
						Name        = "Content",
						TextWrapped = true
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")
				local function resizeParagraph()
					ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size         = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
				end
				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), resizeParagraph)
				AddConnection(ParagraphFrame:GetPropertyChangedSignal("AbsoluteSize"), resizeParagraph)
				ParagraphFrame.Content.Text = Content
				task.defer(resizeParagraph)
				local ParagraphFunction = {}
				function ParagraphFunction:Set(ToChange) ParagraphFrame.Content.Text = ToChange end
				return ParagraphFunction
			end

			-- shared popover creator - shows BELOW the anchor element
			local function MakePopover(anchorFrame, items)
				local pop = Create("Frame", {
					BackgroundColor3       = Color3.fromRGB(18, 6, 36),
					BackgroundTransparency = 1,
					BorderSizePixel        = 0,
					Size                   = UDim2.new(0, 0, 0, 0),
					ClipsDescendants       = true,
					Visible                = false,
					ZIndex                 = 60,
					Parent                 = Orion
				})
				Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = pop})
				Create("UIStroke", {Color = Color3.fromRGB(90, 30, 140), Thickness = 1, Parent = pop})
				local popList = Create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pop})
				Create("UIPadding", {PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8), Parent=pop})

				for _, item in ipairs(items) do
					if item.Type == "slider" then
						local val = item.Default or item.Min
						local row = Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,44), ZIndex=61, Parent=pop})
						Create("TextLabel", {Text=item.Name, Font=Enum.Font.GothamBold, TextSize=12,
							TextColor3=Color3.fromRGB(200,160,255), BackgroundTransparency=1,
							Size=UDim2.new(1,-32,0,14), ZIndex=62, Parent=row})
						local valLbl = Create("TextLabel", {Text=tostring(val), Font=Enum.Font.GothamBold, TextSize=12,
							TextColor3=Color3.fromRGB(160,110,255), BackgroundTransparency=1,
							Size=UDim2.new(0,30,0,14), Position=UDim2.new(1,-30,0,0),
							TextXAlignment=Enum.TextXAlignment.Right, ZIndex=62, Parent=row})
						local track = Create("Frame", {BackgroundColor3=Color3.fromRGB(35,12,60),
							BorderSizePixel=0, Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,22), ZIndex=62, Parent=row})
						Create("UICorner", {CornerRadius=UDim.new(1,0), Parent=track})
						local pct = (val-item.Min)/math.max(1,item.Max-item.Min)
						local fill = Create("Frame", {BackgroundColor3=Color3.fromRGB(130,55,210),
							BorderSizePixel=0, Size=UDim2.new(pct,0,1,0), ZIndex=63, Parent=track})
						Create("UICorner", {CornerRadius=UDim.new(1,0), Parent=fill})
						local knob = Create("Frame", {BackgroundColor3=Color3.fromRGB(255,255,255),
							BorderSizePixel=0, Size=UDim2.new(0,12,0,12),
							Position=UDim2.new(pct,-6,0.5,-6), ZIndex=64, Parent=track})
						Create("UICorner", {CornerRadius=UDim.new(1,0), Parent=knob})
						local drag = false
						track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
						UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
						UserInputService.InputChanged:Connect(function(i)
							if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
								local rel = math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
								val = math.floor(item.Min+rel*(item.Max-item.Min))
								fill.Size = UDim2.new(rel,0,1,0)
								knob.Position = UDim2.new(rel,-6,0.5,-6)
								valLbl.Text = tostring(val)
								item.Callback(val)
							end
						end)
					elseif item.Type == "input" then
						local row = Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,34), ZIndex=61, Parent=pop})
						Create("TextLabel", {Text=item.Name, Font=Enum.Font.GothamBold, TextSize=12,
							TextColor3=Color3.fromRGB(200,160,255), BackgroundTransparency=1,
							Size=UDim2.new(0.45,0,1,0), ZIndex=62, Parent=row})
						local box = Create("TextBox", {Text=tostring(item.Default or ""), Font=Enum.Font.Gotham, TextSize=12,
							TextColor3=Color3.fromRGB(220,190,255), BackgroundColor3=Color3.fromRGB(30,10,55),
							BorderSizePixel=0, Size=UDim2.new(0.55,-4,0,24), Position=UDim2.new(0.45,4,0.5,-12),
							TextXAlignment=Enum.TextXAlignment.Center, ZIndex=62, ClearTextOnFocus=false, Parent=row})
						Create("UICorner", {CornerRadius=UDim.new(0,4), Parent=box})
						Create("UIStroke", {Color=Color3.fromRGB(80,30,130), Thickness=1, Parent=box})
						box.FocusLost:Connect(function() item.Callback(box.Text) end)
					elseif item.Type == "keybind" then
						local row = Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,34), ZIndex=61, Parent=pop})
						Create("TextLabel", {Text="Keybind", Font=Enum.Font.GothamBold, TextSize=12,
							TextColor3=Color3.fromRGB(200,160,255), BackgroundTransparency=1,
							Size=UDim2.new(0.55,0,1,0), ZIndex=62, Parent=row})
						local kbBox = Create("TextButton", {
							Text = item.Default and (item.Default.Name or tostring(item.Default)) or "None",
							Font=Enum.Font.GothamBold, TextSize=12,
							TextColor3=Color3.fromRGB(180,120,255), BackgroundColor3=Color3.fromRGB(30,10,55),
							BorderSizePixel=0, Size=UDim2.new(0.4,0,0,24), Position=UDim2.new(0.6,0,0.5,-12),
							ZIndex=62, Parent=row,
						})
						Create("UICorner", {CornerRadius=UDim.new(0,4), Parent=kbBox})
						Create("UIStroke", {Color=Color3.fromRGB(80,30,130), Thickness=1, Parent=kbBox})
						local listening = false
						kbBox.MouseButton1Click:Connect(function()
							listening = true
							kbBox.Text = "..."
							local conn
							conn = UserInputService.InputBegan:Connect(function(inp)
								if not listening then return end
								if inp.KeyCode == Enum.KeyCode.Backspace then
									listening = false
									conn:Disconnect()
									kbBox.Text = "None"
									item.Callback(nil)
									return
								end
								if inp.KeyCode ~= Enum.KeyCode.Unknown or inp.UserInputType == Enum.UserInputType.MouseButton1 then
									listening = false
									conn:Disconnect()
									local key = inp.KeyCode ~= Enum.KeyCode.Unknown and inp.KeyCode or inp.UserInputType
									kbBox.Text = key.Name
									item.Callback(key)
								end
							end)
						end)
					end
				end

				local popW, popH = 0, 0
				local followConn
				local function updatePos()
					local ap = anchorFrame.AbsolutePosition
					local as = anchorFrame.AbsoluteSize
					pop.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
				end
				local function showPop()
					task.defer(function()
						local ap = anchorFrame.AbsolutePosition
						local as = anchorFrame.AbsoluteSize
						local h  = math.max(popList.AbsoluteContentSize.Y + 20, 60)
						local w  = math.max(as.X, 160)
						popW, popH = w, h
						pop.Size                   = UDim2.new(0, w, 0, 0)
						pop.Position               = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
						pop.BackgroundTransparency = 1
						pop.Visible                = true
						TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
							{Size = UDim2.new(0, w, 0, h), BackgroundTransparency = 0}):Play()
						if followConn then followConn:Disconnect() end
						followConn = RunService.RenderStepped:Connect(updatePos)
					end)
				end
				local function hidePop()
					if followConn then followConn:Disconnect() followConn = nil end
					TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
						{Size = UDim2.new(0, popW, 0, 0), BackgroundTransparency = 1}):Play()
					task.delay(0.27, function() pop.Visible = false end)
				end
				UserInputService.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 and pop.Visible then
						local mx, my = inp.Position.X, inp.Position.Y
						local px, py = pop.AbsolutePosition.X, pop.AbsolutePosition.Y
						local pw, ph = pop.AbsoluteSize.X, pop.AbsoluteSize.Y
						if mx < px or mx > px+pw or my < py or my > py+ph then
							hidePop() popOpen = false
						end
					end
				end)
				local popOpen = false
				return pop, showPop, hidePop, function() return popOpen end, function(v) popOpen = v end
			end

			function ElementFunction:AddButton(ButtonConfig)
				ButtonConfig          = ButtonConfig or {}
				ButtonConfig.Name     = ButtonConfig.Name     or "Button"
				ButtonConfig.Callback = ButtonConfig.Callback or function() end
				ButtonConfig.Icon     = ButtonConfig.Icon     or "rbxassetid://3944703587"
				local Button = {}
				local Click  = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
				local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size   = UDim2.new(1, 0, 0, 33),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
						Size     = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font     = Enum.Font.GothamBold,
						Name     = "Content"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
						Size     = UDim2.new(0, 20, 0, 20),
						Position = UDim2.new(1, -30, 0, 7)
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					Click
				}), "Second")
				local btnSmooth = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local btnFast   = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local S = OrionLib.Themes[OrionLib.SelectedTheme].Second
				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ButtonFrame, btnSmooth, {BackgroundColor3 = Color3.fromRGB(S.R*255+4, S.G*255+4, S.B*255+4)}):Play()
					TweenService:Create(ButtonFrame.Content, btnSmooth, {TextSize = 15.5}):Play()
				end)
				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ButtonFrame, btnSmooth, {BackgroundColor3 = S}):Play()
					TweenService:Create(ButtonFrame.Content, btnSmooth, {TextSize = 15}):Play()
				end)
				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ButtonFrame, btnFast, {BackgroundColor3 = Color3.fromRGB(S.R*255+8, S.G*255+8, S.B*255+8)}):Play()
					TweenService:Create(ButtonFrame.Content, btnFast, {TextSize = 14.5}):Play()
				end)
				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ButtonFrame, btnSmooth, {BackgroundColor3 = Color3.fromRGB(S.R*255+4, S.G*255+4, S.B*255+4)}):Play()
					TweenService:Create(ButtonFrame.Content, btnSmooth, {TextSize = 15.5}):Play()
					spawn(function() ButtonConfig.Callback() end)
				end)
				function Button:Set(ButtonText) ButtonFrame.Content.Text = ButtonText end

				-- keybind box to LEFT of fingerprint icon - OPT-IN ONLY (set ShowKeybind = true)
				if ButtonConfig.ShowKeybind then
					local _btnFlagId = (ButtonConfig.Flag or ButtonConfig.Name) .. "_btn"
					makeKeybindBox(ButtonFrame, -58, ButtonConfig.Keybind, nil, _btnFlagId, function()
						spawn(function() ButtonConfig.Callback() end)
					end)
					ButtonFrame:FindFirstChild("Content").Size = UDim2.new(1, -66, 1, 0)
				end

				-- gear settings button (opt-in via Options table)
				if ButtonConfig.Options then
					local dotBtn = Create("TextButton", {
						Text             = "gear",
						FontFace         = MakeBIconFont(),
						TextSize         = 13,
						TextColor3       = Color3.fromRGB(140, 80, 200),
						BackgroundColor3 = Color3.fromRGB(30, 10, 55),
						BackgroundTransparency = 0,
						BorderSizePixel  = 0,
						Size             = UDim2.new(0, 24, 0, 24),
						Position         = UDim2.new(1, -58, 0.5, -12),
						ZIndex           = 5,
						Parent           = ButtonFrame
					})
					Create("UICorner", {CornerRadius=UDim.new(0,5), Parent=dotBtn})
					local _pop, showP, hideP, isOpen, setOpen = MakePopover(dotBtn, ButtonConfig.Options)
					dotBtn.MouseButton1Click:Connect(function()
						if isOpen() then hideP() setOpen(false)
						else showP() setOpen(true) end
					end)
					ButtonFrame:FindFirstChild("Content").Size = UDim2.new(1, -66, 1, 0)
				end

				return Button
			end

			function ElementFunction:AddToggle(ToggleConfig)
				ToggleConfig          = ToggleConfig or {}
				ToggleConfig.Name     = ToggleConfig.Name     or "Toggle"
				ToggleConfig.Default  = ToggleConfig.Default  or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end
				ToggleConfig.Color    = ToggleConfig.Color    or Color3.fromRGB(120, 50, 200)
				ToggleConfig.Flag     = ToggleConfig.Flag     or nil
				ToggleConfig.Save     = ToggleConfig.Save     or false
				local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save, Type = "Toggle"}
				local Click  = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
				-- Switch track
				local SwitchTrack = Create("Frame", {
					Size             = UDim2.new(0, 40, 0, 22),
					Position         = UDim2.new(1, -50, 0.5, -11),
					BackgroundColor3 = OrionLib.Themes.Default.Divider,
					BorderSizePixel  = 0,
				})
				Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SwitchTrack})
				Create("UIStroke", {Color = OrionLib.Themes.Default.Stroke, Thickness = 1, Name = "Stroke", Parent = SwitchTrack})
				-- Switch knob
				local SwitchKnob = Create("Frame", {
					Size             = UDim2.new(0, 16, 0, 16),
					Position         = UDim2.new(0, 3, 0.5, -8),
					BackgroundColor3 = Color3.fromRGB(160, 160, 180),
					BorderSizePixel  = 0,
					ZIndex           = 2,
					Parent           = SwitchTrack
				})
				Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SwitchKnob})
				local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size   = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
						Size     = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font     = Enum.Font.GothamBold,
						Name     = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					SwitchTrack,
					Click
				}), "Second")
				function Toggle:Set(Value)
					Toggle.Value = Value
					pcall(function()
						local tw = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						if Toggle.Value then
							TweenService:Create(SwitchTrack, tw, {BackgroundColor3 = ToggleConfig.Color}):Play()
							do local _s=SwitchTrack:FindFirstChild("Stroke") if _s then TweenService:Create(_s, tw, {Color = ToggleConfig.Color}):Play() end end
							TweenService:Create(SwitchKnob, tw, {Position = UDim2.new(0, 21, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
						else
							TweenService:Create(SwitchTrack, tw, {BackgroundColor3 = OrionLib.Themes.Default.Divider}):Play()
							do local _s=SwitchTrack:FindFirstChild("Stroke") if _s then TweenService:Create(_s, tw, {Color = OrionLib.Themes.Default.Stroke}):Play() end end
							TweenService:Create(SwitchKnob, tw, {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(160, 160, 180)}):Play()
						end
					end)
					ToggleConfig.Callback(Toggle.Value)
				end
				task.defer(function() Toggle:Set(Toggle.Value) end)
				local tgSmooth = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local TS2 = OrionLib.Themes[OrionLib.SelectedTheme].Second
				AddConnection(Click.MouseEnter,      function() TweenService:Create(ToggleFrame, tgSmooth, {BackgroundColor3 = Color3.fromRGB(TS2.R*255+4, TS2.G*255+4, TS2.B*255+4)}):Play() end)
				AddConnection(Click.MouseLeave,      function() TweenService:Create(ToggleFrame, tgSmooth, {BackgroundColor3 = TS2}):Play() end)
				AddConnection(Click.MouseButton1Up,  function() TweenService:Create(ToggleFrame, tgSmooth, {BackgroundColor3 = Color3.fromRGB(TS2.R*255+4, TS2.G*255+4, TS2.B*255+4)}):Play() SaveCfg(game.GameId) Toggle:Set(not Toggle.Value) end)
				AddConnection(Click.MouseButton1Down, function() TweenService:Create(ToggleFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(TS2.R*255+8, TS2.G*255+8, TS2.B*255+8)}):Play() end)
				if ToggleConfig.Flag then OrionLib.Flags[ToggleConfig.Flag] = Toggle end

				-- keybind box to LEFT of toggle switch - OPT-IN ONLY (set ShowKeybind = true)
				if ToggleConfig.ShowKeybind then
					local _togFlagId = (ToggleConfig.Flag or ToggleConfig.Name) .. "_tog"
					makeKeybindBox(ToggleFrame, -80, ToggleConfig.Keybind, nil, _togFlagId, function()
						Toggle:Set(not Toggle.Value)
					end)
					ToggleFrame:FindFirstChild("Content").Size = UDim2.new(1, -88, 1, 0)
				end

				-- gear settings button (opt-in via Options table)
				if ToggleConfig.Options then
					local dotBtn = Create("TextButton", {
						Text             = "gear",
						FontFace         = MakeBIconFont(),
						TextSize         = 13,
						TextColor3       = Color3.fromRGB(140, 80, 200),
						BackgroundColor3 = Color3.fromRGB(30, 10, 55),
						BackgroundTransparency = 0,
						BorderSizePixel  = 0,
						Size             = UDim2.new(0, 24, 0, 24),
						Position         = UDim2.new(1, -78, 0.5, -12),
						ZIndex           = 5,
						Parent           = ToggleFrame
					})
					Create("UICorner", {CornerRadius=UDim.new(0,5), Parent=dotBtn})
					local _pop, showP, hideP, isOpen, setOpen = MakePopover(dotBtn, ToggleConfig.Options)
					dotBtn.MouseButton1Click:Connect(function()
						if isOpen() then hideP() setOpen(false)
						else showP() setOpen(true) end
					end)
					-- if keybind box is also present, shift dot left to make room
					local _hasKb = ToggleConfig.ShowKeybind == true
					if _hasKb then
						dotBtn.Position = UDim2.new(1, -106, 0.5, -12)
					end
					ToggleFrame:FindFirstChild("Content").Size = UDim2.new(1, _hasKb and -118 or -90, 1, 0)
				end

				return Toggle
			end

			function ElementFunction:AddSlider(SliderConfig)
				SliderConfig           = SliderConfig or {}
				SliderConfig.Name      = SliderConfig.Name      or "Slider"
				SliderConfig.Min       = SliderConfig.Min       or 0
				SliderConfig.Max       = SliderConfig.Max       or 100
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.Default   = SliderConfig.Default   or 50
				SliderConfig.Callback  = SliderConfig.Callback  or function() end
				SliderConfig.ValueName = SliderConfig.ValueName or SliderConfig.Suffix or ""
				SliderConfig.Color     = SliderConfig.Color     or Color3.fromRGB(120, 50, 200)
				SliderConfig.Flag      = SliderConfig.Flag      or nil
				SliderConfig.Save      = SliderConfig.Save      or false
				local Slider   = {Value = SliderConfig.Default, Save = SliderConfig.Save, Type = "Slider"}
				local Dragging = false
				local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
					Size                = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 0.3,
					ClipsDescendants    = true
				}), {
					AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
						Size             = UDim2.new(1, -12, 0, 14),
						Position         = UDim2.new(0, 12, 0, 6),
						Font             = Enum.Font.GothamBold,
						Name             = "Value",
						TextTransparency = 0
					}), "Text")
				})
				local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
					Size                = UDim2.new(1, -24, 0, 26),
					Position            = UDim2.new(0, 12, 0, 30),
					BackgroundTransparency = 0.9
				}), {
					SetProps(MakeElement("Stroke"), {Color = SliderConfig.Color}),
					AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
						Size             = UDim2.new(1, -12, 0, 14),
						Position         = UDim2.new(0, 12, 0, 6),
						Font             = Enum.Font.GothamBold,
						Name             = "Value",
						TextTransparency = 0.8
					}), "Text"),
					SliderDrag
				})
				local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size   = UDim2.new(1, 0, 0, 65),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 15), {
						Size     = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font     = Enum.Font.GothamBold,
						Name     = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					SliderBar
				}), "Second")
				SliderBar.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true end end)
				SliderBar.InputEnded:Connect(function(Input)  if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)
				UserInputService.InputChanged:Connect(function(Input)
					if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
						local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
						SaveCfg(game.GameId)
					end
				end)
				function Slider:Set(Value)
					self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
					TweenService:Create(SliderDrag, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)}):Play()
					SliderBar.Value.Text  = tostring(self.Value) .. " " .. SliderConfig.ValueName
					SliderDrag.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
					SliderConfig.Callback(self.Value)
				end
				Slider:Set(Slider.Value)
				if SliderConfig.Flag then OrionLib.Flags[SliderConfig.Flag] = Slider end
				return Slider
			end

			function ElementFunction:AddDropdown(DropdownConfig)
				DropdownConfig          = DropdownConfig or {}
				DropdownConfig.Name     = DropdownConfig.Name     or "Dropdown"
				DropdownConfig.Options  = DropdownConfig.Options  or {}
				DropdownConfig.Default  = DropdownConfig.Default  or ""
				DropdownConfig.Callback = DropdownConfig.Callback or function() end
				DropdownConfig.Flag     = DropdownConfig.Flag     or nil
				DropdownConfig.Save     = DropdownConfig.Save     or false
				local Dropdown   = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
				local MaxElements = 5
				if not table.find(Dropdown.Options, Dropdown.Value) then Dropdown.Value = "..." end
				local DropdownList      = MakeElement("List")
				local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(40, 40, 40), 4), {
					DropdownList,
					Create("UICorner", {CornerRadius = UDim.new(0, 5)})
				}), {
					Parent           = ItemParent,
					Position         = UDim2.new(0, 0, 0, 38),
					Size             = UDim2.new(1, 0, 1, -38),
					ClipsDescendants = true,
					Visible          = false
				}), "Divider")
				local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
				local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size             = UDim2.new(1, 0, 0, 38),
					Parent           = ItemParent,
					ClipsDescendants = true
				}), {
					DropdownContainer,
					SetProps(SetChildren(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 15), {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamBold, Name = "Content"}), "Text"),
						AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -30, 0.5, 0), ImageColor3 = Color3.fromRGB(240, 240, 240), Name = "Ico"}), "TextDark"),
						AddThemeObject(SetProps(MakeElement("Label", "Selected", 13), {Size = UDim2.new(1, -40, 1, 0), Font = Enum.Font.Gotham, Name = "Selected", TextXAlignment = Enum.TextXAlignment.Right}), "TextDark"),
						AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), Name = "Line", Visible = false}), "Stroke"),
						Click
					}), {Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true, Name = "F"}),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					MakeElement("Corner")
				}), "Second")
				AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
				end)
				local function AddOptions(Options)
					for _, Option in pairs(Options) do
						local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", Color3.fromRGB(40, 40, 40)), {
							MakeElement("Corner", 0, 6),
							AddThemeObject(SetProps(MakeElement("Label", Option, 13, 0.4), {Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -8, 1, 0), Name = "Title"}), "Text")
						}), {Parent = DropdownContainer, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, ClipsDescendants = true}), "Divider")
						AddConnection(OptionBtn.MouseButton1Click, function()
						Dropdown:Set(Option)
						SaveCfg(game.GameId)
						-- auto close dropdown after selecting
						if Dropdown.Toggled then
							Dropdown.Toggled = false
							DropdownFrame.F.Line.Visible = false
							DropdownContainer.Visible = false
							TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()
							TweenService:Create(DropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 38)}):Play()
						end
					end)
						Dropdown.Buttons[Option] = OptionBtn
					end
				end
				function Dropdown:Refresh(Options, Delete)
					if Delete then for _,v in pairs(Dropdown.Buttons) do v:Destroy() end table.clear(Dropdown.Options) table.clear(Dropdown.Buttons) end
					Dropdown.Options = Options
					AddOptions(Dropdown.Options)
				end
				function Dropdown:Set(Value)
					if not table.find(Dropdown.Options, Value) then
						Dropdown.Value = "..."
						DropdownFrame.F.Selected.Text = Dropdown.Value
						for _, v in pairs(Dropdown.Buttons) do TweenService:Create(v,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play() TweenService:Create(v.Title,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0.4}):Play() end
						return
					end
					Dropdown.Value = Value
					DropdownFrame.F.Selected.Text = Dropdown.Value
					for _, v in pairs(Dropdown.Buttons) do TweenService:Create(v,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play() TweenService:Create(v.Title,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0.4}):Play() end
					TweenService:Create(Dropdown.Buttons[Value],TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
					TweenService:Create(Dropdown.Buttons[Value].Title,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
					return DropdownConfig.Callback(Dropdown.Value)
				end
				AddConnection(Click.MouseButton1Click, function()
					Dropdown.Toggled = not Dropdown.Toggled
					DropdownFrame.F.Line.Visible = Dropdown.Toggled
					DropdownContainer.Visible = Dropdown.Toggled
					local _rot = Dropdown.Toggled and 180 or 0
					TweenService:Create(DropdownFrame.F.Ico,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Rotation=_rot}):Play()
					if #Dropdown.Options > MaxElements then
						local _ddSize = Dropdown.Toggled and UDim2.new(1,0,0,38+(MaxElements*28)) or UDim2.new(1,0,0,38)
						TweenService:Create(DropdownFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=_ddSize}):Play()
					else
						local _ddSize2 = Dropdown.Toggled and UDim2.new(1,0,0,DropdownList.AbsoluteContentSize.Y+38) or UDim2.new(1,0,0,38)
						TweenService:Create(DropdownFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=_ddSize2}):Play()
					end
				end)
				Dropdown:Refresh(Dropdown.Options, false)
				Dropdown:Set(Dropdown.Value)
				if DropdownConfig.Flag then OrionLib.Flags[DropdownConfig.Flag] = Dropdown end
				return Dropdown
			end

			function ElementFunction:AddBind(BindConfig)
				BindConfig          = BindConfig or {}
				BindConfig.Name     = BindConfig.Name     or "Bind"
				BindConfig.Default  = BindConfig.Default  or Enum.KeyCode.Unknown
				BindConfig.Hold     = BindConfig.Hold     or false
				BindConfig.Callback = BindConfig.Callback or function() end
				BindConfig.Flag     = BindConfig.Flag     or nil
				BindConfig.Save     = BindConfig.Save     or false
				local Bind    = {Value, Binding = false, Type = "Bind", Save = BindConfig.Save}
				local Holding = false
				local Click   = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
				local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size        = UDim2.new(0, 24, 0, 24),
					Position    = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					ClipsDescendants = true
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, Name = "Value"}), "Text")
				}), "Main")
				local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size   = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 15), {Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamBold, Name = "Content"}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					BindBox, Click
				}), "Second")
				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
					local sz = TextService:GetTextSize(BindBox.Value.Text, 14, Enum.Font.GothamBold, Vector2.new(1000,24))
					local w = math.clamp(sz.X + 16, 24, 130)
					TweenService:Create(BindBox,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,w,0,24)}):Play()
				end)
				AddConnection(Click.InputEnded, function(Input) if Input.UserInputType==Enum.UserInputType.MouseButton1 then if Bind.Binding then return end Bind.Binding=true BindBox.Value.Text="" end end)
				AddConnection(UserInputService.InputBegan, function(Input)
					if UserInputService:GetFocusedTextBox() then return end
					if (Input.KeyCode.Name==Bind.Value or Input.UserInputType.Name==Bind.Value) and not Bind.Binding then
						if BindConfig.Hold then Holding=true BindConfig.Callback(Holding) else BindConfig.Callback() end
					elseif Bind.Binding then
						local Key
						pcall(function() if not CheckKey(BlacklistedKeys,Input.KeyCode) then Key=Input.KeyCode end end)
						pcall(function() if CheckKey(WhitelistedMouse,Input.UserInputType) and not Key then Key=Input.UserInputType end end)
						Key=Key or Bind.Value; Bind:Set(Key); SaveCfg(game.GameId)
					end
				end)
				AddConnection(UserInputService.InputEnded, function(Input)
					if Input.KeyCode.Name==Bind.Value or Input.UserInputType.Name==Bind.Value then
						if BindConfig.Hold and Holding then Holding=false BindConfig.Callback(Holding) end
					end
				end)
				AddConnection(Click.MouseEnter,      function() TweenService:Create(BindFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play() end)
				AddConnection(Click.MouseLeave,      function() TweenService:Create(BindFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play() end)
				AddConnection(Click.MouseButton1Up,  function() TweenService:Create(BindFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play() end)
				AddConnection(Click.MouseButton1Down, function() TweenService:Create(BindFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+6,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+6,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+6)}):Play() end)
				function Bind:Set(Key) Bind.Binding=false Bind.Value=Key or Bind.Value Bind.Value=Bind.Value.Name or Bind.Value BindBox.Value.Text=Bind.Value end
				Bind:Set(BindConfig.Default)
				if BindConfig.Flag then OrionLib.Flags[BindConfig.Flag] = Bind end
				return Bind
			end

			function ElementFunction:AddTextbox(TextboxConfig)
				TextboxConfig              = TextboxConfig or {}
				TextboxConfig.Name         = TextboxConfig.Name         or "Textbox"
				TextboxConfig.Default      = TextboxConfig.Default      or ""
				TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
				TextboxConfig.Callback     = TextboxConfig.Callback     or function() end
				local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
				local TextboxActual = AddThemeObject(Create("TextBox", {
					Size               = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextColor3         = Color3.fromRGB(255, 255, 255),
					PlaceholderColor3  = Color3.fromRGB(210, 210, 210),
					PlaceholderText    = "Input",
					Font               = Enum.Font.GothamSemibold,
					TextXAlignment     = Enum.TextXAlignment.Center,
					TextSize           = 14,
					ClearTextOnFocus   = false
				}), "Text")
				local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size        = UDim2.new(0, 24, 0, 24),
					Position    = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					ClipsDescendants = true
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextboxActual
				}), "Main")
				local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size   = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 15), {Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamBold, Name = "Content"}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextContainer, Click
				}), "Second")
				local _resizing = false
				local function measureAndSize(text)
					local sz = TextService:GetTextSize(text, 14, Enum.Font.GothamSemibold, Vector2.new(1000,24))
					local w = math.clamp(sz.X + 16, 24, 130)
					return w
				end
				AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
					if _resizing then return end
					local w = measureAndSize(TextboxActual.Text)
					TweenService:Create(TextContainer,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,w,0,24)}):Play()
				end)
				AddConnection(TextboxActual.FocusLost, function() TextboxConfig.Callback(TextboxActual.Text) if TextboxConfig.TextDisappear then TextboxActual.Text="" end end)
				_resizing = true
				TextboxActual.Text = TextboxConfig.Default
				local measureText = TextboxConfig.Default ~= "" and TextboxConfig.Default or "Input"
				TextContainer.Size = UDim2.new(0, measureAndSize(measureText), 0, 24)
				_resizing = false
				AddConnection(Click.MouseEnter,      function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play() end)
				AddConnection(Click.MouseLeave,      function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play() end)
				AddConnection(Click.MouseButton1Up,  function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play() TextboxActual:CaptureFocus() end)
				AddConnection(Click.MouseButton1Down, function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+6,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+6,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+6)}):Play() end)
			end

			function ElementFunction:AddSearch(SearchConfig)
				SearchConfig             = SearchConfig or {}
				SearchConfig.Name        = SearchConfig.Name        or "Search"
				SearchConfig.Items       = SearchConfig.Items       or {}
				SearchConfig.Callback    = SearchConfig.Callback    or function() end
				SearchConfig.Placeholder = SearchConfig.Placeholder or "Type to search..."

				-- Results dropdown (starts hidden, expands below the element)
				local ResultsFrame = AddThemeObject(Create("Frame", {
					BackgroundTransparency = 0,
					BorderSizePixel        = 0,
					Size                   = UDim2.new(1, 0, 0, 0),
					ClipsDescendants       = true,
					ZIndex                 = 20,
				}), "Second")
				Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = ResultsFrame})
				Create("UIStroke", {Color = Color3.fromRGB(80, 25, 130), Thickness = 1, Parent = ResultsFrame})
				Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = ResultsFrame})

				-- Main element frame (same height as a button)
				local SearchMain = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size   = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SearchConfig.Name, 15), {
						Size     = UDim2.new(0.45, 0, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font     = Enum.Font.GothamBold,
						Name     = "Content"
					}), "Text"),
					-- search input box on the right side
					AddThemeObject(Create("TextBox", {
						Text               = "",
						PlaceholderText    = SearchConfig.Placeholder,
						Font               = Enum.Font.Gotham,
						TextSize           = 13,
						BackgroundTransparency = 1,
						ClearTextOnFocus   = false,
						Size               = UDim2.new(0.52, -24, 0, 22),
						Position           = UDim2.new(0.45, 4, 0.5, -11),
						TextXAlignment     = Enum.TextXAlignment.Left,
						ZIndex             = 2,
						Name               = "SearchBox"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
				}), "Second")

				local SearchBox = SearchMain:FindFirstChild("SearchBox")

				-- position results just below the element
				ResultsFrame.Position = UDim2.new(0, 0, 1, 2)

				-- Results float OVER content (no layout expansion)
				ResultsFrame.Parent   = Orion  -- parent to ScreenGui so it overlays
				ResultsFrame.Size     = UDim2.new(0, 0, 0, 0)
				ResultsFrame.Visible  = false

				-- keep results aligned below SearchMain every frame
				RunService.RenderStepped:Connect(function()
					if ResultsFrame.Visible then
						local ap = SearchMain.AbsolutePosition
						local as = SearchMain.AbsoluteSize
						ResultsFrame.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
						ResultsFrame.Size     = UDim2.new(0, as.X, 0, ResultsFrame.Size.Y.Offset)
					end
				end)

				local function hideResults()
					for _, c in ipairs(ResultsFrame:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end
					TweenService:Create(ResultsFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Size = UDim2.new(0, ResultsFrame.Size.X.Offset, 0, 0)}):Play()
					task.delay(0.18, function() ResultsFrame.Visible = false end)
				end

				local function showResults(query)
					for _, c in ipairs(ResultsFrame:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end
					local q = query:lower()
					if q == "" then hideResults() return end

					local count = 0
					for _, item in ipairs(SearchConfig.Items) do
						if tostring(item):lower():find(q, 1, true) then
							local btn = Create("TextButton", {
								Text             = tostring(item),
								Font             = Enum.Font.GothamSemibold,
								TextSize         = 13,
								TextColor3       = Color3.fromRGB(220, 190, 255),
								BackgroundColor3 = Color3.fromRGB(28, 10, 50),
								BackgroundTransparency = 0,
								BorderSizePixel  = 0,
								Size             = UDim2.new(1, 0, 0, 30),
								TextXAlignment   = Enum.TextXAlignment.Left,
								ZIndex           = 51,
								Parent           = ResultsFrame
							})
							Create("UIPadding", {PaddingLeft = UDim.new(0, 12), Parent = btn})
							btn.MouseEnter:Connect(function()
								TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 20, 100)}):Play()
							end)
							btn.MouseLeave:Connect(function()
								TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28, 10, 50)}):Play()
							end)
							btn.MouseButton1Click:Connect(function()
								SearchBox.Text = tostring(item)
								SearchConfig.Callback(item)
								hideResults()
							end)
							count = count + 1
							if count >= 6 then break end
						end
					end

					if count > 0 then
						local h = count * 30
						local ap = SearchMain.AbsolutePosition
						local as = SearchMain.AbsoluteSize
						ResultsFrame.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
						ResultsFrame.Size     = UDim2.new(0, as.X, 0, 0)
						ResultsFrame.Visible  = true
						TweenService:Create(ResultsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(0, as.X, 0, h)}):Play()
					else
						hideResults()
					end
				end

				SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
					showResults(SearchBox.Text)
				end)

				SearchBox.FocusLost:Connect(function()
					task.delay(0.25, function() hideResults() end)
				end)
			end

			function ElementFunction:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig          = ColorpickerConfig or {}
				ColorpickerConfig.Name     = ColorpickerConfig.Name     or "Colorpicker"
				ColorpickerConfig.Default  = ColorpickerConfig.Default  or Color3.fromRGB(255, 255, 255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
				ColorpickerConfig.Flag     = ColorpickerConfig.Flag     or nil
				ColorpickerConfig.Save     = ColorpickerConfig.Save     or false
				local ColorH, ColorS, ColorV = 1, 1, 1
				local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}
				local ColorSelection = Create("ImageLabel", {Size = UDim2.new(0,18,0,18), Position = UDim2.new(select(3,Color3.toHSV(Colorpicker.Value))), ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Image = "http://www.roblox.com/asset/?id=4805639000"})
				local HueSelection  = Create("ImageLabel", {Size = UDim2.new(0,18,0,18), Position = UDim2.new(0.5,0,1-select(1,Color3.toHSV(Colorpicker.Value))), ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Image = "http://www.roblox.com/asset/?id=4805639000"})
				local Color = Create("ImageLabel", {Size = UDim2.new(1,-25,1,0), Visible = false, Image = "rbxassetid://4155801252"}, {Create("UICorner",{CornerRadius=UDim.new(0,5)}), ColorSelection})
				local Hue   = Create("Frame", {Size = UDim2.new(0,20,1,0), Position = UDim2.new(1,-20,0,0), Visible = false}, {
					Create("UIGradient",{Rotation=270,Color=ColorSequence.new{ColorSequenceKeypoint.new(0.00,Color3.fromRGB(255,0,4)),ColorSequenceKeypoint.new(0.20,Color3.fromRGB(234,255,0)),ColorSequenceKeypoint.new(0.40,Color3.fromRGB(21,255,0)),ColorSequenceKeypoint.new(0.60,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.80,Color3.fromRGB(0,17,255)),ColorSequenceKeypoint.new(0.90,Color3.fromRGB(255,0,251)),ColorSequenceKeypoint.new(1.00,Color3.fromRGB(255,0,4))}}),
					Create("UICorner",{CornerRadius=UDim.new(0,5)}), HueSelection
				})
				local ColorpickerContainer = Create("Frame", {Position=UDim2.new(0,0,0,32), Size=UDim2.new(1,0,1,-32), BackgroundTransparency=1, ClipsDescendants=true}, {Hue, Color, Create("UIPadding",{PaddingLeft=UDim.new(0,35),PaddingRight=UDim.new(0,35),PaddingBottom=UDim.new(0,10),PaddingTop=UDim.new(0,17)})})
				local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
				local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,4),{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-12,0.5,0),AnchorPoint=Vector2.new(1,0.5)}),{AddThemeObject(MakeElement("Stroke"),"Stroke")}),"Main")
				local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,38),Parent=ItemParent}),{
					SetProps(SetChildren(MakeElement("TFrame"),{
						AddThemeObject(SetProps(MakeElement("Label",ColorpickerConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.GothamBold,Name="Content"}),"Text"),
						ColorpickerBox, Click,
						AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),Name="Line",Visible=false}),"Stroke")
					}),{Size=UDim2.new(1,0,0,38),ClipsDescendants=true,Name="F"}),
					ColorpickerContainer, AddThemeObject(MakeElement("Stroke"),"Stroke")
				}),"Second")
				AddConnection(Click.MouseButton1Click, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					local _cpSize = Colorpicker.Toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)
					TweenService:Create(ColorpickerFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=_cpSize}):Play()
					Color.Visible = Colorpicker.Toggled; Hue.Visible = Colorpicker.Toggled; ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
				end)
				local function UpdateColorPicker()
					ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH,ColorS,ColorV)
					Color.BackgroundColor3 = Color3.fromHSV(ColorH,1,1)
					Colorpicker:Set(ColorpickerBox.BackgroundColor3)
					ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
					SaveCfg(game.GameId)
				end
				ColorH = 1-(math.clamp(HueSelection.AbsolutePosition.Y-Hue.AbsolutePosition.Y,0,Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y)
				ColorS = (math.clamp(ColorSelection.AbsolutePosition.X-Color.AbsolutePosition.X,0,Color.AbsoluteSize.X)/Color.AbsoluteSize.X)
				ColorV = 1-(math.clamp(ColorSelection.AbsolutePosition.Y-Color.AbsolutePosition.Y,0,Color.AbsoluteSize.Y)/Color.AbsoluteSize.Y)
				AddConnection(Color.InputBegan, function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then if ColorInput then ColorInput:Disconnect() end ColorInput=AddConnection(RunService.RenderStepped,function() local CX=(math.clamp(Mouse.X-Color.AbsolutePosition.X,0,Color.AbsoluteSize.X)/Color.AbsoluteSize.X) local CY=(math.clamp(Mouse.Y-Color.AbsolutePosition.Y,0,Color.AbsoluteSize.Y)/Color.AbsoluteSize.Y) ColorSelection.Position=UDim2.new(CX,0,CY,0) ColorS=CX ColorV=1-CY UpdateColorPicker() end) end end)
				AddConnection(Color.InputEnded, function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then if ColorInput then ColorInput:Disconnect() end end end)
				AddConnection(Hue.InputBegan,   function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then if HueInput then HueInput:Disconnect() end HueInput=AddConnection(RunService.RenderStepped,function() local HY=(math.clamp(Mouse.Y-Hue.AbsolutePosition.Y,0,Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y) HueSelection.Position=UDim2.new(0.5,0,HY,0) ColorH=1-HY UpdateColorPicker() end) end end)
				AddConnection(Hue.InputEnded,   function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then if HueInput then HueInput:Disconnect() end end end)
				function Colorpicker:Set(Value) Colorpicker.Value=Value ColorpickerBox.BackgroundColor3=Colorpicker.Value ColorpickerConfig.Callback(Colorpicker.Value) end
				Colorpicker:Set(Colorpicker.Value)
				if ColorpickerConfig.Flag then OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker end
				return Colorpicker
			end

			-- -- AddDivider ---------------------------------------------------
			function ElementFunction:AddDivider()
				local DividerFrame = SetChildren(SetProps(MakeElement("TFrame"), {
					Size   = UDim2.new(1, 0, 0, 16),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Frame"), {
						AnchorPoint = Vector2.new(0, 0.5),
						Size        = UDim2.new(1, 0, 0, 1),
						Position    = UDim2.new(0, 0, 0.5, 0)
					}), "Stroke")
				})
				local DividerFunction = {}
				function DividerFunction:Set(Visible) DividerFrame.Visible = Visible end
				return DividerFunction
			end

			return ElementFunction
		end

		local ElementFunction = {}

		-- Column helpers: Tab:AddLeft() and Tab:AddRight() return element builders
		local function makeColElements(colFrame)
			if not colFrame then return ElementFunction end
			local elems = GetElements(colFrame)
			-- inject AddSection that also uses colFrame
			function elems:AddSection(SectionConfig)
				SectionConfig = SectionConfig or {}
				SectionConfig.Name = SectionConfig.Name or "Section"
				local _hScale  = SectionConfig.Collapsible and 0 or 1
				local _hOffset = SectionConfig.Collapsible and 0 or -24
				local _hPad    = SectionConfig.Collapsible and 20 or 0
				local collapsed = SectionConfig.Collapsible
				local fullH = 0

				local SectionLabel = AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 15), {
					Size     = UDim2.new(1, -30, 0, 20),
					Position = UDim2.new(0, 0, 0, 4),
					Font     = Enum.Font.GothamBlack,
					Name     = "SectionLabel"
				}), "Text")

				local HolderFrame = SetChildren(SetProps(MakeElement("TFrame"), {
					AnchorPoint      = Vector2.new(0, 0),
					Size             = UDim2.new(1, 0, _hScale, _hOffset),
					Position         = UDim2.new(0, 0, 0, 32),
					Name             = "Holder",
					ClipsDescendants = SectionConfig.Collapsible
				}), {
					MakeElement("List", 0, 6),
					MakeElement("Padding", (_hPad > 0 and _hPad or 3), 3, 3, 3)
				})

				local children = { SectionLabel, HolderFrame }

				if SectionConfig.Collapsible then
					local ArrowLbl = Create("TextLabel", {
						Text = ">", Font = Enum.Font.GothamBold, TextSize = 14,
						TextColor3 = Color3.fromRGB(160, 100, 210), BackgroundTransparency = 1,
						Size = UDim2.new(0, 16, 0, 20), Position = UDim2.new(1, -20, 0, 4),
						TextXAlignment = Enum.TextXAlignment.Center, Rotation = 90, ZIndex = 3
					})
					local ClickBtn = Create("TextButton", {
						Text = "", BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 26), ZIndex = 5
					})
					table.insert(children, ArrowLbl)
					table.insert(children, ClickBtn)
					local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
						Size = UDim2.new(1, 0, 0, 28), Parent = colFrame, ClipsDescendants = true
					}), children)
					local tw = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					AddConnection(HolderFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
						fullH = HolderFrame.UIListLayout.AbsoluteContentSize.Y
						if not collapsed then
							SectionFrame.Size = UDim2.new(1, 0, 0, fullH + 38)
							HolderFrame.Size  = UDim2.new(1, 0, 0, fullH + 8)
						end
					end)
					AddConnection(ClickBtn.MouseButton1Click, function()
						collapsed = not collapsed
						if collapsed then
							TweenService:Create(ArrowLbl,     tw, {Rotation = 90}):Play()
							TweenService:Create(HolderFrame,  tw, {Size = UDim2.new(1, 0, 0, 0)}):Play()
							TweenService:Create(SectionFrame, tw, {Size = UDim2.new(1, 0, 0, 28)}):Play()
						else
							fullH = HolderFrame.UIListLayout.AbsoluteContentSize.Y
							TweenService:Create(ArrowLbl,     tw, {Rotation = -90}):Play()
							TweenService:Create(HolderFrame,  tw, {Size = UDim2.new(1, 0, 0, fullH + 8)}):Play()
							TweenService:Create(SectionFrame, tw, {Size = UDim2.new(1, 0, 0, fullH + 38)}):Play()
						end
					end)
				else
					local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
						Size = UDim2.new(1, 0, 0, 26), Parent = colFrame
					}), children)
					AddConnection(HolderFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
						SectionFrame.Size = UDim2.new(1, 0, 0, HolderFrame.UIListLayout.AbsoluteContentSize.Y + 38)
						HolderFrame.Size  = UDim2.new(1, 0, 0, HolderFrame.UIListLayout.AbsoluteContentSize.Y + 8)
					end)
				end

				local sf = {}
				for i,v in next, GetElements(HolderFrame) do sf[i] = v end
				return sf
			end
			return elems
		end

		function ElementFunction:AddLeft()
			return makeColElements(ColLeft)
		end
		function ElementFunction:AddRight()
			return makeColElements(ColRight)
		end
		-- AddAuto: alternates left/right automatically (item 1=left, 2=right, 3=left...)
		function ElementFunction:AddAuto()
			colIndex = colIndex + 1
			return makeColElements(colIndex % 2 == 1 and ColLeft or ColRight)
		end

		function ElementFunction:AddSection(SectionConfig)
			SectionConfig = SectionConfig or {}
			SectionConfig.Name        = SectionConfig.Name        or "Section"
			SectionConfig.Collapsible = SectionConfig.Collapsible or false  -- opt-in only

			local collapsed = SectionConfig.Collapsible  -- if collapsible, start closed
			local fullH     = 0

			local SectionLabel = AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 15), {
				Size     = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 0, 0, 4),
				Font     = Enum.Font.GothamBlack,
				Name     = "SectionLabel"
			}), "Text")

			local _hScale  = SectionConfig.Collapsible and 0 or 1
			local _hOffset = SectionConfig.Collapsible and 0 or -24
			local _hPad    = SectionConfig.Collapsible and 20 or 0
			local HolderFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint      = Vector2.new(0, 0),
				Size             = UDim2.new(1, 0, _hScale, _hOffset),
				Position         = UDim2.new(0, 0, 0, 32),
				Name             = "Holder",
				ClipsDescendants = SectionConfig.Collapsible
			}), {
				MakeElement("List", 0, 6),
				MakeElement("Padding", (_hPad > 0 and _hPad or 3), 3, 3, 3)
			})

			local children = { SectionLabel, HolderFrame }

			-- Only add arrow and click button if collapsible
			if SectionConfig.Collapsible then
				local ArrowLbl = Create("TextLabel", {
					Text                   = ">",
					Font                   = Enum.Font.GothamBold,
					TextSize               = 14,
					TextColor3             = Color3.fromRGB(160, 100, 210),
					BackgroundTransparency = 1,
					Size                   = UDim2.new(0, 16, 0, 20),
					Position               = UDim2.new(1, -20, 0, 4),
					TextXAlignment         = Enum.TextXAlignment.Center,
					Rotation               = 90,  -- pointing down = closed
					ZIndex                 = 3
				})
				table.insert(children, ArrowLbl)

				local ClickBtn = Create("TextButton", {
					Text = "", BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 26), ZIndex = 5
				})
				table.insert(children, ClickBtn)

				local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
					Size = UDim2.new(1, 0, 0, 28), Parent = Container, ClipsDescendants = true
				}), children)

				local tw = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

				AddConnection(HolderFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					if not HolderFrame.Parent then return end
					local newH = HolderFrame.UIListLayout.AbsoluteContentSize.Y
					if newH == fullH then return end
					fullH = newH
					if not collapsed then
						SectionFrame.Size = UDim2.new(1, 0, 0, fullH + 38)
						HolderFrame.Size  = UDim2.new(1, 0, 0, fullH + 8)
					end
				end)

				AddConnection(ClickBtn.MouseButton1Click, function()
					collapsed = not collapsed
					if collapsed then
						TweenService:Create(ArrowLbl,     tw, {Rotation = -90}):Play()
						TweenService:Create(HolderFrame,  tw, {Size = UDim2.new(1, 0, 0, 0)}):Play()
						TweenService:Create(SectionFrame, tw, {Size = UDim2.new(1, 0, 0, 28)}):Play()
					else
						fullH = HolderFrame.UIListLayout.AbsoluteContentSize.Y
						TweenService:Create(ArrowLbl,     tw, {Rotation = 90}):Play()
						TweenService:Create(HolderFrame,  tw, {Size = UDim2.new(1, 0, 0, fullH + 8)}):Play()
						TweenService:Create(SectionFrame, tw, {Size = UDim2.new(1, 0, 0, fullH + 38)}):Play()
					end
				end)

				local SectionFunction = {}
				for i, v in next, GetElements(HolderFrame) do SectionFunction[i] = v end
				return SectionFunction
			end

			-- Non-collapsible: normal always-open section
			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 26), Parent = Container
			}), children)

			AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size        = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 38)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)

			local SectionFunction = {}
			for i, v in next, GetElements(HolderFrame) do SectionFunction[i] = v end
			return SectionFunction
		end

		for i, v in next, GetElements(Container) do
			ElementFunction[i] = v
		end

		if TabConfig.PremiumOnly then
			for i, v in next, ElementFunction do
				ElementFunction[i] = function() end
			end
			Container:FindFirstChild("UIListLayout"):Destroy()
			Container:FindFirstChild("UIPadding"):Destroy()
			SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,1,0), Parent = ItemParent}), {
				AddThemeObject(SetProps(MakeElement("Image","rbxassetid://3610239960"),{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,15,0,15),ImageTransparency=0.4}),"Text"),
				AddThemeObject(SetProps(MakeElement("Label","Unauthorised Access",14),{Size=UDim2.new(1,-38,0,14),Position=UDim2.new(0,38,0,18),TextTransparency=0.4}),"Text"),
				AddThemeObject(SetProps(MakeElement("Image","rbxassetid://4483345875"),{Size=UDim2.new(0,56,0,56),Position=UDim2.new(0,84,0,110)}),"Text"),
				AddThemeObject(SetProps(MakeElement("Label","Premium Features",14),{Size=UDim2.new(1,-150,0,14),Position=UDim2.new(0,150,0,112),Font=Enum.Font.GothamBold}),"Text"),
				AddThemeObject(SetProps(MakeElement("Label","This part of the script is locked to Sirius Premium users. Purchase Premium in the Discord server (sirius.menu/discord)",12),{Size=UDim2.new(1,-200,0,14),Position=UDim2.new(0,150,0,138),TextWrapped=true,TextTransparency=0.4}),"Text")
			})
		end
		return ElementFunction
	end

	return TabFunction
end

function OrionLib:Destroy()
	-- smooth scale-out before destroy
	for _, win in ipairs(Orion:GetDescendants()) do
		if win:IsA("Frame") and win.Name:find("RoundFrame") then
			local s = win:FindFirstChildWhichIsA("UIScale")
			if s then TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play() end
		end
	end
	task.wait(0.3)
	for _, c in next, OrionLib.Connections do pcall(function() c:Disconnect() end) end
	Orion:Destroy()
end


local function MakeKeyUI(cfg, onSuccess)
	local Title        = cfg.Title        or "Key System"
	local Subtitle     = cfg.Subtitle     or "Key System"
	local Note         = cfg.Note         or "Get your key from Discord."
	local FileName     = cfg.FileName     or "PrizHub_Key"
	local SaveKey      = cfg.SaveKey      ~= false
	local GrabFromSite = cfg.GrabKeyFromSite or false
	local Keys         = cfg.Key          or {}
	if type(Keys) == "string" then Keys = {Keys} end

	local TS2 = game:GetService("TweenService")
	local UIS2 = game:GetService("UserInputService")

	-- load saved
	-- HWID-based key save: file stores "HWID|KEY"
	local function getHWID()
		local hwid = ""
		-- try executor-specific HWID functions first
		if hwid == "" then pcall(function() hwid = tostring(syn.get_hwid and syn.get_hwid() or "") end) end
		if hwid == "" then pcall(function() hwid = tostring(gethwid and gethwid() or "") end) end
		if hwid == "" then pcall(function() hwid = tostring(get_hwid and get_hwid() or "") end) end
		if hwid == "" then pcall(function() hwid = tostring(machine_id and machine_id() or "") end) end
		-- fallback: use UserId (not true HWID but consistent per account)
		if hwid == "" then
			pcall(function() hwid = "UID_"..tostring(game:GetService("Players").LocalPlayer.UserId) end)
		end
		return hwid
	end

	local _hwid = getHWID()
	local savedKey = ""
	local _autoVerified = false
	pcall(function()
		if SaveKey and isfile and isfile(FileName..".txt") then
			local raw = (readfile(FileName..".txt")):match("^%s*(.-)%s*$")
			-- format: "HWID|KEY"
			local storedHWID, storedKey = raw:match("^(.+)|(.+)$")
			if storedHWID and storedKey then
				if storedHWID == _hwid then
					savedKey = storedKey
					_autoVerified = true  -- HWID matches, skip manual entry
				else
					-- different HWID - delete saved key, must re-enter
					pcall(function() writefile(FileName..".txt", "") end)
				end
			end
		end
	end)

	local function getValidKeys()
		local valid = {}
		for _, k in ipairs(Keys) do
			local trimmed = (k):match("^%s*(.-)%s*$")
			if trimmed:sub(1,4) == "http" or GrabFromSite then
				pcall(function()
					local raw = game:HttpGet(trimmed)
					for line in raw:gmatch("[^\r\n]+") do
						local t2 = line:match("^%s*(.-)%s*$")
						if t2 ~= "" then valid[#valid+1] = t2 end
					end
				end)
			else
				if trimmed ~= "" then valid[#valid+1] = trimmed end
			end
		end
		return valid
	end

	-- ScreenGui
	local SG = Instance.new("ScreenGui")
	SG.Name = "PrizKeySystem"
	-- destroy any existing key system
	for _, g in ipairs(game.CoreGui:GetChildren()) do
		if g.Name == "PrizKeySystem" and g ~= SG then g:Destroy() end
	end
	pcall(function()
		for _, g in ipairs(gethui and gethui():GetChildren() or {}) do
			if g.Name == "PrizKeySystem" and g ~= SG then g:Destroy() end
		end
	end)
	SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SG.DisplayOrder = 999
	SG.IgnoreGuiInset = true
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(SG) SG.Parent = game.CoreGui end
	end)
	if not SG.Parent then SG.Parent = (typeof(gethui)=="function" and gethui()) or game.CoreGui end

	-- scrim: fullscreen semi-transparent overlay, fades in smoothly
	local Dim = Instance.new("Frame", SG)
	Dim.Size = UDim2.new(1,0,1,0)
	Dim.BackgroundColor3 = Color3.fromRGB(4,0,12)
	Dim.BackgroundTransparency = 1
	Dim.BorderSizePixel = 0
	Dim.ZIndex = 99
	TS2:Create(Dim, TweenInfo.new(0.4), {BackgroundTransparency = 0.45}):Play()

	-- panel
	local PW, PH = 460, 182
	local Panel = Instance.new("Frame", SG)
	Panel.Size = UDim2.new(0,PW,0,PH)
	Panel.AnchorPoint = Vector2.new(0.5,0.5)
	Panel.BackgroundColor3 = Color3.fromRGB(8,3,18)
	Panel.BackgroundTransparency = 0.35
	Panel.BorderSizePixel = 0
	Panel.ZIndex = 100
	Panel.Position = UDim2.new(0.5,0,0.5,0)
	Panel.BackgroundTransparency = 0
	Instance.new("UICorner",Panel).CornerRadius = UDim.new(0,14)

	local PStroke = Instance.new("UIStroke",Panel)
	PStroke.Color = Color3.fromRGB(100,35,170)
	PStroke.Thickness = 1.5

	-- glow behind


	-- open: slide up from below + fade in (bottom to top)
	local KSScale = Instance.new("UIScale", Panel)
	KSScale.Scale = 1
	Panel.BackgroundTransparency = 1
	Panel.Position = UDim2.new(0.5, 0, 0.58, 0)
	Dim.BackgroundTransparency = 1
	task.defer(function()
		TS2:Create(Dim, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0.45}):Play()
		TS2:Create(Panel, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.35}):Play()
	end)

	-- dragging (same smooth tween approach as main UI)
	local Dragging2, DragInput2, MousePos2, FramePos2 = false, nil, nil, nil
	local DragBar = Instance.new("TextButton", Panel)
	DragBar.Size = UDim2.new(1,-40,0,56)
	DragBar.Position = UDim2.new(0,0,0,0)
	DragBar.BackgroundTransparency = 1
	DragBar.Text = ""
	DragBar.ZIndex = 110
	DragBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			Dragging2 = true
			MousePos2 = inp.Position
			FramePos2 = Panel.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then Dragging2 = false end
			end)
		end
	end)
	DragBar.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then DragInput2 = inp end
	end)
	UIS2.InputChanged:Connect(function(inp)
		if inp == DragInput2 and Dragging2 then
			local Delta = inp.Position - MousePos2
			TS2:Create(Panel, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{Position = UDim2.new(FramePos2.X.Scale, FramePos2.X.Offset + Delta.X, FramePos2.Y.Scale, FramePos2.Y.Offset + Delta.Y)}):Play()
		end
	end)

	-- title
	local TL = Instance.new("TextLabel",Panel)
	TL.Text = Title; TL.Font = Enum.Font.GothamBlack; TL.TextSize = 20
	TL.TextColor3 = Color3.fromRGB(235,210,255); TL.BackgroundTransparency = 1
	TL.Size = UDim2.new(1,-50,0,26); TL.Position = UDim2.new(0,18,0,14)
	TL.TextXAlignment = Enum.TextXAlignment.Left; TL.ZIndex = 101

	-- subtitle: typewriter animation (replaces static subtitle)
	local SL = Instance.new("TextLabel",Panel)
	SL.Text = ""; SL.Font = Enum.Font.GothamSemibold; SL.TextSize = 12
	SL.TextColor3 = Color3.fromRGB(130,80,180); SL.BackgroundTransparency = 1
	SL.Size = UDim2.new(1,-50,0,16); SL.Position = UDim2.new(0,18,0,40)
	SL.TextXAlignment = Enum.TextXAlignment.Left; SL.ZIndex = 101
	task.spawn(function()
		local _phrases = {"Key System", "Join our Discord for a key", "Keys are free to get"}
		local _idx = 1
		while SG and SG.Parent do
			local phrase = _phrases[_idx]
			for i = 1, #phrase do
				if not (SG and SG.Parent) then break end
				SL.Text = phrase:sub(1, i)
				task.wait(0.07)
			end
			task.wait(1.2)
			for i = #phrase, 0, -1 do
				if not (SG and SG.Parent) then break end
				SL.Text = phrase:sub(1, i)
				task.wait(0.04)
			end
			task.wait(0.3)
			_idx = (_idx % #_phrases) + 1
		end
	end)

	-- divider
	local Div = Instance.new("Frame",Panel)
	Div.Size = UDim2.new(1,-36,0,1); Div.Position = UDim2.new(0,18,0,62)
	Div.BackgroundColor3 = Color3.fromRGB(80,25,140); Div.BorderSizePixel = 0; Div.ZIndex = 101
	Instance.new("UICorner",Div).CornerRadius = UDim.new(1,0)



	-- close button (same style as main UI)
	local XB = Instance.new("TextButton",Panel)
	XB.Text = ""; XB.BackgroundTransparency = 1
	XB.Size = UDim2.new(0,30,0,30)
	XB.Position = UDim2.new(1,-36,0,8); XB.ZIndex = 112
	local XBIco = Instance.new("ImageLabel", XB)
	XBIco.Image = "rbxassetid://7072725342"
	XBIco.BackgroundTransparency = 1
	XBIco.Size = UDim2.new(0,16,0,16)
	XBIco.Position = UDim2.new(0,7,0,7)
	XBIco.ImageColor3 = Color3.fromRGB(140,90,190)
	XBIco.ZIndex = 113
	XB.MouseEnter:Connect(function()
		XBIco.ImageColor3 = Color3.fromRGB(210,150,255)
	end)
	XB.MouseLeave:Connect(function()
		XBIco.ImageColor3 = Color3.fromRGB(140,90,190)
	end)
	XB.MouseButton1Click:Connect(function()
		local t = TS2:Create(Panel, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0.62, 0), BackgroundTransparency = 1})
		TS2:Create(Dim, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}):Play()
		t.Completed:Connect(function()
			Panel.Visible = false
			SG:Destroy()
		end)
		t:Play()
	end)

	-- input bg
	local IBG = Instance.new("Frame",Panel)
	IBG.Size = UDim2.new(0,240,0,40); IBG.Position = UDim2.new(0,18,0,92)
	IBG.BackgroundColor3 = Color3.fromRGB(16,5,32); IBG.BorderSizePixel = 0; IBG.ZIndex = 101
	Instance.new("UICorner",IBG).CornerRadius = UDim.new(0,8)
	local IS = Instance.new("UIStroke",IBG)
	IS.Color = Color3.fromRGB(60,20,105); IS.Thickness = 1
	IBG.ClipsDescendants = true

	-- floating squares animation inside input box
	task.spawn(function()
		local TS3 = game:GetService("TweenService")
		local squareSizes = {4, 6, 5, 7, 4, 6}
		local function spawnSquare()
			if not (Panel and Panel.Parent) then return end
			local sz = squareSizes[math.random(1, #squareSizes)]
			local sq = Instance.new("Frame", IBG)
			sq.Size = UDim2.new(0, sz, 0, sz)
			sq.Position = UDim2.new(math.random(5, 85)/100, 0, 1, 0)
			sq.BackgroundColor3 = Color3.fromRGB(
				math.random(100, 160),
				math.random(40, 80),
				math.random(200, 255)
			)
			sq.BackgroundTransparency = 0.3
			sq.BorderSizePixel = 0
			sq.ZIndex = 99
			Instance.new("UICorner", sq).CornerRadius = UDim.new(0, 1)
			-- slide up only within the box height (40px), fade out near top
			local rise = math.random(20, 36)
			TS3:Create(sq, TweenInfo.new(
				math.random(12, 20) / 10,
				Enum.EasingStyle.Sine, Enum.EasingDirection.Out
			), {
				Position = UDim2.new(sq.Position.X.Scale, 0, 0, -rise + 40),
				BackgroundTransparency = 1
			}):Play()
			game:GetService("Debris"):AddItem(sq, 2.5)
		end
		while Panel and Panel.Parent do
			spawnSquare()
			task.wait(math.random(3, 7) / 10)
		end
	end)

	-- textbox
	local TB = Instance.new("TextBox",IBG)
	TB.Size = UDim2.new(1,-34,1,0); TB.Position = UDim2.new(0,8,0,0)
	TB.BackgroundTransparency = 1; TB.Text = ""
	TB.PlaceholderText = "Enter your key..."; TB.PlaceholderColor3 = Color3.fromRGB(75,45,105)
	TB.TextColor3 = Color3.fromRGB(210,175,255); TB.Font = Enum.Font.GothamSemibold
	TB.TextSize = 13; TB.TextXAlignment = Enum.TextXAlignment.Left
	TB.ClearTextOnFocus = false; TB.ZIndex = 103
	TB:GetPropertyChangedSignal("Text"):Connect(function()
		TS2:Create(IS,TweenInfo.new(0.15),{Color=Color3.fromRGB(110,40,185)}):Play()
	end)
	TB.FocusLost:Connect(function()
		TS2:Create(IS,TweenInfo.new(0.25),{Color=Color3.fromRGB(60,20,105)}):Play()
	end)

	-- discord icon - right side of input box
	local PB = Instance.new("TextButton", IBG)
	PB.Text = ""; PB.BackgroundTransparency = 1
	PB.Size = UDim2.new(0, 28, 1, 0); PB.Position = UDim2.new(1, -30, 0, 0); PB.ZIndex = 104
	local PBImg = Instance.new("TextLabel", PB)
	PBImg.Text = "two-stacked-squares"
	SetFontFace(PBImg, BICONS_PATH)
	PBImg.TextSize = 14
	PBImg.TextWrapped = true
	PBImg.TextColor3 = Color3.fromRGB(120, 65, 185)
	PBImg.BackgroundTransparency = 1
	PBImg.Size = UDim2.new(1, 0, 1, 0)
	PBImg.TextXAlignment = Enum.TextXAlignment.Center
	PBImg.TextYAlignment = Enum.TextYAlignment.Center
	PBImg.ZIndex = 105
	PB.MouseEnter:Connect(function() PBImg.TextColor3 = Color3.fromRGB(185,125,255) end)
	PB.MouseLeave:Connect(function() PBImg.TextColor3 = Color3.fromRGB(120,65,185) end)
	PB.MouseButton1Click:Connect(function()
		local link = "https://discord.gg/yourlink"
		pcall(setclipboard, link)
		TB.Text = link
		PBImg.TextColor3 = Color3.fromRGB(100, 220, 130)
		task.delay(1.5, function()
			if PBImg and PBImg.Parent then PBImg.TextColor3 = Color3.fromRGB(120, 65, 185) end
		end)
	end)

	-- verify: plain text button, no background
	local VB = Instance.new("TextButton",Panel)
	VB.Text = "Verify"
	VB.Font = Enum.Font.GothamBold
	VB.TextSize = 14
	VB.TextColor3 = Color3.fromRGB(190,140,255)
	VB.BackgroundTransparency = 1
	VB.BorderSizePixel = 0
	VB.AutoButtonColor = false
	VB.Size = UDim2.new(0,70,0,40)
	VB.Position = UDim2.new(1,-136,0,92)
	VB.ZIndex = 101

	-- tooltip: "Copy Discord Invite"
	local VBTip = Instance.new("TextButton", Panel)
	VBTip.Text = "Copy Discord\nInvite"
	VBTip.Font = Enum.Font.GothamSemibold
	VBTip.TextSize = 11
	VBTip.TextColor3 = Color3.fromRGB(200,160,255)
	VBTip.BackgroundColor3 = Color3.fromRGB(18,6,36)
	VBTip.BackgroundTransparency = 1
	VBTip.BorderSizePixel = 0
	VBTip.AutoButtonColor = false
	VBTip.Size = UDim2.new(0,90,0,36)
	VBTip.Position = UDim2.new(1,-146,0,140)
	VBTip.ZIndex = 200
	VBTip.Visible = false


	VB.MouseEnter:Connect(function()
		TS2:Create(VB, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(235,200,255)}):Play()
		-- slide up from below + fade in
		VBTip.Text = "Copy Discord\nInvite"
		VBTip.TextColor3 = Color3.fromRGB(200,160,255)
		VBTip.TextTransparency = 1
		VBTip.Position = UDim2.new(1,-146,0,140)
		VBTip.Visible = true
		TS2:Create(VBTip, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = UDim2.new(1,-146,0,128), TextTransparency = 0}):Play()
	end)
	local function hideTip()
		TS2:Create(VBTip, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{Position = UDim2.new(1,-146,0,140), TextTransparency = 1}):Play()
		task.delay(0.27, function()
			if VBTip and VBTip.Parent then
				VBTip.Visible = false
				VBTip.Text = "Copy Discord\nInvite"
				VBTip.TextColor3 = Color3.fromRGB(200,160,255)
			end
		end)
	end

	-- use RenderStepped to check if mouse is over VB or VBTip - most reliable
	local _tipShowing = false
	game:GetService("RunService").RenderStepped:Connect(function()
		if not (Panel and Panel.Parent) then return end
		local mp = game:GetService("UserInputService"):GetMouseLocation()
		-- check VB bounds
		local vbp = VB.AbsolutePosition; local vbs = VB.AbsoluteSize
		local overVB = mp.X>=vbp.X and mp.X<=vbp.X+vbs.X and mp.Y>=vbp.Y and mp.Y<=vbp.Y+vbs.Y
		-- check VBTip bounds
		local ttp = VBTip.AbsolutePosition; local tts = VBTip.AbsoluteSize
		local overTip = mp.X>=ttp.X and mp.X<=ttp.X+tts.X and mp.Y>=ttp.Y and mp.Y<=ttp.Y+tts.Y
		if overVB and not _tipShowing then
			_tipShowing = true
			TS2:Create(VB, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(235,200,255)}):Play()
			VBTip.Text = "Copy Discord\nInvite"
			VBTip.TextColor3 = Color3.fromRGB(200,160,255)
			VBTip.TextTransparency = 1
			VBTip.Position = UDim2.new(1,-146,0,140)
			VBTip.Visible = true
			TS2:Create(VBTip, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{Position = UDim2.new(1,-146,0,128), TextTransparency = 0}):Play()
		elseif not overVB and not overTip and _tipShowing then
			_tipShowing = false
			TS2:Create(VB, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(190,140,255)}):Play()
			hideTip()
		end
	end)
	-- clicking tooltip area: use VB click for discord copy
	-- VBTip is clickable for discord copy

	-- status label
	local StL = Instance.new("TextLabel",Panel)
	StL.Text = ""; StL.Font = Enum.Font.GothamSemibold; StL.TextSize = 11
	StL.TextColor3 = Color3.fromRGB(150,100,210); StL.BackgroundTransparency = 1
	StL.Size = UDim2.new(1,-36,0,14); StL.Position = UDim2.new(0,18,0,144)
	StL.TextXAlignment = Enum.TextXAlignment.Left; StL.ZIndex = 101

	-- version
	local VL = Instance.new("TextLabel",Panel)
	VL.Text = "v1.0"; VL.Font = Enum.Font.Gotham; VL.TextSize = 10
	VL.TextColor3 = Color3.fromRGB(65,40,95); VL.BackgroundTransparency = 1
	VL.Size = UDim2.new(0,40,0,14); VL.Position = UDim2.new(1,-48,1,-18); VL.ZIndex = 101

	local function closeAndLoad()
		local t = TS2:Create(Panel, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0.62, 0), BackgroundTransparency = 1})
		TS2:Create(Dim, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}):Play()
		t.Completed:Connect(function()
			Panel.Visible = false
			SG:Destroy()
			task.defer(onSuccess)
		end)
		t:Play()
	end

	local function doVerify()
		local entered = TB.Text:match("^%s*(.-)%s*$")
		if entered == "" then
			StL.TextTransparency = 1
			StL.Text = "Please enter a key."
			StL.TextColor3 = Color3.fromRGB(255,155,55)
			TS2:Create(StL, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
			return
		end
		StL.TextTransparency = 1
		StL.Text = "Verifying..."
		StL.TextColor3 = Color3.fromRGB(160,110,220)
		TS2:Create(StL, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		task.spawn(function()
			local valid = getValidKeys()
			local ok = false
			for _, k in ipairs(valid) do if k == entered then ok = true break end end
			if ok then
				StL.Text = "✓  Key accepted! Loading..."
				StL.TextColor3 = Color3.fromRGB(90,215,120)
				TS2:Create(IS,TweenInfo.new(0.2),{Color=Color3.fromRGB(55,175,95)}):Play()
				TS2:Create(IBG,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(8,28,14)}):Play()
				if SaveKey then pcall(function() writefile(FileName..".txt", entered) end) end
				task.wait(1.2)
				closeAndLoad()
			else
				StL.Text = "✗  Invalid key. Try again."
				StL.TextColor3 = Color3.fromRGB(255,70,70)
				-- shake using UIScale
				for i = 1, 4 do
					TS2:Create(KSScale, TweenInfo.new(0.05), {Scale = i%2==0 and 1.04 or 0.97}):Play()
					task.wait(0.06)
				end
				TS2:Create(KSScale, TweenInfo.new(0.1), {Scale = 1}):Play()
				TS2:Create(IBG,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(50,6,16)}):Play()
				task.wait(0.35)
				TS2:Create(IBG,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(16,5,32)}):Play()
				TS2:Create(IS,TweenInfo.new(0.2),{Color=Color3.fromRGB(60,20,105)}):Play()
			end
		end)
	end

	VB.MouseButton1Click:Connect(doVerify)
	TB.FocusLost:Connect(function(enter) if enter then doVerify() end end)

	-- tooltip click = copy discord invite
	VBTip.MouseButton1Click:Connect(function()
		pcall(setclipboard, "https://discord.gg/yourlink")
		VBTip.Text = "Discord Invite\nCopied"
		VBTip.TextColor3 = Color3.fromRGB(100,220,130)
		task.delay(1.5, function()
			if VBTip and VBTip.Parent then
				VBTip.Text = "Copy Discord\nInvite"
				VBTip.TextColor3 = Color3.fromRGB(200,160,255)
			end
		end)
	end)

	-- HWID auto-verify: skip UI, load directly
	if _autoVerified and savedKey ~= "" then
		pcall(function() SG:Destroy() end)
		task.defer(onSuccess)
		return
	end
end

OrionLib.MakeKeyUI = MakeKeyUI

return OrionLib
