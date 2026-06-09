 
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
 
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
		Object[i] = v
	end
	for i, v in next, Children or {} do
		v.Parent = Object
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
	return Create("Frame", {BackgroundTransparency = 0.18})
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
 
		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 10), {
			Parent              = NotificationParent,
			Size                = UDim2.new(1, 0, 0, 0),
			Position            = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize       = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
			MakeElement("Padding", 12, 12, 12, 12),
			SetProps(MakeElement("Image", NotificationConfig.Image), {
				Size       = UDim2.new(0, 20, 0, 20),
				ImageColor3 = Color3.fromRGB(240, 240, 240),
				Name       = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
				Size     = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font     = Enum.Font.GothamBold,
				Name     = "Title"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size          = UDim2.new(1, 0, 0, 0),
				Position      = UDim2.new(0, 0, 0, 25),
				Font          = Enum.Font.GothamSemibold,
				Name          = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3    = Color3.fromRGB(200, 200, 200),
				TextWrapped   = true
			})
		})
 
		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		wait(NotificationConfig.Time - 0.88)
		TweenService:Create(NotificationFrame.Icon,    TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		TweenService:Create(NotificationFrame,         TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
		wait(0.3)
		TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
		TweenService:Create(NotificationFrame.Title,   TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
		wait(0.05)
		NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0), 'In', 'Quint', 0.8, true)
		wait(1.35)
		NotificationFrame:Destroy()
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
	WindowConfig.Name         = WindowConfig.Name         or "Priz Hub"
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
	OrionLib.SaveCfg = WindowConfig.SaveConfig
 
	if WindowConfig.SaveConfig then
		pcall(function()
			if not isfolder(WindowConfig.ConfigFolder) then
				makefolder(WindowConfig.ConfigFolder)
			end
		end)
	end
 
	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 4), {
		Size = UDim2.new(1, 0, 1, -50)
	}), {
		MakeElement("List"),
		MakeElement("Padding", 8, 0, 0, 8)
	}), "Divider")
 
	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
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
 
	-- Settings button - clean gear icon using Roblox image
	local SettingsBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size                   = UDim2.new(0, 35, 1, 0),
		Position               = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706816"), {
			Size           = UDim2.new(0, 16, 0, 16),
			Position       = UDim2.new(0.5, -8, 0.5, -8),
			Name           = "Ico"
		}), "Text")
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
		TextSize         = 10,
		TextColor3       = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
		BackgroundTransparency = 1,
		Size             = UDim2.new(1, -60, 0, 11),
		Position         = UDim2.new(0, 50, 1, -25),
		TextXAlignment   = Enum.TextXAlignment.Left
	})
 
	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Size                  = UDim2.new(0, 150, 1, -50),
		Position              = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 0.55
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
		TabHolder,
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size     = UDim2.new(1, 0, 0, 50),
			Position = UDim2.new(0, 0, 1, -50)
		}), {
			AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(1, 0, 0, 1)
			}), "Stroke"),
			AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size        = UDim2.new(0, 32, 0, 32),
				Position    = UDim2.new(0, 10, 0.5, 0)
			}), {
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
				Position    = UDim2.new(0, 10, 0.5, 0)
			}), {
				Create("UIStroke", {
					Color     = Color3.fromRGB(0, 220, 255),
					Thickness = 1.8,
					Name      = "GlowStroke"
				}),
				MakeElement("Corner", 1)
			}),
			AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, 13), {
				Size             = UDim2.new(1, -60, 0, 14),
				Position         = UDim2.new(0, 50, 0, 9),
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
 
	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Parent                = Orion,
		Position              = UDim2.new(0.5, -307, 0.5, -172),
		Size                  = UDim2.new(0, 615, 0, 344),
		ClipsDescendants      = false,
		BackgroundTransparency = 1
	}), {
		-- TopBar contains DragPoint so it can never overlap the content area
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar"
		}), {
			WindowName,
			TopbarStats,
			PillBadge,
			WindowTopBarLine,
			DragPoint,   -- - inside TopBar, not at window level
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
				Size     = UDim2.new(0, 105, 0, 30),
				Position = UDim2.new(1, -120, 0, 10)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				-- divider between settings and minimize
				AddThemeObject(SetProps(MakeElement("Frame"), {
					Size     = UDim2.new(0, 1, 1, 0),
					Position = UDim2.new(0, 35, 0, 0)
				}), "Stroke"),
				-- divider between minimize and close
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
 
	if WindowConfig.ShowIcon then
		WindowName.Position = UDim2.new(0, 50, 0, -24)
		local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
			Size     = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 25, 0, 15)
		})
		WindowIcon.Parent = MainWindow.TopBar
	end
 
	-- Black outline on main window edges
	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color     = Color3.fromRGB(0, 0, 0)
	MainStroke.Thickness = 5
	MainStroke.Parent    = MainWindow
 
	AddDraggingFunctionality(DragPoint, MainWindow)
 
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
		Size     = UDim2.new(0, 200, 0, 8),
		Position = UDim2.new(1, -210, 0, 52),
		ZIndex   = 50,
		Visible  = false,
		Parent   = MainWindow
	}), {
		AddThemeObject(MakeElement("Stroke"), "Stroke"),
		MakeElement("Padding", 6, 6, 6, 6),
		MakeElement("List", 0, 2)
	})
 
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
 
	MakeSettingBtn("  Save Config",    function() SPSave(cfgName) end)
	MakeSettingBtn("  Load Config",    function() SPLoad(cfgName) end)
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
		-- recompute size each open in case of layout changes
		local ll = SettingsPanel:FindFirstChild("UIListLayout")
		if ll then
			SettingsPanel.Size = UDim2.new(0, 200, 0, ll.AbsoluteContentSize.Y + 12)
		end
		SettingsPanel.Visible = true
		TweenService:Create(SettingsBtn.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Rotation = 90}):Play()
	end
 
	local function closeSettingsPanel()
		SettingsPanelOpen = false
		SettingsPanel.Visible = false
		TweenService:Create(SettingsBtn.Ico, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
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
	-- Drag the bottom-right corner to resize
	local ResizeHandle = Create("TextButton", {
		Text                = "",
		BackgroundTransparency = 1,
		Size                = UDim2.new(0, 16, 0, 16),
		Position            = UDim2.new(1, -16, 1, -16),
		ZIndex              = 10,
		AutoButtonColor     = false,
		Parent              = MainWindow
	})
	-- small visual grip dots
	local GripDots = Create("Frame", {
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		Parent                 = ResizeHandle
	})
	for r = 0, 1 do
		for c = 0, 1 do
			Create("Frame", {
				BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
				Size             = UDim2.new(0, 3, 0, 3),
				Position         = UDim2.new(0, 2 + c * 6, 0, 2 + r * 6),
				BorderSizePixel  = 0,
				Parent           = GripDots
			})
		end
	end
 
	local resizing = false
	local resizeStart, resizeStartSize
	local minW, minH = 400, 250
 
	AddConnection(ResizeHandle.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing       = true
			resizeStart    = Vector2.new(Input.Position.X, Input.Position.Y)
			resizeStartSize = Vector2.new(MainWindow.AbsoluteSize.X, MainWindow.AbsoluteSize.Y)
		end
	end)
	AddConnection(UserInputService.InputEnded, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)
	AddConnection(UserInputService.InputChanged, function(Input)
		if resizing and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Vector2.new(Input.Position.X, Input.Position.Y) - resizeStart
			local newW  = math.max(minW, resizeStartSize.X + delta.X)
			local newH  = math.max(minH, resizeStartSize.Y + delta.Y)
			MainWindow.Size = UDim2.new(0, newW, 0, newH)
			-- keep sidebar and content fitting the new size
			WindowStuff.Size = UDim2.new(0, 150, 1, -50)
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
			MainWindow.Visible = false
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
		MainWindow.Visible = true
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
			wait(0.02)
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
		else
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)}):Play()
			wait(0.1)
			WindowStuff.Visible = false
		end
		Minimized = not Minimized
	end)
 
	local TabFunction = {}
	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name       = TabConfig.Name       or "Tab"
		TabConfig.Icon       = TabConfig.Icon       or ""
		TabConfig.PremiumOnly = TabConfig.PremiumOnly or false
 
		-- Icon: single ASCII char displayed as styled text label (purple tint)
		local iconChar = (TabConfig.Icon ~= "" and TabConfig.Icon) or "-"
		local TabIconLbl = Create("TextLabel", {
			Text             = iconChar,
			Font             = Enum.Font.GothamBold,
			TextSize         = 15,
			TextColor3       = Color3.fromRGB(160, 80, 255),
			TextTransparency = 0.2,
			BackgroundTransparency = 1,
			AnchorPoint      = Vector2.new(0, 0.5),
			Size             = UDim2.new(0, 22, 0, 22),
			Position         = UDim2.new(0, 8, 0.5, 0),
			TextXAlignment   = Enum.TextXAlignment.Center,
			Name             = "Ico"
		})
 
		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size   = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder
		}), {
			TabIconLbl,
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size             = UDim2.new(1, -36, 1, 0),
				Position         = UDim2.new(0, 34, 0, 0),
				Font             = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				Name             = "Title"
			}), "Text")
		})
 
		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
			Size             = UDim2.new(1, -150, 1, -50),
			Position         = UDim2.new(0, 150, 0, 50),
			Parent           = MainWindow,
			Visible          = false,
			Name             = "ItemContainer",
			ScrollingEnabled = true,
			ScrollingDirection = Enum.ScrollingDirection.Y
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")
 
		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
		end)
		-- force initial canvas size
		task.defer(function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
		end)
 
		if FirstTab then
			FirstTab = false
			TabIconLbl.TextTransparency = 0
			if _TabTitle then
				_TabTitle.TextTransparency = 0
				_TabTitle.Font = Enum.Font.GothamBlack
			end
			Container.Visible = true
		end
 
		-- Tab hover: smooth subtle grow
		local _TabTitle = TabFrame:FindFirstChild("Title")
		local _TabIco   = TabFrame:FindFirstChild("Ico")
		local smoothInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		AddConnection(TabFrame.MouseEnter, function()
			if not Container.Visible then
				if _TabTitle then TweenService:Create(_TabTitle, smoothInfo, {TextSize = 14.5, TextTransparency = 0.15}):Play() end
				if _TabIco   then TweenService:Create(_TabIco,   smoothInfo, {TextSize = 15.5, TextTransparency = 0.1}):Play() end
			end
		end)
		AddConnection(TabFrame.MouseLeave, function()
			if not Container.Visible then
				if _TabTitle then TweenService:Create(_TabTitle, smoothInfo, {TextSize = 14, TextTransparency = 0.4}):Play() end
				if _TabIco   then TweenService:Create(_TabIco,   smoothInfo, {TextSize = 15, TextTransparency = 0.2}):Play() end
			end
		end)
 
		AddConnection(TabFrame.MouseButton1Click, function()
			-- deactivate all other tabs
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
			-- activate this tab label
			if _TabTitle then
				TweenService:Create(_TabTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, TextSize = 14}):Play()
				_TabTitle.Font = Enum.Font.GothamBlack
			end
			if _TabIco then
				TweenService:Create(_TabIco, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, TextSize = 16, TextColor3 = Color3.fromRGB(190, 100, 255)}):Play()
			end
			-- show container and animate elements in with stagger
			Container.Visible = true
			task.defer(function()
				Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
				-- stagger each child element: slide in from left + fade in
				local children = {}
				for _, child in ipairs(Container:GetChildren()) do
					if child:IsA("Frame") or child:IsA("TextButton") then
						table.insert(children, child)
					end
				end
				for i, child in ipairs(children) do
					child.Position = UDim2.new(-0.08, 0, child.Position.Y.Scale, child.Position.Y.Offset)
					if child:IsA("Frame") then
						child.BackgroundTransparency = 1
					end
					task.delay((i - 1) * 0.03, function()
						if child and child.Parent then
							TweenService:Create(child, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
								Position = UDim2.new(0, 0, child.Position.Y.Scale, child.Position.Y.Offset)
							}):Play()
 
						end
					end)
				end
			end)
		end)
 
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
				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
					ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size         = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
				end)
				ParagraphFrame.Content.Text = Content
				local ParagraphFunction = {}
				function ParagraphFunction:Set(ToChange) ParagraphFrame.Content.Text = ToChange end
				return ParagraphFunction
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
				return Button
			end
 
			function ElementFunction:AddToggle(ToggleConfig)
				ToggleConfig          = ToggleConfig or {}
				ToggleConfig.Name     = ToggleConfig.Name     or "Toggle"
				ToggleConfig.Default  = ToggleConfig.Default  or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end
				ToggleConfig.Color    = ToggleConfig.Color    or Color3.fromRGB(9, 99, 195)
				ToggleConfig.Flag     = ToggleConfig.Flag     or nil
				ToggleConfig.Save     = ToggleConfig.Save     or false
				local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save, Type = "Toggle"}
				local Click  = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
				local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 4), {
					Size        = UDim2.new(0, 24, 0, 24),
					Position    = UDim2.new(1, -24, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5)
				}), {
					SetProps(MakeElement("Stroke"), {Color = ToggleConfig.Color, Name = "Stroke", Transparency = 0.5}),
					SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
						Size        = UDim2.new(0, 20, 0, 20),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position    = UDim2.new(0.5, 0, 0.5, 0),
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Name        = "Ico"
					})
				})
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
					ToggleBox,
					Click
				}), "Second")
				function Toggle:Set(Value)
					Toggle.Value = Value
					TweenService:Create(ToggleBox,        TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Divider}):Play()
					TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Color = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Stroke}):Play()
					TweenService:Create(ToggleBox.Ico,    TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = Toggle.Value and 0 or 1, Size = Toggle.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)}):Play()
					ToggleConfig.Callback(Toggle.Value)
				end
				Toggle:Set(Toggle.Value)
				local tgSmooth = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local TS2 = OrionLib.Themes[OrionLib.SelectedTheme].Second
				AddConnection(Click.MouseEnter,      function() TweenService:Create(ToggleFrame, tgSmooth, {BackgroundColor3 = Color3.fromRGB(TS2.R*255+4, TS2.G*255+4, TS2.B*255+4)}):Play() end)
				AddConnection(Click.MouseLeave,      function() TweenService:Create(ToggleFrame, tgSmooth, {BackgroundColor3 = TS2}):Play() end)
				AddConnection(Click.MouseButton1Up,  function() TweenService:Create(ToggleFrame, tgSmooth, {BackgroundColor3 = Color3.fromRGB(TS2.R*255+4, TS2.G*255+4, TS2.B*255+4)}):Play() SaveCfg(game.GameId) Toggle:Set(not Toggle.Value) end)
				AddConnection(Click.MouseButton1Down, function() TweenService:Create(ToggleFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(TS2.R*255+8, TS2.G*255+8, TS2.B*255+8)}):Play() end)
				if ToggleConfig.Flag then OrionLib.Flags[ToggleConfig.Flag] = Toggle end
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
				local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(40, 40, 40), 4), {DropdownList}), {
					Parent           = ItemParent,
					Position         = UDim2.new(0, 0, 0, 38),
					Size             = UDim2.new(1, 0, 1, -38),
					ClipsDescendants = true
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
						AddConnection(OptionBtn.MouseButton1Click, function() Dropdown:Set(Option) SaveCfg(game.GameId) end)
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
					TweenService:Create(DropdownFrame.F.Ico,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Rotation=Dropdown.Toggled and 180 or 0}):Play()
					if #Dropdown.Options > MaxElements then
						TweenService:Create(DropdownFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Dropdown.Toggled and UDim2.new(1,0,0,38+(MaxElements*28)) or UDim2.new(1,0,0,38)}):Play()
					else
						TweenService:Create(DropdownFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Dropdown.Toggled and UDim2.new(1,0,0,DropdownList.AbsoluteContentSize.Y+38) or UDim2.new(1,0,0,38)}):Play()
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
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, Name = "Value"}), "Text")
				}), "Main")
				local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size   = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 15), {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamBold, Name = "Content"}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					BindBox, Click
				}), "Second")
				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function() TweenService:Create(BindBox,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,BindBox.Value.TextBounds.X+16,0,24)}):Play() end)
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
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextboxActual
				}), "Main")
				local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size   = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 15), {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamBold, Name = "Content"}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextContainer, Click
				}), "Second")
				AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function() TweenService:Create(TextContainer,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,TextboxActual.TextBounds.X+16,0,24)}):Play() end)
				AddConnection(TextboxActual.FocusLost, function() TextboxConfig.Callback(TextboxActual.Text) if TextboxConfig.TextDisappear then TextboxActual.Text="" end end)
				TextboxActual.Text = TextboxConfig.Default
				AddConnection(Click.MouseEnter,      function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play() end)
				AddConnection(Click.MouseLeave,      function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play() end)
				AddConnection(Click.MouseButton1Up,  function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play() TextboxActual:CaptureFocus() end)
				AddConnection(Click.MouseButton1Down, function() TweenService:Create(TextboxFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+6,OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+6,OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+6)}):Play() end)
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
					TweenService:Create(ColorpickerFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Colorpicker.Toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
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
 
		function ElementFunction:AddSection(SectionConfig)
			SectionConfig = SectionConfig or {}
			SectionConfig.Name = SectionConfig.Name or "Section"
			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size   = UDim2.new(1, 0, 0, 30),
				Parent = Container
			}), {
				AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 15), {
					Size     = UDim2.new(1, -12, 0, 20),
					Position = UDim2.new(0, 0, 0, 4),
					Font     = Enum.Font.GothamBlack
				}), "Text"),
				SetChildren(SetProps(MakeElement("TFrame"), {
					AnchorPoint = Vector2.new(0, 0),
					Size        = UDim2.new(1, 0, 1, -24),
					Position    = UDim2.new(0, 0, 0, 23),
					Name        = "Holder"
				}), {
					MakeElement("List", 0, 6)
				})
			})
			AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size        = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)
			local SectionFunction = {}
			for i, v in next, GetElements(SectionFrame.Holder) do
				SectionFunction[i] = v
			end
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
