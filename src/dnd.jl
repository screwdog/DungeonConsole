#=--------------------------------------------------------------------------------
D&D combat mechanics
--------------------------------------------------------------------------------=#
# this is essentially an @enum type, perhaps replace?
# @enum RollType roll_adv roll_dis roll_norm
# parse(::Type{RollType}, String/Char)
"""
`RollType`

Represents whether a d20 dice roll has advantage/disadvantage. For convenience use constants
`roll_adv`, `roll_dis`, or `roll_norm`. Can also be parsed from characters `⬆`, `⬇`.
"""
struct RollType
    adv::Union{Nothing, Bool}
end
const roll_adv = RollType(true)
const roll_dis = RollType(false)
const roll_norm = RollType(nothing)
RollType() = RollType(nothing)
function RollType(c::Char)
    c == '⬆' && return roll_adv
    c == '⬇' && return roll_dis
    return roll_norm
end
RollType(str) = str |> only |> RollType

"""
`Dice`

Represents a D&D dice roll like "1d8+2", or a flat result like "4". Use `roll(::Dice)` to
get a random roll and `max`/`min` to get the range of possible results.
"""
struct Dice
    numdice::Int
    sides::Int
    bonus::Int
end
function Dice(str)
    # flat result in the form "[4]"? (Since [] are used to delimit such values)
    n = tryparse(Int, strip(str, ['[', ']']))
    n ≠ nothing && return Dice(0, 1, n)
    # otherwise, needs to be like 1d8±2 or 2d20
    m = match(r"(\d+)d(\d+)\s*((?:\+|-)\d+)?", str)
    nums = filter(!isnothing, collect(m))
    length(nums) ≤ 2 && push!(nums, "0")
    return Dice(parse.(Int, nums)...)
end
roll(d::Dice) = (rand(1:d.sides, d.numdice) |> sum) + d.bonus
min(d::Dice) = d.numdice + d.bonus
max(d::Dice) = d.numdice * d.sides + d.bonus

# also essentially @enum Defence def_fly, def_swim, def_norm
"""
`Defence`

Represents whether a creature is flying or swimming. For convenience use constants `def_fly`,
`def_swim`, or `def_norm`. Can also be parsed from strings `☁️` (flying) and `🌊`
(swimming).
"""
struct Defence
    flyorswim::Union{Nothing, Bool}
end
const def_fly = Defence(true)
const def_swim = Defence(false)
const def_norm = Defence(nothing)
Defence() = Defence(nothing)
function Defence(s::AbstractString)
    s == "☁️" && return def_fly
    s == "🌊" && return def_swim
    return def_norm
end

# @Dungeons lists enemies by type using emojis (from "config/emojis.toml" in the source)
const MONSTER_TYPE = Dict(
    "💀"        => "undead",
    "🔥"         => "elemental",
    "👼"        => "celestial",
    "🗿"         => "giant",
    "🦁"        => "beast",
    "🤖"        => "construct",
    "🦂"        => "yugoloth",
    "👿"        => "devil",
    "🦑"        => "aberration",
    "🧍\u200d♂️"  => "humanoid",
    "🧚"        => "fey",
    "🦠"        => "ooze",
    "👺"        => "fiend",
    "🧟"        => "monstrosity",
    "👹"        => "demon",
    "🐉"        => "dragon",
    "🌱"        => "plant",
    "default"   => "unknown"
)

monster_type(str) = MONSTER_TYPE[getkey(MONSTER_TYPE, str, "default")]
