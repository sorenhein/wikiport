#!python3

import sys
import json
import requests
from requests.auth import HTTPBasicAuth
import pprint

AFFINITY_ENDPOINT = 'https://api.affinity.co/'
AFFINITY_HEADERS = {'Content-Type': 'application/json'}
TOKEN = [line.rstrip() for line in open('key.txt', 'r')][0]

org_id = 224925965

response = \
 requests.get(AFFINITY_ENDPOINT + "field-values?organization_id=" + str(org_id), 
              auth=HTTPBasicAuth('', TOKEN), 
              headers=AFFINITY_HEADERS)
print("Return code", response.status_code, "\n")

field_id = 504135

entry = {}
for item in response.json():
  if item['field_id'] == field_id:
    entry = item
    break

pp = pprint.PrettyPrinter(indent=2)
pp.pprint(item)

response = \
  requests.get(AFFINITY_ENDPOINT + "field-value-changes?field_id=" + str(field_id), 
               auth=HTTPBasicAuth('', TOKEN), 
               headers=AFFINITY_HEADERS)
print("Return code", response.status_code, "\n")
if response.status_code != 200:
  sys.exit()

for item in response.json():

  if item['company']['id'] != org_id:
    continue
  
  pp.pprint(item)
