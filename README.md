# Daydream Newspaper Club

> A Hybrid Narrative Visual Novel & Simulated Desktop Operating System Game Engine
> Built with Love2D (Lua) | Windows 10 Style Desktop Interface | 60 FPS Letterboxed Virtual Resolution

---

## Overview

**Daydream Newspaper Club** is a hybrid narrative game that seamlessly switches between **Storytelling Mode (Visual Novel)** and the **Protagonist's Personal Computer (Desktop Simulation)** set in the nostalgic atmosphere of Kamiyama High School.

The player assumes the role of **Aki Akizuki**, lead layout editor of the Kamiyama High Newspaper Club. Facing an impending budget audit by the Student Council, Aki must work alongside Vice President **Suzumia**, President **Nagahashi**, and tech specialist **Hoshida** to assemble the Dual-Cover Autumn Special Edition while uncovering an unauthorized proxy server operating inside the school's old 3rd floor repeater network.

Gameplay transitions are narrative-driven: the visual novel story naturally directs the player to their workstation to complete real computing tasks (downloading email attachments, editing review drafts in TextEditor, researching cat cafe menus in Browser, chatting with club members, and isolating network ciphers), then returns to the visual novel when objectives are fulfilled.

---

## Key Features

### 1. Visual Novel & Narrative Engine
- **Letterboxed Virtual Viewport**: Crisp rendering locked to 760x480 virtual canvas with automatic letterbox/pillarbox scaling for any window size and aspect ratio.
- **Cinematic Transitions**: Standard visual novel transitions including fade, fade white, wipes (left, right, down), curtains, iris, CRT zoom, and glitch.
- **Character Sprites**: Automatic sprite scaling (88% viewport height), sprite mirroring/flipping support (`flip = true`), and missing asset fallback cards for developer friendliness.
- **Dialogue Controls**: On-screen buttons (`[ NEXT > ]`, `[ SKIP >> ]`, `[ AUTO ]`, `[ LOG ]`) and mobile touch support.
- **Backlog History**: Full scrollable transcript dialogue log overlay.

### 2. Desktop Operating System Simulation
- **Multi-Process App Management**: Run multiple concurrent instances with unique Process IDs (`pid`).
- **Core Applications**:
  - TextEditor (File editing, saving, syntax styling)
  - Files Manager (Virtual filesystem browser)
  - Terminal (Shell with `ls`, `cat`, `help`, `quarantine` commands)
  - Email Client (Progressive email threads and attachment downloads)
  - Chat Client (Scripted narrative messaging)
  - Browser (Tabbed intranet and web browsing)
  - ImageViewer (Image rendering with `content` path loading and fallback placeholders)
  - ObjViewer (Interactive 3D model viewer with `.obj` loader)
  - Tessarect (Interactive 4D hypercube wireframe renderer)
  - Settings (Wallpaper, display, system diagnostics, and DLC Manager)

### 3. Modular DLC & Addon System
- Real-time DLC application discovery from the `dlc/` directory.
- Hot-reloading DLC apps via the in-game Settings app without restarting.
- Included sample DLC apps: Calculator, Music Player, and Retro Snake.

---

## DLC & Addons Complete Guide

The engine includes a modular, flexible **DLC (Downloadable Content / Addon)** system allowing developers and players to create, drop in, and run custom applications inside the desktop environment.

### 1. Where to Install DLCs

All DLC packages and standalone scripts must be placed in the `dlc/` folder located at the root of the game directory:

```
lynux-caracal/
├── dlc/
│   ├── calculator/          <-- Folder-based DLC
│   │   ├── dlc.json
│   │   ├── init.lua
│   │   └── calculator.lua
│   ├── music_player/        <-- Folder-based DLC
│   │   ├── dlc.json
│   │   ├── init.lua
│   │   └── music_player.lua
│   ├── retro_snake/         <-- Folder-based DLC
│   │   ├── dlc.json
│   │   ├── init.lua
│   │   └── snake.lua
│   └── my_custom_app.lua    <-- Single-file standalone DLC
```

---

### 2. Supported DLC Formats

The DLC Manager supports two distinct formats:

#### Format A: Folder-based DLC Package (Recommended)
A directory inside `dlc/<package_name>/` containing:
1. `dlc.json` (or `manifest.json`): Package metadata.
2. `init.lua`: Main Lua loader executed when the DLC is initialized.
3. `apps/*.lua`: One or more app modules, scripts, or assets.

#### Format B: Single-file Standalone App
A single `.lua` file placed directly in `dlc/<app_name>.lua` that returns an app table or class module.

---

### 3. Manifest File Schema (`dlc.json`)

The `dlc.json` file configures how the DLC is identified, categorized, and rendered:

```json
{
    "id": "calculator",
    "name": "Calculator",
    "version": "1.0.0",
    "author": "Lynux Dev Team",
    "description": "Standard & scientific desktop calculator app with memory.",
    "category": "Utilities",
    "defaultWidth": 340,
    "defaultHeight": 440,
    "enabled": true
}
```

#### Manifest Fields:
| Field | Type | Description |
|---|---|---|
| `id` | String | Unique alphanumeric identifier (e.g. `"paint_app"`). |
| `name` | String | User-facing display title shown in Taskbar and Start Menu. |
| `version` | String | Version number (e.g. `"1.0.0"`). |
| `author` | String | Creator or organization name. |
| `description`| String | Summary shown in the Settings DLC Manager. |
| `category` | String | Category: `"Utilities"`, `"Games"`, `"Media"`, `"Development"`, `"Tools"`. |
| `defaultWidth` | Number | Initial window width in pixels (e.g. `480`). |
| `defaultHeight`| Number | Initial window height in pixels (e.g. `360`). |
| `enabled` | Boolean | Set `false` to disable without deleting files. |

---

### 4. DLC App Architecture & Lifecycle API

Every DLC application module must implement standard lifecycle callbacks:

```lua
-- dlc/paint/paint.lua
local PaintApp = {}
PaintApp.__index = PaintApp

-- 1. Constructor: Creates a new process instance
function PaintApp.new()
    local self = setmetatable({}, PaintApp)
    self.canvas = love.graphics.newCanvas(400, 300)
    self.color = {0, 0, 0}
    return self
end

-- 2. Frame Update: Called every frame with delta time (dt in seconds)
function PaintApp:update(dt)
end

-- 3. Draw: Render your UI inside the window content bounds
-- Note: (x, y) is the window content top-left, (width, height) is the window dimensions
function PaintApp:draw(x, y, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Paint Canvas", x + 10, y + 10)
end

-- 4. Mouse Input Handlers
function PaintApp:mousepressed(mx, my, button)
    -- mx, my are local to the window
    return true -- Return true if input was consumed
end

function PaintApp:mousemoved(mx, my, dx, dy)
end

function PaintApp:mousereleased(mx, my, button)
end

function PaintApp:wheelmoved(x, y)
end

-- 5. Keyboard & Text Input Handlers
function PaintApp:keypressed(key)
    if key == "r" then
        -- Reset action
        return true
    end
end

function PaintApp:textinput(text)
end

-- 6. Window Resize Notification
function PaintApp:resize(w, h)
end

return PaintApp
```

---

### 5. Step-by-Step Example: Creating a Custom DLC App

Here is how to create a complete custom **"Notepad Plus"** DLC from scratch:

#### Step 1: Create the Folder
Create `dlc/notepad_plus/`

#### Step 2: Create `dlc/notepad_plus/dlc.json`
```json
{
    "id": "notepad_plus",
    "name": "Notepad Plus",
    "version": "1.0.0",
    "author": "Modder",
    "description": "Simple notes scratchpad with quick clear.",
    "category": "Utilities",
    "defaultWidth": 460,
    "defaultHeight": 320,
    "enabled": true
}
```

#### Step 3: Create `dlc/notepad_plus/init.lua`
```lua
local folderPath = ...
local chunk = love.filesystem.load(folderPath .. "/notepad.lua")
if chunk then
    return chunk()
end
return nil
```

#### Step 4: Create `dlc/notepad_plus/notepad.lua`
```lua
local Notepad = {}
Notepad.__index = Notepad

function Notepad.new()
    local self = setmetatable({}, Notepad)
    self.text = "Type your notes here..."
    return self
end

function Notepad:update(dt) end

function Notepad:draw(x, y, width, height)
    love.graphics.setColor(0.98, 0.98, 0.99)
    love.graphics.rectangle("fill", x, y, width, height)

    love.graphics.setColor(0.15, 0.18, 0.25)
    love.graphics.printf(self.text, x + 12, y + 12, width - 24, "left")
end

function Notepad:textinput(text)
    self.text = self.text .. text
end

function Notepad:keypressed(key)
    if key == "backspace" then
        self.text = self.text:sub(1, -2)
        return true
    elseif key == "return" then
        self.text = self.text .. "\n"
        return true
    end
end

return Notepad
```

#### Step 5: Reload in Game
Open **Settings** on the desktop, go to the **DLC & Addons** tab, and click **Reload All DLCs**. The app will immediately appear on the Taskbar Dock and Start Menu!

---

### 6. Built-in Sample DLC Apps

The game ships with 3 pre-built sample DLC apps in the `dlc/` directory:

1. **Calculator** (`dlc/calculator/`):
   - Number and operator buttons (`+`, `-`, `*`, `/`, `%`, `+/-`).
   - Tape display history, backspace, and keyboard number input.
2. **Music Player** (`dlc/music_player/`):
   - Playlist selection with Daydream OST and ambient tracks.
   - Play/Pause/Next/Prev controls and animated real-time audio visualizer bars.
3. **Retro Arcade Snake** (`dlc/retro_snake/`):
   - Classic grid-based snake mini-game.
   - Arrow/WASD steering, fruit generation, score & high-score tracking, progressive speed scaling, and instant restart.

---

## Controls

| Context | Key / Action | Description |
|---|---|---|
| **Anywhere** | `ESC` | Open / Close Pause & Settings Menu / Back |
| **Main Menu** | `Up` / `Down` / `Enter` / `Click` | Navigate & activate menu options |
| **Story Mode** | `Space` / `Enter` / `Left Click` | Advance dialogue / Complete typewriter text |
| **Story Mode** | `1`, `2`, `3` / `Click` | Select branching dialogue option |
| **Story Mode** | `H` / `L` | Toggle dialogue backlog history |
| **Desktop** | `Left Click` | Focus, launch, and interact with app windows & icons |
| **Desktop** | `Right Click` on Dock | Launch new process instance of application |
| **Desktop** | `Window Titlebar Drag` | Move active window |
| **Desktop** | `Window Bottom-Right Drag` | Resize active window |
| **Task HUD** | `Click Continue Story` | Return to visual novel after completing task |

---

## Running the Game

Launch with Love2D (v11+):
```bash
love .
```
