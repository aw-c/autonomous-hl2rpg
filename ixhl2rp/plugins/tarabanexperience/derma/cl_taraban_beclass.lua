local PLUGIN = PLUGIN

local PANEL = {}

function PANEL:Init()
    local scrW, scrH = ScrW(), ScrH()

    self:SetSize(scrW *.8, scrH *.9)

    self:MakePopup()
    self:Center()
    self:SetTitle("Выберите класс")

    local selfWide,selfTall = self:GetWide(), self:GetTall()
    local trippleWide = selfWide * .33

    self.lightClassPanel = self:Add("DButton")
    self.lightClassPanel:SetWide(trippleWide)
    self.lightClassPanel:SetTall(selfTall)
    self.lightClassPanel:SetX(0)
    self.lightClassPanel:SetText("ЛЁГКИЙ")
    self.lightClassPanel.DoClick = function()
        netstream.Start("taraban.ChooseSideAndClass", self.side, "light")
    end

    self.mediumClassPanel = self:Add("DButton")
    self.mediumClassPanel:SetWide(trippleWide)
    self.mediumClassPanel:SetTall(selfTall)
    self.mediumClassPanel:SetX(trippleWide)
    self.mediumClassPanel:SetText("СРЕДНИЙ")
    self.mediumClassPanel.DoClick = function()
        netstream.Start("taraban.ChooseSideAndClass", self.side, "medium")
    end

    self.heavyClassPanel = self:Add("DButton")
    self.heavyClassPanel:SetWide(trippleWide)
    self.heavyClassPanel:SetTall(selfTall)
    self.heavyClassPanel:SetX(selfWide * .66)
    self.heavyClassPanel:SetText("ТЯЖЁЛЫЙ")
    self.heavyClassPanel.DoClick = function()
        netstream.Start("taraban.ChooseSideAndClass", self.side, "heavy")
    end
end

function PANEL:SetData(side)
    self.side = side
end

vgui.Register("taraban.beclass", PANEL, "DFrame")