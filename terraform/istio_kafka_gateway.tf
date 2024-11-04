# Define Istio Gateway for Kafka to accept external traffic
resource "kubernetes_manifest" "kafka_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "kafka-gateway"
      namespace = "strimzi"
    }
    spec = {
      selector = {
        istio = "ingressgateway"  # Select the default Istio ingress gateway
      }
      servers = [
        {
          port = {
            number   = 9094
            name     = "tcp-kafka"
            protocol = "TCP"
          }
          hosts = ["*"]
        }
      ]
    }
  }
}

# Define Istio VirtualService to route traffic from the gateway to the Kafka service
resource "kubernetes_manifest" "kafka_virtual_service" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "kafka"
      namespace = "strimzi"
    }
    spec = {
      hosts    = ["*"]
      gateways = [kubernetes_manifest.kafka_gateway.metadata[0].name]
      tcp      = [
        {
          match = [
            {
              port = 9094  # Match the external port on the Gateway
            }
          ]
          route = [
            {
              destination = {
                host = "my-kafka-cluster-kafka-bootstrap.strimzi.svc.cluster.local"  # Strimzi Kafka service name
                port = {
                  number = 9092  # Internal Kafka port
                }
              }
            }
          ]
        }
      ]
    }
  }
}
