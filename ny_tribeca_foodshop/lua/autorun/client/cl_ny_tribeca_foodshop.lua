if not CLIENT then return end

NYUI = NYUI or {}

-- Тот же шрифт и стиль, что в главном меню сервера: Bahnschrift, чёрный фон, жёлтые акценты.
local function Font(name, size, weight)
    surface.CreateFont(name, {font = "Bahnschrift", size = size, weight = weight, antialias = true, extended = true})
end
Font("NYFood.Title", 30, 800)
Font("NYFood.Body", 18, 800)
Font("NYFood.Desc", 14, 600)
Font("NYFood.Small", 15, 700)
Font("NYFood.Icon", 21, 700)
Font("NYFood.Label", 12, 700)
Font("NYFood.Price", 26, 800)
Font("NYFood.Button", 15, 800)
Font("NYFood.Pill", 12, 800)
Font("NYFood.Close", 34, 600)

local C = {
    bg = Color(8, 8, 8, 252),
    panel = Color(17, 17, 17),
    panelHover = Color(26, 24, 19),
    gold = Color(224, 178, 66),
    goldHot = Color(255, 215, 55),
    dark = Color(10, 10, 10),
    text = Color(244, 244, 244),
    muted = Color(140, 140, 140),
    red = Color(214, 74, 66)
}

local categories = {
    {id = "food", name = "ЕДА"},
    {id = "water", name = "ВОДА"},
    {id = "medical", name = "АПТЕЧНЫЕ ИЗДЕЛИЯ"}
}
local frame, current = nil, nil

local function A(color, alpha) return Color(color.r, color.g, color.b, alpha) end
local function Mix(t, a, b)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a or 255, b.a or 255))
end
local function Approach(panel, key, target, speed)
    panel[key] = Lerp(math.min(FrameTime() * (speed or 14), 1), panel[key] or 0, target)
    return panel[key]
end
local function Text(text, font, x, y, color, ax, ay)
    draw.SimpleText(text, font, x, y, color, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end
-- Удаляет последний символ строки в UTF-8 (utf8.offset в GMod падает на кириллице).
local function DropLastChar(text)
    local i = #text
    while i > 1 do
        local b = string.byte(text, i)
        if b < 0x80 or b >= 0xC0 then break end
        i = i - 1
    end
    return string.sub(text, 1, i - 1)
end

local function Fit(text, font, maxWidth)
    surface.SetFont(font)
    text = tostring(text or "")
    if surface.GetTextSize(text) <= maxWidth then return text end
    while #text > 1 and surface.GetTextSize(text .. "…") > maxWidth do
        text = DropLastChar(text)
    end
    return text .. "…"
end

local function Request(action, id)
    net.Start("NYFoodShop.Action")
        net.WriteString(action)
        net.WriteString(id or "")
    net.SendToServer()
end

local function CloseShop()
    if IsValid(frame) then frame:Close() end
end

-- Кнопка: gold (покупка) или ghost (недоступно).
local function MakeButton(parent, label, x, y, w, h, enabled, onClick)
    local button = vgui.Create("DButton", parent)
    button:SetPos(x, y)
    button:SetSize(w, h)
    button:SetText("")
    button:SetEnabled(enabled)
    button:SetCursor(enabled and "hand" or "arrow")
    surface.SetFont("NYFood.Button")
    local font = surface.GetTextSize(label) > w - 16 and "NYFood.Pill" or "NYFood.Button"
    button.Paint = function(self, bw, bh)
        if not enabled then
            draw.RoundedBox(6, 0, 0, bw, bh, Color(255, 255, 255, 22))
            draw.RoundedBox(5, 1, 1, bw - 2, bh - 2, Color(20, 20, 20))
            Text(label, font, bw * 0.5, bh * 0.5, C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        local hover = Approach(self, "_h", self:IsHovered() and 1 or 0)
        draw.RoundedBox(6, 0, 0, bw, bh, Mix(hover, C.gold, C.goldHot))
        Text(label, font, bw * 0.5, bh * 0.5, C.dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    button.DoClick = onClick
    return button
end

local function Chip(label, x, y)
    surface.SetFont("NYFood.Pill")
    local tw = surface.GetTextSize(label)
    local w, h = tw + 18, 22
    draw.RoundedBox(11, x, y, w, h, A(C.gold, 150))
    draw.RoundedBox(10, x + 1, y + 1, w - 2, h - 2, C.dark)
    Text(label, "NYFood.Pill", x + w * 0.5, y + h * 0.5, C.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return x + w + 6
end

local function DrawNeedBar(label, value, x, y, w)
    local low = value <= 15
    Text(label, "NYFood.Label", x, y, C.muted)
    Text(value .. "%", "NYFood.Label", x + w, y, low and C.red or C.text, TEXT_ALIGN_RIGHT)
    draw.RoundedBox(3, x, y + 22, w, 6, Color(255, 255, 255, 18))
    local fill = math.max(0, math.min(1, value / 100)) * w
    if fill > 1 then draw.RoundedBox(3, x, y + 22, math.max(fill, 6), 6, low and C.red or C.gold) end
end

local function OpenShop(vendor, items, medical, consumables, hunger, thirst, money)
    if IsValid(frame) then frame:Remove() end
    current = {vendor = vendor, items = items or {}, medical = medical or {}, consumables = consumables or {}, hunger = hunger or 100, thirst = thirst or 100, money = money or 0, category = "food", search = ""}

    local sw, sh = ScrW(), ScrH()
    local width, height = math.min(1060, sw - 60), math.min(740, sh - 60)

    -- Окно на весь экран: затемнение, клик вне карточки и Esc закрывают магазин.
    local root = vgui.Create("DFrame")
    frame = root
    root:SetTitle("")
    root:ShowCloseButton(false)
    root:SetDraggable(false)
    root:SetSizable(false)
    root:SetPos(0, 0)
    root:SetSize(sw, sh)
    root:MakePopup()
    root.Paint = function(_, w, h)
        surface.SetDrawColor(0, 0, 0, 190)
        surface.DrawRect(0, 0, w, h)
    end
    root.OnClose = function()
        Request("close", "")
        current = nil
    end

    local card = vgui.Create("DPanel", root)
    card:SetSize(width, height)
    card:SetPos((sw - width) * 0.5, (sh - height) * 0.5)
    card.Paint = function(_, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(255, 255, 255, 28))
        draw.RoundedBox(11, 1, 1, w - 2, h - 2, C.bg)
        Text("МАГАЗИН", "NYFood.Title", 32, 24, C.text)
        Text("ВЫБЕРИТЕ ТОВАР  •  ПОЛУЧИТЕ ЕГО СРАЗУ В РУКИ", "NYFood.Label", 33, 66, C.gold)
        surface.SetDrawColor(C.gold)
        surface.DrawRect(32, 90, 56, 2)
        surface.SetDrawColor(255, 255, 255, 20)
        surface.DrawRect(88, 91, w - 120, 1)

        if not current then return end
        -- Баланс и потребности справа в шапке.
        Text("БАЛАНС", "NYFood.Label", w - 84, 22, C.muted, TEXT_ALIGN_RIGHT)
        Text("$" .. string.Comma(current.money), "NYFood.Price", w - 84, 38, C.gold, TEXT_ALIGN_RIGHT)
        if w >= 860 then
            local thirstX = w - 84 - 190 - 120
            DrawNeedBar("ГОЛОД", current.hunger, thirstX - 36 - 120, 26, 120)
            DrawNeedBar("ЖАЖДА", current.thirst, thirstX, 26, 120)
        end
    end

    local close = vgui.Create("DButton", card)
    close:SetText("")
    close:SetSize(44, 44)
    close:SetPos(width - 60, 20)
    close:SetCursor("hand")
    close.Paint = function(self, w, h)
        local hover = Approach(self, "_h", self:IsHovered() and 1 or 0)
        Text("×", "NYFood.Close", w * 0.5, h * 0.5 - 2, Mix(hover, C.muted, C.goldHot), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = CloseShop

    root.OnMousePressed = function(self, code)
        if code ~= MOUSE_LEFT then return end
        local mx, my = self:CursorPos()
        local x, y = card:GetPos()
        if mx < x or mx > x + width or my < y or my > y + height then self:Close() end
    end
    root.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then
            gui.HideGameUI()
            self:Close()
        end
    end

    -- ---------- Поиск ----------
    local PAD = 32
    local searchBg = vgui.Create("DPanel", card)
    searchBg:SetPos(PAD, 112)
    searchBg:SetSize(width - PAD * 2, 40)

    local search = vgui.Create("DTextEntry", card)
    search:SetPos(PAD + 40, 112)
    search:SetSize(width - PAD * 2 - 52, 40)
    search:SetFont("NYFood.Small")
    search:SetDrawLanguageID(false)
    search:SetUpdateOnType(true)

    searchBg.Paint = function(self, w, h)
        local focus = Approach(self, "_focus", search:HasFocus() and 1 or 0, 12)
        draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 8 + focus * 8))
        surface.SetDrawColor(C.gold.r, C.gold.g, C.gold.b, 50 + focus * 205)
        surface.DrawRect(0, h - 1, w, 1)
        -- Значок лупы.
        surface.SetDrawColor(C.gold.r, C.gold.g, C.gold.b, 170 + focus * 85)
        local cx, cy = 22, h * 0.5 - 1
        local px, py = cx + 6, cy
        for i = 1, 16 do
            local a = i / 16 * math.pi * 2
            local x, y = cx + math.cos(a) * 6, cy + math.sin(a) * 6
            surface.DrawLine(px, py, x, y)
            px, py = x, y
        end
        surface.DrawLine(cx + 4, cy + 4, cx + 9, cy + 9)
        surface.DrawLine(cx + 5, cy + 4, cx + 10, cy + 9)
    end
    searchBg.OnMousePressed = function() search:RequestFocus() end

    search.Paint = function(self, w, h)
        if self:GetValue() == "" then
            Text("Поиск по товарам…", "NYFood.Small", 3, h * 0.5, Color(255, 255, 255, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        self:DrawTextEntryText(C.text, A(C.gold, 90), C.goldHot)
    end

    -- ---------- Вкладки ----------
    local tabBar = vgui.Create("DPanel", card)
    tabBar:SetPos(PAD, 164)
    tabBar:SetSize(width - PAD * 2, 36)
    tabBar.Paint = function(_, w, h)
        surface.SetDrawColor(255, 255, 255, 20)
        surface.DrawRect(0, h - 1, w, 1)
    end

    -- ---------- Сетка товаров ----------
    local list = vgui.Create("DScrollPanel", card)
    list:SetPos(PAD, 212)
    list:SetSize(width - PAD * 2, height - 212 - 24)
    local vbar = list:GetVBar()
    vbar:SetWide(6)
    vbar:SetHideButtons(true)
    vbar.Paint = function(_, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 10)) end
    vbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, A(C.gold, self:IsHovered() and 235 or 150)) end

    local Rebuild

    local function AddItemCard(grid, item, cardW)
        local ROW_H = 142
        local panel = grid:Add("DPanel")
        panel:SetSize(cardW, ROW_H)

        local alreadyOwned = (item.weapon and current.medical[item.id]) or (item.weaponClass and current.consumables[item.id])
        local typeBusy = item.weaponClass and current.consumables[item.weaponClass] and not alreadyOwned
        local disabled = alreadyOwned == true or typeBusy == true
        local price = item.price or 0
        local affordable = current.money >= price

        panel.Paint = function(self, w, h)
            local hover = Approach(self, "_h", (self:IsHovered() or self:IsChildHovered()) and 1 or 0)
            draw.RoundedBox(9, 0, 0, w, h, Mix(hover, Color(255, 255, 255, 22), A(C.gold, 190)))
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, Mix(hover, C.panel, C.panelHover))
            surface.SetDrawColor(C.gold.r, C.gold.g, C.gold.b, 90 + 165 * hover)
            surface.DrawRect(0, 18, 3, h - 36)

            -- Подложка под модель.
            draw.RoundedBox(7, 14, 14, 100, h - 28, Color(255, 255, 255, 14))
            draw.RoundedBox(6, 15, 15, 98, h - 30, Color(10, 10, 10))

            local tx, tw = 130, w - 130 - 16
            Text(Fit(item.name or "Товар", "NYFood.Body", tw), "NYFood.Body", tx, 16, Mix(hover, C.text, C.goldHot))
            Text(Fit(item.desc or "", "NYFood.Desc", tw), "NYFood.Desc", tx, 42, C.muted)

            -- Эффекты товара.
            local cx = tx
            if (item.hunger or 0) > 0 then cx = Chip("+" .. item.hunger .. " ГОЛОД", cx, 66) end
            if (item.thirst or 0) > 0 then cx = Chip("+" .. item.thirst .. " ЖАЖДА", cx, 66) end
            if item.category == "medical" then Chip("МЕДИЦИНА", cx, 66) end

            Text("$" .. string.Comma(price), "NYFood.Price", tx, h - 48, affordable and C.gold or C.red)
        end

        local icon = vgui.Create("SpawnIcon", panel)
        icon:SetPos(17, (ROW_H - 94) * 0.5)
        icon:SetSize(94, 94)
        icon:SetModel(item.model or "models/Items/HealthKit.mdl")
        icon:SetTooltip(item.name or "")
        icon:SetMouseInputEnabled(false)

        local label = alreadyOwned and "УЖЕ В РУКАХ" or (typeBusy and "ИСПОЛЬЗУЙТЕ ПРЕДМЕТ" or "КУПИТЬ")
        local bw = 150
        MakeButton(panel, label, cardW - 16 - bw, ROW_H - 14 - 36, bw, 36, not disabled, function()
            Request("buy", item.id)
        end)
    end

    Rebuild = function()
        if not IsValid(list) or not current then return end
        local scrollPos = vbar:GetScroll()
        list:Clear()

        local query = string.Trim(string.lower(current.search or ""))
        local matched = {}
        for _, item in ipairs(current.items) do
            local matches = query == "" or string.find(string.lower((item.name or "") .. " " .. (item.desc or "")), query, 1, true) ~= nil
            if current.category == item.category and matches then matched[#matched + 1] = item end
        end

        if #matched == 0 then
            local empty = list:Add("DPanel")
            empty:Dock(TOP)
            empty:SetTall(140)
            empty.Paint = function(_, w, h)
                Text("Ничего не найдено", "NYFood.Body", w * 0.5, h * 0.5, C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            return
        end

        local gap = 12
        local inner = list:GetWide() - 12
        local columns = inner >= 900 and 3 or (inner >= 560 and 2 or 1)
        local cardW = math.floor((inner - gap * (columns - 1)) / columns)

        local grid = vgui.Create("DIconLayout", list)
        grid:Dock(TOP)
        grid:SetSpaceX(gap)
        grid:SetSpaceY(gap)
        for _, item in ipairs(matched) do AddItemCard(grid, item, cardW) end

        -- После покупки остаёмся на том же месте списка.
        list:InvalidateLayout(true)
        vbar:SetScroll(scrollPos)
        timer.Simple(0, function()
            if IsValid(list) and scrollPos > 0 then vbar:SetScroll(scrollPos) end
        end)
    end

    -- Вкладки категорий со счётчиком товаров.
    local tabX = 0
    for _, data in ipairs(categories) do
        local total = 0
        for _, item in ipairs(current.items) do
            if item.category == data.id then total = total + 1 end
        end
        local label = data.name .. "   " .. total
        surface.SetFont("NYFood.Button")
        local tw = surface.GetTextSize(label)
        local tab = vgui.Create("DButton", tabBar)
        tab:SetPos(tabX, 0)
        tab:SetSize(tw + 40, 36)
        tab:SetText("")
        tab:SetCursor("hand")
        tab.Paint = function(self, w, h)
            local active = current and current.category == data.id
            local hover = Approach(self, "_h", self:IsHovered() and 1 or 0)
            Text(label, "NYFood.Button", w * 0.5, h * 0.5 - 1, active and C.gold or Mix(hover, C.muted, C.text), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if active then
                surface.SetDrawColor(C.gold)
                surface.DrawRect(0, h - 2, w, 2)
            end
        end
        tab.DoClick = function()
            if not current then return end
            current.category = data.id
            vbar:SetScroll(0)
            Rebuild()
            vbar:SetScroll(0)
        end
        tabX = tabX + tw + 40 + 6
    end

    search.OnChange = function(self)
        if not current then return end
        current.search = self:GetValue()
        Rebuild()
    end
    current.refresh = Rebuild
    Rebuild()
end

net.Receive("NYFoodShop.Open", function()
    OpenShop(net.ReadEntity(), net.ReadTable(), net.ReadTable(), net.ReadTable(), net.ReadUInt(7), net.ReadUInt(7), net.ReadUInt(32))
end)

net.Receive("NYFoodShop.Update", function()
    if not current then return end
    current.medical = net.ReadTable() or {}
    current.consumables = net.ReadTable() or {}
    current.hunger = net.ReadUInt(7)
    current.thirst = net.ReadUInt(7)
    current.money = net.ReadUInt(32)
    local message, good = net.ReadString(), net.ReadBool()
    if IsValid(frame) and message ~= "" then
        notification.AddLegacy(message, good and NOTIFY_GENERIC or NOTIFY_ERROR, 3)
        surface.PlaySound(good and "buttons/button14.wav" or "buttons/button10.wav")
        if current.refresh then current.refresh() end
    end
end)

net.Receive("NYFoodShop.Notify", function()
    local message, good = net.ReadString(), net.ReadBool()
    notification.AddLegacy(message, good and NOTIFY_GENERIC or NOTIFY_ERROR, 3)
    surface.PlaySound(good and "buttons/button14.wav" or "buttons/button10.wav")
end)
