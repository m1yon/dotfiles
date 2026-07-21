local eventtap = require("hs.eventtap")
require("hs.ipc")
local mouse = require("hs.mouse")
local spaces = require("hs.spaces")
local timer = require("hs.timer")
local window = require("hs.window")

local log = hs.logger.new("native-spaces", "info")
window.animationDuration = 0

local function orderedUserSpaces()
  local ids, err = spaces.spacesForScreen("Main")
  if not ids then
    log.e("Unable to list Spaces: " .. tostring(err))
    return {}
  end

  local result = {}
  for _, id in ipairs(ids) do
    if spaces.spaceType(id) == "user" then
      table.insert(result, id)
    end
  end
  return result
end

local function spaceAt(index)
  local id = orderedUserSpaces()[index]
  if not id then
    hs.alert.show("Space " .. index .. " does not exist")
  end
  return id
end

local function switchToSpace(index)
  local id = spaceAt(index)
  if not id then return end

  local ok, err = spaces.gotoSpace(id)
  if not ok then
    log.e("Could not switch to Space " .. index .. ": " .. tostring(err))
    hs.alert.show("Could not switch to Space " .. index)
  end
end

local moveInProgress = false
local moveSafetyTimer = nil

local function windowIsOnSpace(targetWindow, targetSpace)
  for _, id in ipairs(spaces.windowSpaces(targetWindow) or {}) do
    if id == targetSpace then return true end
  end
  return false
end

-- Apple made spaces.moveWindowToSpace a silent no-op in Sequoia/Tahoe.
-- Holding a real title-bar drag while invoking macOS's native Space
-- shortcut still works. The one-pixel drag also supports apps with custom
-- title bars, and the original frame is restored after the switch.
local function moveWindowToSpace(index)
  local targetSpace = spaceAt(index)
  if not targetSpace or moveInProgress then return end

  local focusedWindow = window.focusedWindow()
  if not focusedWindow then
    hs.alert.show("No focused window")
    return
  end

  if windowIsOnSpace(focusedWindow, targetSpace) then return end

  local frame = focusedWindow:frame()
  local originalFrame = {
    x = frame.x,
    y = frame.y,
    w = frame.w,
    h = frame.h,
  }
  local originalMousePosition = mouse.absolutePosition()
  local titleBarPoint = {
    x = frame.x + frame.w / 2,
    y = frame.y + 3,
  }
  local dragPoint = {
    x = titleBarPoint.x + 1,
    y = titleBarPoint.y,
  }
  local shortcutKey = index == 10 and "0" or tostring(index)

  local function resetMoveState()
    if moveSafetyTimer then
      moveSafetyTimer:stop()
      moveSafetyTimer = nil
    end
    moveInProgress = false
  end

  local function releaseWindow()
    eventtap.event.newMouseEvent(
      eventtap.event.types.leftMouseUp,
      mouse.absolutePosition()
    ):post()

    timer.doAfter(0.05, function()
      focusedWindow:setFrame(originalFrame)
      mouse.absolutePosition(originalMousePosition)

      if windowIsOnSpace(focusedWindow, targetSpace) then
        focusedWindow:raise()
        focusedWindow:focus()
      else
        log.e("Title-bar drag did not move the window to Space " .. index)
        hs.alert.show("Could not move window to Space " .. index)
      end
      resetMoveState()
    end)
  end

  moveInProgress = true
  moveSafetyTimer = timer.doAfter(2, function()
    eventtap.event.newMouseEvent(
      eventtap.event.types.leftMouseUp,
      mouse.absolutePosition()
    ):post()
    mouse.absolutePosition(originalMousePosition)
    log.e("Timed out while moving a window to Space " .. index)
    resetMoveState()
  end)

  mouse.absolutePosition(titleBarPoint)
  timer.doAfter(0.05, function()
    eventtap.event.newMouseEvent(
      eventtap.event.types.leftMouseDown,
      titleBarPoint
    ):post()

    timer.doAfter(0.03, function()
      eventtap.event.newMouseEvent(
        eventtap.event.types.leftMouseDragged,
        dragPoint
      ):setProperty(eventtap.event.properties.mouseEventDeltaX, 1):post()

      timer.doAfter(0.05, function()
        -- Tahoe ignores a combined Control-number CGEvent here. Send the
        -- modifier and key transitions separately, like physical input.
        eventtap.event.newKeyEvent("ctrl", true):post()
        timer.doAfter(0.02, function()
          eventtap.event.newKeyEvent(shortcutKey, true):post()
          timer.doAfter(0.02, function()
            eventtap.event.newKeyEvent(shortcutKey, false):post()
            eventtap.event.newKeyEvent("ctrl", false):post()
            timer.doAfter(0.6, releaseWindow)
          end)
        end)
      end)
    end)
  end)
end

-- Event taps do not use macOS's Carbon hotkey registry. That registry keeps
-- Control-1 through Control-4 reserved on some macOS releases even after
-- their Mission Control shortcuts have been disabled.
local keyCodeToSpace = {
  [18] = 1,
  [19] = 2,
  [20] = 3,
  [21] = 4,
  [23] = 5,
  [22] = 6,
  [26] = 7,
  [28] = 8,
  [25] = 9,
  [29] = 10,
}

local function handleSpaceHotkey(event)
  local flags = event:getFlags()
  local index = keyCodeToSpace[event:getKeyCode()]

  if not index or not flags.ctrl or flags.cmd or flags.alt or flags.fn then
    return false
  end

  if event:getProperty(eventtap.event.properties.keyboardEventAutorepeat) == 1 then
    return true
  end

  -- Let the synthetic Control-number event used by moveWindowToSpace reach
  -- macOS's native Mission Control shortcut.
  if moveInProgress and not flags.shift then
    return false
  end

  if flags.shift then
    moveWindowToSpace(index)
  else
    switchToSpace(index)
  end
  return true
end

nativeSpacesKeyTap = eventtap.new({ eventtap.event.types.keyDown }, handleSpaceHotkey):start()
if nativeSpacesKeyTap:isEnabled() then
  log.i("Loaded Control Space shortcuts through an event tap")
else
  log.e("Could not start the Space shortcut event tap")
  hs.alert.show("Hammerspoon could not capture Space shortcuts")
end

-- Reload automatically whenever Home Manager replaces this configuration.
nativeSpacesConfigWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()
