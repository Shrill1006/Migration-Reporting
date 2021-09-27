#!/bin/bash

# Login and get current namespaces
get_namespaces() {
	login $1 $2
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

# Login to a namespace
login() {
	oc login $1 $2 >/dev/null
}

# Logout of current project
logout() {
	oc logout >/dev/null
}

# This function checks if namespaces have been migrated to newer version of OpenShift
migration_check() {
	# Check if proper number of args are provided
	if [ "$#" -ne 4 ]
	then
		echo "Illegal number of parameters!"
	else
		# Retrieve all namespaces under the older project
		get_namespaces $1 $2
		declare -p proj_names >/dev/null
		arr1=( "${proj_names[@]}" )

		# Retrieve all namespaces under the newer project
		get_namespaces $3 $4
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
			login $1 $2
			running_pods_1+=($(get_num_of_running_pods $name))
			login $3 $4
			running_pods_2+=($(get_num_of_running_pods $name))
		done
		logout

		# Based on the number of running pods for each namespace, determine if the project has been completelty migrated
		for ((i=0; i< ${#common_names[@]}; i++))
		do
			migrated $((${running_pods_1[$i]})) $((${running_pods_2[$i]})) ${common_names[$i]}
		done
	fi
}

#------ Execution of script begins here ------
migration_check $1 $2 $3 $4
