"""Upload CosmicHunter screenshots to ja + en-US localizations.
iPhone APP_IPHONE_67 (1290x2796), iPad APP_IPAD_PRO_3GEN_129 (2048x2732).
Run locally: point KEY_PATH at the real p8 and SHOTS_DIR at the captured PNGs.
"""
import jwt, time, requests, os, hashlib, sys

KEY_ID = "WDXGY9WX55"
ISSUER = "2be0734f-943a-4d61-9dc9-5d9045c46fec"
KEY_PATH = r"C:\Users\Windows\.appstoreconnect\private_keys\AuthKey_WDXGY9WX55.p8"
APP_ID = os.environ.get("APP_ID", "")
BASE = os.path.dirname(os.path.abspath(__file__))
SHOTS_DIR = os.path.join(os.path.dirname(BASE), "shots")
p8 = open(KEY_PATH).read()

# (displayType, filename prefix, mode count)
IPHONE = "APP_IPHONE_67"
IPAD = "APP_IPAD_PRO_3GEN_129"
MODES = ["1", "2", "3"]


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, p8, algorithm="ES256", headers={"kid": KEY_ID})


def api(m, path, **kw):
    return requests.request(m, "https://api.appstoreconnect.apple.com/v1" + path,
                            headers={"Authorization": "Bearer " + tok(),
                                     "Content-Type": "application/json"}, **kw)


def version_id():
    d = api("GET", f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1").json()["data"]
    return d[0]["id"]


def del_shots(set_id):
    for ss in api("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=10").json().get("data", []):
        api("DELETE", f"/appScreenshots/{ss['id']}")


def get_or_make_set(loc_id, dtype):
    for s in api("GET", f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=20").json().get("data", []):
        if s["attributes"]["screenshotDisplayType"] == dtype:
            del_shots(s["id"])
            return s["id"]
    r = api("POST", "/appScreenshotSets", json={"data": {"type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": dtype},
            "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}})
    return r.json()["data"]["id"]


def upload(set_id, fpath):
    name = os.path.basename(fpath)
    data = open(fpath, "rb").read()
    r = api("POST", "/appScreenshots", json={"data": {"type": "appScreenshots",
            "attributes": {"fileName": name, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
    if r.status_code not in (200, 201):
        print("   reserve fail", name, r.status_code, r.text[:200]); return
    sd = r.json()["data"]
    for op in sd["attributes"].get("uploadOperations", []):
        h = {x["name"]: x["value"] for x in op["requestHeaders"]}
        requests.put(op["url"], headers=h, data=data[op["offset"]:op["offset"] + op["length"]])
    r2 = api("PATCH", f"/appScreenshots/{sd['id']}", json={"data": {"type": "appScreenshots", "id": sd["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    print("   ", name, "OK" if r2.status_code == 200 else f"commit {r2.status_code} {r2.text[:150]}")


vid = version_id()
locs = {l["attributes"]["locale"]: l["id"] for l in
        api("GET", f"/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=10").json()["data"]}
print("locales:", list(locs))

for locale, loc_id in locs.items():
    print(f"\n== {locale} ==")
    iset = get_or_make_set(loc_id, IPHONE)
    for m in MODES:
        upload(iset, os.path.join(SHOTS_DIR, f"iphone_67_{m}.png"))
    ipset = get_or_make_set(loc_id, IPAD)
    for m in MODES:
        upload(ipset, os.path.join(SHOTS_DIR, f"ipad_129_{m}.png"))

print("\nDone.")
