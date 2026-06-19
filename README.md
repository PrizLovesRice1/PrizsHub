# PrizsHubZ

# Duvome UI Library

> A heavily customized Orion-based UI library for Roblox exploit hubs. Deep purple theme, snow animations, avatar panels, collapsible sidebar, key system, and more.

---

## Quick Start

```lua
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/PrizLovesRice1/PrizsHub/main/OrionLib.lua"))()
```

---

## Creating a Window

```lua
local Window = OrionLib:MakeWindow({
    Name = "My Hub",
    IntroEnabled = true,
    IntroText = "My Hub",
    SaveConfig = false,
    ConfigFolder = "MyHubConfig",
    HidePremium = false,
    CloseCallback = function()
        -- fired when the close button is clicked
    end
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Duvome"` | Title shown in the top bar |
| `IntroEnabled` | bool | `true` | Show intro animation on load |
| `IntroText` | string | `"Orion Library"` | Text during intro |
| `SaveConfig` | bool | `false` | Auto-save/load flags to file |
| `ConfigFolder` | string | `Name` | Folder name for saved configs |
| `HidePremium` | bool | `false` | Hide premium-only tabs |
| `CloseCallback` | function | `nil` | Called when UI is closed |

---

## Creating a Tab

```lua
local Tab = Window:MakeTab({
    Name = "Main",
    Icon = "house",          -- BuilderIcons name
    PremiumOnly = false,
    Columns = false          -- set true for two-column layout
})
```

> Icons use the Roblox **BuilderIcons** font. Pass the icon name as a string e.g. `"sword"`, `"gear"`, `"house"`.

---

## Elements

### Section

```lua
local Section = Tab:AddSection({
    Name = "Combat",
    Collapsible = false   -- set true to make it collapse/expand
})
```

---

### Toggle

```lua
local Toggle = Section:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Flag = "AutoFarm",
    Save = true,
    ShowKeybind = true,       -- shows a keybind box next to the toggle
    Keybind = Enum.KeyCode.F, -- optional default keybind
    Color = Color3.fromRGB(120, 50, 200),
    Callback = function(Value)
        print("Auto Farm:", Value)
    end
})

-- Manually set value
Toggle:Set(true)
```

---

### Button

```lua
local Button = Section:AddButton({
    Name = "Teleport",
    Callback = function()
        print("Teleport clicked")
    end,
    ShowKeybind = true,
    Keybind = Enum.KeyCode.T,
    -- Optional gear panel with sub-settings:
    Options = {
        { Type = "slider", Name = "Speed",    Min = 1, Max = 100, Default = 16, Callback = function(v) end },
        { Type = "input",  Name = "Place",    Default = "Spawn",               Callback = function(v) end },
        { Type = "keybind",Name = "Bind",     Default = Enum.KeyCode.T,        Callback = function(v) end },
    }
})

Button:Set("New Label")
```

---

### Slider

```lua
local Slider = Section:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 1,
    Suffix = "studs/s",
    Flag = "WalkSpeed",
    Save = true,
    Color = Color3.fromRGB(120, 50, 200),
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
})

Slider:Set(100)
```

---

### Dropdown

```lua
local Dropdown = Section:AddDropdown({
    Name = "Select Aura",
    Options = { "None", "Fire", "Ice", "Lightning" },
    Default = "None",
    Flag = "SelectedAura",
    Save = true,
    Callback = function(Value)
        print("Selected:", Value)
    end
})

-- Add or replace options at runtime
Dropdown:Refresh({ "None", "Fire", "Ice" }, true)  -- second arg = delete old
Dropdown:Set("Fire")
```

---

### Colorpicker

```lua
local Picker = Section:AddColorpicker({
    Name = "Trail Color",
    Default = Color3.fromRGB(180, 100, 255),
    Flag = "TrailColor",
    Save = true,
    Callback = function(Value)
        print("Color:", Value)
    end
})

Picker:Set(Color3.fromRGB(255, 0, 0))
```

---

### Textbox

```lua
Section:AddTextbox({
    Name = "Player Name",
    Default = "",
    TextDisappear = false,   -- clears text after focus lost if true
    Callback = function(Value)
        print("Entered:", Value)
    end
})
```

---

### Bind

```lua
local Bind = Section:AddBind({
    Name = "Noclip Key",
    Default = Enum.KeyCode.N,
    Hold = false,   -- true = fires on hold, false = fires on press
    Flag = "NoclipBind",
    Save = true,
    Callback = function()
        print("Noclip toggled")
    end
})

Bind:Set(Enum.KeyCode.N)
```

---

### Label

```lua
local Label = Section:AddLabel("Status: Idle")

Label:Set("Status: Running")
```

---

### Paragraph

```lua
local Para = Section:AddParagraph("Info", "This is a description that wraps automatically.")

Para:Set("Updated content here.")
```

---

### Search

```lua
Section:AddSearch({
    Name = "Find Player",
    Placeholder = "Type a name...",
    Items = { "Player1", "Player2", "Player3" },
    Callback = function(Value)
        print("Picked:", Value)
    end
})
```

---

### Divider

```lua
Section:AddDivider()
```

---

## Two-Column Layout

Pass `Columns = true` when creating a tab, then use `:AddLeft()`, `:AddRight()`, or `:AddAuto()` instead of the tab directly.

```lua
local Tab = Window:MakeTab({ Name = "Settings", Columns = true })

local Left  = Tab:AddLeft()
local Right = Tab:AddRight()

Left:AddSection({ Name = "Left Side" })
Right:AddSection({ Name = "Right Side" })

-- Or alternate automatically:
Tab:AddAuto():AddToggle({ Name = "Option A", Callback = function() end })
Tab:AddAuto():AddToggle({ Name = "Option B", Callback = function() end })
```

---

## Key System

Place this **before** building your window. Pass a callback — it fires once the key is verified.

```lua
OrionLib.MakeKeyUI({
    Title      = "My Hub",
    Subtitle   = "Key System",
    Note       = "Get your key from our Discord.",
    FileName   = "MyHub_Key",    -- saved to file so user only enters once per HWID
    SaveKey    = true,
    Key        = { "mykey123" }, -- string, table of strings, or an http URL that returns keys
}, function()
    -- key accepted — build your window here
    local Window = OrionLib:MakeWindow({ Name = "My Hub" })
    -- ...
end)
```

| Option | Type | Description |
|---|---|---|
| `Title` | string | Panel title |
| `FileName` | string | File to save the verified key to |
| `SaveKey` | bool | Remember key per HWID (default `true`) |
| `Key` | string / table / URL | Valid key(s). If a URL, fetches and reads each line as a key |

---

## Flags

Every element with a `Flag` field is registered in `OrionLib.Flags`. You can read or set them globally:

```lua
-- Read
print(OrionLib.Flags["WalkSpeed"].Value)

-- Set
OrionLib.Flags["AutoFarm"]:Set(true)
```

---

## Notifications

```lua
OrionLib:MakeNotification({
    Name    = "Update",
    Content = "Hub loaded successfully.",
    Image   = "rbxassetid://4384403532",
    Time    = 5
})
```

---

## Toggle Keybind

The default toggle key is **RightShift**. Players can change it inside the gear (⚙) menu in the top bar.

---

## Destroy

```lua
OrionLib:Destroy()
```

---

## Credits

Built on a customized fork of [OrionLib](https://github.com/shlexware/Orion) with icons from Roblox BuilderIcons and [lucideblox](https://github.com/evoincorp/lucideblox).
