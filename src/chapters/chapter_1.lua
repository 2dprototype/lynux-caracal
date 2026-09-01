-- src/chapters/chapter_1.lua
-- Lynux Caracal: Chapter 1 - "Ink, Whiskers & The Midnight Repeater"
-- Locked to Aki's POV (Newspaper Club Reporter)

local TaskConditions = require("src.tasks.task_conditions")
local EventBus = require("src.core.event_bus")

-- Chapter 1 Desktop Task Sequence Definitions
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
        PlayerStats.setFlag("email_unlocked:105", true)
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
