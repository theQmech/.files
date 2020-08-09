# Use case: Grab PDF files from webpages (required in some extreme cases)

import re
import urllib.request
from bs4 import BeautifulSoup
import sys

headers = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"

# url = "http://www.pm.inf.ethz.ch/education/courses/COOP.html"
url = sys.argv[1]
req = urllib.request.Request(url)
req.add_header('User-Agent', headers)
html = urllib.request.urlopen(req).read()

sopa = BeautifulSoup(html, "html.parser")
for link in sopa.find_all(href=re.compile("pdf$")):
    pdflink = link.get("href")
    fname = urllib.parse.unquote(pdflink.rsplit('/', 1)[-1])

    req = urllib.request.Request(pdflink)
    req.add_header('User-Agent', headers)
    pdf = urllib.request.urlopen(req).read()

    with open(fname, 'wb') as f:
        f.write(pdf)

    print (fname)

