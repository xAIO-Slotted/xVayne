local core = require("xCore")
local name = "xVayne"
local version = "0.0.1"

local function updater()

    local vu = "https://raw.githubusercontent.com/username/repository/main/version.txt"

    local uu = "https://raw.githubusercontent.com/username/repository/main/myscript.lua"

    local fp = "/path/to/myscript.lua"

    local latestVersion = tonumber(io.open(vu):read("*all"):match("%d+"))

    if latestVersion > version then
        local handle = io.open(fp, "w")
        handle:write(io.open(uu):read("*all"))
        handle:close()

        print("[xAIO] Updated xVayne. Please reload!")
    else
        print("[xAIO] xVayne is up to date!")
    end

end

local Class = function(...)
    local cls = {}
    cls.__index = cls
    function cls:New(...)
        local instance = setmetatable({}, cls)
        cls.__init(instance, ...)
        return instance
    end
    cls.__call = function(_, ...) return cls:New(...) end
    return setmetatable(cls, {__call = cls.__call})
end

local myHero = g_local

local add_nav = menu.get_main_window():push_navigation(name + " " + version, 10000)
local navigation = menu.get_main_window():find_navigation(name + " " + version)

-- Sections
local combo_sec = navigation:add_section("Combo")
local harass_sec = navigation:add_section("Harass")
local clear_sec = navigation:add_section("Clear")
local misc_sec = navigation:add_section("Misc")
local draw_sec = navigation:add_section("Draw")
local peel_sec = navigation:add_section("Peel")
local duel_sec = navigation:add_section("Duel")

-- Misc

local auto_e = misc_sec:add_checkbox("Auto E", "auto_e", true)
local auto_e_hc = misc_sec:select("E Hitchance", g_config:add_int(3, "auto_e_hc"), 3, {"Low", "Normal", "High", "Very High", "Immobile"})

---------------------------------

-------- CollisionResult --------

local CollisionResult = Class()

function CollisionResult:__init()
    self.Result = false
    self.Positions = {}
    self.Objects = {}
end

function CollisionResult:add_pos(pos)
    table.insert(self.Positions, pos)
end

function CollisionResult:ad_obj(obj)
    table.insert(self.Objects, obj)
end

---------------------------------

------------- Math -------------

local Math = Class()

function Math:__init() end

function Math:get_wall(startPos, endPos, width, speed, delay_ms)
    local direction = (endPos - startPos):normalized()
    local distance = (endPos - startPos):len()

    local targetPos = endPos

    local result = CollisionResult()
    result.Result = false

    for i = 1, distance do
        local currentPos = startPos + direction * i
        local tileX, tileY = currentPos.x, currentPos.z -- assuming a 2D terrain with X and Z coordinates
        local tpos = vec3:new(tileX, 0, tileY):get_navgrid_type()

        if g_navgrid:is_wall(tpos) or g_navgrid:is_building(tpos) then
            result.Result = true
            result:AddPosition(currentPos) -- store the wall position in the Positions array
            break
        end

        local projectileTime = (currentPos - startPos):len() / speed
        local targetDist = (targetPos - currentPos):len()

        if targetDist <= width and targetDist <= speed * (delay_ms / 1000 - projectileTime) then
            result.Result = true
            result:AddPosition(currentPos) -- store the wall position in the Positions array
            break
        end
    end

    return result
end

function Math:can_condemn(pos, from)
    from = from or myHero.position
    local startPos = pos:extend(from, -50)
    local endPos   = pos:extend(from, -425)
    return self:get_wall(startPos, endPos, 10, 25000, 250).Result
end

function Math:get_condemn_chance(target, from)
    local tPos = target.Position
    if not self:can_condemn(tPos, from) then return -1 end

    local colChance, maxCols = 0, 8
    local delay = core.helper:get_latency()/1000 + spells.E_Pred.Delay
    local points = circle_t:new(tPos, target.movement_speed * delay):to_polygon(tPos, 0, maxCols).points
    for k, point in ipairs(points) do
        if self:can_condemn(point, from) then
            colChance = colChance + 1
        end
    end
    return colChance
end



---------------------------------

------------- Data -------------

local Data = Class()

function Data:__init()
    self.last_tick = 0
    self.Q = {
        mana_cost = { 30, 30, 30, 30, 30 },
        spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.q),
        spell_slot = e_spell_slot.q,
        range = 300,
        level = 0,
    }
    self.E = {
    mana_cost = { 90, 90, 90, 90, 90 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.e),
    spell_slot = e_spell_slot.e,
    range = 550,
    cast_time = 0.25,
    level = 0,
    }
    self.R = {
    mana_cost = { 80, 80, 80 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.r),
    spell_slot = e_spell_slot.r,
    level = 0,
    }
    cheat.register_callback("feature", Data:refresh())
end

function Data:refresh_data()

    -- TODO

end

function Data:refresh()
    Data:refresh_data()
end

---------------------------------

------------- Vayne -------------

local Vayne = Class()

function Vayne:__init()
    self.last_tick = 0

    self.data = Data:New()
    self.math = Math:New()

    cheat.register_callback("feature", self:run())
end

function Vayne:run()
    local time = g_time
    if time < (last + 0.25) and myHero.is_alive then return end
    last = time



end

function Vayne:auto()
    local mode = features.orbwalker:get_mode()
    if self.data.E.spell:is_ready() and auto_e:get_value() then

        local minChance = auto_e_hc:get_value() + 3
        local targets = core.target_selector.get_targets(550)

        for k, t in ipairs(targets) do
            if Vayne:get_condemn_chance(t) >= minChance then
                g_input:cast_spell(self.data.E.spell_slot, t)
                return
            end
        end

    end


end

cheat.register_callback("feature", Data:refresh())


