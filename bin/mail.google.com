#!/bin/bash

exec google-chrome --profile-directory=Default --app='https://mail.google.com/'
