#!python3

# Interfaces with Affinity API.  For now it does organizations.
# Reads key.txt for the API key.
# % python3 affinity.py orgs.csv

import sys
import json
import requests
from requests.auth import HTTPBasicAuth
import numpy as np


affinityBase = 'https://api.affinity.co/organizations/'
affinityHeaders = {'Content-Type': 'application/json'}

keyfile = 'key.txt'

headings = [
  'Organization Id',
  'Name',
  'Organization URL',
  'MIG Sector',
  'Wiki URL']

separator = ';'

### End constants


def readTargets(tfile):
  """Read in the lines of target pages."""
  tlines = [line.rstrip() for line in open(tfile, 'r')]
  return tlines


def parseCSV(lines):
  pfields = np.empty((len(lines), 5), dtype = object)
  for i in range(len(lines)):
    pfields[i] = lines[i].split(separator)
  return pfields


def printField(field):
  for i in range(len(headings)):
    print("{0:20s}: {1}".format(headings[i], field[i]))
  print("")


def getURL(URL):
  response = requests.get(URL, 
    auth = HTTPBasicAuth('', token), 
    headers = affinityHeaders)

  if (response.status_code != 200):
    print(response.status_code)
    sys.exit()
  
  return response


if len(sys.argv) != 2:
  print("Usage: python3 affinity.py file.csv")
  sys.exit()

tokenlines = readTargets(keyfile)
token = tokenlines[0]

fields = parseCSV(readTargets(sys.argv[1]))

# Get all fields
# URL = 'https://api.affinity.co/organizations/fields'
# URL = 'https://api.affinity.co/lists/56429/list_entries/15659640'
# URL = 'https://api.affinity.co/lists'
# response = getURL(URL)

# js = response.json()
# print(json.dumps(js, indent = 2))
# sys.exit()


for field in fields:
  URL = affinityBase + field[0]
  print("Getting ", URL)

  response = getURL(URL)

  js = response.json()
  print(json.dumps(js, indent = 2))

