local PLUGIN = PLUGIN

ix.gui.taraban = ix.gui.taraban or {}

function PLUGIN:OnOpenSelectClass(side)
    if (IsValid(ix.gui.taraban.beclass)) then
        ix.gui.taraban.beclass:Remove()
    end

    if (IsValid(ix.gui.taraban.setside)) then
        ix.gui.taraban.setside:Remove()
    end

    ix.gui.taraban.beclass = vgui.Create("taraban.beclass")
    ix.gui.taraban.beclass:SetData(side)
end

function PLUGIN:OnOpenSelectSide()
    if (IsValid(ix.gui.taraban.setside)) then
        ix.gui.taraban.setside:Remove()
    end

    ix.gui.taraban.setside = vgui.Create("taraban.setside")
end

local PANEL = baseclass.Get("ui.mainmenu.wrapper")
ix.gui.taraban.wrapperPerviousMenuClick = ix.gui.taraban.wrapperPerviousMenuClick or PANEL.MenuClick

function PANEL:MenuClick(id)
    if (id == 1 or id == 2) then
        hook.Run("OnOpenSelectSide")
        return
    end

    return ix.gui.taraban.wrapperPerviousMenuClick(self, id)
end

vgui.Register("ui.mainmenu.wrapper", PANEL, "ixCharMenuPanel")

netstream.Hook("taraban.closeChooseClass", function()
    if (IsValid(ix.gui.taraban.beclass)) then
        ix.gui.taraban.beclass:Remove()
    end
end)

timer.Simple(0.3, function()
    if (IsValid(ix.gui.characterMenu)) then
        ix.gui.characterMenu.mainPanel.MenuClick = PANEL.MenuClick
    end
end)

local font = "cellar.main.warn"
local colorWhite = Color(255,255,255)
local colorBlue = Color(0,110,255)
local colorOrange = Color(255,165,0)

function PLUGIN:HUDPaint()
    draw.DrawText("ЖИЗНИ СТОРОН", font, ScrW()*.94, ScrH()*.01, colorWhite, TEXT_ALIGN_LEFT)
    draw.DrawText(Format("COMBINE %s", ix.Net:GetVar("taraban.combinelifes")), font, ScrW()*.94, ScrH()*.03, colorBlue, TEXT_ALIGN_LEFT)
    draw.DrawText(Format("RESISTANCE %s", ix.Net:GetVar("taraban.resistancelifes")), font, ScrW()*.94, ScrH()*.045, colorOrange, TEXT_ALIGN_LEFT)
end