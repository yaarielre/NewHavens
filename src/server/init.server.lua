--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
Remotes.Init()

local CombatService = require(script.Services.CombatService)
CombatService.Init()
