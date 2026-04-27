local Scorer = {}

function Scorer.score(pattern, added_score, multiplier_mod)
    added_score = added_score or 0
    multiplier_mod = multiplier_mod or 1
    if not pattern then
        return { pattern = "", base_score = 0, pattern_mult = 0, final_score = 0 }
    end
    local final = math.floor((pattern.base_score + added_score) * pattern.mult * multiplier_mod + 0.5)
    return {
        pattern = pattern.display,
        pattern_id = pattern.id,
        base_score = pattern.base_score,
        pattern_mult = pattern.mult,
        final_score = final,
    }
end

return Scorer
