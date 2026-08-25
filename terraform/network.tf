# создаем облачную сеть
resource "yandex_vpc_network" "develop" {
  name = "develop-fops-${var.flow}"
}

# создаем приватную подсеть zone A
resource "yandex_vpc_subnet" "develop_a" {
  name           = "develop-fops-${var.flow}-ru-central1-a-private"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id # Нужна для выхода приватных нод в интернет через NAT
}

# создаем приватную подсеть zone B
resource "yandex_vpc_subnet" "develop_b" {
  name           = "develop-fops-${var.flow}-ru-central1-b-private"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id # Нужна для выхода приватных нод в интернет через NAT
}

# создаем публичную подсеть zone A (для Bastion, Zabbix, Kibana, ALB)
resource "yandex_vpc_subnet" "public_a" {
  name           = "develop-fops-${var.flow}-ru-central1-a-public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.10.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

# создаем NAT для выхода в интернет приватных машин
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "fops-gateway-${var.flow}"
  shared_egress_gateway {}
}

# создаем сетевой маршрут для выхода в интернет через NAT
resource "yandex_vpc_route_table" "rt" {
  name       = "fops-route-table-${var.flow}"
  network_id = yandex_vpc_network.develop.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# Защита Бастион-хоста (доступен только SSH снаружи)
resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    description    = "Allow SSH from anywhere"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Внутренний обмен трафиком (LAN) между всеми ВМ внутри VPC
resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    description    = "Allow traffic from public subnet"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.10.0/24"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    description    = "Allow traffic from private subnet A"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.1.0/24"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    description    = "Allow traffic from private subnet B"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.2.0/24"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    description       = "Allow traffic and healthchecks from ALB"
    protocol          = "TCP"
    port              = 80
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    description    = "Permit ANY internal and external"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Публичный доступ к балансировщику веб-сайта и веб-панелям Zabbix / Kibana
resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id

  # Доступ к балансировщику сайта (протокол HTTP)
  ingress {
    description    = "Allow HTTP traffic to ALB"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Доступ к веб-интерфейсу Zabbix
  ingress {
    description    = "Allow Zabbix Web Interface"
    protocol       = "TCP"
    port           = 8080
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # Доступ к веб-интерфейсу Kibana
  ingress {
    description    = "Allow Kibana Web Interface"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
