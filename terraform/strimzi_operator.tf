resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

resource "kubernetes_manifest" "strimzi_operator" {
  depends_on = [kubernetes_namespace.kafka]

  # Use yamldecode to directly insert the namespace into the manifest data
  manifest = yamldecode(
    templatefile("https://strimzi.io/install/latest?namespace=kafka", {
      namespace = kubernetes_namespace.kafka.metadata[0].name
    })
  )
}
