#=--------------------------------------------------------------------------------
Parse HTML into useful datatypes
--------------------------------------------------------------------------------=#
# This is all unavoidably tightly tied to the way that @dungeons currently presents
# data. Mostly uses regular expressions and while it should cope with things being
# rearranged, any changes beyond that will likely break this although hopefully will
# be easily fixed.

# just strip out any higher code characters and simple HTML conversion
function plaintext(str)
    text = replace(str, "<p>" => "", "</p>" => "\n\n", "<br>" => "\n")
    return filter(c -> Char(256) - c > 0, text) |> strip
end

# ignore if not matched and return default
capture(m) = something(m, ["0"]) |> only
parseint(m) = m |> capture |> n -> parse(Int, n)

#=--------------------------------------------------------------------------------
Character sheet parsing
--------------------------------------------------------------------------------=#
const CLASS_SYMBOLS = "[⚒️📯☀️🌿⚔️☯🛡️🏹🗡️💫🧿🔮]"
const DESC_REGEX = Regex("<p>" * CLASS_SYMBOLS * raw".*?(\w+,(?:\w|\s|-)*)<")

parsedesc(body) = match(DESC_REGEX, body) |> capture
function parsehp(body)
    m = match(r"(?:❤️|🖤){10} (-?\d+)/(\d+)", body)
    m === nothing && return (0,0)
    return Tuple(parse.(Int, m))
end
function parselevel(body)
    m = match(r"⭐ (\d+) \((\d+)\)", body)
    m === nothing && return 0
    return Tuple(parse.(Int, m))
end
function parsehitdice(body)
    m = match(r"🎲 (\d+)/(\d+)", body)
    m === nothing && return (0,0)
    return Tuple(parse.(Int, m))
end
function parseweapon(body)
    m = match(
            r">.+? ((?:\w|\s|,)+?\[.+?\]) " *       # first weapon
            r"(?:.+? ((?:\w|\s|,)+?\[.+?\]) )?",   # optional 2nd weapon
        body)
    m === nothing && return "No weapon"
    return join(filter(!isnothing, collect(m)), "\n")
end
parseshield(body) = match(r"Shield", body) |> !isnothing
parsearmour(body) = match(r"<br>🛡️\s*((?:\w|\s|-)*\[\d+\])\s*<", body) |> capture

const SPELL_REGEX = r">(?:(\d)..(\d+)\/(\d+))+\s*?<"

function parsespells(body)
    m = match(SPELL_REGEX, body)
    m === nothing && return Spells()
    spells = Vector{Tuple{Int, Int}}()
    for i ∈ 2:3:length(m)
        push!(spells, parse.(Int, (m[i], m[i+1])))
    end
    return Spells(m[1] == "0", spells)
end

parsegold(body) = match(r"🪙 (\d+)<", body) |> parseint
parseattributes(body) = eachmatch(r"\w{3} (\d+)", body) |> collect .|> parseint
parsecampaign(body) = match(r"🗺. (\d+)", body) |> parseint

const CLOCK_SYMBOLS = '[' * join('🕐':'🕧') * ']'
const CLOCK_REGEX = Regex("$CLOCK_SYMBOLS" * raw" (?:(\d+) days?, )?(\d+):(\d+)<")

function parsebirth(body)
    m = match(CLOCK_REGEX, body)
    m === nothing && return now(localzone())
    times = parse.(Int, something.(m, "0")) .|> (Day, Hour, Minute)
    timeago = mapreduce(Minute, +, times)
    return round(now(localzone()) - timeago, Minute)
end

#=--------------------------------------------------------------------------------
Activities parsing
--------------------------------------------------------------------------------=#
# Since emojis are sometimes multiple characters, some of which are invisible, and
# look vastly different in browser/code/console, often use (.+?) to capture them.
# Single character emoji are represented as literals.

# Optional elements are simply passed to the constructor who will provide defaults.

# fighting activity, extract: type, name, hpcur, hpmax, ac, defence, cr, xp
const fighting = r"---<br>" *               # after divider
    r"(.+?) ((?:\w|\s|,|\(|\))+)<br>" *     # emoji for type, then creature name
    r"(?:❤️|🖤){1,10} (\d+)\/(\d+)<br>" *  # current hp / max hp
    r".+?(\d+) (.+?)?<br>" *                # ac, optional defence style
    r"❕(\d+(?:\/\d+)?)<br>" *               # cr (possible fraction)
    r"✨ (\d+)<" =>                         # xp
    Fighting

# adventuring activity, extract: type, name, hpmin, hpmax, defence, cr, xp
const adventuring = 
    r"---<br>(?:\w|\s|,)+" *    # ignore preamble
    r"(.+?) ((?:\w|\s|\(|\))+)<br>" * # emoji for type, then creature name
    r"❤️ (\d+)-(\d+)" *         # min - max hp
    r" (.+?)?" *                # optional defence style
    r" ❕(\d+(?:\/\d+)?)" *      # cr (possible fraction)
    r" ✨ (\d+)<" =>            # xp
    Adventuring

const shopping = r"<br>🎒<br>" => Shopping
# this is hard to detect. Hopefully this is sufficient.
const intown = r"---<br>.+?(?:town|village).*?," *
    r" what would you like to do\?<\/p>" => InTown
const newchar = r"🗺️ Campaign (\d+) <a .+?>#<span>dnd<\/span>" => NewChar

# Base.parse(::Rational{Int}, str) isn't available yet, do basic conversion here.
# (see https://github.com/JuliaLang/julia/issues/18328)
function parserat(str)
    nums = parse.(Int, split(str, "/"))
    return Rational(nums...)
end

# add new activities here
const ACTIVITIES = Dict(
    fighting,
    adventuring,
    shopping,
    intown,
    newchar
)

# return first matched activity, or fallback to SimpleActivity
function parseactivity(status)
    for (regex, type) ∈ ACTIVITIES
        m = match(regex, status)
        isnothing(m) && continue
        matchedtext = filter(!isnothing, collect(m))
        return type(matchedtext...)
    end
    return SimpleActivity(status)
end

#=--------------------------------------------------------------------------------
Actions parsing
--------------------------------------------------------------------------------=#
# those actions that simply need the initial emoji removed
const basicaction = r"^.+? (.*?[a-zA-Z-, ]+!?)$" => BasicAction

# either kind of rest, stripped of emojis
const restaction = r"^.+? ((?:Short|Long) Rest) \(\+❤️ (?:\+|-)🎲\)$" => RestAction

# spell attack: capture spell level, name, damage, and optionally ⬆/⬇ for (dis)advantage
const spellattack = r"^(\d).+? (.+?) \[(.+)\](?: (⬆|⬇).+?)?$" => SpellAction

# weapon attack: capture attack name, damage, and optionally ⬆/⬇ to indicate (dis)advantage
const weaponattack = r"^.+? (Melee|Ranged).+ (\[.+\])\s*(?:(⬆|⬇).+?)?$" => AttackAction

# items for sale: capture name, combat value and cost
const itemforsale = r"^.+? (.+) (\[.+\])(?: ~ .+)? \(((?:\+|-)\d+).+?\)$" => PurchaseAction

# add new actions here
const ACTIONS = Dict(
    basicaction,
    restaction,
    spellattack,
    weaponattack,
    itemforsale
)

# return first matched type or fallback to SimpleAction
function parseaction(text, votes)
    for (regex, type) ∈ ACTIONS
        m = match(regex, text)
        isnothing(m) && continue
        matchedtext = filter(!isnothing, collect(m))
        return type(matchedtext..., votes)
    end
    return SimpleAction(text, votes)
end
parseaction(d::Dict) = parseaction(d["title"], d["votes_count"])
