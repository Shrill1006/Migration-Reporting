# Migration-Reporting

This script takes two OpenShift accounts (one where projects were made with the older version of OpenShift and the other with the newer version) and checks if the
namespaces/projects that are common to both the accounts have been completely migrated over to the newer version of Openshift.

### Running the script
To run the script locally, run these commands. Note that the `DATACENTER` parameter must either be QIDC or KIDC.
```
docker build . --rm -t openshift_pod_check:latest
docker run -it --rm -e DATACENTER={QIDC or KIDC} openshift_pod_check:latest
```
