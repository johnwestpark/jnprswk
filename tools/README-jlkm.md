Juniper License Key Management
===

OVERVIEW
---
This tool is used to automate generating and retrieving license keys.  This tool currently supports the QFX.  Future support for EX is coming soon.

USAGE
---

     --- Juniper Networks Webkit ---
           License Key Management
                 v0.0.1
            (nonprod, no-JTAC)
    
    Usage: jlkm [options]  
       -u, --user [USER-NAME]           User-Name (will prompt if omitted)
       -s, --sn [SERIAL-NUMBER]         Device Serial-Number
       -r, --rtu [RTU-NUMBER]           Right-To-Use Number
           --QFX                        Generate license for QFX Device
           --EX                         Generate license for EX Device
       -f, --file [FILE-NAME]           File containing SN and RTU
       -F, --ofile                      License key output saved in file
       -R, --retrieve                   Retrieve License Key
       -K, --keygen                     Generate License Key
     
EXAMPLES
---
### Retrieve a license key given a serial-number, output license key to screen:
    jlkm --user myname@mycompany.com --sn ABC12345

### Retrieve a license key and save it to a file
    jlkm --user myname@mycompany.com -F --sn ABC12345
> The output file will be ABC12345.license

### Retrieve many license keys using text file of serial-numbers
    jlm --user myname@mycompany.com -F --file myfile.txt

### Generate a license key for a single serial-number given a RTU
    jlkm --user me@mycorp.com --sn ABC12345 --rtu RTU12345 --QFX
> The license key will be output to the screen.  You can use the -F option to store it to file

### Generate many license keys using text file of serial-numbers and RTU
    jlkm --user me@mycorp.com --F --file myfile.txt --QFX
> This example would store each license key in separate files

DATA FILE
---
The data file used in conjunction with the --file option is a text file with each line containing a serial-number followed by a space followed by an RTU:

     ABC12345 RTU5551212
     GPDX2345 RT82376723
    <...etc...>

Any line that starts with a hash (#) will be ignored.

LICENSE
---
This SOFTWARE is licensed under the LICENSE provided in the
./LICENSE.txt file. By downloading, installing, copying, or otherwise
using the SOFTWARE, you agree to be bound by the terms of that
LICENSE.  There is no Juniper Technical Support (JTAC) offered for this SOFTWARE.


BUGS & COMMENTS:
----------------
Please give bug reports and other feedback to Jeremy Schulman, <jschulman@juniper.net>
