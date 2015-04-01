# gensum
Powerful checksums generator!

Gensum is a bash script created with the intent to speed up the work of any forensic Analyst.
It recursively generates checksums (SHA1,SHA224, SHA256, SHA384,SHA512 MD5 and CRC) starting from archives (and its contents), folders, files and even strings!

Additional dependencies: unar

HELP:
	gensum 1.4β (3/30/2015), powerful multi file, multi checksum generator.
	Copyright(C) 2015 sten_gun, Nhoya  
	
	Usage: gensum.sh [options] file(s)
	
	Available Options:
	-m                          Uses MD5 checksum
	-s [1|224|256|384|512|all]              Uses SHA1|SHA256 or both checksums
	-k                          Uses CRC checksum
	-d <directory>              Calculate checksum for each file in a directory
	-z <archive>                Calculate checksum for archive and each file in it
	-t                          Calculate checksum for strings instead of files (put string as arg)
	-v                          Display script version

	

Known issues: 
- Archive function to rewrite
