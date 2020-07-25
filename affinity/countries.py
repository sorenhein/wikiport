#!python3
"""Interfaces with Affinity API to derive Country from Location"""

import sys
from enum import Enum
import json
import numpy as np
import re
import collections
import csv
import api


class Fields(Enum):
  """All the fields expected in the CSV file."""
  ListEntryId = 0
  OrganizationId = 1
  Name = 2
  OrganizationURL = 3
  Location = 4
  Country = 5
  DateAdded = 6

HEADING_TO_ENUM = {
  'List Entry Id': Fields.ListEntryId,
  'Organization Id': Fields.OrganizationId,
  'Name': Fields.Name,
  'Organization URL': Fields.OrganizationURL,
  'Location': Fields.Location,
  'Country': Fields.Country,
  'Date Added': Fields.DateAdded}

ENUM_TO_HEADING = {val: key for key, val in HEADING_TO_ENUM.items()}

CSV_COLUMN_TO_ENUM = [Fields.ListEntryId for i in range(len(Fields))]

# My Excel is German.
SEPARATOR = ','
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
    res = list(csv.reader([lines[i]], delimiter=',', quotechar='"'))[0]

    if len(res) != n+1:
      print("Line", i, ":", lines[i], ", count", len(res), "vs", n+1)
      sys.exit()

    local_fields[i-1] = res

  return headers, local_fields


def set_header_maps(local_csv_headings):
  """Set up header tables."""
  for i, h in enumerate(local_csv_headings):
    if not h in HEADING_TO_ENUM:
      print("CSV header", h, "does not exist")
      sys.exit()

    CSV_COLUMN_TO_ENUM[i] = HEADING_TO_ENUM[h]


def turn_line_into_map(line, column_to_enum):
  """Turn a 0-indexed line into a dictionary."""
  line_map = {}

  for i, local_e in enumerate(column_to_enum):
    line_map[local_e] = line[i]

  return line_map


def turn_csv_into_map(local_csv_fields):
  """csv_fields are counted from 0.  Turn into a dictionary."""
  fields = []
  for line in local_csv_fields:
    fields.append(turn_line_into_map(line, CSV_COLUMN_TO_ENUM))

  return fields


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
print("Got args", CSVFile, refresh_flag)
# Set up the cached files if needed.
if refresh_flag == 1:
  print("Remaking cache")
  api.make_cached_org_file()

# Read the cached files to get the field mapping.
field_name_to_enum, field_id_to_enum, enum_to_field_id = \
  api.get_org_field_maps(HEADING_TO_ENUM)

# Read the CSV file.
csv_headings, csv_fields = read_csv_file(CSVFile)

# Set up field correspondences.
set_header_maps(csv_headings)

# Store the CSV lines more semantically.
csv_maps = turn_csv_into_map(csv_fields)

set_and_identical = 0
set_and_different = 0
only_country = 0
only_location = 0
none_set = 0

fid = enum_to_field_id[Fields.Country]
count = 0
for entry in csv_maps:
  count += 1

  print("%4d of %4d: %4d %4d %4d %4d %4d, %s" % (count, len(csv_maps), set_and_identical, set_and_different, only_country, only_location, none_set, entry[Fields.Name]))
  # print("Expect location", entry[Fields.Location])
  # print("Expect country", entry[Fields.Country])

  fetched = {}

  # Get the organization fields.
  json = api.fetch_organization(entry[Fields.OrganizationId])
  # api.dump_json("org fetched", json)

  location, id = \
    api.get_simple_value(json, enum_to_field_id[Fields.Location]);

  country, id = \
    api.get_simple_value(json, enum_to_field_id[Fields.Country]);

  # print("Fetched", fetched[Fields.Location], fetched[Fields.Country])

  location_set = True
  if location == '':
    location_set = False

  country_set = True
  if country == '':
    country_set = False

  # if location_set:
    # print("Got location", location)
    # print("  in", location['country'])
  # else:
    # print("Got no location")

  if location_set:
    if country_set:
      if location['country'] == country:
        set_and_identical += 1
      else:
        set_and_different += 1
        print("    differ")
    else:
      only_location += 1
      api.post_specific_field(fid, entry[Fields.OrganizationId], location['country'])
  elif country_set:
    only_country += 1
    print("    only country")
  else:
    none_set += 1
  
  # sys.exit()

print("%-20s %4d" % ("Set and identical", set_and_identical))
print("%-20s %4d" % ("Set and different", set_and_different))
print("%-20s %4d" % ("Only country", only_country))
print("%-20s %4d" % ("Only location", only_location))
print("%-20s %4d" % ("none_set", none_set))
sys.exit()
