#!/bin/bash

exec google-chrome --profile-directory=daniel.fanjul.alcuten@gmail.com --app='https://inbox.google.com/'
