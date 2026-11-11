AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/Humans/Group03/male_07.mdl")
    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 76))
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(true)

    local sequence = self:LookupSequence("idle_all_01")
    if sequence < 0 then sequence = self:LookupSequence("idle_all") end
    if sequence >= 0 then
        self:ResetSequence(sequence)
        self:SetPlaybackRate(0)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if NYFoodShop and isfunction(NYFoodShop.Open) then
        NYFoodShop.Open(activator, self)
    else
        activator:ChatPrint("Магазин пока загружается. Попробуй через секунду.")
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end
