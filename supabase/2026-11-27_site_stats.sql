-- Štatistiky návštevnosti a používania pre administráciu.
-- site_events: anonymné udalosti (návšteva stránky raz za deň na návštevníka, dokončený test aj u hostí).
-- Návštevník = náhodné ID uložené v prehliadači, žiadne osobné údaje ani IP adresy.

create table if not exists public.site_events (
  id bigserial primary key,
  created_at timestamptz not null default now(),
  day date not null default (now() at time zone 'Europe/Bratislava')::date,
  visitor text not null,
  kind text not null check (kind in ('visit', 'test_done')),
  page text,
  detail text,
  lang text,
  user_id uuid
);
create unique index if not exists site_events_visit_once
  on public.site_events (day, visitor, page) where kind = 'visit';
create index if not exists site_events_day on public.site_events (day);
alter table public.site_events enable row level security;
-- žiadne politiky: zápis len cez hb_log, čítanie len cez admin_stats

create or replace function public.hb_log(p_visitor text, p_kind text, p_page text default null, p_detail text default null, p_lang text default null)
returns void language plpgsql security definer set search_path = public as $$
declare d date := (now() at time zone 'Europe/Bratislava')::date;
begin
  if p_visitor is null or length(p_visitor) < 8 or length(p_visitor) > 64 then return; end if;
  if p_kind not in ('visit', 'test_done') then return; end if;
  -- ochrana pred zahltením: najviac 300 udalostí na návštevníka za deň
  if (select count(*) from site_events where day = d and visitor = p_visitor) >= 300 then return; end if;
  insert into site_events (day, visitor, kind, page, detail, lang, user_id)
  values (d, p_visitor, p_kind, left(p_page, 40), left(p_detail, 40), left(p_lang, 8), auth.uid())
  on conflict do nothing;
end $$;
revoke all on function public.hb_log(text, text, text, text, text) from public;
grant execute on function public.hb_log(text, text, text, text, text) to anon, authenticated;

create or replace function public.admin_stats(p_days int default 30)
returns table (
  day date,
  visitors int,          -- unikátni návštevníci webu (hlavná stránka alebo testy)
  test_visitors int,     -- unikátni návštevníci stránky testov
  test_plays int,        -- dokončené testy (aj hostia)
  test_players int,      -- unikátni ľudia, ktorí dokončili aspoň jeden test
  runs int,              -- uložené pokusy prihlásených hráčov
  new_users int,         -- nové registrácie
  new_records int        -- nové športové výkony
) language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_staff() then raise exception 'not_allowed'; end if;
  return query
  with days as (
    select generate_series((now() at time zone 'Europe/Bratislava')::date - (greatest(1, least(p_days, 366)) - 1),
                           (now() at time zone 'Europe/Bratislava')::date, interval '1 day')::date as d
  )
  select days.d,
    (select count(distinct e.visitor) from site_events e where e.day = days.d and e.kind = 'visit')::int,
    (select count(distinct e.visitor) from site_events e where e.day = days.d and e.kind = 'visit' and e.page = 'tests')::int,
    (select count(*) from site_events e where e.day = days.d and e.kind = 'test_done')::int,
    (select count(distinct e.visitor) from site_events e where e.day = days.d and e.kind = 'test_done')::int,
    (select count(*) from hb_runs r where (r.created_at at time zone 'Europe/Bratislava')::date = days.d)::int,
    (select count(*) from profiles p where (p.created_at at time zone 'Europe/Bratislava')::date = days.d)::int,
    (select count(*) from records rc join sports s on s.id = rc.sport_id and s.kind <> 'cognitive'
       where (rc.created_at at time zone 'Europe/Bratislava')::date = days.d)::int
  from days order by days.d;
end $$;
revoke all on function public.admin_stats(int) from public;
grant execute on function public.admin_stats(int) to authenticated;

-- najhranejšie testy za obdobie (aj hostia)
create or replace function public.admin_top_tests(p_days int default 30)
returns table (test text, plays int, players int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_staff() then raise exception 'not_allowed'; end if;
  return query
  select e.detail, count(*)::int, count(distinct e.visitor)::int
  from site_events e
  where e.kind = 'test_done' and e.day > (now() at time zone 'Europe/Bratislava')::date - greatest(1, least(p_days, 366))
  group by e.detail order by 2 desc;
end $$;
revoke all on function public.admin_top_tests(int) from public;
grant execute on function public.admin_top_tests(int) to authenticated;
