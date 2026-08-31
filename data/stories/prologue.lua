-- data/stories/prologue.lua
-- Extended Prologue Narrative Script with Sister's Email, Girlfriend Chat, and Hacker Intrusion

local TaskConditions = require("src.tasks.task_conditions")
local EventBus = require("src.core.event_bus")

return {
    -- 1. Setting the Scene: Bedroom at 2:00 AM
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "02:00 AM. Another quiet night in my apartment, lit only by the soft glow of my computer monitor." },
    { type = "monologue", text = "The hum of the fan and the faint click of my mechanical keyboard are the only sounds breaking the silence." },
    { type = "monologue", text = "Before I dive back into my code, I remember Maya sent an email earlier about Mom's 50th birthday. I should probably check it before she texts me tomorrow." },

    -- 2. Task 1: Check Sister's Email
    {
        type = "task",
        task = {
            id = "check_sister_email",
            title = "Check Maya's Email",
            desc = "Open the Email application on your desktop and read the new message from your sister Maya.",
            hint = "Launch Email from the bottom taskbar or start menu, then click on Maya's unread email.",
            xp = 50,
            condition = TaskConditions.emailRead("Maya"),
            onComplete = function(task)
                local Notifications = require("src.desktop.notifications")
                Notifications.add("Chat", "New message from Chloe (Girlfriend)", nil, 5.0)
            end
        }
    },

    -- 3. Switch to Desktop Mode for Task 1
    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- 4. Story continues after reading sister's email
    { type = "label", name = "after_email" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "Right... Mom's birthday is this Sunday. I'll need to transfer my share of the gift money in the morning." },
    { type = "sfx", name = "notification" },
    { type = "monologue", text = "A chat ping just popped up on my taskbar. It's Chloe... she's still awake too." },

    -- 5. Task 2: Flirt / Chat with Girlfriend
    {
        type = "task",
        task = {
            id = "chat_with_chloe",
            title = "Message Chloe",
            desc = "Open the Chat app, select Chloe's conversation, and send her a reply.",
            hint = "Launch Chat from the taskbar, click on 'Chloe (Girlfriend)', type a sweet message, and press Enter to send.",
            xp = 75,
            condition = TaskConditions.chatSentTo("Chloe"),
            onComplete = function(task)
                local Notifications = require("src.desktop.notifications")
                Notifications.add("Security Alert", "Port scan detected on 8080. Encrypted payload received.", nil, 6.0)
            end
        }
    },

    -- 6. Switch to Desktop Mode for Task 2
    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- 7. Narrative continues: Sudden Network Intrusion
    { type = "label", name = "after_chat" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "She's sweet... always worrying about my sleep schedule." },
    { type = "sfx", name = "notification" },
    { type = "monologue", text = "Wait. What was that? My network firewall just threw a high-priority alert on port 8080." },
    { type = "monologue", text = "Someone just dumped a raw encrypted packet directly into my sandbox buffer." },
    { type = "monologue", text = "I ran a quick XOR decompilation script in the background... the extracted secret key is 'DELTA-99'." },
    { type = "monologue", text = "I need to open TextEditor immediately and save this cipher key before my memory buffer flushes." },

    -- 8. Task 3: Secure the Cipher Key in TextEditor
    {
        type = "task",
        task = {
            id = "create_cipher_file",
            title = "Secure the Cipher Key",
            desc = "Create a file named 'cipher.txt' in your home folder containing 'DELTA-99'.",
            hint = "Launch TextEditor from the taskbar. Type 'DELTA-99' and save the file as 'cipher.txt'.",
            xp = 100,
            condition = TaskConditions.fileContentContains("home/cipher.txt", "DELTA-99"),
            onComplete = function(task)
                local Notifications = require("src.desktop.notifications")
                Notifications.add("Ghost (Unknown)", "I see you secured the cipher. Quick hands.", nil, 6.0)
            end
        }
    },

    -- 9. Switch to Desktop Mode for Task 3
    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- 10. Narrative Climax: Confrontation with Ghost
    { type = "label", name = "post_task" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "Done. 'cipher.txt' is written and indexed into the local storage." },
    { type = "sfx", name = "notification" },
    { type = "say", speaker = "Ghost", text = "I saw you write that key into your local directory. Quick hands... but keeping plaintext secrets on a home desktop is risky." },
    { type = "say", speaker = "Protagonist", text = "Wait—who are you? How did you penetrate my local subnet?" },
    
    -- 11. Branching Choice
    {
        type = "choice",
        prompt = "How do you respond to Ghost?",
        options = {
            {
                text = "Demand to know who they work for",
                target = "branch_demand"
            },
            {
                text = "Ask what they want with the DELTA-99 key",
                target = "branch_ask_key"
            },
            {
                text = "Threaten to trace and counter-hack their IP",
                target = "branch_threaten"
            }
        }
    },

    -- Branch 1
    { type = "label", name = "branch_demand" },
    { type = "say", speaker = "Ghost", text = "I don't have a master, and neither should you if you value your privacy in this city." },
    { type = "jump", target = "conclusion" },

    -- Branch 2
    { type = "label", name = "branch_ask_key" },
    { type = "say", speaker = "Ghost", text = "DELTA-99 isn't just a key. It's the master override to Caracal Corporation's private database." },
    { type = "jump", target = "conclusion" },

    -- Branch 3
    { type = "label", name = "branch_threaten" },
    { type = "say", speaker = "Ghost", text = "Heh. You're welcome to run 'traceroute' in your Terminal. You'll find my proxies bounce through seven countries." },
    { type = "jump", target = "conclusion" },

    -- Conclusion
    { type = "label", name = "conclusion" },
    { type = "say", speaker = "Ghost", text = "Check your inbox tomorrow morning. If you're ready for the real work, I'll send the coordinates." },
    { type = "monologue", text = "The connection abruptly severed. The screen returned to a quiet blinking cursor." },
    { type = "monologue", text = "Whatever just began... there's no turning back now." }
}
