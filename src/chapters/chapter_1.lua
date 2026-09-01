-- src/chapters/chapter_1.lua
-- Lynux Caracal: Chapter 1 - "Ink, Whiskers & The Midnight Repeater"
-- Locked to Aki's POV (Newspaper Club Reporter)

local TaskConditions = require("src.tasks.task_conditions")
local EventBus = require("src.core.event_bus")
local ContentRegistry = require("src.core.content_registry")

-- =========================================================================
-- REGISTER DYNAMIC CONTENT TO APPEAR AS STORY PROGRESSES
-- =========================================================================

-- Helper function to register emails (handles both single and arrays)
local function registerEmails(flagName, emails)
    if type(emails) == "table" and #emails > 0 then
        for _, email in ipairs(emails) do
            ContentRegistry.registerOnFlag(flagName, email)
        end
    else
        ContentRegistry.registerOnFlag(flagName, emails)
    end
end

-- Helper function to register chat messages
local function registerChatMessages(flagName, messages)
    if type(messages) == "table" and #messages > 0 then
        for _, msg in ipairs(messages) do
            ContentRegistry.registerChatOnFlag(flagName, msg)
        end
    else
        ContentRegistry.registerChatOnFlag(flagName, messages)
    end
end

-- Register Hiko's email (appears immediately when chapter starts)
registerEmails("chapter_1_started", {
    {
        id = 101,
        subject = "Dinner tonight + DON'T forget the laundry!",
        sender = "Hiko (Sister)",
        email = "hiko.akizuki@kamiyama.net",
        time = "11:15 PM",
        body = "Hey big brother!\n\nI left some leftover curry in the fridge with plastic wrap. Make sure you microwave it before eating instead of eating it cold like a savage.\n\nAlso, are you still staying up late on the computer? Mom called and said don't forget to buy milk on your way home from school tomorrow.\n\nBy the way, all the first-years in my class were whispering today about weird noises and blinking lights from the 3rd floor old server room after 6 PM... Is your Newspaper Club really investigating that? Don't get suspended, dummy!\n\n- Hiko",
        unread = true,
        starred = true,
        unlocked = true
    }
})

-- Register Suzumia's email (appears when she promises to send it in story)
registerEmails("suzumia_email_sent", {
    {
        id = 102,
        subject = "Cat Cafe Draft Notes & Photo Selection [URGENT cute!]",
        sender = "Suzumia (Vice President)",
        email = "suzumia.y@kamiyama-press.org",
        time = "11:42 PM",
        body = "Hi Aki-kun,\n\nThank you so much for backing me up during the editorial meeting today when President Nagahashi started going overboard with his ghost story idea!\n\nI just organized my interview notes from the Meow Latte Cat Cafe. The owner was super nice and gave us permission to publish photos of Mochi (the white Scottish Fold) and Chobi (the calico)! Mochi actually climbed into my lap while I was writing notes... it was heaven. (///_///)\n\nI have attached my raw draft notes below ('cat_cafe_review.txt'). Please click the attachment below to download it to your Downloads folder, then check the formatting and menu pricing in TextEditor! I really want our front-cover feature to turn out amazing.\n\nSee you in the clubroom tomorrow!\n\n- Suzumia",
        unread = true,
        starred = true,
        unlocked = true,
        attachment = {
            filename = "cat_cafe_review.txt",
            size = "1.4 KB",
            content = "=== KAMIYAMA HIGH NEWSPAPER: SPECIAL FEATURE ===\nTITLE: A Whiskered Paradise: Visiting 'Meow Latte' Cat Cafe\nAUTHOR: Suzumia (VP) & Aki (Reporter)\n\n[HIGHLIGHTS]\n- Location: 3 minutes walking from Kamiyama Station South Exit.\n- Atmosphere: Warm wood interior, sunlight through large bay windows, relaxing jazz music.\n- Featured Stars:\n  * Mochi (White Scottish Fold) - Extremely friendly, curled up on our notes!\n  * Chobi (Calico Shorthair) - Playful and curious, loved our camera straps.\n- Recommended Treats: Strawberry Cat-Paw Parfait (¥680), Souffle Pancakes (¥750).\n- Student Special: 10% discount when presenting Kamiyama High ID card!\n\nNote from Suzumia: Aki-kun, let's make sure Mochi's picture is front and center on the main cover!"
        }
    }
})

-- Register Nagahashi's email (appears after reading Suzumia's email)
registerEmails("email_read:102", {
    {
        id = 103,
        subject = "OPERATION GHOST SCOOP: Editorial Manifesto #42",
        sender = "Nagahashi (President)",
        email = "president.nagahashi@kamiyama-press.org",
        time = "10:30 PM",
        body = "ATTENTION ALL NEWSPAPER CLUB PERSONNEL:\n\nThe Student Council thinks they can intimidate us with their budget review threats. THEY ARE MISTAKEN.\n\nOur upcoming edition MUST be sensational. Aki, as Lead Layout Editor, I expect you to give the 'Midnight Server Room Urban Legend' article the most dramatic, spine-chilling headline possible! Use red ink borders if the school mimeograph allows it!\n\nI know Suzumia insisted on her cat cafe piece, so we will compromise with the Dual Cover format. But the Mystery Report will be our magnum opus!\n\nJournalistic glory awaits!\n\n- President Nagahashi",
        unread = true,
        starred = false,
        unlocked = true
    }
})

-- Register Student Council email (appears after downloading attachment)
registerEmails("email_downloaded:102", {
    {
        id = 104,
        subject = "Notice of Review: Newspaper Club Operating Budget",
        sender = "Student Council (Auditing)",
        email = "council-audit@kamiyama-hs.ed.jp",
        time = "04:15 PM",
        body = "To: Kamiyama High Newspaper Club Editorial Board\n\nThis is a formal notification regarding the upcoming Q3 Club Budget Allocation Review.\n\nDue to declining readership in recent issues, your allocated printing quota is subject to a 40% reduction unless circulation and verified student engagement show a marked increase in the upcoming Special Edition.\n\nPlease submit your publication draft by Friday afternoon.\n\nKamiyama High Student Council Auditing Committee",
        unread = false,
        starred = false,
        unlocked = true
    }
})

-- Register Hoshida's email (appears after chatting with Suzumia)
registerEmails("chat_sent:suzumia", {
    {
        id = 105,
        subject = "Found that old server archive dump you asked for",
        sender = "Hoshida",
        email = "hoshida.tech@kamiyama-press.org",
        time = "09:50 PM",
        body = "Yo Aki,\n\nI dug through our club's old backup drive and found the raw network dump from last year's website server. I put it in your Downloads folder as 'school_server_dump.log'.\n\nNagahashi thinks he's just inventing spooky rumors to scare freshmen, but... honestly, there are some strange outbound packets logged on port 8080 from the old terminal. Take a look when you're at your desk.\n\nAnyway, back to watching my late-night anime stream. 2D cat maids > 3D drama any day.\n\n( ^ _ ^ )/\n- Hoshida",
        unread = true,
        starred = false,
        unlocked = true,
        attachment = {
            filename = "school_server_dump.log",
            size = "2.8 KB",
            content = "[23:14:02] [ETH-0] INBOUND PACKET on Port 8080 from 192.168.1.144 (Old 3rd Floor Rack)\n[23:14:03] [PAYLOAD] Encrypted XOR stream detected [Length: 256 bytes]\n[23:14:04] [DECRYPTOR] Matching signature with Newspaper Club archive...\n[23:14:05] [KEY_FOUND] Secret Token: SHADOW-CAT-09\n[23:14:06] [STATUS] Remote node ping active. Traceroute bounces through 3 internal relays.\n[23:14:07] [NOTE] Hoshida: 'Aki, someone is definitely using the school old repeater as a proxy.'"
        }
    }
})

-- Register Hoshida's traceroute email (appears after saving cipher.txt)
registerEmails("file_saved:cipher.txt", {
    {
        id = 106,
        subject = "[CONFIDENTIAL] Traceroute analysis & Basement Sub-Station Anomaly",
        sender = "Hoshida",
        email = "hoshida.tech@kamiyama-press.org",
        time = "07:15 AM",
        body = "Aki,\n\nI ran a subnet traceroute on the repeater while eating morning Pocky.\n\nThe packet route does not end on the 3rd floor. The signal is being re-routed down the elevator shaft into the locked basement power sub-station (IP: 192.168.1.254).\n\nCheck 'traceroute_dump.txt' in your Downloads folder.\n\nThe MAC address matches a commercial high-gain transceiver. Someone is piggybacking on our school grid to host an external server.\n\nKeep this between us until we pass the Student Council audit at 5 PM.\n\n- Hoshida [Root]",
        unread = true,
        starred = true,
        unlocked = true,
        attachment = {
            filename = "traceroute_dump.txt",
            size = "1.8 KB",
            content = "=== KAMIYAMA HIGH INTRANET TRACEROUTE LOG ===\nTARGET: port8080.ghost-relay.local\n\nHOP 1: 192.168.1.1 (Kamiyama Gateway Router) [1.2ms]\nHOP 2: 192.168.1.144 (3rd Floor Switchboard 04) [4.5ms]\nHOP 3: 192.168.1.254 (Basement Electrical Conduit Sub-Station) [0.8ms]\n\nALERT: Target IP 192.168.1.254 responds with MAC: 00:1A:C2:7B:99:4F\nNOTE (Hoshida): This MAC address belongs to an external commercial mesh router, not school inventory!\nCIPHER VERIFIED: [SHADOW-CAT-09]"
        }
    }
})

-- Register dynamic chat messages to appear when story progresses
registerChatMessages("browsed_cat_cafe", {
    {
        userId = 1,
        senderName = "Suzumia (Vice President)",
        color = {0.94, 0.48, 0.58},
        text = "Aki-kun! Did you get a chance to check the Meow Latte photos on their site? :)",
        timestamp = os.time()
    },
    {
        userId = 1,
        senderName = "Suzumia (Vice President)",
        color = {0.94, 0.48, 0.58},
        text = "Mochi (the white Scottish Fold) looked so peaceful in the bay window sunlight... what do you think of making him the main cover photo?",
        timestamp = os.time() + 1
    }
})

-- Register Hoshida's alert after chatting with Suzumia
registerChatMessages("chat_sent:suzumia", {
    {
        userId = 2,
        senderName = "Hoshida",
        color = {0.32, 0.72, 0.48},
        text = "[URGENT] Aki, check your Downloads folder right now.",
        timestamp = os.time() + 2
    },
    {
        userId = 2,
        senderName = "Hoshida",
        color = {0.32, 0.72, 0.48},
        text = "I dumped the raw packets from the 3rd floor repeater rack ('school_server_dump.log'). There is an encrypted XOR stream active on port 8080. Someone is using the school network as an unauthorized relay bridge.",
        timestamp = os.time() + 3
    }
})

-- =========================================================================
-- CHAPTER 1 TASK DEFINITIONS
-- =========================================================================

local ch1Tasks = {}

ch1Tasks.task8 = {
    id = "ch1_task8_dual_master_proof",
    title = "Finalize Dual-Cover Layout Proof",
    desc = "Open Files, navigate to Documents/newspaper/ and verify 'dual_issue_draft.txt' combining the Cat Cafe feature and the Mystery report.",
    hint = "Check 'Documents/newspaper/dual_issue_draft.txt' in Files or TextEditor.",
    xp = 150,
    condition = TaskConditions.fileContentContains("home/user/Documents/newspaper/dual_issue_draft.txt", "SHADOW-CAT-09"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        local PlayerStats = require("src.core.player_stats")
        PlayerStats.setFlag("chapter1_desktop_completed", true)
        Notifications.add("All Tasks Complete!", "Chapter 1 desktop layout finished. Click 'Continue Story' to proceed.", nil, 6.0)
    end
}

ch1Tasks.task7 = {
    id = "ch1_task7_secure_cipher",
    title = "Save Quarantine Cipher 'SHADOW-CAT-09'",
    desc = "Create a file named 'cipher.txt' in your home folder containing 'SHADOW-CAT-09' to trigger Hoshida's port quarantine script.",
    hint = "In TextEditor, create a new file, type 'SHADOW-CAT-09', and save as 'cipher.txt' in your home folder.",
    xp = 100,
    condition = TaskConditions.any(
        TaskConditions.fileContentContains("home/cipher.txt", "SHADOW-CAT-09"),
        TaskConditions.fileContentContains("home/user/cipher.txt", "SHADOW-CAT-09")
    ),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Security Firewall", "Port 8080 quarantined. Proxy severed.", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch1Tasks.task8)
    end
}

ch1Tasks.task6 = {
    id = "ch1_task6_inspect_server_dump",
    title = "Inspect Port 8080 Packet Dump",
    desc = "Hoshida detected an unauthorized proxy stream on the school network! Check 'school_server_dump.log' in Downloads or Hoshida's email (#105) to locate the token.",
    hint = "Open 'school_server_dump.log' from Downloads in TextEditor, or view Hoshida's email (#105). Find the Secret Token.",
    xp = 75,
    condition = TaskConditions.any(
        TaskConditions.emailRead("Hoshida"),
        TaskConditions.fileContentContains("home/user/Downloads/school_server_dump.log", "SHADOW-CAT-09")
    ),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Hoshida [Root]", "Token identified! Save it in 'cipher.txt' in home folder.", nil, 6.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch1Tasks.task7)
    end
}

ch1Tasks.task5 = {
    id = "ch1_task5_chat_with_suzumia",
    title = "Message Suzumia on Chat",
    desc = "Open Chat, select 'Suzumia (Vice President)', and send her your feedback on the Meow Latte photos.",
    hint = "Open Chat from taskbar, click on Suzumia, read Aki's scripted response, and click 'Send'.",
    xp = 75,
    condition = TaskConditions.chatSentTo("Suzumia"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        local PlayerStats = require("src.core.player_stats")
        PlayerStats.setFlag("hoshida_alert", true)
        Notifications.add("Hoshida [Root]", "URGENT: Port 8080 anomaly detected on school subnet!", nil, 6.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch1Tasks.task6)
    end
}

ch1Tasks.task4 = {
    id = "ch1_task4_browse_cat_cafe",
    title = "Research Meow Latte Website",
    desc = "Launch Browser and visit 'http://meowlatte.com' to review the cat profiles and dessert specials.",
    hint = "Open Browser from taskbar, type 'http://meowlatte.com' or click the link on the home page.",
    xp = 75,
    condition = TaskConditions.browserVisited("cat"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        local PlayerStats = require("src.core.player_stats")
        PlayerStats.setFlag("browsed_cat_cafe", true)
        Notifications.add("Chat Notification", "Suzumia (Vice President) is online now", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch1Tasks.task5)
    end
}

ch1Tasks.task3 = {
    id = "ch1_task3_review_draft_notes",
    title = "Review & Format 'cat_cafe_review.txt'",
    desc = "Open 'cat_cafe_review.txt' from Downloads in TextEditor. Verify the student discount and parfait details, then save the file.",
    hint = "In Files or TextEditor, open 'cat_cafe_review.txt' in Downloads. Press Ctrl+S to save.",
    xp = 50,
    condition = TaskConditions.any(
        TaskConditions.fileSaved("cat_cafe_review.txt"),
        TaskConditions.fileContentContains("home/user/Downloads/cat_cafe_review.txt", "10% discount")
    ),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Browser Alert", "Meow Latte website accessible at http://meowlatte.com", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch1Tasks.task4)
    end
}

ch1Tasks.task2 = {
    id = "ch1_task2_download_attachment",
    title = "Download 'cat_cafe_review.txt' from Email",
    desc = "Open Suzumia's email (#102) and click 'Download File' on the attachment to save her notes to Downloads.",
    hint = "Open Email app, view Suzumia's email (#102), scroll down, and click the 'Download File' button.",
    xp = 50,
    condition = TaskConditions.attachmentDownloaded("cat_cafe_review.txt"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("TextEditor Alert", "Open 'cat_cafe_review.txt' from Downloads to inspect", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch1Tasks.task3)
    end
}

ch1Tasks.task1 = {
    id = "ch1_task1_check_inbox",
    title = "Check Inbox (Hiko & Suzumia)",
    desc = "Open Email on your desktop. Read the message from your sister Hiko, as well as Suzumia's draft notes.",
    hint = "Launch Email from taskbar. Click on Hiko's and Suzumia's unread emails to read them.",
    xp = 50,
    condition = TaskConditions.all(
        TaskConditions.emailRead("Hiko"),
        TaskConditions.emailRead("Suzumia")
    ),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Email Attachment", "Suzumia attached 'cat_cafe_review.txt' to her email", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch1Tasks.task2)
    end
}

-- =========================================================================
-- CHAPTER 1 STORY SCRIPT
-- =========================================================================

return {
    -- =========================================================================
    -- ACT I: GOLDEN HOUR IN CLUBROOM 204
    -- =========================================================================
    { type = "bg", name = "clubroom_sunset" },
    { type = "music", track = "main_theme", loop = true },

    -- Trigger content registry to check for initial content
    { type = "flag", name = "chapter_1_started", value = true },
    
    -- Force content check immediately after setting the flag
    { type = "custom", fn = function()
        ContentRegistry.checkFlags()
    end },

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

    -- TRIGGER: Suzumia sends her email
    { type = "flag", name = "suzumia_email_sent", value = true },
    
    -- Force content check immediately after setting the flag
    { type = "custom", fn = function()
        ContentRegistry.checkFlags()
    end },
    
    { type = "monologue", text = "Suzumia's email should arrive in my inbox soon with the cat cafe attachments." },

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

    -- ASSIGN INITIAL CHAPTER 1 TASK & SWITCH TO DESKTOP
    {
        type = "task",
        task = ch1Tasks.task1
    },

    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- =========================================================================
    -- ACT V: MIDNIGHT RESOLUTION & BRANCHING CHOICES
    -- =========================================================================
    { type = "label", name = "post_task" },
    { type = "bg", name = "bedroom_night" },
    { type = "monologue", text = "01:15 AM. The keyboard falls silent at last. 'cipher.txt' is saved, and Hoshida's automated script successfully severed the intruder's tunnel." },
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
    { type = "jump", target = "chapter1_conclusion" },

    -- Branch 2: Mystery Investigation Focus
    { type = "label", name = "branch_mystery_focus" },
    { type = "monologue", text = "Something real is happening in the locked rooms of Kamiyama High. A true reporter can't simply look away when the truth is right in front of them." },
    { type = "say", speaker = "Aki", text = "Hoshida, keep your network sniffer active. Nagahashi's instinct was right all along—we're going to crack this school mystery wide open." },
    { type = "jump", target = "chapter1_conclusion" },

    -- Branch 3: Dual Mastery
    { type = "label", name = "branch_dual_mastery" },
    { type = "monologue", text = "The beauty of our club is that we don't have to sacrifice one for the other. We can give our readers the warmest cat cafe feature while safeguarding the school in the shadows." },
    { type = "say", speaker = "Aki", text = "We deliver the ultimate Dual-Cover Edition. Suzumia gets her front-page triumph, Nagahashi gets his gripping mystery, and Hoshida and I protect the club's code." },
    { type = "jump", target = "chapter1_conclusion" },

    -- Conclusion of Chapter 1 & Transition into Chapter 2
    { type = "label", name = "chapter1_conclusion" },
    { type = "monologue", text = "02:15 AM. The draft files are safely formatted and ready for the morning press." },
    { type = "monologue", text = "I take a slow sip of cooling tea, gazing out the bedroom window at the quiet autumn stars above Kamiyama City." },
    { type = "monologue", text = "Tomorrow, when the clubroom door opens and the afternoon sun floods the second floor... our real story begins." },
    { type = "wait", duration = 1.5 },

    -- AUTO-TRANSITION TO CHAPTER 2
    {
        type = "load_chapter",
        chapter = 2
    }
}