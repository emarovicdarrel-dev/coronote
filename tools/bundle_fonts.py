# Downloads the two Google Fonts used by the app and rewrites docs/index.html to use local copies,
# so the installed app makes no request to Google while running.
import os, urllib.request
UA = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36"
API = "https://fonts.googleapis.com/css2?family=Manrope:wght@500;600;700&family=Cormorant+Garamond:wght@700&display=swap"

def get(u):
    return urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": UA}), timeout=30).read()

def run(root="docs"):
    css = get(API).decode()
    os.makedirs(root + "/fonts", exist_ok=True)
    urls, i = [], 0
    while True:
        a = css.find("url(", i)
        if a < 0: break
        b = css.find(")", a)
        u = css[a + 4:b].strip("'\"")
        if u.startswith("https://fonts.gstatic.com/") and u not in urls: urls.append(u)
        i = b
    if not urls: raise SystemExit("no font files found")
    for n, u in enumerate(urls):
        name = "f%d.woff2" % n
        open("%s/fonts/%s" % (root, name), "wb").write(get(u))
        css = css.replace(u, "fonts/" + name)
    open(root + "/fonts.css", "w").write(css)
    p = root + "/index.html"
    h = open(p).read()
    a = h.find('<link href="https://fonts.googleapis.com')
    if a < 0: raise SystemExit("font link not found in index.html")
    b = h.find(">", a) + 1
    open(p, "w").write(h[:a] + '<link href="fonts.css" rel="stylesheet">' + h[b:])
    print("fonts bundled:", len(urls))

if __name__ == "__main__":
    run()
