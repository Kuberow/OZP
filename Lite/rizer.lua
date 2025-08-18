-- OZP Installer: Nano-style RIZER editor with status bar and space
local fs = fs or require("filesystem")
local term = term or require("term")

-- Ensure /bin exists
if not fs.exists("/bin") then
    fs.makeDir("/bin")
    print("Created /bin directory")
end

local rizer_content = [[
-- Rizer Text Editor for ComputerCraft
-- Version 2.0
-- Inspired by nano text editor

-- Get command line arguments
local args = { ... }

local w, h = term.getSize()
local running = true
local filename = ""
local lines = {}
local currentLine = 1
local currentCol = 1
local topLine = 1
local dirty = false
local clipboard = {}  -- Now a table to store multiple lines
local message = ""
local messageTimer = 0
local mode = "normal" -- normal, save, search, replace, goto, help, select
local selection = {
    active = false,
    startLine = 1,
    startCol = 1,
    endLine = 1,
    endCol = 1
}
local ctrlHeld = false  -- Track if Ctrl is being held
local mouseSelecting = false  -- Track if mouse is being used for selection

-- Check for clipboard support using multiple methods
local hasClipboard = false
local clipboardPeripheral = nil

-- Method 1: Check for built-in clipboard table
if clipboard and type(clipboard) == "table" and clipboard.read and clipboard.write then
    hasClipboard = true
    end

    -- Method 2: Check for clipboard peripheral
    if not hasClipboard then
        local periphList = peripheral.getNames()
        for _, name in ipairs(periphList) do
            if peripheral.getType(name) == "clipboard" then
                clipboardPeripheral = peripheral.wrap(name)
                if clipboardPeripheral and clipboardPeripheral.read and clipboardPeripheral.write then
                    hasClipboard = true
                    break
                    end
                    end
                    end
                    end

                    -- Color scheme
                    local colorscheme = {
                        background = colors.black,
                        text = colors.white,
                        linenumber = colors.yellow,
                        statusbar = colors.gray,
                        statusbarText = colors.white,
                        commandbar = colors.lightGray,
                        commandbarText = colors.black,
                        selection = colors.blue,
                        cursor = colors.white
                    }

                    -- Key mappings
                    local ctrlMap = {
                        [keys.o] = "save",
                        [keys.x] = "exit",
                        [keys.w] = "search",
                        [keys.k] = "cut",
                        [keys.u] = "paste",
                        [keys.c] = "cancel",
                        [keys.g] = "help",
                        [keys.r] = "replace",
                        [keys.a] = "home",
                        [keys.e] = "end",
                        [keys.space] = "select"  -- Ctrl+Space to start selection
                    }

                    -- Initialize editor
                    local function init()
                    if #args == 0 then
                        print("Usage: rizer <filename>")
                        running = false
                        return
                        end

                        filename = args[1]

                        -- Initialize with at least one empty line
                        lines = {""}

                        if fs.exists(filename) then
                            local file = fs.open(filename, "r")
                            if file then
                                lines = {}
                                local line = file.readLine()
                                while line do
                                    table.insert(lines, line)
                                    line = file.readLine()
                                    end
                                    file.close()
                                    if #lines == 0 then
                                        lines = {""}
                                        end
                                        message = "Loaded " .. filename .. " with " .. #lines .. " lines"
                                        else
                                            message = "Error: Could not open file"
                                            end
                                            else
                                                message = "New file: " .. filename
                                                end

                                                -- Ensure we have at least one line
                                                if #lines == 0 then
                                                    lines = {""}
                                                    end
                                                    end

                                                    -- Draw screen with enhanced GUI
                                                    local function drawScreen()
                                                    term.setBackgroundColor(colorscheme.background)
                                                    term.clear()
                                                    term.setCursorPos(1, 1)

                                                    -- Header with gradient effect
                                                    term.setBackgroundColor(colors.gray)
                                                    term.setTextColor(colors.white)
                                                    term.write(" Rizer Editor: " .. filename)
                                                    if dirty then
                                                        term.setTextColor(colors.red)
                                                        term.write(" *")
                                                        end
                                                        term.setTextColor(colors.white)
                                                        term.clearLine()

                                                        -- Line numbers and content with selection highlighting
                                                        local visibleLines = h - 3
                                                        for i = 1, visibleLines do
                                                            local lineNum = topLine + i - 1
                                                            term.setCursorPos(1, i + 2)  -- Start at line 3 to leave space for header
                                                            term.clearLine()

                                                            if lineNum <= #lines then
                                                                -- Line number background
                                                                term.setBackgroundColor(colors.gray)
                                                                term.setTextColor(colorscheme.linenumber)
                                                                term.write(string.format("%4d ", lineNum))

                                                                -- Content area
                                                                term.setBackgroundColor(colorscheme.background)
                                                                term.setTextColor(colorscheme.text)
                                                                local line = lines[lineNum] or ""

                                                                -- Handle selection highlighting
                                                                if selection.active and lineNum >= selection.startLine and lineNum <= selection.endLine then
                                                                    local startCol = 1
                                                                    local endCol = #line + 1

                                                                    if lineNum == selection.startLine then
                                                                        startCol = selection.startCol
                                                                        end
                                                                        if lineNum == selection.endLine then
                                                                            endCol = selection.endCol
                                                                            end

                                                                            -- Text before selection
                                                                            if startCol > 1 then
                                                                                term.write(line:sub(1, startCol - 1))
                                                                                end

                                                                                -- Selected text
                                                                                term.setBackgroundColor(colorscheme.selection)
                                                                                term.write(line:sub(startCol, endCol - 1))

                                                                                -- Text after selection
                                                                                term.setBackgroundColor(colorscheme.background)
                                                                                if endCol <= #line then
                                                                                    term.write(line:sub(endCol))
                                                                                    end
                                                                                    else
                                                                                        -- No selection on this line
                                                                                        term.write(line:sub(1, w - 5))
                                                                                        end
                                                                                        end
                                                                                        end

                                                                                        -- Enhanced status bar
                                                                                        term.setCursorPos(1, h - 1)
                                                                                        term.setBackgroundColor(colorscheme.statusbar)
                                                                                        term.setTextColor(colorscheme.statusbarText)
                                                                                        term.clearLine()
                                                                                        term.write("Line: " .. currentLine .. " | Col: " .. currentCol)
                                                                                        if selection.active then
                                                                                            term.write(" | SEL: " .. math.abs(selection.endLine - selection.startLine) + 1 .. " lines")
                                                                                            end
                                                                                            if message ~= "" then
                                                                                                term.write(" | " .. message)
                                                                                                end

                                                                                                -- Enhanced command bar with color coding
                                                                                                term.setCursorPos(1, h)
                                                                                                term.setBackgroundColor(colorscheme.commandbar)
                                                                                                term.setTextColor(colorscheme.commandbarText)
                                                                                                term.clearLine()

                                                                                                -- Color code the commands
                                                                                                local commands = {
                                                                                                    {key = "^X", desc = "Exit", color = colors.red},
                                                                                                    {key = "^O", desc = "Save", color = colors.green},
                                                                                                    {key = "^W", desc = "Search", color = colors.blue},
                                                                                                    {key = "^K", desc = "Cut", color = colors.orange},
                                                                                                    {key = "^U", desc = "Paste", color = colors.purple},
                                                                                                    {key = "^G", desc = "Help", color = colors.cyan},
                                                                                                    {key = "^^", desc = "Select", color = colors.yellow}
                                                                                                }

                                                                                                local pos = 1
                                                                                                for _, cmd in ipairs(commands) do
                                                                                                    term.setTextColor(cmd.color)
                                                                                                    term.write(cmd.key)
                                                                                                    term.setTextColor(colorscheme.commandbarText)
                                                                                                    term.write(" " .. cmd.desc .. "  ")
                                                                                                    pos = pos + #cmd.key + #cmd.desc + 4
                                                                                                    if pos > w - 10 then break end
                                                                                                        end

                                                                                                        -- Cursor
                                                                                                        if currentLine >= topLine and currentLine < topLine + visibleLines then
                                                                                                            term.setCursorPos(5 + currentCol, currentLine - topLine + 3)
                                                                                                            term.setCursorBlink(true)
                                                                                                            term.setTextColor(colorscheme.cursor)
                                                                                                            else
                                                                                                                term.setCursorBlink(false)
                                                                                                                end
                                                                                                                end

                                                                                                                -- Update message
                                                                                                                local function updateMessage(msg)
                                                                                                                message = msg
                                                                                                                messageTimer = 10
                                                                                                                end

                                                                                                                -- Save file
                                                                                                                local function saveFile()
                                                                                                                local file = fs.open(filename, "w")
                                                                                                                if file then
                                                                                                                    for _, line in ipairs(lines) do
                                                                                                                        file.writeLine(line)
                                                                                                                        end
                                                                                                                        file.close()
                                                                                                                        dirty = false
                                                                                                                        updateMessage("Saved to " .. filename)
                                                                                                                        else
                                                                                                                            updateMessage("Error: Could not save file")
                                                                                                                            end
                                                                                                                            mode = "normal"
                                                                                                                            end

                                                                                                                            -- Toggle selection mode
                                                                                                                            local function toggleSelection()
                                                                                                                            if not selection.active then
                                                                                                                                -- Start selection
                                                                                                                                selection.active = true
                                                                                                                                selection.startLine = currentLine
                                                                                                                                selection.startCol = currentCol
                                                                                                                                selection.endLine = currentLine
                                                                                                                                selection.endCol = currentCol
                                                                                                                                updateMessage("Selection started")
                                                                                                                                else
                                                                                                                                    -- End selection
                                                                                                                                    selection.active = false
                                                                                                                                    updateMessage("Selection ended")
                                                                                                                                    end
                                                                                                                                    end

                                                                                                                                    -- Delete selection
                                                                                                                                    local function deleteSelection()
                                                                                                                                    if not selection.active then
                                                                                                                                        return false
                                                                                                                                        end

                                                                                                                                        -- Normalize selection (start before end)
                                                                                                                                        local startLine, startCol, endLine, endCol
                                                                                                                                        if selection.startLine < selection.endLine or
                                                                                                                                            (selection.startLine == selection.endLine and selection.startCol <= selection.endCol) then
                                                                                                                                            startLine, startCol = selection.startLine, selection.startCol
                                                                                                                                            endLine, endCol = selection.endLine, selection.endCol
                                                                                                                                            else
                                                                                                                                                startLine, startCol = selection.endLine, selection.endCol
                                                                                                                                                endLine, endCol = selection.startLine, selection.startCol
                                                                                                                                                end

                                                                                                                                                -- Extract selected lines to clipboard (for cut operation)
                                                                                                                                                clipboard = {}
                                                                                                                                                if startLine == endLine then
                                                                                                                                                    -- Single line selection
                                                                                                                                                    local line = lines[startLine] or ""
                                                                                                                                                    table.insert(clipboard, line:sub(startCol, endCol - 1))

                                                                                                                                                    -- Update the line
                                                                                                                                                    lines[startLine] = line:sub(1, startCol - 1) .. line:sub(endCol)
                                                                                                                                                    if lines[startLine] == "" and #lines > 1 then
                                                                                                                                                        table.remove(lines, startLine)
                                                                                                                                                        if startLine > #lines then
                                                                                                                                                            startLine = #lines
                                                                                                                                                            end
                                                                                                                                                            end
                                                                                                                                                            else
                                                                                                                                                                -- Multi-line selection
                                                                                                                                                                -- First line
                                                                                                                                                                local firstLine = lines[startLine] or ""
                                                                                                                                                                table.insert(clipboard, firstLine:sub(startCol))

                                                                                                                                                                -- Middle lines
                                                                                                                                                                for i = startLine + 1, endLine - 1 do
                                                                                                                                                                    table.insert(clipboard, lines[i] or "")
                                                                                                                                                                    end

                                                                                                                                                                    -- Last line
                                                                                                                                                                    local lastLine = lines[endLine] or ""
                                                                                                                                                                    table.insert(clipboard, lastLine:sub(1, endCol - 1))

                                                                                                                                                                    -- Update lines
                                                                                                                                                                    lines[startLine] = firstLine:sub(1, startCol - 1) .. lastLine:sub(endCol)

                                                                                                                                                                    -- Remove middle lines
                                                                                                                                                                    for i = startLine + 1, endLine do
                                                                                                                                                                        table.remove(lines, startLine + 1)
                                                                                                                                                                        end
                                                                                                                                                                        end

                                                                                                                                                                        -- Move cursor to start of selection
                                                                                                                                                                        currentLine = startLine
                                                                                                                                                                        currentCol = startCol
                                                                                                                                                                        selection.active = false
                                                                                                                                                                        dirty = true
                                                                                                                                                                        return true
                                                                                                                                                                        end

                                                                                                                                                                        -- Cut selection or current line
                                                                                                                                                                        local function cutSelection()
                                                                                                                                                                        if selection.active then
                                                                                                                                                                            if deleteSelection() then
                                                                                                                                                                                updateMessage("Cut " .. #clipboard .. " lines")
                                                                                                                                                                                end
                                                                                                                                                                                else
                                                                                                                                                                                    -- Cut current line
                                                                                                                                                                                    clipboard = {lines[currentLine] or ""}
                                                                                                                                                                                    table.remove(lines, currentLine)
                                                                                                                                                                                    if #lines == 0 then
                                                                                                                                                                                        lines = {""}
                                                                                                                                                                                        end
                                                                                                                                                                                        if currentLine > #lines then
                                                                                                                                                                                            currentLine = #lines
                                                                                                                                                                                            end
                                                                                                                                                                                            currentCol = 1
                                                                                                                                                                                            dirty = true
                                                                                                                                                                                            updateMessage("Cut line")
                                                                                                                                                                                            end
                                                                                                                                                                                            end

                                                                                                                                                                                            -- Read from system clipboard with multiple fallbacks
                                                                                                                                                                                            local function readSystemClipboard()
                                                                                                                                                                                            local clipboardText = ""

                                                                                                                                                                                            -- Try built-in clipboard table
                                                                                                                                                                                            if clipboard and type(clipboard) == "table" and clipboard.read then
                                                                                                                                                                                                local success, result = pcall(clipboard.read)
                                                                                                                                                                                                if success and result then
                                                                                                                                                                                                    clipboardText = result
                                                                                                                                                                                                    end
                                                                                                                                                                                                    end

                                                                                                                                                                                                    -- Try clipboard peripheral
                                                                                                                                                                                                    if clipboardText == "" and clipboardPeripheral and clipboardPeripheral.read then
                                                                                                                                                                                                        local success, result = pcall(clipboardPeripheral.read)
                                                                                                                                                                                                        if success and result then
                                                                                                                                                                                                            clipboardText = result
                                                                                                                                                                                                            end
                                                                                                                                                                                                            end

                                                                                                                                                                                                            -- Try alternative methods
                                                                                                                                                                                                            if clipboardText == "" then
                                                                                                                                                                                                                -- Try using shell.run to read clipboard (if available)
                                                                                                                                                                                                                local success, result = pcall(shell.run, "clipboard", "read")
                                                                                                                                                                                                                if success and result then
                                                                                                                                                                                                                    clipboardText = tostring(result)
                                                                                                                                                                                                                    end
                                                                                                                                                                                                                    end

                                                                                                                                                                                                                    return clipboardText
                                                                                                                                                                                                                    end

                                                                                                                                                                                                                    -- Paste clipboard at cursor position
                                                                                                                                                                                                                    local function pasteClipboard()
                                                                                                                                                                                                                    local pasteContent = {}

                                                                                                                                                                                                                    -- Try to get system clipboard
                                                                                                                                                                                                                    if hasClipboard then
                                                                                                                                                                                                                        local clipboardText = readSystemClipboard()
                                                                                                                                                                                                                        if clipboardText and clipboardText ~= "" then
                                                                                                                                                                                                                            -- Split by lines (handle both \n and \r\n)
                                                                                                                                                                                                                            for line in clipboardText:gmatch("([^\r\n]*)[\r\n]?") do
                                                                                                                                                                                                                                if line ~= "" then
                                                                                                                                                                                                                                    table.insert(pasteContent, line)
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    end

                                                                                                                                                                                                                                    -- Use internal clipboard if system clipboard is empty
                                                                                                                                                                                                                                    if #pasteContent == 0 then
                                                                                                                                                                                                                                        pasteContent = clipboard
                                                                                                                                                                                                                                        end

                                                                                                                                                                                                                                        if #pasteContent == 0 then
                                                                                                                                                                                                                                            updateMessage("Clipboard is empty")
                                                                                                                                                                                                                                            return
                                                                                                                                                                                                                                            end

                                                                                                                                                                                                                                            local line = lines[currentLine] or ""

                                                                                                                                                                                                                                            -- If we're pasting a single line, insert it at cursor position
                                                                                                                                                                                                                                            if #pasteContent == 1 then
                                                                                                                                                                                                                                                lines[currentLine] = line:sub(1, currentCol - 1) .. pasteContent[1] .. line:sub(currentCol)
                                                                                                                                                                                                                                                currentCol = currentCol + #pasteContent[1]
                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                    -- Multiple lines: split current line and insert all clipboard lines
                                                                                                                                                                                                                                                    local beforeCursor = line:sub(1, currentCol - 1)
                                                                                                                                                                                                                                                    local afterCursor = line:sub(currentCol)

                                                                                                                                                                                                                                                    -- Replace current line with first clipboard line + afterCursor
                                                                                                                                                                                                                                                    lines[currentLine] = beforeCursor .. pasteContent[1]

                                                                                                                                                                                                                                                    -- Insert remaining clipboard lines
                                                                                                                                                                                                                                                    for i = 2, #pasteContent do
                                                                                                                                                                                                                                                        table.insert(lines, currentLine + i - 1, pasteContent[i])
                                                                                                                                                                                                                                                        end

                                                                                                                                                                                                                                                        -- Add afterCursor to the last pasted line
                                                                                                                                                                                                                                                        local lastLine = currentLine + #pasteContent - 1
                                                                                                                                                                                                                                                        lines[lastLine] = lines[lastLine] .. afterCursor

                                                                                                                                                                                                                                                        -- Move cursor to end of pasted content
                                                                                                                                                                                                                                                        currentLine = lastLine
                                                                                                                                                                                                                                                        currentCol = #lines[lastLine] - #afterCursor + 1
                                                                                                                                                                                                                                                        end

                                                                                                                                                                                                                                                        dirty = true
                                                                                                                                                                                                                                                        updateMessage("Pasted " .. #pasteContent .. " lines")
                                                                                                                                                                                                                                                        end

                                                                                                                                                                                                                                                        -- Search function
                                                                                                                                                                                                                                                        local function search()
                                                                                                                                                                                                                                                        term.setCursorPos(1, h - 1)
                                                                                                                                                                                                                                                        term.setBackgroundColor(colorscheme.statusbar)
                                                                                                                                                                                                                                                        term.setTextColor(colorscheme.statusbarText)
                                                                                                                                                                                                                                                        term.clearLine()
                                                                                                                                                                                                                                                        term.write("Search: ")

                                                                                                                                                                                                                                                        local searchTerm = ""
                                                                                                                                                                                                                                                        local inputActive = true

                                                                                                                                                                                                                                                        while inputActive do
                                                                                                                                                                                                                                                            local event, p1 = os.pullEvent()

                                                                                                                                                                                                                                                            if event == "key" then
                                                                                                                                                                                                                                                                if p1 == keys.enter then
                                                                                                                                                                                                                                                                inputActive = false
                                                                                                                                                                                                                                                                elseif p1 == keys.backspace then
                                                                                                                                                                                                                                                                if #searchTerm > 0 then
                                                                                                                                                                                                                                                                searchTerm = searchTerm:sub(1, -2)
                                                                                                                                                                                                                                                                term.write("\b")
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif p1 == keys.c then
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                updateMessage("Search cancelled")
                                                                                                                                                                                                                                                                return
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif event == "char" then
                                                                                                                                                                                                                                                                searchTerm = searchTerm .. p1
                                                                                                                                                                                                                                                                term.write(p1)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                if searchTerm ~= "" then
                                                                                                                                                                                                                                                                for i = currentLine, #lines do
                                                                                                                                                                                                                                                                local pos = lines[i]:find(searchTerm, currentCol, true)
                                                                                                                                                                                                                                                                if pos then
                                                                                                                                                                                                                                                                currentLine = i
                                                                                                                                                                                                                                                                currentCol = pos
                                                                                                                                                                                                                                                                updateMessage("Found at line " .. i)
                                                                                                                                                                                                                                                                return
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                updateMessage("Not found: " .. searchTerm)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Replace function
                                                                                                                                                                                                                                                                local function replace()
                                                                                                                                                                                                                                                                term.setCursorPos(1, h - 1)
                                                                                                                                                                                                                                                                term.setBackgroundColor(colorscheme.statusbar)
                                                                                                                                                                                                                                                                term.setTextColor(colorscheme.statusbarText)
                                                                                                                                                                                                                                                                term.clearLine()
                                                                                                                                                                                                                                                                term.write("Replace: ")

                                                                                                                                                                                                                                                                local searchStr = ""
                                                                                                                                                                                                                                                                local inputActive = true

                                                                                                                                                                                                                                                                -- Get search string
                                                                                                                                                                                                                                                                while inputActive do
                                                                                                                                                                                                                                                                local event, p1 = os.pullEvent()

                                                                                                                                                                                                                                                                if event == "key" then
                                                                                                                                                                                                                                                                if p1 == keys.enter then
                                                                                                                                                                                                                                                                inputActive = false
                                                                                                                                                                                                                                                                elseif p1 == keys.backspace then
                                                                                                                                                                                                                                                                if #searchStr > 0 then
                                                                                                                                                                                                                                                                searchStr = searchStr:sub(1, -2)
                                                                                                                                                                                                                                                                term.write("\b")
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif p1 == keys.c then
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                updateMessage("Replace cancelled")
                                                                                                                                                                                                                                                                return
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif event == "char" then
                                                                                                                                                                                                                                                                searchStr = searchStr .. p1
                                                                                                                                                                                                                                                                term.write(p1)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                term.clearLine()
                                                                                                                                                                                                                                                                term.write("With: ")
                                                                                                                                                                                                                                                                local replaceStr = ""
                                                                                                                                                                                                                                                                inputActive = true

                                                                                                                                                                                                                                                                -- Get replace string
                                                                                                                                                                                                                                                                while inputActive do
                                                                                                                                                                                                                                                                local event, p1 = os.pullEvent()

                                                                                                                                                                                                                                                                if event == "key" then
                                                                                                                                                                                                                                                                if p1 == keys.enter then
                                                                                                                                                                                                                                                                inputActive = false
                                                                                                                                                                                                                                                                elseif p1 == keys.backspace then
                                                                                                                                                                                                                                                                if #replaceStr > 0 then
                                                                                                                                                                                                                                                                replaceStr = replaceStr:sub(1, -2)
                                                                                                                                                                                                                                                                term.write("\b")
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif p1 == keys.c then
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                updateMessage("Replace cancelled")
                                                                                                                                                                                                                                                                return
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif event == "char" then
                                                                                                                                                                                                                                                                replaceStr = replaceStr .. p1
                                                                                                                                                                                                                                                                term.write(p1)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Perform replacement
                                                                                                                                                                                                                                                                local count = 0
                                                                                                                                                                                                                                                                for i = 1, #lines do
                                                                                                                                                                                                                                                                local line = lines[i]
                                                                                                                                                                                                                                                                local newLine, replaced = line:gsub(searchStr, replaceStr)
                                                                                                                                                                                                                                                                if replaced > 0 then
                                                                                                                                                                                                                                                                lines[i] = newLine
                                                                                                                                                                                                                                                                count = count + replaced
                                                                                                                                                                                                                                                                dirty = true
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                updateMessage("Replaced " .. count .. " occurrences")
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Show help
                                                                                                                                                                                                                                                                local function showHelp()
                                                                                                                                                                                                                                                                mode = "help"
                                                                                                                                                                                                                                                                local helpText = {
                                                                                                                                                                                                                                                                "Rizer Editor Help",
                                                                                                                                                                                                                                                                "^X: Exit editor",
                                                                                                                                                                                                                                                                "^O: Save file",
                                                                                                                                                                                                                                                                "^W: Search text",
                                                                                                                                                                                                                                                                "^K: Cut selection or line",
                                                                                                                                                                                                                                                                "^U: Paste clipboard",
                                                                                                                                                                                                                                                                "^R: Replace text",
                                                                                                                                                                                                                                                                "^C: Cancel current operation",
                                                                                                                                                                                                                                                                "^A: Go to beginning of line",
                                                                                                                                                                                                                                                                "^E: Go to end of line",
                                                                                                                                                                                                                                                                "^^: Toggle selection mode",
                                                                                                                                                                                                                                                                "Arrow keys: Move cursor",
                                                                                                                                                                                                                                                                "Enter: New line",
                                                                                                                                                                                                                                                                "Backspace: Delete character or selection",
                                                                                                                                                                                                                                                                "Delete: Delete character at cursor",
                                                                                                                                                                                                                                                                "Page Up/Down: Scroll page",
                                                                                                                                                                                                                                                                "Home/End: Beginning/end of line",
                                                                                                                                                                                                                                                                "Mouse: Click and drag to select",
                                                                                                                                                                                                                                                                "",
                                                                                                                                                                                                                                                                "System clipboard: " .. (hasClipboard and "Enabled" or "Disabled"),
                                                                                                                                                                                                                                                                "Clipboard methods: " .. (hasClipboard and "Built-in/Peripheral" or "Internal only"),
                                                                                                                                                                                                                                                                "",
                                                                                                                                                                                                                                                                "Press any key to return to editor"
                                                                                                                                                                                                                                                                }

                                                                                                                                                                                                                                                                term.setBackgroundColor(colorscheme.background)
                                                                                                                                                                                                                                                                term.clear()
                                                                                                                                                                                                                                                                term.setCursorPos(1, 1)
                                                                                                                                                                                                                                                                term.setTextColor(colorscheme.text)

                                                                                                                                                                                                                                                                for i, line in ipairs(helpText) do
                                                                                                                                                                                                                                                                term.setCursorPos(1, i)
                                                                                                                                                                                                                                                                term.clearLine()
                                                                                                                                                                                                                                                                term.write(line)
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                os.pullEvent("key")
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Handle mouse click
                                                                                                                                                                                                                                                                local function handleMouseClick(button, x, y)
                                                                                                                                                                                                                                                                -- Check if click is in the text area
                                                                                                                                                                                                                                                                if y >= 3 and y <= h - 2 then
                                                                                                                                                                                                                                                                local clickedLine = topLine + y - 3
                                                                                                                                                                                                                                                                local clickedCol = x - 5

                                                                                                                                                                                                                                                                if clickedLine >= 1 and clickedLine <= #lines then
                                                                                                                                                                                                                                                                local line = lines[clickedLine] or ""
                                                                                                                                                                                                                                                                if clickedCol < 1 then
                                                                                                                                                                                                                                                                clickedCol = 1
                                                                                                                                                                                                                                                                elseif clickedCol > #line + 1 then
                                                                                                                                                                                                                                                                clickedCol = #line + 1
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Move cursor to clicked position
                                                                                                                                                                                                                                                                currentLine = clickedLine
                                                                                                                                                                                                                                                                currentCol = clickedCol

                                                                                                                                                                                                                                                                -- Start mouse selection
                                                                                                                                                                                                                                                                mouseSelecting = true
                                                                                                                                                                                                                                                                selection.active = true
                                                                                                                                                                                                                                                                selection.startLine = clickedLine
                                                                                                                                                                                                                                                                selection.startCol = clickedCol
                                                                                                                                                                                                                                                                selection.endLine = clickedLine
                                                                                                                                                                                                                                                                selection.endCol = clickedCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Handle mouse drag
                                                                                                                                                                                                                                                                local function handleMouseDrag(button, x, y)
                                                                                                                                                                                                                                                                if mouseSelecting and y >= 3 and y <= h - 2 then
                                                                                                                                                                                                                                                                local draggedLine = topLine + y - 3
                                                                                                                                                                                                                                                                local draggedCol = x - 5

                                                                                                                                                                                                                                                                if draggedLine >= 1 and draggedLine <= #lines then
                                                                                                                                                                                                                                                                local line = lines[draggedLine] or ""
                                                                                                                                                                                                                                                                if draggedCol < 1 then
                                                                                                                                                                                                                                                                draggedCol = 1
                                                                                                                                                                                                                                                                elseif draggedCol > #line + 1 then
                                                                                                                                                                                                                                                                draggedCol = #line + 1
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Update selection end position
                                                                                                                                                                                                                                                                selection.endLine = draggedLine
                                                                                                                                                                                                                                                                selection.endCol = draggedCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Handle mouse release
                                                                                                                                                                                                                                                                local function handleMouseRelease(button, x, y)
                                                                                                                                                                                                                                                                mouseSelecting = false
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Handle key input
                                                                                                                                                                                                                                                                local function handleKey(key)
                                                                                                                                                                                                                                                                -- Skip if this is a Ctrl key
                                                                                                                                                                                                                                                                if key == keys.leftCtrl or key == keys.rightCtrl then
                                                                                                                                                                                                                                                                return
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Navigation keys
                                                                                                                                                                                                                                                                if key == keys.up then
                                                                                                                                                                                                                                                                if currentLine > 1 then
                                                                                                                                                                                                                                                                currentLine = currentLine - 1
                                                                                                                                                                                                                                                                local line = lines[currentLine] or ""
                                                                                                                                                                                                                                                                if currentCol > #line + 1 then
                                                                                                                                                                                                                                                                currentCol = #line + 1
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endLine = currentLine
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys.down then
                                                                                                                                                                                                                                                                if currentLine < #lines then
                                                                                                                                                                                                                                                                currentLine = currentLine + 1
                                                                                                                                                                                                                                                                local line = lines[currentLine] or ""
                                                                                                                                                                                                                                                                if currentCol > #line + 1 then
                                                                                                                                                                                                                                                                currentCol = #line + 1
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endLine = currentLine
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys.left then
                                                                                                                                                                                                                                                                if currentCol > 1 then
                                                                                                                                                                                                                                                                currentCol = currentCol - 1

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif currentLine > 1 then
                                                                                                                                                                                                                                                                currentLine = currentLine - 1
                                                                                                                                                                                                                                                                currentCol = #(lines[currentLine] or "") + 1

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endLine = currentLine
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys.right then
                                                                                                                                                                                                                                                                local line = lines[currentLine] or ""
                                                                                                                                                                                                                                                                if currentCol <= #line then
                                                                                                                                                                                                                                                                currentCol = currentCol + 1

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif currentLine < #lines then
                                                                                                                                                                                                                                                                currentLine = currentLine + 1
                                                                                                                                                                                                                                                                currentCol = 1

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endLine = currentLine
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys.home then
                                                                                                                                                                                                                                                                currentCol = 1

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys["end"] then
                                                                                                                                                                                                                                                                currentCol = #(lines[currentLine] or "") + 1

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys.pageUp then
                                                                                                                                                                                                                                                                currentLine = math.max(1, currentLine - (h - 3))

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endLine = currentLine
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys.pageDown then
                                                                                                                                                                                                                                                                currentLine = math.min(#lines, currentLine + (h - 3))

                                                                                                                                                                                                                                                                -- Update selection if active
                                                                                                                                                                                                                                                                if selection.active and not mouseSelecting then
                                                                                                                                                                                                                                                                selection.endLine = currentLine
                                                                                                                                                                                                                                                                selection.endCol = currentCol
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Editing keys
                                                                                                                                                                                                                                                                elseif key == keys.enter then
                                                                                                                                                                                                                                                                local line = lines[currentLine] or ""
                                                                                                                                                                                                                                                                lines[currentLine] = line:sub(1, currentCol - 1)
                                                                                                                                                                                                                                                                table.insert(lines, currentLine + 1, line:sub(currentCol))
                                                                                                                                                                                                                                                                currentLine = currentLine + 1
                                                                                                                                                                                                                                                                currentCol = 1
                                                                                                                                                                                                                                                                dirty = true
                                                                                                                                                                                                                                                                elseif key == keys.backspace then
                                                                                                                                                                                                                                                                if selection.active then
                                                                                                                                                                                                                                                                -- Delete selection if active
                                                                                                                                                                                                                                                                if deleteSelection() then
                                                                                                                                                                                                                                                                updateMessage("Deleted selection")
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif currentCol > 1 then
                                                                                                                                                                                                                                                                local line = lines[currentLine] or ""
                                                                                                                                                                                                                                                                lines[currentLine] = line:sub(1, currentCol - 2) .. line:sub(currentCol)
                                                                                                                                                                                                                                                                currentCol = currentCol - 1
                                                                                                                                                                                                                                                                dirty = true
                                                                                                                                                                                                                                                                elseif currentLine > 1 then
                                                                                                                                                                                                                                                                local prevLine = lines[currentLine - 1] or ""
                                                                                                                                                                                                                                                                local currentLineText = lines[currentLine] or ""
                                                                                                                                                                                                                                                                lines[currentLine - 1] = prevLine .. currentLineText
                                                                                                                                                                                                                                                                table.remove(lines, currentLine)
                                                                                                                                                                                                                                                                currentLine = currentLine - 1
                                                                                                                                                                                                                                                                currentCol = #prevLine + 1
                                                                                                                                                                                                                                                                dirty = true
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif key == keys.delete then
                                                                                                                                                                                                                                                                if selection.active then
                                                                                                                                                                                                                                                                -- Delete selection if active
                                                                                                                                                                                                                                                                if deleteSelection() then
                                                                                                                                                                                                                                                                updateMessage("Deleted selection")
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                                local line = lines[currentLine] or ""
                                                                                                                                                                                                                                                                if currentCol <= #line then
                                                                                                                                                                                                                                                                lines[currentLine] = line:sub(1, currentCol - 1) .. line:sub(currentCol + 1)
                                                                                                                                                                                                                                                                dirty = true
                                                                                                                                                                                                                                                                elseif currentLine < #lines then
                                                                                                                                                                                                                                                                local nextLine = lines[currentLine + 1] or ""
                                                                                                                                                                                                                                                                lines[currentLine] = line .. nextLine
                                                                                                                                                                                                                                                                table.remove(lines, currentLine + 1)
                                                                                                                                                                                                                                                                dirty = true
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Control keys - only if Ctrl is held
                                                                                                                                                                                                                                                                elseif ctrlHeld and ctrlMap[key] then
                                                                                                                                                                                                                                                                local action = ctrlMap[key]
                                                                                                                                                                                                                                                                if action == "exit" then
                                                                                                                                                                                                                                                                if dirty then
                                                                                                                                                                                                                                                                mode = "exitConfirm"
                                                                                                                                                                                                                                                                updateMessage("Save changes? (Y/N/C)")
                                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                                running = false
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif action == "save" then
                                                                                                                                                                                                                                                                saveFile()
                                                                                                                                                                                                                                                                elseif action == "search" then
                                                                                                                                                                                                                                                                mode = "search"
                                                                                                                                                                                                                                                                search()
                                                                                                                                                                                                                                                                elseif action == "cut" then
                                                                                                                                                                                                                                                                cutSelection()
                                                                                                                                                                                                                                                                elseif action == "paste" then
                                                                                                                                                                                                                                                                pasteClipboard()
                                                                                                                                                                                                                                                                elseif action == "cancel" then
                                                                                                                                                                                                                                                                if mode ~= "normal" then
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                updateMessage("Cancelled")
                                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                                updateMessage("Line " .. currentLine .. ", Col " .. currentCol)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif action == "help" then
                                                                                                                                                                                                                                                                showHelp()
                                                                                                                                                                                                                                                                elseif action == "replace" then
                                                                                                                                                                                                                                                                mode = "replace"
                                                                                                                                                                                                                                                                replace()
                                                                                                                                                                                                                                                                elseif action == "home" then
                                                                                                                                                                                                                                                                currentCol = 1
                                                                                                                                                                                                                                                                elseif action == "end" then
                                                                                                                                                                                                                                                                currentCol = #(lines[currentLine] or "") + 1
                                                                                                                                                                                                                                                                elseif action == "select" then
                                                                                                                                                                                                                                                                toggleSelection()
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Handle character input
                                                                                                                                                                                                                                                                local function handleChar(char)
                                                                                                                                                                                                                                                                if mode == "normal" then
                                                                                                                                                                                                                                                                if selection.active then
                                                                                                                                                                                                                                                                -- If there's a selection, replace it with the character
                                                                                                                                                                                                                                                                deleteSelection()
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                local line = lines[currentLine] or ""
                                                                                                                                                                                                                                                                lines[currentLine] = line:sub(1, currentCol - 1) .. char .. line:sub(currentCol)
                                                                                                                                                                                                                                                                currentCol = currentCol + 1
                                                                                                                                                                                                                                                                dirty = true
                                                                                                                                                                                                                                                                elseif mode == "exitConfirm" then
                                                                                                                                                                                                                                                                if char:lower() == "y" then
                                                                                                                                                                                                                                                                saveFile()
                                                                                                                                                                                                                                                                running = false
                                                                                                                                                                                                                                                                elseif char:lower() == "n" then
                                                                                                                                                                                                                                                                running = false
                                                                                                                                                                                                                                                                elseif char:lower() == "c" then
                                                                                                                                                                                                                                                                mode = "normal"
                                                                                                                                                                                                                                                                updateMessage("")
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Main loop
                                                                                                                                                                                                                                                                local function main()
                                                                                                                                                                                                                                                                init()

                                                                                                                                                                                                                                                                if not running then
                                                                                                                                                                                                                                                                return
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Show clipboard status
                                                                                                                                                                                                                                                                local clipboardStatus = "System clipboard: "
                                                                                                                                                                                                                                                                if hasClipboard then
                                                                                                                                                                                                                                                                clipboardStatus = clipboardStatus .. "Enabled ("
                                                                                                                                                                                                                                                                if clipboard and type(clipboard) == "table" then
                                                                                                                                                                                                                                                                clipboardStatus = clipboardStatus .. "Built-in"
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                if clipboardPeripheral then
                                                                                                                                                                                                                                                                if clipboardStatus:sub(-1) ~= "(" then
                                                                                                                                                                                                                                                                clipboardStatus = clipboardStatus .. "/"
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                clipboardStatus = clipboardStatus .. "Peripheral"
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                clipboardStatus = clipboardStatus .. ")"
                                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                                clipboardStatus = clipboardStatus .. "Disabled - Using internal clipboard only"
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                updateMessage(clipboardStatus)

                                                                                                                                                                                                                                                                while running do
                                                                                                                                                                                                                                                                drawScreen()

                                                                                                                                                                                                                                                                -- Update message timer
                                                                                                                                                                                                                                                                if messageTimer > 0 then
                                                                                                                                                                                                                                                                messageTimer = messageTimer - 1
                                                                                                                                                                                                                                                                if messageTimer == 0 then
                                                                                                                                                                                                                                                                message = ""
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                -- Adjust view
                                                                                                                                                                                                                                                                if currentLine < topLine then
                                                                                                                                                                                                                                                                topLine = currentLine
                                                                                                                                                                                                                                                                elseif currentLine >= topLine + h - 3 then
                                                                                                                                                                                                                                                                topLine = currentLine - (h - 3) + 1
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                local event, p1, p2, p3 = os.pullEvent()

                                                                                                                                                                                                                                                                if event == "key" then
                                                                                                                                                                                                                                                                -- Track Ctrl key state
                                                                                                                                                                                                                                                                if p1 == keys.leftCtrl or p1 == keys.rightCtrl then
                                                                                                                                                                                                                                                                ctrlHeld = true
                                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                                handleKey(p1)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif event == "key_up" then
                                                                                                                                                                                                                                                                -- Track Ctrl key release
                                                                                                                                                                                                                                                                if p1 == keys.leftCtrl or p1 == keys.rightCtrl then
                                                                                                                                                                                                                                                                ctrlHeld = false
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                elseif event == "char" then
                                                                                                                                                                                                                                                                handleChar(p1)
                                                                                                                                                                                                                                                                elseif event == "mouse_click" then
                                                                                                                                                                                                                                                                handleMouseClick(p1, p2, p3)
                                                                                                                                                                                                                                                                elseif event == "mouse_drag" then
                                                                                                                                                                                                                                                                handleMouseDrag(p1, p2, p3)
                                                                                                                                                                                                                                                                elseif event == "mouse_up" then
                                                                                                                                                                                                                                                                handleMouseRelease(p1, p2, p3)
                                                                                                                                                                                                                                                                elseif event == "term_resize" then
                                                                                                                                                                                                                                                                w, h = term.getSize()
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                term.setBackgroundColor(colorscheme.background)
                                                                                                                                                                                                                                                                term.clear()
                                                                                                                                                                                                                                                                term.setCursorPos(1, 1)
                                                                                                                                                                                                                                                                term.setTextColor(colorscheme.text)
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                main()
]]

-- Write rizer.lua to /bin
local path = "/bin/rizer"
if fs.exists(path) then fs.delete(path) end
local f = fs.open(path, "w")
f.write(rizer_content)
f.close()

