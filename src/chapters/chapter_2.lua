-- src/chapters/chapter_2.lua
-- Lynux Caracal: Chapter 2 - "The Morning Commute & The Basement Sub-Station"
-- Locked to Aki's POV (Newspaper Club Reporter)

local TaskConditions = require("src.tasks.task_conditions")
local EventBus = require("src.core.event_bus")

return {
    -- =========================================================================
    -- ACT VI: THE MORNING COMMUTE & GINKGO SLOPE
    -- =========================================================================
    { type = "bg", name = "commute_morning" },
    { type = "music", track = "morning_theme", loop = true },
    { type = "monologue", text = "--- CHAPTER 2: INK, WHISKERS & THE BASEMENT SUB-STATION ---" },
    { type = "monologue", text = "07:35 AM. The morning air is crisp with the first hint of late October frost. Golden ginkgo leaves drift gently onto the sidewalk along the slope leading up to Kamiyama High School." },
    { type = "monologue", text = "Beside me, my sister Hiko is marching with brisk steps, clutching a buttered toast in one hand and her oversized school bag in the other." },

    { type = "say", speaker = "Hiko", text = "Aki, you look completely washed out. You have huge dark circles under your eyes! Did you seriously stay awake clattering on your keyboard until three in the morning?" },
    { type = "say", speaker = "Aki", text = "It wasn't three, it was two-fifteen. And I was working on layout proofs for the club. Our entire budget depends on this special issue." },
    { type = "say", speaker = "Hiko", text = "Uh-huh, sure. 'Layout proofs'. Is that what you call staring at photos of fluffy cats and texting Suzumia-senpai all night?" },
    { type = "monologue", text = "I nearly stumble on the pavement curb. I clear my throat and quickly adjust my bag strap." },
    { type = "say", speaker = "Aki", text = "Suzumia is the Vice President. We were strictly coordinating editorial deadlines." },
    { type = "say", speaker = "Hiko", text = "Right, right. Keep telling yourself that, big brother! But hey... remember what I mentioned in my email last night about the 3rd floor server room?" },
    { type = "say", speaker = "Aki", text = "Yeah. You said your classmate's brother in the IT club was talking about it." },
    { type = "say", speaker = "Hiko", text = "He told him that the school administration unplugged that rack five years ago when they upgraded to fiber optics in the main office. That room is supposed to be completely dead." },
    { type = "monologue", text = "My heart gives a subtle twitch. If the room has been dead for five years... where was that live XOR packet stream coming from last night?" },
    { type = "say", speaker = "Hiko", text = "So if you hear weird hums or see lights behind that steel fire-door, don't go playing detective alone, okay? Mom would kill me if you got expelled." },
    { type = "say", speaker = "Aki", text = "Don't worry, Hiko. I'm just the layout editor." },

    -- ACT VII: LOCKER RENDEZVOUS
    { type = "bg", name = "hallway_day" },
    { type = "monologue", text = "08:10 AM. We arrive at the first-floor shoe locker hallway. The chatter of arriving students echoes against the tall windows." },
    { type = "monologue", text = "As I switch my outdoor shoes for indoor loafers, a familiar sweet scent of vanilla and lavender catches the autumn breeze." },
    { type = "say", speaker = "Suzumia", text = "Good morning, Aki-kun!" },
    { type = "monologue", text = "Suzumia is standing near the second-year locker bank. Her school blazer is neatly buttoned, and her cheeks have a faint morning glow from the walk." },
    { type = "monologue", text = "She shyly extends two warm aluminum cans of honey milk tea purchased from the courtyard vending machine." },
    { type = "say", speaker = "Suzumia", text = "Here... I bought one for you. I saw your light on late last night when I looked across the neighborhood. Thank you so much for polishing the Meow Latte draft, Aki-kun." },
    { type = "say", speaker = "Aki", text = "Thank you, Suzumia. The tea smells amazing. And your draft was great—Mochi's interview section is going to be the biggest hit in the school." },
    { type = "say", speaker = "Suzumia", text = "Really? (///_///) I was so nervous that President Nagahashi would scrap it for his ghost rumor article! Let's make sure today's printing goes perfectly!" },

    -- ACT VIII: AFTERNOON CLUBROOM & THE COUNCIL THREAT
    { type = "bg", name = "clubroom_day" },
    { type = "monologue", text = "03:45 PM. Afternoon sunlight filters through the high mullioned windows of Clubroom 204. The smell of ink, recycled paper, and warm tea fills the air." },
    { type = "monologue", text = "Suzumia is carefully sorting printed photo glossy sheets of Mochi and Chobi at the table. Hoshida is slouching in his corner chair with a bag of matcha Pocky and his laptop open." },
    { type = "say", speaker = "Nagahashi", text = "EMERGENCY, MY FELLOW JOURNALISTS! CODE RED IN ROOM 204!" },
    { type = "monologue", text = "President Nagahashi kicks the wooden door open with his usual theatrical flair, slamming a stamped memo onto the conference table." },
    { type = "say", speaker = "Nagahashi", text = "The Student Council Auditing Committee has moved our review forward! Committee Head Saeki will be standing in this very room at exactly 17:00 to inspect our final master proof!" },
    { type = "say", speaker = "Suzumia", text = "Five o'clock?! But that's only an hour away! We haven't verified the final duplex layout on Aki-kun's computer yet!" },
    { type = "say", speaker = "Nagahashi", text = "Which is why our fate rests in the hands of our master layout technician! Aki, boot up your workstation immediately!" },
    { type = "monologue", text = "As Nagahashi begins dramatically pacing around the blackboard, Hoshida quietly leans over and slides a USB drive and a sticky note across the wooden desk toward my keyboard." },
    { type = "say", speaker = "Hoshida", text = "[Whispering] Aki... check your inbox. I sent you the traceroute log from 07:15 AM. The signal isn't on the 3rd floor at all. It's routing straight down into the locked basement power conduit at 192.168.1.254." },
    { type = "say", speaker = "Aki", text = "[Whispering] The basement? Under the gymnasium?" },
    { type = "say", speaker = "Hoshida", text = "[Whispering] Yeah. And whoever set it up is using a commercial MAC router. Open your PC, check the traceroute dump in Downloads, and compile the final master proof in your Documents folder before Saeki arrives." },

    -- CHAPTER 2 TASK: DESKTOP WORKSTATION INVESTIGATION
    {
        type = "task",
        task = {
            id = "task_chapter2_master_proof",
            title = "Compile Final Master Proof & Inspect Basement Traceroute",
            desc = "1. Read Hoshida's confidential email (#106) in Email app.\n2. Verify the basement sub-station IP (192.168.1.254) in 'traceroute_dump.txt'.\n3. Confirm final_dual_issue_master.txt in Documents/newspaper/.",
            hint = "Open Email, read email #106 from Hoshida, download/view 'traceroute_dump.txt' in Downloads.",
            xp = 400,
            condition = TaskConditions.all(
                TaskConditions.emailRead("Hoshida"),
                TaskConditions.fileContentContains("home/user/Downloads/traceroute_dump.txt", "192.168.1.254")
            ),
            onComplete = function(task)
                local PlayerStats = require("src.core.player_stats")
                PlayerStats.setFlag("chapter2_proof_verified", true)
            end
        }
    },

    { type = "switch_mode", mode = "desktop", transition = "crt_zoom" },

    -- RETURN TO STORY: ACT IX - THE STUDENT COUNCIL AUDIT
    { type = "bg", name = "clubroom_sunset" },
    { type = "monologue", text = "16:58 PM. The clubroom is bathed in deep golden amber. The mimeograph drum cools down on the back shelf, leaving the crisp scent of fresh ink hanging in the quiet room." },
    { type = "monologue", text = "A sharp, measured knock sounds against the door. A girl with silver-framed spectacles and the Student Council Auditing armband steps into Room 204." },
    { type = "say", speaker = "Student Council", text = "Good afternoon, Newspaper Club. I am Saeki from the Council Auditing Committee. I trust your Special Edition proofs are ready for budget evaluation?" },
    { type = "say", speaker = "Nagahashi", text = "Welcome, Auditor Saeki! Feast your eyes upon Issue #42—the pinnacle of Kamiyama journalism!" },
    { type = "monologue", text = "Suzumia steps forward with graceful composure, presenting the freshly printed front-cover proof across the table." },
    { type = "say", speaker = "Suzumia", text = "Saeki-san, our main front-page feature is an exclusive community spotlight on the Meow Latte Cat Cafe by Kamiyama Station. We have negotiated a 10% student discount for all Kamiyama High pupils." },
    { type = "monologue", text = "Auditor Saeki pauses, adjusting her glasses as she examines the crisp, beautifully balanced layout of Mochi the cat and the dessert pricing." },
    { type = "say", speaker = "Student Council", text = "A student discount partnership with a local business...? That is... surprisingly practical. Readership will easily double if pupils can redeem coupons from the paper." },
    { type = "say", speaker = "Nagahashi", text = "And on the reverse side—the Mystery Report! A rigorous, technically substantiated investigation into the 3rd floor repeater anomalies, backed by network cipher forensics!" },
    { type = "monologue", text = "Saeki reviews the back cover, her eyes widening slightly at the professional formatting and technical rigor provided by Hoshida and Aki." },
    { type = "say", speaker = "Student Council", text = "The dual-cover balance is exceptional. Clean typography, verified facts, and high student appeal. The Auditing Committee hereby APPROVES your full printing quota with a 25% supplementary grant." },
    { type = "say", speaker = "Suzumia", text = "We did it! Thank you so much, Saeki-san!" },
    { type = "say", speaker = "Nagahashi", text = "GLORY UNTO THE PRESS! THE TRUTH SHALL NEVER BE SILENCED!" },

    -- ACT X: CELEBRATION AT MEOW LATTE & THE CLIFFHANGER
    { type = "bg", name = "cat_cafe" },
    { type = "music", track = "cat_cafe_theme" },
    { type = "monologue", text = "18:30 PM. Warm jazz melody drifts through the wooden interior of Meow Latte Cat Cafe." },
    { type = "monologue", text = "Suzumia and I sit side-by-side at a sunlit corner table. A tall strawberry parfait with a cat-paw marshmallow rests between us, accompanied by two steaming cups of caramel latte." },
    { type = "monologue", text = "Mochi, the white Scottish Fold, is purring contentedly curled up right on Suzumia's lap, his tail lazily flicking against her skirt." },
    { type = "say", speaker = "Suzumia", text = "Aki-kun... look at him. Mochi remembered me! He came straight to our table as soon as we sat down!" },
    { type = "say", speaker = "Aki", text = "I think he likes the sound of your voice, Suzumia. You were amazing in front of Saeki today." },
    { type = "monologue", text = "Suzumia looks at me, her eyes shimmering with genuine warmth and happiness." },
    { type = "say", speaker = "Suzumia", text = "I couldn't have done any of it without you, Aki-kun. When Nagahashi-senpai was shouting and the council threatened our budget, you stayed calm and brought everything together. I'm really glad we're in this club together." },
    { type = "monologue", text = "For a brief, quiet moment, the entire world feels gentle and warm. I smile back at her, feeling my heart beat a little faster." },
    { type = "monologue", text = "Suddenly, my phone vibrates sharply against the wooden table." },
    { type = "say", speaker = "Aki", text = "Hm? A message from Hoshida...?" },
    { type = "say", speaker = "Hoshida (Anon)", text = "[SECURE_PING] Aki. Look under the cafe table right now. Check the sticker on the back of the Meow Latte Wi-Fi router." },
    { type = "monologue", text = "I reach under the wooden table edge, glancing at the small black router mounted against the cafe baseboard." },
    { type = "monologue", text = "My breath catches in my throat. Printed on the manufacturer barcode is the exact same MAC address from Hoshida's morning traceroute: [ 00:1A:C2:7B:99:4F ]." },
    { type = "say", speaker = "Hoshida (Anon)", text = "The Meow Latte router and the school basement sub-station are the same private physical mesh node. The person running the ghost server in our school... is right here in this cafe." },
    { type = "monologue", text = "I look up. Suzumia is gently stroking Mochi's soft ears, smiling innocently in the warm cafe light." },
    { type = "monologue", text = "Beyond the counter glass, the cafe owner quietly closes a locked steel door leading to the back storage basement." },
    { type = "wait", duration = 2.5 },
    { type = "monologue", text = "========================================================" },
    { type = "monologue", text = "        TO BE CONTINUED IN CHAPTER 3: THE GHOST MESH    " },
    { type = "monologue", text = "========================================================" }
}
