DCL MINING — LEADERBOARD PRIZE SYSTEM
  ========================================

  NEW FEATURES IN THIS VERSION
  ------------------------------

  1. PRIZE TIERS (shown on Leaderboard tab)
     🥇 #1      → 500 DCL + x20 Boost (FREE)
     🥈 #2–#3   → 200 DCL + x10 Boost
     🥉 #4–#10  → 100 DCL + x5 Boost
     #11–#100   → 25 DCL + x2 Boost

  2. #1 CHAMPION SPOTLIGHT
     A golden card at the top of the leaderboard always
     shows who is currently in first place.

  3. YOUR RANK DISPLAY
     The "YOU" card now shows your current rank
     (#1, #7, >50, etc.) next to your name.

  4. PRIZE-ELIGIBLE BADGE
     Players ranked #1–#10 see "🎁 Prize eligible"
     under their tap count in the list.

  5. AUTO TELEGRAM CHANNEL ANNOUNCEMENT
     When the #1 player changes, the bot automatically
     posts a hype message to your Telegram channel.

     HOW TO SET IT UP:
     a) Open app → hold "$" logo 2 sec → pw: dcl@admin2025
     b) Enter your Bot Token (from @BotFather)
     c) Enter your Admin Chat ID (@userinfobot)
     d) Enter your Channel ID → @dcl_official
        (or numeric ID like -1001234567890)
     e) Click Save Bot Config

     IMPORTANT: Your bot must be an ADMIN in @dcl_official
     to post messages. Go to channel → Add Administrator →
     add @dclmining_admin_bot → allow Post Messages.

     Example announcement sent to channel:
     ─────────────────────────────────────────
     👑 NEW #1 CHAMPION! 👑
     🏆 @username has taken the top spot!
     💰 Balance: 1234.567 DCL
     ⛏️ Taps: 98,432
     🎁 #1 Prize: 500 DCL + x20 Boost (FREE)
     👉 https://decentralisedcointelegramlearn.netlify.app
     #DCLMining #Leaderboard #Champion
     ─────────────────────────────────────────

  WHEN DOES IT ANNOUNCE?
    Every time a user opens the Leaderboard tab (or clicks
    Refresh), the app checks if the #1 player has changed
    since the last check. If yes → posts to channel.
    (Stored in localStorage so it won't double-post for
    the same player from the same device.)

  NETLIFY DEPLOY
    1. Run supabase-setup.sql in Supabase SQL Editor (if new)
    2. Extract zip → drag folder to Netlify
    3. Configure bot in admin panel after deploy

  Admin password: dcl@admin2025
  BNB address:    0x6CDA062a90cc9ea61e0Bb099De483610504944C9
  Bot:            @dclmining_admin_bot
  Channel:        @dcl_official
  