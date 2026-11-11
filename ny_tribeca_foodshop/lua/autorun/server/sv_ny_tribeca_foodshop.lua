if not SERVER then return end

AddCSLuaFile("autorun/client/cl_ny_tribeca_foodshop.lua")
resource.AddSingleFile("resource/fonts/bahnschrift.ttf")

NYFoodShop = NYFoodShop or {}
local NET = {
    open = "NYFoodShop.Open",
    action = "NYFoodShop.Action",
    update = "NYFoodShop.Update",
    notify = "NYFoodShop.Notify"
}
for _, name in pairs(NET) do util.AddNetworkString(name) end

local VENDOR_CLASS = "ny_tribeca_food_vendor"
local USE_RADIUS = 190

local ITEMS = {
    {id="big_burger", category="food", name="Бургер в упаковке", desc="Сытный перекус", model="models/jordfood/canned_burger.mdl", price=12, hunger=28, thirst=0, weaponClass="weapon_nyfood_big_burger"},
    {id="water_bottle", category="water", name="Бутылка воды", desc="Чистая питьевая вода", model="models/jorddrink/the_bottle_of_water.mdl", price=2, hunger=0, thirst=36, weaponClass="weapon_nyfood_water_bottle"},
    {id="milk", category="water", name="Молоко", desc="Питательный напиток", model="models/foodnhouseholditems/milk.mdl", price=4, hunger=5, thirst=24, weaponClass="weapon_nyfood_milk"},
    {id="canned_food", category="food", name="Консервы", desc="Долго хранящийся обед", model="models/jordfood/can.mdl", price=8, hunger=30, thirst=0, weaponClass="weapon_nyfood_canned_food"},
    {id="juice_big", category="water", name="Сок, большая упаковка", desc="Фруктовый сок", model="models/foodnhouseholditems/juice.mdl", price=4, hunger=2, thirst=28, weaponClass="weapon_nyfood_juice_big"},
    {id="cola_big", category="water", name="Кола, большая бутылка", desc="Сладкая газировка", model="models/foodnhouseholditems/cola.mdl", price=4, hunger=0, thirst=18, weaponClass="weapon_nyfood_cola_big"},
    {id="baguette", category="food", name="Багет", desc="Свежий хлеб", model="models/foodnhouseholditems/bagette.mdl", price=6, hunger=24, thirst=0, weaponClass="weapon_nyfood_baguette"},
    {id="chips_tube", category="food", name="Чипсы в тубе", desc="Картофельные чипсы", model="models/jordfood/prongleclosedfilledgreen.mdl", price=5, hunger=14, thirst=0, weaponClass="weapon_nyfood_chips_tube"},

    {id="drink_7up", category="water", name="7UP", desc="Лимонная газировка", model="models/jorddrink/7upcan01a.mdl", price=2, hunger=0, thirst=14, weaponClass="weapon_nyfood_drink_7up"},
    {id="drink_barq", category="water", name="Barq's Root Beer", desc="Газировка в банке", model="models/jorddrink/barqcan1a.mdl", price=2, hunger=0, thirst=14, weaponClass="weapon_nyfood_drink_barq"},
    {id="drink_cola", category="water", name="Кола", desc="Банка колы", model="models/jorddrink/cozcan01a.mdl", price=2, hunger=0, thirst=14, weaponClass="weapon_nyfood_drink_cola"},
    {id="drink_crush", category="water", name="Апельсиновая газировка", desc="Сладкая газировка", model="models/jorddrink/crucan01a.mdl", price=2, hunger=0, thirst=13, weaponClass="weapon_nyfood_drink_crush"},
    {id="drink_mountain", category="water", name="Mountain Dew", desc="Цитрусовая газировка", model="models/jorddrink/dewcan01a.mdl", price=2, hunger=0, thirst=13, weaponClass="weapon_nyfood_drink_mountain"},
    {id="drink_fos", category="water", name="Газировка", desc="Сладкая газировка", model="models/jorddrink/foscan01a.mdl", price=2, hunger=0, thirst=13, weaponClass="weapon_nyfood_drink_fos"},
    {id="drink_hi", category="water", name="Hi-C", desc="Фруктовый напиток", model="models/jorddrink/heican01a.mdl", price=2, hunger=0, thirst=15, weaponClass="weapon_nyfood_drink_hi"},
    {id="drink_mong", category="water", name="Энергетик", desc="Банка энергетического напитка", model="models/jorddrink/mongcan1a.mdl", price=3, hunger=0, thirst=10, weaponClass="weapon_nyfood_drink_mong"},
    {id="drink_pepsi", category="water", name="Пепси", desc="Банка колы", model="models/jorddrink/pepcan01a.mdl", price=2, hunger=0, thirst=14, weaponClass="weapon_nyfood_drink_pepsi"},
    {id="drink_red", category="water", name="Энергетик", desc="Небольшая банка энергетика", model="models/jorddrink/redcan01a.mdl", price=3, hunger=0, thirst=10, weaponClass="weapon_nyfood_drink_red"},
    {id="drink_sprite", category="water", name="Sprite", desc="Лимонно-лаймовая газировка", model="models/jorddrink/sprcan01a.mdl", price=2, hunger=0, thirst=14, weaponClass="weapon_nyfood_drink_sprite"},
    {id="tuna", category="food", name="Тунец", desc="Консервы с тунцом", model="models/jordfood/atun.mdl", price=7, hunger=24, thirst=0, weaponClass="weapon_nyfood_tuna"},
    {id="chips_fritos", category="food", name="Кукурузные чипсы", desc="Небольшая пачка снеков", model="models/foodnhouseholditems/chipsfritos.mdl", price=3, hunger=10, thirst=0, weaponClass="weapon_nyfood_chips_fritos"},
    {id="chips_lays_1", category="food", name="Чипсы Lay's", desc="Небольшая пачка снеков", model="models/foodnhouseholditems/chipslays3.mdl", price=3, hunger=10, thirst=0, weaponClass="weapon_nyfood_chips_lays_1"},
    {id="chips_lays_2", category="food", name="Чипсы Lay's, большая пачка", desc="Большая пачка снеков", model="models/foodnhouseholditems/chipslays5.mdl", price=5, hunger=15, thirst=0, weaponClass="weapon_nyfood_chips_lays_2"},
    {id="juice_small", category="water", name="Сок", desc="Фруктовый сок", model="models/foodnhouseholditems/juicesmall.mdl", price=2, hunger=1, thirst=18, weaponClass="weapon_nyfood_juice_small"},
    {id="burger_box", category="food", name="Бургер навынос", desc="Готовый бургер", model="models/foodnhouseholditems/mcdburgerbox.mdl", price=11, hunger=32, thirst=0, weaponClass="weapon_nyfood_burger_box"},

    {id="bandage", category="medical", name="Бинт", desc="Одноразовый медицинский бинт", model="models/bandages.mdl", price=35, weapon="weapon_bandage_sh"},
    {id="big_bandage", category="medical", name="Большая повязка", desc="Усиленная медицинская повязка", model="models/bandages.mdl", price=70, weapon="weapon_bigbandage_sh"},
    {id="painkillers", category="medical", name="Обезболивающие", desc="Таблетки от боли", model="models/bloocobalt/l4d/items/w_eq_pills.mdl", price=20, weapon="weapon_painkillers"}
}

local ITEM_BY_ID = {}
for _, item in ipairs(ITEMS) do ITEM_BY_ID[item.id] = item end

local function EnsureDatabase()
    sql.Query([[CREATE TABLE IF NOT EXISTS nyfood_vendors (
        map_name TEXT PRIMARY KEY,
        pos_x REAL NOT NULL, pos_y REAL NOT NULL, pos_z REAL NOT NULL,
        yaw REAL NOT NULL DEFAULT 0
    )]])
end
hook.Add("Initialize", "NYFoodShop.Database", EnsureDatabase)
EnsureDatabase()

local function Notify(ply, message, good)
    if not IsValid(ply) then return end
    net.Start(NET.notify)
        net.WriteString(tostring(message or ""))
        net.WriteBool(good == true)
    net.Send(ply)
end

local function ReadMoney(ply)
    if isfunction(SSRP_GetMoney) then
        local ok, amount = pcall(SSRP_GetMoney, ply)
        if ok and tonumber(amount) then return math.max(0, math.floor(tonumber(amount))) end
    end
    if istable(MoneySystem) and isfunction(MoneySystem.GetMoney) then
        local ok, amount = pcall(MoneySystem.GetMoney, ply)
        if ok and tonumber(amount) then return math.max(0, math.floor(tonumber(amount))) end
    end
    if isfunction(ply.getDarkRPVar) then
        local ok, amount = pcall(ply.getDarkRPVar, ply, "money")
        if ok and tonumber(amount) then return math.max(0, math.floor(tonumber(amount))) end
    end
    return math.max(0, math.floor(tonumber(ply:GetPData("ssrp_money", "0")) or 0))
end

local function ReadNeed(ply, kind)
    if NYNeeds and isfunction(NYNeeds[kind == "hunger" and "GetHunger" or "GetThirst"]) then
        local ok, value = pcall(NYNeeds[kind == "hunger" and "GetHunger" or "GetThirst"], ply)
        if ok and tonumber(value) then return math.Clamp(math.floor(tonumber(value)), 0, 100) end
    end
    local key = kind == "hunger" and "NYTribecaHunger" or "NYTribecaThirst"
    return math.Clamp(ply:GetNW2Int(key, 100), 0, 100)
end

local function AddNeed(ply, kind, amount)
    local method = kind == "hunger" and "AddHunger" or "AddThirst"
    if NYNeeds and isfunction(NYNeeds[method]) then
        local ok = pcall(NYNeeds[method], ply, amount)
        if ok then return end
    end
    local key = kind == "hunger" and "NYTribecaHunger" or "NYTribecaThirst"
    ply:SetNW2Int(key, math.Clamp(ply:GetNW2Int(key, 100) + amount, 0, 100))
end

local function TakeMoney(ply, amount)
    if istable(MoneySystem) and isfunction(MoneySystem.TakeMoney) then
        local ok, result = pcall(MoneySystem.TakeMoney, ply, amount, "ny_tribeca_foodshop")
        return ok and result ~= false
    end
    if istable(MoneySystem) and isfunction(MoneySystem.AddMoney) then
        local ok, result = pcall(MoneySystem.AddMoney, ply, -amount, "ny_tribeca_foodshop")
        return ok and result ~= false
    end
    if isfunction(ply.addMoney) then
        local ok, result = pcall(ply.addMoney, ply, -amount)
        return ok and result ~= false
    end
    return false
end

local function GetState(ply)
    local medical, consumables = {}, {}
    for _, item in ipairs(ITEMS) do
        if item.weapon then medical[item.id] = ply:HasWeapon(item.weapon)
        elseif item.weaponClass then
            consumables[item.id] = false
            local held = ply:GetWeapon(item.weaponClass)
            if IsValid(held) then
                consumables[item.weaponClass] = held.NYFoodShopItem ~= nil
                if held.NYFoodShopItem == item.id then consumables[item.id] = true end
            end
        end
    end
    return medical, consumables
end

local function SendState(ply, message, good)
    local medical, consumables = GetState(ply)
    net.Start(NET.update)
        net.WriteTable(medical)
        net.WriteTable(consumables)
        net.WriteUInt(ReadNeed(ply, "hunger"), 7)
        net.WriteUInt(ReadNeed(ply, "thirst"), 7)
        net.WriteUInt(ReadMoney(ply), 32)
        net.WriteString(tostring(message or ""))
        net.WriteBool(good == true)
    net.Send(ply)
end

local function IsNearVendor(ply)
    local vendor = ply.NYFoodShopVendor
    return IsValid(vendor) and vendor:GetClass() == VENDOR_CLASS
        and ply:GetPos():DistToSqr(vendor:GetPos()) <= USE_RADIUS * USE_RADIUS
end

function NYFoodShop.Open(ply, vendor)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if IsValid(vendor) then
        if vendor:GetClass() ~= VENDOR_CLASS or ply:GetPos():DistToSqr(vendor:GetPos()) > USE_RADIUS * USE_RADIUS then return end
    else
        vendor = NULL
    end
    ply.NYFoodShopVendor = vendor
    local medical, consumables = GetState(ply)
    net.Start(NET.open)
        net.WriteEntity(vendor)
        net.WriteTable(ITEMS)
        net.WriteTable(medical)
        net.WriteTable(consumables)
        net.WriteUInt(ReadNeed(ply, "hunger"), 7)
        net.WriteUInt(ReadNeed(ply, "thirst"), 7)
        net.WriteUInt(ReadMoney(ply), 32)
    net.Send(ply)
end

local function ApplyNeeds(ply, item)
    if (item.hunger or 0) > 0 then AddNeed(ply, "hunger", item.hunger) end
    if (item.thirst or 0) > 0 then AddNeed(ply, "thirst", item.thirst) end

    -- Keep the server's metabolism in sync with the hunger and thirst HUD.
    local organism = ply.organism
    if istable(organism) then
        organism.satiety = math.min(100, math.max(0, tonumber(organism.satiety) or 0) + ((item.hunger or 0) > 0 and 5 or 2))
        organism.hungry = math.max(0, (tonumber(organism.hungry) or 0) - math.max(3, (item.hunger or item.thirst or 0) * 0.35))
    end
    return true
end

local function PatchConsumable(class)
    local stored = weapons.GetStored(class)
    if not istable(stored) or not isfunction(stored.Heal) then return false end
    if stored.NYFoodShopPatched then return true end
    local originalHeal = stored.Heal
    stored.Heal = function(self, target, ...)
        local owner = self:GetOwner()
        local item = ITEM_BY_ID[self.NYFoodShopItem or ""]
        local result = originalHeal(self, target, ...)
        if result == true and item and IsValid(owner) and owner:IsPlayer() then ApplyNeeds(owner, item) end
        return result
    end
    stored.NYFoodShopPatched = true
    return true
end

timer.Create("NYFoodShop.PatchConsumables", 1, 0, function()
    local bigReady = PatchConsumable("weapon_bigconsumable")
    local smallReady = PatchConsumable("weapon_smallconsumable")
    if bigReady and smallReady then timer.Remove("NYFoodShop.PatchConsumables") end
end)

net.Receive(NET.action, function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if (ply.NYFoodShopNextAction or 0) > CurTime() then return end
    ply.NYFoodShopNextAction = CurTime() + 0.25

    local action = net.ReadString()
    local id = net.ReadString()
    if action == "close" then ply.NYFoodShopVendor = nil return end
    local item = ITEM_BY_ID[id]
    if not item then return end

    if action == "buy" then
        if not IsNearVendor(ply) then Notify(ply, "Подойди к продавцу, чтобы купить товар.", false) return end
        local class = item.weaponClass or item.weapon
        if not isstring(class) or class == "" then return end
        if not weapons.GetStored(class) then SendState(ply, "Этот предмет сейчас недоступен.", false) return end
        local held = ply:GetWeapon(class)
        if item.weaponClass and IsValid(held) and held.NYFoodShopItem then
            SendState(ply, "Сначала используй уже купленный предмет этого типа.", false)
            return
        end
        if ReadMoney(ply) < item.price then SendState(ply, "Не хватает денег.", false) return end
        if not TakeMoney(ply, item.price) then SendState(ply, "Не удалось списать деньги.", false) return end
        local weapon = IsValid(held) and item.weaponClass and held or ply:Give(class)
        if not IsValid(weapon) then
            if istable(MoneySystem) and isfunction(MoneySystem.AddMoney) then
                pcall(MoneySystem.AddMoney, ply, item.price, "ny_tribeca_foodshop_refund")
            elseif isfunction(ply.addMoney) then
                pcall(ply.addMoney, ply, item.price)
            end
            SendState(ply, "Не удалось выдать товар. Покупка отменена.", false)
            return
        end

        if item.weaponClass then
            weapon.NYFoodShopItem = item.id
            weapon.Eating = 5
            weapon.CDEating = 0
            weapon.WorldModel = item.model
            weapon:SetModel(item.model)
            if isfunction(weapon.SetCurModel) then weapon:SetCurModel(item.model) end
        end
        ply:SelectWeapon(class)
        SendState(ply, item.name .. " выдан в руки. Цена: $" .. item.price .. ".", true)
    end
end)

hook.Add("PlayerDisconnected", "NYFoodShop.ClearSession", function(ply) ply.NYFoodShopVendor = nil end)

local function SpawnVendor(pos, yaw)
    for _, old in ipairs(ents.FindByClass(VENDOR_CLASS)) do if IsValid(old) then old:Remove() end end
    local vendor = ents.Create(VENDOR_CLASS)
    if not IsValid(vendor) then return nil end
    vendor:SetPos(pos)
    vendor:SetAngles(Angle(0, yaw or 0, 0))
    vendor:Spawn()
    vendor:Activate()
    return vendor
end

local function SaveVendor(vendor)
    local pos = vendor:GetPos()
    sql.Query("REPLACE INTO nyfood_vendors (map_name, pos_x, pos_y, pos_z, yaw) VALUES (" ..
        sql.SQLStr(game.GetMap()) .. ", " .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ", " .. vendor:GetAngles().y .. ")")
end

concommand.Add("nyfood_spawn", function(ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local trace = ply:GetEyeTrace()
    if not trace.Hit then Notify(ply, "Наведи взгляд на место установки продавца.", false) return end
    local vendor = SpawnVendor(trace.HitPos + Vector(0, 0, 2), ply:EyeAngles().y + 180)
    if not IsValid(vendor) then Notify(ply, "Не удалось создать продавца.", false) return end
    SaveVendor(vendor)
    Notify(ply, "Продавец еды установлен. Позиция сохранится после перезапуска карты.", true)
end)

concommand.Add("nyfood_remove", function(ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    for _, vendor in ipairs(ents.FindByClass(VENDOR_CLASS)) do if IsValid(vendor) then vendor:Remove() end end
    sql.Query("DELETE FROM nyfood_vendors WHERE map_name = " .. sql.SQLStr(game.GetMap()))
    Notify(ply, "Продавец еды удалён с этой карты.", true)
end)

local function LoadVendor()
    EnsureDatabase()
    local rows = sql.Query("SELECT * FROM nyfood_vendors WHERE map_name = " .. sql.SQLStr(game.GetMap()))
    if not istable(rows) or not rows[1] or #ents.FindByClass(VENDOR_CLASS) > 0 then return end
    local row = rows[1]
    SpawnVendor(Vector(tonumber(row.pos_x) or 0, tonumber(row.pos_y) or 0, tonumber(row.pos_z) or 0), tonumber(row.yaw) or 0)
end
hook.Add("InitPostEntity", "NYFoodShop.LoadVendor", function() timer.Simple(2, LoadVendor) end)
hook.Add("PostCleanupMap", "NYFoodShop.RespawnVendor", function() timer.Simple(1, LoadVendor) end)

NYFoodShop.Items = ITEMS
