Project TODO List
=================

1. get data from server
    ✓ return in custom types
    ✓ profile data
    ✓ posts
    ✓ polls
    ✓ filter irrelevant posts
    - regular update to poll results?
    - clear notifications for closed polls
2. show post
    ✓ reformat for console
    ✓ extract profile data for current status
    ✓ present poll options
3. display information as dashboard
    ✓ rather than by post
    ✓ determine current state - fighting, in town, etc - and present accordingly
    - non-scrolling
    - help displays explanation of symbols
3. allow poll responses
    ✓ read input from user
    ✓ implement authentication
    ✓ POST response to server
4. auto poll responses
    - implement 5e rules to infer attack bonuses, etc
    - optimal attacks (melee vs ranged vs spell, etc)
    - optimal strategy (attack, run, etc based on win chance, death chance, etc)
    - optimal strategy out of combat (engage, sneak, rest, go to town)
    - town actions (rest, shop, adventure)
5. options
    - change options in interface rather than config file


Mock up interface
=================

#DungeonConsole# (v0.1) <-- nice font/colour

🛡️ Andrew, the Tiefling Paladin   |    You are currently *fighting* a  <-- or *adventuring*, *in town*, etc
❤️❤️❤️❤️❤️❤️❤️🖤🖤🖤 16/25   |       🧟 Mimic
⭐ 3 (2400) 🎲 2/3               |       ❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️ 66/66
⚔️ Maul [2d6+4, +6]              |       🛡️ 12     ❕2    ✨ 450
🛡️ Chain Mail [16]               |--------------------------------------------
1️⃣3/3                            |     What should we do?
🥇 103                           |     1.  ⚔️ Melee, two-handed     [11, 75%] <-- bold and ✓ when selected
Str 18 (+4)                      |       (28%) [========                     ] <-- different colour
Dex 12 (+1)                      |     2.  🏹 Ranged, improvised    [3.5, 25%]
Con 12 (+1)                      |       (0%)  [                             ]
Int 16 (+3)                      |     3.  👊 Melee, unarmed          [5, 75%]
Wis 16 (+3)                      |       (0%)  [                             ]
Cha 10 (+0)                      |     4.  🏃 Run!                       [75%]
🗺️ 38 🕥 4 days, 10:52          |       (72%) [====================         ]

*Manual*/*Auto* *mode* 11 minutes left
(1, 2, 3, [4], (R)efresh, (H)elp, (O)ptions, (Q)uit):       <-- numbers only if not voted

Eventually: refresh votes (and campaign length?) every minute, update when poll closes/new post.

(0) Chill Touch [1d8] (⬇) 

Activities: fighting a ..., adventuring, in town, shopping, building a new character