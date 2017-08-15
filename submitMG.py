#! /usr/bin/env python
#
# Creating dir:
#   uberftp t3se01.psi.ch 'mkdir /pnfs/psi.ch/cms/trivcat/store/user/ineuteli/samples/LowMassDiTau_madgraph'
#
# Multicore jobs:
#   to submit multicore job:    qsub -pe smp 8 ...
#   in mg_configuration.txt:    run_mode=2 # multicore
#                               nb_core=8
#   note it might wait longer in queue
# 
# Luca vs. Izaak
#   https://www.diffchecker.com/JSVEi5qL

import os, sys
import subprocess
import time


WORKPATH        = "/mnt/t3nfs01/data01/shome/pbaertsc/tauregression/CMSSW_8_0_23/src/MG5_aMC_v2_5_5"
samples         = ["DrellYan"]
n_cores         = 1
arguments           = [ ]
test_indices        = [40,41]
signal_indices      = range( 33+1, 34+1 ) # start from 1-10, 11-20, 21-40 



def main():
    print " "
    
    indices = test_indices
    #indices = signal_indices
    # ensure directory
    REPORTDIR = "%s/submitMG"%(WORKPATH)
    if not os.path.exists(REPORTDIR):
        os.makedirs(REPORTDIR)
        print ">>> made directory " + REPORTDIR

    
    for sample in samples:
        for index in indices:
            jobname = "%s_%d"%(sample,index)
            command = "qsub -q all.q -N %s submitMG.sh %s %s" % (jobname,sample,index)
            print "\n>>> " + command.replace(jobname,"\033[;1m%s\033[0;0m"%jobname,1)
            sys.stdout.write(">>> ")
            sys.stdout.flush()
            os.system(command)
        
    print ">>>\n>>> done\n"



def printColums(list):
    N = len(list)
    if N%4: list.extend( [" "]*(4-N%4) ); N = len(list)
    for row in zip(list[:N/4],list[N/4:N/2],list[N/2:N*3/4],list[N*3/4:]):
        print ">>> %18s %18s %18s %18s" % row



def proceed(prompt=">>> proceed?",proceed_message=">>> proceding...",stop_message=">>> stop"):
    proceed = False
    while True:
        answer = raw_input(prompt+" (y or n) ").lower()
        if answer.lower() in [ 'y', 'ye', 'yes', 'yeah', 'yep', 'jep' ]:
            print proceed_message
            proceed = True
            break
        elif answer.lower() in [ 'n', 'no', 'na', 'nah', 'nee', 'neen', 'nop' ]:
            print stop_message
            proceed = False
            break
        else:
            print ">>> incorrect input"
            continue
    return proceed



if __name__ == '__main__':
    main()


