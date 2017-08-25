import re
import sys
import urllib2
import BeautifulSoup

usage = "Run the script: ./find_torrent.py SearchQuery"

if len(sys.argv)!=2:
    print(usage)
    sys.exit(0)

if len(sys.argv) > 1:
    findme = sys.argv[1]


from BeautifulSoup import BeautifulSoup
## torrentz = "https://monova.org/search?term=" + findme
torrentz = "https://torrentz2.eu/search?f=" + findme
print torrentz
hdr = {'User-Agent': 'Mozilla/5.0'}
req = urllib2.Request(torrentz,headers=hdr)

url = urllib2.urlopen(req)
content = url.read()
soup = BeautifulSoup(content)

for a in soup.findAll('a',href=True):
    if re.findall('python', a['href']):
        print "Found the URL:", a['href']
