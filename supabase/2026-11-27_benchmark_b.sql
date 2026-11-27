-- Kognitívne testy (benchmark), časť B: disciplíny a ochrana pred ručným zadávaním.
-- Spustiť až po zlúčení pull requestu (nové disciplíny sa hneď objavia na webe).

insert into public.sports (id, name, unit, lower_is_better, accent, sort_order, kind, hb_test, active, hb_min, hb_max) values
 ('hb_reakcia',  'Reakčný čas',            'ms',          true,  '#2563eb', 20, 'cognitive', 'reakcia',   true, 100, 1500),
 ('hb_mierenie', 'Mierenie',               'ms / terč',   true,  '#0891b2', 21, 'cognitive', 'mierenie',  true, 150, 3000),
 ('hb_slova',    'Slovná pamäť',           'slov',        false, '#7c3aed', 24, 'cognitive', 'slova',     true, 0, 500),
 ('hb_simpanz',  'Šimpanzí test',          'čísel',       false, '#ca8a04', 25, 'cognitive', 'simpanz',   true, 0, 40),
 ('hb_vizualna', 'Vizuálna pamäť',         'úroveň',      false, '#0d9488', 26, 'cognitive', 'vizualna',  true, 0, 60),
 ('hb_pisanie',  'Písanie na klávesnici',  'WPM',         false, '#4f46e5', 27, 'cognitive', 'pisanie',   true, 0, 250),
 ('hb_stroop',   'Stroopov test',          'bodov',       false, '#dc2626', 28, 'cognitive', 'stroop',    true, 0, 120),
 ('hb_klikanie', 'Rýchlosť klikania',      'klikov/s',    false, '#ea580c', 29, 'cognitive', 'klikanie',  true, 0, 20),
 ('hb_pocty',    'Rýchle počty',           'príkladov',   false, '#16a34a', 30, 'cognitive', 'pocty',     true, 0, 150),
 ('hb_cas',      'Odhad času',             'ms odchýlka', true,  '#9333ea', 31, 'cognitive', 'cas',       true, 0, 10000),
 ('hb_farby',    'Postreh na farby',       'úroveň',      false, '#db2777', 32, 'cognitive', 'farby',     true, 0, 60),
 ('hb_bodky',    'Počítanie bodiek',       'správne',     false, '#0284c7', 33, 'cognitive', 'bodky',     true, 0, 100),
 ('hb_skcz',     'Slovenské či české?',    'bodov',       false, '#1d4ed8', 34, 'cognitive', 'skcz',      true, 0, 100),
 ('hb_vybrane',  'Vybrané slová',          'bodov',       false, '#b91c1c', 35, 'cognitive', 'vybrane',   true, 0, 100),
 ('hb_schulte',  'Schulteho tabuľka',      's',           true,  '#0f766e', 36, 'cognitive', 'schulte',   true, 3, 600),
 ('hb_gonogo',   'Zelená / červená',       'ms',          true,  '#15803d', 37, 'cognitive', 'gonogo',    true, 120, 5000),
 ('hb_nback',    'Pracovná pamäť (2-back)','%',           false, '#6d28d9', 38, 'cognitive', 'nback',     true, 0, 100),
 ('hb_lopticky', 'Sledovanie loptičiek',   'úroveň',      false, '#c2410c', 39, 'cognitive', 'lopticky',  true, 0, 40),
 ('hb_anagramy', 'Anagramy',               'slov',        false, '#be185d', 40, 'cognitive', 'anagramy',  true, 0, 100),
 ('hb_rotacia',  'Otáčanie tvarov',        'bodov',       false, '#0369a1', 41, 'cognitive', 'rotacia',   true, 0, 150),
 ('hb_ciara',    'Zastav na čiare',        '% odchýlka',  true,  '#a16207', 42, 'cognitive', 'ciara',     true, 0, 100),
 ('hb_uhol',     'Odhad uhla',             '° odchýlka',  true,  '#4338ca', 43, 'cognitive', 'uhol',      true, 0, 180),
 ('hb_pismeno',  'Nájdi písmeno',          's',           true,  '#047857', 44, 'cognitive', 'pismeno',   true, 5, 600)
on conflict (id) do nothing;

-- Existujúce HB disciplíny sa stanú hrateľnými testami (ich doterajšie výsledky zostávajú).
update public.sports set kind = 'cognitive', hb_test = 'cisla', name = 'Číselná pamäť', unit = 'číslic', hb_min = 0, hb_max = 40 where id = 'hb_number';
update public.sports set kind = 'cognitive', hb_test = 'sekvencia', name = 'Sekvenčná pamäť', unit = 'úroveň', hb_min = 0, hb_max = 60 where id = 'hb_sequence';

-- Výsledky kognitívnych testov sa nedajú zadať ani upraviť ručne, iba cez hb_submit.
drop policy if exists records_insert on public.records;
create policy records_insert on public.records for insert to authenticated with check (
  user_id = (select auth.uid())
  and record_date <= current_date + 1
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.consent_at is not null)
  and not exists (select 1 from public.sports sp where sp.id = sport_id and sp.kind = 'cognitive'));
drop policy if exists records_update on public.records;
create policy records_update on public.records for update to authenticated
  using (user_id = (select auth.uid()) and not exists (select 1 from public.sports sp where sp.id = sport_id and sp.kind = 'cognitive'))
  with check (user_id = (select auth.uid()) and record_date <= current_date + 1
              and not exists (select 1 from public.sports sp where sp.id = sport_id and sp.kind = 'cognitive'));
