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

Теперь можем проверять работу сервисов.

В частности работу баллансировщика можно проверить обновляя сайт работает по ссылке: http://158.160.151.128/

Файлы для terraform и ansible лежат в директори:  [terraform](https://github.com/PhartomX/sys_dip_netology/tree/main/terraform)
