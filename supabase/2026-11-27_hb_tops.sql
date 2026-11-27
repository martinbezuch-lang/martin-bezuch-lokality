-- Rozhodovanie zhôd v rebríčku testov: 5 najlepších platných pokusov každého hráča.
-- Pri rovnakom najlepšom výsledku rozhoduje 2. najlepší pokus, potom 3., 4. a 5.
create or replace function public.hb_tops()
returns table (user_id uuid, sport_id text, tops numeric[])
language sql stable security definer set search_path = public as $$
  select r.user_id, r.sport_id,
         (array_agg(r.score order by case when s.lower_is_better then r.score else -r.score end))[1:5]
  from public.hb_runs r
  join public.sports s on s.id = r.sport_id and s.kind = 'cognitive'
  where r.status = 'ok'
  group by r.user_id, r.sport_id
$$;
revoke all on function public.hb_tops() from public;
grant execute on function public.hb_tops() to anon, authenticated;
