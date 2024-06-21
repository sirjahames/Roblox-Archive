local TableUtil = {}

export type Array<V> = { V } 
export type Map<K, V> = { [K]: V }

function TableUtil.Filter<K, V>(tbl: Map<K, V>, isArray: boolean, transform: (K, V) -> (boolean))
    local Copy = {}

    for key, value in tbl do
        if transform(key, value) then
            if not isArray then
                Copy[key] = value           --> for use with dictionaries
            else
                table.insert(Copy, value)   --> for use with arrays
            end
        end
    end

    return Copy
end

return TableUtil