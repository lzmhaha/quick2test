local BattleMap = class('BattleMap', function(filePath)
    return cc.TMXTiledMap:create(filePath)
    -- return cc.uiloader:load('res/publish/RPGGame.json')
end)

local MAP_MAX_SCALE = 5
local MAP_MIN_SCALE = 0.2


function BattleMap:ctor()
    self:setTouchMode(cc.TOUCH_MODE_ALL_AT_ONCE)
    -- self:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, handler(self, self._onTouch))
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self._onTouch))
    self:setTouchSwallowEnabled(true)
    self:setTouchEnabled(true)

    local floor = self:layerNamed('floor')
    floor:setTileGID(4, cc.p(0, 0))
    -- 抗锯齿
    floor:getTexture():setAntiAliasTexParameters()
end

function BattleMap:_onTouch(event)
    if event.name ~= 'moved' then return true end
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
    local size = self:getContentSize()
    x = x + dx
    y = y + dy
    scale = scale or self:getScale()
    if x - size.width / 2 * scale > 0 then x = size.width / 2 * scale end
    if x + size.width / 2 * scale < display.width then x = display.width - size.width / 2 * scale end
    if y - size.height / 2 * scale > 0 then y = size.height / 2 * scale end
    if y + size.height / 2 * scale < display.height then y = display.height - size.height / 2 * scale end

    self:pos(x, y)
    self:scale(scale)
end

return BattleMap