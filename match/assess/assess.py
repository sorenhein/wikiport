#!python3
"""Interfaces with Affinity API to put comments."""

import sys
from enum import Enum
import json
import numpy as np
import re
import collections
import csv
import api


# My Excel is German.
SEPARATOR = ','
ENUMERATOR = ','


def get_args():
  """Reads the CSV file name."""
  usage_flag = 0
  local_refresh_flag = 0
  l = len(sys.argv)

  if l == 3:
    return sys.argv[1], sys.argv[2]
  else:
    print("Usage: python3 comm.py wiki.csv aff.csv")
    sys.exit()


def read_lines(fname):
  """Read in the lines of target pages."""
  lines = [line.rstrip() for line in open(fname, 'r')]
  return lines


def read_csv_file(fname, delim):
  """Read and parse the CSV file."""
  lines = read_lines(fname)

  local_fields = []
  for i in range(len(lines)):
    res = list(csv.reader([lines[i]], delimiter=delim, quotechar='"'))[0]
    local_fields.append(res)

  return local_fields


# Get command-line arguments.
wiki_file, aff_file = get_args()

# Read the Wiki file.
wiki_fields = read_csv_file(wiki_file, ';')
wiki_map = {}
for e in wiki_fields:
  wiki_map[e[0]] = e[1]


# Read the Affinity file.
aff_fields = read_csv_file(aff_file, ',')
aff_map = {}
for e in aff_fields:
  aff_map[e[17]] = e

print("Got", len(wiki_fields), "Wiki fields and", len(aff_fields), "Affinity fields")

# Field ID of "Comment (Legacy)", hardwired
descr_no_id = 504495

num_no_aff_deal = 0
num_same = 0
num_empty = 0
num_diff = 0
n = 0

deal_list_id = api.get_deal_list_id()
print("deal_list_id", deal_list_id)

for wno in wiki_map:
  wdesc = wiki_map[wno]
  n += 1

  if wno not in aff_map:
    num_no_aff_deal += 1
  else:
    adesc = aff_map[wno][8]
    if wdesc == adesc:
      num_same += 1
    elif adesc == '':
      num_empty += 1
      # Should create
      orgid = aff_map[wno][0]
      listid = aff_map[wno][1]
      print("%4d, empty %8s %9s: %s" % (n, orgid, listid, wdesc))
      api.post_specific_field2(descr_no_id, listid, orgid, wdesc)
      # sys.exit()
    else:
      num_diff += 1
      print("%4d, %s, different %s, %s" % (n, aff_map[wno][2], wdesc, adesc))
      # Should replace
      orgid = aff_map[wno][0]
      listid = aff_map[wno][1]
      # print("%4d, empty %8s %9s: %s" % (n, orgid, listid, wdesc))
      # json = api.fetch_list_basics(deal_list_id, orgid)
      json = api.fetch_list_fields(orgid)
      api.dump_json("fetch", json)
      atext, fno = api.get_simple_value(json, descr_no_id)
      print("atext online", atext, "fno", fno, "wdesc", wdesc)
      api.put_specific_field(fno, wdesc)
      sys.exit()

print("No Aff deal:", num_no_aff_deal)
print("Same       :", num_same)
print("Empty      :", num_empty)
print("Different  :", num_diff)

sys.exit()
