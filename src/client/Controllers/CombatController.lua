--!strict
-- Traduce input (click/tap, Q, F) a pedidos al servidor y reproduce el
-- feedback que el servidor confirma. Nunca decide daño ni estados por su cuenta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CombatController = {}

local isBlocking = false

local function requestAttack()
	Remotes.Get("RequestAttack"):FireServer()
end

local function requestDodge()
	Remotes.Get("RequestDodge"):FireServer()
end

local function setBlocking(value: boolean)
	if isBlocking == value then
		return
	end
	isBlocking = value
	Remotes.Get("RequestBlock"):FireServer(value)
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		requestAttack()
	elseif input.KeyCode == Enum.KeyCode.Q then
		requestDodge()
	elseif input.KeyCode == Enum.KeyCode.F then
		setBlocking(true)
	end
end

local function onInputEnded(input: InputObject, _gameProcessed: boolean)
	if input.KeyCode == Enum.KeyCode.F then
		setBlocking(false)
	end
end

function CombatController.Init()
	Remotes.Get("AttackResult").OnClientEvent:Connect(function(result: { ComboIndex: number, HitCount: number })
		-- TODO: reproducir animación del golpe result.ComboIndex y hitspark si result.HitCount > 0.
	end)

	Remotes.Get("DodgeResult").OnClientEvent:Connect(function(_success: boolean)
		-- TODO: reproducir animación de esquive.
	end)

	Remotes.Get("BlockResult").OnClientEvent:Connect(function(_blocking: boolean)
		-- TODO: reproducir animación de guardia/idle de bloqueo.
	end)

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
end

return CombatController
