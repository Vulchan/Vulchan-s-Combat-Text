-- Vulchan's Combat Text v0.4.14
-- Standalone: compact floating damage numbers with source spell icons.
local defaults = {
    enabled=true, x=-115, y=0, size=20, critSize=28,
    spacing=31, rise=18, lifetime=1.25, maxLines=7, iconSize=22,
    showIcons=true, layout="vertical", scale=100
}
local active, pool, iconCache = {}, {}, {}
local isDragging = false
local dragStartCursorX, dragStartCursorY, dragStartOffsetX, dragStartOffsetY
local originalCombatDamage=nil
local frame=CreateFrame("Frame","VulchansCombatTextFrame",UIParent)
local dragFrame=CreateFrame("Frame","VulchansCombatTextDragFrame",UIParent)
dragFrame:SetWidth(310); dragFrame:SetHeight(250); dragFrame:SetMovable(false)
dragFrame:EnableMouse(false); dragFrame:RegisterForDrag("LeftButton")
dragFrame:SetFrameStrata("DIALOG"); dragFrame:SetAlpha(0)
dragFrame:SetBackdrop({
    bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=12,
    insets={left=3,right=3,top=3,bottom=3}
})
dragFrame:SetBackdropColor(0.15,0.08,0.02,0.45)
dragFrame:SetBackdropBorderColor(1,0.72,0.18,0.95)
local dragLabel=dragFrame:CreateFontString(nil,"OVERLAY")
dragLabel:SetFont("Fonts\\FRIZQT__.TTF",12,"THICKOUTLINE")
dragLabel:SetPoint("CENTER",dragFrame,"CENTER",0,0)
dragLabel:SetText("CTRL + DRAG TO MOVE")
dragLabel:SetTextColor(1,0.82,0.35,1)

local function Print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33Vulchan's Combat Text:|r "..msg) end
end
local function InitDB()
    if not VCTDB then VCTDB={} end
    for k,v in pairs(defaults) do if VCTDB[k]==nil then VCTDB[k]=v end end
end
local function ScaleFactor()
    return (VCTDB and tonumber(VCTDB.scale) or 100)/100
end
local function NewText(index)
    if not pool[index] then
        local f=UIParent:CreateFontString(nil,"OVERLAY")
        f:SetFont("Fonts\\FRIZQT__.TTF",math.max(6,math.floor(VCTDB.size*ScaleFactor()+0.5)),"THICKOUTLINE")
        f:SetWidth(260); f:SetHeight(38); f:SetJustifyH("RIGHT"); f:SetJustifyV("MIDDLE")
        f:SetShadowColor(0,0,0,1); f:SetShadowOffset(1,-1); f:Hide()
        local icon=UIParent:CreateTexture(nil,"OVERLAY")
        icon:SetWidth(VCTDB.iconSize*ScaleFactor()); icon:SetHeight(VCTDB.iconSize*ScaleFactor())
        icon:SetTexture(nil); icon:Hide()
        pool[index]={font=f,icon=icon}
    end
    return pool[index]
end
local function GetFree()
    for i=1,table.getn(pool) do
        if not pool[i].font:IsShown() then return pool[i] end
    end
    return NewText(table.getn(pool)+1)
end

-- WoW 1.12 spellbook lookup. Cache both successful and unsuccessful names.
local function SpellIcon(name)
    if not name or name=="" then return nil end
    if iconCache[name]~=nil then return iconCache[name] or nil end
    local found=nil
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellName and GetSpellTexture then
        for tab=1,GetNumSpellTabs() do
            local _,_,offset,count=GetSpellTabInfo(tab)
            for slot=(offset or 0)+1,(offset or 0)+(count or 0) do
                if GetSpellName(slot,"spell")==name then
                    found=GetSpellTexture(slot,"spell")
                    if found then break end
                end
            end
            if found then break end
        end
    end
    -- Basic melee/ranged sources use the equipped weapon artwork.
    if name=="Melee" or name=="Attack" then
        found=GetInventoryItemTexture and GetInventoryItemTexture("player",16)
    elseif name=="Auto Shot" or name=="Shoot" or name=="Shot" then
        found=(GetInventoryItemTexture and GetInventoryItemTexture("player",18)) or
              (GetInventoryItemTexture and GetInventoryItemTexture("player",16))
    end
    iconCache[name]=found or false
    return found
end

local function Reflow()
    local kept={}
    for i=1,table.getn(active) do
        local e=active[i]
        if e.age<VCTDB.lifetime then table.insert(kept,e)
        else e.parts.font:Hide(); e.parts.icon:Hide() end
    end
    active=kept
    for i=1,table.getn(active) do active[i].slot=i end
end
local function Spawn(amount,crit,taken,periodic,source)
    if not VCTDB or not VCTDB.enabled or not tonumber(amount) then return end
    Reflow()
    if table.getn(active)>=VCTDB.maxLines then
        local old=table.remove(active,table.getn(active)); old.parts.font:Hide(); old.parts.icon:Hide()
    end
    local p=GetFree(); local f=p.font; local icon=p.icon
    local value=tonumber(amount)
    -- Keep small hits exact; abbreviate larger hits as whole thousands (1k-999k).
    local rounded=math.floor(value+0.5)
    local label
    if rounded>=1000 then label=tostring(math.floor(rounded/1000)).."k"
    else label=tostring(rounded) end
    if taken then label="-"..label end
    f:SetFont("Fonts\\FRIZQT__.TTF",math.max(6,math.floor((crit and VCTDB.critSize or VCTDB.size)*ScaleFactor()+0.5)),
        crit and "THICKOUTLINE" or "OUTLINE")
    f:SetText(label)
    if taken then f:SetTextColor(1,0.25,0.25)
    elseif crit then f:SetTextColor(1,0.78,0.12)
    elseif periodic then f:SetTextColor(0.78,0.82,0.88)
    else f:SetTextColor(1,0.91,0.62) end

    local texture=nil
    if VCTDB.showIcons and not taken then texture=SpellIcon(source) end
    if texture then
        icon:SetTexture(texture); icon:SetWidth(VCTDB.iconSize*ScaleFactor()); icon:SetHeight(VCTDB.iconSize*ScaleFactor())
        icon:ClearAllPoints(); icon:SetPoint("RIGHT",f,"RIGHT",-(f:GetStringWidth()+ScaleFactor()),0); icon:SetAlpha(1); icon:Show()
    else icon:Hide() end
    f:Show(); f:SetAlpha(1)
    table.insert(active,1,{parts=p,age=0,slot=1})
end

local function ParseOutgoing(msg)
    if not msg then return end
    local who,target,amount
    if string.find(msg," crit",1,true) then
        _,_,who,target,amount=string.find(msg,"^(.-) crits (.+) for (%d+)")
        if not amount then _,_,who,target,amount=string.find(msg,"^(.-) crit (.+) for (%d+)") end
        if amount then
            local a,b,spellName=string.find(who,"^Your (.+)$")
            local source=spellName or (who=="You" and "Melee") or who
            Spawn(amount,true,false,false,source); return
        end
    end
    if string.find(msg," hit",1,true) then
        _,_,who,target,amount=string.find(msg,"^(.-) hits (.+) for (%d+)")
        if not amount then _,_,who,target,amount=string.find(msg,"^(.-) hit (.+) for (%d+)") end
        if amount then
            local a,b,spellName=string.find(who,"^Your (.+)$")
            local source=spellName or (who=="You" and "Melee") or who
            Spawn(amount,false,false,false,source); return
        end
    end
    local first,last,targetName,periodicAmount,spell=string.find(msg,"^(.+) suffers (%d+) .- damage from your (.-)%.?$")
    if periodicAmount then Spawn(periodicAmount,false,false,true,spell) end
end
local function Apply()
    if not VCTDB then return end
    if VCTDB.enabled then
        if originalCombatDamage==nil then originalCombatDamage=GetCVar and GetCVar("CombatDamage") or "1" end
        if SetCVar then SetCVar("CombatDamage","0") end
        frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
        frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        frame:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")
        frame:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
        frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
        frame:RegisterEvent("COMBAT_TEXT_UPDATE")
    else
        frame:UnregisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
        frame:UnregisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        frame:UnregisterEvent("CHAT_MSG_COMBAT_PET_HITS")
        frame:UnregisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
        frame:UnregisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
        frame:UnregisterEvent("COMBAT_TEXT_UPDATE")
        if SetCVar then SetCVar("CombatDamage",originalCombatDamage or "1") end
        for i=1,table.getn(active) do active[i].parts.font:Hide(); active[i].parts.icon:Hide() end
        active={}
    end
end
frame:SetScript("OnEvent",function()
    if event=="COMBAT_TEXT_UPDATE" then
        if (arg1=="DAMAGE" or arg1=="DAMAGE_CRIT" or arg1=="SPELL_DAMAGE") and tonumber(arg2) then
            Spawn(arg2,arg1=="DAMAGE_CRIT",true,false,nil)
        end
    else ParseOutgoing(arg1) end
end)
frame:SetScript("OnUpdate",function()
    if not VCTDB then return end
    if not VCTDB.enabled then dragFrame:EnableMouse(false); return end
    if (IsControlKeyDown and IsControlKeyDown()) or isDragging then
        dragFrame:EnableMouse(true)
        dragFrame:SetAlpha(0.85)
        dragLabel:Show()
    else
        dragFrame:EnableMouse(false)
        dragFrame:SetAlpha(0)
        dragLabel:Hide()
    end
    -- Move the handle ourselves using cursor deltas. This avoids the legacy
    -- StartMoving/StopMovingOrSizing anchor handoff that caused release snapping.
    if isDragging and dragStartCursorX and GetCursorPosition then
        local cx,cy=GetCursorPosition()
        local uiScale=(UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or
                      (UIParent.GetScale and UIParent:GetScale()) or 1
        if not uiScale or uiScale==0 then uiScale=1 end
        local dx=(cx-dragStartCursorX)/uiScale
        local dy=(cy-dragStartCursorY)/uiScale
        VCTDB.x=dragStartOffsetX+dx
        VCTDB.y=dragStartOffsetY+dy
        dragFrame:ClearAllPoints()
        dragFrame:SetPoint("RIGHT",UIParent,"RIGHT",VCTDB.x,VCTDB.y)
    end
    -- The damage text and drag handle share this single anchor throughout movement.
    local sf=ScaleFactor()
    local stack=(math.max(1,(VCTDB.maxLines or 7)-1)*(VCTDB.spacing or 31))*sf
    for i=1,table.getn(active) do
        local e=active[i]; e.age=e.age+arg1; local t=e.age/VCTDB.lifetime
        if t>=1 then e.parts.font:Hide(); e.parts.icon:Hide()
        else
            local x,y
            if VCTDB.layout=="horizontal" then
                -- Numbers progress from left to right inside the wide handle.
                x=(55+(e.slot-1)*75)*sf
                y=0
            else
                x=0
                -- Center the vertical stack inside the tall handle.
                y=(stack/2-(e.slot-1)*(VCTDB.spacing or 31)*sf)+(VCTDB.rise*sf*t)
            end
            local alpha=1
            if t>0.48 then alpha=1-((t-0.48)/0.52) end
            if alpha<0 then alpha=0 end
            local f=e.parts.font
            -- Fit the text field to the orientation: narrow for a vertical stack,
            -- wide only when numbers are laid out in a row.
            if VCTDB.layout=="horizontal" then f:SetWidth(260*sf)
            else f:SetWidth(100*sf) end
            f:ClearAllPoints()
            if VCTDB.layout=="horizontal" then
                f:SetPoint("RIGHT",dragFrame,"LEFT",x,y)
            else
                f:SetPoint("RIGHT",dragFrame,"RIGHT",0,y)
            end
            f:SetAlpha(alpha)
            local icon=e.parts.icon
            if icon:IsShown() then
                icon:ClearAllPoints()
                icon:SetPoint("RIGHT",f,"RIGHT",-(f:GetStringWidth()+sf),0)
                icon:SetAlpha(alpha)
            end
        end
    end
    Reflow()
end)
local function UpdateDragFrame()
    local sf=ScaleFactor()
    local width,height
    if VCTDB.layout=="horizontal" then
        width=(310+(math.max(1,(VCTDB.maxLines or 7)-1)*75))*sf
        height=70*sf
    else
        -- A compact portrait handle hugs the stacked number-and-icon column.
        -- The 100px text field plus icon and a little breathing room fit inside.
        width=130*sf
        height=(math.max(1,(VCTDB.maxLines or 7)-1)*(VCTDB.spacing or 31)+50)*sf
    end
    dragFrame:SetWidth(width)
    dragFrame:SetHeight(height)
    dragFrame:ClearAllPoints()
    -- Use one anchor only. Two simultaneous anchors caused the frame to
    -- jump/disappear after StopMovingOrSizing on the legacy UI API.
    dragFrame:SetPoint("RIGHT",UIParent,"RIGHT",VCTDB.x,VCTDB.y)
end
local function FinishDrag()
    if not isDragging then return end
    isDragging=false
    dragStartCursorX=nil; dragStartCursorY=nil
    dragStartOffsetX=nil; dragStartOffsetY=nil
    -- Do not reposition on release: the live position is already the saved one.
    Print("position saved.")
end
dragFrame:SetScript("OnDragStart",function()
    if IsControlKeyDown and IsControlKeyDown() and GetCursorPosition then
        dragStartCursorX,dragStartCursorY=GetCursorPosition()
        dragStartOffsetX=VCTDB.x or defaults.x
        dragStartOffsetY=VCTDB.y or defaults.y
        isDragging=true
        dragLabel:Hide()
    end
end)
dragFrame:SetScript("OnMouseUp",function() FinishDrag() end)
dragFrame:SetScript("OnDragStop",function() FinishDrag() end)

local function Test()
    Spawn(4409,false,false,false,"Shadow Bolt")
    Spawn(16332,true,false,false,"Corruption")
    Spawn(9782,false,false,false,"Melee")
end
SLASH_VCT1="/vct"
SlashCmdList["VCT"]=function(msg)
    msg=string.lower(msg or "")
    if msg=="test" then Test()
    elseif msg=="on" then VCTDB.enabled=true; Apply(); Print("custom numbers enabled.")
    elseif msg=="off" then VCTDB.enabled=false; Apply(); Print("custom numbers disabled; original numbers restored.")
    elseif msg=="icons on" then VCTDB.showIcons=true; Print("spell icons enabled.")
    elseif msg=="icons off" then VCTDB.showIcons=false; Print("spell icons disabled.")
    elseif string.find(msg,"^scale ") then
        local n=tonumber(string.sub(msg,7))
        if n and n>=50 and n<=200 then
            VCTDB.scale=math.floor(n+0.5)
            UpdateDragFrame()
            Print("scale set to "..VCTDB.scale.."%.")
        else Print("scale must be between 50 and 200.") end
    elseif msg=="horizontal" or msg=="layout horizontal" then VCTDB.layout="horizontal"; Print("horizontal layout enabled.")
    elseif msg=="vertical" or msg=="layout vertical" then VCTDB.layout="vertical"; Print("vertical layout enabled.")
    elseif msg=="reset" then
        VCTDB.x=defaults.x; VCTDB.y=defaults.y; VCTDB.size=defaults.size; VCTDB.critSize=defaults.critSize
        VCTDB.spacing=defaults.spacing; VCTDB.iconSize=defaults.iconSize; VCTDB.layout=defaults.layout; VCTDB.scale=defaults.scale
        UpdateDragFrame(); Print("layout reset.")
    elseif string.find(msg,"^iconsize ") then
        local n=tonumber(string.sub(msg,10)); if n and n>=12 and n<=36 then VCTDB.iconSize=n; Print("icon size set to "..n) end
    else Print("commands: /vct test | on | off | icons on | icons off | iconsize 22 | scale 100 | horizontal | vertical | reset") end
end
local init=CreateFrame("Frame")
init:RegisterEvent("VARIABLES_LOADED")
init:SetScript("OnEvent",function()
    InitDB(); Apply(); UpdateDragFrame()
    Print("v0.4.13 loaded. Hold CTRL to reveal the drag area, then left-click and drag. Use /vct scale 50-200, /vct horizontal, or /vct vertical.")
end)
