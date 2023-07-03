Utils = {}

function Utils.RoundFloat(Number, DecimalPlace)
    local Multiplier = math.pow(10, DecimalPlace)
    return math.floor(Number * Multiplier + 0.5) / Multiplier
end

return Utils