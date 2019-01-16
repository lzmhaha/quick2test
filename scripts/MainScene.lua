local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    -- local bg = display.newColorLayer(cc.c4b(255, 255, 255, 255))
    -- bg:addTo(self)
    math.randomseed(os.time())

    -- local lb = ui.newBMFontLabel({text = '123', font = 'fonts/font.fnt'})
    _('apple')
    local num = 7
    local name = 'John'
    local text = _('I have %d apples', num) .. '\n' .. _('my name is %s', name)
    local lb = ui.newTTFLabel({text = text, size = 40, color = display.COLOR_BLACK})
    lb:pos(display.cx, display.cy):addTo(self, 1)
    self.lb = lb

    self:addMap()
    self:addSprite()

    self:addButton()
    self:addListView()
    self:addScrollView()
    self:addPageView()
    self:addUi()

    self:scheduleUpdate(handler(self, self.update))
    -- self:scheduleUpdate_()

    -- self:ioTest()
    self:drawcallTest()

    -- 截屏
    -- display.printscreen(self, {file = device.writablePath..'la.jpg'})

    self:hotUpdateTest()

    self:blendFuncTest()
end

function MainScene:onEnter()
    print('on enter')
end

function MainScene:onExit()
    print('on exit')
end

function MainScene:addButton()
    -- local btn = ui.newImageMenuItem({
    --     image = 'res/imgs/btn1.png',
    --     imageSelected = 'res/imgs/btn2.png',
    --     listener = function()
    --         print('on btn click')
    --     end
    -- })
    -- local menu = ui.newMenu({btn})
    -- menu:addTo(self):pos(100, 100)

    -- local btn = cc.ui.UIPushButton.new('res/imgs/btn1.png')
    local btn = cc.ui.UIPushButton.new({
        normal = 'res/imgs/btn1.png',
        pressed = 'res/imgs/btn2.png',
        disabled = 'res/imgs/btn3.png',
    })
    btn:onButtonClicked(function()
        print('on btn click')
    end)
    btn:addTo(self):pos(100, 100)
end

function MainScene:addSprite()
    local sprite = display.newSprite('res/imgs/shield.png', x, y, params)
    -- sprite:setTouchMode(cc.TOUCH_MODE_ALL_AT_ONCE)
    sprite:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        -- print(event.name)
        if event.name == 'began' then
            return true
        elseif event.name == 'moved' then
            local x, y = sprite:getPosition()
            local touch
            if event.mode == cc.TOUCH_MODE_ALL_AT_ONCE then
                touch = event.points['0']
            else
                touch = event
            end
            sprite:pos(x + touch.x - touch.prevX, y + touch.y - touch.prevY)
        end
    end)
    sprite:setTouchEnabled(true)
    sprite:addTo(self):pos(200, 100)
    -- sprite:addTo(self._map):pos(3200, 1600)
    -- sprite:addTo(self._map, 10):pos(300, 100)
    self.sp = sprite
end

function MainScene:addEditBox()
    local editbox = ui.newEditBox({image = 'res/imgs/btn3.png', size = cc.size(119, 45), listener = function(eventName)
        print('on edit', eventName)
    end})
    editbox:addTo(self):pos(300, 100)
end

function MainScene:addMap()
    local map = require('battle.BattleMap').new('res/maps/map.tmx')
    map:addTo(self):align(display.CENTER)
    -- map:align(display.CENTER)
    -- battleLayer:addScrollNode(map)
    
    self._map = map
end

function MainScene:addListView()
    local rect = cc.rect(0, 0, 150, 300)
    local lv = cc.ui.UIListView.new({
        viewRect = rect,
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        bgColor = cc.c4b(123, 123, 0, 123),
    })
    lv:addTo(self):pos(800, 100)

    for i = 1, 10 do
        local btn = cc.ui.UIPushButton.new({
            normal = 'imgs/btn2.png',
            pressed = 'imgs/btn3.png',
        }):onButtonClicked(function()
            print('on btn click')
        end)
        btn:setTouchSwallowEnabled(false) -- 触摸按钮也能滚动

        local item = lv:newItem(btn)
        item.setMargin({left = 20, right = 20, top = 200, bottom = 20}) -- 不生效
        item:setBg('res/imgs/btn1.png')
        item:setItemSize(100, 60)
        lv:addItem(item)
    end
    lv:reload()
end

function MainScene:addScrollView()
    local rect = cc.rect(200, 400, 200, 200)
    local sv = cc.ui.UIScrollView.new{viewRect = rect, direction = cc.ui.UIScrollView.DIRECTION_VERTICAL}
    sv:addBgColorIf({bgColor = ccc4(125, 125, 125, 255), viewRect = rect})
    sv:addTo(self)
        -- :pos(20, 200)

    local panel = cc.ui.UIPanel.new({})
    -- panel:size(100, 300)
    -- panel:pos(100, 0)
    sv:addScrollNode(panel)

    for i = 1, 10 do
        -- local btn = cc.ui.UIPushButton.new('imgs/btn1.png', {listener = function()
        --     print('on btn click')
        -- end})addTo(panel):pos(0, 45 * i)
        display.newSprite('imgs/btn1.png', 300, 45 * i):addTo(panel)
    end

    -- 使用此函数，前提是scrollview坐标为(0,0)，由viewRect来确定显示位置
    sv:resetPosition()
    -- sv:scrollAuto()
end

function MainScene:addPageView()
    local pv = cc.ui.UIPageView.new({
        viewRect = cc.rect(20, 20, 200, 200),
        column = 2,
        row = 4,
        columnSpace = 5,
        rowSpace = 5,
        padding = {left = 5, right = 5, top = 5, bottom = 5},
    })
    pv:size(200, 200)
    for i = 1, 16 do
        local item = pv:newItem()
        local sp = display.newScale9Sprite('imgs/btn1.png')
        sp:size(item:getContentSize())
        pv:addItem(sp)
    end
    pv:reload()
    pv:onTouch(function(event)
        if event.name ~= 'clicked' then return end
        print(event.itemIdx)
        local item = event.item
        if item then
            -- local s1 = cc.ScaleTo:create(0.1, 0.9)
            -- local s2 = cc.ScaleTo:create(0.1, 1.0)
            -- local a = cc.Sequence:createWithTwoActions(s1, s2)
            -- item:runAction(a)
            item:setColor(cc.c3b(255, 0, 255))
        end
    end)
    pv:addTo(self)
    -- :pos(200, 400)
end

function MainScene:addUi()
    local uiNode =  cc.uiloader:load('studios/UITest/UITest.json')
    uiNode:addTo(self)
        -- :pos(500, 100)
end

function MainScene:ioTest()
    local fileName = device.writablePath..'text.txt'
    local success, err = pcall(function()
        local fout = io.open(fileName, 'w')
        io.output(fout)
        io.write('write sth')
        io.close(fout)
    end)
    print('----------------- write success?', success, err)
    print(device.writablePath)

    self:performWithDelay(function()
        local success, err = pcall(function()
            local fin = io.open(fileName, 'r')
            io.input(fin)
            local str = io.read('*a')
            io.close(fin)
            self.lb:setString(str)
        end)
        print('----------------- read success?', success, err)
    end, 1)
end

function MainScene:drawcallTest()
    display.addSpriteFramesWithFile('imgs/atlas.plist', 'imgs/atlas.png')
    local node = display.newBatchNode('imgs/atlas.png')
    -- local node = display.newNode()
    local function getSp()
        return display.newSprite('#a'..tostring(math.random(1, 2))..'.png')
    end
    for i = 1, 10 do
        local sp = getSp()
        sp:addTo(node):pos(5 * i, 0)

        local sp1 = getSp()
        sp1:addTo(sp):pos(0, 20)

        local sp2 = getSp()
        sp2:addTo(sp):pos(0, -20)

        -- error
        -- local sp3 = display.newSprite('imgs/btn1.png')
        -- sp3:addTo(sp)

        -- error
        -- local lb = ui.newTTFLabel({text = 'asdasdasd'})
        -- lb:addTo(sp)
    end
    node:addTo(self):pos(50, 100)
end

function MainScene:setUserDataTest()
    cc.UserDefault:sharedUserDefault():setStringForKey('name', 'cwt')
    print(cc.UserDefault:sharedUserDefault():getStringForKey('name'))
end

local function checkDir(path)
    local lfs = require "lfs"
    local oldpath = lfs.currentdir()
    CCLuaLog("old path------> "..oldpath)

    if lfs.chdir(path) then
        lfs.chdir(oldpath)
        CCLuaLog("path check OK------> "..path)
        return true
    end

    if lfs.mkdir(path) then
        CCLuaLog("path create OK------> "..path)
        return true
    end
end

function MainScene:hotUpdateTest()
    print(require('test'))

    local lfs = require('lfs')
    local updPath = device.writablePath .. 'upd/'
    checkDir(updPath)
    cc.FileUtils:sharedFileUtils():addSearchPath(updPath) -- 这一句应该提前调用，在addSearchPath('res/')之, 确保先用到更新的资源
    local scripts = {
        'local t = 123',
        'print(123123123123)',
        'return t',
    }
    io.writefile(updPath .. 'test.lua', table.concat(scripts, "\n"), 'w')

    package.loaded['test'] = nil
    print(require('test'))
end

function MainScene:blendFuncTest()
    local f = ccBlendFunc()
    f.src = gl.GL_DST_COLOR
    f.dst = gl.GL_ONE_MINUS_SRC_ALPHA
    self.sp:setBlendFunc(f)
end

function MainScene:update(dt)
    -- print('on update', dt)
end

return MainScene
