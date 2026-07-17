local tbThing = GameMain:GetMod("ThingHelper"):GetThing("KongTiao_Building");

function tbThing:OnInit()
if self.Time == nil then
self.Time = 0;
end
if self.WenDu == nil then
self.WenDu = 20;
end
end

function tbThing:OnStep(dt)
local it = self.it;
if it.BuildingState == g_emBuildingState.Working then
self.Time = self.Time + dt;
if (it.AtRoom ~= nil) then
if (self.Time>=2) then
xlua.private_accessible(CS.XiaWorld.AreaRoom);
local MapWenDu = Map:GetGlobleTemperature();
local WuWenDu =it.AtRoom.m_fTemperatureWall;
print(WuWenDu);
local WenDuCha = self.WenDu-MapWenDu-WuWenDu;
setWenDu = WenDuCha * it.AtRoom.m_lisGrids.Count / 25;
print(setWenDu);
it.def.Heat.RoomValue = setWenDu;
self.Time = 0;
end
end
end
end

function tbThing:OnPutDown()
self.it:RemoveBtnData("Set", nil, "bind.luaclass:GetTable():UseKongTiao()", "Adjust the temperature of the Incense Burner", nil);
self.it:AddBtnData("Settings", nil, "bind.luaclass:GetTable():UseKongTiao()", "Adjust the temperature of the Incense Burner", nil);
end

function tbThing:UseKongTiao()
  local xWindow = GameMain:GetMod("Windows"):GetWindow("KongTiaoWindow");
  xWindow:Hide();
xWindow:SetUpData(self);
xWindow:Show();
end

function tbThing:setWenDu(WenDu)
self.WenDu = WenDu;
end