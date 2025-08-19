print("Installing file io...")
-- OZP Installer: fully functional command scripts
local fs = fs or require("filesystem") -- just in case

local files = {
    ["rm"] = [[

-- remove a file
local path = ...
if not path then print("Usage: rm <path>") return end
if fs.exists(path) then
    fs.delete(path)
    print("Deleted "..path)
else
    print("File not found: "..path)
end
]],
    ["cp"] = [[

-- copy a file
local src, dest = ...
if not src or not dest then print("Usage: cp <source> <dest>") return end
if fs.exists(src) then
    local inFile = fs.open(src, "r")
    local outFile = fs.open(dest, "w")
    outFile.write(inFile.readAll())
    inFile.close()
    outFile.close()
    print("Copied "..src.." to "..dest)
else
    print("Source not found: "..src)
end
]],
    ["move"] = [[

-- move a file
local src, dest = ...
if not src or not dest then print("Usage: move <source> <dest>") return end
if fs.exists(src) then
    fs.move(src, dest)
    print("Moved "..src.." to "..dest)
else
    print("Source not found: "..src)
end
]],
    ["mkdir"] = [[

-- make directory
local path = ...
if not path then print("Usage: mkdir <path>") return end
if not fs.exists(path) then
    fs.makeDir(path)
    print("Created directory "..path)
else
    print("Directory already exists: "..path)
end
]],
    ["mkfile"] = [[

-- create empty file
local path = ...
if not path then print("Usage: mkfile <path>") return end
if not fs.exists(path) then
    local f = fs.open(path, "w")
    f.write("")
    f.close()
    print("Created file "..path)
else
    print("File already exists: "..path)
end
]],
    ["ls"] = [[
local files = fs.list(".")
for _, f in ipairs(files) do
    if not fs.isDir(f) then
    print(f)
    else
    term.setTextColor(colors.purple)
    print(f)
    term.setTextColor(color.white)
end 
end
]],
}

-- Ensure /bin exists
if not fs.exists("/bin") then
    fs.makeDir("/bin")
    print("Created /bin directory")
end

-- Write the files
for name, content in pairs(files) do
    local path = "/bin/"..name
    if fs.exists(path) then fs.delete(path) end
    local f = fs.open(path, "w")
    f.write(content)
    f.close()
    print("Installed "..path)
end

