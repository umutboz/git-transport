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
## Version: 1.0.0
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
    azure_devops_api_url = "azure_devops_url/_apis/git/repositories?api-version=4.1"
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



def createFolderAndCloneSourceRepo(repo_folder, repo_url):
    os.system("mkdir " + repo_folder)
    #git clone old repo 
    git_clone_old_repo_cmd = "git -C " + repo_folder + " clone --mirror " + repo_url
    os.system(git_clone_old_repo_cmd)


def createTargetByRepoAZCLI(repo_name, target_project_name):
    #create repo on target repo (azure cloud) with azure cli
    az_create_repo_cli_cmd = "az repos create --name " + repo_name + " --project " + target_project_name
    os.system(az_create_repo_cli_cmd)

def pushRemoteTargetRepo(repo_name, repo_folder_git_path):
    origin_name = "your_origin"
    #git remote add new-origin <url_of_new_repo>
    target_git_new_repo_url = "git@ssh.dev.azure.com:v3/{organization}/{project_name}/" + repo_name
    print(target_git_new_repo_url, repo_folder_git_path)

    #check exist config file - append on constantly remote origin
    if os.path.exists(repo_folder + "/" + repo.get("name") + ".git/config"):
        #git remote set-url origin ssh://newhost.com/usr/local/gitroot/myproject.git
        remote_origin_command = "git -C " + repo_folder_git_path + "remote rm " + origin_name
        os.system(remote_origin_command)
        #git_remote_add_new_origin_cmd = "git -C " + repo_folder_git_path + " remote add azuredevops " + target_git_new_repo_url
        git_remote_add_new_origin_cmd = "git -C " + repo_folder_git_path + " remote add " + origin_name +  " " + target_git_new_repo_url
        os.system(git_remote_add_new_origin_cmd)
        
    os.system("git -C " + repo_folder_git_path + " push " + origin_name + " --mirror")
    os.system("cd ..")


#coding start
#git-transport
if len(sys.argv) >= 0:
    #param1 = str(sys.argv[1])
    #param2 = str(sys.argv[2])
    target_project_name = "add_project_name"
    # get internal azure devops repositories with azure devops api (source repo)
    repositrories = getCurrentRepositories()
    
    if len(repositrories) == 0:
        print("repositories not found")
    
    for repo in repositrories:
        #initialize folder structure
        repo_folder = os.getcwd() + "/" + repo.get("name")
        repo_folder_git_path = repo_folder + "/" +  repo.get("name") + ".git "

        #check exist cloned repo
        if not os.path.exists(repo_folder_git_path):
            createFolderAndCloneSourceRepo(repo_folder = repo_folder, repo_url = repo.get("url"))

        #create repo on target repo (azure cloud) with azure cli
        createTargetByRepoAZCLI(repo_name = repo.get("name"), target_project_name = target_project_name)
    
        #push git remote add new-origin <url_of_new_repo>
        pushRemoteTargetRepo(repo_name = repo.get("name"), repo_folder_git_path = repo_folder_git_path)

else:
    print("encapsulateFramework -framework_name")
    print("min 0 arguments in commands")
