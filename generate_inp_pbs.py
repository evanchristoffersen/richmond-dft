""" ANHARM """

with open("{}_anharm.inp".format(), 'w') as f:
    f.write('%NProcShared={}'.format())
    f.write('%mem={}GB'.format())
    f.write('%rwf=/tmp/{}_anharm/,-1'.format())
    f.write('%chk=/tmp/{}_anharm/{}_anharm.chk'.format())
    f.write('#T B3LYP/6-311++G(2d,2p) Freq(Anharmonic) scf(tight)\n')

    f.write(' Gaussian09 anharm calc of {} using\
    B3LYP/6-311++G(2d,2p)'.format())

    f.write('{} {}'.format()) # charge and multiplicity

    f.write() # xyz coords
    f.write('\n\n')

with open("{}_anharm.pbs", 'w') as f:
    f.write('#!/bin/bash')
    f.write('#SBATCH --output="{}_anharm.out"'.format())
    f.write('#SBATCH --partition={}'.format())
    f.write('#SBATCH --nodes={}'.format())
    f.write('#SBATCH --ntasks-per-node={}'.format())
    f.write('#SBATCH --export=ALL')
    f.write('#SBATCH --time=0-{}:00:00'.format())
    f.write('#SBATCH --error={}_anharm.err'.format())

    f.write('hostname')

    f.write('# Create scratch directory here:')
    f.write('test -d /tmp/PLACEHOLDER_anharm || mkdir -v /tmp/PLACEHOLDER_anharm'.format())

    f.write('# Activate Gaussian:')
    f.write('#export g09root=/usr/local/packages/gaussian')
    f.write('#. $g09root/g09/bsd/g09.profile')
    f.write('module load gaussian')

    f.write('which g09')

    f.write('g09 < PLACEHOLDER_anharm.inp > PLACEHOLDER_anharm.out'.format())

    f.write('# Copy checkpoint file from local scratch to working directory after job completes:')
    f.write('cp -pv /tmp/PLACEHOLDER_anharm/PLACEHOLDER_anharm.chk .'.format())

    f.write('# Clean up scratch:')
    f.write('rm -rv /tmp/PLACEHOLDER_anharm'.format())

""" FREQ """

"""
%rwf=/tmp/PLACEHOLDER_freq/,-1
%chk=/tmp/PLACEHOLDER_freq/PLACEHOLDER_freq.chk
#T B3LYP/6-311++G(2d,2p) Freq(HPModes) scf(tight)  

 Gaussian09 freq calc of PLACEHOLDER using B3LYP/6-311++G(2d,2p)

"""

"""
#SBATCH --output="PLACEHOLDER_freq.out"
#SBATCH --error=PLACEHOLDER_freq.err

test -d /tmp/PLACEHOLDER_freq || mkdir -v /tmp/PLACEHOLDER_freq

g09 < PLACEHOLDER_freq.inp > PLACEHOLDER_freq.out

cp -pv /tmp/PLACEHOLDER_freq/PLACEHOLDER_freq.chk .

rm -rv /tmp/PLACEHOLDER_freq

"""

""" OPT """

"""
%rwf=/tmp/PLACEHOLDER_opt/,-1
%chk=/tmp/PLACEHOLDER_opt/PLACEHOLDER_opt.chk
#T B3LYP/6-311++G(2d,2p) OPT(Tight) scf(tight)

 Gaussian09 opt calc of PLACEHOLDER using B3LYP/6-311++G(2d,2p)

"""

"""
#SBATCH --output="PLACEHOLDER_opt.out"
#SBATCH --error=PLACEHOLDER_opt.err

test -d /tmp/PLACEHOLDER_opt || mkdir -v /tmp/PLACEHOLDER_opt

g09 < PLACEHOLDER_opt.inp > PLACEHOLDER_opt.out

cp -pv /tmp/PLACEHOLDER_opt/PLACEHOLDER_opt.chk .

rm -rv /tmp/PLACEHOLDER_opt

"""

""" HF """

"""
%rwf=/tmp/PLACEHOLDER_hf/,-1
%chk=/tmp/PLACEHOLDER_hf/PLACEHOLDER_hf.chk
#P HF/6-31g* OPT(Tight) scf(tight)

 Gaussian09 HF opt of PLACEHOLDER_hf using HF/6-31g*

"""

"""
#SBATCH --output="PLACEHOLDER_hf.out"
#SBATCH --error=PLACEHOLDER_hf.err

test -d /tmp/PLACEHOLDER_hf || mkdir -v /tmp/PLACEHOLDER_hf

g09 < PLACEHOLDER_hf.inp > PLACEHOLDER_hf.out

cp -pv /tmp/PLACEHOLDER_hf/PLACEHOLDER_hf.chk .

rm -rv /tmp/PLACEHOLDER_hf

"""
