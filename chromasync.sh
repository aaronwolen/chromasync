#!/usr/bin/env bash

# USAGE:
# chromasync encode
# chromasync roadmap


# =============
# = variables =
# =============
encode_ftp="hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC"
roadmap_ftp="ftp.ncbi.nlm.nih.gov/pub/geo/DATA/roadmapepigenomics/by_experiment"

# Spreadsheet containing list of files to sync
filelist="https://docs.google.com/spreadsheet/pub?key=0An_O4LjjAhYRdElhVG9QYkJOeE5hdGxzNGNPSkRuZnc&single=true&gid=##&output=txt"

# Local directory in which files will be stored
destdir=/home/chromatin/$1


# =============
# = functions =
# =============

# check_installed
#################
# Verify a dependency is installed. If it is, return its location, otherwise thrown an error. 
function check_installed {
  command -v $1 2>&1 || { 
    echo >&2 "I require foo but it's not installed.  Aborting."; exit 1; 
  }
}


# make_jobname
##############
# Create unique qsub jobnames based on a filename and an optional prefix
function make_jobname {
  
  filename=""
  maxlength=14
  
  # Add prefix
  if [ ! -z "$2" ]; then
    
    # Ensure prefix doesn't exceed maximum allowed length}
    if [ ${#2} -gt $maxlength ]; then
      echo "Prefix must be less than $maxlength characters"
      exit 1;
    fi
    
    filename="$2-"
  fi
  
  # Number of characters available
  openchars=$(( $maxlength - ${#filename} ))
  
  # Abbreviate input filename
  abbrvfile=$(basename ${1%.*} | sed 's/[^a-zA-Z0-9]//g')
  abbrvfile=$(echo ${abbrvfile:0:$openchars})

  echo $filename$abbrvfile
}


# ================
# = perform sync =
# ================

# Choose repository
if [ "$1" == encode ]; then
  repo=$encode_ftp
  filelist=$(echo $filelist | sed 's/##/0/')
elif [ "$1" == roadmap ]; then
  repo=$roadmap_ftp
  filelist=$(echo $filelist | sed 's/##/2/')
else  
  echo You must specify either 'roadmap' or 'encode'.
  exit 1;
fi
  
# Download filelist
curl --silent $filelist > $destdir/inventory.txt

rsync --times --log-file=$destdir/rsync.log --files-from=$destdir/inventory.txt --group=reimers --chmod=a+rwx,g+r,o+r rsync://$repo $destdir


# ======================================
# = convert wig files to bigWig format =
# ======================================

fetchChromSizes=$(check_installed fetchChromSizes)
wigToBigWig=$(check_installed wigToBigWig)


# Obtain chromosome sizes (creates a tmpi folder in ~)
mkdir --parents $TMPDIR
chrsizes="$(mktemp)"
$fetchChromSizes hg19 > $chrsizes
  
wigs=( $(find $destdir -name "*.wig.gz") )

for wigfile in "${wigs[@]}"; do
  convert=0
  
  # Check if bigwig file exists and if it is older than wig
  bigwigfile=${wigfile%.wig.gz}.bigWig

  if [ ! -f "$bigwigfile" ]; then
    convert=1
  elif [ "$wigfile" -nt "$bigwigfile" ]; then
    convert=1
  fi

  # Convert wig to bigwig
  if [ $convert -eq 1 ]; then
    qsub_cmd="$wigToBigWig $wigfile $chrsizes $bigwigfile"
    jobname=$( make_jobname $wigfile w2bw )
    
    echo $qsub_cmd | qsub -N $jobname
  fi

done

