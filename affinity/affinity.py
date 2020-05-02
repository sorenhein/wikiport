#!python3
"""Interfaces with Affinity API: python3 affinity.py file.csv [refresh]"""

import sys
from enum import Enum
import json
import requests
from requests.auth import HTTPBasicAuth
import numpy as np


AFFINITY_BASE = 'https://api.affinity.co/'
AFFINITY_HEADERS = {'Content-Type': 'application/json'}

# File where personal Affinity API key is stored.
KEY_FILE = 'key.txt'

# File with output of /lists.
LISTS_FILE = 'lists.txt'

# File with output of /fields.
FIELDS_FILE = 'fields.txt'

# File with output of /organizations/fields.
ORG_FIELDS_FILE = 'orgfields.txt'

class Fields(Enum):
  """All the fields expected in the CSV file."""
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

HEADING_TO_ENUM = {
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
  'Reason to decline/ lost': Fields.Reason}

SPECIAL_HEADINGS = {
  'List Entry Id': Fields.ListEntryId,
  'Organization Id': Fields.OrganizationId,
  'Name': Fields.Name,
  'Organization URL': Fields.OrganizationURL,
  'Date Added': Fields.DateAdded,
  'Date Decided': Fields.DateDecided}

SECONDARY_HEADINGS = {
  'Owners (Primary Email)': 'Owners',
  'Source Name (Primary Email)': 'Source Name',
  'Sourced By (Primary Email)': 'Sourced By'}

class FieldInfo:
  """Keeps track of knowledge about a field."""
  def __init__(self, heading, csv_column, affinity_field,
               field_list_index, secondary_index):
    self.heading = heading
    self.csv_column = csv_column
    self.affinity_field = affinity_field
    self.field_list_index = field_list_index
    self.secondary_index = secondary_index

  def show(self):
    """Simple dump."""
    print("Heading", self.heading)
    print("csv_column", self.csv_column)
    print("affinityField", self.affinity_field)
    print("fieldListIndex", self.field_list_index)
    print("secondaryIndex", self.secondary_index)
    print()

GlobalFieldMap = {}


# My Excel is German.
SEPARATOR = ';'
ENUMERATOR = ','


def get_args():
  """Reads the CSV file name and an optional refresh flag."""
  usage_flag = 0
  local_refresh_flag = 0
  l = len(sys.argv)

  if l in (2, 3):
    f = sys.argv[1]
  else:
    usage_flag = 1

  if usage_flag == 0 and l == 3:
    if sys.argv[2] == 'refresh':
      local_refresh_flag = 1
    else:
      print("Optional flag must be 'refresh' if present.")
      usage_flag = 1

  if usage_flag:
    print("Usage: python3 affinity.py file.csv [refresh]")
    sys.exit()

  return f, local_refresh_flag


def read_lines(fname):
  """Read in the lines of target pages."""
  lines = [line.rstrip() for line in open(fname, 'r')]
  return lines


def get_url(url):
  """Reads from the Affinity API."""
  local_resp = requests.get(url,
                            auth=HTTPBasicAuth('', token),
                            headers=AFFINITY_HEADERS)

  if local_resp.status_code != 200:
    print(local_resp.status_code)
    sys.exit()

  return response


def make_cached_file(url, fname):
  """Make a cached file from the URL."""
  local_resp = get_url(url)
  jsr = local_resp.json()
  lfile = open(fname, "w")
  lfile.write(json.dumps(jsr, indent=2))
  lfile.close()


def make_cached_files():
  """Make the cached files (lists and fields)."""
  make_cached_file(AFFINITY_BASE + 'lists', LISTS_FILE)
  make_cached_file(AFFINITY_BASE + 'fields', FIELDS_FILE)
  make_cached_file(AFFINITY_BASE + 'organizations/fields', ORG_FIELDS_FILE)


def read_deal_list_id(fname):
  """Read and parse the Deal Flow List number from the file."""
  with open(fname, 'r') as f:
    lists_dict = json.load(f)

  for e in lists_dict:
    if e['name'] == 'Deal Flow List':
      return e['id']

  print("Deal Flow List not found")
  sys.exit()


def read_field_map(fname):
  """Read and parse the fields file."""
  with open(fname, 'r') as f:
    fields_dict = json.load(f)

  return fields_dict


def read_csv_file(fname):
  """Read and parse the CSV file."""
  lines = read_lines(fname)

  # Read the header line.
  n = lines[0].count(SEPARATOR)
  headers = np.empty(n+1, dtype=object)
  headers = lines[0].split(SEPARATOR)

  local_fields = np.empty((len(lines)-1, n+1), dtype=object)
  for i in range(1, len(lines)):
    s = lines[i].count(SEPARATOR)
    if s != n:
      print("Line", i, ":", lines[i], ", count", s)
      sys.exit()
    local_fields[i-1] = lines[i].split(SEPARATOR)

  return headers, local_fields


def find_field_in_main_maps(heading, local_field_map, local_org_map):
  """Try to find the field."""
  for i in range(len(field_map)):
    if local_field_map[i]['name'] == heading:
      return i, local_field_map[i]['id']

  for i in range(len(local_org_map)):
    if local_org_map[i]['name'] == heading:
      return i, local_org_map[i]['id']

  return -1, -1


def find_field(heading, local_field_map, local_org_map):
  """Finds field index and ID if it exists."""

  if heading in SECONDARY_HEADINGS:
    # Mail addresses that are part of a primary field.
    heading2 = SECONDARY_HEADINGS[heading]
    a, c = find_field_in_main_maps(heading2, local_field_map, local_org_map)
    b = -1
  else:
    a, b = find_field_in_main_maps(heading, local_field_map, local_org_map)
    c = -1

  # Found a match.
  if (a, b, c) != (-1, -1, -1):
    return a, b, c

  # Special fields.
  if heading in SPECIAL_HEADINGS:
    return -1, -1, -1

  print("Field", heading, "not found")
  sys.exit()


def set_header_maps(csv_headings, local_field_map, local_org_map):
  """Set up header tables."""

  for i in range(len(csv_headings)):
    h = csv_headings[i]

    if not h in HEADING_TO_ENUM:
      print("CSV header", h, "does not exist")
      sys.exit()

    index, id1, id2 = find_field(h, local_field_map, local_org_map)
    GlobalFieldMap[HEADING_TO_ENUM[h]] = FieldInfo(h, i, index, id1, id2)


def turn_line_into_map(line, column_to_enum):
  """Turn a 0-indexed line into a dictionary."""
  line_map = {}
  for i in range(len(column_to_enum)):
    line_map[column_to_enum[i]] = line[i]

  return line_map


def turn_csv_into_map(local_csv_fields):
  """csv_fields are counted from 0.  Turn into a dictionary."""
  column_to_enum = [0 for i in range(len(GlobalFieldMap))]
  for e in GlobalFieldMap:
    g = GlobalFieldMap[e]
    column_to_enum[g.csv_column] = HEADING_TO_ENUM[g.heading]

  fields = []
  for line in local_csv_fields:
    fields.append(turn_line_into_map(line, column_to_enum))

  return fields


# Get command-line arguments.
CSVFile, refresh_flag = get_args()

# Read the personal Affinity token.
token = read_lines(KEY_FILE)[0]

# Set up the cached files if needed.
if refresh_flag == 1:
  print("Remaking cache")
  make_cached_files()

# Read the cached files.
dealListId = read_deal_list_id(LISTS_FILE)
field_map = read_field_map(FIELDS_FILE)
org_field_map = read_field_map(ORG_FIELDS_FILE)

# Read the CSV file.
CSVHeadings, csv_fields = read_csv_file(CSVFile)

# Set up field correspondences.
set_header_maps(CSVHeadings, field_map, org_field_map)

# Store the CSV lines more semantically.
CSVMaps = turn_csv_into_map(csv_fields)

# Loop over CSV lines.
for entry in CSVMaps:
  response = get_url(AFFINITY_BASE + 'organizations/' +
                     entry[Fields.OrganizationId])

  # print("Organization")
  # js = response.json()
  # print(json.dumps(js, indent = 2))

  response = get_url(AFFINITY_BASE + 'lists/' +
                     str(dealListId) + '/list-entries/' +
                     entry[Fields.ListEntryId])

  # print("Deal List entry")
  # js = response.json()
  # print(json.dumps(js, indent = 2))

  response = get_url(AFFINITY_BASE + 'field-values?list_entry_id=' +
                     entry[Fields.ListEntryId])
  print("Fields")
  js = response.json()
  print(json.dumps(js, indent=2))


sys.exit()
