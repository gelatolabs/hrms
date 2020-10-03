import json
from random import randint, randrange

# Backend Game Functions for:
#
# "Human Resources Manglement Software"
# A Gelato Labs production for Ludum Dare 47
#
# Backend code by Matthew Petry (fireTwoOneNine)
# Makes use of pdfTeX by The pdfTeX Team (Hàn Thế Thành et al), licensed under GPL (see LICENSE.pdftex file)
#
# All original code under the ISC license (see COPYING for details)

def getNoun(l):
  with open("datasets/nouns_"+l+".txt") as nounfile:
    for i, line in enumerate(nounfile, 2):
      if randrange(i): continue
      noun = line.strip("\n")
    return noun


def generateName():
  fnamenum = randint(1, 2718)
  with open("datasets/f_names.txt") as fnamefile:
    for i, line in enumerate(fnamefile):
      if i == fnamenum:
        fname = line.strip("\n")
  lname = getNoun(fname[0])

  return (fname + " " + lname)


def generateAddress():
  roadtypes = ["Lane","Road","Circle","Blvd","Street"]
  roadtype = roadtypes[randint(0,4)]
  housenumber = randint(1,999)
  roadname = getNoun(roadtype[0])
  return (str(housenumber) + " " + roadname + " " + roadtype)
  
  

print(generateName())
print(generateAddress())
