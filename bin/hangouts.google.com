#!/bin/bash

exec google-chrome --profile-directory=Default --app='https://hangouts.google.com/'
