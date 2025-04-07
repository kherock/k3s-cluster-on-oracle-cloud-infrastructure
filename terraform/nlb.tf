resource "oci_network_load_balancer_network_load_balancer" "public_ingress" {
  compartment_id = var.compartment_id
  display_name   = "public-nlb"
  subnet_id      = module.network.cluster_subnet.id

  is_private                     = false
  is_preserve_source_destination = false
  network_security_group_ids     = [module.network.nsg_public_ingress]
}

resource "oci_network_load_balancer_backend_set" "k8s" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id
  name                     = "k8s-server-nodes"
  policy                   = "FIVE_TUPLE"

  is_preserve_source = true

  health_checker {
    protocol           = "HTTPS"
    interval_in_millis = 10000
    port               = 6443
    retries            = 3
    return_code        = 401
    timeout_in_millis  = 3000
    url_path           = "/healthy"
  }
}

resource "oci_network_load_balancer_backend" "k8s" {
  for_each = module.compute.k8s_apiserver_nodes

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id
  backend_set_name         = oci_network_load_balancer_backend_set.k8s.name
  target_id                = each.value.id
  port                     = 6443
}

resource "oci_network_load_balancer_listener" "public_ingress_k8s" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id

  default_backend_set_name = oci_network_load_balancer_backend_set.k8s.name
  name                     = "k8s-apiserver"
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "puffer_sftp" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id
  name                     = "puffer-sftp"
  policy                   = "FIVE_TUPLE"

  is_preserve_source = true

  health_checker {
    protocol           = "TCP"
    port               = 5657
    interval_in_millis = 10000
    retries            = 3
    timeout_in_millis  = 3000
    request_data       = ""
    response_data      = ""
  }
}

resource "oci_network_load_balancer_backend" "puffer_sftp" {
  for_each = module.compute.k8s_apiserver_nodes

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id
  backend_set_name         = oci_network_load_balancer_backend_set.puffer_sftp.name
  target_id                = each.value.id
  port                     = 5657
}

resource "oci_network_load_balancer_listener" "public_ingress_puffer_sftp" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id

  default_backend_set_name = oci_network_load_balancer_backend_set.puffer_sftp.name
  name                     = "puffer-sftp"
  port                     = 5657
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "http" {
  for_each = toset(["HTTP", "HTTPS"])

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id
  name                     = lower(each.key)
  policy                   = "FIVE_TUPLE"

  is_preserve_source = true

  health_checker {
    protocol           = each.key
    interval_in_millis = 10000
    retries            = 3
    return_code        = 404
    timeout_in_millis  = 3000
    url_path           = "/"
  }
}

resource "oci_network_load_balancer_backend" "http" {
  for_each = merge([
    for name, instance in module.compute.k8s_agent_nodes : {
      for protocol, backend_set in oci_network_load_balancer_backend_set.http :
      "${name}:${protocol}" => {
        id          = instance.id
        backend_set = backend_set
        port = lookup({
          HTTP  = 80
          HTTPS = 443
        }, protocol)
      }
    }
  ]...)

  network_load_balancer_id = each.value.backend_set.network_load_balancer_id
  backend_set_name         = each.value.backend_set.name
  target_id                = each.value.id
  port                     = each.value.port
}

resource "oci_network_load_balancer_listener" "public_ingress_http" {
  for_each = {
    HTTP = 80
    HTTPS = 443
  }

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id

  default_backend_set_name = oci_network_load_balancer_backend_set.http[each.key].name
  name                     = lower(each.key)
  port                     = each.value
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "minecraft" {
  for_each = toset(["minecraft", "minecraft-bedrock"])

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id
  name                     = each.key
  policy                   = "FIVE_TUPLE"

  is_preserve_source = true
  is_fail_open       = true

  health_checker {
    protocol           = "TCP"
    port               = 25565
    interval_in_millis = 10000
    retries            = 3
    timeout_in_millis  = 3000
    request_data       = ""
    response_data      = ""
  }
}

resource "oci_network_load_balancer_backend" "minecraft" {
  for_each = {
    for name, instance in module.compute.k8s_agent_nodes :
    name => instance.id
  }

  network_load_balancer_id = oci_network_load_balancer_backend_set.minecraft["minecraft"].network_load_balancer_id
  backend_set_name         = oci_network_load_balancer_backend_set.minecraft["minecraft"].name
  target_id                = each.value
  port                     = 25565
}

resource "oci_network_load_balancer_backend" "minecraft_bedrock" {
  for_each = {
    for name, instance in module.compute.k8s_agent_nodes :
    name => instance.id
  }

  network_load_balancer_id = oci_network_load_balancer_backend_set.minecraft["minecraft-bedrock"].network_load_balancer_id
  backend_set_name         = oci_network_load_balancer_backend_set.minecraft["minecraft-bedrock"].name
  target_id                = each.value
  port                     = 19132
}

resource "oci_network_load_balancer_listener" "public_ingress_minecraft" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id

  default_backend_set_name = oci_network_load_balancer_backend_set.minecraft["minecraft"].name
  name                     = "minecraft"
  port                     = 25565
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_listener" "public_ingress_minecraft_bedrock" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.public_ingress.id

  default_backend_set_name = oci_network_load_balancer_backend_set.minecraft["minecraft-bedrock"].name
  name                     = "minecraft-bedrock"
  port                     = 19132
  protocol                 = "UDP"
}
