-- Krajina merania pri testoch podľa časového pásma telefónu (posiela prehliadač ako p_place).
-- Ak nepríde, použije sa krajina z profilu ako doteraz. Rebríčky sa riadia krajinou z profilu.
drop function if exists public.hb_submit(text, numeric, text, text, text[], text);
create or replace function public.hb_submit(p_sport text, p_score numeric, p_device text, p_lang text, p_flags text[], p_detail text, p_place text default null)
returns jsonb language plpgsql security definer set search_path = public as $function$
declare
  uid uuid := auth.uid();
  s public.sports%rowtype;
  prof public.profiles%rowtype;
  fl text[];
  st text;
  recent int;
  best numeric;
  is_best boolean := false;
  place text := nullif(left(btrim(coalesce(p_place, '')), 60), '');
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
        values (uid, p_sport, p_score, current_date, coalesce(place, prof.country));
      is_best := true;
    end if;
  end if;
  return jsonb_build_object('status', st, 'flags', fl, 'personal_best', is_best, 'previous_best', best);
end $function$;
revoke all on function public.hb_submit(text, numeric, text, text, text[], text, text) from public;
grant execute on function public.hb_submit(text, numeric, text, text, text[], text, text) to authenticated;
