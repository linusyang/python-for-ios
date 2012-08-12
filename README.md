Python for iOS
========

Script written by Linus Yang <laokongzi@gmail.com>  
Licensed under GPLv3

Script for building Python 2.6 and above with iOS SDK. **IPv6 support is enabled.**  
*Get built Debian Packages at https://code.google.com/p/yangapp/downloads/list*

##Current supported Python version to be built:
     2.6.5, 2.7.2, 2.7.3

##Depends:
* Mac OS X and iOS SDK
* Dedian Package Tool 'dpkg-deb' (*optional*)

##Usage:
* Change build.command permission to be executable and double click it to build.
* Or you can specify the version by argument in terminal:
    
    chmod +x build.command
    ./build.command [Python Version] [Debian Package Build #]

##Current Module Status:

###2.6
    Failed to find the necessary bits to build these modules:
    _hashlib           bsddb185           dl              
    gdbm               imageop            linuxaudiodev   
    ossaudiodev        spwd               sunaudiodev     
    To find the necessary bits, look in setup.py in detect_modules() for the module's name.
    

###2.7
    Python build finished, but the necessary bits to build these modules were not found:
    _tkinter           bsddb185           dl              
    gdbm               imageop            linuxaudiodev   
    nis                ossaudiodev        spwd            
    sunaudiodev                                           
    To find the necessary bits, look in setup.py in detect_modules() for the module's name.

##Reference:
* http://randomsplat.com/id5-cross-compiling-python-for-embedded-linux.html
* https://github.com/cobbal/python-for-iphone

