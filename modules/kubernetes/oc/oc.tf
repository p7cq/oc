# Secret

resource "kubernetes_secret_v1" "this" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    name      = join("-", [var.oc.name, "secret"])
    namespace = var.namespace
  }

  data = {
    "mysql-admin-password"      = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).mysql-admin-password
    "mysql-nc-user"             = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).mysql-nc-user
    "mysql-nc-password"         = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).mysql-nc-password
    "nc-user"                   = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).nc-user
    "nc-password"               = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).nc-password
    "nc-smtp-host"              = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).nc-smtp-host
    "nc-smtp-mail-domain"       = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).nc-smtp-mail-domain
    "nc-smtp-mail-from-address" = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).nc-smtp-mail-from-address
    "nc-smtp-user"              = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).nc-smtp-user
    "nc-smtp-password"          = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).nc-smtp-password
    "redis-password"            = jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).redis-password
  }

  type = "Opaque"
}

# Config map

resource "kubernetes_config_map_v1" "apache_default" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    labels = {
      app = "nextcloud"
    }
    name      = "apache-default-cm"
    namespace = var.namespace
  }

  data = {
    "000-default.conf" = <<EOF
ServerName ${var.oc.load_balancer_host}

<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html/>
        Options +FollowSymlinks
        AllowOverride All
        Satisfy Any
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
         SetEnv HOME /var/www/html
         SetEnv HTTP_HOME /var/www/html
    </Directory>

    ErrorLog $${APACHE_LOG_DIR}/error.log
    CustomLog $${APACHE_LOG_DIR}/access.log combined

    Redirect 301 /.well-known/caldav https://${var.oc.load_balancer_host}/remote.php/dav
    Redirect 301 /.well-known/carddav https://${var.oc.load_balancer_host}/remote.php/dav
</VirtualHost>
EOF
  }
}

resource "kubernetes_config_map_v1" "sql_script" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    labels = {
      app = "mysql"
    }
    name      = "count-background-jobs-cm"
    namespace = var.namespace
  }

  data = {
    "count-jobs.sh" = <<EOF
#!/usr/bin/env bash

export MYSQL_PWD='${jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).mysql-nc-password}'
mysql -u ${jsondecode(base64decode(data.oci_secrets_secretbundle.this.secret_bundle_content.0.content)).mysql-nc-user} -NBe "select count(*) from ${var.oc.name}.oc_jobs where last_run = 0;"

exit 0

EOF
  }
}

# Persistent volume

resource "kubernetes_persistent_volume_v1" "this" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    labels = {
      type = "Local"
    }
    name = "oc-pv"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "120Gi"
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "hostname"
            operator = "In"
            values   = [lookup(var.worker_hostname_map, 0)]
          }
        }
      }
    }
    persistent_volume_source {
      local {
        path = "/mnt/storage"
      }
    }
    storage_class_name = "local-storage"
    volume_mode        = "Filesystem"
  }

  timeouts { create = "30s" }
}

resource "kubernetes_persistent_volume_claim_v1" "this" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    name      = "oc-pv-claim"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "120Gi"
      }
    }
    storage_class_name = "local-storage"
  }

  timeouts { create = "30s" }
}

# Service

resource "kubernetes_service_v1" "mysql" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    name      = "mysql"
    namespace = var.namespace
  }
  spec {
    port {
      port = 3306
    }
    selector = {
      app = "mysql"
    }
  }
}

resource "kubernetes_service_v1" "redis" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    name      = "redis"
    namespace = var.namespace
  }
  spec {
    port {
      port = 6379
    }
    selector = {
      app = "redis"
    }
  }
}

resource "kubernetes_service_v1" "nextcloud" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    name      = "nextcloud-service"
    namespace = var.namespace
  }
  spec {
    port {
      port = 80
    }
    selector = {
      app = "nextcloud"
    }
    type = "ClusterIP"
  }
}

# Deployment

resource "kubernetes_deployment_v1" "redis" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    labels = {
      app = "redis"
    }
    name      = "redis"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redis"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          app = "redis"
        }
      }
      spec {
        container {
          image             = join(":", ["redis", var.oc.version.redis])
          image_pull_policy = "IfNotPresent"
          name              = "redis"
          args              = ["--requirepass $(REDIS_AUTH)"]
          env {
            name = "REDIS_AUTH"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "redis-password"
              }
            }
          }
          port {
            container_port = 6379
            name           = "redis"
          }
        }
        node_selector = {
          hostname = lookup(var.worker_hostname_map, 0)
        }
      }
    }
  }

  timeouts { create = "30s" }

  depends_on = [kubernetes_secret_v1.this]
}

resource "kubernetes_deployment_v1" "mysql" {
  count = var.oc.kubernetes && !var.reset ? 1 : 0

  metadata {
    labels = {
      app = "mysql"
    }
    name      = "mysql"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        container {
          image             = join(":", ["mysql", var.oc.version.mysql])
          image_pull_policy = "IfNotPresent"
          name              = "mysql"
          args              = ["--transaction-isolation=READ-COMMITTED", "--log-bin", "--binlog-format=ROW"]
          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "mysql-admin-password"
              }
            }
          }
          env {
            name  = "MYSQL_DATABASE"
            value = var.oc.name
          }
          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "mysql-nc-user"
              }
            }
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "mysql-nc-password"
              }
            }
          }
          port {
            container_port = 3306
            name           = "mysql"
          }
          volume_mount {
            mount_path = "/var/lib/mysql"
            name       = "mysql-volume"
            sub_path   = "mysql"
          }
          volume_mount {
            mount_path = "/usr/local/bin/count-jobs.sh"
            name       = "count-jobs-script"
            sub_path   = "count-jobs.sh"
          }
        }
        node_selector = {
          hostname = lookup(var.worker_hostname_map, 0)
        }
        volume {
          name = "mysql-volume"
          persistent_volume_claim {
            claim_name = "oc-pv-claim"
          }
        }
        volume {
          name = "count-jobs-script"
          config_map {
            name         = "count-background-jobs-cm"
            default_mode = "0755"
          }
        }
      }
    }
  }

  timeouts { create = "60s" }

  depends_on = [
    kubernetes_secret_v1.this,
    kubernetes_config_map_v1.sql_script,
    kubernetes_persistent_volume_claim_v1.this
  ]
}

resource "time_sleep" "this" {
  count = var.oc.kubernetes && !var.reset ? 1 : 0

  create_duration = "30s"

  depends_on = [kubernetes_deployment_v1.mysql]
}

resource "kubernetes_deployment_v1" "nextcloud" {
  count = var.oc.kubernetes && !var.reset ? 1 : 0

  metadata {
    labels = {
      app = "nextcloud"
    }
    name      = "nextcloud"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nextcloud"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          app = "nextcloud"
        }
      }
      spec {
        container {
          image             = join(":", ["nextcloud", var.oc.version.nextcloud])
          image_pull_policy = "IfNotPresent"
          name              = "nextcloud"

          env {
            name  = "MYSQL_DATABASE"
            value = var.oc.name
          }
          env {
            name  = "MYSQL_HOST"
            value = join(".", ["mysql", var.namespace, "svc.cluster.local"])
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "mysql-nc-password"
              }
            }
          }
          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "mysql-nc-user"
              }
            }
          }
          env {
            name = "NEXTCLOUD_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "nc-password"
              }
            }
          }
          env {
            name = "NEXTCLOUD_ADMIN_USER"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "nc-user"
              }
            }
          }
          env {
            name  = "NEXTCLOUD_TRUSTED_DOMAINS"
            value = var.oc.load_balancer_host
          }
          env {
            name  = "REDIS_HOST"
            value = join(".", ["redis", var.namespace, "svc.cluster.local"])
          }
          env {
            name = "REDIS_HOST_PASSWORD"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "redis-password"
              }
            }
          }
          env {
            name = "SMTP_HOST"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "nc-smtp-host"
              }
            }
          }
          env {
            name  = "SMTP_SECURE"
            value = "tls"
          }
          env {
            name  = "SMTP_PORT"
            value = "587"
          }
          env {
            name  = "SMTP_AUTHTYPE"
            value = "LOGIN"
          }
          env {
            name = "SMTP_PASSWORD"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "nc-smtp-password"
              }
            }
          }
          env {
            name = "SMTP_NAME"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "nc-smtp-user"
              }
            }
          }
          env {
            name = "MAIL_FROM_ADDRESS"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "nc-smtp-mail-from-address"
              }
            }
          }
          env {
            name = "MAIL_DOMAIN"
            value_from {
              secret_key_ref {
                name = "oc-secret"
                key  = "nc-smtp-mail-domain"
              }
            }
          }
          env {
            name  = "TRUSTED_PROXIES"
            value = join(" ", [var.load_balancer_ip, var.load_balancer_cidr])
          }
          env {
            name  = "OVERWRITEPROTOCOL"
            value = "https"
          }
          env {
            name  = "NC_default_phone_region"
            value = "RO"
          }
          env {
            name  = "NC_skeletondirectory"
            value = ""
          }
          env {
            name  = "PHP_UPLOAD_LIMIT"
            value = var.max_upload_size
          }
          port {
            container_port = 80
          }
          volume_mount {
            mount_path = "/var/www/html/data"
            name       = "nextcloud-volume"
            sub_path   = "nextcloud"
          }
          volume_mount {
            mount_path = "/etc/apache2/sites-available/000-default.conf"
            name       = "apache-config"
            sub_path   = "000-default.conf"
          }
        }
        node_selector = {
          hostname = lookup(var.worker_hostname_map, 0)
        }
        volume {
          name = "nextcloud-volume"
          persistent_volume_claim {
            claim_name = "oc-pv-claim"
          }
        }
        volume {
          name = "apache-config"
          config_map {
            name = "apache-default-cm"
          }
        }
      }
    }
  }

  timeouts { create = "60s" }

  depends_on = [
    kubernetes_config_map_v1.apache_default,
    time_sleep.this
  ]
}

# Ingress

resource "kubernetes_ingress_v1" "this" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    name = "nextcloud-ingress"
    annotations = {
      "cert-manager.io/issuer"                              = var.issuer.name
      "kubernetes.io/ingress.class"                         = "nginx"
      "nginx.ingress.kubernetes.io/permanent-redirect-code" = "301"
      "nginx.ingress.kubernetes.io/proxy-body-size"         = var.max_upload_size
    }
    namespace = var.namespace
  }
  spec {
    tls {
      hosts       = [var.oc.load_balancer_host]
      secret_name = var.ingress_secret_name
    }
    rule {
      host = var.oc.load_balancer_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "nextcloud-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_v1.nextcloud]
}

# Cronjob

resource "kubernetes_cron_job_v1" "this" {
  count = var.oc.kubernetes ? 1 : 0

  metadata {
    name      = "nextcloud-cronjob"
    namespace = var.namespace
  }
  spec {
    schedule = "*/1 * * * *"
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              args              = ["-s", join("/", [join("//", ["https:", var.oc.load_balancer_host]), "cron.php"])]
              image             = "curlimages/curl"
              image_pull_policy = "IfNotPresent"
              name              = "curl"
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_ingress_v1.this]
}
