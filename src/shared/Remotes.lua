--!strict
-- Punto único de acceso a los RemoteEvents del juego. El servidor crea la
-- carpeta y los remotes; el cliente solo los espera (WaitForChild).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local FOLDER_NAME = "Remotes"

local EVENT_NAMES = {
	"RequestAttack",
	"AttackResult",
	"RequestDodge",
	"DodgeResult",
	"RequestBlock",
	"BlockResult",
}

function Remotes.GetFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end

	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.Get(name: string): RemoteEvent
	local folder = Remotes.GetFolder()

	if RunService:IsServer() then
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		return remote :: RemoteEvent
	end

	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.Init()
	assert(RunService:IsServer(), "Remotes.Init solo debe llamarse desde el servidor")
	for _, name in EVENT_NAMES do
		Remotes.Get(name)
	end
end

return Remotes
