local frktest = require("@pkg/frktest")
local Wirebox = require("../lib")
local Provider = Wirebox.Provider
local Collection = Wirebox.Collection

local check = frktest.assert.check
local req = frktest.assert.require
local test = frktest.test

return function() 
    test.case("app starts with logger", function() 
        local c = Collection.new()
        local provide = Wirebox.provide(c)

        local Logger = {}
        Logger.__index = Logger

        function Logger.new()
            return setmetatable({}, Logger)
        end

        function Logger:log(msg)
            print(msg)
        end

        local App = {}
        App.__index = App

        function App.new(logger)
            return setmetatable({
                Logger = logger
            }, App)
        end

        function App:start()
            self.Logger:log("hello world")
        end

        provide(Logger.new):Singleton():Name("Logger")
        provide(App.new):With(Logger.new):Singleton():Name("App")


        local p = Provider.FromCollection(c)

        local app = p:GetService(App.new)
        app:start()

        return nil
    end)
end