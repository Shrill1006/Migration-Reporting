# Migration-Reporting

This script takes two OpenShift accounts (one where projects were made with the older version of OpenShift and the other with the newer version) and checks if the
namespaces/projects that are common to both the accounts have been completely migrated over to the newer version of Openshift.

### Running the Script Locally
To run the script locally, run these commands.
```
docker build . --rm -t openshift_pod_check:latest
docker run -it --rm openshift_pod_check:latest
```
