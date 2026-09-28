--!strict
-- Datos puros de armas. El agente/balanceador cambia números aquí, nunca en
-- CombatService.

export type WeaponConfig = {
	Name: string,
	ComboHits: number,
	BaseDamage: number,
	Range: number, -- studs
	AttackAngle: number, -- grados, medio-ángulo del cono frontal de golpe
	ComboWindow: number, -- segundos entre golpes para mantener el combo
	HitCooldown: number, -- segundos mínimos entre un golpe y el siguiente
	AnimationIds: { string }, -- una animación por golpe del combo (TODO: llenar cuando haya rig/anims)
}

local Weapons: { [string]: WeaponConfig } = {
	Sword = {
		Name = "Sword",
		ComboHits = 4,
		BaseDamage = 8,
		Range = 6,
		AttackAngle = 60,
		ComboWindow = 1.2,
		HitCooldown = 0.35,
		AnimationIds = { "", "", "", "" },
	},
}

return Weapons
