print("Installing file io...")
-- OZP Installer: fully functional command scripts
local fs = fs or require("filesystem") -- just in case

local files = {
    ["shutdown"] = [[
term.clear()
os.shutdown()
]],
    ["reboot"] = [[
term.clear()
os.reboot()
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
