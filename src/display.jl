#=--------------------------------------------------------------------------------
Display methods
--------------------------------------------------------------------------------=#

# create the title panel
titlepanel() = Panel(
    "{bold red}DungeonConsole{/bold red} {bright red}(v0.1){/bright red}";
    justify=:center,
    box=:HEAVY,
    style="bright red on_black",
    width=71
)

#=--------------------------------------------------------------------------------
Character sheet methods
--------------------------------------------------------------------------------=#
charactersheet(s::SimpleCharacter) = TextBox(
    s.text;
    title="Character Sheet",
    title_style="bold yellow",
    title_justify=:center,
    width=35,
    height=23
)

# variety of methods to create the various parts of a more complex character sheet
function healthtext(currhp, maxhp)
    currhp ≤ 0 && return "{bold #454545}$currhp{/bold #454545}/{green}$maxhp{/green}"
    gradient = range(HSL(colorant"red"), stop=HSL(colorant"green"), length=maxhp)
    hpcolor = hex(gradient[currhp])
    return "{#$hpcolor}$currhp{/#$hpcolor}/{green}$maxhp{/green}"
end
healthtext(itr) = healthtext(itr...)

function spell_list(s::Spells)
    list = String[]
    for i ∈ range(start=1 - s.cantrips, length=length(s.spells))
        push!(list, "{purple}$i{/purple} {#44b9eb}$(s.spells[i][1]){/#44b9eb}/{bold #44b9eb}$(s.spells[i][2]){/bold #44b9eb}")
    end
    return join(list, " ")
end

function modstr(i)
    m = modifier(i)
    return (m ≥ 0 ? "+" : "") * string(m)
end
attribute(i) = "$(lpad(i, 2)) ({#ab5454}$(modstr(i)){/#ab5454})"

campaignstart(date) = Dates.format(date, "d u Y")

# detailed character sheet
charactersheet(b::BasicCharacter) = TextBox(
    """
    $(b.description)

    Level {gold1}$(b.level[1]){/gold1} ($(b.level[2]) experience)
    $(healthtext(b.hp)) hit points, $(b.hitdice[1])/$(b.hitdice[2]) hit dice

    $(b.weapon)
    $(b.armour)
    $(ismagic(b) ? "Spells:" : "") $(ismagic(b) ? spell_list(b.spells) : "")
    {gold1}$(b.gold){/gold1} gold

    Strength:     $(attribute(b.attributes[1]))
    Dexterity:    $(attribute(b.attributes[2]))
    Constitution: $(attribute(b.attributes[3]))
    Intelligence: $(attribute(b.attributes[4]))
    Wisdom:       $(attribute(b.attributes[5]))
    Charisma:     $(attribute(b.attributes[6]))

    {underline}Campaign $(b.campaign){/underline}
    Started $(campaignstart(b.birthdate))
    """;
    title="Character Sheet",
    title_style="bold yellow",
    title_justify=:center,
    width=35,
    height=23
)

#=--------------------------------------------------------------------------------
Activity box methods
--------------------------------------------------------------------------------=#
function defencetext(d::Defence)
    d.flyorswim === nothing && return ""
    return "(" * (d.flyorswim ? "flying" : "swimming") * ")"
end

function rattext(r::Rational)
    denominator(r) == 1 && return string(numerator(r))
    return string(numerator(r), "/", denominator(r))
end

# specialised methods for the text of each activity type. Heavily marked up as per
# Term.jl so somewhat hard to read.
activitytext(s::SimpleActivity) = s.text
activitytext(f::Fighting) = "You are fighting a...\n\n" *
    "$(f.name) [{blue}$(f.type){/blue}]\n" *
    "$(healthtext(f.hp)) HP, AC$(f.ac) $(defencetext(f.defence))\n" *
    "CR {#FFFFFF}$(rattext(f.cr)){/#FFFFFF}, XP {gold1}$(f.xp){/gold1}"
activitytext(a::Adventuring) = "You encounter a...\n\n" *
    "$(a.name) [{blue}$(a.type){/blue}]\n" *
    "{red}$(a.hp[1]){/red}-{green}$(a.hp[2]){/green} HP $(defencetext(a.defence))\n" *
    "CR {#FFFFFF}$(rattext(a.cr)){/#FFFFFF}, XP {gold1}$(a.xp){/gold1}"
activitytext(s::Shopping) = "You are in a shop. What would you like to buy?"
activitytext(i::InTown) = "You are safe in a town. What would you like to do?"
activitytext(n::NewChar) = "Campaign $(n.campaign).\n\nWhose story should this be?"

# construct the activity panel
activitypanel(a::AbstractActivity) = TextBox(
    activitytext(a);
    title="Current Activity",
    title_style="bold yellow",
    title_justify=:center,
    width=35,
    height=12
)

#=--------------------------------------------------------------------------------
Actions box methods
--------------------------------------------------------------------------------=#

# methods to markup attack descriptions
function bonustext(n::Int)
    n == 0 && return ""
    return string(n < 0 ? "-" : "+", abs(n))
end
function dicetext(d::Dice)
    d.numdice == 0 && return string(d.bonus)
    return "$(d.numdice){#808080}d{/#808080}$(d.sides)$(bonustext(d.bonus))"
end
function advtext(rt::RollType)
    rt.adv === nothing && return ""
    return "(" * (rt.adv ? "{green}⬆{/green}" : "{red}⬇{/red}") * ")"
end

# TODO implement this but since text is marked up it is difficult to calcuate it's actual
# width. Also, can't just truncate string as tags need to be balanced. Ideally, would like
# to modify SpellAction/AttackAction to truncate to "Melee, ⋯ [1d8+2]" or similar.
function fitwidth(str, width)
    length(str) ≤ width && return str
    return first(str, fld(width - 3, 2)) * " … " * last(str, cld(width - 3, 2))
end
fitwidth(width) = str -> fitwidth(str, width)

# markup the text for each action
actiontext(a::AbstractAction) = action(a)
actiontext(s::SpellAction) = 
    "{purple}($(s.level)){/purple} $(s.name) [$(dicetext(s.damage))] $(advtext(s.advantage))"
actiontext(a::AttackAction) =
    "$(a.name) [$(dicetext(a.damage))] $(advtext(a.advantage))"
actiontext(i::PurchaseAction) = "$(i.name) ({gold1}$(i.cost){/gold1} gp)"

votestr(vote, width) = lpad("($vote)", width)

# create the action lines and the lines showing voting percentages/numbers
actionline(i, a::AbstractAction) = "{#44b9eb bold}$i{/#44b9eb bold} $(actiontext(a))"
function percentline(votes, percent)
    barwidth = 27 - length(votes)
    on = round(Int, barwidth*percent/100)
    off = barwidth - on
    return "{dim #FF8C00}" * "▬"^on * " "^off * "{/dim #FF8C00} " * votes
end

# Create the "Actions Available" box
function actionlist(a::Actions)
    width = maximum(length ∘ string, votes.(a))
    votestrs = votestr.(votes.(a), width)
    lines = actionline.(axes(a, 1), a)
    percents = round.(Int, percentages(a) * 100)
    for (i, percent) ∈ enumerate(percents)
        insert!(lines, 2i, percentline(votestrs[i], percent))
    end
    return TextBox(
        join(lines, "\n");
        title="Actions Available",
        title_style="bold yellow",
        title_justify=:center,
        width=35,
        height=10
    )
end

#=--------------------------------------------------------------------------------
Layout and prompt
--------------------------------------------------------------------------------=#
# use Term.jl layout and Compositor to display everything
function simplelayout(character, activity, actions)
    layout = :( T(3, 71) /
        (C(23, 35) * V(23, 1) * (A(12, 35) / H(1, 35) / O(10, 35)))
    )
    return Compositor(
        layout;
        T=titlepanel(),
        C=charactersheet(character),
        V=vLine(23; style="dim white"),
        A=activitypanel(activity),
        H=hLine(35; style="dim white"),
        O=actionlist(actions)
    )
end

# display the prompt and read response
finishtime(time) = Dates.format(time, "I:MM p")
function prompt(actions, default)
    promptline = ">>> Poll close$(expired(actions) ? "d" : "s") at " *
        finishtime(actions.expiry)
    opts = [
        "efresh {#44b9eb}a{/#44b9eb}ll",    # efresh all
        "{#44b9eb}p{/#44b9eb}oll",          # poll
        "or {#44b9eb}q{/#44b9eb}uit: "      # or quit
    ]
    if !isvoted(actions)
        opts[1] = "or r" * opts[1]
        prepend!(opts, [
            "Vote {underline}1{/underline}", # <--- TODO underline the actual default
            string.(2:length(actions))...
        ])
    else
        opts[1] = "R" * opts[1]
    end
    options = join(opts, ", ")
    # tprint/ln instead of print/ln to use Term.jl formatting power
    tprintln(promptline)
    tprint(options)
    input = readline()
    println()
    return input ≠ "" ? input : default
end
