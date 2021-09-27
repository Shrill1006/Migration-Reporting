#!/bin/bash

# Datacenter constants
QIDC_MASTER="paas-master-east-np.tsl.telus.com"
KIDC_MASTER="paas-master-west-np.tsl.telus.com"
QIDC311_MASTER="paas-master-east2-np.tsl.telus.com"
KIDC311_MASTER="paas-master-west2-np.tsl.telus.com"

# Take in string and make it all CAPS
uppercase() {
  echo "$1" | tr a-z A-Z >/dev/null
}

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

# Checks if a project has been completely migrated to a new version of OpenShift
migrated() {
	if [ $1 -eq 0 ] && [ $2 -ge 1 ]
	then
        	echo "Migrated" $3 "--> TRUE"
	else
        	echo "Migrated" $3 "--> FALSE"
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
	for name in ${common_names[@]}
	do
		change_context $SOURCE 443
		running_pods_1+=($(get_num_of_running_pods $name))
		change_context $DEST 443
		running_pods_2+=($(get_num_of_running_pods $name))
	done
	logout

	# Based on the number of running pods for each namespace, determine if the project has been completelty migrated
	for ((i=0; i< ${#common_names[@]}; i++))
	do
		migrated $((${running_pods_1[$i]})) $((${running_pods_2[$i]})) ${common_names[$i]}
	done
}

#------ Execution of script begins here ------
CENTER=`uppercase $DATACENTER`
if [ $CENTER == "QIDC" ]
then
	SOURCE=$QIDC_MASTER
	DEST=$QIDC311_MASTER
else
	SOURCE=$KIDC_MASTER
	DEST=$KIDC311_MASTER
fi

migration_check
