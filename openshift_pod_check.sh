#!/bin/bash

# Datacenter constants for non-production (uncomment lines 4-7 and 102-112 to run for non-production)
# QIDC_MASTER="paas-master-east-np.tsl.telus.com"
# KIDC_MASTER="paas-master-west-np.tsl.telus.com"
# QIDC311_MASTER="paas-master-east2-np.tsl.telus.com"
# KIDC311_MASTER="paas-master-west2-np.tsl.telus.com"

# Datacenter constants for production
QIDC_MASTER_PR="paas-master-east.tsl.telus.com"
KIDC_MASTER_PR="paas-master-west.tsl.telus.com"
QIDC311_MASTER_PR="paas-master-east2.tsl.telus.com"
KIDC311_MASTER_PR="paas-master-west2.tsl.telus.com"

# Login and get current namespaces
get_namespaces() {
	change_context $1 $2
    IFS=$'\n' read -r -d '' -a proj_names < <( oc get projects -o custom-columns=NAME:.metadata.name --no-headers && printf '\0' )
}

# This function returns the number of running pods in a project
get_num_of_running_pods() {
	oc project $1 >/dev/null
	oc get pods -o custom-columns=NAME:.metadata.name,STATUS:status.phase | grep -c "Running"
}

# List all admins for a project
get_admins() {
	oc get rolebinding admin -n $1 -o custom-columns=USERS:.userNames --no-headers | sed 's/[][]//g'
}

# Checks if a project has been completely migrated to a new version of OpenShift
migrated() {
	if [ $1 -eq 0 ] && [ $2 -ge 1 ]
	then
        	echo "$3,TRUE,$4,$5" >> out.csv
	else
        	echo "$3,FALSE,$4,$5" >> out.csv
	fi
}

change_context() {
	CLUSTER=$1
	PORT=$2
	CONTEXT=`echo $CLUSTER | sed 's/\./-/g'`
	oc config use-context openshift/${CONTEXT}:${PORT}/system:serviceaccount:openshift:project-view >/dev/null
}

# Logout of current project
logout() {
	oc logout >/dev/null
}

# Converts array to delimited string
join_arr() {
	local IFS="$1"
	shift
	echo "\"$*\""
}

# This function checks if namespaces have been migrated to newer version of OpenShift
migration_check() {
	# Retrieve all namespaces under the older project
	get_namespaces $SOURCE 443
	declare -p proj_names >/dev/null
	arr1=( "${proj_names[@]}" )

	# Retrieve all namespaces under the newer project
	get_namespaces $DEST 443
	declare -p proj_names >/dev/null
	arr2=( "${proj_names[@]}" )

	# From all the namespaces between the new and old projects, extract all namespaces that are the same between both projects
	common_names=($(comm -12 <(printf '%s\n' "${arr1[@]}" | LC_ALL=C sort) <(printf '%s\n' "${arr2[@]}" | LC_ALL=C sort)))
	if [ "${#common_names[@]}" -eq 0 ]
	then
		echo "No common namespaces to check for migration!"
		exit 1
	fi

	declare -a running_pods_1=()
	declare -a running_pods_2=()
	# For each common namespace, retrieve the number of running pods
	change_context $SOURCE 443
	for name in ${common_names[@]}
	do
		running_pods_1+=($(get_num_of_running_pods $name))
	done
	logout
	change_context $DEST 443
	for name in ${common_names[@]}
	do
		running_pods_2+=($(get_num_of_running_pods $name))
	done

	# Based on the number of running pods for each namespace, determine if the project has been completelty migrated
	for ((i=0; i< ${#common_names[@]}; i++))
	do
		admins_arr=( $(get_admins ${common_names[$i]}) )
		admins_str=$(join_arr ';' ${admins_arr[@]})
		migrated $((${running_pods_1[$i]})) $((${running_pods_2[$i]})) ${common_names[$i]} $1 ${admins_str}
	done
	logout
}

#------ Execution of script begins here ------
# Create or clear existing file to write output of the currrent script run
FILE=./out.csv
if test -f "$FILE"
then 
	> out.csv
else
	echo "NAMESPACE, MIGRATED, DATACENTER, ADMINS" >> out.csv
fi

# # Run for QIDC first
# SOURCE=$QIDC_MASTER
# DEST=$QIDC311_MASTER
# DATACENTER="QIDC"
# migration_check $DATACENTER

# # Run for KIDC
# SOURCE=$KIDC_MASTER
# DEST=$KIDC311_MASTER
# DATACENTER="KIDC"
# migration_check $DATACENTER

# Run for QIDC first
SOURCE=$QIDC_MASTER_PR
DEST=$QIDC311_MASTER_PR
DATACENTER="QIDC"
migration_check $DATACENTER

# Run for KIDC
SOURCE=$KIDC_MASTER_PR
DEST=$KIDC311_MASTER_PR
DATACENTER="KIDC"
migration_check $DATACENTER