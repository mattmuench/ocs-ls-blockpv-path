# ocs-ls-blockpv-path
Red Hat OCS: getting block backing volume for pvc

To determine which backing volume from underlying Gluster cluster is used for a block PV some steps required to drill down
on the final destination. This script lists the structural elements for a PV based on the PVC. 

Produces a list of 
    $PVCNAME via: $IPPORTAL $PORTALS ACT=$ACTPORTAL blockBACKVOL=$OCSVOL primary_shard=$VOLLOC/$OCSVOLFILE
where:
   via: lists the IP addresses of all configured potential portals for iscsi session
   ACT: describes the IP address of the actual portal used for iscsi session
   blockBACKVOL: gives the name of the OCS (gluster) block backing volume used for this block PV
   primary_shard: lists the name of the file used to back block PV
