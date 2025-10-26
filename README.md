# Wirebox
A Luau library that provides dependency injection based on constructors.

Languages like C#, TypeScript or Java often come with reflection and metadata attached to objects. However Luau, as an interpreted and sandboxed language, doesn't provide
anything similar. This library comes with a service Collection, which can be fed up with services using injector hook. Similar to C#, you define the service and it's lifetime.
However, the extra step is adding the dependencies constructors in the right order. The collection can later be built into a provider, where the required services can be accessed by their constructor.

The services can have only two lifetimes - singleton and transient. The singleton services are constructed once, and transient services are constructed on each request.

# Usage
See `/examples` for more.

```luau
local wirebox = require("wirebox")

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
```
