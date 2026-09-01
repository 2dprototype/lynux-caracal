-- src/chapters/chapter_3.lua
-- Lynux Caracal: Chapter 3 - "The Ghost Mesh"
-- Locked to Aki's POV (Newspaper Club Reporter)

local TaskConditions = require("src.tasks.task_conditions")
local EventBus = require("src.core.event_bus")

-- =========================================================================
-- CHAPTER 3: EXTENSIVE TASK SEQUENCE
-- =========================================================================

local ch3Tasks = {}

-- TASK 15: FINAL CHAPTER RESOLUTION
ch3Tasks.task15 = {
    id = "ch3_task15_network_cleanup",
    title = "Purge the Ghost Mesh & Submit Final Report",
    desc = "Create a comprehensive report in 'ghost_mesh_report.txt' documenting the Meow Latte router, basement sub-station, and all forensic evidence. Then send it to Hoshida via the terminal.",
    hint = "Write a detailed report in TextEditor, save as 'ghost_mesh_report.txt' in Documents/newspaper/. Then type 'report_submit' in Terminal.",
    xp = 300,
    condition = TaskConditions.all(
        TaskConditions.fileContentContains("home/user/Documents/newspaper/ghost_mesh_report.txt", "Meow Latte"),
        TaskConditions.fileContentContains("home/user/Documents/newspaper/ghost_mesh_report.txt", "basement"),
        TaskConditions.flagIsSet("terminal_report_submitted")
    ),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        local PlayerStats = require("src.core.player_stats")
        PlayerStats.setFlag("chapter3_completed", true)
        Notifications.add("Chapter 3 Complete!", "The Ghost Mesh has been neutralized. The truth is finally documented.", nil, 6.0)
    end
}

-- TASK 14: TERMINAL REPORT SUBMISSION
ch3Tasks.task14 = {
    id = "ch3_task14_terminal_submit",
    title = "Submit Final Report via Terminal",
    desc = "Open Terminal and type 'report_submit' to send the compiled evidence to Hoshida's secure channel.",
    hint = "Launch Terminal from taskbar, type 'report_submit' and press Enter.",
    xp = 100,
    condition = TaskConditions.flagIsSet("terminal_report_submitted"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Evidence Submitted", "Hoshida has received the report. The authorities have been notified.", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch3Tasks.task15)
    end
}

-- TASK 13: COMPILE EVIDENCE REPORT
ch3Tasks.task13 = {
    id = "ch3_task13_compile_report",
    title = "Compile All Evidence into a Report",
    desc = "Create a file named 'ghost_mesh_report.txt' in Documents/newspaper/ that includes:\n- The MAC address from Meow Latte router\n- The basement sub-station IP (192.168.1.254)\n- The cipher token (SHADOW-CAT-09)\n- Traceroute logs\n- Timeline of events",
    hint = "Open TextEditor, create a new file, type out all the evidence, and save as 'ghost_mesh_report.txt' in Documents/newspaper/.",
    xp = 150,
    condition = TaskConditions.fileContentContains("home/user/Documents/newspaper/ghost_mesh_report.txt", "SHADOW-CAT-09"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Report Ready", "All evidence compiled. Now submit it via Terminal.", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch3Tasks.task14)
    end
}

-- TASK 12: RESEARCH THE MAC ADDRESS
ch3Tasks.task12 = {
    id = "ch3_task12_mac_research",
    title = "Research the Commercial MAC Address",
    desc = "The MAC address 00:1A:C2:7B:99:4F belongs to a specific commercial networking brand. Use the Browser to search for 'MAC address vendor lookup' or visit 'http://macvendors.com' to identify the hardware manufacturer.",
    hint = "Open Browser and search for MAC address vendor lookup. Enter the MAC address to find the manufacturer.",
    xp = 100,
    condition = TaskConditions.any(
        TaskConditions.browserVisited("macvendors"),
        TaskConditions.browserVisited("00:1A:C2")
    ),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Hardware Identified", "The router is a commercial-grade mesh node manufactured for enterprise use.", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch3Tasks.task13)
    end
}

-- TASK 11: HOSHIDA'S SECURE CHAT
ch3Tasks.task11 = {
    id = "ch3_task11_chat_hoshida",
    title = "Chat with Hoshida About the Cafe Router",
    desc = "Open Chat, select 'Hoshida [Root]' (formerly Hoshida Club Member), and share what you discovered about Meow Latte's router.",
    hint = "Open Chat, click on Hoshida [Root], send the scripted message about the MAC address match.",
    xp = 75,
    condition = TaskConditions.chatSentTo("Hoshida"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Hoshida [Root]", "The MAC address confirms the link. Start researching the hardware manufacturer.", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch3Tasks.task12)
    end
}

-- TASK 10: READ HOSHIDA'S CHAPTER 3 EMAIL
ch3Tasks.task10 = {
    id = "ch3_task10_read_hoshida_email",
    title = "Read Hoshida's New Email (#107)",
    desc = "Hoshida has sent a follow-up email with additional forensic data. Open the Email app and read his latest message.",
    hint = "Open Email, find Hoshida's newest email (#107), and read the full contents.",
    xp = 50,
    condition = TaskConditions.emailRead("Hoshida"),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        Notifications.add("Hoshida [Root]", "The MAC address from Meow Latte matches the basement sub-station. We need to investigate.", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch3Tasks.task11)
    end
}

-- TASK 9: PROCESS HIKO'S ANGRY MAILS
ch3Tasks.task9 = {
    id = "ch3_task9_handle_hiko_mails",
    title = "Deal with Hiko's Angry Emails",
    desc = "Hiko has been sending increasingly frustrated emails about your late nights and lack of sleep. Open the Email app and read all her messages.",
    hint = "Open Email, read Hiko's multiple emails (#108, #109, #110). Respond by acknowledging her concerns.",
    xp = 50,
    condition = TaskConditions.all(
        TaskConditions.emailRead("Hiko"),
        TaskConditions.flagIsSet("hiko_mails_acknowledged")
    ),
    onComplete = function(task)
        local Notifications = require("src.desktop.notifications")
        local PlayerStats = require("src.core.player_stats")
        PlayerStats.setFlag("hiko_calm", true)
        Notifications.add("Hiko", "Finally! I've been trying to get through to you all week. Thanks for checking in, dummy.", nil, 5.0)
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.setTask(ch3Tasks.task10)
    end
}

return {
    -- =========================================================================
    -- ACT XI: THE MORNING AFTER THE REVELATION
    -- =========================================================================
    { type = "bg", name = "bedroom_morning" },
    { type = "music", track = "morning_theme", loop = true },

    { type = "monologue", text = "--- CHAPTER 3: THE GHOST MESH ---" },
    { type = "monologue", text = "06:30 AM. I barely slept. Every time I closed my eyes, I saw that MAC address staring back at me." },
    { type = "monologue", text = "The cafe owner's face. The locked basement door. The way our eyes met for just a fraction of a second." },
    { type = "monologue", text = "I rub my tired eyes and reach for my phone. Already, there are notifications piling up." },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 06:15 AM] Hiko: 'AKI! I saw your light on again at 3 AM. WHAT ARE YOU DOING?!'" },
    
    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 06:17 AM] Hiko: 'Are you even ALIVE?! You need to sleep! You're going to collapse!'" },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 06:21 AM] Hiko: 'I'm not joking. I'm calling Mom if you don't respond by breakfast.'" },

    { type = "say", speaker = "Aki", text = "[Thought] Oh no. Hiko's in full protective sister mode. I need to respond before she wakes up the entire house." },

    { type = "monologue", text = "I type a quick message back, trying to sound calm and reassuring." },

    { type = "say", speaker = "Aki", text = "[Reply: 06:33 AM] 'I'm fine, Hiko. Just working on an important club project. I'll be down for breakfast soon. Promise.'" },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 06:34 AM] Hiko: 'You said that yesterday. And the day before. I'm coming up there.'" },

    { type = "monologue", text = "I hear the sound of rapid footsteps on the stairs. Hiko's bedroom door slams open. Her voice echoes through the hallway." },

    { type = "char_show", char = "Hiko", pos = "center" },
    { type = "say", speaker = "Hiko", text = "AKI! I'VE HAD ENOUGH OF THIS!" },

    { type = "monologue", text = "My door flies open. Hiko stands there in her pajamas, arms crossed, looking like a storm cloud about to burst." },

    { type = "say", speaker = "Aki", text = "Hiko, calm down. It's not—" },

    { type = "say", speaker = "Hiko", text = "Not what?! Not the third night in a row you've stayed up until sunrise?! I'm not stupid, Aki!" },
    { type = "say", speaker = "Hiko", text = "You've been staring at that computer screen like some kind of zombie. What's really going on?" },

    { type = "monologue", text = "I hesitate. I can't tell her about the Ghost Mesh. She'll worry even more. But I can't lie to her either." },

    { type = "say", speaker = "Aki", text = "It's the Newspaper Club. We have this huge project. The Student Council audit—" },

    { type = "say", speaker = "Hiko", text = "That's not all of it. I know that look in your eyes. You're investigating something. Something you think you need to hide from me." },
    { type = "say", speaker = "Hiko", text = "I'm your sister, Aki. I grew up with you. I can tell when you're keeping secrets." },

    { type = "monologue", text = "She's right. Of course she's right. I've never been able to hide anything from her." },

    { type = "say", speaker = "Aki", text = "I promise I'll tell you everything once it's safe. But right now... I need you to trust me." },

    { type = "say", speaker = "Hiko", text = "[Sighs heavily] Fine. But I'm sending you emails. Lots of them. Every hour until you respond. I'm not letting you disappear into that computer of yours." },
    { type = "say", speaker = "Hiko", text = "And when you come down for breakfast, you better have a good explanation. Or I'm telling Mom you've been watching 'midnight urban legend documentaries' again." },

    { type = "say", speaker = "Aki", text = "That was ONE TIME." },

    { type = "say", speaker = "Hiko", text = "You screamed so loud you woke up the entire neighborhood." },

    { type = "monologue", text = "Despite everything, a smile creeps onto my face. Hiko's theatrical worry is annoying, but also... comforting. At least someone's looking out for me." },

    { type = "char_hide" },
    { type = "wait", duration = 0.5 },

    -- =========================================================================
    -- ACT XII: THE CLUBROOM BRIEFING
    -- =========================================================================
    { type = "bg", name = "clubroom_day" },
    { type = "monologue", text = "08:45 AM. The clubroom is quiet except for the hum of Hoshida's laptop. Nagahashi is still lecturing someone on the phone about printing costs." },
    { type = "monologue", text = "Suzumia sits at the table, carefully sorting through a stack of photo proofs. She looks up and smiles warmly as I walk in." },

    { type = "char_show", char = "Suzumia", pos = "left" },
    { type = "char_show", char = "Hoshida", pos = "right" },

    { type = "say", speaker = "Suzumia", text = "Aki-kun! You look exhausted. Did you sleep at all last night?" },

    { type = "say", speaker = "Aki", text = "I got a few hours. There's something important I need to discuss with you both." },

    { type = "monologue", text = "Hoshida looks up from his screen, his expression immediately sharpening. He knows exactly what I'm about to say." },

    { type = "say", speaker = "Hoshida", text = "The cafe router." },

    { type = "say", speaker = "Aki", text = "Yes. The MAC address on the Meow Latte router matches exactly with the basement sub-station node. 00:1A:C2:7B:99:4F." },

    { type = "say", speaker = "Suzumia", text = "Wait... what? The cafe router? What does that have to do with the school network?" },

    { type = "say", speaker = "Hoshida", text = "Everything. Someone is using the Meow Latte router as a physical mesh node to bridge the school basement network to an external source." },
    { type = "say", speaker = "Hoshida", text = "The cafe owner—or someone with access to the cafe—is running a hidden server from inside the school basement." },

    { type = "say", speaker = "Suzumia", text = "That's... that's insane! The owner was so nice! He gave us the student discount! He let us take photos!" },

    { type = "say", speaker = "Aki", text = "I know. He seemed genuine. But the evidence doesn't lie, Suzumia." },

    { type = "monologue", text = "Suzumia's face goes pale. She looks down at the photo of Mochi sitting in her lap, her fingers trembling slightly." },

    { type = "say", speaker = "Suzumia", text = "I... I brought him a thank-you card. From the club. I left it on the counter with his name on it. What if he thinks we're investigating him?" },

    { type = "say", speaker = "Nagahashi", text = "WE ARE INVESTIGATING HIM! THIS IS THE STORY OF THE CENTURY!" },

    { type = "monologue", text = "Nagahashi slams the phone down and strides over, his eyes alight with excitement." },

    { type = "say", speaker = "Nagahashi", text = "A commercial mesh node bridging our school network to a cat cafe?! This is the conspiracy I've been dreaming of! The Phantom of the 3rd Floor has a physical connection!" },

    { type = "say", speaker = "Aki", text = "President, we need to be careful about this. If the owner is running a secret server, confronting him directly could be dangerous." },

    { type = "say", speaker = "Nagahashi", text = "Dangerous?! Danger is the crucible of truth! Aki, you're going to investigate this properly!" },

    { type = "say", speaker = "Hoshida", text = "I've already started gathering forensic data. The traceroute logs, the packet dumps, the MAC address registry. We have enough to compile a detailed report." },

    { type = "say", speaker = "Suzumia", text = "But what do we do with the report? If we publish it in the newspaper, the owner could sue the school! Or worse, shut down the cafe!" },

    { type = "say", speaker = "Aki", text = "She's right. We need to handle this with care. We document the evidence, verify our facts, and then decide what to do." },

    { type = "say", speaker = "Nagahashi", text = "Fine. But I want weekly updates. This is our magnum opus!" },

    { type = "char_hide" },

    -- =========================================================================
    -- ACT XIII: THE INVESTIGATION BEGINS - HIKO'S MAIL STORM
    -- =========================================================================
    { type = "monologue", text = "09:15 AM. I sit down at my workstation, my mind racing with possibilities. Hoshida transfers the forensic data to my desktop." },
    { type = "monologue", text = "Before I can even open the files, my phone starts buzzing again. And again. And again." },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 09:16 AM] Hiko: 'Did you eat breakfast? I didn't see you come down.'" },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 09:17 AM] Hiko: 'If you skip breakfast again I'm coming to your classroom.'" },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 09:18 AM] Hiko: 'I'm not joking, Aki. I'll bring Mom's homemade onigiri and embarrass you in front of your friends.'" },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 09:20 AM] Hiko: 'Okay, that last one was a bluff. But I'm still worried. Text me back you idiot.'" },

    { type = "say", speaker = "Aki", text = "[Thought] She's relentless. I should probably respond before she escalates to carrier pigeons." },

    { type = "monologue", text = "I type a quick response between checking Hoshida's files." },

    { type = "say", speaker = "Aki", text = "[Reply: 09:22 AM] 'I had a rice ball on the way to school. I'm alive. You can stand down, General Hiko.'" },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 09:23 AM] Hiko: 'Don't call me General! >:( And I'm not standing down until you promise to get at least 6 hours of sleep tonight.'" },

    { type = "say", speaker = "Aki", text = "[Reply: 09:24 AM] 'I promise I'll try. Now can I please work without getting spammed every 2 minutes?'" },

    { type = "sfx", name = "notification" },
    { type = "monologue", text = "[Message: 09:25 AM] Hiko: 'Fine. But I'll be sending emails too. READ THEM.'" },

    { type = "monologue", text = "I sigh, but I can't help smiling. Hiko's overbearing concern is exhausting, but it's also the only reason I haven't completely collapsed from sleep deprivation." },

    -- =========================================================================
    -- ACT XIV: THE DESKTOP INVESTIGATION PHASE
    -- =========================================================================
    { type = "monologue", text = "10:00 AM. The investigation requires full desktop access. I need to read Hoshida's forensic dump, research the MAC address, and compile evidence." },

    -- ASSIGN TASK 9: HIKO'S MAILS
    {
        type = "task",
        task = ch3Tasks.task9
    },

    { type = "switch_mode", mode = "desktop", transition = "fade" },

    -- =========================================================================
    -- ACT XV: EVIDENCE ACCUMULATION
    -- =========================================================================
    { type = "label", name = "post_task9" },

    { type = "monologue", text = "11:45 AM. Finally, Hiko's emails have been acknowledged. She's calmed down slightly, though I know I'll be getting hourly check-ins for the foreseeable future." },
    { type = "monologue", text = "Hoshida's forensic data is more alarming than I expected. The basement node has been active for at least two years." },

    { type = "char_show", char = "Hoshida", pos = "center" },
    { type = "say", speaker = "Hoshida", text = "I've traced the data flow patterns. The node isn't just acting as a proxy—it's hosting a full server instance." },
    { type = "say", speaker = "Hoshida", text = "Someone has been using our school's infrastructure to run a private cloud service from the basement. The electricity alone would have shown up on the school's billing." },

    { type = "say", speaker = "Aki", text = "So someone had to have access to the school's utility accounts. That means either an administrator, a long-term contractor... or someone who bribed the right person." },

    { type = "say", speaker = "Hoshida", text = "Exactly. The MAC address from Meow Latte is the physical link. Someone from the cafe—likely the owner himself—is the bridge between the school basement and the outside world." },

    { type = "char_hide" },

    -- =========================================================================
    -- ACT XVI: RESEARCH & ROUTER IDENTIFICATION
    -- =========================================================================
    { type = "monologue", text = "12:30 PM. The next step is identifying the router's manufacturer and model. If we can trace the hardware, we might be able to find a paper trail." },

    -- ASSIGN TASK 10: READ HOSHIDA'S NEW EMAIL
    {
        type = "task",
        task = ch3Tasks.task10
    },

    { type = "switch_mode", mode = "desktop", transition = "fade" },

    -- =========================================================================
    -- ACT XVII: CHAT WITH HOSHIDA
    -- =========================================================================
    { type = "label", name = "post_task10" },

    { type = "char_show", char = "Hoshida", pos = "center" },
    { type = "say", speaker = "Hoshida", text = "Good. You've read the new data. The MAC address vendor is a company called 'Nexus Networks'—they specialize in commercial-grade mesh routing for enterprise clients." },
    { type = "say", speaker = "Hoshida", text = "The router model is from their 'ShadowMesh' product line, which is designed specifically for covert network bridging." },

    { type = "say", speaker = "Aki", text = "Covert network bridging? That's... concerningly specific. This wasn't just some amateur using consumer equipment." },

    { type = "say", speaker = "Hoshida", text = "Whoever set this up had professional knowledge and access to enterprise-grade hardware. This is not a prank or a student experiment." },
    { type = "say", speaker = "Hoshida", text = "The ShadowMesh devices are used by corporations and government agencies for secure off-grid network access. Finding one in a high school basement is extremely unusual." },

    { type = "say", speaker = "Aki", text = "So we're dealing with someone who knows what they're doing. Someone who wanted to run an off-grid server without being detected." },

    { type = "say", speaker = "Hoshida", text = "And who was willing to invest significant money to do it. The ShadowMesh router alone costs over two thousand dollars." },

    { type = "monologue", text = "My stomach drops. Two thousand dollars. A high school student couldn't afford that. A cafe owner might, but why would they want to host a server in a school basement?" },

    { type = "char_hide" },

    -- =========================================================================
    -- ACT XVIII: MAC ADDRESS RESEARCH
    -- =========================================================================
    { type = "monologue", text = "01:15 PM. I need to confirm the hardware details myself. Hoshida's data is reliable, but I want to see the MAC address registry with my own eyes." },

    -- ASSIGN TASK 11: CHAT WITH HOSHIDA
    {
        type = "task",
        task = ch3Tasks.task11
    },

    { type = "switch_mode", mode = "desktop", transition = "fade" },

    -- =========================================================================
    -- ACT XIX: ONLINE RESEARCH
    -- =========================================================================
    { type = "label", name = "post_task11" },

    { type = "monologue", text = "02:00 PM. Hoshida confirms the connection. The MAC address from Meow Latte is an exact match. There's no doubt anymore." },
    { type = "monologue", text = "I open the browser to research Nexus Networks and the ShadowMesh line. The more I read, the more unsettling the whole situation becomes." },

    -- ASSIGN TASK 12: RESEARCH MAC ADDRESS
    {
        type = "task",
        task = ch3Tasks.task12
    },

    { type = "switch_mode", mode = "desktop", transition = "fade" },

    -- =========================================================================
    -- ACT XX: COMPILING THE REPORT
    -- =========================================================================
    { type = "label", name = "post_task12" },

    { type = "monologue", text = "03:30 PM. The research is complete. Nexus Networks' ShadowMesh line is exclusively sold to corporate clients with signed NDAs. The hardware in our school basement is not available to the public." },
    { type = "monologue", text = "We have a professional-grade covert network bridge operating from inside Kamiyama High School, physically linked to a local cat cafe. The implications are staggering." },

    { type = "char_show", char = "Suzumia", pos = "center" },
    { type = "say", speaker = "Suzumia", text = "Aki-kun... this is much bigger than I ever imagined. What are we supposed to do with this information?" },

    { type = "say", speaker = "Aki", text = "We need to compile a complete report. Every piece of evidence, every log entry, every photo of the router and the basement node. Hoshida's forensic dumps. The MAC address registry. Everything." },

    { type = "say", speaker = "Suzumia", text = "And then what? Do we go to the authorities? The school administration?" },

    { type = "say", speaker = "Nagahashi", text = "[From the corner] WE PUBLISH! Front page exposé! This is the biggest scandal in Kamiyama High history!" },

    { type = "say", speaker = "Aki", text = "President, we can't publish this without verifying every single fact. If we publish something incorrect, we lose all credibility." },

    { type = "say", speaker = "Suzumia", text = "Aki's right. If we're going to do this, we have to do it properly. A full report, verified evidence, and a plan for what to do next." },

    { type = "char_hide" },

    -- =========================================================================
    -- ACT XXI: THE REPORT WRITING PHASE
    -- =========================================================================
    { type = "monologue", text = "04:45 PM. I sit down at my desktop, ready to compile everything we've discovered." },
    { type = "monologue", text = "Hoshida has sent me the complete forensic package. Suzumia has provided photos of the cafe router. Nagahashi has written a dramatic introduction." },
    { type = "monologue", text = "Now I just need to assemble it all into a coherent document." },

    -- ASSIGN TASK 13: COMPILE THE REPORT
    {
        type = "task",
        task = ch3Tasks.task13
    },

    { type = "switch_mode", mode = "desktop", transition = "fade" },

    -- =========================================================================
    -- ACT XXII: REPORT SUBMISSION
    -- =========================================================================
    { type = "label", name = "post_task13" },

    { type = "monologue", text = "06:15 PM. The report is complete. Every piece of evidence is documented, cross-referenced, and organized." },
    { type = "monologue", text = "I read through the final draft three times, checking for errors. Everything is accurate." },
    { type = "monologue", text = "Hoshida has set up a secure submission channel through the terminal. All I have to do is send it." },

    { type = "char_show", char = "Hoshida", pos = "center" },
    { type = "say", speaker = "Hoshida", text = "The terminal channel is ready. Type 'report_submit' and it will send the encrypted file to my secure server." },
    { type = "say", speaker = "Hoshida", text = "Once it's submitted, I can route it to the appropriate authorities without alerting the cafe owner." },

    { type = "say", speaker = "Aki", text = "Are you sure about this? Once we submit the report, there's no taking it back." },

    { type = "say", speaker = "Hoshida", text = "We've verified every single piece of evidence. The MAC address match, the traceroute logs, the packet dumps. This isn't speculation anymore." },
    { type = "say", speaker = "Hoshida", text = "It's time to act." },

    { type = "char_hide" },

    -- =========================================================================
    -- ACT XXIII: THE TERMINAL SUBMISSION
    -- =========================================================================
    { type = "monologue", text = "06:30 PM. I open the terminal. My hands are steady as I type the command." },

    -- ASSIGN TASK 14: SUBMIT VIA TERMINAL
    {
        type = "task",
        task = ch3Tasks.task14
    },

    { type = "switch_mode", mode = "desktop", transition = "fade" },

    -- =========================================================================
    -- ACT XXIV: FINAL RESOLUTION
    -- =========================================================================
    { type = "label", name = "post_task14" },

    { type = "monologue", text = "07:00 PM. The report has been submitted. Hoshida confirms receipt and encryption." },
    { type = "monologue", text = "The investigation is officially complete. The Ghost Mesh has been documented and exposed." },

    { type = "char_show", char = "Suzumia", pos = "left" },
    { type = "char_show", char = "Hoshida", pos = "right" },
    { type = "char_show", char = "Nagahashi", pos = "center" },

    { type = "say", speaker = "Nagahashi", text = "We've done it! The truth has been revealed! Journalism prevails!" },

    { type = "say", speaker = "Suzumia", text = "Aki-kun... I can't believe we actually did this. We found a real conspiracy in our own school." },

    { type = "say", speaker = "Aki", text = "We all did it together. Hoshida's forensic work, your photos, Nagahashi's determination. This was a team effort." },

    { type = "say", speaker = "Hoshida", text = "The authorities will take it from here. The cafe owner will be investigated, and the basement server will be shut down." },

    { type = "say", speaker = "Aki", text = "I wonder why he did it. The owner seemed like such a nice person." },

    { type = "say", speaker = "Suzumia", text = "Sometimes the kindest people have the most complicated reasons for what they do. That doesn't make what he was doing right, but... I hope he has a chance to explain." },

    { type = "monologue", text = "Suzumia looks down at her hands, and I can see the conflict in her eyes. She genuinely liked the cafe owner." },
    { type = "monologue", text = "This whole situation is so much more complicated than I ever imagined." },

    { type = "char_hide" },

    -- =========================================================================
    -- ACT XXV: THE FINAL TASK
    -- =========================================================================
    { type = "monologue", text = "07:30 PM. There's one final task remaining. I need to create a comprehensive cleanup report documenting everything we've done and submitting it to Hoshida." },

    -- ASSIGN TASK 15: FINAL REPORT & CLEANUP
    {
        type = "task",
        task = ch3Tasks.task15
    },

    { type = "switch_mode", mode = "desktop", transition = "fade" },

    -- =========================================================================
    -- ACT XXVI: CONCLUSION
    -- =========================================================================
    { type = "label", name = "post_task15" },

    { type = "monologue", text = "08:00 PM. Everything is done. The report is submitted. The investigation is complete." },
    { type = "monologue", text = "I lean back in my chair, feeling the weight of the past three chapters finally lift from my shoulders." },

    { type = "char_show", char = "Suzumia", pos = "center" },

    { type = "say", speaker = "Suzumia", text = "Aki-kun... thank you. For everything. For staying calm when the rest of us were panicking. For putting together the report. For being the one I could always count on." },

    { type = "say", speaker = "Aki", text = "You were the one who believed in this club from the start, Suzumia. I just followed your lead." },

    { type = "say", speaker = "Suzumia", text = "You're too modest. But I'm glad we're in this together." },

    { type = "monologue", text = "She smiles softly, and for a moment, the chaos of the past few weeks feels like it was all worth it." },

    { type = "say", speaker = "Aki", text = "So... what happens now?" },

    { type = "say", speaker = "Suzumia", text = "We wait. The authorities will investigate the cafe owner. The school will likely shut down the basement node. And we go back to being newspaper club members." },

    { type = "say", speaker = "Aki", text = "Back to normal?" },

    { type = "say", speaker = "Suzumia", text = "Back to normal. Well... as normal as things can be after uncovering a conspiracy." },

    { type = "char_hide" },

    { type = "monologue", text = "I look out the window at the darkening sky. The stars are starting to appear, faintly glowing in the twilight." },
    { type = "monologue", text = "It's been a wild ride. But somehow, I feel like this is just the beginning." },

    { type = "wait", duration = 1.5 },

    { type = "monologue", text = "========================================================" },
    { type = "monologue", text = "     CHAPTER 3 COMPLETE. THE STORY CONTINUES..." },
    { type = "monologue", text = "========================================================" }
}