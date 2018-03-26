# Dynamic Kubernetes routing mesh with Consul, Helm, and NGINX

## Presentation notes with accompanying commands:
1. Set the boolean conditionals for deploying the sidecars to false to demonstrate service registration when deploying the sidecars<br />
	* ```helm template -f  helm-values/k8s-vancouver-meetup-minikube.yml helm/k8s-vancouver-meetup | kubectl apply -f -```<br />
	* exec into k8s-vancouver-meetup pod and show nothing listening on localhost<br />
		* ```kubectl exec -it k8s-vancouver-meetup-xxx-xxx bash```<br />

2. Port-forward to the consul server pod and show consul UI with only consul registered so far<br />
	* ```kubectl port-forward consul-server-xxx-xxx 8500:8500```<br />
	* Create nginx-router-template in the consul KV store with the contents of nginx-router-template.tpl<br />

3. Set (and explain) the sidecar deployment booleans to true and redeploy. This redeploys the application pod w/sidecars but leaves the consul DC with our newly added template. Explain the ConfigMaps<br />
	* ```kubectl logs k8s-vancouver-meetup-xxx-xxx -c consul-sidecar```<br />
	* ```kubectl logs k8s-vancouver-meetup-xxx-xxx -c nginx-sidecar```<br />
	* ``` kubectl get configmap nginx-config-map consul-config-map -o yaml```
	* Navigate back to the consul UI and verify new service registration

4. Exec into the nginx sidecar container and show the template file and rendered config file<br />
	* ```kubectl exec -it k8s-vancouver-meetup-xxx-xxx -c nginx-sidecar bash```<br />
	* ```cat /nginx-router-template.tpl```<br />
	* ```cat /etc/nginx/conf.d/default.conf```<br />

5. Exec into any service pod container and verify routing via the nginx mesh<br />
	* ```kubectl exec -it k8s-vancouver-meetup-755b6df96d-jm85v -c k8s-vancouver-meetup bash```<br />
	* ```curl localhost/mesh/k8s-vancouver-meetup/```<br />
	* ```curl localhost/mesh/consul-server/ui/```<br />

6. Port-forward to port 80 on the k8s-meetup pod and navigate to the above URLs in a browser<br />
	* Note how you can't navigate to port 8500 directly for consul anymore, but you can go via the mesh address<br />

## Setup Steps:
1. Create a Helm template that deploys any image that serves out a web page or responds to cURL<br />
2. Add a conditional that deploys the consul sidecar container<br />
3. Add environment variables that get rendered into the deployment manifest for both containers<br />
    1. Create a separate variables file with values that get substituted during helm template rendering<br />
4. Create a ConfigMap template that contains the consul server config AND the consul client config. Mount this inside the consul sidecar<br />
5. Deploy a pod/service for consul server with a UI<br />
6. Mount the consul server ConfigMap inside this container (at /consul/config/, the default place consul checks for config files. MUST end in .json)<br />
7. Verify that the application has registered in the consul DC<br />
8. Deploy a NGINX router as a sidecar container with Helm<br />
9. Create an entrypoint configmap for the nginx-sidecar container<br />
    1. Install consul-template<br />
    2. Grab the template and render an nginx router config<br />
    3. Start NGINX using your newly rendered config file<br />
10. Template out a proxy config that forwards the "mesh" endpoint to the kube-dns endpoint (.ie do a URL rewrite to use a kube-dns or IP endpoint)<br />
11. Verify routing is working as expected<br />

### General Remarks:
* You would have separate repos with unique template values for the consul server and the application w/sidecar containers in practice<br />
* You wouldn't store your entrypoints as a config map and mount it - you'd bake it into your image and push this to your docker registry. I don't have a docker registry set up, and I want this to work stand-alone without any external dependencies, so I'm using a config map to mount the alternative entrypoint<br />
