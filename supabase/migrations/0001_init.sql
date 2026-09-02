-- Mes Étoiles — schéma initial
-- À exécuter dans le SQL editor de votre projet Supabase (ou via `supabase db push`).

create extension if not exists "pgcrypto";

-- =========================================================================
-- TABLES
-- =========================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  family_name text not null default 'Ma famille',
  parent_pin text,
  created_at timestamptz not null default now()
);

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  first_name text not null,
  avatar text not null default 'lion',
  theme text not null default 'mint',
  available_stars int not null default 0,
  created_at timestamptz not null default now(),
  constraint available_stars_not_negative check (available_stars >= 0)
);

create table if not exists public.star_events (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  value int not null,
  category text not null check (category in ('positive', 'negative', 'exceptional', 'reward_redeemed')),
  reason text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  emoji text not null default '🎁',
  stars_required int not null check (stars_required > 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.redeemed_rewards (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  reward_id uuid references public.rewards (id) on delete set null,
  stars_spent int not null,
  created_at timestamptz not null default now()
);

create index if not exists children_profile_id_idx on public.children (profile_id);
create index if not exists star_events_child_id_idx on public.star_events (child_id, created_at);
create index if not exists rewards_profile_id_idx on public.rewards (profile_id);
create index if not exists redeemed_rewards_child_id_idx on public.redeemed_rewards (child_id);

-- =========================================================================
-- LOGIQUE MÉTIER : le compteur d'étoiles disponibles ne descend jamais
-- sous zéro, et se recalcule en rejouant l'historique dans l'ordre
-- chronologique (chaque événement est appliqué avec un clamp à 0).
-- =========================================================================

create or replace function public.recalc_child_available_stars(p_child_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  running int := 0;
  ev record;
begin
  for ev in
    select value from public.star_events
    where child_id = p_child_id
    order by created_at asc, id asc
  loop
    running := greatest(0, running + ev.value);
  end loop;

  update public.children set available_stars = running where id = p_child_id;
end;
$$;

create or replace function public.trg_star_events_recalc()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'DELETE' then
    perform public.recalc_child_available_stars(OLD.child_id);
    return OLD;
  else
    perform public.recalc_child_available_stars(NEW.child_id);
    if TG_OP = 'UPDATE' and OLD.child_id is distinct from NEW.child_id then
      perform public.recalc_child_available_stars(OLD.child_id);
    end if;
    return NEW;
  end if;
end;
$$;

drop trigger if exists star_events_after_change on public.star_events;
create trigger star_events_after_change
after insert or update or delete on public.star_events
for each row execute function public.trg_star_events_recalc();

-- Attribution d'une note en une seule transaction (utilisé pour -1 / +1 / +2).
-- Renvoie à la fois l'événement créé (pour permettre l'annulation rapide)
-- et l'enfant à jour (nouveau solde d'étoiles).
create or replace function public.add_star_event(
  p_child_id uuid,
  p_value int,
  p_category text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_child public.children;
  v_event public.star_events;
begin
  select profile_id into v_profile_id from public.children where id = p_child_id;

  if v_profile_id is null or v_profile_id <> auth.uid() then
    raise exception 'not_authorized';
  end if;

  if p_value not in (-1, 1, 2) then
    raise exception 'invalid_value';
  end if;

  insert into public.star_events (child_id, value, category, reason)
  values (p_child_id, p_value, p_category, p_reason)
  returning * into v_event;

  select * into v_child from public.children where id = p_child_id;

  return jsonb_build_object(
    'child', to_jsonb(v_child),
    'event', to_jsonb(v_event)
  );
end;
$$;

-- Utilisation d'une récompense : vérifie le solde, déduit les étoiles et
-- journalise l'opération, le tout de façon atomique.
create or replace function public.redeem_reward(p_child_id uuid, p_reward_id uuid)
returns public.children
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_reward public.rewards;
  v_child public.children;
begin
  select profile_id into v_profile_id from public.children where id = p_child_id;
  if v_profile_id is null or v_profile_id <> auth.uid() then
    raise exception 'not_authorized';
  end if;

  select * into v_reward from public.rewards
    where id = p_reward_id and profile_id = v_profile_id and active = true;
  if v_reward is null then
    raise exception 'reward_not_found';
  end if;

  select * into v_child from public.children where id = p_child_id;
  if v_child.available_stars < v_reward.stars_required then
    raise exception 'insufficient_stars';
  end if;

  insert into public.star_events (child_id, value, category, reason)
  values (p_child_id, -v_reward.stars_required, 'reward_redeemed', v_reward.title);

  insert into public.redeemed_rewards (child_id, reward_id, stars_spent)
  values (p_child_id, p_reward_id, v_reward.stars_required);

  select * into v_child from public.children where id = p_child_id;
  return v_child;
end;
$$;

-- =========================================================================
-- RLS : chaque famille ne voit que ses propres données.
-- =========================================================================

alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.star_events enable row level security;
alter table public.rewards enable row level security;
alter table public.redeemed_rewards enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "children_all_own" on public.children;
create policy "children_all_own" on public.children
  for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

drop policy if exists "star_events_all_own" on public.star_events;
create policy "star_events_all_own" on public.star_events
  for all using (
    child_id in (select id from public.children where profile_id = auth.uid())
  ) with check (
    child_id in (select id from public.children where profile_id = auth.uid())
  );

drop policy if exists "rewards_all_own" on public.rewards;
create policy "rewards_all_own" on public.rewards
  for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

drop policy if exists "redeemed_rewards_all_own" on public.redeemed_rewards;
create policy "redeemed_rewards_all_own" on public.redeemed_rewards
  for all using (
    child_id in (select id from public.children where profile_id = auth.uid())
  ) with check (
    child_id in (select id from public.children where profile_id = auth.uid())
  );
