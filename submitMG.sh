#! /bin/bash

printf "###########################################\n"
printf "##   Run Delphes for samples %-12s##\n" "$1"
printf "###########################################\n"


SAMPLE="$1"
N="$2"
SAMPLEN="${SAMPLE}_${N}"
FINALOUTFILES="*.root"

DBG=2
JOBLOGFILES="myout.txt myerr.txt"
BASEDIR="/mnt/t3nfs01/data01/shome/pbaertsc/tauregression/CMSSW_8_0_23/src/MG5_aMC_v2_5_5"
JOBDIR="submitMG"

WORKDIR=/scratch/$USER/$JOBDIR/$SAMPLEN
OUTDIR=$WORKDIR/$SAMPLE/Events/$SAMPLEN # where OUTFILES are generated
RESULTDIR=$BASEDIR/$JOBDIR
REPORTDIR=$BASEDIR/$JOBDIR
FINALRESULTDIR=/scratch/$USER/DrellYan

CARDS="run pythia8 delphes"
CARDDIR="$BASEDIR/myCards"


##### MONITORING/DEBUG INFORMATION ########################################

mkdir -p /mnt/t3nfs01/data01/shome/pbaertsc/tauregression/CMSSW_8_0_23/src/MG5_aMC_v2_5_5/submitMG/
#$ -e /mnt/t3nfs01/data01/shome/pbaertsc/tauregression/CMSSW_8_0_23/src/MG5_aMC_v2_5_5/submitMG/
#$ -o /mnt/t3nfs01/data01/shome/pbaertsc/tauregression/CMSSW_8_0_23/src/MG5_aMC_v2_5_5/submitMG/

DATE_START=`date +%s`
echo "Job started at " `date`
cat <<EOF

###########################################
##       QUEUEING SYSTEM SETTINGS:       ##
###########################################
  HOME=$HOME
  USER=$USER
  JOB_ID=$JOB_ID
  JOB_NAME=$JOB_NAME
  HOSTNAME=$HOSTNAME
  TASK_ID=$TASK_ID
  QUEUE=$QUEUE
EOF

if test 0"$DBG" -gt 0; then
    echo " "
    echo "###########################################"
    echo "##         Environment Variables         ##"
    echo "###########################################"
    env
fi



##### SET ENVIRONMENT #####################################################

if test -e "$WORKDIR"; then
   echo "ERROR: WORKDIR ($WORKDIR) already exists!" >&2
   echo "ls $TOPWORKDIR"
   echo `ls $TOPWORKDIR` >&22
   echo "ls $WORKDIR"
   echo `ls $WORKDIR` >&2
   #exit 1
fi
mkdir -p $WORKDIR
if test ! -d "$WORKDIR"; then
   echo "ERROR: Failed to create workdir ($WORKDIR)! Aborting..." >&2
   exit 1
fi
export PYTHIA8DATA=/shome/pbaertsc/tauregression/CMSSW_8_0_23/src/MG5_aMC_v2_5_5/HEPTools/pythia8/share/Pythia8/xmldoc/

cat <<EOF

###########################################
##             JOB SETTINGS:             ##
###########################################
  STARTDIR=$STARTDIR
  BASEDIR=$BASEDIR
  WORKDIR=$WORKDIR
  RESULTDIR=$RESULTDIR
  REPORTDIR=$REPORTDIR
  FINALRESULTDIR=$FINALRESULTDIR
EOF



echo " "
echo "###########################################"
echo "##         MY FUNCTIONALITY CODE         ##"
echo "###########################################"

cd $WORKDIR
source $VO_CMS_SW_DIR/cmsset_default.sh >&2

# make process dir
echo "\
$BASEDIR/bin/mg5_aMC $CARDDIR/${SAMPLE}_proc_card.dat >> myout.txt 2>> myerr.txt"
$BASEDIR/bin/mg5_aMC $CARDDIR/${SAMPLE}_proc_card.dat >> myout.txt 2>> myerr.txt

# copy cards
for CARD in $CARDS; do
  echo "cp $CARDDIR/${SAMPLE}_${CARD}_card.dat $WORKDIR/$SAMPLE/Cards/${CARD}_card.dat"
  cp $CARDDIR/${SAMPLE}_${CARD}_card.dat $WORKDIR/$SAMPLE/Cards/${CARD}_card.dat
done



echo "ls"
ls

# generate events
echo "\
$WORKDIR/$SAMPLE/bin/generate_events -f ${SAMPLEN} >> myout.txt 2>> myerr.txt"
$WORKDIR/$SAMPLE/bin/generate_events -f ${SAMPLEN} >> myout.txt 2>> myerr.txt

# rename output
cd $OUTDIR
echo "\
rename _events "" *.root"
rename _events "" *.root
echo "\
rename $SAMPLE $SAMPLEN *.root"
rename $SAMPLE $SAMPLEN *.root

##### RETRIEVAL OF OUTPUT FILES AND CLEANING UP ###########################

cd $WORKDIR
if test 0"$DBG" -gt 0; then
    echo " " 
    echo "###########################################################"
    echo "##   MY OUTPUT WILL BE MOVED TO \$RESULTDIR and \$OUTDIR   ##"
    echo "###########################################################"
    echo "  \$RESULTDIR=$RESULTDIR"
    echo "  \$REPORTDIR=$REPORTDIR"
    echo "  Working directory contents:"
    echo "  pwd: " `pwd`
    find -maxdepth 3 -ls #ls -Rl
    ls $OUTDIR
fi

cd $WORKDIR
if test x"$JOBLOGFILES" != x; then
    mkdir -p $REPORTDIR
    if test ! -e "$REPORTDIR"; then
        echo "ERROR: Failed to create $REPORTDIR ...Aborting..." >&2
        exit 1
    fi
    for n in $JOBLOGFILES; do
        echo ">>> copying $n"
        if test ! -e $WORKDIR/$n; then
            echo "WARNING: Cannot find output file $WORKDIR/$n. Ignoring it" >&2
        else
            cp -a $WORKDIR/$n $REPORTDIR/${SAMPLEN}_$n
            if test $? -ne 0; then
                echo "ERROR: Failed to copy $WORKDIR/$n to $REPORTDIR/${SAMPLEN}_$n" >&2
            fi
    fi
    done
fi

cd $OUTDIR
for j in `ls $FINALOUTFILES`; do
    echo ">>> copying $OUTDIR/$j to $FINALERESULTDIR/$j"
    cp -a $OUTDIR/$j $FINALRESULTDIR/$j >&2
done


echo "Cleaning up $WORKDIR"
rm -rf $WORKDIR



###########################################################################

DATE_END=`date +%s`
RUNTIME=$((DATE_END-DATE_START))
echo " "
echo "#####################################################"
echo "    Job finished at " `date`
echo "    Wallclock running time: $(( $RUNTIME / 3600 )):$(( $RUNTIME % 3600 /60 )):$(( $RUNTIME % 60 )) "
echo "#####################################################"
echo " "

exit 0
