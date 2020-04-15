#!python3

import sys
import re
import requests
import html2text
import pprint
import time

### Constants

baseURL = 'https://info.mig.ag'

# MoinMoin language
action = 'action=raw'

# HTML
# action = 'action=show'

cookieFile = 'cookies.txt'

sleepyTime = 1.2

### End constants


# https://stackoverflow.com/questions/14742899/using-cookies-txt-file-with-python-requests
def parseCookieFile(cfile):
  """Parse a cookies.txt file and return a dictionary of key value pairs
  compatible with requests."""

  cookies = {}
  with open (cfile, 'r') as fp:
    for line in fp:
      if not re.match(r'^\#', line):
        lineFields = line.strip().split('\t')
        cookies[lineFields[5]] = lineFields[6]
  return cookies


if len(sys.argv) != 2:
  print("Usage: python3 cook.py file")
  sys.exit()

f = open(sys.argv[1], 'r')
lines = f.readlines()
f.close()

cookies = parseCookieFile(cookieFile)

for line in lines:
  tag = line.rstrip()
  print('Line ' + tag)
  time.sleep(sleepyTime)

# Remove comments
# rstrip() and manually add newline
# Read
# . shared
# . Affinity-only
# . Wiki-only (split into dead and alive) (split alive into deals and other)

# r = requests.get(baseURL + '/' + 'Affiris' + '?' + action, cookies=cookies)
# print(r.text)
