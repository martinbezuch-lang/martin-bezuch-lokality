-- „Naposledy online“ v profile: čas poslednej aktivity prihláseného používateľa (zapisuje sa najviac raz za 5 minút)
alter table public.profiles add column if not exists last_seen_at timestamptz;

create or replace view public.public_profiles as
 SELECT id, display_name, country, gender, is_celebrity, created_at,
    CASE WHEN show_body_data THEN birth_year ELSE NULL::integer END AS birth_year,
    CASE WHEN show_body_data THEN weight_kg ELSE NULL::numeric END AS weight_kg,
    CASE WHEN show_body_data THEN height_cm ELSE NULL::numeric END AS height_cm,
    is_trusted, celebrity_type, social_youtube, social_instagram, social_facebook, social_tiktok,
    last_seen_at
   FROM profiles
  WHERE consent_at IS NOT NULL;

create or replace function public.touch_last_seen()
returns void language sql security definer set search_path = public as $$
  update public.profiles set last_seen_at = now()
  where id = auth.uid() and (last_seen_at is null or last_seen_at < now() - interval '5 minutes');
$$;
revoke all on function public.touch_last_seen() from public;
grant execute on function public.touch_last_seen() to authenticated;
