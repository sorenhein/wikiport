#!python3
"""Interfaces with Affinity API to put Wiki numbers to Wiki No."""

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

  if l == 2:
    return sys.argv[1]
  else:
    print("Usage: python3 numbers.py numbers.csv")
    sys.exit()


def read_lines(fname):
  """Read in the lines of target pages."""
  lines = [line.rstrip() for line in open(fname, 'r')]
  return lines


def read_csv_file(fname):
  """Read and parse the CSV file."""
  lines = read_lines(fname)

  local_fields = []
  for i in range(len(lines)):
    res = list(csv.reader([lines[i]], delimiter=';', quotechar='"'))[0]
    local_fields.append(res)

  return local_fields


# Get command-line arguments.
CSVFile = get_args()

# Read the CSV file.
csv_fields = read_csv_file(CSVFile)

# Field ID of Wiki No., hardwired
wiki_no_id = 590532

count = 0
num_write = 0
num_correct = 0
num_error = 0
for entry in csv_fields:
  count += 1

  # Fetch deal
  json = api.fetch_list_fields(entry[0])

  value, vid = api.get_simple_value(json, wiki_no_id)
  if value == '':
    print("%8s, %9s: %4d %4d %4d %4d %-8s %s" % (entry[0], entry[1], count, num_write, num_correct, num_error, "WRITE", entry[2]), flush=True)
    api.post_specific_field2(wiki_no_id, entry[1], entry[0], entry[2])
    num_write += 1
  elif value == entry[2]:
    print("%8s, %9s: %4d %4d %4d %4d %-8s %s" % (entry[0], entry[1], count, num_write, num_correct, num_error, "CORRECT", entry[2]), flush=True)
    num_correct += 1
  else:
    print("%8s, %9s: %4d %4d %4d %4d %-8s %s" % (entry[0], entry[1], count, num_write, num_correct, num_error, "ERROR", entry[2]), flush=True)
    num_error += 1

print("-" * 57)
print("%8s, %9s: %4d %4d %4d %4d %-8s %s" % ("", "", count, num_write, num_correct, num_error, "ALL", ""))

sys.exit()
