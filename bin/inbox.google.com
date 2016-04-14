#!/bin/bash

exec google-chrome --profile-directory=Default --app='https://inbox.google.com/'
