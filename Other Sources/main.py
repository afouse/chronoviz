#
#  main.py
#  asdfasdf
#
#  Created by Bill Bumgarner on 11/24/07.
#  Copyright __MyCompanyName__ 2007. All rights reserved.
#

#import modules required by application
import objc
try:
    import Foundation
except:
    print "handled foundation exception"

try:
    import AppKit
except:
    print "handled appkit exception"


try:
    from PyObjCTools import AppHelper
except:
    print "handled PyObjCTools exception"

