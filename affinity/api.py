#!python3
"""Methods for interfacing with the Affinity API."""

import sys
import json
import requests
import collections
from requests.auth import HTTPBasicAuth
import re


AFFINITY_BASE = 'https://api.affinity.co/'

AFFINITY_HEADERS = {'Content-Type': 'application/json'}

TOKEN = [line.rstrip() for line in open('key.txt', 'r')][0]

# File with output of /lists.
LISTS_FILE = 'lists.txt'

# File with output of /fields.
FIELDS_FILE = 'fields.txt'

# File with output of /organizations/fields.
ORG_FIELDS_FILE = 'orgfields.txt'

# File with MIG names, mails and person ID's.
NAMES_FILE = 'names.txt'


def err_msg(response, text):
  """Common code for error message."""
  if response.status_code != 200:
    print("Affinity get error code", response.status_code)
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
  """Makes a cached file from the URL."""
  response = fetch_url(url)
  lfile = open(fname, "w")
  lfile.write(json.dumps(response, indent=2))
  lfile.close()


def make_cached_files(MIG_MAILS):
  """Makes the cached files (lists and fields)."""
  make_cached_file(AFFINITY_BASE + 'lists', LISTS_FILE)
  make_cached_file(AFFINITY_BASE + 'fields', FIELDS_FILE)
  make_cached_file(AFFINITY_BASE + 'organizations/fields', ORG_FIELDS_FILE)

  names = []
  for mail in MIG_MAILS:
    # As we query by mail, the response should always be right.
    response = fetch_url(AFFINITY_BASE + 'persons?term=' + mail)
    names.append(response['persons'][0])

  lfile = open(NAMES_FILE, "w")
  lfile.write(json.dumps(names, indent=2))
  lfile.close()


def get_deal_list_id():
  """Reads and parses the Deal Flow List number from the list file."""
  with open(LISTS_FILE, 'r') as f:
    lists_dict = json.load(f)

  for entry in lists_dict:
    if entry['name'] == 'Deal Flow List':
      return entry['id']

  print("Deal Flow List not found")
  sys.exit()


def get_field_maps(deal_list_id, heading_to_enum):
  """Reads and parses both cached files that contain fields."""
  with open(FIELDS_FILE, 'r') as f:
    fields_list1 = json.load(f)
  with open(ORG_FIELDS_FILE, 'r') as f:
    fields_list2 = json.load(f)
  fields_list = fields_list1 + fields_list2
  id_list = [str(deal_list_id)] * len(fields_list1) + \
            ['None'] * len(fields_list2)

  field_name_to_enum = {}
  field_id_to_enum = {}
  enum_to_field_id = {}

  for field, iid in zip(fields_list, id_list):
    if not field['name'] in heading_to_enum:
      continue

    if str(field['list_id']) != iid:
      continue

    fid = field['id']
    name = field['name']
    entry = heading_to_enum[name]

    field_name_to_enum[name] = entry
    field_id_to_enum[fid] = entry
    enum_to_field_id[entry] = fid

  return field_name_to_enum, field_id_to_enum, enum_to_field_id


def get_dropdown_maps(deal_list_id, heading_to_enum):
  """Reads both field files (again...) for dropdowns."""
  with open(FIELDS_FILE, 'r') as f:
    fields_list1 = json.load(f)
  with open(ORG_FIELDS_FILE, 'r') as f:
    fields_list2 = json.load(f)
  fields_list = fields_list1 + fields_list2
  id_list = [str(deal_list_id)] * len(fields_list1) + \
            ['None'] * len(fields_list2)

  enum_text_to_id = collections.defaultdict(dict)
  enum_id_to_text = collections.defaultdict(dict)

  for field, iid in zip(fields_list, id_list):
    if str(field['list_id']) != iid:
      continue

    if field['dropdown_options'] == []:
      continue

    if not field['name'] in heading_to_enum:
      print("Warning", field['name'])
      continue

    henum = heading_to_enum[field['name']]
    for item in field['dropdown_options']:
      text = item['text']
      iid = item['id']
      enum_text_to_id[henum][text] = iid
      enum_id_to_text[henum][iid] = text

  return enum_text_to_id, enum_id_to_text


def add_name_dropdowns(enum_text_to_id, enum_id_to_text, heading_to_enum):
  # Also do the MIG names as honorary dropdowns.
  with open(NAMES_FILE, 'r') as f:
    fields_list = json.load(f)

  for field in fields_list:
    text = field['first_name'] + ' ' + field['last_name']
    iid = field['id']
    mail = field['primary_email']

    enum_text_to_id[heading_to_enum['Owners']][text] = iid
    enum_id_to_text[heading_to_enum['Owners']][iid] = text
  
    enum_text_to_id[heading_to_enum['Owners (Primary Email)']][mail] = iid
    enum_id_to_text[heading_to_enum['Owners (Primary Email)']][iid] = mail
  
    enum_text_to_id[heading_to_enum['Sourced By']][text] = iid
    enum_id_to_text[heading_to_enum['Sourced By']][iid] = text
  
    enum_text_to_id[heading_to_enum['Sourced By (Primary Email)']][mail] = iid
    enum_id_to_text[heading_to_enum['Sourced By (Primary Email)']][iid] = mail

  return enum_text_to_id, enum_id_to_text
  

def turn_text_into_dropdown(text, dropdown_map):
  """Turns text into the corresponding dropdown key(s)."""
  if text == "":
    return text

  if text in dropdown_map:
    return dropdown_map[text]

  # There are differently formatted fields in csv -- fix these.
  # Remove "1. "
  text = re.sub("^\d+\. ", "", text)
  # Turn "1 Interesting" into "1 - Interesting"
  text = re.sub("^(\d+) ([^-])", r"\1 - \2", text)

  if text in dropdown_map:
    return dropdown_map[text]

  print("Warning", text)
  return text


def get_simple_value(response, field_id):
  """Gets a simple value."""
  for entry in response:
    if entry['field_id'] == field_id:
      return entry['value']
  return ''
  

def get_multi_value(response, field_id, dropdown_map):
  """Turns a multi-value field into a comma-separated string."""
  res = ""
  for entry in response:
    if entry['field_id'] == field_id:
      if res != "":
        res = res + ", "
      res = res + entry['value']
      # res = res + str(turn_text_into_dropdown(entry['value'], dropdown_map))

  return res


def get_time_string(aff_str):
  """Turns an Affinity time string into dd.mm.yyyy."""
  s = aff_str[8:10] + '.' + aff_str[5:7] + '.' + aff_str[0:4]
  return s


def dump_json(name, json_object):
  """Simple print."""
  print(name)
  print(json.dumps(json_object, indent=2))
  print("")


def put_specific_field(field_value_id, value):
  """Put the changes."""
  put_url(AFFINITY_BASE + 'field-values/' + field_value_id, value)


def post_specific_field(field_id, entity_id, value):
  """Post a new field to the right place in the tables."""
  payload = {'field_id': field_id, 'entity_id': entity_id, 'value': value}

  post_url(AFFINITY_BASE + 'field-values', payload)


def post_specific_field2(field_id, entity_id, list_entry_id, value):
  """Post a new field to the right place in the tables."""
  payload = {'field_id': field_id, 'entity_id': entity_id,
             'list_entry_id': list_entry_id, 'value': value}


  post_url(AFFINITY_BASE + 'field-values', payload)
