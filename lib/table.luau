
local Table = {}
Table.__index = Table

function Table.Map<T, R>(t: {T}, fn: (T) -> R): {R}
    local r = {}
    for _, v in t do
        table.insert(r, fn(v))
    end
    return r
end

function Table.Fold<T, R>(t: {T}, fn: (T, R) -> R, acc: R)
    local res = acc
    for _, v in t do
        res = fn(v, acc)
    end
    return res
end

function Table.Filter<T>(t: {T}, fn: (T) -> boolean): {T}
    local res = {}
    for _, v in t do
        if fn(v) then
            table.insert(res, v)
        end
    end
    return res
end

function Table.IsArray(t)
    return t[1] ~= nil
end

function Table.DeepCopy(t)
    local res = {}
    if Table.IsArray(t) then
        for _, v in t :: any do
            if type(v) == "table" then
                table.insert(res, Table.DeepCopy(v))
            else
                table.insert(res, v)
            end
        end
    else
        for k, v in t :: any do
            if type(v) == "table" then
                res[k] = Table.DeepCopy(v)
            else
                res[k] = v
            end
        end
    end
    return res :: any
end

function Table.First<T>(t: {T}, predicate: (T) -> boolean): T?
    for _, v in t do
        if predicate(v) then return v end
    end
    return nil
end

function Table.Assign<A, B>(a: A, b: B) : A & B
    for k, v in a :: any do
        (b :: any)[k] = v
    end
    return b :: A & B
end

function Table.ForEach<T>(t : {T}, f: (i: number, v: T) -> ()): ()
    for i, v in t do
        f(i, v)
    end
end

return Table
