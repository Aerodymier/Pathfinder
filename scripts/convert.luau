--selene: allow(incorrect_standard_library_use)
local remodel = require("./remodel")

local game = remodel.readPlaceFile("../Pathfinder.rbxl")

local Workspace = game.Workspace
local Lighting = game.Lighting

local function handleLoops(object, folderName)
    if object.ClassName == "Folder" then
        local dir = "../src/" .. folderName .. "/" .. object.Name
        remodel.createDirAll(dir)
        for _, v in pairs(object:GetChildren()) do
            handleLoops(v, dir)
        end
    else
        local dir = "../src/" .. folderName .. "/" .. object.Name

        remodel.writeModelFile(object, dir .. ".rbxmx")
    end
end

for _, model in ipairs(Workspace:GetChildren()) do
    remodel.writeModelFile("../src/workspace/" .. model.Name .. ".rbxmx", model)
end

for _, model in ipairs(Lighting:GetChildren()) do
    remodel.writeModelFile("../src/lighting/" .. model.Name .. ".rbxmx", model)
end