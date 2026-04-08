# 💻 **_Prometheus_** 

**_Prometheus_** é um projeto pessoal desenvolvido como portfólio backend em **_Elixir_**, utilizando o framework **_Phoenix_**. A aplicação incorpora práticas modernas de desenvolvimento e integra ferramentas como **_Argon2_** para hashing de senhas e **_SnowflakeID_** para geração de identificadores distribuídos. Além disso, faz uso de tecnologias como **_Docker_**, **_Redis_** e **_PostgreSQL_**.

## 🌎 **_Prerequisites_**

- Instalar [**_Git_**](https://git-scm.com/).
- Instalar [**_Elixir_**](https://elixir-lang.org/install.html). (_Necessário somente para deploy **Localmente**._)
- Instalar [**_Erlang/OTP_**](https://www.erlang.org/downloads). (_Necessário somente para deploy **Localmente**._)
- Instalar [**_Docker_**](https://www.docker.com/). (_Necessário somente para deploy em container **Docker**._)
- Instalar [**_PostgreSQL_**](https://www.postgresql.org/). (_Necessário somente para deploy **Localmente**._)
- Instalar [**_Redis_**](https://redis.io/). (_Necessário somente para deploy **Localmente**._)

### 🚚 **_Installation_**

1. Clone o repositório usando **_`git clone https://github.com/NukeZzZin/prometheus.git`_** no seu terminal.
2. Entre na pasta do repositório usando **_`cd prometheus`_** no seu terminal.

#### 📦 **_Docker Compose deploy_**

1. Construa o container **_Docker_** usando **_`docker-compose build`_** no seu terminal.
2. Definir as variáveis de ambiente em um arquivo **_`.env`_**, seguindo o exemplo de **_`.env.example`_**.
3. Inicialize o container **_Docker_** usando **_`docker-compose --profile application up`_** no seu terminal.

#### 🐱‍💻 **_Local Developing run_**

1. Faça toda a preparação do **_Prometheus_** usando **_`MIX_ENV=dev mix project.prepare`_** no seu terminal.
2. Definir as variáveis de ambiente em um arquivo **_`.env`_**, seguindo o exemplo de **_`.env.example`_**.
3. Inicialize o **_PostgreSQL_** e adeque suas configurações com base em suas configurações no **_PostgreSQL_**.
4. Inicialize o **_Redis_** e adeque suas configurações com base em suas configurações no **_Redis_**.
5. Inicialize o **_Prometheus_** usando **_`MIX_ENV=dev iex -S mix phx.server`_** no seu terminal.

#### 🏎️ **_Local production run_**

1. Faça toda a preparação do **_Prometheus_** usando **_`MIX_ENV=prod mix project.prepare`_** no seu terminal.
2. Definir as variáveis de ambiente em um arquivo **_`.env`_**, seguindo o exemplo de **_`.env.example`_**.
3. Inicialize o **_PostgreSQL_** e adeque suas configurações com base em suas configurações no **_PostgreSQL_**.
4. Inicialize o **_Redis_** e adeque suas configurações com base em suas configurações no **_Redis_**.
5. Inicialize o **_Prometheus_** usando **_`MIX_ENV=prod iex -S mix phx.server`_** no seu terminal.

## 🪷 **_Frontend_**

**_Prometheus_** também possui um repositório dedicado à sua camada de frontend, [**_Zeus_**](https://github.com/NukeZzZin/zeus), desenvolvido em **_NodeJS_** com o uso do framework **_React (Vite)_**. A aplicação adota uma abordagem moderna de desenvolvimento, utilizando **_Axios_** para comunicação com **_Prometheus_**, **_Material UI_** para construção de interfaces consistentes e acessíveis, e **_Zustand_** para gerenciamento de estado de forma simples e eficiente.

## 📝 **_License_**

> **_Você pode conferir a licença completa [aqui](https://github.com/NukeZzZin/prometheus/blob/master/LICENSE)._**

_Este projeto está licenciado sob os termos da licença **_GNU AFFERO GENERAL PUBLIC LICENSE v3.0_**._
