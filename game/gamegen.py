import json
import os
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
    for i, line in enumerate(nounfile, 1):
      if randrange(i): continue
      noun = line.strip("\n")
    return noun

def getBadTrait():
  btnum = randint(1, 177)
  with open("datasets/badtraits.txt") as btfile:
    for i, line in enumerate(btfile):
        if i == btnum:
            return line.strip("\n")

def getGoodTrait():
  gtnum = randint(1, 137)
  with open("datasets/goodtraits.txt") as gtfile:
    for i, line in enumerate(gtfile):
        if i == gtnum:
            return line.strip("\n")

def getGoodSkill():
  csnum = randint(1,45)
  tsnum = randint(1,16)
  if randint(0,1):
      with open("datasets/comm_skills.txt") as csfile:
        for i, line in enumerate(csfile):
            if i == csnum:
                return line.strip("\n")
  else:
      with open("datasets/tech_skills.txt") as tsfile:
        for i, line in enumerate(tsfile):
            if i == tsnum:
                return line.strip("\n")

def getBadSkill():
  bsnum = randint(1, 13)
  with open("datasets/bad_skills.txt") as bsfile:
    for i, line in enumerate(bsfile):
        if i == bsnum:
            return line.strip("\n")

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
  
def generateTraits():
  traits = []
  goodness = 0
  traitmultiplier = randint(1,10)
  for i in range(1,randint(3,8)):
    if traitmultiplier * randint(0,10) > 32:
        traits.append(getGoodTrait())
        goodness = goodness + 1
    else:
        traits.append(getBadTrait())
        goodness = goodness - 1
  return traits,goodness
  
def generateSkills(goodness):
  skills = []
  traitmultiplier = 20 + (goodness * 5)
  for i in range(1,randint(3,8)):
    if traitmultiplier * randint(1,6) > 12:
        skills.append(getGoodSkill())
    else:
        skills.append(getBadSkill())
  return skills
  
def generateResumeEmail(name, address,guid):
  emailID = str(randint(3,3000))
  os.mkdir("../../etc/users/"+guid+"/emails/"+emailID)
  with open("../../etc/users/"+guid+"/emails/"+emailID+"/sender", "w+", encoding="utf-8") as f:
        f.write(name)  
  with open("../../etc/users/"+guid+"/emails/"+emailID+"/subject", "w+", encoding="utf-8") as f:
        f.write("Job Application") 
  with open("../../etc/users/"+guid+"/emails/"+emailID+"/body", "w+", encoding="utf-8") as f:
        f.write("<object class=\"objectembed\" data=\"/etc/users/"+guid+"/emails/"+emailID+"/attachment.pdf\" width=\"100%\" height=\"100%\" type=\"application/pdf\" style=\"margin: 0\" title=\"\">") 
  texText = ""
  with open("datasets/tex-templates/basic.tex", "r+", encoding="utf-8") as f:
        texText = f.read()
  texText = texText.replace("<<name>>", name)
  texText = texText.replace("<<address>>", address)
  
  with open("../../etc/users/"+guid+"/emails/"+emailID+"/attachment.tex", "w+", encoding="utf-8") as f:
        f.write(texText)
  os.system("cd ../../etc/users/"+guid+"/emails/"+emailID+" && pdflatex attachment.tex")

name = generateName()
address = generateAddress()
guid = "12345abcd"
print(name)
print(address)
traitobject = generateTraits()
print(traitobject[0])
print("Goodness of person is " + str(traitobject[1]))
print(generateSkills(traitobject[1]))
generateResumeEmail(name,address,guid)