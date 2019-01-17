local AStar = class('AStar')

-- grids 为一维数组 0: 空地 1: 障碍物
AStar._grids = nil
AStar.width = 0
AStar.height = 0

local SQRT_2 = math.sqrt(2)

function AStar:ctor(grids, width, height)
    if grids then self:init(grids, width, height) end
end

function AStar:init(grids, width, height)
    if #grids ~= width * height then
        printError('err: grids\' lenght is not equal to width * height')
        return
    end
    self._grids = grids
    self.width = width
    self.height = height
end

function AStar:searchPath(start, goal)
    if not self._grids then
        printError('err: astar has not inited')
        return
    end
    if not self:_isPosInMap(start.x, start.y) then
        printError('err: start point is not in map (%d, %d)', start.x, start.y)
        return
    end
    if not self:_isPosInMap(goal.x, goal.y) then
        printError('err: goal point is not in map (%d, %d)', goal.x, goal.y)
        return
    end

    local startIdx = self:_pos2Idx(start.x, start.y)
    local goalIdx = self:_pos2Idx(goal.x, goal.y)
    local cur = startIdx
    local open = {}
    local close = {[cur] = true}
    local g = {[cur] = 0}   -- 从起点到当前位置的实际消耗
    local h = {}            -- 当前点到目标点的消耗估计值
    local f = {}            -- f = g + h
    local from = {}

    while cur ~= goalIdx do
        -- 确保cur周围的点都加入到open列表，并判断是否从当前点'过去'会更近
        local x, y = self:_idx2Pos(cur)
        local nears = self:_getNearPoints(x, y)
        table.walk(nears, function(p)
            local idx = self:_pos2Idx(p.x, p.y)
            if self:_isBlockAt(p.x, p.y) or close[idx] then
                return
            elseif table.indexof(open, idx) then
                if g[cur] + 1 < g[idx] then
                    g[idx] = g[cur] + self:_calculateDis(x, y, p.x, p.y)
                    f[idx] = g[idx] + h[idx]
                    from[idx] = cur
                end
            else
                g[idx] = g[cur] + self:_calculateDis(x, y, p.x, p.y)
                h[idx] = self:_calculateDis(x, y, goal.x, goal.y)
                f[idx] = g[idx] + h[idx]
                table.insert(open, idx)
                from[idx] = cur
            end
        end)

        -- 在open列表中找到f值最小的点，加入到close列表
        local minIdx = -1
        local minF = -1
        for _, idx in ipairs(open) do
            if minF < 0 or f[idx] < minF then
                minF = f[idx]
                minIdx = idx
            end
        end

        if minIdx == -1 then
            printError('search path fail from (%d, %d) to (%d, %d)', start.x, start.y, goal.x, goal.y)
            return
        else
            cur = minIdx
            table.remove(open, table.indexof(open, cur))
            close[cur] = true
        end
    end

    local path = {}
    while cur ~= startIdx do
        local x, y = self:_idx2Pos(cur)
        table.insert(path, 1, {x = x, y = y})
        cur = from[cur]
    end
    return path
end

function AStar:printMap(path)
    local strs = {}
    for y = self.height, 1, -1 do
        for x = 1, self.width, 1 do
            if self:_isBlockAt(x, y) then
                table.insert(strs, '@ ')
            else
                table.insert(strs, '- ')
            end
        end
        table.insert(strs, '\n')
    end
    if path and #path then
        for i, p in ipairs(path) do
            local idx = p.x + (self.height - p.y) * (self.width + 1) -- width+1 是加上 '\n'
            strs[idx] = '* '
        end
    end
    print('-------------------map----------------\n' .. table.concat(strs))
end

-- private
function AStar:_isBlockAt(x, y)
    return self._grids[self:_pos2Idx(x, y)] ~= 0
end

-- 获取周围连接的点
function AStar:_getNearPoints(x, y)
    local ret = {}
    for dx = -1, 1 do
        for dy = -1, 1 do
            local inMap = self:_isPosInMap(x + dx, y + dy)  -- 是否在地图内
            local isSelf = dx == 0 and dy == 0              -- 是否为中心点
            local isDiagonal = dx ~= 0 and dy ~= 0           -- 是否为对角点

            -- 4方向
            -- if (not isSelf) and (not isDiagonal) and inMap then
            --     table.insert(ret, {x = x + dx, y = y + dy})
            -- end

            -- 8方向
            -- if inMap and (not isSelf) and ((not isDiagonal) or not(self:_isBlockAt(x, y + dy) and self:_isBlockAt(x + dx, y))) then
            if inMap and not isSelf then
                table.insert(ret, {x = x + dx, y = y + dy})
            end
        end
    end
    return ret
end

-- 计算两点之间的移动消耗（不考虑地形障碍物）
function AStar:_calculateDis(x1, y1, x2, y2)
    local dx = math.abs(x1 - x2)
    local dy = math.abs(y1 - y2)
    -- return dx + dy  -- 4方向
    local min = math.min(dx, dy)
    local max = math.max(dx, dy)
    return min * SQRT_2 + (max - min) -- 8方向
end

function AStar:_isPosInMap(x, y)
    if x < 1 or x > self.width or y < 0 or y > self.height then return false end
    return true
end

function AStar:_pos2Idx(x, y)
    return x + (y - 1) * self.width
end

function AStar:_idx2Pos(idx)
    local x = math.mod(idx - 1, self.width) + 1
    local y = math.ceil(idx / self.width)
    return x, y
end

return AStar