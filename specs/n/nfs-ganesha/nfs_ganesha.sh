#!/bin/bash

VOLNAME=
CONF=
IP=
LOG=
DBGLVL=
OPT=
FILE1=

trap    cleanup   SIGHUP SIGINT SIGTERM


        if [ $EUID -ne 0 ];  then
                echo "You have to be root to run this script"
                exit 1
        fi


function usage {
        echo " Usage : nfs-ganesha.sh [-l <logfile>][-n <dbg_lvl>] -v <volname> -i <ganesha_host_ip> -f <config_file> -o <start|stop>
               [-h]                    display this help
               [-l <logfile>]          set the logfile for the daemon
               [-n <dbg_lvl>]          set the verbosity level
	       dbg_lvl options        NIV_NULL, NIV_MAJ, NIV_CRIT, NIV_EVENT, NIV_DEBUG, NIV_MID_DEBUG, NIV_FULL_DEBUG 
               -v <volname>            name of the volume to be exported
               -i <ganesha_host_ip>    IP of the ganesha host
               -f <config_file>        set the config file to be used
               -o <start|stop>         start or stop ganesha server
                ===========Default Values=============
                LogFile    : /tmp/nfs-ganesha.log
                DebugLevel : NIV_EVENT"
        }

while getopts "hf:i:l:n:v:o: -l help" OPTION
           do
             case $OPTION in
                     f) CONF=$OPTARG
                     ;;
                     i) IP=$OPTARG
                     ;;
                     l) LOG=$OPTARG
                     ;;
                     n) DBGLVL=$OPTARG
                     ;;
                     h) usage 
			exit 1
                     ;;
                     v) VOLNAME=$OPTARG
                     ;;
                     o) OPT=$OPTARG
                     ;;
             esac
     done


function cleanup ()
{
	if [ -f /tmp/old-ganesha.conf ] 
	then  cp /tmp/old-ganesha.conf $CONF 
	exit 1
	fi 
}


function check_for_stop()
{
	if  echo $OPT | grep -i -q  "stop" 
	then stop_ganesha
	fi
}

function check_usage()
{

     if [ "$VOLNAME" = "" ]
     then
             usage
             exit 1
     fi
     if [ "$CONF" = "" ]
     then
             usage
             exit 1
     fi
     if [ "$IP" = "" ]
     then
             usage
     exit 1
     fi
     if [ "$OPT" = "" ]
     then
             usage
     exit 1
     fi
}
function check_ip {
        if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo "Invalid  IP , please enter the correct IP of the ganesha host."
                usage
                exit 1
        fi
}


function check_volname
{
        if ! ls /var/lib/glusterd/vols | grep -q "$VOLNAME" ;  then
                echo "Volume doesn't exist. Please enter a  valid volume name."
                exit 1
        fi
}

function check_conf


{

        if ! [ -f "$CONF" ]; then
                echo "The config_file $CONF doesn't exist."
                usage
                exit 1
        else
                if ! [ -s "$CONF" ]; then
                        echo "The cofig_file $CONF is empty "
                        exit 1
                fi
        fi
}

function  check_option
{
        if ! echo $OPT | grep -i  -q  -e "start"  -q -e "stop"
        then
                        echo  "Invalid value for option 'o': start or stop expected"
                                exit 1
        else if echo $OPT | grep -i -q "start"
        then
                OPT="start"
        else
                OPT="stop"
        fi
        fi
}


function check_debug
{
        if [ "$DBGLVL" = "" ] ; then
                DBGLVL="NIV_EVENT"
        else
                if ! echo $DBGLVL | grep -q -e " NIV_NULL" -q -e  "NIV_MAJOR" -q -e " NIV_CRIT" -q -e "NIV_EVENT" -q -e "NIV_DEBUG" -q -e "NIV_FULL_DEBUG"
                then
                        echo  "Invalid value for option 'n': NIV_NULL, NIV_MAJ, NIV_CRIT, NIV_EVENT, NIV_DEBUG, NIV_MID_DEBUG or NIV_FULL_DEBUG expected."
                        exit 1
                fi
        fi

}


function check_logfile
{
        if [ "$LOG" = "" ]; then
                LOG="/tmp/nfs-ganesha.log"
        else if [ -f $LOG ]
        then
                cp $LOG /tmp/old-ganesha.log
                FILE1="1"
        fi
        fi
}

function call_checks
{
        check_ip
        check_conf
	cp $CONF /tmp/old-ganesha.conf

        check_debug
        check_logfile
        check_option
        check_volname
}
function check_glusterd()
{

        if ! ps aux | grep -q -e "[g]lusterd$" -q -e "[g]lusterd.pid"
        then
                echo "glusterd not started , please start glusterd. "
                exit 1
        fi
}

function check_bricks()
{
        gluster volume status $VOLUME | grep -q  "N/A"
        if [ "$?" -eq 0 ]
        then
                echo "Brick(s) not online , please check $VOLUME volume status"
                exit 1
        fi
}

function check_glusternfs
{
        if  echo "$(ls /var/lib/glusterd/vols | wc -l)" | grep -q "1" ; then
                if   ps aux | grep -q "[g]luster/nfs" ; then
                echo "gluster-nfs server is active, needs to be disabled to proceed. "
                while true; do
                        read -p "Do you wish to disable gluster-nfs server ? [Y\N]" yn
                        case $yn in
                                [Yy]* ) gluster volume set $VOLNAME nfs.disable ON >/dev/null 2>/dev/null; break;;
                                [Nn]* ) exit 1;;
                                * ) echo "Please answer yes or no.";;
                        esac
                done
                sleep 2
                        if ps aux | grep -q "[g]luster/nfs" ; then
                                 echo "Volume set unsuccessful , please try disabling gluster-nfs server "
                                exit 1
                         fi
                sleep 2
                        if rpcinfo -p | grep -q -e  "nfs_acl" ; then
                                 echo " gluster-nfs ports still in use; please try again"
                        exit 1
                        fi

         fi
 else
         if    ps aux | grep -q  "[g]luster/nfs"; then
                echo "Please disable gluster-nfs servers on all the volumes"
                exit 1
                 fi
        fi
}

function check_kernelnfs()
{
        service nfs status  | grep -q -e "dead" -q -e "stopped" -q -e "disabled" 
        if [ "$?" -eq 1 ]; then
                echo "kernel-NFS server is active , it needs to disabled to proceed. "
                while true; do
                        read -p "Do you wish to disable kernel-nfs server ? [Y\N]" yn
                                case $yn in
                                         [Yy]* ) service nfs stop; break;;
                                         [Nn]* ) exit 1;;
                                          * ) echo "Please answer yes or no.";;
                                esac
                done
                sleep 2
                service nfs status | grep -q -e "dead" -q -e "stopped" -q -e "inactive" >>/dev/null
                if [ "$?" -eq 1 ]; then
                        echo " kernel-NFS server couldn't be disabled , please try again"
                        exit 1
                else
                        echo "kernel-NFS server successfully disabled"
                fi
        fi
}


function check_volstart()
{

        if ! cat /var/lib/glusterd/vols/$1/info | grep -q "status=1" 
        then
                echo "Volume $1 is not started, please start the volume."
                exit 1
        fi
}

function check_ganesha
{
        if  ps aux | grep -q "[g]anesha.nfsd" ;  then
                echo "NFS-ganesha server is already active , nothing to do."
                exit 1
        fi
}


function check_ports
{
        if netstat -an | grep -q "2049$" ; then
                echo "Port 2049 is already in use , exiting"
                exit 1
        fi
}

function check_fsal
{

       if !  ls /usr/lib64/ganesha | grep -q "libfsalgluster.so"  ; then
               echo "Cannot find shared object libfsalgluster.so , exiting"
               exit 1
       fi
}




function start_ganesha
{
	check_ganesha
        #check_rpms
        check_fsal
        check_glusterd
        check_volstart $1
        check_kernelnfs
        check_glusternfs  $1
        check_ports
        check_conf $3
        check_bricks $1
        sed -i /^[[:space:]]*\#/!s/volume.*/"volume=$1,hostname=$2\";"/ $3
        sed -i /^[[:space:]]*\#/!s/Pseudo.*/Pseudo="\"\/$1\";"/ $3
        sed -i s/Path.*/Path="\"\/$1\";"/ $3
        sed -i 's/\r//g' $3
        /usr/bin/ganesha.nfsd -f $CONF  -L  $LOG -N $DBGLVL -d  >/dev/null 2>/dev/null

        sleep 5

}


function stop_ganesha
{
        if ! ps aux | grep -q "[g]anesha.nfsd" ;  then
                echo "NFS-ganesha server already inactive,nothing to do."
                exit 1
        fi
        kill -9 `cat /var/run/ganesha.pid`
        if ps aux | ganesha.nfsd ; then
                if  rpcinfo -p | grep -q -e "nfs" ; then
                        echo "NFS-ganesha server could not be stopped, please try again"
                fi
        else
                echo " NFS-ganesha server is now inactive."
		exit 0
        fi
}



function check_for_stop()
{
        if  echo $OPT | grep -i -q  "stop"
        then stop_ganesha
        fi
}



check_for_stop
check_usage
call_checks

if [ "$OPT" = "start"  ]
then
        start_ganesha $VOLNAME $IP $CONF
        if  ! ps aux | grep -q "[g]anesha.nfsd" ; then
                start_ganesha $VOLNAME $IP $CONF
        fi
        sleep 5
        if ! ps aux | grep  -q "[g]anesha.nfsd"
        then
                if [ "$FILE1" = "1" ]
                then
                cp /tmp/old-ganesha.log $LOG
                rm -rf /tmp/ganesha.log
                fi
                cp /tmp/old-ganesha.conf $CONF
		rm -rf /tmp/ganesha.conf
                 echo "Failed to start NFS-ganesha server , please see $LOG for details"
         else
                echo ""
                echo "NFS-ganesha server started."
                 echo "============Volume exports============"
                 showmount -e $IP
		echo "======================================"
		rm -rf /tmp/old-ganesha.conf
         fi
fi

  if  [ "$OPT" = "stop" ]
then
                stop_ganesha
		exit 0

fi

