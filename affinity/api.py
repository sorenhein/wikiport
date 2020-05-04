#!python3
"""Methods for interfacing with the Affinity API."""

import sys
import json
import requests
from requests.auth import HTTPBasicAuth


AFFINITY_BASE = 'https://api.affinity.co/'

AFFINITY_HEADERS = {'Content-Type': 'application/json'}


def fetch_url(url):
  """Reads from the Affinity API."""
  response = \
    requests.get(url, auth=HTTPBasicAuth('', token),
                 headers=AFFINITY_HEADERS)

  if response.status_code != 200:
    print("Affinity error code", response.status_code)
    sys.exit()

  return response


def fetch_organization(org_id, field_id):
  """Fetches the MIG Sector."""
  response = \
    fetch_url(AFFINITY_BASE + 'field-values?organization_id=' + org_id)

  return response.json()


def fetch_organization_name(org_id):
  """Fetches an organization name from Affinity."""
  response = get_url(AFFINITY_BASE + 'organizations/' + str(org_id))

  return response.json()['name']


def fetch_person(person_id):
  """Fetches a person."""
  response = get_url(AFFINITY_BASE + 'persons/' + str(person_id))
  json = response.json()

  name = json['first_name'] + ' ' + json['last_name']
  mail = json['primary_email']

  return name, mail


def fetch_list_basics(list_id, entry_id):
  """Fetches the basics for a list entry."""
  response = \
    fetch_url(AFFINITY_BASE + 'lists/' +
              str(list_id) + '/list-entries/' + entry_id)

  return response.json()


def fetch_list_fields(list_id):
  """Fetches all field values for a list entry."""
  response = \
    get_url(AFFINITY_BASE + 'field-values?list_entry_id=' + list_id)

  js = response.json()


def get_multi_value(response, field_id):
  """Turns a multi-value field into a comma-separated string."""
  res = ""
  for entry in response:
    if entry['field_id'] == field_id:
      if res != "":
        res = res + ", "
      res = res + entry['value']

  return res
