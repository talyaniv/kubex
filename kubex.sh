#!/bin/bash

# Copyright (c) 2020 Tal Yaniv


########################
#   internal methods   #
########################

# setup does the following:
# 1. Configures AWS with your global credentials, or with a profile if given to the '--profile' parameter.
# 2. Downloads aws-iam-authenticator into '/usr/local/bin/' and gives it running permissions
# 3. Calling the 'aws eks' commands for all environments

function setup
{
    AUTHENTICATOR=/usr/local/bin/aws-iam-authenticator
    if [ ! -f AUTHENTICATOR ]; then
        echo "Downloading aws-iam-authenticator to /usr/local/bin/aws-iam-authenticator..."
        curl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/darwin/amd64/aws-iam-authenticator --output AUTHENTICATOR
        chmod 755 /usr/local/bin/aws-iam-authenticator
    fi

    echo "Updateing kubeconfig for dev, qa, staging, production..."
    aws eks update-kubeconfig --name dev --region us-west-2 $PROFILE
}

# get_kube_token will get your kubernetes (may take a few seconds) and copy it to your clipboard

function get_kube_token {
    echo "getting token..."
    RES=`kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')`
    echo ${RES#*token: } | cut -f1 -d" " | pbcopy
    echo "token copied to clipboard"
}


# get_contexts will scan your ~/.kube/config file, prepare a list of contexts and will store them in contexts variable

function get_contexts {

    CONTEXTS=() # stores an array of contexts
    FOUND_CONTEXTS=false # flags finding the "contexts" label
    CONTEXTS_COUNT=0

    # iterating over the config file
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ "$FOUND_CONTEXTS" = true ]; then
            if [[ $line == *"  name: "* ]]; then
                LINE_CONTENT=${line#*"  name: "}
                CONTEXTS+=("$LINE_CONTENT")
                CONTEXTS_COUNT=$(( $CONTEXTS_COUNT + 1 ))
            fi
        fi
        if [ "$line" = users: ]; then
            break
        fi
        if [ "$line" = contexts: ]; then
            FOUND_CONTEXTS=true
        fi
    done < ~/.kube/config

}

# if no arguments supplied, showing help
NOARGS=$(( $# == 0 ))
SETUP=0

##########################
#   commands execution   #
##########################

for arg in "$@"
do
    case $arg in

        # sets the profile to use, defaults to AWS default profile in ~/.aws/credentials
        # add profile=[profile] to use an SSO profile
        # example
        # ./kubex.sh --setup --profile=1234567890_AdministratorAccess
        --profile=*)
            PROFILE="--profile ${arg#*=}"
            shift
            ;;



        # setup
        # ./kubex.sh s
        # or
        # ./kubex.sh --setup
        s|--setup)
            SETUP=1
            shift
            ;;



        # ./kubex.sh t
        # or
        # ./kubex.sh --token
        t|get_kube_token)
            get_kube_token
            shift
            ;;



        # ./kubex.sh c=<conext index>
        # or
        # ./kubex.sh --context=<context index>

        # switches context
        # to list all contexts use:
        # ./kubex.sh --list-contexts 

        # example - to list contexts and switch to production:
        # $ ./kubex.sh --list-contexts
        # 1 - arn:aws:eks:us-east-1:123123123123:cluster/staging
        # 2 - arn:aws:eks:us-east-1:123123123123:cluster/production
        # $ ./kubex.sh --context=2

        c=*|--context=*)
            get_contexts
            CONTEXT=${CONTEXTS[$(( ${arg#*=} - 1 ))]}
            if [ "$CONTEXT" == "" ]; then
                echo "context out of scope (1~$CONTEXTS_COUNT)"
            else
                kubectl config use-context $CONTEXT
            fi
            shift
            ;;



        # ./kubex.sh l
        # or
        # ./kubex.sh --list-contexts

        # lists all context in ~/.kube/config

        # example
        # $ ./kubex.sh --list-contexts
        # 1 - arn:aws:eks:us-east-1:123123123123:cluster/staging
        # 2 - arn:aws:eks:us-east-1:123123123123:cluster/production

        l|--list-contexts)
            get_contexts
            CONTEXT_INDEX=0
            while [ "$CONTEXT_INDEX" -lt "$CONTEXTS_COUNT" ]
            do
                echo $(( $CONTEXT_INDEX + 1 )) - ${CONTEXTS[$CONTEXT_INDEX]}
                CONTEXT_INDEX=$(( $CONTEXT_INDEX + 1 ))
            done
            shift
            ;;



        # ./kubex.sh p
        # or
        # ./kubex.sh --proxy

        # gets a token
        # stores in clipboard
        # opens a Chrome (Mac) browser page and navigates to the login screen
        # starts a proxt session

        p|--proxy)
        get_kube_token
        /usr/bin/open -a "/Applications/Google Chrome.app" "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login"
        kubectl proxy
        shift
        ;;


        # unresolved arguments
        *)
        NOARGS=1

    esac
done


if [ $SETUP == 1 ]; then
    setup
fi



if [ $NOARGS == 1 ]; then
    echo "kubex is a lightweight shell script for daily kubernetes jobs"
    echo
    echo "usage:"
    echo "./kubex.sh <arg1> <optional arg2>"
    echo "example:"
    echo ".kubex.sh l"
    echo
    echo "l or --list-contexts         list all kubernetes contexts"
    echo "                             use the index numbers to switch conexts with --context command"
    echo
    echo "t or --token                 generates a login token and copies to clipboard"
    echo
    echo "c=<context index>"
    echo "or --context=<context index> switches to a context from the list"
    echo "                             use l or --list to see the list"
    echo
    echo "p or --proxy                 gets a token and copies to clipboard"
    echo "                             opens Mac Chrome app with the login page"
    echo "                             starts a proxy session"
    echo
    echo "s [--profile=profile_name]"
    echo "or --setup [--profile=profile_name]"
    echo "                             Configures aws to the given profile or to the global credentials if --profile is missing,"
    echo "                             downloads aws-iam-authenticator into /usr/local/bin, and runs 'aws eks' commands for all the environments"
fi
