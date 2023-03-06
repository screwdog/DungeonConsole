module DungeonConsole
using Colors
using Dates
using HTTP
using JSON
using Term
using TimeZones
using TOML

# D&D combat and enemy mechanics
include("dnd.jl")

# game state data types
include("data.jl")

# convert received html into a more usable form
include("parsing.jl")

# basic Mastodon interaction
include("toot.jl")

# @Dungeons bot specific functionality
include("dungeons.jl")

# output routines
include("display.jl")

function run()
    # begin by getting the current status
    input = "all"
    local character, activity, actions
    while input ∉ ["q", "quit", "exit"]
        if input ∈ ["a", "all"]
            character, activity, actions = current()
        end
        if input ∈ ["1", "2", "3", "4"]
            votenum = parse(Int, input)
            votenum ≤ length(actions) && vote(actions, votenum)
            # after voting, update the poll status
            input = "p"
        end
        if input ∈ ["p", "poll"]
            update!(actions)
        end
        simplelayout(character, activity, actions) |> print
        default = "1"
        input = prompt(actions, default)
    end
end
end; # module DungeonConsole
