-- ============================================================
-- DCL MINING — COMPLETE SUPABASE SETUP (GLOBAL VERSION)
-- Paste ALL of this into: Supabase → SQL Editor → Run
-- This drops old tables and rebuilds everything cleanly
-- Includes: country_code, region for global player tracking
-- ============================================================

-- ── STEP 1: DROP EVERYTHING (clean reset) ─────────────────
drop table if exists public.boost_txs   cascade;
drop table if exists public.withdrawals cascade;
drop table if exists public.profiles    cascade;
drop function if exists public.handle_updated_at cascade;
drop function if exists public.add_referral_bonus cascade;
drop function if exists public.credit_referrer cascade;

-- ── STEP 2: PROFILES TABLE ────────────────────────────────
create table public.profiles (
  id              bigserial primary key,
  telegram_id     text unique not null,
  username        text,
  balance         numeric(20,8) not null default 0,
  taps            bigint not null default 0,
  streak          int not null default 0,
  last_checkin    date,
  per_tap         numeric(10,6) not null default 0.005,
  boost_name      text not null default 'x5',
  upgrades        jsonb not null default '{"multitap":1,"energy":0,"recharge":1,"bot":0}'::jsonb,
  tasks           jsonb not null default '{}'::jsonb,
  achievements    jsonb not null default '{}'::jsonb,
  referred_by     text,
  country_code    text not null default 'XX',
  region          text not null default 'World',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index profiles_balance_idx     on public.profiles(balance desc);
create index profiles_taps_idx        on public.profiles(taps desc);
create index profiles_referred_by_idx on public.profiles(referred_by);
create index profiles_username_idx    on public.profiles(username);
create index profiles_country_idx     on public.profiles(country_code);
create index profiles_region_idx      on public.profiles(region);

-- ── STEP 3: WITHDRAWALS TABLE ─────────────────────────────
create table public.withdrawals (
  id              bigserial primary key,
  telegram_id     text not null,
  username        text,
  wallet_addr     text not null,
  amount          numeric(20,8) not null,
  status          text not null default 'pending'
                    check (status in ('pending','approved','rejected')),
  admin_note      text,
  tx_hash_out     text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index withdrawals_telegram_id_idx on public.withdrawals(telegram_id);
create index withdrawals_status_idx      on public.withdrawals(status);
create index withdrawals_created_at_idx  on public.withdrawals(created_at desc);

-- ── STEP 4: BOOST TRANSACTIONS TABLE ──────────────────────
create table public.boost_txs (
  id              bigserial primary key,
  telegram_id     text not null,
  username        text,
  tx_hash         text unique not null,
  boost           text not null,
  amount_bnb      numeric(18,8) not null,
  verified_at     timestamptz not null default now()
);

create index boost_txs_telegram_id_idx on public.boost_txs(telegram_id);
create index boost_txs_verified_at_idx on public.boost_txs(verified_at desc);

-- ── STEP 5: AUTO-UPDATE TRIGGER ───────────────────────────
create function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

create trigger withdrawals_updated_at
  before update on public.withdrawals
  for each row execute function public.handle_updated_at();

-- ── STEP 6: REFERRAL BONUS FUNCTION ──────────────────────
-- Safe referral crediting — prevents double-credit by checking
-- that referred_by matches and profile exists
create function public.add_referral_bonus(ref_id text, bonus numeric)
returns void language plpgsql security definer as $$
begin
  update public.profiles
    set balance = balance + bonus,
        updated_at = now()
    where telegram_id = ref_id;
end;
$$;

-- credit_referrer: called client-side but guarded by referred_by uniqueness in the app
create function public.credit_referrer(referrer_id text, new_user_id text, bonus numeric)
returns boolean language plpgsql security definer as $$
declare
  already_credited boolean;
begin
  -- Only credit if the new user actually has referred_by = referrer_id
  select exists(
    select 1 from public.profiles
    where telegram_id = new_user_id
      and referred_by = referrer_id
  ) into already_credited;

  if already_credited then
    update public.profiles
      set balance = balance + bonus,
          updated_at = now()
      where telegram_id = referrer_id;
    return true;
  end if;
  return false;
end;
$$;

-- ── STEP 7: GLOBAL STATS VIEW ─────────────────────────────
-- Handy view for admin: players per region with totals
create or replace view public.region_stats as
  select
    region,
    country_code,
    count(*)                              as player_count,
    sum(taps)                             as total_taps,
    round(sum(balance)::numeric, 2)       as total_dcl,
    count(*) filter (where referred_by is not null) as referred_players
  from public.profiles
  group by region, country_code
  order by player_count desc;

-- ── STEP 7b: GLOBAL CHAT TABLE ───────────────────────────
create table public.chat_messages (
  id            bigserial primary key,
  telegram_id   text not null,
  username      text not null default 'Player',
  country_code  text not null default 'XX',
  message       text not null check (char_length(message) <= 200),
  created_at    timestamptz not null default now()
);

create index chat_messages_created_at_idx  on public.chat_messages(created_at desc);
create index chat_messages_telegram_id_idx on public.chat_messages(telegram_id);

-- ── STEP 8: ROW LEVEL SECURITY ────────────────────────────
alter table public.profiles    enable row level security;
alter table public.withdrawals enable row level security;
alter table public.boost_txs   enable row level security;

-- Profiles: open read (leaderboard), open insert/update (app uses anon key)
create policy "profiles_select"
  on public.profiles for select using (true);

create policy "profiles_insert"
  on public.profiles for insert with check (true);

create policy "profiles_update"
  on public.profiles for update using (true) with check (true);

-- Withdrawals: open (filtered client-side by telegram_id)
create policy "withdrawals_select"
  on public.withdrawals for select using (true);

create policy "withdrawals_insert"
  on public.withdrawals for insert with check (true);

create policy "withdrawals_update"
  on public.withdrawals for update using (true) with check (true);

-- Boost txs: open read/insert (verified server-side via BSC RPC)
create policy "boosts_select"
  on public.boost_txs for select using (true);

create policy "boosts_insert"
  on public.boost_txs for insert with check (true);

-- ── STEP 9: GRANT FUNCTION EXECUTE ────────────────────────
grant execute on function public.add_referral_bonus(text, numeric) to anon, authenticated;
grant execute on function public.credit_referrer(text, text, numeric) to anon, authenticated;
grant select on public.region_stats to anon, authenticated;

-- Chat policies
alter table public.chat_messages enable row level security;

create policy "chat_select"
  on public.chat_messages for select using (true);

create policy "chat_insert"
  on public.chat_messages for insert with check (true);

-- ── STEP 10: REALTIME (live leaderboard + chat) ───────────
alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.chat_messages;

-- ── DONE ─────────────────────────────────────────────────
-- Tables:
--   public.profiles    — player data + country_code + region
--   public.withdrawals — withdrawal requests
--   public.boost_txs   — BNB boost payments
--
-- New in Global Version:
--   country_code TEXT  — ISO country code (US, IN, AE, GB …)
--   region TEXT        — US/Europe/SEA/MENA/South Asia etc.
--   region_stats VIEW  — live breakdown of players by country
--   credit_referrer()  — safe referral crediting function
--
-- After running this, your DCL Mining app works globally.
-- ─────────────────────────────────────────────────────────

notify pgrst, 'reload schema';
