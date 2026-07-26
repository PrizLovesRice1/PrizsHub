# DuvomeLib

DuvomeLib is a UI library for Roblox scripts. It has a dark purple look with a lot of glow and smooth animations. You can use it to build menus with buttons, toggles, sliders, dropdowns, and more. It also saves user settings and lets people pick their own colors.

---

## Quick Start

Here is the smallest example that works:

```lua
local Duvome = loadstring(game:HttpGet("https://raw.githubusercontent.com/PrizLovesRice1/PrizsHub/refs/heads/main/DuvomeLib.lua"))()

local Window = Duvome:MakeWindow({
    Name         = "My Hub",
    SaveConfig   = true,
    ConfigFolder = "MyHubConfigs",
    Theme        = "Default",
})

local Tab = Window:MakeTab({Name = "Main", Icon = "house", Columns = true})
local Left, Right = Tab:AddLeft(), Tab:AddRight()
local Section = Left:AddSection({Name = "Features"})

Section:AddButton({
    Name = "Click Me",
    Callback = function() print("clicked") end
})

Duvome:Init()   -- always call this at the very end
```

The order goes like this: Window, then Tab, then Column (Left, Right, or Auto), then Section, then your buttons and toggles.

---

## Window

This is where you set up the main menu.

```lua
local Window = Duvome:MakeWindow({
    Name           = "My Hub",
    Icon           = "rbxassetid://...",
    ShowIcon       = true,
    IconFont       = "rbxasset://...",
    SaveConfig     = true,
    ConfigFolder   = "MyHubConfigs",
    AutoLoadConfig = false,
    Theme          = "Default",
    HidePremium    = true,
    IntroEnabled   = false,
    IntroText      = "My Hub",
    IntroIcon      = "rbxassetid://...",
    Blur           = false,
    BlurSize       = 8,
    CloseCallback  = function() end,
})
```

Press **RightShift** to hide or show the menu. Users can change this key later in the settings.

---

## Tabs

```lua
local Tab = Window:MakeTab({
    Name        = "Main",
    Icon        = "house",
    Columns     = true,
    PremiumOnly = false,
})

local Left  = Tab:AddLeft()
local Right = Tab:AddRight()
local Auto  = Tab:AddAuto()   -- picks left or right for you
```

## Sections

```lua
local Section = Left:AddSection({
    Name        = "Combat",
    Collapsible = true,   -- click the title to fold it away
})
```

---

## Buttons, Toggles, and Sliders

Everything below goes inside a Section.

### Button

```lua
Section:AddButton({
    Name        = "Do Thing",
    Icon        = "rbxassetid://...",
    Tooltip     = "Shows up when you hover",
    ShowKeybind = true,
    Callback    = function() end,
    Options     = { ... },   -- see Gear Popovers below
})
```

### Toggle

```lua
Section:AddToggle({
    Name        = "ESP",
    Default     = false,
    Color       = Color3.fromRGB(255,120,0),
    Flag        = "esp_enabled",
    Save        = true,
    Tooltip     = "Draws boxes around players",
    ShowKeybind = true,
    Callback    = function(value) end,
    Options     = { ... },
})
```

You get back an object. You can call `:Set(true)` or `:SetVisible(false)` on it later.

### Slider

```lua
Section:AddSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 300,
    Default   = 16,
    Increment = 1,
    ValueName = "spd",
    Flag      = "walkspeed",
    Save      = true,
    Color     = Color3.fromRGB(80,220,120),
    Callback  = function(value) end,
})
```

You can drag the slider, or click the number box on the right and just type a value.

### Range Slider

This one has two handles so users can pick a low and high number.

```lua
Section:AddRangeSlider({
    Name       = "Price Range",
    Min        = 0,
    Max        = 1000,
    DefaultMin = 100,
    DefaultMax = 750,
    Increment  = 25,
    ValueName  = "$",
    Flag       = "price_range",
    Color      = Color3.fromRGB(80,220,120),
    Callback   = function(min, max) end,
})
```

### Dropdown

```lua
Section:AddDropdown({
    Name        = "Select Item",
    Options     = {"Apple", "Banana", "Cherry"},
    Default     = "Apple",
    MultiSelect = false,
    Search      = true,
    SelectAll   = true,
    Flag        = "item_choice",
    Save        = true,
    Callback    = function(value) end,
})
```

If `MultiSelect` is on, the callback gives you a table instead of one value. `Search` adds a small search bar. `SelectAll` adds two buttons for picking or clearing everything at once.

### Textbox

```lua
Section:AddTextbox({
    Name           = "Your Name",
    Default        = "",
    TextDisappear  = false,
    Callback       = function(text) end,
})
```

### Keybind

```lua
Section:AddBind({
    Name     = "Toggle Fly",
    Default  = Enum.KeyCode.F,
    Mode     = "toggle",
    Interval = 0.5,
    Modifier = Enum.KeyCode.LeftControl,
    Flag     = "fly_key",
    Save     = true,
    Callback = function(state) end,
})
```

Three modes to pick from:
- **press** fires one time when you hit the key
- **toggle** flips something on and off
- **hold** keeps firing over and over while you hold it down

Hit Backspace while picking a new key to clear it. If someone tries to use a key that is already taken, they get a warning instead.

### Colorpicker

```lua
Section:AddColorpicker({
    Name         = "Box Color",
    Default      = Color3.fromRGB(255, 0, 80),
    UseAlpha     = true,
    DefaultAlpha = 0,
    Flag         = "box_color",
    Callback     = function(color, alpha) end,
})
```

Click the little color box to open the full picker.

### Search

A standalone search bar that filters a list you give it.

```lua
Section:AddSearch({
    Name        = "Find Item",
    Items       = {"Apple", "Banana", "Cherry"},
    Placeholder = "Type to search...",
    Callback    = function(item) end,
})
```

### Labels, Paragraphs, and Dividers

```lua
Section:AddLabel("A plain line of text")

Section:AddParagraph("Title", "Longer text that wraps onto more than one line.")

Section:AddDivider()   -- just a line to split things up
```

---

## Gear Popovers

You can add a small gear icon to a toggle or button that opens extra settings when clicked.

```lua
Section:AddToggle({
    Name = "ESP",
    Callback = function(v) end,
    Options = {
        {Type = "colorpicker", Name = "Box Color", Default = Color3.fromRGB(255,0,80), UseAlpha = true,
            Callback = function(c, a) end,
            OnSelect = function(c, a) end},

        {Type = "toggle", Name = "Show Names", Default = true,
            Callback = function(v) end},

        {Type = "slider", Name = "Max Distance", Min = 50, Max = 2000, Default = 300,
            Callback = function(v) end},

        {Type = "input", Name = "Label", Default = "Player",
            Callback = function(text) end},

        {Type = "keybind", Name = "Toggle Key", Default = nil,
            OnPress = function() end,
            OnBind  = function(key) end},
    }
})
```

The types you can use are colorpicker, toggle, slider, input, and keybind.

---

## Notifications

```lua
Duvome:MakeNotification({
    Name    = "Success",
    Content = "Everything worked.",
    Type    = "success",
    Time    = 4,
    Actions = {
        {Text = "Undo",   Callback = function() end},
        {Text = "Dismiss", Callback = function() end, Close = true},
    }
})
```

Type can be info, success, warning, error, or left out for a plain look.

## Prompt Dialog

A pop up box asking the user to confirm something. Only one shows at a time.

```lua
Duvome:Prompt({
    Title   = "Reset Everything",
    Content = "This will wipe all saved settings. Are you sure?",
    Options = {
        {Text = "Cancel", Callback = function() end},
        {Text = "Reset",  Callback = function() end},
    }
})
```

---

## Themes and Colors

There are five themes built in: Default, Ocean, Crimson, Emerald, and Midnight.

```lua
Duvome:SetTheme("Ocean")
local names = Duvome:GetThemes()

Duvome:SetAccent(Color3.fromRGB(45, 200, 110))
```

`SetAccent` lets you build a whole new theme from just one color. It picks matching backgrounds and text colors on its own. If someone picks a very dark or grey color, the text stays neutral grey and white instead of turning that color too.

Users can also pick a theme from the gear icon at the top of the window. This has the five themes plus a full color picker. If they pick a custom color, it gets saved with their config and comes back next time.

---

## Watch List

A small box that floats on screen and shows which features are turned on. It works for keybinds and for regular toggles too.

```lua
local flying = false

Duvome:AddWatch("Fly", function() return flying end, Enum.KeyCode.F)
Duvome:AddWatch("God Mode", function() return godMode end)
Duvome:AddWatch("FPS", function() return currentFps .. " fps" end)

Duvome:SetWatchVisible(false)
```

If your function returns true or false, it shows ON or OFF. If it returns a string, that string just shows as is. Users can turn the whole list off from the settings menu too.

---

## Saving Configs

Turn on `SaveConfig = true` and give your elements a `Flag`. Users can click the pencil icon at the bottom left to name and save their setup, load it later, or copy it to their clipboard.

```lua
Section:AddToggle({Name = "ESP", Flag = "esp_enabled", Save = true, Callback = function(v) end})
```

You can read saved values like this:

```lua
local value = Duvome.Flags["esp_enabled"].Value
```

Custom colors and the picked theme get saved too.

---

## Side Panels

**Avatar panel:** click your profile picture on the side. It shows your name, username, user id, account age, executor, the game's name, the place id, and a live list of players in the server. Click a player to copy their user id.

**Config panel:** click the pencil icon. This is where you save, load, and export configs.

Both panels slide in and follow the window if you drag it around. They also snap to either side of the window. They will never sit on the same side at the same time. If one is on the right, the other moves to the left.

---

## Other Useful Methods

```lua
Duvome:Init()
Duvome:IsRunning()
Duvome:Destroy()
Duvome:SetWatchVisible(true)
```

Always call `Init()` last, after you finish building everything.

---

## Controlling Elements Later

Most elements give you back something you can control after you make them.

```lua
local toggle = Section:AddToggle({Name = "ESP", Callback = function(v) end})

toggle:Set(true)
toggle:SetVisible(false)
```

| Method | Works on |
|---|---|
| `:Set(value)` | Toggle, Slider, Dropdown, Textbox, Bind, Colorpicker, Label, Paragraph |
| `:SetVisible(bool)` | Toggle, Slider, Button, Dropdown, Bind, Colorpicker |
| `:Refresh(options, clear)` | Dropdown |

---

## Mobile

When the UI is hidden, a small circle button shows up so people on phones can bring it back. Phones don't have a keyboard for the toggle key, so this is how they reopen the menu. Users can drag the circle around without it accidentally reopening the menu.

---

## Good to Know

- Always call `Duvome:Init()` after you build your whole menu, not before.
- Long text gets cut off cleanly instead of overlapping other stuff.
- The blur setting covers the whole screen, not just the menu. Roblox does not let you blur only one shape on screen.
