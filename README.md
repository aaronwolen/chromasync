Chromatin repository syncing
============================

This script is used to sync chromatin modification data from the ENCODE and RoadMap projects to servers at VIPBG.


Installation
------------
Use git to clone this repository and from within the `chromasync` directory create a symbolic link to `~/bin` or some other location in your `$PATH`.

```bash 
git clone git@github.com:aaronwolen/chromasync.git
cd chromasync
chmod +x chromasync
ln -s $PWD/chromasync.sh ~/bin/chromasync
```

Alternatively, you could just [download this repository][repozip], decompress it and just run the script:

```bash
cd chromasync
sh chromasync encode
```


Selecting files to sync
-----------------------
To sync a file from ENCODE or RoadMap its URL must be added to the appropriate worksheet tab in [this Google Spreadsheet][spreadsheet]. The URL should be relative to the base URLs listed below:

* **ENCODE**: hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC
* **RoadMap**: ftp.ncbi.nlm.nih.gov/pub/geo/DATA/roadmapepigenomics/by_experiment

Empty rows may be inserted in the spreadsheet to provide some separation between different types of files. 

Synced files are located in either `/home/chromatin/encode` or `/home/chromatin/roadmap`. A running inventory (`inventory.txt`) of all synced files is automatically maintained in each directory. These files can easily parsed to extract the locations for files of interest.  


wig to bigWig conversion
------------------------
Synced files ending in `.wig.gz` are assumed to be compressed wig files and will be converted to bigWig format if an existing bigWig file is older or does not exist. Conversions are submitted as jobs to PBS via `qsub`. 

In order for conversions to take place `wigToBigWig` and `fetchChromSizes` must be installed. Both programs can be obtained from [here][ucsctools].


[roadmap]: http://www.roadmapepigenomics.org/
[encode]: http://genome.ucsc.edu/ENCODE/
[ucsctools]: http://hgdownload.cse.ucsc.edu/admin/exe/
[repozip]: https://github.com/aaronwolen/chromasync/archive/master.zip
[spreadsheet]: https://docs.google.com/a/mymail.vcu.edu/spreadsheet/ccc?key=0An_O4LjjAhYRdElhVG9QYkJOeE5hdGxzNGNPSkRuZnc




