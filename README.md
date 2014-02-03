Python for iOS
========
by Linus Yang

##Features
* Only for jailbroken devices, better than sandboxed version in App Store
* Updated to latest Python 2.7.x branch
* Fully functional, dynamically linking iOS port
* Built-in modules __mostly working__ (_See building module status below_)
* IPv6 support
* Packages with several basic site packages:
    * setuptools (`easy_install`)
    * gevent
    * PyCrypto
    * pyOpenSSL
    * M2Crypto
* Works with on-device toolchains to build native Python libraries:
    * iPhone GCC toolchain from Cydia/Telesphoreo (__recommended__, directly working)
    * Clang toolchain by @coolstarorg at thebigboss repo (__need to create a symlink__ by `ln -s clang /usr/bin/arm-apple-darwin9-gcc`)

__Get latest built Debian Packages at [Release Site](https://github.com/linusyang/python-for-ios/releases).__

##Build Guide:
You may need Mac OS X and iOS 5.1 SDK for building armv6 binaries.

Change build.sh permission to be executable and run the script in terminal:    
    
```bash
chmod +x build.sh   
./build.sh
```

##Building Module Status:
```
Python build finished, but the necessary bits to build these modules were not found:
_tkinter           bsddb185           dl              
gdbm               imageop            linuxaudiodev   
nis                ossaudiodev        spwd            
sunaudiodev                                           
To find the necessary bits, look in setup.py in detect_modules() for the module's name.
```

##References:
* http://randomsplat.com/id5-cross-compiling-python-for-embedded-linux.html
* https://github.com/cobbal/python-for-iphone
* http://www.trevorbowen.com/2013/10/07/cross-compiling-python-2-7-5-for-embedded-linux/

##License
This project is licensed under GPLv3.
