# Kubernetes and Istio
- Reuse the existing AKS Istio installation and existing approved Gateway.
- Do not install NGINX, Traefik, another Istio control plane, or another Gateway unless explicitly directed by the cluster owner.
- Use ClusterIP for project services.
- Public/user routing is created by project-owned VirtualService resources referencing the existing gatewayRef.
- Admin UIs use port-forward or an already-approved internal-only route; they are not public.
- Inspect and follow the cluster's actual sidecar/ambient, mTLS, egress and namespace-label conventions. Do not guess them.
- If external egress is restricted, add the smallest required project-scoped egress config for approved endpoints; never wildcard allow all.
- ISTIO mode is sidecar.
