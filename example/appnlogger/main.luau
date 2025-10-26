local wirebox = require("../../lib")

local collection = wirebox.Collection.new()
local inject = wirebox.createInjector(collection)

local Logger = {}
Logger.__index = Logger

function Logger.new()
    return setmetatable({}, Logger)
end

function Logger:log(msg)
    print(msg)
end

inject(Logger.new)
    :asTransient()

local App = {}
App.__index = App

function App.new(logger)
    return setmetatable({
        logger = logger
    }, App)
end

function App:hello()
    self.logger:log("world")
end

inject(App.new)
    :with(Logger.new)
    :asSingleton()

local provider = collection:BuildProvider()
local app = provider:Get(App.new)
if not app then return end
app:hello()
