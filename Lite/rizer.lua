-- OZP Installer: install RIZER text editor

local fs = fs or require("filesystem")


-- RIZER content
local rizer_content = [[
OZLE
-- RIZER: simple text editor
local args = {...}
if #args < 1 then
    print("Usage: rizer <filename>")
    return
end

local filename = args[1]

local fs = fs or require("filesystem")

-- Load existing file
local lines = {}
if fs.exists(filename) then
    local f = fs.open(filename, "r")
    for line in f.readAll():gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    f.close()
end

print("Editing "..filename..". Type ':w' to save and ':q' to quit.")

while true do
    io.write("> ")
    local input = read()
    if input == ":w" then
        local f = fs.open(filename, "w")
        for _, line in ipairs(lines) do
            f.write(line.."\n")
        end
        f.close()
        print("Saved "..filename)
    elseif input == ":q" then
        break
    else
        table.insert(lines, input)
    end
end
]]

-- Write rizer.lua to /bin
local path = "/bin/rizer"
if fs.exists(path) then fs.delete(path) end

local f = fs.open(path, "w")
f.write(rizer_content)
f.close()

