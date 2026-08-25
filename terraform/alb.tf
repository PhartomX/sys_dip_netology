
# Объединяем приватные веб-сервера для распределения входящего трафика
resource "yandex_alb_target_group" "web_tg" {
  name = "web-target-group-${var.flow}"

  target {
    subnet_id  = yandex_vpc_subnet.develop_a.id
    ip_address = yandex_compute_instance.web_1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.develop_b.id
    ip_address = yandex_compute_instance.web_2.network_interface.0.ip_address
  }
}


# Определяем правила распределения нагрузки и параметры проверки
resource "yandex_alb_backend_group" "web_bg" {
  name = "web-backend-group-${var.flow}"

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_tg.id]
    
    load_balancing_config {
      panic_threshold = 50 
    }    

    healthcheck {
      timeout             = "2s"
      interval            = "5s"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      
      http_healthcheck {
        path = "/index.html" 
      }
    }
  }
}

# Задаем правила маршрутизации URL-путей на созданную группу бэкендов
resource "yandex_alb_http_router" "web_router" {
  name = "web-http-router-${var.flow}"
}

resource "yandex_alb_virtual_host" "web_vh" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "root-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
        timeout          = "5s"
      }
    }
  }
}

#  Единая точка входа (Reverse Proxy) с публичным IP

resource "yandex_alb_load_balancer" "web_alb" {
  name               = "web-load-balancer-${var.flow}"
  network_id         = yandex_vpc_network.develop.id
  security_group_ids = [yandex_vpc_security_group.web_sg.id]

  # Размещение балансировщика в публичной подсети для получения внешнего трафика
  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
    }
  }

  # Слушатель на 80-м порту
  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
}


# Выводит IP-адреса для быстрого копирования после сборки
output "bastion_public_ip" {
  description = "Публичный IP Бастион-сервера для SSH-туннелей"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "zabbix_public_ip" {
  description = "Публичный IP для входа в веб-панель Zabbix (порт 8080)"
  value       = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "kibana_public_ip" {
  description = "Публичный IP для входа в веб-панель Kibana (порт 5601)"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "alb_public_ip" {
  description = "Публичный IP балансировщика для тестирования команды curl"
  value       = yandex_alb_load_balancer.web_alb.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}
