Дипломная работа по профессии «`Системный администратор`» - `Алексей Сидоров`
---

### Задача.

Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. 

Подготавливаем файлы для terraform и запускаем:
```
terraform init
terraform apply
```

Видим в Yandex Cloud развёрнутую инфраструктуру:

![img1](https://github.com/PhartomX/sys_dip_netology/blob/main/img/img1.png)

![img2](https://github.com/PhartomX/sys_dip_netology/blob/main/img/img2.png)


Применяем плейбуки:

```
ansible-playbook -i host.ini site.yml
```

### `Сайт`

Cсылка на сайт: http://158.160.152.148/

Работу баллансировщика можно проверить обновляя сайт.

### `Мониторинг`

Добавляем все созданные ВМ на Zabbix-сервер:

![img3](https://github.com/PhartomX/sys_dip_netology/blob/main/img/img3.png)

Создаём дашборд для мониторинга ресурсов:

![img4](https://github.com/PhartomX/sys_dip_netology/blob/main/img/img4.png)

Просмотр возможен под пользователем `guest` по ссылке http://89.169.136.113:8080/

### `Логи`

Подключаемся по ссылке http://89.169.130.105:5601/ , создаём `Index patterns` в `Kibana`, переходим в `Discover` и видим собранные логи.
Для удобства отфильтровал логи и сохранил применённые фильтры под именем `SYS_DIP_LOG`:

![img5](https://github.com/PhartomX/sys_dip_netology/blob/main/img/img5.png)


### `Сеть`

Настройку сети можно посмотреть в файлах terraform.

Файлы для terraform и ansible лежат в директории:
[terraform](https://github.com/PhartomX/sys_dip_netology/tree/main/terraform)
