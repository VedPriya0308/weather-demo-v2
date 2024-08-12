#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -z "$PROJECT" ]; then
    echo "No PROJECT variable set"
    exit
fi

if [ -z "$APIGEE_ENV" ]; then
    echo "No APIGEE_ENV variable set"
    exit
fi

if [ -z "$APIGEE_HOST" ]; then
    echo "No APIGEE_HOST variable set"
    exit
fi

TOKEN=$(gcloud auth print-access-token)

echo "Installing dependencies"
npm install --no-fund

echo "Installing apigeecli"
curl -s https://raw.githubusercontent.com/apigee/apigeecli/master/downloadLatest.sh | bash
export PATH=$PATH:$HOME/.apigeecli/bin

echo "Creating Apigee config..."

apigeecli datacollectors create --name "dc_weather_history_v2_location" --type STRING --org "$PROJECT" --token "$TOKEN" 

apigeecli targetservers create --name "bigquery" --host "bigquery.googleapis.com" --port 443  --tlsenforce true --org "$PROJECT" --token "$TOKEN" --env "$APIGEE_ENV"

apigeecli kvms create --name "weather-history-v2-kvm" --env "$APIGEE_ENV" --org "$PROJECT" --token "$TOKEN"

apigeecli kvms entries create --map "weather-history-v2-kvm" --key "geocode-apikey" --value "$GEOCODE_APIKEY" --env "$APIGEE_ENV" --org "$PROJECT" --token "$TOKEN"

find ./src -type f -name "*.xml" -exec sed -i '' "s/\[PROJECT\]/$PROJECT/" {} +

find ./portal/specs -type f -name "*.yaml" -exec sed -i '' "s/\[APIGEE_HOST\]/$APIGEE_HOST/" {} +

echo "Importing and Deploying Apigee weather-history-v2 proxy..."
REV=$(apigeecli apis create bundle -f "src/proxies/weather-history-v2/apiproxy"  -n weather-history-v2 --org "$PROJECT" --token "$TOKEN" --disable-check | jq ."revision" -r)

apigeecli apis deploy --wait --name weather-history-v2 --ovr --rev "$REV" --org "$PROJECT" --env "$APIGEE_ENV" --token "$TOKEN" --sa "$BIGQUERY_SERVICE_ACCOUNT"

echo "Creating API Products"
apigeecli products create --name weather-history-v2-premium-product --display-name "Weather History v2 Premium" --opgrp ./src/config/weather-history-v2-product-ops.json --envs "$APIGEE_ENV" --approval auto --quota 20 --interval 1 --unit minute --org "$PROJECT" --token "$TOKEN"

apigeecli products create --name weather-history-v2-freemium-product --display-name "Weather History v2 Freemium" --opgrp ./src/config/weather-history-v2-product-ops.json --envs "$APIGEE_ENV" --approval auto --quota 10 --interval 1 --unit minute --org "$PROJECT" --token "$TOKEN"

echo "Creating Developer"
apigeecli developers create --user testuser --email weather-history-v2-developer@acme.com --first A --last User --org "$PROJECT" --token "$TOKEN"

echo "Creating Developer Apps"
apigeecli apps create --name weather-history-v2-premium-app --email weather-history-v2-developer@acme.com --prods weather-history-v2-premium-product --org "$PROJECT" --token "$TOKEN" --disable-check

apigeecli apps create --name weather-history-v2-freemium-app --email weather-history-v2-developer@acme.com --prods weather-history-v2-freemium-product --org "$PROJECT" --token "$TOKEN" --disable-check

APIKEY_PREM=$(apigeecli apps get --name weather-history-v2-premium-app --org "$PROJECT" --token "$TOKEN" --disable-check | jq ."[0].credentials[0].consumerKey" -r)
export APIKEY_PREM

APIKEY_FREE=$(apigeecli apps get --name weather-history-v2-freemium-app --org "$PROJECT" --token "$TOKEN" --disable-check | jq ."[0].credentials[0].consumerKey" -r)
export APIKEY_FREE

# vars is expected by integration test (apickli)
export PROXY_URL="$APIGEE_HOST/v2/weather-history"
export APIKEY=$APIKEY_PREM

# integration tests

npm run test

echo " "
echo "Your Premium APIKEY is: $APIKEY_PREM"
echo " "
echo "Your Freemium APIKEY is: $APIKEY_FREE"
echo " "
echo "Your PROXY_URL is: $PROXY_URL"
echo " "
echo "-----------------------------"