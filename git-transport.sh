#!/usr/bin/env python
# -*- coding: utf-8 -*-
""":"
exec python $0 ${1+"$@"}
"""

############################################################
## git-transport
############################################################
## Author: Umut Boz
## Copyright (c) 2020, OneframeMobile, KoçSistem
## Email: oneframemobile@gmail.com
############################################################
## Version: 0.1.0
############################################################

import os
import sys
import re
import shutil
import commands
import datetime
import urllib2
import ssl
import json
import base64

def getCurrentRepositories():
    repositories = []
    azure_devops_api_url = "source_repo_azure_devops/_apis/git/repositories?api-version=4.1"
    username = "user_name"
    password = "token_key"
    requestConfig = {
    "headers" : {
    "Content-Type": "application/json",
    "Authorization": "Basic " + base64.encodestring('%s:%s' % (username, password)).replace('\n', '')
    },
    "url": azure_devops_api_url}
    try:
        jsonData = ""
        datas = None
        request = urllib2.Request(requestConfig["url"], datas, requestConfig["headers"])
        result = urllib2.urlopen(request)
        dataString = result.read().decode('utf-8')
        jsonData = json.loads(dataString)

    except urllib2.HTTPError as e:
        print('HTTPError = ' + str(e.code))
        sys.exit(0)
    except urllib2.URLError as e:
        print('URLError = ' + str(e.reason))
        sys.exit(0)
    except Exception as e:
        print('generic exception: ' + str(e))
        sys.exit(0)
    
    for val in jsonData["value"]:
        val_json_dumps = json.dumps(val)
        val_json_object = json.loads(val_json_dumps)
        repos_size = val_json_object.get('size')
        if repos_size == None or repos_size == 0:
            continue
        repositories.append({'name' : val_json_object.get('name'), 'url' : val_json_object.get('remoteUrl')})
    
    return repositories



#coding start
#git-transport
if len(sys.argv) >= 0:
    param1 = str(sys.argv[1])
    param2 = str(sys.argv[2])
    
    # get internal azure devops repositories with azure devops api (source repo)
    repositrories = getCurrentRepositories()
    
    if len(repositrories) == 0:
        print("repositories not found")
    
    for repo in repositrories:
        #initialize folder structure
        repo_folder = os.getcwd() + "/" + repo.get("name")
        os.system("mkdir " + repo_folder)
        #git clone old repo 
        git_clone_old_repo_cmd = "git -C " + repo_folder + " clone --mirror " + repo.get("url")
        os.system(git_clone_old_repo_cmd)

        #create repo on target repo (azure cloud) with azure cli
        target_project_name = "target_project_name"
        az_create_repo_cli_cmd = "az repos create --name " + repo.get("name") + " --project " + target_project_name
        os.system(az_create_repo_cli_cmd)

        #git remote add new-origin <url_of_new_repo>
        target_git_new_repo_url = "git@ssh.dev.azure.com:v3/{organization}/{project}/" + repo.get("name") 
        git_remote_add_new_origin_cmd = "git -C " + repo_folder + "/" +  repo.get("name") + ".git " + " remote add azuredevops " + target_git_new_repo_url
        os.system(git_remote_add_new_origin_cmd)
        os.system("git -C " + repo_folder + "/" +  repo.get("name") + ".git" + " push azuredevops --mirror")
        os.system("cd ..")

else:
    print("encapsulateFramework -framework_name")
    print("min 0 arguments in commands")
