# spacewalk-k8s
Spacewalk--containerized and running on Kubernetes

https://jacobsalmela.com/2019/02/18/spacewalk-containerized-and-running-in-kubernetes/

## Pull prebuilt images from Github or Docker
```
# Github
docker pull docker.pkg.github.com/jacobsalmela/spacewalk-k8s/spacewalk:2.9
docker pull docker.pkg.github.com/jacobsalmela/spacewalk-k8s/spacewalk-postgres:2.9
# Docker
docker pull jacobsalmela/spacewalk:2.9
docker pull jacobsalmela/spacewalk-postgres:2.9

```
## Spacewalk as a Kubernetes deployment, why?

This repo is an attempt to containerize Spacewalk and run it as a Kubernetes deployment.

I started doing this because Spacewalk is a monolithic app and upgrading it is difficult.  It also takes a while to setup, so recovering from a disaster would be slow.  I fell in love with Kubernetes and I thought Spacewalk was the perfect candidate for a container because:

- it is a monolithic app with several components that can be broken down into microservices
- it is difficult to upgrade parts of the software without updating everything
- some might consider it a legacy app because the only way to install it is via a traditional install directly to an OS so it's not very future proof

I also wanted to show how it is possible to take a complex program and containerize it, even though it is not easy.  So this repo:

- demonstrates how you can decouple parts of the program, like the database and turn it into it's own container
- demonstrates how to take a traditional app that runs on an init system and port it over to a container
- demonstrates how to create config maps
- demonstrates how to create custom docker images from parts of an existing application
- demonstrates how to use persistent volumes for data that needs to persist

# Caveats

The Dockerfile does most everything, but the last program `supervisord` runs is a sleep command and then installs Spacewalk and restarts the Web services.  It's janky, but it seems to work--at least for development.  It also seems to work fine if you kill the deployment and re-create it--the persistent storage portion is working so you don't lose anything.

# Testing locally

```
git clone <this repo>
cd <this repo>
docker build -t spacewalk:2.9 -f Dockerfile-centos .
cd postgres/
docker build -t spacewalk-postgres:2.9 .
cd ..
kubectl create -f spacewalk-pv/
kubectl create -f spacewalk/
kubectl get po
kubectl port-forward <pod> 8000:80 8443:443 8080:8080
```

(optionally) enter the container and run a few more commands:

```
kubectl exec -it <CONTAINER ID> /bin/bash

# Make sure this program is exited
supervisorctl status spacewalk-init
# If it's running forever, stop it and start it again
supervisorctl stop spacewalk-init
supervisorctl start spacewalk-init
# Or run the install commands yourself from the supervisord config map
```

At this point, you should be able to reach the Web interface.

[https://127.0.0.1:8443/rhn/newlogin/CreateFirstUser.do](https://127.0.0.1:8443/rhn/newlogin/CreateFirstUser.do)

or [https://127.0.0.1:8443/rhn/Login.do](https://127.0.0.1:8443/rhn/Login.do) if you already created your first user account and have an existing database.


# Register a client
I tested with a container here as an example, but the steps are the same for a traditional server or VM (per https://github.com/spacewalkproject/spacewalk/wiki/RegisteringClients#red-hat-enterprise-linux-5-6-and-7-scientific-linux-6-and-7-centos-5-6-and-7)

```
rpm -Uvh https://copr-be.cloud.fedoraproject.org/results/%40spacewalkproject/spacewalk-2.9-client/epel-7-x86_64/00830558-spacewalk-repo/spacewalk-client-repo-2.9-4.el7.noarch.rpm
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install rhn-client-tools rhn-check rhn-setup rhnsd m2crypto yum-rhn-plugin
rpm -Uvh http://<SPACEWALK WEB CONTAINER>/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
rhnreg_ks --serverUrl=https://<SPACEWALK WEB CONTAINER>/XMLRPC --sslCACert=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT --activationkey=1-centos7
```

# Re-deploying with changes

You can rebuild images if you make changes.  Thanks to the persistent storage, the database and things should stay in tact.  

```
kubectl delete -f spacewalk/
kubectl create -f spacewalk/
```

Just don't delete the `spacewalk-pv/` folder or you'll lose your persistent storage.

# Exploring the database

I have included the `adminer` container, which is a nice little GUI for databases.  Load it up at http://localhost:8080

# Next steps

- certs
- integrate errata sync via https://github.com/liedekef/spacewalk_scripts
