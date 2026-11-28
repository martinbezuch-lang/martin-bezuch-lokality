# Generátor SEO stránok /test/<slug>/ a sitemap.xml. Spúšťa sa ručne; texty sú v seo_content.py.
# Potrebuje /tmp/tests.json a /tmp/disc.json (export z benchmark.html a disciplines.js).
import json, os, html, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from seo_content import C

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
tests = json.load(open('/tmp/tests.json'))
disc = json.load(open('/tmp/disc.json'))
order = disc.pop('__order')
byid = {t['id']: t for t in tests}
E = html.escape
BASE = 'https://porovnajsa.sk'
SID = {'sekvencia': 'hb_sequence', 'cisla': 'hb_number'}

CSS = """*{box-sizing:border-box}body{margin:0;background:#0b1422;color:#eef2f8;font:17px/1.6 Inter,system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
a{color:#93c5fd}.wrap{max-width:820px;margin:0 auto;padding:0 20px}
header{border-bottom:1px solid #1e2b44}header .wrap{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:14px 20px}
.logo{display:flex;align-items:center;gap:10px;color:#fff;text-decoration:none;font-weight:800}.logo i{width:36px;height:36px;border-radius:10px;background:#2563eb;display:grid;place-items:center;font-style:normal}
.crumbs{font-size:14px;color:#9aa7ba;margin:22px 0 8px}.crumbs a{color:#9aa7ba}
.hero{display:flex;gap:18px;align-items:center;margin:8px 0 6px}.ic{flex:none;width:72px;height:72px;border-radius:18px;display:grid;place-items:center;color:#fff}
h1{font-size:clamp(28px,6vw,40px);line-height:1.15;margin:0}.cat{display:inline-flex;align-items:center;gap:6px;font-size:14px;font-weight:700;padding:4px 10px;border-radius:999px;margin-top:8px}
.lead{font-size:19px;color:#cbd5e1;margin:18px 0}.cta{display:inline-flex;align-items:center;gap:8px;background:#fff;color:#1d4ed8;font-weight:800;font-size:18px;text-decoration:none;padding:14px 28px;border-radius:999px;margin:6px 0 10px}
.cta:hover{background:#e0e7ff}.note{font-size:14px;color:#9aa7ba}
h2{font-size:22px;margin:34px 0 10px}.card{background:#14203a;border-radius:16px;padding:16px 20px}.card p{margin:0 0 10px}.card p:last-child{margin:0}
.more{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:10px;margin-top:10px}.more a{display:flex;align-items:center;gap:10px;background:#14203a;border-radius:12px;padding:12px 14px;color:#eef2f8;text-decoration:none;font-weight:600}
.more a span{width:30px;height:30px;border-radius:8px;display:grid;place-items:center;flex:none;color:#fff}
.src{font-size:14px;color:#9aa7ba}footer{margin:50px 0 30px;font-size:14px;color:#9aa7ba}"""

def page(title, desc, url, body, ld):
    return f"""<!DOCTYPE html>
<html lang="sk">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{E(title)}</title>
<meta name="description" content="{E(desc)}">
<link rel="canonical" href="{url}">
<meta property="og:type" content="website">
<meta property="og:locale" content="sk_SK">
<meta property="og:title" content="{E(title)}">
<meta property="og:description" content="{E(desc)}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{BASE}/og-image.png">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#0b1422">
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False)}</script>
<style>{CSS}</style>
</head>
<body>
<header><div class="wrap"><a class="logo" href="/"><i>📊</i>Porovnaj sa</a><a href="/benchmark.html">Všetky testy →</a></div></header>
<main class="wrap">
{body}
</main>
<footer class="wrap">© porovnajsa.sk · <a href="/test/">Prehľad testov</a> · <a href="/ochrana-udajov.html">Ochrana údajov</a></footer>
</body>
</html>
"""

os.makedirs(f'{ROOT}/test', exist_ok=True)
urls = []
cats = {}
for t in tests:
    cats.setdefault(disc[t['id']]['cat'], []).append(t['id'])

for t in tests:
    tid = t['id']; slug, seot, h1, what, tip = C[tid]; d = disc[tid]
    name = t['name']['sk']; desc_short = t['desc']['sk']
    url = f'{BASE}/test/{slug}/'
    urls.append(url)
    title = f'{seot} zadarmo | Porovnaj sa'
    mdesc = (h1 + '. ' + what)[:155].rsplit(' ', 1)[0] + '…'
    ref = ''
    if t.get('ref'):
        note = t['ref']['note']['sk'] if isinstance(t['ref']['note'], dict) else t['ref']['note']
        srcs = ' · '.join(f'<a href="{E(u)}" rel="nofollow noopener" target="_blank">{E(n)}</a>' for n, u in t['ref']['src'])
        ref = f'<h2>Čo hovorí výskum</h2><div class="card"><p>{E(note)}</p><p class="src">Zdroje: {srcs}</p></div>'
    others = [o for o in cats[d['cat']] if o != tid]
    more = ''.join(f'<a href="/test/{C[o][0]}/"><span style="background:{disc[o]["color"]}">{disc[o]["icon"].replace("width=\"40\" height=\"40\"", "width=\"18\" height=\"18\"")}</span>{E(byid[o]["name"]["sk"])}</a>' for o in others)
    body = f"""<p class="crumbs"><a href="/">Porovnaj sa</a> › <a href="/test/">Testy</a> › {E(d['catLabel'])}</p>
<div class="hero"><div class="ic" style="background:{d['color']}">{d['icon']}</div><div><h1>{E(seot)}</h1><span class="cat" style="background:{d['color']}26;color:{d['color']}">{d['catIcon']} {E(d['catLabel'])}</span></div></div>
<p class="lead">{E(h1)}. {E(desc_short)}</p>
<a class="cta" href="/benchmark.html#{tid}">▶ Spustiť test: {E(name)}</a>
<p class="note">Zadarmo, bez registrácie, na mobile aj počítači. Po prihlásení uvidíš svoje poradie a percentil medzi ostatnými.</p>
<h2>Čo test meria</h2><div class="card"><p>{E(what)}</p></div>
<h2>Tip na lepší výsledok</h2><div class="card"><p>{E(tip)}</p></div>
{ref}
<h2>Porovnaj sa s ostatnými</h2><div class="card"><p>Výsledky prihlásených hráčov sa ukladajú do rebríčka na porovnajsa.sk. Uvidíš, koľkých ľudí svojho veku a pohlavia prekonávaš, a môžeš vyzvať priateľov.</p><p><a href="/?sport={SID.get(tid, 'hb_' + tid)}">Pozrieť rebríček: {E(name)} →</a></p></div>
{f'<h2>Ďalšie testy: {E(d["catLabel"])}</h2><div class="more">{more}</div>' if more else ''}
<p style="margin-top:28px"><a class="cta" href="/benchmark.html#{tid}">▶ Vyskúšať {E(name)}</a></p>"""
    ld = {"@context": "https://schema.org", "@graph": [
        {"@type": "WebApplication", "name": seot, "url": url, "applicationCategory": "GameApplication", "operatingSystem": "Web",
         "inLanguage": "sk", "isAccessibleForFree": True, "offers": {"@type": "Offer", "price": "0", "priceCurrency": "EUR"}, "description": what},
        {"@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "Porovnaj sa", "item": BASE + "/"},
            {"@type": "ListItem", "position": 2, "name": "Testy", "item": BASE + "/test/"},
            {"@type": "ListItem", "position": 3, "name": seot, "item": url}]}]}
    os.makedirs(f'{ROOT}/test/{slug}', exist_ok=True)
    open(f'{ROOT}/test/{slug}/index.html', 'w').write(page(title, mdesc, url, body, ld))

# prehľad
sections = ''
for c in order:
    ids = cats.get(c)
    if not ids: continue
    d0 = disc[ids[0]]
    items = ''.join(f'<a href="/test/{C[o][0]}/"><span style="background:{disc[o]["color"]}">{disc[o]["icon"].replace("width=\"40\" height=\"40\"", "width=\"18\" height=\"18\"")}</span>{E(C[o][1])}</a>' for o in ids)
    sections += f'<h2>{E(d0["catLabel"])}</h2><div class="more">{items}</div>'
body = f"""<p class="crumbs"><a href="/">Porovnaj sa</a> › Testy</p>
<h1>Testy mozgu online zadarmo</h1>
<p class="lead">25 krátkych testov po slovensky: reakčný čas, pamäť, postreh, odhad a logika. Každý trvá okolo minúty, funguje na mobile aj počítači a výsledok si môžeš porovnať s ostatnými.</p>
<a class="cta" href="/benchmark.html">▶ Otvoriť všetky testy</a>
{sections}"""
ld = {"@context": "https://schema.org", "@type": "CollectionPage", "name": "Testy mozgu online", "url": BASE + "/test/", "inLanguage": "sk"}
open(f'{ROOT}/test/index.html', 'w').write(page('Testy mozgu online zadarmo: reakcia, pamäť, postreh | Porovnaj sa',
    '25 bezplatných testov mozgu po slovensky: reakčný čas, pamäť, postreh, odhad a logika. Otestuj sa za minútu a porovnaj sa s ostatnými.', BASE + '/test/', body, ld))

sm = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
      f'  <url><loc>{BASE}/</loc><changefreq>daily</changefreq><priority>1.0</priority></url>',
      f'  <url><loc>{BASE}/benchmark.html</loc><changefreq>weekly</changefreq><priority>0.9</priority></url>',
      f'  <url><loc>{BASE}/test/</loc><changefreq>weekly</changefreq><priority>0.9</priority></url>']
sm += [f'  <url><loc>{u}</loc><changefreq>monthly</changefreq><priority>0.8</priority></url>' for u in urls]
sm += [f'  <url><loc>{BASE}/ochrana-udajov.html</loc><changefreq>yearly</changefreq><priority>0.2</priority></url>', '</urlset>']
open(f'{ROOT}/sitemap.xml', 'w').write('\n'.join(sm) + '\n')
print(len(urls), 'pages')
