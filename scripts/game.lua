require("config")
require("framework.init")

function _(text)
    return text
end
local langPath = "res/langs/"..LANGUAGE..'.mo'
if CCFileUtils:sharedFileUtils():isFileExist(langPath) then
    local t = assert(require("framework.cc.utils.Gettext").gettextFromFile(langPath))
    _ = function(format, ...)
        return string.format(t(format), ...)
    end
end

-- define global module
game = {}

function game.startup()
    CCFileUtils:sharedFileUtils():addSearchPath("res/")
    game.showDemoScene()
end

function game.exit()
    --CCDirector:sharedDirector():endToLua()
    os.exit()
end

function game.showDemoScene()
    display.replaceScene(require("MainScene").new(), "fade", 0.6, display.COLOR_WHITE)
end
