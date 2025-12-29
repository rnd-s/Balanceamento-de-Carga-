# Infraestrutura de Balanceamento de Carga com Alta Disponibilidade

Este projeto implementa uma **infraestrutura  para sistemas Web**, com foco em:

- **Alta Disponibilidade (HA)**
- **Balanceamento de Carga**
- **Monitoramento em Tempo Real**
- **Tolerância a Falhas**

O ambiente foi projetado para suportar **falhas críticas de servidores** e **picos de tráfego**, mantendo a disponibilidade do serviço para o cliente final.

---

## Arquitetura do Projeto

A infraestrutura é composta por **Máquinas Virtuais (VMs) isoladas**, comunicando-se através de uma rede interna, simulando um ambiente de produção real.

| Componente       | Tecnologia             | Função                                                                 |
|------------------|------------------------|------------------------------------------------------------------------|
| Load Balancer    | HAProxy                | Recebe todo o tráfego e distribui entre os servidores (Round Robin).  |
| App Cluster      | Nginx + Docker         | 3 réplicas da aplicação web rodando em containers isolados.           |
| Cache            | Redis                  | Cache de sessão e dados de acesso rápido.                             |
| Monitoramento    | Prometheus + Grafana   | Coleta métricas e visualiza a saúde dos nós.                          |
| Gateway          | pfSense (Opcional)     | Gerenciamento de rede, firewall e segmentação.                        |

---
## Ambiente de Execução

Este projeto foi desenvolvido e testado em um ambiente **virtualizado com múltiplas máquinas virtuais no VirtualBox**.

**Importante:**  
Clonar este repositório **não cria automaticamente as máquinas virtuais** nem configura a topologia de rede.

Para reproduzir o experimento, é necessário:

- Criar manualmente as VMs no VirtualBox
- Configurar a rede interna entre elas
- Atribuir os IPs conforme descrito na arquitetura
- Instalar Docker e Docker Compose em cada VM
- Executar os serviços conforme a seção *Como Executar*

Este repositório contém **todas as configurações, scripts e documentação necessários**, mas **depende de infraestrutura externa** para funcionamento completo.


## Funcionalidades e Resultados

### Balanceamento de Carga

Utilizando o **HAProxy**, o tráfego é distribuído igualmente entre os nós `web1`, `web2` e `web3`, evitando sobrecarga em um único servidor.

### Alta Disponibilidade (Failover)

O sistema detecta falhas automaticamente nos nós de aplicação.

**Teste realizado:**  
O container `web1` foi desligado propositalmente (`docker stop`).

**Resultado:**  
O HAProxy identificou a falha em menos de **2 segundos** e redirecionou o tráfego para `web2` e `web3`. O cliente final continuou recebendo respostas **HTTP 200 OK**, sem interrupção perceptível.

---

##  Como Testar o Sistema

Esta seção descreve **os testes reais executados**, incluindo **comandos**, **métricas observadas** e **resultados obtidos**, garantindo a reprodutibilidade do experimento.

---

###  Teste 1 — Monitoramento de Saúde dos Backends (HAProxy)

**Objetivo:**
Verificar se o HAProxy detecta corretamente o estado dos servidores backend (`UP/DOWN`).

 **VM:** VM 2 — HAProxy

Execute:

```bash
curl -s http://10.0.10.10:9101/metrics | grep "haproxy_server_up"
```

**Resultado esperado:**

* Valor `1` → servidor **UP**
* Valor `0` → servidor **DOWN**

**Resultado obtido:**

```text
haproxy_server_up{backend="web_servers",server="web1"} 1
haproxy_server_up{backend="web_servers",server="web2"} 1
haproxy_server_up{backend="web_servers",server="web3"} 1
```

Caso apareça `0`, aguarde cerca de **10 segundos**, pois o *health check* do HAProxy possui atraso intencional.

---

###  Teste 2 — Teste de Estresse (Carga / DDoS Simulado)

**Objetivo:**
Simular um pico de acessos concorrentes e validar o balanceamento de carga.

 **VM:** VM 5 — Monitor (atuando como cliente)

Instale o Apache Benchmark (se necessário):

```bash
sudo apt-get install apache2-utils
```

Execute o teste:

```bash
ab -n 10000 -c 100 http://10.0.10.10/
```

**Parâmetros:**

* `-n 10000` → 10.000 requisições totais
* `-c 100` → 100 usuários simultâneos

**Resultado obtido:**

```text
Complete requests:      10000
Failed requests:        0
Requests per second:    75.59 [#/sec]
```

 **100% das requisições atendidas**
 **Zero falhas**
Serviço permaneceu disponível durante todo o teste

---

###  Teste 3 — Prova do Balanceamento de Carga via Métricas

Após o teste de estresse, volte à **VM 2 (HAProxy)** e execute:

```bash
curl -s http://10.0.10.10:9101/metrics | grep "haproxy_backend_sessions_total"
```

**Resultado obtido:**

```text
haproxy_backend_sessions_total{backend="web_servers"} 10000
```

 Este valor confirma que o HAProxy processou todas as requisições, distribuindo-as entre `web1`, `web2` e `web3`.

---

###  Teste 4 — Monitoramento em Tempo Real (Modo Texto)

**Objetivo:**
Visualizar em tempo real o estado dos servidores backend.

 **VM:** VM 2 — HAProxy

Execute:

```bash
watch -n 1 "curl -s http://10.0.10.10:9101/metrics | grep haproxy_server_up"
```

**Interpretação:**

* `1` → servidor ativo
* `0` → servidor indisponível

---

###  Teste 5 — Failover (Alta Disponibilidade)

####  Sabotagem Controlada

 **VM:** VM 3 — App

Desligue propositalmente um servidor:

```bash
sudo docker stop web1
```

---

####  Observação do Failover

**VM:** VM 2 — HAProxy

Após **2 a 5 segundos**, o monitoramento mostrará:

```text
haproxy_server_up{server="web1"} 0
```

Confirmando que o HAProxy detectou a falha.

---

####  Prova de Vida do Sistema

Ainda com o `web1` desligado, execute:

```bash
curl -I http://10.0.10.10
```

**Resultado esperado:**

```text
HTTP/1.1 200 OK
```

 O serviço permanece disponível
O tráfego é redirecionado automaticamente para `web2` e `web3`

---

####  Ressurreição do Nó

**VM:** VM 3 — App

```bash
sudo docker start web1
```

Após alguns segundos, o status volta para:

```text
haproxy_server_up{server="web1"} 1
```

 O nó é reintegrado automaticamente ao cluster

---

## Estrutura do Repositório

```text
├── vm2-loadbalancer/      # Configurações do HAProxy
│   ├── haproxy.cfg
│   └── docker-compose.yml
│
├── vm3-app/               # Cluster de Aplicação (Nginx + Redis)
│   ├── app/               # Código da aplicação web
│   ├── nginx/             # Configurações do proxy reverso
│   └── docker-compose.yml
│
└── vm5-monitor/           # Stack de Observabilidade
    ├── prometheus/
    └── docker-compose.yml
```

---

## Como Executar

### Requisitos

- Linux (Ubuntu Server recomendado)
- Docker Engine
- Docker Compose
- VirtualBox ou ambiente virtualizado equivalente

## Execução Automatizada (Vagrant)

Opcionalmente, toda a infraestrutura pode ser provisionada automaticamente
utilizando **Vagrant + VirtualBox**.

### Requisitos
- VirtualBox
- Vagrant

### Subir o ambiente

```bash
cd vagrant
vagrant up

### Passo 1 - Cluster de Aplicação

```bash
cd vm3-app
docker-compose up -d
```

Inicia 3 servidores web nas portas `8081`, `8082` e `8083`.

### Passo 2 - Load Balancer

```bash
cd vm2-loadbalancer
docker-compose up -d
```

O serviço estará acessível na **porta 80** da VM.

### Passo 3 - Monitoramento

```bash
cd vm5-monitor
docker-compose up -d
```

Acesse o **Grafana** pela porta `3000`.

---

## Considerações de Segurança (Disclaimer)

Este projeto foi desenvolvido com **finalidade educacional e acadêmica**.

- Credenciais estão visíveis nos arquivos `docker-compose.yml` para facilitar testes.
- **Não recomendado para produção sem ajustes.**

Em ambientes reais, recomenda-se:

- Uso de **variáveis de ambiente (.env)** não versionadas
- **Docker Secrets** ou **Vault**
- Redes Docker internas sem exposição de serviços sensíveis
- O projeto roda todo na porta 80 (HTTP). Num cenário real, o HAProxy deveria fazer o SSL Offloading (receber na 443 HTTPS, descriptografar e passar para o interno via HTTP)

---

## Licença

Este projeto é distribuído sob a licença **MIT**.
