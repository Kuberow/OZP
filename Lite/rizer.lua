-- OZP Installer: Nano-style RIZER editor (corrected)
local fs = fs or require("filesystem")
local term = term or require("term")

-- Ensure /bin exists
if not fs.exists("/bin") then
    fs.makeDir("/bin")
    print("Created /bin directory")
end

-- RIZER content (Nano-style)
local rizer_content = [[
OZLE
-- RIZER: Nano-style text editor
local args = {...}
if #args < 1 then
    print("Usage: rizer <filename>")
    return
end

local filename = args[1]
local fs = fs or require("filesystem")
local term = term or require("term")

local lines = {}
if fs.exists(filename) then
    local f = fs.open(filename, "r")
    local content = f.readAll()
    f.close()
    for line in string.gmatch(content, "[^\r\n]+") do
        table.insert(lines, line)
    end
end

local cursorX, cursorY = 1, 1
local scroll = 0

local function draw()
    term.clear()
    local w, h = term.getSize()
    for i = 1, math.min(#lines - scroll, h - 1) do
        term.setCursorPos(1, i)
        io.write(lines[i + scroll] or "")
    end
    term.setCursorPos(cursorX, cursorY - scroll)
end

if #lines == 0 then table.insert(lines, "") end

while true do
    draw()
    local event, key = os.pullEvent("key")
    if key == keys.left and cursorX > 1 then
        cursorX = cursorX - 1
    elseif key == keys.right then
        cursorX = cursorX + 1
    elseif key == keys.up and cursorY > 1 then
        cursorY = cursorY - 1
        if cursorY - scroll < 1 and scroll > 0 then scroll = scroll - 1 end
    elseif key == keys.down then
        cursorY = math.min(cursorY + 1, #lines)
        local w, h = term.getSize()
        if cursorY - scroll > h - 1 then scroll = scroll + 1 end
    elseif key == keys.backspace then
        local line = lines[cursorY]
        if cursorX > 1 then
            lines[cursorY] = line:sub(1, cursorX-2)..line:sub(cursorX)
            cursorX = cursorX - 1
        elseif cursorY > 1 then
            local prev = lines[cursorY-1]
            cursorX = #prev + 1
            lines[cursorY-1] = prev .. line
            table.remove(lines, cursorY)
            cursorY = cursorY - 1
        end
    elseif key == keys.enter then
        local line = lines[cursorY]
        local newLine = line:sub(cursorX)
        lines[cursorY] = line:sub(1, cursorX-1)
        table.insert(lines, cursorY + 1, newLine)
        cursorY = cursorY + 1
        cursorX = 1
    elseif key == keys.leftShift or key == keys.rightShift then
        -- ignore
    elseif key == keys.ctrl then
        local _, subKey = os.pullEvent("key")
        if subKey == keys.s then
            local f = fs.open(filename, "w")
            for _, line in ipairs(lines) do
                f.write(line.."\n")
            end
            f.close()
            print("\nSaved "..filename)
        elseif subKey == keys.q then
            break
        end
    else
        local char = keys.getName(key)
        if #char == 1 then
            local line = lines[cursorY]
            lines[cursorY] = line:sub(1, cursorX-1)..char..line:sub(cursorX)
            cursorX = cursorX + 1
        end
    end
end
]]

-- Write rizer.lua to /bin
local path = "/bin/rizer.lua"
if fs.exists(path) then fs.delete(path) end
local f = fs.open(path, "w")
f.write(rizer_content)
f.close()

print("Nano-style RIZER installed in /bin/rizer.lua! You can now run:")
print("rizer <filename>")
