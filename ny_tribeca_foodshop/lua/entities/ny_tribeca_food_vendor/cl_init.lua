include("shared.lua")

surface.CreateFont("NYFoodVendor.Name", {font="Bahnschrift", size=17, weight=700, antialias=true, extended=true})

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 82)
    local ang = Angle(0, EyeAngles().y - 90, 90)
    cam.Start3D2D(pos, ang, 0.075)
        draw.RoundedBox(5, -108, -22, 216, 44, Color(13, 18, 24, 230))
        draw.RoundedBox(2, -108, -22, 3, 44, Color(220, 172, 83))
        draw.SimpleText("ПРОДУКТОВЫЙ МАГАЗИН", "NYFoodVendor.Name", 0, -7, Color(239, 239, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("НАЖМИТЕ E", "NYFoodVendor.Name", 0, 12, Color(220, 172, 83), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
