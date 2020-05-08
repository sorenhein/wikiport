#!python3
"""Interfaces with Affinity API: python3 affinity.py file.csv [refresh]"""

import sys
from enum import Enum
import json
import numpy as np
import re
import collections
import api


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

ENUM_TO_HEADING = {val: key for key, val in HEADING_TO_ENUM.items()}

CSV_COLUMN_TO_ENUM = [Fields.ListEntryId for i in range(len(Fields))]

CERTAIN_FIXES = {
  Fields.MIGSector: 1,
  Fields.Status: 1,
  Fields.Owners: 1,
  Fields.Transaction: 1,
  Fields.FundingRound: 1,
  Fields.Amount: 1,
  Fields.PreMoney: 1,
  Fields.Currency: 1,
  Fields.Quality: 1,
  Fields.WikiURL: 1,
  Fields.SourceType: 1,
  Fields.SourcedBy: 1,
  Fields.Reason: 1}

SPECIAL_HEADINGS = {
  'List Entry Id': Fields.ListEntryId,
  'Organization Id': Fields.OrganizationId,
  'Name': Fields.Name,
  'Organization URL': Fields.OrganizationURL,
  'Date Added': Fields.DateAdded,
  'Date Decided': Fields.DateDecided}

PRIMARY_ENUMS = {
  Fields.Owners: Fields.OwnersMail,
  Fields.SourceName: Fields.SourceNameMail,
  Fields.SourcedBy: Fields.SourcedByMail}

SECONDARY_HEADINGS = {
  'Owners (Primary Email)': 'Owners',
  'Source Name (Primary Email)': 'Source Name',
  'Sourced By (Primary Email)': 'Sourced By'}

ASSOCIATED_HEADINGS = {
  Fields.Owners: Fields.OwnersMail,
  Fields.SourcedBy: Fields.SourcedByMail}

NUMERICAL_HEADINGS = {
  Fields.Status: 1,
  Fields.Quality: 1,
  Fields.Owners: 1,
  Fields.OwnersMail: 1,
  Fields.SourcedBy: 1,
  Fields.SourcedByMail: 1}

class Matches(Enum):
  """All the fields expected in the CSV file."""
  NoData = 0
  OnlyCSVGlobal = 1
  OnlyCSVLocal = 2
  OnlyAffinityGlobal = 3
  OnlyAffinityLocal = 4
  BothSame = 5
  BothDiffGlobal = 6
  BothDiffLocal = 7

MATCH_TO_NAME = {
  Matches.NoData: 'none',
  Matches.OnlyCSVGlobal: 'csv-g',
  Matches.OnlyCSVLocal: 'csv-l',
  Matches.OnlyAffinityGlobal: 'aff-g',
  Matches.OnlyAffinityLocal: 'aff-l',
  Matches.BothSame: 'same',
  Matches.BothDiffGlobal: 'diff-g',
  Matches.BothDiffLocal: 'diff-l'}

MIG_MAILS = {
  'at@mig.ag',
  'bb@mig.ag',
  'jk@mig.ag',
  'ksg@mig.ag',
  'mg@mig.ag',
  'mk@mig.ag',
  'mm@mig.ag',
  'ok@mig.ag',
  'sh@mig.ag',
  'kf@mig.ag',
  'info@mig.ag',
  'businessplan@mig.ag'}

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


def read_csv_file(fname):
  """Read and parse the CSV file."""
  lines = read_lines(fname)

  # Read the header line.
  n = lines[0].count(SEPARATOR)
  headers = np.empty(n+1, dtype=object)
  headers = lines[0].split(SEPARATOR)

  # Drop the three non-text bytes in front of Excel csv.
  if headers[0][1] == 'L':
    headers[0] = headers[0][1:]

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
  if heading in local_field_map:
    return local_field_map[heading]

  if heading in local_org_map:
    return local_org_map[heading]

  return -1


def find_field(heading, local_field_map, local_org_map):
  """Finds field index and ID if it exists."""

  if heading in SECONDARY_HEADINGS:
    # Mail addresses that are part of a primary field.
    heading2 = SECONDARY_HEADINGS[heading]
    c = find_field_in_main_maps(heading2, local_field_map, local_org_map)
    b = -1
  else:
    b = find_field_in_main_maps(heading, local_field_map, local_org_map)
    c = -1

  # Found a match.
  if (b, c) != (-1, -1):
    return b, c

  # Special fields.
  if heading in SPECIAL_HEADINGS:
    return -1, -1

  print("Field", heading, "not found")
  sys.exit()


def set_header_maps(local_csv_headings):
  """Set up header tables."""
  for i, h in enumerate(local_csv_headings):
    if not h in HEADING_TO_ENUM:
      print("CSV header", h, "does not exist")
      sys.exit()

    CSV_COLUMN_TO_ENUM[i] = HEADING_TO_ENUM[h]


def turn_line_into_map(line, column_to_enum, dropdown_map):
  """Turn a 0-indexed line into a dictionary."""
  line_map = {}

  for i, local_e in enumerate(column_to_enum):
    # Split if enumerator is present.
    n = line[i].count(ENUMERATOR + ' ')
    items = np.empty(n+1, dtype=object)
    items = line[i].split(ENUMERATOR + ' ')

    res = ''
    for item in items:
      if res != '':
        res = res + ENUMERATOR + ' '

      if local_e in dropdown_map:
        # Remove "1. "
        item = re.sub("^\d+\. ", "", item)
        # Turn "1 Interesting" into "1 - Interesting"
        item = re.sub("^(\d+) ([^-])", r"\1 - \2", item)
        # item = re.sub("^(\d+)\. (\d) ([^-])", r"\1. \2 - \3", item)
        # if local_e == Fields.Quality:
          # print("item", item)

        if local_e in NUMERICAL_HEADINGS:
          item = api.turn_text_into_dropdown(item, enum_text_to_id[local_e])

        res = res + str(item)
          # str(api.turn_text_into_dropdown(item, dropdown_map[local_e]))
      else:
        res = res + item

    # To be consistent with Affinity.
    if local_e == Fields.OrganizationURL and res == '':
      res = 'None'

    line_map[local_e] = res

  return line_map


def turn_csv_into_map(local_csv_fields, dropdown_map):
  """csv_fields are counted from 0.  Turn into a dictionary."""
  fields = []
  for line in local_csv_fields:
    fields.append(turn_line_into_map(line, 
                  CSV_COLUMN_TO_ENUM, dropdown_map))

  return fields


def get_value_from_field(local_field, enum_value):
  """Parses the value from an Affinity return."""
  if 'value' not in local_field:
    print("Warning", local_field)
    return -1, -1

  val = local_field['value']
  if isinstance(val, str) or isinstance(val, float):
    return val, -1

  if enum_value in PRIMARY_ENUMS:
    # This is a person, so we need to get the name and mail.
    return api.fetch_person(local_field['value'])

  if isinstance(val, dict):
    if 'text' in val:
      return val['text'], -1
    print("Expected text")
    return -1, -1

  if enum_value == Fields.SourceOrganization:
    # Look up organization name.
    return api.fetch_organization_name(val), -1

  print("Warning: Stuck")
  print("enum_value", enum_value)
  print("type", type(val))
  print("local_field", local_field)
  return -1, -1


def classify_match(csv_field, aff_field, my_global_flag):
  """Classify according to the Matches enum."""
  if csv_field == '':
    if aff_field == '':
      e = Matches.NoData
    elif my_global_flag == 1:
      e = Matches.OnlyAffinityGlobal
    else:
      e = Matches.OnlyAffinityLocal
  elif aff_field == '':
    if my_global_flag == 1:
      e = Matches.OnlyCSVGlobal
    else:
      e = Matches.OnlyCSVLocal
  elif str(csv_field) == str(aff_field):
      e = Matches.BothSame
  elif my_global_flag == 1:
    e = Matches.BothDiffGlobal
  else:
    e = Matches.BothDiffLocal

  return e


def compare(csv_entry, fetched_fields, my_global_flag, matches):
  """Compare (for now, print) the vectors."""
  entry_changed = {}
  change_flag = 0

  for local_e in Fields:
    if local_e in csv_entry:
      cfield = csv_entry[local_e]
    else:
      cfield = ''

    if local_e in fetched_fields:
      ffield = fetched_fields[local_e]
    else:
      ffield = ''

    c = classify_match(cfield, ffield, my_global_flag)
    matches[local_e][c] += 1
    # if c == Matches.OnlyAffinityLocal or c == Matches.OnlyAffinityGlobal:
      # print("HERE", cfield, "and", ffield)

    if cfield == '' and ffield == '':
      entry_changed[local_e] = 0
      continue

    if str(cfield) == str(ffield):
      diff = ''
      ffield = '='
      entry_changed[local_e] = 0
    elif ffield != None and cfield != '' and cfield == ffield[0:len(cfield)]:
      # Numerical equality, 1000 vs 1000.0
      diff = ''
      ffield = '='
      entry_changed[local_e] = 0
      if c == Matches.OnlyAffinityLocal or c == Matches.OnlyAffinityGlobal:
        print("HERE", cfield, "and", ffield)
    else:
      diff = MATCH_TO_NAME[c]
      entry_changed[local_e] = 1
      change_flag = 1

    print('%20s: %30s %15s %s' % (str(local_e)[7:], cfield, ffield, diff))

  print("", flush=True)
  return change_flag, entry_changed, matches


def make_json_line(heading, value, field_name_to_enum, enum_to_field_id,
                   enum_text_to_id):
  """Make a json entry out of the change."""
  result = {}

  evalue = field_name_to_enum[heading]
  result['field_id'] = enum_to_field_id[evalue]

  if evalue in enum_to_field_id:
    # It's a dropdown item.
    result['value'] = {'id': int(value)}
  else:
    result['value'] = value

  return result
        

def make_deal_changes(entry, changes_entry, field_name_to_enum,
                      enum_to_field_id, enum_text_to_id):
  """Make a json list of deal changes."""
  result = []
  for heading in HEADING_TO_ENUM:
    henum = HEADING_TO_ENUM[heading]
    if changes_entry[henum] == 0:
      continue
    if heading in SPECIAL_HEADINGS or heading in SECONDARY_HEADINGS:
      continue
    if heading == 'WikiURL' or heading == 'MIG Sector':
      continue

    result.append(make_json_line(heading, entry[henum], field_name_to_enum,
                                 enum_to_field_id, enum_text_to_id))
  
  return result


def print_dict_of_dicts(dict_dict):
  """Print the dropdown menus for the user."""
  for enum_val in dict_dict:
    print("Field:", ENUM_TO_HEADING[enum_val])
    for key in dict_dict[enum_val]:
      print('%-10s %s' % (dict_dict[enum_val][key], key))
    print('')


def print_dict_dict_stats(dict_dict):
  """Print a 2D array."""

  # Print the header.
  s = '%-20s' % ''
  sum_col = {}
  for key in MATCH_TO_NAME:
    s += '%7s' % MATCH_TO_NAME[key]
    sum_col[key] = 0
  s += '%7s' % 'SUM'
  print(s)

  for key in dict_dict:
    # Print each line.
    sum_row = 0
    s = '%-20s' % str(key)[7:]
    for key_key in dict_dict[key]:
      v = dict_dict[key][key_key]
      if v == 0:
        s += '%7s' % '-'
      else:
        s += '%7d' % v
      sum_row += v
      sum_col[key_key] += v
    s += '%7d' % sum_row
    print(s)

  s = '%-20s' % 'SUM'
  for key in sum_col:
    s += '%7d' % sum_col[key]
  print(s)
  print('')


# Get command-line arguments.
CSVFile, refresh_flag = get_args()

# Set up the cached files if needed.
if refresh_flag == 1:
  print("Remaking cache")
  api.make_cached_files(MIG_MAILS)

# Read the cached files to get the field mapping.
deal_list_id = api.get_deal_list_id()
field_name_to_enum, field_id_to_enum, enum_to_field_id = \
  api.get_field_maps(deal_list_id, HEADING_TO_ENUM)

# Read them again to get the dropdown choices.
enum_text_to_id, enum_id_to_text = \
  api.get_dropdown_maps(deal_list_id, HEADING_TO_ENUM)


# Add honorary dropdowns for MIG names.
enum_text_to_id, enum_id_to_text = \
  api.add_name_dropdowns(enum_text_to_id, enum_id_to_text, HEADING_TO_ENUM)

print_dict_of_dicts(enum_text_to_id)

# Read the CSV file.
csv_headings, csv_fields = read_csv_file(CSVFile)

# Set up field correspondences.
set_header_maps(csv_headings)

# Store the CSV lines more semantically.
csv_maps = turn_csv_into_map(csv_fields, enum_text_to_id)

matches = collections.defaultdict(dict)
for entry in Fields:
  for match in Matches:
    matches[entry][match] = 0

# print("deal_list_id", deal_list_id)
# api.put_specific_field('500478743', {'value': 27000000})
# api.put_specific_field('500478746', {'value': "USD"})
# api.post_specific_field2(504481, 15624246, 56429, "USD")
# api.post_specific_field(504481, 15624246, "USD")
# sys.exit()

# field_id: what it says
# entity_id: The *org* ID
# list_entry_id: The line ID

# Loop over CSV lines.
for entry in csv_maps:

  fetched = {}

  # Get the organization fields -- only place to get MIG Sector.
  json = api.fetch_organization(entry[Fields.OrganizationId])
  # api.dump_json("org", json)

  fetched[Fields.MIGSector] = \
    api.get_multi_value(json, enum_to_field_id[Fields.MIGSector],
                        enum_text_to_id[Fields.MIGSector])
  
  fetched[Fields.WikiURL] = \
    api.get_simple_value(json, enum_to_field_id[Fields.WikiURL]);

  fetched[Fields.ListEntryId] = entry[Fields.ListEntryId]
  fetched[Fields.OrganizationId] = entry[Fields.OrganizationId]

  json = api.fetch_list_basics(deal_list_id, entry[Fields.ListEntryId])
  # api.dump_json("basics", json)

  fetched[Fields.Name] = json['entity']['name']
  fetched[Fields.OrganizationURL] = json['entity']['domain']
  global_flag = json['entity']['global']

  fetched[Fields.DateAdded] = api.get_time_string(json['created_at'])

  json = api.fetch_list_fields(entry[Fields.ListEntryId])
  # api.dump_json("fields", json)
  # sys.exit()

  for field in json:
    # print("field", field)
    if not field['field_id'] in field_id_to_enum:
      continue

    e = field_id_to_enum[field['field_id']]
    v1, v2 = get_value_from_field(field, e)

    # if e in enum_text_to_id:
      # v1 = api.turn_text_into_dropdown(v1, enum_text_to_id[e])

    if e in ASSOCIATED_HEADINGS:
      eprime = ASSOCIATED_HEADINGS[e]
      # print("Call", eprime, v1, "and", v2)
      # print("field", field)
      # print("e", e)
      v1 = api.turn_text_into_dropdown(v1, enum_text_to_id[e])
      v2 = api.turn_text_into_dropdown(v2, enum_text_to_id[eprime])
    elif e in NUMERICAL_HEADINGS:
      v1 = api.turn_text_into_dropdown(v1, enum_text_to_id[e])

    if e in fetched:
      # Multi-field.
      fetched[e] += ', ' + str(v1)
      if e in PRIMARY_ENUMS:
        fetched[PRIMARY_ENUMS[e]] += ', ' + str(v2)
    else:
      fetched[e] = str(v1)
      if e in PRIMARY_ENUMS:
        fetched[PRIMARY_ENUMS[e]] = str(v2)

      

  change_flag, changes_entry, matches = \
    compare(entry, fetched, global_flag, matches)

  # print("change_flag", change_flag)
  # print("entry", entry)
  # print("fetched", fetched)

  if change_flag == 0:
    # print("Continuing")
    continue

  # print("Still there")

  for e in CERTAIN_FIXES:
    # print("e candidate", e)
    if not e in entry or entry[e] == '':
      continue
    if e in fetched and fetched[e] != '':
      continue

    # print("enum_id_to_text", enum_id_to_text[e])

    fid = enum_to_field_id[e]
    oid = fetched[Fields.OrganizationId]
    lid = entry[Fields.ListEntryId]
    v = entry[e]

    # if e == Fields.Quality:
      # print("Skipping Quality", v)
      # continue

    # if e == Fields.Quality and v == "2. 2 - Interesting":
      # v = 1913257

    print("Trying", e, fid, oid, lid, v)
    if e == Fields.MIGSector:
      api.post_specific_field(fid, oid, v)
    else:
      api.post_specific_field2(fid, oid, lid, v)
    # sys.exit()

  # changed_json = \
    # make_deal_changes(entry, changes_entry, field_name_to_enum, 
                      # enum_to_field_id, enum_text_to_id)
  # api.put_deal_fields(entry[Fields.ListEntryId], changed_json)

  # sys.exit()

print_dict_dict_stats(matches)
sys.exit()
