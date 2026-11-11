if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_smallconsumable"
SWEP.PrintName = "Газировка"
SWEP.Category = "N.Y. Tribeca"
SWEP.Spawnable = false
SWEP.AdminOnly = true
SWEP.NYFoodShopItem = "drink_fos"
SWEP.NYFoodShopModel = "models/jorddrink/foscan01a.mdl"

function SWEP:InitializeAdd()
    if self.BaseClass and isfunction(self.BaseClass.InitializeAdd) then
        self.BaseClass.InitializeAdd(self)
    end
    self:SetModel(self.NYFoodShopModel)
    if isfunction(self.SetCurModel) then self:SetCurModel(self.NYFoodShopModel) end
    self.WorldModel = self.NYFoodShopModel
    self.Eating = 5
    self.CDEating = 0
end
