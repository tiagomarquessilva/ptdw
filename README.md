# Projeto Temático em Desenvolvimento Web

Este é o repositório relativo ao [PTDW](https://www.ua.pt/estga/uc/5163), inserido no Módulo Temático em Desenvolvimento de Aplicações da licenciatura em [Tecnologias da Informação](https://www.ua.pt/estga/course/63/?p=2) lecionada na [Universidade de Aveiro - Escola Superior de Tecnologia e Gestão de Águeda (ESTGA - UA)](https://www.ua.pt/estga/Default.aspx)

## Objetivos

Este projeto tem como objetivo receber os valores obtidos dos equipamentos colocados a monitorizar pessoas acamadas, apresentá-los numa aplicação Web e calibrar esses mesmos equipamentos. A calibração do equipamento consiste em definir a gama de valores de máximos e mínimos do batimento cardíaco e eletromiografia considerados normais da pessoa acamada. É enviado um alerta para a aplicação Web caso o equipamento detete um valor anormal. Os potenciais utilizadores da aplicação Web consistem em profissionais de saúde, cuidadores e administrador. Os pacientes (pessoas acamadas) estão associados a unidades de saúde. O profissional de saúde configura os valores do equipamento da pessoa acamada. A gestão dos equipamentos, profissionais de saúde e unidades de saúde é feita pelo administrador e a gestão dos cuidadores e pacientes é feita pelos profissionais de saúde.

Uma descrição mais detalhada dos requisitos pode ser encontrada na Documentação deste documento. 

## Tecnologias, Protocolos, Software, Etc. Usados

- [Laravel](https://laravel.com/);
- [PostgreSQL](https://www.postgresql.org/);
- [jQuery](https://jquery.com/);
- [Bootstrap](https://getbootstrap.com/);
- JavaScript;
- CSS;
- HTML;
- [Git](https://git-scm.com/);
- UML.

## Instalação

1. Importar a [base de dados](database.sql) para o PostgreSQL;
1. Inserir as credenciais de acesso à BD no [.env](app/.env);
1. Executar os comandos:
```composer install```
```php artisan key:generate```
```chmod -R ug+rwx storage bootstrap/cache```
```chown -R www-data:www-data vendor/```
```chmod -R 775 ./```
```chmod -R 777 storage/```
```chmod -R 777 bootstrap/```
```php artisan db:seed```
```php artisan serve```.

## Documentação

- [Relatório](Relatorio.pdf);

## Autores

Os autores foram os seguintes alunos da Universidade de Aveiro:
- Diogo Santos (Nº Mec. 84062);
- Jorge Godinho (Nº Mec. 25288);            
- Pedro Quinta (Nº Mec. 46367);    
- Ricardo Balreira (Nº Mec. 88078); 
- Tiago Silva (Nº Mec. 87913).     
