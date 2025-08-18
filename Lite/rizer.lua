-- RIZER Text Editor Installer (No Help Version)
-- By: YourName
-- Version: 1.0

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    print("====================================")
    print("      RIZER Text Editor Installer")
    print("====================================")
    print()
end

local function backupExisting()
    if fs.exists("rizer") then
        print("Existing RIZER installation found.")
        print("Creating backup (rizer.bak)...")
        fs.copy("rizer", "rizer.bak")
        print("Backup created successfully.")
    end
end

local function writeRIZER()
    print("Installing RIZER text editor...")
    
    -- RIZER code embedded as a string (without help functionality)
    local rizerCode = [[-- RIZER - A nano-inspired text editor for CC:Tweaked
-- By: YourName
-- Version: 1.0

local args = {...}
local filename = args[1] or "newfile.txt"
local buffer = {}
local dirty = false
local running = true
local cursorX, cursorY = 1, 1
local offsetX, offsetY = 1, 1
local termW, termH = term.getSize()
local statusMsg = ""
local statusTimer = 0

-- Initialize the editor
local function init()
  term.clear()
  term.setCursorPos(1, 1)
  
  -- Try to load file if it exists
  if fs.exists(filename) then
    local file = io.open(filename, "r")
    if file then
      for line in file:lines() do
        table.insert(buffer, line)
      end
      file:close()
      dirty = false
      showStatus("Loaded " .. filename)
    else
      showStatus("Error opening " .. filename)
    end
  else
    buffer = {""}
    dirty = true
    showStatus("New File")
  end
  
  -- Ensure buffer has at least one line
  if #buffer == 0 then
    buffer = {""}
  end
end

-- Show a status message
local function showStatus(msg)
  statusMsg = msg
  statusTimer = 3
end

-- Draw the editor interface
local function draw()
  term.clear()
  
  -- Calculate visible area
  local visibleLines = math.min(termH - 2, #buffer - offsetY + 1)
  
  -- Draw buffer content
  for i = 1, visibleLines do
    local lineNum = offsetY + i - 1
    if lineNum <= #buffer then
      local line = buffer[lineNum]
      local visibleLine = line:sub(offsetX, offsetX + termW - 1)
      term.setCursorPos(1, i)
      term.write(visibleLine)
    end
  end
  
  -- Draw status bar
  term.setCursorPos(1, termH)
  term.setBackgroundColor(colors.gray)
  term.setTextColor(colors.white)
  term.write(" File: " .. filename .. " ")
  term.write(string.rep(" ", termW - #filename - 20))
  term.write(" Ln " .. cursorY .. ", Col " .. cursorX .. " ")
  term.setBackgroundColor(colors.black)
  
  -- Draw help bar
  term.setCursorPos(1, termH - 1)
  term.setBackgroundColor(colors.blue)
  term.setTextColor(colors.white)
  term.write("^X Exit  ^O Save  ^W SaveAs  ^R Open")
  term.setBackgroundColor(colors.black)
  
  -- Draw cursor
  local screenX = cursorX - offsetX + 1
  local screenY = cursorY - offsetY + 1
  if screenX >= 1 and screenX <= termW and screenY >= 1 and screenY <= termH - 2 then
    term.setCursorPos(screenX, screenY)
    term.setCursorBlink(true)
  end
  
  -- Draw status message if active
  if statusTimer > 0 then
    term.setCursorPos(1, termH - 1)
    term.setBackgroundColor(colors.green)
    term.setTextColor(colors.black)
    term.write(" " .. statusMsg .. string.rep(" ", termW - #statusMsg - 1))
    term.setBackgroundColor(colors.black)
    statusTimer = statusTimer - 1
  end
end

-- Handle key presses
local function handleKey(key)
  -- Handle special keys
  if key == keys.left then
    if cursorX > 1 then
      cursorX = cursorX - 1
    elseif cursorY > 1 then
      cursorY = cursorY - 1
      cursorX = #buffer[cursorY] + 1
    end
  elseif key == keys.right then
    if cursorX <= #buffer[cursorY] then
      cursorX = cursorX + 1
    elseif cursorY < #buffer then
      cursorY = cursorY + 1
      cursorX = 1
    end
  elseif key == keys.up then
    if cursorY > 1 then
      cursorY = cursorY - 1
      if cursorX > #buffer[cursorY] then
        cursorX = #buffer[cursorY] + 1
      end
    end
  elseif key == keys.down then
    if cursorY < #buffer then
      cursorY = cursorY + 1
      if cursorX > #buffer[cursorY] then
        cursorX = #buffer[cursorY] + 1
      end
    end
  elseif key == keys.backspace then
    if cursorX > 1 then
      buffer[cursorY] = buffer[cursorY]:sub(1, cursorX - 2) .. buffer[cursorY]:sub(cursorX)
      cursorX = cursorX - 1
      dirty = true
    elseif cursorY > 1 then
      local prevLine = buffer[cursorY - 1]
      buffer[cursorY - 1] = prevLine .. buffer[cursorY]
      table.remove(buffer, cursorY)
      cursorY = cursorY - 1
      cursorX = #prevLine + 1
      dirty = true
    end
  elseif key == keys.enter then
    local line = buffer[cursorY]
    buffer[cursorY] = line:sub(1, cursorX - 1)
    table.insert(buffer, cursorY + 1, line:sub(cursorX))
    cursorY = cursorY + 1
    cursorX = 1
    dirty = true
  elseif key == keys.home then
    cursorX = 1
  elseif key == keys["end"] then
    cursorX = #buffer[cursorY] + 1
  end
  
  -- Update view if cursor is out of bounds
  if cursorX < offsetX then
    offsetX = cursorX
  elseif cursorX > offsetX + termW - 1 then
    offsetX = cursorX - termW + 1
  end
  
  if cursorY < offsetY then
    offsetY = cursorY
  elseif cursorY > offsetY + termH - 3 then
    offsetY = cursorY - termH + 3
  end
end

-- Handle character input
local function handleChar(char)
  local line = buffer[cursorY]
  buffer[cursorY] = line:sub(1, cursorX - 1) .. char .. line:sub(cursorX)
  cursorX = cursorX + 1
  dirty = true
end

-- Save the current file
local function saveFile(newName)
  local saveName = newName or filename
  local file = io.open(saveName, "w")
  if file then
    for _, line in ipairs(buffer) do
      file:write(line .. "\n")
    end
    file:close()
    dirty = false
    filename = saveName
    showStatus("Saved as " .. saveName)
    return true
  else
    showStatus("Error saving " .. saveName)
    return false
  end
end

-- Open a file
local function openFile(newName)
  if dirty then
    showStatus("Save changes first (Ctrl+O)")
    return
  end
  
  if fs.exists(newName) then
    local file = io.open(newName, "r")
    if file then
      buffer = {}
      for line in file:lines() do
        table.insert(buffer, line)
      end
      file:close()
      filename = newName
      dirty = false
      cursorX, cursorY = 1, 1
      offsetX, offsetY = 1, 1
      showStatus("Opened " .. newName)
    else
      showStatus("Error opening " .. newName)
    end
  else
    showStatus("File not found: " .. newName)
  end
end

-- Main editor loop
local function run()
  init()
  
  while running do
    draw()
    
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "key" then
      if p1 == keys.x and ctrl then  -- Ctrl+X: Exit
        if dirty then
          showStatus("Save changes first (Ctrl+O)")
        else
          running = false
        end
      elseif p1 == keys.o and ctrl then  -- Ctrl+O: Save
        saveFile()
      elseif p1 == keys.w and ctrl then  -- Ctrl+W: Save As
        term.setCursorPos(1, termH - 1)
        term.setBackgroundColor(colors.gray)
        term.write("Save as: ")
        term.setBackgroundColor(colors.black)
        local newName = read()
        if newName ~= "" then
          saveFile(newName)
        end
      elseif p1 == keys.r and ctrl then  -- Ctrl+R: Open
        term.setCursorPos(1, termH - 1)
        term.setBackgroundColor(colors.gray)
        term.write("Open file: ")
        term.setBackgroundColor(colors.black)
        local newName = read()
        if newName ~= "" then
          openFile(newName)
        end
      else
        handleKey(p1)
      end
    elseif event == "char" then
      handleChar(p1)
    elseif event == "key_up" then
      if p1 == keys.leftCtrl or p1 == keys.rightCtrl then
        ctrl = false
      end
    elseif event == "key_down" then
      if p1 == keys.leftCtrl or p1 == keys.rightCtrl then
        ctrl = true
      end
    end
  end
  
  term.clear()
  term.setCursorPos(1, 1)
  print("Thank you for using RIZER!")
end

-- Start the editor
run()]]

    -- Write the code to file
    local file = fs.open("rizer", "w")
    if file then
        file.write(rizerCode)
        file.close()
        print("RIZER installed successfully!")
        return true
    else
        print("ERROR: Failed to create file!")
        return false
    end
end

local function verifyInstallation()
    print("Verifying installation...")
    
    if not fs.exists("rizer") then
        print("ERROR: RIZER file not found!")
        return false
    end
    
    local file = fs.open("rizer", "r")
    if not file then
        print("ERROR: Unable to open RIZER file!")
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    -- Simple verification by checking for key content
    if content:find("RIZER") and content:find("text editor") then
        print("Installation verified successfully!")
        return true
    else
        print("ERROR: Installation verification failed!")
        return false
    end
end

local function showCompletion()
    print("\n====================================")
    print("  Installation completed successfully!")
    print("====================================")
    print("\nTo use RIZER:")
    print("1. Run 'rizer' to start the editor")
    print("2. Run 'rizer filename' to edit a file")
    print("\nExample: rizer startup")
    print("\nKeyboard shortcuts:")
    print("Ctrl+X - Exit  Ctrl+O - Save")
    print("Ctrl+W - Save As  Ctrl+R - Open")
    print("\nA backup of your previous version")
    print("was saved as 'rizer.bak' if it existed.")
end

-- Main installer logic
printHeader()

backupExisting()

if not writeRIZER() then
    return
end

if not verifyInstallation() then
    print("\nInstallation failed. Please try again.")
    return
end

showCompletion()
