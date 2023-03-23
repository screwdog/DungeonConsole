#=--------------------------------------------------------------------------------
Methods for reading @dungeons data
--------------------------------------------------------------------------------=#
# these are built directly on the Mastodon api methods in "toot.jl".

profile(n::NetData) = account(botid(n))["note"]

# find the most recent status post with a poll
function currentstatus(n::NetData)
    sts = statuses(botid(n))
    last_poll = findfirst(ispoll, sts)
    return sts[last_poll]
end

status_text(st) = st["content"]
currentpoll(st) = st["poll"]

ispoll(st) = currentpoll(st) ≠ nothing

options(p) = p["options"]
expiry(p) = astimezone(ZonedDateTime(p["expires_at"]), localzone())
poll_id(p) = p["id"]
voted(p) = p["voted"]

# get the current state of the campaign: character status, location and actions available
function current(n::NetData)
    status = currentstatus(n)
    poll = currentpoll(status)
    return (
        # refactor so 1st/3rd matches 2nd (preferred) or vice-versa.
        BasicCharacter(profile(n)),
        parseactivity(status_text(status)),
        Actions(parseaction.(options(poll)), expiry(poll), poll_id(poll), voted(poll))
    )
end
current() = current(STATUS)

# update the poll status, getting the current vote numbers
function update!(a::Actions)
    poll = pollbyid(a.poll_id)
    empty!(a.actions)
    append!(a.actions, parseaction.(options(poll)))
    a.voted = voted(poll)
end

# place our vote
vote(a::Actions, num) = vote(a.poll_id, num)
