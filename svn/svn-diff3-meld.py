#!/usr/bin/env python
# svn merge-tool python wrapper for meld

import sys
import subprocess

try:
   # path to meld
   meld = "/usr/bin/meld"

   # file paths
   # Subversion provides the paths we need as the last three parameters.
   theirs = sys.argv[-1]
   base   = sys.argv[-2]
   mine   = sys.argv[-3]
  
   # the call to meld
   cmd = [meld, base, mine, theirs]

   # Call meld, making sure it exits correctly
   subprocess.check_call(cmd)

except:
   print "Oh noes, an error!"
   # print error info
   print "Error: ", sys.exc_info()[0]
   sys.exit(-1)
