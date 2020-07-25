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


api.make_cached_fields_file()

