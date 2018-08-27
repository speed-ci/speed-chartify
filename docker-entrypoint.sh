#!/bin/bash
set -e

source /init.sh

printmainstep "Publication du chart Kubernetes Helm"
printstep "Vérification des paramètres d'entrée"
init_artifactory_env

CHART_FILE_NAME="Chart.yaml"
if [ ! -f $CHART_FILE_NAME ]; then
    printerror "Le fichier de meta-données $CHART_FILE_NAME doit être présent dans le répertoire courrant"
    exit 1
fi

CHART_NAME=$(yq r Chart.yaml name)
if [ $CHART_NAME == null ]; then
    printerror "Le fichier de meta-données $CHART_FILE_NAME doit contenir le nom du chart (champ name)"
    exit 1
fi

CHART_VERSION=$(yq r Chart.yaml version)
if [ $CHART_NAME == null ]; then
    printerror "Le fichier de meta-données $CHART_FILE_NAME doit contenir la version du chart (champ version)"
    exit 1
fi

printstep "Configuration de l'accès au chart repository"
printcomment "helm init --client-only --skip-refresh"
helm init --client-only --skip-refresh
printcomment "helm repo remove local"
helm repo remove local
printcomment "helm repo add stable \$ARTIFACTORY_URL/artifactory/helm --username \$ARTIFACTORY_USER --password \$ARTIFACTORY_PASSWORD"
helm repo add stable "$ARTIFACTORY_URL/artifactory/helm" --username "$ARTIFACTORY_USER" --password "$ARTIFACTORY_PASSWORD"

printstep "Vérification de la syntaxe du chart $CHART_NAME"
cp -r /srv/speed /srv/$CHART_NAME
cd /srv/$CHART_NAME
printcomment "helm lint"
helm lint

printstep "Construction de l'archive chart helm"
printcomment "helm package ."
helm package .

printstep "Publication du chart helm dans Artifactory"
curl --noproxy '*'  -u$ARTIFACTORY_USER:$ARTIFACTORY_PASSWORD -T $CHART_NAME-$CHART_VERSION.tgz $ARTIFACTORY_URL/artifactory/helm/$CHART_NAME-$CHART_VERSION.tgz
