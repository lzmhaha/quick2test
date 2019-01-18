local BattleMap = class('BattleMap', function(filePath)
    return cc.TMXTiledMap:create(filePath)
    -- return cc.uiloader:load('res/publish/RPGGame.json')
end)

local MAP_MAX_SCALE = 5
local Map_MAX_SCALE_BACK = 4    -- 放大回弹
local MAP_MIN_SCALE = 0.2

local MIN_MOVE_DIS = 10 -- 触摸移动最小阈值

function BattleMap:ctor()
    self.spdDir = cc.p(0, 0)
    self.spd = 0
    self.pressing = false
    self.moveDelta = cc.p(0, 0)
    self.moving = false
    self.moveQueue = {} -- 储存3个滑动位移，用于滑动后缓动，取平均值表现更平滑

    self:setTouchMode(cc.TOUCH_MODE_ALL_AT_ONCE)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self._onTouch))
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._update))
    self:scheduleUpdate_()
    self:setTouchSwallowEnabled(true)
    self:setTouchEnabled(true)

    local floor = self:layerNamed('floor')
    floor:setTileGID(4, cc.p(0, 0))
    -- 抗锯齿
    floor:getTexture():setAntiAliasTexParameters()
end

function BattleMap:_onTouch(event)
    if event.name == 'began' then
        self:_onPress()
    elseif event.name == 'moved' then
        self:_onMove(event)
    elseif event.name == 'ended' then
        self:_onRelease(event)
    end
end

function BattleMap:_onPress(event)
    self.pressing = true
    self.moveDelta.x = 0
    self.moveDelta.y = 0
    self.moveQueue = {}
    self.moving = false
end

function BattleMap:_onMove(event)
    local dx = 0
    local dy = 0
    local points = event.points
    local midPoint = cc.p()
    local scale
    local isMulTouch = not not points['1']
    for i = 0, 1 do
        point = points[tostring(i)]
        if not point then break end
        dx = dx + point.x - point.prevX
        dy = dy + point.y - point.prevY
        midPoint.x = midPoint.x + point.prevX
        midPoint.y = midPoint.y + point.prevY
    end
    if isMulTouch then
        dx = dx / 2
        dy = dy / 2
    end

    table.insert(self.moveQueue, {x = dx, y = dy})
    if self.moveQueue[3] then table.remove(self.moveQueue, 1) end

    -- 滑动距离过短，先不做移动处理
    if not self.moving then
        self.moveDelta.x = self.moveDelta.x + dx
        self.moveDelta.y = self.moveDelta.y + dy
        if self.moveDelta:getLength() > MIN_MOVE_DIS then
            self.moving = true
            dx = self.moveDelta.x
            dy = self.moveDelta.y
        else
            return
        end
    end

    if isMulTouch then
        midPoint.x = midPoint.x / 2
        midPoint.y = midPoint.y / 2
        local p1 = points['0']
        local p2 = points['1']
        local dis1 = cc.PointDistance(cc.p(p1.prevX, p1.prevY), cc.p(p2.prevX, p2.prevY))
        local dis2 = cc.PointDistance(cc.p(p1.x, p1.y), cc.p(p2.x, p2.y))
        scale = dis2 / dis1

        -- 计算由缩放导致的坐标位移
        local originScale = self:getScale()
        local posInMap = self:convertToNodeSpaceAR(midPoint)
        scale = originScale * scale
        if scale > MAP_MAX_SCALE then scale = MAP_MAX_SCALE end
        if scale < MAP_MIN_SCALE then scale = MAP_MIN_SCALE end
        dx = dx - posInMap.x * (scale - originScale)
        dy = dy - posInMap.y * (scale - originScale)
    end

    -- 判断是否超出范围
    local x, y = self:getPosition()
    x = x + dx
    y = y + dy
    x, y = self:_checkPos(x, y)

    self:pos(x, y)
    if scale then self:scale(scale) end
end

function BattleMap:_onRelease(event)
    self.pressing = false
    if not self.moving then
        self:_onClick(event)
    else
        self.spdDir.x = 0
        self.spdDir.y = 0
        for i, p in ipairs(self.moveQueue) do
            self.spdDir.x = self.spdDir.x + p.x
            self.spdDir.y = self.spdDir.y + p.y
        end
        self.spdDir.x = self.spdDir.x / #self.moveQueue
        self.spdDir.y = self.spdDir.y / #self.moveQueue
        self.spd = self.spdDir:getLength()
        self.spdDir = self.spdDir:normalize()
    end
end

function BattleMap:_onClick(event)
    local x = event.points['0'].x
    local y = event.points['0'].y
    print(string.format('on click, %d, %d', x, y))
end

function BattleMap:_update(dt)
    if (not self.pressing) then
        if self.spd > 0 then
            local x, y = self:getPosition()
            x = x + self.spdDir.x * self.spd
            y = y + self.spdDir.y * self.spd
            local xok, yok
            x, y, xok, yok = self:_checkPos(x, y)
            self:pos(x, y)
            self.spd = (xok or yok) and self.spd - 1 or 0
        else
            -- 回弹
        end
    end
end

-- 检测坐标是否超过边界
function BattleMap:_checkPos(_x, _y)
    local x, y = _x, _y
    local scale = self:getScale()
    local size = self:getContentSize()
    if x - size.width / 2 * scale > 0 then x = size.width / 2 * scale end
    if x + size.width / 2 * scale < display.width then x = display.width - size.width / 2 * scale end
    if y - size.height / 2 * scale > 0 then y = size.height / 2 * scale end
    if y + size.height / 2 * scale < display.height then y = display.height - size.height / 2 * scale end
    return x, y, x == _x, y == _y
end

return BattleMap