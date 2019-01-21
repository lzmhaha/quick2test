local BattleMap = class('BattleMap', function(filePath)
    return cc.TMXTiledMap:create(filePath)
    -- return cc.uiloader:load('res/publish/RPGGame.json')
end)

local MAP_MAX_SCALE = 5
local Map_MAX_SCALE_BACK = 4    -- 放大回弹
local MAP_MIN_SCALE = 0.2

local MIN_MOVE_DIS = 10 -- 触摸移动最小阈值

function BattleMap:ctor()
    self._spdDir = cc.p(0, 0)
    self._spd = 0
    self._pressing = false
    self._moveDelta = cc.p(0, 0)
    self._moving = false
    self._moveQueue = {} -- 储存3个滑动位移，用于滑动后缓动，取平均值表现更平滑
    self._size = self:getMapSize()
    self._tileSize = self:getTileSize()

    self:setTouchMode(cc.TOUCH_MODE_ALL_AT_ONCE)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self._onTouch))
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._update))
    self:scheduleUpdate_()
    self:setTouchSwallowEnabled(true)
    self:setTouchEnabled(true)

    self.floor = self:layerNamed('floor')
    -- 抗锯齿
    self.floor:getTexture():setAntiAliasTexParameters()
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
    self._pressing = true
    self._moveDelta.x = 0
    self._moveDelta.y = 0
    self._moveQueue = {}
    self._moving = false
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

    table.insert(self._moveQueue, {x = dx, y = dy})
    if #self._moveQueue > 3 then table.remove(self._moveQueue, 1) end

    -- 滑动距离过短，先不做移动处理
    if not self._moving then
        self._moveDelta.x = self._moveDelta.x + dx
        self._moveDelta.y = self._moveDelta.y + dy
        if self._moveDelta:getLength() > MIN_MOVE_DIS then
            self._moving = true
            dx = self._moveDelta.x
            dy = self._moveDelta.y
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

    if scale then self:scale(scale) end
    -- 判断是否超出范围
    local x, y = self:getPosition()
    x = x + dx
    y = y + dy
    x, y = self:_checkPos(x, y)
    self:pos(x, y)
end

function BattleMap:_onRelease(event)
    self._pressing = false
    if not self._moving then
        self:_onClick(event)
    else
        self._spdDir.x = 0
        self._spdDir.y = 0
        for i, p in ipairs(self._moveQueue) do
            self._spdDir.x = self._spdDir.x + p.x
            self._spdDir.y = self._spdDir.y + p.y
        end
        self._spdDir.x = self._spdDir.x / #self._moveQueue
        self._spdDir.y = self._spdDir.y / #self._moveQueue
        self._spd = self._spdDir:getLength()
        self._spdDir = self._spdDir:normalize()
    end
end

function BattleMap:_onClick(event)
    local x = event.points['0'].x
    local y = event.points['0'].y
    local grid = self:_touch2grid(x, y)
    if grid then
        print(string.format('on click, %d, %d', grid.x, grid.y))
        self.floor:setTileGID(4, cc.p(grid.x, grid.y))
    end
end

function BattleMap:_update(dt)
    if (not self._pressing) then
        if self._spd > 0 then
            local x, y = self:getPosition()
            x = x + self._spdDir.x * self._spd
            y = y + self._spdDir.y * self._spd
            local xok, yok
            x, y, xok, yok = self:_checkPos(x, y)
            self:pos(x, y)
            self._spd = (xok or yok) and self._spd - 1 or 0
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

function BattleMap:_touch2grid(x, y)
    local posInMap = self:convertToNodeSpaceAR(cc.p(x, y))
    -- 锚点(0.5, 1)的坐标，因为图块(0, 0)在地图的正上方
    local originX = posInMap.x
    local originY = self._tileSize.height * self._size.height * 0.5 - posInMap.y
    local gridX = math.floor(originX / self._tileSize.width + originY / self._tileSize.height)
    local gridY = math.floor(originY / self._tileSize.height - originX / self._tileSize.width)
    if gridX < 0 or gridX >= self._size.width or gridY < 0 or gridY >= self._size.height then return nil end
    return cc.p(gridX, gridY)
end

return BattleMap