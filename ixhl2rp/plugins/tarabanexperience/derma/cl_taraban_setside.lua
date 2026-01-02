local PLUGIN = PLUGIN

local PANEL = {}

function PANEL:Init()
    local scrW, scrH = ScrW(), ScrH()

    self:SetSize(scrW *.8, scrH *.9)

    self:MakePopup()
    self:Center()
    self:SetTitle("Выберите сторону")

    local selfWide = self:GetWide()

    self.combinePanel = self:Add("DButton")
    self.combinePanel:Dock(LEFT)
    self.combinePanel:SetWide(selfWide *.5)
    self.combinePanel:SetText("COMBINE")

    self.combinePanel.DoClick = function()
        hook.Run("OnOpenSelectClass", PLUGIN.teams.combine)
    end

    self.resistancePanel = self:Add("DButton")
    self.resistancePanel:Dock(RIGHT)
    self.resistancePanel:SetWide(selfWide *.5)
    self.resistancePanel:SetText("RESISTANCE")
    
    self.resistancePanel.DoClick = function()
        hook.Run("OnOpenSelectClass", PLUGIN.teams.resistance)
    end
end

vgui.Register("taraban.setside", PANEL, "DFrame")