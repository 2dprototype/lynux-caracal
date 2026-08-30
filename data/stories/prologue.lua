-- data/stories/prologue.lua
local TaskConditions = require("src.tasks.task_conditions")
local EventBus = require("src.core.event_bus")

return {
    -- 1. Setting the Scene
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "02:43 AM. Another sleepless night in the cold, flickering glow of the monitor." },
    { type = "monologue", text = "The quiet hum of the CPU fan is the only sound cutting through the stillness of my room." },
    { type = "monologue", text = "About twenty minutes ago, an anomalous packet slipped past my local firewall on port 8080." },
    { type = "monologue", text = "It took me three grueling hours of XOR decompilation to extract the payload. The decrypted key was... 'DELTA-99'." },
    { type = "monologue", text = "If I lose this access key, weeks of research are gone. I need to log into my PC and secure it in a text file right now." },

    -- 2. Issue the Task
    {
        type = "task",
        task = {
            id = "create_cipher_file",
            title = "Secure the Cipher Key",
            desc = "Create a file named 'cipher.txt' in your home folder containing 'DELTA-99'.",
            hint = "Launch the TextEditor from the bottom dock. Type 'DELTA-99', click the header or save icon to save as 'cipher.txt'.",
            xp = 100,
            condition = TaskConditions.fileContentContains("home/cipher.txt", "DELTA-99"),
            onComplete = function(task)
                -- Send an incoming chat notification from Ghost
                local Notifications = require("src.desktop.notifications")
                Notifications.add("Ghost (Encrypted)", "I see you secured the cipher. Not bad, kid.", nil, 6.0)
            end
        }
    },

    -- 3. Switch to Desktop Mode
    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- 4. Narrative Continuation when player returns to Story mode or finishes task
    { type = "label", name = "post_task" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "Done. 'cipher.txt' is written and indexed into the local storage." },
    { type = "sfx", name = "notification" },
    { type = "say", speaker = "Ghost", text = "I saw you write that key into your local directory. Quick hands... but keeping plaintext secrets is rookie behavior." },
    { type = "say", speaker = "Protagonist", text = "Wait—who are you? How did you penetrate my network sandbox?" },
    
    -- 5. Branching Choice
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
    { type = "say", speaker = "Ghost", text = "I don't have a master, and neither should you if you value your freedom in this city." },
    { type = "jump", target = "conclusion" },

    -- Branch 2
    { type = "label", name = "branch_ask_key" },
    { type = "say", speaker = "Ghost", text = "DELTA-99 isn't just a key. It's the master override to Caracal Corporation's private database." },
    { type = "jump", target = "conclusion" },

    -- Branch 3
    { type = "label", name = "branch_threaten" },
    { type = "say", speaker = "Ghost", text = "Heh. You're welcome to run 'traceroute' in your Terminal. You'll find my proxies bounce through seven continents." },
    { type = "jump", target = "conclusion" },

    -- Conclusion
    { type = "label", name = "conclusion" },
    { type = "say", speaker = "Ghost", text = "Check your email in the morning. If you're ready for the real work, I'll send the coordinates." },
    { type = "monologue", text = "The connection abruptly severed. The screen returned to a blinking cursor." },
    { type = "monologue", text = "Whatever just began... there's no turning back now." }
}
