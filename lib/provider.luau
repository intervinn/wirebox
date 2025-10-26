local Provider = {}
Provider.__index = Provider

export type Service = {
    lifetime: "transient" | "singleton",
    constructor: (...any) -> any,
    factory: () -> any,
    instance: any?
}

export type Provider = typeof(setmetatable({}, Provider))

function Provider.new()
    return setmetatable({
        Services = {}
    }, Provider)
end

function Provider:Get<T>(constructor: (...any) -> T): T?
    for _, v: Service in self.Services do
        if v.constructor == constructor then
            return v.factory()
        end
    end
    return nil
end

function Provider:GetEntry<T>(constructor: (...any) -> T): Service?
    for _, v: Service in self.Services do
        if v.constructor == constructor then
            return v
        end
    end

    return nil
end

return Provider
