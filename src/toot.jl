#=--------------------------------------------------------------------------------
Basic Mastodon interactions
--------------------------------------------------------------------------------=#
# hard-coded as I'm unlikely to need to change these any time soon.
const SERVER = "aus.social"
const BOT_NAME = "dungeons@mastodon.social"
const BOT_ID = "109357144624209438"
const CONFIG_FILE = "../dungeons_config.toml"

# client details stored externally so they aren't included in the repo. These values come
# from registering the app in my personal profile on the Mastodon server.
const CONFIG = TOML.parsefile(CONFIG_FILE)

const CLIENT_ID = CONFIG["client_id"]
const CLIENT_SECRET = CONFIG["client_secret"]
const TOKEN = CONFIG["token"]

const REDIRECT = "urn:ietf:wg:oauth:2.0:oob"

# configuration details
mutable struct NetData
    server::String
    botname::String
    botid::String
    clientid::String
    clientsecret::String
    token::String
end
NetData() = NetData(SERVER, BOT_NAME, BOT_ID, CLIENT_ID, CLIENT_SECRET, TOKEN)

# global configuration, used throughout as a default.
const STATUS = NetData()

server(n::NetData) = n.server
server() = server(STATUS)

botid(n::NetData) = n.botid
botid() = botid(STATUS)

clientid(n::NetData) = n.clientid
clientid() = clientid(STATUS)

clientsecret(n::NetData) = n.clientsecret
clientsecret() = clientsecret(STATUS)

token(n::NetData) = "Bearer " * n.token
token() = token(STATUS)

# specialised get/post methods for interacting with the Mastodon api
function get(server, path, query)
    response = HTTP.get(
        "https://$server/api/v1/$path";
        headers=["Authorization" => token()],
        query=query,
        status_exception=false
    )
    # TODO improved error handling?
    HTTP.iserror(response) && @warn response
    return response.body |> String |> JSON.parse
end
get(path, query=Dict()) = get(server(), path, query)

function post(server, path, body)
    response = HTTP.post(
        "https://$server/api/v1/$path";
        headers=["Authorization" => token()],
        body=body,
        status_exception=false
    )
    # TODO improved error handling?
    HTTP.iserror(response) && @warn response
    return response.body |> String |> JSON.parse
end
post(path, body) = post(server(), path, body)

# key Mastodon api methods
lookup(accountname) = get("accounts/lookup", Dict("acct" => accountname))
statuses(accountid) = get("accounts/$accountid/statuses")
account(accountid) = get("accounts/$accountid")
pollbyid(pollid::String) = get("polls/$pollid")
vote(pollid, num) = post("polls/$pollid/votes", Dict("choices[]" => [num-1]))

verifyapp() = get("apps/verify_credentials") # doesn't work ??
verifyaccount() = get("accounts/verify_credentials")
