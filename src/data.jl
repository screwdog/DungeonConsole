#=--------------------------------------------------------------------------------
Types to represent the game state
--------------------------------------------------------------------------------=#
# We divide the current game state into three parts: current character, current
# activity (location), and available actions (voting options).

# Broadly, these correspond to the profile page (character), status post (activity),
# and poll (actions).

# A SimpleX type is provided for each as a fall back with does no analysis and just
# stores the plaintext provided.

#=--------------------------------------------------------------------------------
Character (sheets) types
--------------------------------------------------------------------------------=#
abstract type AbstractCharacter end
struct SimpleCharacter <: AbstractCharacter
    text::String
    SimpleCharacter(str) = new(plaintext(str))
end

# character's current / maximum spell slots
struct Spells
    cantrips::Bool
    spells::Vector{Tuple{Int, Int}}
end
Spells() = Spells(false, Tuple{Int, Int}[])

# attribute modifier for given attribute value
modifier(attr) = round(Int, (attr - 10) / 2, RoundDown)

"""
`BasicCharacter`

Represents a basic @Dungeons character, tracking important static and dynamic values but not
in sufficient detail to allow for combat calculations. Use `BasicCharacter(str)` to parse
from an input string.
"""
struct BasicCharacter <: AbstractCharacter
    description::String
    hp::Tuple{Int, Int}
    level::Tuple{Int, Int}
    hitdice::Tuple{Int, Int}
    weapon::String
    shield::Bool
    armour::String
    spells::Spells
    gold::Int
    attributes::Vector{Int}
    campaign::Int
    birthdate::ZonedDateTime
end
BasicCharacter(itr) = BasicCharacter(itr...)
# TODO move this to "parsing.jl"
BasicCharacter(body::AbstractString) = BasicCharacter(
    body .|> (parsedesc, parsehp, parselevel, parsehitdice, parseweapon, parseshield,
        parsearmour, parsespells, parsegold, parseattributes, parsecampaign, parsebirth)
)

# does a character have access to magic?
ismagic(b::BasicCharacter) = length(b.spells.spells) > 0

#=--------------------------------------------------------------------------------
Activity types
--------------------------------------------------------------------------------=#
abstract type AbstractActivity end
struct SimpleActivity <: AbstractActivity
    text::String
    SimpleActivity(str) = new(plaintext(str))
end

"""
`Fighting`

For when currently engaged in combat. Stores the details of the opponent.
"""
struct Fighting <: AbstractActivity
    type::String
    name::String
    hp::Tuple{Int, Int}
    ac::Int
    defence::Defence
    cr::Rational
    xp::Int
end
Fighting(type, name, hpcur, hpmax, ac, defence, cr, xp) =
    Fighting(monster_type(type), name, parse.(Int, (hpcur, hpmax)), parse(Int, ac),
        Defence(defence), parserat(cr), parse(Int, xp))
Fighting(type, name, hpcur::AbstractString, hpmax::AbstractString, ac, cr, xp) =
    Fighting(type, name, hpcur, hpmax, ac, " ", cr, xp)

"""
`Adventuring`

For when currently adventuring but not in combat. Stores the details of the potential
opponent.
"""
struct Adventuring <: AbstractActivity
    type::String
    name::String
    hp::Tuple{Int, Int}
    defence::Defence
    cr::Rational
    xp::Int
end
Adventuring(type, name, hpmin, hpmax, defence, cr, xp) =
    Adventuring(monster_type(type), name, parse.(Int, (hpmin, hpmax)), Defence(defence),
        parserat(cr), parse(Int, xp))
Adventuring(type, name, hpmin::AbstractString, hpmax::AbstractString, cr, xp) =
    Adventuring(type, name, hpmin, hpmax, " ", cr, xp)

# These activities don't have significant data associated.
struct Shopping <: AbstractActivity end
struct InTown <: AbstractActivity end
# Not currently used as we ignore any posts that don't have polls. Included for potential
# future inclusion.
struct Dead <: AbstractActivity end
# Used when choosing a name for a new character
struct NewChar <: AbstractActivity
    campaign::Int
end
NewChar(str) = NewChar(parse(Int, str))

#=--------------------------------------------------------------------------------
Action (poll option) types
--------------------------------------------------------------------------------=#
abstract type AbstractAction end
# most actions are simple text and a number of votes
action(a::AbstractAction) = a.text
votes(a::AbstractAction) = a.votes

struct SimpleAction <: AbstractAction
    text::String
    votes::Int
    SimpleAction(str, votes) = new(plaintext(str), votes)
end

struct BasicAction <: AbstractAction
    text::String
    votes::Int
end

struct RestAction <: AbstractAction
    text::String
    votes::Int
end

# spell attack during combat. Separates out the spell level, name, damage and whether it has
# advantage/disadvantage.
struct SpellAction <: AbstractAction
    level::Int
    name::String
    damage::Dice
    advantage::RollType
    votes::Int
end
SpellAction(leveltext::AbstractString, name, damagetext, advtext, votes) =
    SpellAction(parse(Int, leveltext), name, Dice(damagetext), RollType(advtext), votes)
SpellAction(leveltext, name, damagetext, votes) =
    SpellAction(leveltext, name, damagetext, " ", votes)

# similar to the spell attack
struct AttackAction <: AbstractAction
    name::String
    damage::Dice
    advantage::RollType
    votes::Int
end
AttackAction(name, damagetext::AbstractString, advtext::AbstractString, votes) =
    AttackAction(name, Dice(damagetext), RollType(advtext), votes)
AttackAction(name, damagetext::AbstractString, adv::RollType, votes) =
    AttackAction(name, Dice(damagetext), adv, votes)
AttackAction(name, damagetext, votes) = AttackAction(name, damagetext, " ", votes)

# Items for purchase in a shop. Currently just discards the damage/ac of the item.
struct PurchaseAction <: AbstractAction
    name::String
    cost::Int
    votes::Int
end
PurchaseAction(name, combatval, costtext, votes) =
    PurchaseAction(name, parse(Int, costtext), votes)

#=--------------------------------------------------------------------------------
Actions type
--------------------------------------------------------------------------------=#
"""
`Actions`

A collection of available actions, including the poll it's associated with.
"""
mutable struct Actions <: AbstractVector{AbstractAction}
    actions::Vector{AbstractAction}
    # DateTime doesn't support a time zone but Mastodon is zoned to UTC. Easier just
    # to use ZonedDateTime instead of DateTime
    expiry::ZonedDateTime
    poll_id::String
    voted::Bool
end
# AbstractVector interface
Base.size(a::Actions) = size(a.actions)
Base.getindex(a::Actions, i) = a.actions[i]

actions(a::Actions) = action.(a.actions)
totalvotes(a::Actions) = sum(votes, a.actions)
function percentages(a::Actions)
    totalvotes(a) == 0 && return fill(0.0, length(a))
    return votes.(a.actions) ./ totalvotes(a)
end
expiry(a::Actions) = a.expiry
expired(a::Actions) = a.expiry < now(localzone()) # need localzone because expiry is zoned
isvoted(a::Actions) = a.voted
