-- Kognitívne testy (benchmark), časť A: nové stĺpce, tabuľka pokusov a funkcie.
-- Bezpečné spustiť kedykoľvek: existujúci web tieto zmeny ignoruje.

alter table public.sports add column if not exists kind text not null default 'sport';
alter table public.sports add column if not exists hb_test text;
alter table public.sports add column if not exists active boolean not null default true;
alter table public.sports add column if not exists hb_min numeric;
alter table public.sports add column if not exists hb_max numeric;
do $$ begin
  alter table public.sports add constraint sports_kind_check check (kind in ('sport','cognitive'));
exception when duplicate_object then null; end $$;

create table if not exists public.hb_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  sport_id text not null references public.sports(id) on delete cascade,
  score numeric not null,
  detail text,
  device text not null check (device in ('mouse','touch')),
  lang text check (lang in ('sk','cz')),
  flags text[] not null default '{}',
  status text not null default 'ok' check (status in ('ok','flagged')),
  created_at timestamptz not null default now()
);
create index if not exists hb_runs_sport_idx on public.hb_runs (sport_id, status, device);
create index if not exists hb_runs_user_idx on public.hb_runs (user_id, created_at desc);
alter table public.hb_runs enable row level security;
drop policy if exists hb_runs_select on public.hb_runs;
create policy hb_runs_select on public.hb_runs for select to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());
-- Žiadne insert/update/delete politiky: pokusy sa zapisujú iba cez hb_submit.

-- Uloženie pokusu: kontrola prihlásenia, súhlasu, disciplíny, rozsahu skóre a frekvencie.
create or replace function public.hb_submit(p_sport text, p_score numeric, p_device text, p_lang text, p_flags text[], p_detail text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  s public.sports%rowtype;
  prof public.profiles%rowtype;
  fl text[];
  st text;
  recent int;
  best numeric;
  is_best boolean := false;
begin
  if uid is null then raise exception 'not_authenticated'; end if;
  select * into prof from public.profiles where id = uid;
  if prof.id is null or prof.consent_at is null then raise exception 'no_profile'; end if;
  select * into s from public.sports where id = p_sport and kind = 'cognitive' and active;
  if s.id is null then raise exception 'unknown_test'; end if;
  if p_device is null or p_device not in ('mouse','touch') then raise exception 'bad_device'; end if;
  if p_score is null or p_score < 0
     or (s.hb_min is not null and p_score < s.hb_min)
     or (s.hb_max is not null and p_score > s.hb_max) then
    raise exception 'implausible_score';
  end if;
  select count(*) into recent from public.hb_runs where user_id = uid and created_at > now() - interval '1 minute';
  if recent >= 20 then raise exception 'rate_limited'; end if;
  select coalesce(array_agg(f), '{}') into fl from unnest(coalesce(p_flags, '{}')) f
    where f in ('bot','blur','fast','robot','paste','teleport');
  st := case when cardinality(fl) > 0 then 'flagged' else 'ok' end;
  insert into public.hb_runs (user_id, sport_id, score, detail, device, lang, flags, status)
    values (uid, p_sport, p_score, left(p_detail, 200), p_device,
            case when p_lang in ('sk','cz') then p_lang end, fl, st);
  if st = 'ok' and p_score > 0 then
    select case when s.lower_is_better then min(value) else max(value) end into best
      from public.records where user_id = uid and sport_id = p_sport;
    if best is null or (s.lower_is_better and p_score < best) or (not s.lower_is_better and p_score > best) then
      insert into public.records (user_id, sport_id, value, record_date, country)
        values (uid, p_sport, p_score, current_date, prof.country);
      is_best := true;
    end if;
  end if;
  return jsonb_build_object('status', st, 'flags', fl, 'personal_best', is_best, 'previous_best', best);
end $$;
revoke all on function public.hb_submit(text, numeric, text, text, text[], text) from public, anon;
grant execute on function public.hb_submit(text, numeric, text, text, text[], text) to authenticated;

-- Štatistiky: najlepší výsledok každého hráča (iba neoznačené pokusy), medián, percentil a vekové skupiny.
-- Vekové skupiny s menej ako 5 hráčmi sa nevracajú, aby sa nedali odhaliť výsledky jednotlivcov.
create or replace function public.hb_stats(p_sport text, p_device text default null)
returns jsonb language sql stable security definer set search_path = public as $$
  with s as (select lower_is_better lib from public.sports where id = p_sport and kind = 'cognitive'),
  b as (
    select r.user_id, case when (select lib from s) then min(r.score) else max(r.score) end best
    from public.hb_runs r
    where r.sport_id = p_sport and r.status = 'ok' and (p_device is null or r.device = p_device)
    group by r.user_id),
  g as (
    select b.best, case
      when p.birth_year is null then null
      when extract(year from now())::int - p.birth_year < 18 then 'do 17'
      when extract(year from now())::int - p.birth_year < 25 then '18–24'
      when extract(year from now())::int - p.birth_year < 35 then '25–34'
      when extract(year from now())::int - p.birth_year < 45 then '35–44'
      when extract(year from now())::int - p.birth_year < 55 then '45–54'
      when extract(year from now())::int - p.birth_year < 65 then '55–64'
      else '65+' end grp
    from b left join public.profiles p on p.id = b.user_id),
  me as (select best from b where user_id = auth.uid()),
  n as (select count(*) c from b)
  select jsonb_build_object(
    'n', (select c from n),
    'median', case when (select c from n) >= 5 then (select percentile_cont(0.5) within group (order by best) from b) end,
    'my_best', (select best from me),
    'worse', (select count(*) from b, me where case when (select lib from s) then b.best > me.best else b.best < me.best end),
    'equal', (select count(*) from b, me where b.best = me.best and b.user_id <> auth.uid()),
    'groups', (select coalesce(jsonb_agg(jsonb_build_object('g', grp, 'n', c, 'median', med) order by grp), '[]'::jsonb)
               from (select grp, count(*) c, percentile_cont(0.5) within group (order by best) med
                     from g where grp is not null group by grp having count(*) >= 5) x)
  ) where exists (select 1 from s);
$$;
grant execute on function public.hb_stats(text, text) to anon, authenticated;

-- Admin: skryť / zobraziť disciplínu bez mazania výsledkov.
create or replace function public.admin_set_sport_active(p_id text, p_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_superadmin() then raise exception 'forbidden'; end if;
  update public.sports set active = p_active where id = p_id;
end $$;
revoke all on function public.admin_set_sport_active(text, boolean) from public, anon;
grant execute on function public.admin_set_sport_active(text, boolean) to authenticated;
