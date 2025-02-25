#!/bin/bash

####################################################
# Functions
####################################################

repeat() {
    echo
    for i in {1..120}; do
        echo -n "$1"
    done
    echo
}

enable_user_workload_monitoring()
{
    echo
    echo "Enabling monitoring for user-defined projects..."
    echo

    oc apply -f ../manifest/cluster-monitoring-config.yml -n openshift-monitoring
}

install_operator() {
    operatorNameParam=$1
    operatorDescParam=$2
    ymlFilePathParam=$3
    project=$4

    echo
    echo "Installing $operatorDescParam to $project project..."
    echo

    oc apply -f $ymlFilePathParam -n $project

    echo
    echo "Waiting for $operatorDescParam to be available..."
    echo

    available="False"

    while [[ $available != "True" ]]; do
        sleep 5
        available=$(oc get -n $project operators.operators.coreos.com \
            $operatorNameParam.$project \
            -o jsonpath='{.status.components.refs[?(@.apiVersion=="apps/v1")].conditions[?(@.type=="Available")].status}')
    done

    echo "$operatorDescParam is now available!"
}

install_amq_streams() {
    operatorName=amq-streams
    operatorDesc="Red Hat Integration - AMQ Streams"
    ymlFilePath=../manifest/amq-stream-subscription.yml
    project=openshift-operators

    install_operator $operatorName "$operatorDesc" $ymlFilePath $project
}

install_distributed_tracing_platform() {
    project=openshift-operators

    operatorName=jaeger-product
    operatorDesc="Red Hat OpenShift distributed tracing platform"
    ymlFilePath=../manifest/distributed-tracing-platform-subscription.yml

    install_operator $operatorName "$operatorDesc" $ymlFilePath $project
}

install_distributed_tracing_data_collection() {
    operatorName=opentelemetry-product
    operatorDesc="Red Hat OpenShift distributed tracing data collection"
    ymlFilePath=../manifest/distributed-tracing-data-collection-subscription.yml
    project=openshift-operators

    install_operator $operatorName "$operatorDesc" $ymlFilePath $project
}

install_service_registry() {
    operatorName=service-registry-operator
    operatorDesc="Red Hat Integration - Service Registry Operator"
    ymlFilePath=../manifest/service-registry-subscription.yml
    project=openshift-operators

    install_operator $operatorName "$operatorDesc" $ymlFilePath $project
}

setup_web_terminal() {
    operatorName=web-terminal
    operatorDesc="Web Terminal"
    ymlFilePath=../manifest/web-terminal-subscription.yml
    project=openshift-operators

    install_operator $operatorName "$operatorDesc" $ymlFilePath $project

    # Customize Web Terminal template see: https://github.com/redhat-developer/web-terminal-operator/
    oc annotate devworkspacetemplates.workspace.devfile.io web-terminal-tooling 'web-terminal.redhat.com/unmanaged-state=true' -n $project
    oc patch devworkspacetemplates.workspace.devfile.io web-terminal-tooling --type=merge --patch-file=../manifest/web-terminal-tooling.json -n $project

    # Hack!! Reinstall after customized otherwise the Web Terminal icon won't show up in the web console
    oc delete subscription web-terminal-operator -n $project
    sleep 5
    install_operator $operatorName "$operatorDesc" $ymlFilePath $project
}

install_grafana() {
    operatorName=grafana-operator
    operatorDesc="Grafana Operator"
    ymlFilePath=../manifest/grafana-subscription.yml
    project=openshift-operators

    install_operator $operatorName "$operatorDesc" $ymlFilePath $project
}

####################################################
# Main (Entry point)
####################################################
echo
echo "Super Heroes on OpenShift Workshop Provisioner"
repeat '-'

enable_user_workload_monitoring
repeat '-'

install_amq_streams
repeat '-'

install_distributed_tracing_platform
repeat '-'

install_distributed_tracing_data_collection
repeat '-'

install_service_registry
repeat '-'

install_grafana
repeat '-'

# For some reasons, the web terminal icon doesn't show in OpenShift web console
# if we install Web Terminal operator via CLI but the issue is gone if we install
# it via OpenShift web console. That's weird!
# setup_web_terminal
# repeat '-'

oc project default

echo "Done!!!"
