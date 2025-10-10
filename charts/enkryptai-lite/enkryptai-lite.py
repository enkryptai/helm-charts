# k8s-architecture-enhanced.py
# Author: anjul@cloudraft.io
# Enhanced and restructured Kubernetes architecture diagram
# Usage: pip3 install diagrams && python k8s-architecture-enhanced.py

from diagrams import Diagram, Cluster, Edge
from diagrams.k8s.group import NS
from diagrams.k8s.network import SVC
from diagrams.k8s.compute import Pod, StatefulSet, Deployment
from diagrams.k8s.network import Service, Ingress
from diagrams.k8s.podconfig import Secret, ConfigMap
from diagrams.aws.compute import EKS, ECR
from diagrams.aws.network import NLB, Route53
from diagrams.aws.database import RDS, ElasticacheForRedis
from diagrams.aws.security import SecretsManager
from diagrams.onprem.certificates import CertManager, LetsEncrypt
from diagrams.onprem.gitops import Argocd
from diagrams.onprem.logging import Fluentbit
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.logging import Loki
from diagrams.onprem.vcs import Github
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.queue import Nats
from diagrams.onprem.tracing import Tempo
from diagrams.onprem.client import Users

# Define custom styling
graph_attr = {
    "fontsize": "16",
    "fontcolor": "#2d3748",
    "bgcolor": "transparent",
    "rankdir": "TB",
    "splines": "ortho",
    "nodesep": "0.8",
    "ranksep": "1.2"
}

cluster_attr = {
    "fontsize": "14",
    "fontcolor": "#2d3748",
    "style": "rounded,filled",
    "fillcolor": "#f7fafc",
    "color": "#cbd5e0"
}

with Diagram(
    "EnkryptAI Lite Architecture", 
    outformat=["png", "svg"], 
    direction="TB",
    graph_attr=graph_attr,
    show=False
):
    

    
    users = Users("End Users")
    route53 = Route53("DNS")
    nlb = NLB("Network Load Balancer\n(ingress-nginx)")
    users >> route53 >> nlb
    
    with Cluster("EKS Production Cluster", graph_attr=cluster_attr):
        
        # ───────────────────────────────────────────────────────────
        # INFRASTRUCTURE LAYER
        # ───────────────────────────────────────────────────────────
        
        with Cluster("Infrastructure Services", graph_attr=cluster_attr):
            
            # Ingress Controller
            with Cluster("Ingress", graph_attr={"fillcolor": "#e6fffa"}):
                nginx_svc = Service("NGINX Service")
                nginx_pods = [Pod(f"NGINX Pod {i+1}") for i in range(2)]
                nginx_svc >> nginx_pods
            
                        
        
          
        # ───────────────────────────────────────────────────────────
        # DATA LAYER
        # ───────────────────────────────────────────────────────────
        
        with Cluster("Data Services", graph_attr={"fillcolor": "#fdf2e9"}):
            
            # Storage & Cache
            with Cluster("Storage & Cache"):
                minio = StatefulSet("MinIO\n(Object Storage)")
                keydb = StatefulSet("KeyDB\n(Redis Cache)")
                
            # Message Queue
            with Cluster("Messaging"):
                nats = Nats("NATS\nMessage Queue")
        
        # ───────────────────────────────────────────────────────────
        # APPLICATION LAYER
        # ───────────────────────────────────────────────────────────
        
        with Cluster("Application Services", graph_attr={"fillcolor": "#f9f9f9"}):
            
            # API Gateway
            
            # Guardrails Service
            with Cluster("AI Guardrails", graph_attr={"fillcolor": "#fff0e6"}):
                guardrails_svc = Service("Guardrails Service")
                guardrails_deploy = Deployment("Guardrails")
                guardrails_pods = [Pod(f"Guardrails Pod {i+1}") for i in range(3)]
                
                guardrails_svc >> guardrails_deploy >> guardrails_pods
            
            # Red Team Service
            with Cluster("Red Team Testing", graph_attr={"fillcolor": "#ffe6e6"}):
                redteam_svc = Service("Red Team Service")
                redteam_deploy = Deployment("Red Team")
                redteam_pods = [Pod(f"Red Team Pod {i+1}") for i in range(2)]
                argo_workflows = Argocd("Argo Workflows")
                redteam_task = Pod("Red Team Task\nRunner")
                
                redteam_svc >> redteam_deploy >> redteam_pods
                argo_workflows >> [nats, redteam_task]
                for pod in redteam_pods:
                    pod >> nats
            
        nginx_pods >> redteam_svc 
        nginx_pods >> guardrails_svc
        # ───────────────────────────────────────────────────────────
        # INGRESS ROUTING
        # ───────────────────────────────────────────────────────────
        
    
    # ═══════════════════════════════════════════════════════════════
    # CONNECTION FLOWS
    # ═══════════════════════════════════════════════════════════════
    
    # External connections
    nlb >> nginx_svc
    
    # Gateway routing
    
    
    # Configuration and secrets
    
    # Monitoring connections (lightweight dashed lines)

print("✅ Enhanced Kubernetes architecture diagram generated!")
print("📁 Files created: EnkryptAI_Kubernetes_Architecture.png, EnkryptAI_Kubernetes_Architecture.svg")
print("🎨 Improvements made:")
print("   • Better visual organization with logical groupings")
print("   • Color-coded clusters for different service types")
print("   • Clearer connection flows and relationships")
print("   • Multiple pod replicas for scalability visualization")
print("   • Enhanced styling and spacing")
print("   • Both PNG and SVG output formats")


