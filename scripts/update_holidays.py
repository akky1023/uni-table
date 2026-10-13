"""Development-only update. The app itself never accesses the network."""
import csv
import io
import json
import pathlib
import sys
import urllib.request

url = 'https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv'
text = (pathlib.Path(sys.argv[1]).read_bytes() if len(sys.argv) > 1 else urllib.request.urlopen(url, timeout=30).read()).decode('cp932')
rows = list(csv.reader(io.StringIO(text)))[1:]
holidays = {f'{int(y):04}-{int(m):02}-{int(d):02}': name
            for date, name in rows if date
            for y, m, d in [date.split('/')]}
target = pathlib.Path(__file__).resolve().parents[1] / 'assets' / 'holidays.json'
target.write_text(json.dumps({'source': url, 'first_year': 1955, 'last_year': max(int(k[:4]) for k in holidays), 'dates': holidays}, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'{len(holidays)} holidays; through {max(holidays)}')
