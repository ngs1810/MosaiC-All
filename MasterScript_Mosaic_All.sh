#!/bin/bash
# MasterScript: Phase 1 of mosaic variant finding pipeline, which includes
# 1. Coverage Analysis of every bam file
# 2. GATK-HC: germline variant calling in each family
# 3. Mutect2 and FilterMutect2: Parents,Probands and Siblings (if available)
# 4. MosaicHunter: Parents,Probands and Siblings (if available)
# 5. MosaicForecast on Mutect2 variant callset, followed by Filter
# UniAdelaide-HPC friendly
# Date: 9th June 2023
# trying other git commands

## Define Directories##
SCRIPTDIR="/hpcfs/groups/phoenix-hpc-neurogenetics/Nandini/Mosaic-All"
#SCRIPTDIR="/hpcfs/groups/phoenix-hpc-neurogenetics/scripts/git/neurocompnerds/Mosaic-All"
LOGDIR="/hpcfs/users/${USER}/Mosaic_log"

if [ ! -d "${logDir}" ]; then
    mkdir -p ${logDir}
    echo "## INFO: New log directory created, you'll find all of the log information from this pipeline here: ${logDir}"
fi

usage()
{
echo "#MasterScript: Phase 1 of mosaic variant finding pipeline, which includes
# 1. Coverage Analysis of every bam file
# 2. GATK-HC: germline variant calling in each family
# 3. Mutect2: Parents and Probands and Siblings (if available)
# 4. MosaicHunter: Parents and Probands and Siblings (if available)
# 5. MosaicForecast on Mutect2 variant callset
#
#
# Usage $0 -p file_prefix -s sampleID.list -o $Output.folder -r $ReferenceGenomewithDirectory -p $PON | [ - h | --help ]
#
# Options
#-s REQUIRED sampleID.list (tab-delimited columns $BAMdir,$ProbandID,$Gender,$Mother,$Father)
#-o REQUIRED Output directory (all variant calls_output in a single output directory)
#-r REQUIRED Referencegenome (i.e /hpcfs/groups/phoenix-hpc-neurogenetics/RefSeq/hs37d5.fa)
#-p OPTIONAL PanelOfNormal (i.e /gpfs/users/a1149120/GA_Mutect2_ReCalling/PON)
# -h or --help  Prints this message.  Or if you got one of the options above wrong you'll be reading this too!
#
# Original: Nandini Sandran, 9/6/2023
# Modified: (Date; Name; Description)
# 
#
#
"
}

## Set Variables ##
while [ "$1" != "" ]; do
        case $1 in
                -s )                    shift
                                        SAMPLEID=$1
                                        ;;
               	-o )                    shift
                                        OUTDIR=$1
                                        ;;
                -r )                    shift
                                        REFGEN=$1
                                       	;;
                -p )                    shift
                                        PONDIR=$1
                                        ;;
                * )                     usage
                                        exit 1
        esac
        shift
done

#Define variables from SAMPLEID list file
Proband=
ProbandGender=
Mother=
Father=

#CHeck if singleton or Trios


# VARIANT CALLER 1: MOSAICHUNTER

## Part1:Variant Calling

### MosaicHunter variant calling in probands for Trios:
sbatch $SCRIPTDIR/MosaicHunter_WES_Trio_GA.sh -s $Proband -b $BAM -d $OUTDIR -g $ProbandGender -r $REFGEN

### MosaicHunter variant calling in probands for Singleton:
sbatch $SCRIPTDIR/MosaicHunter_WES_Trio_GA.sh -s $Proband -b $BAM -d $OUTDIR -g $ProbandGender -r $REFGEN

### FATHER
sbatch $SCRIPTDIR/MosaicHunter_WES_Singlemode_GA.sh -s $Father -b $BAM -d $OUTDIR -g M -r $REFGEN

### MOTHER
sbatch $SCRIPTDIR/MosaicHunter_WES_Singlemode_GA.sh -s $Mother -b $BAM -d $OUTDIR -g F -r $REFGEN

## Part2: Check and Record the status based on SlurmOutput

## Part3: Accumulate the variants in meta-file, that contains all other samples





#VARIANT CALLER 2: MUTECT2
## Part1: Check if PON db contains the sample, or else use the other PON

## Part2: Variant Calling
### Execute Mutect2 for all members in a family
for Sample in $Proband, $Sibling, $Father, $Mother; do
MUT='sbatch Mutect2.singlemode.sh -b $BAM -m $MUTDIR -s $Sample -d $OUTDIR -r $REF'
done

## Part3: Filter Mutect2
#>>>>only after Mutect2 is completed
for Sample in $Proband, $Sibling, $Father, $Mother; do
sbatch --export=ALL --dependency=afterok:${MUT} 

## Part4: Check the slurm and Record variant frequency

## Part5: Accumulate the variants in meta-file, that contains all other samples

#VARIANT CALLER 3: MOSAICFORECAST
#>>>>This has to be executed only after Mutect2 is completed
## Part1:Preprocess
sbatch --export=ALL --dependency=afterok:${MUT} 

## Part2:Extract features

## Part3:Genotype

## Part4:Filter

## Part5: Check slurm and record

## Part6: Accumulate the variants in meta-file, that contains all other samples

#VARIANT CALLER 4: GATK HC
## Part1: Variant calling

## Part2: gatherVCFs of each sample



#COVERAGE ANALYSIS







MUT_Pro='sbatch Mutect2.singlemode.sh -b $BAM -m $MUTDIR -s $Proband -d $OUTDIR -r $REF'
### Execute Mutect2 for sibling
MUT_Sib='sbatch Mutect2.singlemode.sh -b $BAM -m $MUTDIR -s $Sibling -d $OUTDIR -r $REF'
### Execute Mutect2 for father
MUT_Fa='sbatch Mutect2.singlemode.sh -b $BAM -m $MUTDIR -s $Father -d $OUTDIR -r $REF'
### Execute Mutect2 for mother
MUT_Mo='sbatch Mutect2.singlemode.sh -b $BAM -m $MUTDIR -s $Mother -d $OUTDIR -r $REF'