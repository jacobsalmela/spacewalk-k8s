# spacewalk-k8s
Spacewalk--containerized and running on Kubernetes

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

At present, I can get Spacewalk to load up fine in a deployment, but it takes a little manual work to get there.

The Dockerfile does most everything, but the last program `supervisord` runs is a sleep command and then installs Spacewalk and restarts the Web services.  It's janky, but it seems to work at least for development.

# Testing locally

```
git clone <this repo>
cd <this repo>
docker build -t spacewalk:0.3 -f Dockerfile-centos .
cd postgres/
docker build -t spacewalk-postgres:0.2 .
cd ..
kubectl create -f spacewalk-pvc/
kubectl create -f spacewalk/
kubectl get po
kubectl port-forward <pod> 8000:80 8443:443 8080:8080
# Wait at least two minutes for the 90 second sleep command to complete
docker container ls
```

Now, enter the container and run a few more commands

```
docker exec -it <CONTAINER ID> /bin/bash

# Make sure this program is exited
supervisorctl status spacewalk
exit
```

At this point, you should be able to reach the Web interface.

[https://127.0.0.1:8443/rhn/newlogin/CreateFirstUser.do](https://127.0.0.1:8443/rhn/newlogin/CreateFirstUser.do)

or [https://127.0.0.1:8443/rhn/Login.do](https://127.0.0.1:8443/rhn/Login.do) if you already created your first user account and have an existing database.

# Next steps

- certs
- integrate errata sync via https://github.com/liedekef/spacewalk_scripts
