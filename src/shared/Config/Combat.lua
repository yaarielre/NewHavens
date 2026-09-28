--!strict
-- Parámetros generales de combate (esquive, bloqueo, stamina). Datos puros.

export type CombatConfig = {
	DodgeCost: number,
	DodgeCooldown: number,
	DodgeDuration: number, -- ventana de i-frames tras esquivar
	MaxStamina: number,
	StaminaRegenPerSecond: number,
	BlockDamageReduction: number, -- 0..1, fracción de daño bloqueada
	ParryWindow: number, -- segundos tras iniciar bloqueo en los que un golpe es parry
	ParryStunDuration: number,
}

local CombatConfig: CombatConfig = {
	DodgeCost = 25,
	DodgeCooldown = 0.8,
	DodgeDuration = 0.35,
	MaxStamina = 100,
	StaminaRegenPerSecond = 15,
	BlockDamageReduction = 0.7,
	ParryWindow = 0.25,
	ParryStunDuration = 1.5,
}

return CombatConfig
