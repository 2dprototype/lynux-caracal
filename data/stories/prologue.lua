-- data/stories/prologue.lua
-- Lynux Caracal: Chapter 1 - "Ink, Whiskers & The Midnight Repeater"
-- Locked to Aki's POV (Newspaper Club Reporter)

local TaskConditions = require("src.tasks.task_conditions")
local EventBus = require("src.core.event_bus")

return {
    -- =========================================================================
    -- ACT I: GOLDEN HOUR IN CLUBROOM 204
    -- =========================================================================
    { type = "bg", name = "clubroom_sunset" },
    { type = "music", track = "main_theme", loop = true },

    { type = "monologue", text = "04:45 PM. October sunlight cuts across the wooden floorboards of Clubroom 204." },
    { type = "monologue", text = "The room always smells faintly of hot mimeograph toner, aged paper, and the sweet roasted barley tea Suzumia brews before each editorial meeting." },
    { type = "monologue", text = "I lean back in my chair, listening to the rhythmic clack of typewriter keys and the low hum of Hoshida's laptop in the corner." },
    { type = "monologue", text = "To most students at Kamiyama High, our Newspaper Club is just a quiet corner on the second floor. But today, the atmosphere is unusually tense." },

    { type = "char_show", char = "Nagahashi", pos = "center" },
    { type = "sfx", name = "click" },
    { type = "say", speaker = "Nagahashi", text = "Gentlemen... and Vice President Suzumia. We are standing upon the precipice of ruin!" },

    { type = "monologue", text = "President Nagahashi slams a crisp white envelope with the official Student Council seal onto the conference table." },

    { type = "say", speaker = "Aki", text = "Is that... the budget audit notice already?" },

    { type = "say", speaker = "Nagahashi", text = "Indeed! The Student Council has issued an ultimatum: if our upcoming Autumn Special Edition does not double circulation, our printing quota will be slashed by forty percent!" },
    { type = "say", speaker = "Nagahashi", text = "Do you know what that means?! It means we'll be reduced to handing out single-sheet black-and-white flyers like common amateurs!" },

    { type = "char_show", char = "Suzumia", pos = "left" },
    { type = "say", speaker = "Suzumia", text = "President, panicking won't fix our readership numbers. Our last issue dipped because we covered the calligraphy exhibition for three pages in a row." },

    { type = "say", speaker = "Nagahashi", text = "Which is precisely why we must pivot to investigative sensationalism! Behold: Operation Ghost Scoop!" },

    { type = "monologue", text = "Nagahashi uncaps a red whiteboard marker with theatrical flair and writes on the chalkboard in jagged capital letters: 'THE PHANTOM OF THE 3RD FLOOR SERVER ROOM'." },

    { type = "say", speaker = "Nagahashi", text = "Every night after 6 PM, weird rhythmic modem beeps and blinking crimson LEDs emanate from behind the locked fire-door on the third floor. Students are terrified! It's the ultimate urban legend scoop!" },

    { type = "say", speaker = "Suzumia", text = "Nagahashi-senpai, that's completely irresponsible! School journalism should be about genuine, uplifting campus life, not inventing spooky rumors that get students disciplined!" },

    { type = "monologue", text = "Suzumia pulls a bright pink, pastel-trimmed flyer from her leather notebook. A faint blush tints her cheeks, though she tries to keep her expression perfectly professional." },

    { type = "say", speaker = "Suzumia", text = "Look at this instead. The newly opened 'Meow Latte' Cat Cafe right near Kamiyama Station! It's run by a rescue animal charity. They have eight adorable cats, strawberry souffle pancakes, and they offered our students a 10% discount!" },
    { type = "say", speaker = "Suzumia", text = "If we feature a warm, heartwarming photo spread of the cats on the front page, every single class will read it!" },

    { type = "char_show", char = "Hoshida", pos = "right" },
    { type = "monologue", text = "From behind a fortress of empty potato chip bags and a glowing laptop covered in anime decals, Hoshida adjusts his thick glasses." },

    { type = "say", speaker = "Hoshida", text = "I must cast my vote with Vice President Suzumia. Fluffy feline companions and cute cafe parfaits are the absolute pinnacle of human spiritual culture." },
    { type = "say", speaker = "Hoshida", text = "Besides, 2D cat maids and 3D rescue kittens share an undeniable aesthetic resonance. It is scientifically proven to boost morale." },

    { type = "say", speaker = "Nagahashi", text = "Nonsense! Where is the grit?! Where is the adrenaline?! A cat cafe won't give readers the electric thrill of a midnight conspiracy!" },

    { type = "monologue", text = "Nagahashi and Suzumia lock eyes across the table, both refusing to yield. Nagahashi stands with arms crossed, while Suzumia clutches her cat cafe notes with determined tenacity." },
    { type = "monologue", text = "Whenever the club reaches a deadlock like this, their gazes inevitably turn toward me." },

    { type = "say", speaker = "Suzumia", text = "Aki-kun... you're our lead layout editor. What do you think our readers really need right now?" },

    { type = "say", speaker = "Aki", text = "Well... why do we have to choose only one?" },
    { type = "say", speaker = "Aki", text = "What if we produce a Dual-Cover Special Edition? The front cover gets Suzumia's 'Meow Latte' feature with full-color cat photos and student discounts, and the back cover gets Nagahashi's 'Kamiyama Mystery Files: Investigating the 3rd Floor Anomaly'." },

    { type = "monologue", text = "Silence hangs in the room for a moment. Then Nagahashi's eyes ignite with theatrical excitement." },

    { type = "say", speaker = "Nagahashi", text = "A two-faced publication! The light of wholesome youth on the outside, the shadowy intrigue of the unknown on the flip side! Aki, you are a visionary!" },

    { type = "say", speaker = "Suzumia", text = "That... actually sounds wonderful! It gives students both warmth and excitement without compromising our integrity." },

    { type = "monologue", text = "Suzumia turns to me and offers a gentle, genuine smile that makes my heart skip a quiet beat." },

    { type = "say", speaker = "Suzumia", text = "Thank you, Aki-kun. I'll email you my full interview notes and cat photos tonight. Let's make this our best issue yet!" },

    { type = "say", speaker = "Nagahashi", text = "Then it is settled! Aki, you are in charge of synthesizing both stories on your PC tonight. Kamiyama Press rides to victory!" },

    -- =========================================================================
    -- ACT II: NIGHT AT THE BEDROOM DESK
    -- =========================================================================
    { type = "char_hide" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "11:35 PM. Back home in my bedroom, surrounded by the quiet hum of the night." },
    { type = "monologue", text = "A cool breeze slips past the curtains, and the faint blue glow of my desktop monitor illuminates the desk." },
    { type = "monologue", text = "Down the hall, I heard my sister Hiko yelling earlier about leftover curry in the fridge before she went to her room." },
    { type = "monologue", text = "Before I begin assembling the dual-cover layout, I should check my email inbox. Hiko sent a message about chores, and Suzumia promised to send over her Meow Latte notes." },

    -- TASK 1: Check Sibling & Club Emails
    {
        type = "task",
        task = {
            id = "check_club_emails",
            title = "Check Inbox (Hiko & Suzumia)",
            desc = "Open the Email application on your desktop. Read the message from your sister Hiko, as well as Suzumia's draft notes.",
            hint = "Launch Email from the bottom taskbar or start menu. Click through Hiko's and Suzumia's unread emails.",
            xp = 50,
            condition = TaskConditions.emailRead("Suzumia"),
            onComplete = function(task)
                local Notifications = require("src.desktop.notifications")
                Notifications.add("Browser Alert", "New website shortcut added: Meow Latte Cat Cafe", nil, 5.0)
            end
        }
    },

    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- =========================================================================
    -- ACT III: RESEARCHING THE FELINE SANCTUARY & CHATTING WITH SUZUMIA
    -- =========================================================================
    { type = "label", name = "after_email" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "Suzumia was so thorough... she even cataloged each cat's personality and favorite sleeping spots." },
    { type = "monologue", text = "And Hiko's email mentioned that even the first-years in her class have been gossiping about the server room noises." },
    { type = "monologue", text = "To write a compelling review, I should browse the official 'Meow Latte' website in my browser to verify the dessert menu and cat names, then text Suzumia to confirm the headline." },

    -- TASK 2: Browse Cat Cafe Website
    {
        type = "task",
        task = {
            id = "browse_cat_cafe",
            title = "Browse Meow Latte Website",
            desc = "Launch the Browser app and visit 'http://meowlatte.com' to review the cat profiles and dessert specials.",
            hint = "Open Browser from the taskbar, click the 'Meow Latte' shortcut or type 'http://meowlatte.com'.",
            xp = 75,
            condition = TaskConditions.browserVisited("cat"),
            onComplete = function(task)
                local Notifications = require("src.desktop.notifications")
                Notifications.add("Chat", "Suzumia (Vice President) is active now", nil, 5.0)
            end
        }
    },

    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    { type = "label", name = "after_browser" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "Mochi the Scottish Fold and Chobi the calico... they really are adorable. Suzumia's enthusiasm makes complete sense now." },
    { type = "monologue", text = "I notice Suzumia's status indicator in the Chat app is active. I should send her a quick message to let her know the draft is looking great." },

    -- TASK 3: Message Suzumia on Chat
    {
        type = "task",
        task = {
            id = "chat_with_suzumia",
            title = "Message Suzumia on Chat",
            desc = "Open Chat, select 'Suzumia (Vice President)', and send her a reply about the cat cafe photos.",
            hint = "Open Chat from the taskbar, click on Suzumia, type a friendly message, and hit Enter.",
            xp = 75,
            condition = TaskConditions.chatSentTo("Suzumia"),
            onComplete = function(task)
                local Notifications = require("src.desktop.notifications")
                Notifications.add("Hoshida [Root]", "URGENT: Port 8080 anomaly detected on school subnet!", nil, 6.0)
            end
        }
    },

    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- =========================================================================
    -- ACT IV: THE MIDNIGHT ANOMALY & HOSHIDA'S REVELATION
    -- =========================================================================
    { type = "label", name = "after_chat" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "Talking to Suzumia late at night always puts my mind at ease. She really cares so much about our club." },
    { type = "sfx", name = "notification" },
    { type = "monologue", text = "Wait... a red notification badge just flashed in my system tray. It's from Hoshida." },
    { type = "monologue", text = "His usual goofy otaku tone is completely gone. In its place is a raw packet dump from port 8080." },
    { type = "monologue", text = "Hoshida ran a deep subnet scan against the school's old 3rd floor repeater rack. Someone dumped an encrypted XOR payload containing the key 'SHADOW-CAT-09'." },
    { type = "monologue", text = "The rumor Nagahashi thought he made up... someone is actually using the school's old server as an unauthorized proxy bridge!" },
    { type = "monologue", text = "I need to open TextEditor immediately and save the cipher key 'SHADOW-CAT-09' into 'cipher.txt' in my home folder so Hoshida's firewall script can quarantine the port." },

    -- TASK 4: Save Cipher Key in TextEditor
    {
        type = "task",
        task = {
            id = "secure_school_cipher",
            title = "Secure Cipher 'SHADOW-CAT-09'",
            desc = "Create a file named 'cipher.txt' in your home folder containing 'SHADOW-CAT-09' to trigger the quarantine script.",
            hint = "Launch TextEditor from the taskbar. Type 'SHADOW-CAT-09' and save the file as 'cipher.txt'.",
            xp = 100,
            condition = TaskConditions.fileContentContains("home/cipher.txt", "SHADOW-CAT-09"),
            onComplete = function(task)
                local Notifications = require("src.desktop.notifications")
                Notifications.add("System", "Port 8080 quarantined. Proxy severed.", nil, 6.0)
            end
        }
    },

    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- =========================================================================
    -- ACT V: MIDNIGHT RESOLUTION & BRANCHING CHOICES
    -- =========================================================================
    { type = "label", name = "post_task" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "Done. 'cipher.txt' is saved, and Hoshida's automated script successfully severed the intruder's tunnel." },
    { type = "sfx", name = "notification" },

    { type = "say", speaker = "Hoshida (Anon)", text = "Tunnel terminated. Clean work, Aki. The repeater switch on the 3rd floor is locked down." },
    { type = "say", speaker = "Aki", text = "Hoshida... who was tapping into the school network? Was it really someone trying to modify student grades?" },
    { type = "say", speaker = "Hoshida (Anon)", text = "Whoever it was, they were using our Newspaper Club's old web server as a relay bounce. If Nagahashi had published his ghost rumor blindly, the administration might have confiscated our club computers." },

    { type = "monologue", text = "I stare at the twin drafts resting on my screen: the warm, heartwarming draft of Suzumia's cat cafe review on one side, and the dangerous truth of the school network intrusion on the other." },
    { type = "monologue", text = "Tomorrow morning in Clubroom 204, the final editorial direction will rest squarely on my shoulders." },

    -- BRANCHING CHOICE: EDITORIAL DIRECTION
    {
        type = "choice",
        prompt = "How will you steer the Special Edition tomorrow morning?",
        options = {
            {
                text = "Highlight Suzumia's Cat Cafe as the heartwarming main spotlight",
                target = "branch_cat_focus"
            },
            {
                text = "Investigate the real school network mystery alongside Hoshida",
                target = "branch_mystery_focus"
            },
            {
                text = "Perfect the Dual Edition—protecting the club while solving the puzzle in secret",
                target = "branch_dual_mastery"
            }
        }
    },

    -- Branch 1: Cat Cafe Focus
    { type = "label", name = "branch_cat_focus" },
    { type = "monologue", text = "Suzumia is right. High school life shouldn't be consumed by shadows and paranoia. Bringing smiles to our classmates with cute cats and sweet parfaits is what journalism should be." },
    { type = "say", speaker = "Aki", text = "I'll make sure Suzumia's Meow Latte article gets the full front-page spread it deserves. Hoshida and I can handle the server quietly." },
    { type = "jump", target = "prologue_conclusion" },

    -- Branch 2: Mystery Investigation Focus
    { type = "label", name = "branch_mystery_focus" },
    { type = "monologue", text = "Something real is happening in the locked rooms of Kamiyama High. A true reporter can't simply look away when the truth is right in front of them." },
    { type = "say", speaker = "Aki", text = "Hoshida, keep your network sniffer active. Nagahashi's instinct was right all along—we're going to crack this school mystery wide open." },
    { type = "jump", target = "prologue_conclusion" },

    -- Branch 3: Dual Mastery
    { type = "label", name = "branch_dual_mastery" },
    { type = "monologue", text = "The beauty of our club is that we don't have to sacrifice one for the other. We can give our readers the warmest cat cafe feature while safeguarding the school in the shadows." },
    { type = "say", speaker = "Aki", text = "We deliver the ultimate Dual-Cover Edition. Suzumia gets her front-page triumph, Nagahashi gets his gripping mystery, and Hoshida and I protect the club's code." },
    { type = "jump", target = "prologue_conclusion" },

    -- Conclusion
    { type = "label", name = "prologue_conclusion" },
    { type = "monologue", text = "02:15 AM. The keyboard falls silent at last. The draft files are safely formatted and ready for the morning press." },
    { type = "monologue", text = "I take a slow sip of cooling tea, gazing out the bedroom window at the quiet autumn stars above Kamiyama City." },
    { type = "monologue", text = "Tomorrow, when the clubroom door opens and the afternoon sun floods the second floor... our real story begins." },
    { type = "wait", duration = 2.0 },
    { type = "monologue", text = "[ Chapter 1 Complete - Thank you for playing Lynux Caracal! ]" }
}

