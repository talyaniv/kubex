# Lightweight shell script for daily kubernetes jobs

Usage:

```
./kubex.sh <arg1> <optional arg2>
```

You may need to change the permissions for the script to run
```
chmod 700 kubex.sh
```

* reduces the hassle of getting a login token, copying to clipboard and opening a proxy session
* easily switching between contexts without needing to remember complex context name (e.g. in AWS EKS)

Copyright (c) 2018 Tal Yaniv

License: http://opensource.org/licenses/MIT


## arguments
```
l or --list lists-contexts   list all kubernetes contexts
                             use the index numbers to switch conexts with --context command

t or --token                 generates a login token and copies to clipboard

c <context index>
or --context <context index> switches to a context from the list
                             use l or --list to see the list

p or --proxy                 gets a token and copies to clipboard
                             open Mac Chrome app with the login page
                             starts a proxy session
```

## note about the --proxy method

This opens Mac Chrome browser. If you prefer another browser or use Linux, just change the app path from ```/Applications/Google Chrome.app``` to your favorite app.

## example

list contexts and switch to production:
```
$ ./kubex.sh --list-contexts
1 - arn:aws:eks:us-east-1:439989238490:cluster/staging
2 - arn:aws:eks:us-east-1:439989238490:cluster/production

$ ./kubex.sh --context 2
Switched to context "arn:aws:eks:us-east-1:439989238490:cluster/production".
```

## tip - create a symbolic link in /usr/local/bin/

Instead of going to the directory or copying this script all around - simply create a link for it in /usr/local/bin/

For example if the script is downloaded to `~/Downloads/kubex/kubex.sh`

```
ln -s ~/Downloads/kubex/kubex.sh /usr/local/bin/kubex
```

Then, from anywhere you can always
```
$ kubex l
1 - arn:aws:eks:us-east-1:439989238490:cluster/staging
2 - arn:aws:eks:us-east-1:439989238490:cluster/production
```

Easier!