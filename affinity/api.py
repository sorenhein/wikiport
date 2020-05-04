#!python3
"""Methods for interfacing with the Affinity API."""

import sys
import json
import requests
from requests.auth import HTTPBasicAuth


AFFINITY_BASE = 'https://api.affinity.co/'

AFFINITY_HEADERS = {'Content-Type': 'application/json'}

TOKEN = [line.rstrip() for line in open('key.txt', 'r')][0]


def fetch_url(url):
  """Reads from the Affinity API."""
  response = \
    requests.get(url, auth=HTTPBasicAuth('', TOKEN),
                 headers=AFFINITY_HEADERS)

  if response.status_code != 200:
    print("Affinity error code", response.status_code)
    sys.exit()

  return response.json()


def fetch_organization(org_id):
  """Fetches the MIG Sector."""
  response = \
    fetch_url(AFFINITY_BASE + 'field-values?organization_id=' + org_id)

  return response


def fetch_organization_name(org_id):
  """Fetches an organization name from Affinity."""
  response = fetch_url(AFFINITY_BASE + 'organizations/' + str(org_id))

  return response['name']


def fetch_person(person_id):
  """Fetches a person."""
  response = fetch_url(AFFINITY_BASE + 'persons/' + str(person_id))

  name = response['first_name'] + ' ' + response['last_name']
  mail = response['primary_email']

  return name, mail


def fetch_list_basics(list_id, entry_id):
  """Fetches the basics for a list entry."""
  response = \
    fetch_url(AFFINITY_BASE + 'lists/' +
              str(list_id) + '/list-entries/' + entry_id)

  return response


def fetch_list_fields(list_id):
  """Fetches all field values for a list entry."""
  response = \
    fetch_url(AFFINITY_BASE + 'field-values?list_entry_id=' + list_id)

  return response


def make_cached_file(url, fname):
  """Make a cached file from the URL."""
  response = get_url(url)
  lfile = open(fname, "w")
  lfile.write(json.dumps(response, indent=2))
  lfile.close()


def get_multi_value(response, field_id):
  """Turns a multi-value field into a comma-separated string."""
  res = ""
  for entry in response:
    if entry['field_id'] == field_id:
      if res != "":
        res = res + ", "
      res = res + entry['value']

  return res


def dump_json(name, json_object):
  """Simple print."""
  print(name)
  print(json.dumps(json_object, indent=2))
  print("")
