Python for iOS
========

Script written by Linus Yang <laokongzi@gmail.com>  
Licensed under GPLv3

Script for building Python 2.7.6 with iOS SDK (with IPv6 support, gevent, pyOpenSSL and M2Crypto).
*Get built Debian Packages at https://code.google.com/p/yangapp/downloads/list*

##Depends:
* Mac OS X and iOS 5.1 SDK

##Usage:
Change build.sh permission to be executable and run the script in terminal:    
    
```bash
chmod +x build.sh   
./build.sh
```

##Current Module Status:
```
Python build finished, but the necessary bits to build these modules were not found:
_tkinter           bsddb185           dl              
gdbm               imageop            linuxaudiodev   
nis                ossaudiodev        spwd            
sunaudiodev                                           
To find the necessary bits, look in setup.py in detect_modules() for the module's name.
```

##Reference:
* http://randomsplat.com/id5-cross-compiling-python-for-embedded-linux.html
* https://github.com/cobbal/python-for-iphone
* http://www.trevorbowen.com/2013/10/07/cross-compiling-python-2-7-5-for-embedded-linux/
