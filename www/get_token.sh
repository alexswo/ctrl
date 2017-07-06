#!/bin/bash

pickle=$1
curl -d "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${pickle}" https://www.googleapis.com/oauth2/v4/token
