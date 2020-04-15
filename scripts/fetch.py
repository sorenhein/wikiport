#!python3

# Fetches pages from MIG wiki:
# python3 fetch.py pages.txt

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

sleepyTime = 12

outDir = "../data/deals"
foundDir = "found"
missedDir = "notfound"

### End constants


def readTargets(tfile):
  """Read in the lines of target pages."""
  f = open(sys.argv[1], 'r')
  tlines = f.readlines()
  f.close()
  return tlines


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


def writeText(odir, tag, lines):
  """Fix and write the lines to the output file."""
  mtext = "Page " + tag + " not found."
  if (len(lines) <= len(mtext) + 2 and lines[:len(mtext)+1] == mtext):
    ofile = odir + '/' + missedDir + '/miss.txt'
    of = open(ofile, 'a')
    of.write(tag + "\n")
    of.close()
  else:
    ofile = odir + '/' + foundDir + '/' + tag + '.txt'
    of = open(ofile, 'w')
    of.write(lines + "\n")
    of.close()


if len(sys.argv) != 2:
  print("Usage: python3 cook.py file")
  sys.exit()

lines = readTargets(sys.argv[1])

cookies = parseCookieFile(cookieFile)

for line in lines:
  tag = line.rstrip()

  # tag may have spaces that need to be converted into %20.
  spaceTag = tag
  spaceTag.replace(' ', '%20')

  print('Getting ' + tag)
  r = requests.get(baseURL + '/' + spaceTag + '?' + action, cookies=cookies)
  writeText(outDir, spaceTag, r.text)

  time.sleep(sleepyTime)

# Remove comments

# Read
# . shared
# . Affinity-only
# . Wiki-only (split into dead and alive) (split alive into deals and other)
