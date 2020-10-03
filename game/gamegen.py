import json
from random import randint

# Backend Game Functions for:
#
# "Human Resources Manglement Software"
# A Gelato Labs production for Ludum Dare 47
#
# Backend code by Matthew Petry (fireTwoOneNine)
# Makes use of pdfTeX by The pdfTeX Team (Hàn Thế Thành et al), licensed under GPL (see LICENSE.pdftex file)
#
# All original code under the ISC license (see COPYING for details)

def getNoun():
  nounnum = randint(1, 6797)
  with open("datasets/nouns.txt") as nounfile:
    for i, line in enumerate(nounfile):
        if i == nounnum:
            return line.strip("\n")


def generateName():
  fnamenum = randint(1, 2718)
  with open("datasets/f_names.txt") as fnamefile:
    for i, line in enumerate(fnamefile):
        if i == fnamenum:
            fname = line.strip("\n")
  lname = getNoun()

  return (fname + " " + lname)


def generateAddress():
  roadtypes = ["Lane","Road","Circle","Blvd","Street"]
  roadtype = roadtypes[randint(0,4)]
  housenumber = randint(1,999)
  roadname = getNoun()
  return (str(housenumber) + " " + roadname + " " + roadtype)
  
  

print(generateName())
print(generateAddress())