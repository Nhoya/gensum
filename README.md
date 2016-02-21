# gensum
Powerful checksum generation helper!

Gensum is a bash script created with the intent to speed up the work of any forensic Analyst.
It recursively generates checksums starting from archives (and its contents), folders, files and even strings, and these hashes can be saved inside a file with the following format

	hash filename

Additional dependencies: unar
Usage

	Copyright(C) 2015 sten_gun, Nhoya  
	
	Usage: gensum.sh [options] file(s)
	
	Available Options:
    	-m                        		Uses MD5 checksum
    	-s [1| 224| 256| 384| 512 |all]	Uses SHA1|SHA224|SHA256|SHA384|SHA512 or all.
    	-c <checfile> <file>      		Specifies a file for checksum check
    	-k                        		Uses CRC checksum
    	-d <directory>            		Calculate checksum for files inside a directory.
    	-z <archive>              		Calculate checksum for an archive and its contents.
    	-t <string>               		Calculate checksum for strings instead of files.
    	-o <outfile>              		Writes output to outfile."
    	-v                        		Display script version
    	-h                        		Display this page

