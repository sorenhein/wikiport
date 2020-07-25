#!python3
"""Interfaces with Affinity API to put comments."""

import sys
import json
import requests
import collections
from requests.auth import HTTPBasicAuth
import re


AFFINITY_BASE = 'https://api.affinity.co/'

AFFINITY_HEADERS = {'Content-Type': 'application/json'}

TOKEN = [line.rstrip() for line in open('key.txt', 'r')][0]

def err_msg(response, text):
  """Common code for error message."""
  if response.status_code != 200:
    print("Affinity error code", response.status_code)
    print("Source:", text)
    print("Response", response)
    sys.exit()


def fetch_url(url):
  """Reads from the Affinity API."""
  response = \
    requests.get(url, auth=HTTPBasicAuth('', TOKEN),
                 headers=AFFINITY_HEADERS)

  err_msg(response, "get")
  return response.json()


def put_url(url, payload):
  """Puts to the Affinity API."""
  response = \
    requests.put(url, json=payload, auth=HTTPBasicAuth('', TOKEN),
                 headers=AFFINITY_HEADERS)

  err_msg(response, "put")
  return response.json()


def post_url(url, payload):
  """Posts to the Affinity API."""
  response = \
    requests.post(url, json=payload, auth=HTTPBasicAuth('', TOKEN),
                 headers=AFFINITY_HEADERS)

  err_msg(response, "post")
  return response.json()


def fetch_list_fields(list_id):
  """Fetches all field values for a list entry."""
  response = \
    fetch_url(AFFINITY_BASE + 'field-values?list_entry_id=' + list_id)

  return response


def get_simple_value(response, field_id):
  """Gets a simple value."""
  for entry in response:
    if entry['field_id'] == field_id:
      return entry['value'], entry['id']
  return '', ''
  

def put_specific_field(field_value_id, value):
  """Puts the changes."""
  put_url(AFFINITY_BASE + 'field-values/' + str(field_value_id), value)


# Deal Flow List
deal_list_id = 56429

# SAFE ID Solutions
org_id = '16690852'

# Field ID of "Comment (Legacy)"
descr_no_id = 504495

new_text = "AT8"

json = fetch_list_fields(org_id)
aff_text, field_value_id = get_simple_value(json, descr_no_id)
print("Affinity text online", aff_text, "fno", field_value_id)
put_specific_field(field_value_id, new_text)
# url2 = "https://api.affinity.co/field-values/588148050?value=AT:7"
# response = requests.request("PUT", url2, auth=("", TOKEN))
# print(response.text.encode('utf8'))
sys.exit()

