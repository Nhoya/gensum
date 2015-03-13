# gensum
Powerfull checksum generator!

Gensum is a bash script created with the intent to speed up the work of any forensic Analyst generating checksumes (SHA1, SHA256, MD5) starting from an archive, folder or more then one file

Additional dependencies: unar

HELP:
	gensum 1.0 (3/13/2015), generate checksum of your files  
	Copyright(C) 2015 sten_gun, Nhoya  
	
	Usage: gensum [options] file(s)
	
	Available Options:
	-m                		Uses MD5 checksum.
	-s [1|256|all]			Uses SHA1|SHA256 or both checksums.
	-d <directory>			Calculate checksum for each file in a directory
	-z <archive>		      	Calculate checksum for archive and each file in it
	-h				Display this page
	
	
