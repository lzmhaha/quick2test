require("config")
require("framework.init")

function gettext(text)
    return text
end
local langPath = "res/langs/"..LANGUAGE..'.mo'
if CCFileUtils:sharedFileUtils():isFileExist(langPath) then
    gettext = assert(require("framework.cc.utils.Gettext").gettextFromFile(langPath))
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
