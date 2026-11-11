-- Wichtel-Losung: Datenbank für Supabase
-- Einmal im Supabase-Dashboard unter "SQL Editor" komplett ausführen.
--
-- Sicherheitsprinzip:
--   * Namen, Zuordnungen und Wünsche werden im Browser verschlüsselt (AES-GCM).
--     Der Schlüssel steht nur im Link hinter dem "#" und erreicht den Server nie.
--     Die Datenbank enthält also nur unlesbaren Datensalat.
--   * Die Tabellen sind für Browser komplett gesperrt (RLS ohne Policies).
--     Zugriff gibt es nur über die Funktionen unten.
--   * Die eigene Zuordnung bekommt nur, wer die PIN des Platzes kennt.
--     Nach 10 falschen PINs ist der Platz gesperrt, bis die Organisation ihn freigibt.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.wichtel_rounds (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  admin_hash  text not null,
  meta        text not null                -- verschlüsselt: Name der Runde, Budget, Datum, Hinweis, Namen
);

create table if not exists public.wichtel_slots (
  round_id    uuid not null references public.wichtel_rounds(id) on delete cascade,
  idx         int  not null,
  payload     text not null,               -- verschlüsselt: wen diese Person beschenkt + Wunsch-Schlüssel
  pin_hash    text,
  claimed_at  timestamptz,
  failed      int  not null default 0,
  wish        text,                        -- verschlüsselt, nur für den eigenen Wichtel lesbar
  wish_at     timestamptz,
  primary key (round_id, idx)
);

alter table public.wichtel_rounds enable row level security;
alter table public.wichtel_slots  enable row level security;
revoke all on public.wichtel_rounds, public.wichtel_slots from anon, authenticated;

-- Neue Runde anlegen ---------------------------------------------------------
create or replace function public.wichtel_create(p_meta text, p_admin text, p_payloads text[])
returns uuid
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_id uuid;
  n int := coalesce(array_length(p_payloads, 1), 0);
begin
  if n < 3 or n > 60 then raise exception 'Zwischen 3 und 60 Personen erlaubt'; end if;
  if length(p_meta) > 20000 or length(p_admin) < 16 then raise exception 'Ungültige Daten'; end if;
  if exists (select 1 from unnest(p_payloads) p where length(p) > 4000) then raise exception 'Ungültige Daten'; end if;
  insert into wichtel_rounds (admin_hash, meta)
    values (encode(digest(p_admin, 'sha256'), 'hex'), p_meta)
    returning id into v_id;
  insert into wichtel_slots (round_id, idx, payload)
    select v_id, i - 1, p_payloads[i] from generate_series(1, n) i;
  return v_id;
end $$;

-- Runde lesen (nur verschlüsselte Daten + Status) ---------------------------
create or replace function public.wichtel_get(p_round uuid)
returns json
language sql security definer set search_path = public, extensions stable
as $$
  select json_build_object(
    'meta', r.meta,
    'slots', (select json_agg(json_build_object(
                'idx', s.idx,
                'claimed', s.pin_hash is not null,
                'locked', s.failed >= 10,
                'wish', s.wish,
                'wish_at', s.wish_at) order by s.idx)
              from wichtel_slots s where s.round_id = r.id))
  from wichtel_rounds r where r.id = p_round;
$$;

-- Platz mit PIN beanspruchen bzw. sich wieder anmelden ----------------------
create or replace function public.wichtel_claim(p_round uuid, p_idx int, p_pin text)
returns json
language plpgsql security definer set search_path = public, extensions
as $$
declare s wichtel_slots;
begin
  select * into s from wichtel_slots where round_id = p_round and idx = p_idx for update;
  if not found then return json_build_object('ok', false, 'error', 'not_found'); end if;
  if s.failed >= 10 then return json_build_object('ok', false, 'error', 'locked'); end if;
  if s.pin_hash is null then
    if length(coalesce(p_pin, '')) < 4 then return json_build_object('ok', false, 'error', 'pin_short'); end if;
    update wichtel_slots set pin_hash = crypt(p_pin, gen_salt('bf')), claimed_at = now()
      where round_id = p_round and idx = p_idx;
    return json_build_object('ok', true, 'payload', s.payload, 'new', true);
  elsif s.pin_hash = crypt(coalesce(p_pin, ''), s.pin_hash) then
    update wichtel_slots set failed = 0 where round_id = p_round and idx = p_idx;
    return json_build_object('ok', true, 'payload', s.payload, 'new', false);
  else
    update wichtel_slots set failed = failed + 1 where round_id = p_round and idx = p_idx;
    return json_build_object('ok', false, 'error', 'wrong_pin', 'left', greatest(0, 9 - s.failed));
  end if;
end $$;

-- Eigenen (verschlüsselten) Wunsch speichern --------------------------------
create or replace function public.wichtel_set_wish(p_round uuid, p_idx int, p_pin text, p_wish text)
returns json
language plpgsql security definer set search_path = public, extensions
as $$
declare s wichtel_slots;
begin
  if length(coalesce(p_wish, '')) > 8000 then return json_build_object('ok', false, 'error', 'too_long'); end if;
  select * into s from wichtel_slots where round_id = p_round and idx = p_idx for update;
  if not found then return json_build_object('ok', false, 'error', 'not_found'); end if;
  if s.failed >= 10 then return json_build_object('ok', false, 'error', 'locked'); end if;
  if s.pin_hash is null or s.pin_hash <> crypt(coalesce(p_pin, ''), s.pin_hash) then
    update wichtel_slots set failed = failed + 1 where round_id = p_round and idx = p_idx;
    return json_build_object('ok', false, 'error', 'wrong_pin');
  end if;
  update wichtel_slots set wish = nullif(p_wish, ''), wish_at = now(), failed = 0
    where round_id = p_round and idx = p_idx;
  return json_build_object('ok', true);
end $$;

-- Organisation: Platz freigeben (PIN, Sperre und Wunsch zurücksetzen) -------
create or replace function public.wichtel_admin_reset(p_round uuid, p_admin text, p_idx int)
returns json
language plpgsql security definer set search_path = public, extensions
as $$
begin
  if not exists (select 1 from wichtel_rounds
                 where id = p_round and admin_hash = encode(digest(p_admin, 'sha256'), 'hex')) then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;
  update wichtel_slots set pin_hash = null, claimed_at = null, failed = 0, wish = null, wish_at = null
    where round_id = p_round and idx = p_idx;
  return json_build_object('ok', true);
end $$;

-- Organisation: Runde komplett löschen --------------------------------------
create or replace function public.wichtel_admin_delete(p_round uuid, p_admin text)
returns json
language plpgsql security definer set search_path = public, extensions
as $$
begin
  delete from wichtel_rounds where id = p_round and admin_hash = encode(digest(p_admin, 'sha256'), 'hex');
  return json_build_object('ok', found);
end $$;

revoke execute on function public.wichtel_create(text, text, text[]),
                          public.wichtel_get(uuid),
                          public.wichtel_claim(uuid, int, text),
                          public.wichtel_set_wish(uuid, int, text, text),
                          public.wichtel_admin_reset(uuid, text, int),
                          public.wichtel_admin_delete(uuid, text) from public;
grant execute on function public.wichtel_create(text, text, text[]),
                         public.wichtel_get(uuid),
                         public.wichtel_claim(uuid, int, text),
                         public.wichtel_set_wish(uuid, int, text, text),
                         public.wichtel_admin_reset(uuid, text, int),
                         public.wichtel_admin_delete(uuid, text) to anon, authenticated;
