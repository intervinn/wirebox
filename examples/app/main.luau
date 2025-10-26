local wirebox = require("../../lib")

local collection = wirebox.Collection.new()
local inject = wirebox.createInjector(collection)

----------------------- logger
local Logger = {}
Logger.__index = Logger

function Logger.new()
    print("BUILDING LOGGER")
    return setmetatable({}, Logger)
end

function Logger:log(message)
    print(message)
end

inject(Logger.new)
    :asSingleton()
    :name("Logger")

----------------------- store
local Store = {}
Store.__index = Store

function Store.new(logger)
    print("BUILDING STORE")
    return setmetatable({
        logger = logger,
        store = {}
    }, Store)
end

function Store:Put(key, value)
    self.logger:log(`putting {key}-{value}`)
    self.store[key] = value
end

function Store:Get(key, value)
    self.logger:log(`getting {key}-{value}`)
    return self.store[key]
end

inject(Store.new)
    :with(Logger.new)
    :asSingleton()
    :name("Store")

----------------------- app
local App = {}
App.__index = App

function App.new(logger, store)
    print("BUILDING APP")
    return setmetatable({
        logger = logger,
        store = store
    }, App)
end

function App:start()
    self.store:Put("world", "hello")
    self.logger:log("app: hello world!")
end

inject(App.new)
    :asSingleton()
    :with(Logger.new)
    :with(Store.new)
    :name("App")

local provider = collection:BuildProvider()
provider:Get(App.new):start()
-- putting world-hello
-- app: hello world!

local app = provider:Get(App.new)
local store = provider:Get(Store.new)
print(app.logger == store.logger) -- true
