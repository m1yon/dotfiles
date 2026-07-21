local application = require("hs.application")
local eventtap = require("hs.eventtap")
local hotkey = require("hs.hotkey")
require("hs.ipc")
local mouse = require("hs.mouse")
local osascript = require("hs.osascript")
local settings = require("hs.settings")
local spaces = require("hs.spaces")
local task = require("hs.task")
local timer = require("hs.timer")
local window = require("hs.window")

local log = hs.logger.new("native-spaces", "info")
window.animationDuration = 0

local function openNewChromeWindow()
  task.new("/usr/bin/open", function(exitCode, _, stderr)
    if exitCode ~= 0 then
      log.e("Could not open a new Chrome window: " .. stderr)
      hs.alert.show("Could not open Chrome")
    end
  end, {"-n", "-a", "Google Chrome"}):start()
end

local function openNewGhosttyWindow()
  if not application.get("com.mitchellh.ghostty") then
    if not application.launchOrFocusByBundleID("com.mitchellh.ghostty") then
      log.e("Could not launch Ghostty")
      hs.alert.show("Could not open Ghostty")
    end
    return
  end

  local ok, _, errorDetails = osascript.applescript([[
    tell application id "com.mitchellh.ghostty"
      new window
      activate
    end tell
  ]])
  if not ok then
    log.e("Could not open a window in the existing Ghostty instance: "
      .. hs.inspect(errorDetails))
    hs.alert.show("Could not open a Ghostty window")
  end
end

hotkey.bind({"ctrl", "shift"}, "b", openNewChromeWindow)
hotkey.bind({"ctrl", "shift"}, "t", openNewGhosttyWindow)

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

local nativeSwitchInProgress = false
local moveInProgress = false
local moveSafetyTimer = nil
local currentSpace = spaces.activeSpaceOnScreen("Main")
local storedCurrentSpace = settings.get("nativeSpacesCurrentSpace")
local previousSpace = settings.get("nativeSpacesPreviousSpace")

if storedCurrentSpace and storedCurrentSpace ~= currentSpace then
  previousSpace = storedCurrentSpace
end
if previousSpace == currentSpace then
  previousSpace = nil
end
if currentSpace then
  settings.set("nativeSpacesCurrentSpace", currentSpace)
end

-- Re-post ordinary switching as a native macOS shortcut. Passing the original
-- event through is not reliable on Tahoe, while posting the native shortcut
-- keeps the normal Space transition and avoids spaces.gotoSpace() opening
-- Mission Control.
local function switchToSpace(index)
  local shortcutKey = index == 10 and "0" or tostring(index)

  nativeSwitchInProgress = true
  eventtap.event.newKeyEvent({"ctrl"}, shortcutKey, true):post()
  eventtap.event.newKeyEvent({"ctrl"}, shortcutKey, false):post()
  timer.doAfter(0.05, function()
    nativeSwitchInProgress = false
  end)
end

local function switchToPreviousSpace()
  if not previousSpace then
    hs.alert.show("No previous Space yet")
    return
  end

  for index, id in ipairs(orderedUserSpaces()) do
    if id == previousSpace then
      switchToSpace(index)
      return
    end
  end

  hs.alert.show("Previous Space no longer exists")
end

-- Track every Space change, including trackpad gestures and app activation.
-- Query the stable Space ID instead of relying on the watcher's deprecated
-- numeric Space argument.
nativeSpacesHistoryWatcher = spaces.watcher.new(function()
  timer.doAfter(0.05, function()
    local newSpace = spaces.activeSpaceOnScreen("Main")
    if newSpace and newSpace ~= currentSpace then
      previousSpace = currentSpace
      currentSpace = newSpace
      settings.set("nativeSpacesPreviousSpace", previousSpace)
      settings.set("nativeSpacesCurrentSpace", currentSpace)
    end
  end)
end):start()

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
  local keyCode = event:getKeyCode()
  local index = keyCodeToSpace[keyCode]
  local isPreviousSpaceShortcut = keyCode == 48 -- Tab

  if (not index and not isPreviousSpaceShortcut)
      or not flags.ctrl
      or flags.cmd
      or flags.alt
      or flags.fn
      or (isPreviousSpaceShortcut and flags.shift) then
    return false
  end

  -- Let the native shortcut generated by switchToSpace or moveWindowToSpace
  -- reach macOS instead of intercepting it recursively.
  if index and not flags.shift and (nativeSwitchInProgress or moveInProgress) then
    return false
  end

  if event:getProperty(eventtap.event.properties.keyboardEventAutorepeat) == 1 then
    return true
  end

  if isPreviousSpaceShortcut then
    switchToPreviousSpace()
  elseif flags.shift then
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
