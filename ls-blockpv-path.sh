#!/bin/sh
# ident: ls-blockpv-path.sh, v1.1, 2019/03/22. (C) 2019,mmuench@redhat
#
# DESCRIPTION: takes a OCS block pvc name list as argument and displays information about the source of the PVs components
#

usage() {
	echo "usage: $0 [-v] pvc_list" >&2
	echo "   pvc_list: list of space separted pvc names" >&2
	echo "   Produces a list of \"\$PVCNAME via: \$IPPORTAL \$PORTALS ACT=$ACTPORTAL blockBACKVOL=\$OCSVOL primary_shard=\$VOLLOC/\$OCSVOLFILE\"" >&2
	echo "   where:"
	echo "   via: lists the IP addresses of all configured potential portals for iscsi session"
	echo "   ACT: describes the IP address of the actual portal used for iscsi session"
	echo "   blockBACKVOL: gives the name of the OCS (gluster) block backing volume used for this block PV"
	echo "   primary_shard: lists the name of the file used to back block PV"
	echo " option -v gives a full info listing of the backing gluster volume" >&2
}

vopt=0
while getopts hv optchar; do
    case "${optchar}" in
        h)
	    usage
            exit 2
            ;;
        v)
            vopt=1
	    shift
            ;;
        *)
            echo "ERROR: unknown option"
	    usage
	    exit 1
            ;;
    esac
done

for PVCNAME in `echo $@`; do
	PVC=`oc get pv|grep --color=never $PVCNAME|awk '{print $1}'`
	RAWIQN=`oc describe pv/$PVC|grep --color=never IQN:|awk '{print $2}'`
	if [ -z $RAWIQN ]; then 
		echo "WARNING: $PVCNAME has no OCS based block PV"
	else
		IQN=`oc describe pv/$PVC|grep --color=never IQN:|awk '{print $2}'|cut -f2 -d:`
		IPPORTAL=`oc describe pv/$PVC|grep --color=never TargetPortal:|awk '{print $2}'`
		PORTALS=`oc describe pv/$PVC|grep --color=never Portals:|cut -d[ -f2-|cut -d] -f1`
		OCSPOD=`oc get pods --all-namespaces=true -o wide|grep --color=never $IPPORTAL|grep --color=never glusterfs|awk '{print $2}'`
		ACTPORTAL=`oc rsh $OCSPOD targetcli ls iscsi/$RAWIQN|tr -d '['|grep -v disabled|grep --color=never -A5 tpg|tail -1|awk '{print $3}'|cut -d: -f1|cut -dm -f3`
		TGTPOD=`oc get pods --all-namespaces=true -o wide|grep --color=never $ACTPORTAL|grep --color=never glusterfs|awk '{print $2}'`
		BACKSTORE=`oc rsh $TGTPOD  targetcli ls backstores/user:glfs |grep --color=never /block-store/$IQN`
		OCSVOL=v`echo $BACKSTORE|cut -d\@ -f1|cut -dv -f3`
		OCSVOLFILE=`echo $BACKSTORE|cut -d/ -f2-3|awk '{print $1}'`
		VOLLOC=`oc rsh $TGTPOD gluster vol info $OCSVOL|grep --color=never Brick|grep -v Bricks|head -3|grep --color=never $ACTPORTAL|tr -d '\r'|cut -d: -f3`
		echo "$PVCNAME via: $IPPORTAL $PORTALS ACT=$ACTPORTAL blockBACKVOL=$OCSVOL primary_shard=$VOLLOC/$OCSVOLFILE"
		if [ $vopt -eq 1 ]; then
			oc rsh $TGTPOD gluster vol info $OCSVOL
			echo ""
			echo ""
		fi
	fi
done
