

Este projeto implementa uma infraestrutura robusta para um sistema bancário simulado, focado em Alta Disponibilidade (HA), Balanceamento de Carga e Monitoramento em Tempo Real.

O objetivo foi criar um ambiente que suporte falhas críticas de servidores e picos de tráfego sem interromper o serviço para o cliente final.

Arquitetura do Projeto

A infraestrutura foi dividida em Máquinas Virtuais (VMs) isoladas, comunicando-se através de uma rede interna, simulando um ambiente de produção real.

Componente

Tecnologia

Função

Load Balancer

HAProxy

Recebe todo o tráfego e distribui entre os servidores (Round Robin).

App Cluster

Nginx + Docker

3 réplicas da aplicação web rodando em containers isolados.

Cache

Redis

Cache de sessão e dados rápidos.

Monitoramento

Prometheus + Grafana

Coleta métricas e visualiza a saúde dos nós.

Gateway

pfSense

(Opcional) Gerenciamento de Rede e Firewall.

 Funcionalidades e Resultados

1. Balanceamento de Carga (Load Balancing)

Utilizando o HAProxy, o tráfego é distribuído igualmente entre os nós web1, web2 e web3. Isso evita sobrecarga em um único servidor.

2. Alta Disponibilidade (Failover) 

O sistema é capaz de detectar falhas automaticamente.

Teste Realizado: O container web1 foi desligado propositalmente (docker stop).

Resultado: O HAProxy detectou a falha em < 2 segundos e redirecionou o tráfego para web2 e web3. O cliente recebeu status 200 OK sem interrupção.

3. Teste de Estresse (DDoS Simulado) 

Foi utilizado o Apache Benchmark (ab) para simular um pico de acesso.

Cenário: 10.000 requisições com 100 usuários simultâneos.

Resultado: 100% das requisições atendidas com sucesso (Zero Falhas).

 Estrutura do Repositório

├── vm2-loadbalancer/      # Configurações do HAProxy e Exporter
│   ├── haproxy.cfg
│   └── docker-compose.yml
│
├── vm3-app/               # Cluster de Aplicação (Nginx + Redis)
│   ├── app/               # Código HTML/PHP do site
│   ├── nginx/             # Configurações de Proxy Reverso
│   └── docker-compose.yml
│
└── vm5-monitor/           # Stack de Observabilidade
    ├── prometheus/
    └── docker-compose.yml


Como Executar

Este projeto foi desenhado para rodar em VMs Linux (Ubuntu Server) com Docker Engine instalado.

Passo 1: Configurar a VM de Aplicação

Navegue até a pasta vm3-app e suba o cluster:

cd vm3-app
docker-compose up -d


Isso iniciará 3 servidores web nas portas 8081, 8082 e 8083.

Passo 2: Configurar o Load Balancer

Navegue até a pasta vm2-loadbalancer e inicie o HAProxy:

cd vm2-loadbalancer
docker-compose up -d


O serviço estará acessível na porta 80 da VM.

Passo 3: Configurar o Monitoramento

Navegue até a pasta vm5-monitor:

cd vm5-monitor
docker-compose up -d


Acesse o Grafana na porta 3000.

---

##  Considerações de Segurança (Disclaimer)

Este projeto foi desenvolvido para fins **educacionais e acadêmicos**. Por esse motivo:
1.  As credenciais (senhas de banco e tokens) estão expostas nos arquivos `docker-compose.yml` para facilitar a execução e testes por terceiros.
2.  Em um ambiente de **Produção**, recomenda-se fortemente o uso de:
    -   **Variáveis de Ambiente (.env)** não versionadas.
    -   **Docker Secrets** ou **Vault** para gestão de credenciais.
    -   Rede interna do Docker isolada sem exposição de portas de banco de dados para a rede pública.


