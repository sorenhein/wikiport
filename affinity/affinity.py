#!python3

# Interfaces with Affinity API.
#
# python3 affinity.py file.csv [refresh]

import sys
from enum import Enum
import json
import requests
from requests.auth import HTTPBasicAuth
import numpy as np


affinityBase = 'https://api.affinity.co/'
affinityHeaders = {'Content-Type': 'application/json'}

# File where personal Affinity API key is stored.
keyFile = 'key.txt'

# File with output of /lists.
listsFile = 'lists.txt'

# File with output of /fields.
fieldsFile = 'fields.txt'

# File with output of /organizations/fields.
orgFieldsFile = 'orgfields.txt'

class Fields(Enum):
  ListEntryId = 0
  OrganizationId = 1
  Name = 2
  OrganizationURL = 3
  MIGSector = 4
  Status = 5
  Owners = 6
  OwnersMail = 7
  Transaction = 8
  FundingRound = 9
  Amount = 10
  PreMoney = 11
  Currency = 12
  Quality = 13
  DateAdded = 14
  DateDecided = 15
  WikiURL = 16
  SourceType = 17
  SourceOrganization = 18
  SourceName = 19
  SourceNameMail = 20
  SourceMethod = 21
  SourcedBy = 22
  SourcedByMail = 23
  Reason = 24

headingToEnum = {
  'List Entry Id': Fields.ListEntryId,
  'Organization Id': Fields.OrganizationId,
  'Name': Fields.Name,
  'Organization URL': Fields.OrganizationURL,
  'MIG Sector': Fields.MIGSector,
  'Status': Fields.Status,
  'Owners': Fields.Owners,
  'Owners (Primary Email)': Fields.OwnersMail,
  'Transaction': Fields.Transaction,
  'Funding Round': Fields.FundingRound,
  'Amount': Fields.Amount,
  'Pre-Money': Fields.PreMoney,
  'Currency': Fields.Currency,
  'Quality': Fields.Quality,
  'Date Added': Fields.DateAdded,
  'Date Decided': Fields.DateDecided,
  'Wiki URL': Fields.WikiURL,
  'Source Type': Fields.SourceType,
  'Source Organization': Fields.SourceOrganization,
  'Source Name': Fields.SourceName,
  'Source Name (Primary Email)': Fields.SourceNameMail,
  'Source Method': Fields.SourceMethod,
  'Sourced By': Fields.SourcedBy,
  'Sourced By (Primary Email)': Fields.SourcedByMail,
  'Reason to decline/ lost': Fields.Reason }

specialHeadings = {
  'List Entry Id': Fields.ListEntryId,
  'Organization Id': Fields.OrganizationId,
  'Name': Fields.Name,
  'Organization URL': Fields.OrganizationURL,
  'Date Added': Fields.DateAdded,
  'Date Decided': Fields.DateDecided }

secondaryHeadings = {
  'Owners (Primary Email)': 'Owners',
  'Source Name (Primary Email)': 'Source Name',
  'Sourced By (Primary Email)': 'Sourced By' }

class FieldInfo:
  def __init__(self, heading, CSVcolumn, affinityField, fieldListIndex, secondaryIndex):
    self.heading = heading
    self.CSVcolumn = CSVcolumn
    self.affinityField = affinityField
    self.fieldListIndex = fieldListIndex
    self.secondaryIndex = secondaryIndex

  def print(self):
    print("Heading", self.heading)
    print("CSVcolumn", self.CSVcolumn)
    print("affinityField", self.affinityField)
    print("fieldListIndex", self.fieldListIndex)
    print("secondaryIndex", self.secondaryIndex)
    print()

globalFieldMap = {}


# My Excel is German.
separator = ';'
enumerator = ','


def getArgs():
  """Reads the CSV file name and an optional refresh flag."""
  usageFlag = 0
  refreshFlag = 0
  l = len(sys.argv)

  if l == 2 or l == 3:
    f = sys.argv[1]
  else:
    usageFlag = 1
    
  if usageFlag == 0 and l == 3:
    if sys.argv[2] == 'refresh':
      refreshFlag = 1
    else:
      print("Optional flag must be 'refresh' if present.")
      usageFlag = 1

  if usageFlag:
    print("Usage: python3 affinity.py file.csv [refresh]")
    sys.exit()

  return f, refreshFlag


def readLines(fname):
  """Read in the lines of target pages."""
  lines = [line.rstrip() for line in open(fname, 'r')]
  return lines


def getURL(URL):
  response = requests.get(URL, 
    auth = HTTPBasicAuth('', token), 
    headers = affinityHeaders)

  if (response.status_code != 200):
    print(response.status_code)
    sys.exit()
  
  return response


def makeCachedFile(URL, fname):
  """Make a cached file from the URL."""
  response = getURL(URL)
  js = response.json()
  lf = open(fname, "w")
  lf.write(json.dumps(js, indent = 2))
  lf.close()


def makeCachedFiles():
  """Make the cached files (lists and fields)."""
  makeCachedFile(affinityBase + 'lists', listsFile)
  makeCachedFile(affinityBase + 'fields', fieldsFile)
  makeCachedFile(affinityBase + 'organizations/fields', orgFieldsFile)


def readDealListId(fname):
  """Read and parse the Deal Flow List number from the file."""
  with open(listsFile, 'r') as f:
    listsDict = json.load(f)

  for e in listsDict:
    if e['name'] == 'Deal Flow List':
      return e['id']
  
  print("Deal Flow List not found")
  sys.exit()


def readFieldMap(fname):
  """Read and parse the fields file."""
  with open(fname, 'r') as f:
    fieldsDict = json.load(f)

  return fieldsDict


def readCSVFile(fname):
  """Read and parse the CSV file."""
  lines = readLines(fname)

  # Read the header line.
  n = lines[0].count(separator)
  headers = np.empty(n+1, dtype = object)
  headers = lines[0].split(separator)

  fields = np.empty((len(lines)-1, n+1), dtype = object)
  for i in range(1, len(lines)):
    s = lines[i].count(separator)
    if s != n:
      print("Line", i, ":", lines[i], ", count", s)
      sys.exit()
    fields[i-1] = lines[i].split(separator)

  return headers, fields


def findFieldInMainMaps(heading, fieldMap, orgFieldMap):
  for i in range(len(fieldMap)):
    if fieldMap[i]['name'] == heading:
      return i, fieldMap[i]['id']

  for i in range(len(orgFieldMap)):
    if orgFieldMap[i]['name'] == heading:
      return i, orgFieldMap[i]['id']
  
  return -1, -1


def findField(heading, fieldMap, orgFieldMap):
  """Finds field index and ID if it exists."""

  if heading in secondaryHeadings:
    # Mail addresses that are part of a primary field.
    heading2 = secondaryHeadings[heading]
    a, c = findFieldInMainMaps(heading2, fieldMap, orgFieldMap)
    b = -1
  else:
    a, b = findFieldInMainMaps(heading, fieldMap, orgFieldMap)
    c = -1

  # Found a match.
  if (a, b, c) != (-1, -1, -1):
    return a, b, c

  # Special fields.
  if heading in specialHeadings:
    return -1, -1, -1

  print("Field", heading, "not found")
  sys.exit()


def setHeaderMaps(CSVHeadings, fieldMap, orgFieldMap):
  """Set up header tables."""

  for i in range(len(CSVHeadings)):
    h = CSVHeadings[i]

    if not h in headingToEnum:
      print("CSV header", h, "does not exist")
      sys.exit()

    index, id1, id2 = findField(h, fieldMap, orgFieldMap)
    globalFieldMap[headingToEnum[h]] = FieldInfo(h, i, index, id1, id2)


# Get command-line arguments.
CSVFile, refreshFlag = getArgs()

# Read the personal Affinity token.
token = readLines(keyFile)[0]

# Set up the cached files if needed.
if refreshFlag == 1:
  print("Remaking cache")
  makeCachedFiles()

# Read the cached files.
dealListId = readDealListId(listsFile)
fieldMap = readFieldMap(fieldsFile)
orgFieldMap = readFieldMap(orgFieldsFile)

# Read the CSV file.
CSVHeadings, CSVFields = readCSVFile(CSVFile)

# Set up field correspondences.
setHeaderMaps(CSVHeadings, fieldMap, orgFieldMap)

sys.exit()


fields = parseCSV(readTargets(sys.argv[1]))
# Get all fields
# Works
# URL = 'https://api.affinity.co/organizations/fields'

# Works
# URL = 'https://api.affinity.co/lists/56429'

# Dumps the whole deal flow list.
# URL = 'https://api.affinity.co/lists/56429/list-entries'

# Dumps a single entry from the deal list.
# URL = 'https://api.affinity.co/lists/56429/list-entries/15659640'

URL = 'https://api.affinity.co/field-values?list_entry_id=15659640'


# URL = 'https://api.affinity.co/lists'
response = getURL(URL)

js = response.json()
print(json.dumps(js, indent = 2))
sys.exit()


for field in fields:
  URL = affinityBase + field[0]
  print("Getting ", URL)

  response = getURL(URL)

  js = response.json()
  print(json.dumps(js, indent = 2))

