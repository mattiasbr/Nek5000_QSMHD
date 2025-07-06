#!/bin/bash
# script to compile Nek5000
SETUP=duct

# commands
cp_cmd="cp -v"
mv_cmd="mv -v"
rm_cmd="rm -vf"

# paths
NEK_HOME=$HOME/Nek5000
NEK_LOCAL=$(pwd)/Nek5000
# modified and QSMHDT source files
MOD_SRC=$(pwd)/nek_src/core
QSMHD_SRC=$(pwd)/src
export MOD_FILES="$(ls $MOD_SRC)"
export QSMHD_FILES="$(ls $QSMHD_SRC)"

# arguments
args=("$@")
argsnr=$#

case "${args[0]}" in
    all)
# create local source copy
	mkdir -p ${NEK_LOCAL}
	${cp_cmd} -rfp ${NEK_HOME}/core ${NEK_LOCAL}/
	${cp_cmd} -rfp ${NEK_HOME}/3rd_party ${NEK_LOCAL}/
	mkdir -p ${NEK_LOCAL}/bin
	${cp_cmd} -rfp ${NEK_HOME}/bin/nekconfig ${NEK_LOCAL}/bin/
	${cp_cmd} -rfp ${NEK_HOME}/bin/makenek ${NEK_LOCAL}/bin/
	
# copy modified and new files
        for i in ${MOD_FILES}; do
            ${cp_cmd} ${MOD_SRC}/${i} ${NEK_LOCAL}/core/
        done
        for i in ${QSMHD_FILES}; do
            ${cp_cmd} ${QSMHD_SRC}/${i} ${NEK_LOCAL}/core/
        done

# switch the source root to the local version
    	export NEK_SOURCE_ROOT=${NEK_LOCAL}

# compile the code
        ${NEK_LOCAL}/bin/makenek ${SETUP} ./${NEK_LOCAL}/core
        ;;

    clean)
# clean 
	${rm_cmd} -r ${NEK_LOCAL} ./obj
        ${rm_cmd} ./nek5000 ./makefile ./build.log ${SETUP}.o ${SETUP}.f libnek5000.a .state
        ;;
    *) echo 'Wrong option'
        ;;
esac
