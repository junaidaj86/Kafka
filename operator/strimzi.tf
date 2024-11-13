terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Providers to connect with the Kubernetes and Helm
provider "kubernetes" {
  config_path = "~/.kube/config"  # Kind cluster config path
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Kafka Cluster Deployment - 3 Kafka and 3 Zookeeper replicas
resource "kubernetes_manifest" "strimzi_kafka" {
  manifest = {
    apiVersion = "kafka.strimzi.io/v1beta2"
    kind       = "Kafka"
    metadata = {
      name      = "my-kafka-cluster"
      namespace = "strimzi"
    }
    spec = {
      kafka = {
        replicas = 3
        listeners = [
          {
            name = "plain"
            port = 9092
            type = "internal"
            tls  = false
          }
          ,
          # {
          #   name     = "external"
          #   port     = 9094
          #   type     = "loadbalancer"
          #   tls      = false
          # }
        ]
        config = {
          "offsets.topic.replication.factor" = 3
          "transaction.state.log.replication.factor" = 3
          "transaction.state.log.min.isr" = 2
          "log.message.format.version" = "2.8"
        }
        storage = {
          type = "ephemeral"
        }
      }

      zookeeper = {
        replicas = 3
        storage = {
          type = "ephemeral"
        }
      }

      entityOperator = {
        topicOperator = {}
        userOperator = {}
      }
    }
  }
}
