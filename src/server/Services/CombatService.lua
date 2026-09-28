--!strict
-- Combate en tiempo real con validación 100% en servidor: el cliente solo pide
-- ("RequestAttack"/"RequestDodge"/"RequestBlock"), el servidor decide si vale.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tags = require(ReplicatedStorage.Shared.Tags)
local WeaponConfigs = require(ReplicatedStorage.Shared.Config.Weapons)
local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)

type PlayerCombatState = {
	ComboIndex: number,
	LastAttackTime: number,
	LastDodgeTime: number,
	Stamina: number,
	IsBlocking: boolean,
	BlockStartTime: number,
	InvulnerableUntil: number,
	StunnedUntil: number,
}

local CombatService = {}

local playerStates: { [Player]: PlayerCombatState } = {}
local DEFAULT_WEAPON = "Sword"

local function getState(player: Player): PlayerCombatState
	local state = playerStates[player]
	if not state then
		state = {
			ComboIndex = 0,
			LastAttackTime = 0,
			LastDodgeTime = -math.huge,
			Stamina = CombatConfig.MaxStamina,
			IsBlocking = false,
			BlockStartTime = 0,
			InvulnerableUntil = 0,
			StunnedUntil = 0,
		}
		playerStates[player] = state
	end
	return state
end

local function isAlive(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- Devuelve los Model con tag Damageable dentro del alcance y el cono frontal
-- del atacante. No incluye al propio atacante.
local function findTargetsInCone(attacker: Model, origin: CFrame, range: number, halfAngleDeg: number): { Model }
	local hits = {}
	local halfAngleRad = math.rad(halfAngleDeg)
	local forward = origin.LookVector

	for _, instance in CollectionService:GetTagged(Tags.Damageable) do
		if instance:IsA("Model") and instance ~= attacker then
			local root = instance:FindFirstChild("HumanoidRootPart")
			local humanoid = instance:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local offset = root.Position - origin.Position
				local distance = offset.Magnitude
				if distance <= range then
					local angle = 0
					if distance > 1e-3 then
						angle = math.acos(math.clamp(forward:Dot(offset.Unit), -1, 1))
					end
					if angle <= halfAngleRad then
						table.insert(hits, instance)
					end
				end
			end
		end
	end

	return hits
end

local function onRequestAttack(player: Player)
	if not isAlive(player) then
		return
	end

	local state = getState(player)
	local now = os.clock()

	if now < state.StunnedUntil then
		return
	end

	local weapon = WeaponConfigs[DEFAULT_WEAPON]
	local timeSinceLastAttack = now - state.LastAttackTime

	if timeSinceLastAttack < weapon.HitCooldown then
		-- Ataque más rápido de lo posible: ignorar (input duplicado o exploit).
		return
	end

	if timeSinceLastAttack > weapon.ComboWindow then
		state.ComboIndex = 0
	end

	state.ComboIndex = (state.ComboIndex % weapon.ComboHits) + 1
	state.LastAttackTime = now

	local character = player.Character :: Model
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local targets = findTargetsInCone(character, root.CFrame, weapon.Range, weapon.AttackAngle)

	for _, target in targets do
		local humanoid = target:FindFirstChildOfClass("Humanoid") :: Humanoid
		humanoid:TakeDamage(weapon.BaseDamage)
	end

	Remotes.Get("AttackResult"):FireClient(player, {
		ComboIndex = state.ComboIndex,
		HitCount = #targets,
	})
end

local function onRequestDodge(player: Player)
	if not isAlive(player) then
		return
	end

	local state = getState(player)
	local now = os.clock()

	if now - state.LastDodgeTime < CombatConfig.DodgeCooldown then
		return
	end

	if state.Stamina < CombatConfig.DodgeCost then
		return
	end

	state.Stamina -= CombatConfig.DodgeCost
	state.LastDodgeTime = now
	state.InvulnerableUntil = now + CombatConfig.DodgeDuration

	Remotes.Get("DodgeResult"):FireClient(player, true)
end

local function onRequestBlock(player: Player, isBlocking: unknown)
	if not isAlive(player) then
		return
	end
	if typeof(isBlocking) ~= "boolean" then
		return
	end

	local state = getState(player)
	state.IsBlocking = isBlocking
	if isBlocking then
		state.BlockStartTime = os.clock()
	end

	Remotes.Get("BlockResult"):FireClient(player, isBlocking)
end

-- API pública para que otros servicios (ej. futuro EnemyAIService) resuelvan
-- daño a jugadores respetando i-frames de esquive y bloqueo/parry.
function CombatService.DamagePlayer(player: Player, amount: number)
	if not isAlive(player) then
		return
	end

	local state = getState(player)
	local now = os.clock()

	if now < state.InvulnerableUntil then
		return -- i-frames de esquive
	end

	local finalAmount = amount
	if state.IsBlocking then
		if now - state.BlockStartTime <= CombatConfig.ParryWindow then
			finalAmount = 0
			-- TODO: cuando exista EnemyAIService, aturdir al atacante
			-- CombatConfig.ParryStunDuration segundos.
		else
			finalAmount *= (1 - CombatConfig.BlockDamageReduction)
		end
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(finalAmount)
	end
end

function CombatService.Init()
	Remotes.Get("RequestAttack").OnServerEvent:Connect(function(player)
		onRequestAttack(player)
	end)

	Remotes.Get("RequestDodge").OnServerEvent:Connect(function(player)
		onRequestDodge(player)
	end)

	Remotes.Get("RequestBlock").OnServerEvent:Connect(function(player, isBlocking)
		onRequestBlock(player, isBlocking)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerStates[player] = nil
	end)

	RunService.Heartbeat:Connect(function(deltaTime: number)
		for _, state in playerStates do
			if state.Stamina < CombatConfig.MaxStamina then
				state.Stamina =
					math.min(CombatConfig.MaxStamina, state.Stamina + CombatConfig.StaminaRegenPerSecond * deltaTime)
			end
		end
	end)
end

return CombatService
