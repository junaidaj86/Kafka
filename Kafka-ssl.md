# Strimzi Kafka SSL/TLS Authentication with Self-Signed CA

This guide outlines the steps to configure SSL/TLS authentication for Strimzi Kafka brokers and clients using a self-signed Certificate Authority (CA). This includes creating the CA, generating the broker and client certificates, and configuring the necessary keystores and truststores.

## Prerequisites
- OpenSSL installed on your machine.
- Basic understanding of how Strimzi Kafka works with SSL/TLS.
- Ability to interact with Kafka and Strimzi components (if deploying within a Kubernetes environment).

## Steps

### 1. **Create a Self-Signed CA**

First, generate the private key and self-signed certificate for your Certificate Authority (CA).

```bash
# Create the private key for the CA
openssl genrsa -out ~/ca/private/ca.key 4096

# Set appropriate permissions for the private key
chmod 400 ~/ca/private/ca.key

# Generate the self-signed certificate for the CA
openssl req -x509 -new -nodes -key ~/ca/private/ca.key -sha256 -days 3650 \
  -out ~/ca/certs/ca.crt -subj "/CN=Strimzi-CA"
```

This will generate:
- A private key for the CA: `~/ca/private/ca.key`
- The CA certificate: `~/ca/certs/ca.crt`

### 2. **Generate Broker Certificate Signed by the CA**

Now, generate the broker's private key and certificate signing request (CSR), and then sign the broker's certificate using the CA.

```bash
# Generate the broker's private key
openssl genrsa -out broker.key 2048

# Generate the broker's CSR
openssl req -new -key broker.key -out broker.csr -subj "/CN=broker.example.com"

# Sign the broker's CSR with the CA certificate to generate the broker's certificate
openssl x509 -req -in broker.csr -CA ~/ca/certs/ca.crt -CAkey ~/ca/private/ca.key \
  -CAcreateserial -out broker.crt -days 365 -sha256
```

This will generate:
- The broker's private key: `broker.key`
- The broker's certificate signed by the CA: `broker.crt`

### 3. **Generate Client Certificate Signed by the CA**

Next, generate the client's private key and CSR, and then sign the client's certificate using the CA.

```bash
# Generate the client's private key
openssl genrsa -out client.key 2048

# Generate the client's CSR
openssl req -new -key client.key -out client.csr -subj "/CN=client.example.com"

# Sign the client's CSR with the CA certificate to generate the client's certificate
openssl x509 -req -in client.csr -CA ~/ca/certs/ca.crt -CAkey ~/ca/private/ca.key \
  -CAcreateserial -out client.crt -days 365 -sha256
```

This will generate:
- The client's private key: `client.key`
- The client's certificate signed by the CA: `client.crt`

### 4. **Configure the Kafka Broker for SSL/TLS Authentication**

Now that you have the broker certificate (`broker.crt`), private key (`broker.key`), and CA certificate (`ca.crt`), configure Strimzi Kafka to use SSL/TLS.

1. Create a `Kafka` custom resource (CR) in Strimzi with the SSL configuration for the broker.

Example `Kafka` CR:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    version: 3.5.1
    replicas: 3
    listeners:
      - name: external
        port: 9093
        tls: true
        type: nodeport
    authentication:
      type: tls
    config:
      ssl.keystore.location: /tmp/kafka/keystore.p12
      ssl.keystore.password: <keystore-password>
      ssl.truststore.location: /tmp/kafka/truststore.p12
      ssl.truststore.password: <truststore-password>
```

- **`ssl.keystore.location`**: Path to the broker’s keystore file (which contains the broker's certificate and private key).
- **`ssl.truststore.location`**: Path to the broker’s truststore (which contains the CA certificate).

### 5. **Configure the Kafka Client for SSL/TLS Authentication**

To connect to the Kafka broker securely, configure your client (producer or consumer) to use SSL/TLS.

Create a `client.properties` file:

```properties
security.protocol=SSL
ssl.truststore.location=/path/to/truststore.p12
ssl.truststore.password=<truststore-password>
ssl.keystore.location=/path/to/client.keystore.p12
ssl.keystore.password=<keystore-password>
ssl.key.password=<key-password>
```

The `client.keystore.p12` and `client.truststore.p12` files should contain:
- The client's private key and certificate (in the keystore).
- The CA certificate (in the truststore).

### 6. **Verify the Setup**

1. **Verify Kafka Broker Logs**:
   Check the Kafka broker logs to ensure SSL/TLS has been correctly configured:
   ```bash
   kubectl logs <kafka-broker-pod-name> -n kafka-namespace
   ```

2. **Test the Client-Broker Connection**:
   Use `kafka-console-producer` and `kafka-console-consumer` with the SSL configuration:

   ```bash
   kafka-console-producer --broker-list <broker-address>:9093 --topic test-topic \
   --producer.config client.properties
   ```

   ```bash
   kafka-console-consumer --bootstrap-server <broker-address>:9093 --topic test-topic \
   --consumer.config client.properties --from-beginning
   ```

3. **Use `openssl` to Test the SSL Connection**:
   You can also use `openssl s_client` to check if the SSL handshake is working:
   ```bash
   openssl s_client -connect <broker-address>:9093 -CAfile /path/to/client-ca.crt
   ```

## Summary

- **Step 1**: Create a self-signed CA using OpenSSL.
- **Step 2**: Generate broker certificates and sign them using the CA.
- **Step 3**: Generate client certificates and sign them using the same CA.
- **Step 4**: Configure Strimzi Kafka brokers to use SSL/TLS authentication.
- **Step 5**: Configure Kafka clients to authenticate with the broker using SSL/TLS.
- **Step 6**: Verify that the setup works using Kafka tools and `openssl`.

