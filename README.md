# Data Platform 

## Introduction

Welcome to our Data Platform project! Designed with Data Engineer and Scientist in mind, this project offers a comprehensive **local development** environment. The goal is to streamline your workflow by providing a suite of pre-configured tools that work seamlessly together, enabling you to focus more on innovation and less on setup.

Any of the tools listed in the [Architecture](#architecture) section can be used independently, or you can follow along with the sample [use case](/UseCase.md) for a more comprehensive walkthrough. 

### Background
In data engineering, setting up an environment with all the necessary tools can be time-consuming, especially if you're new to the tech (which is often the case given the number of products out there). This realization hit home during my work on a few side projects, each requiring setup efforts. As I was already collecting a bunch of snippets (bash, kubectl, helm, etc...) for different projects, I decided to build a dev playground of sorts. A solution that helps me explore ideas by having a suite of tools I regularly use already integrated with each other. And easy to start/stop, reset, and expand as needed. The project is the public version of those efforts. 

### Scope
This project is intended for local development only. 

In future projects, I will focus on deploying some of the services in the project to a cloud provider, with special attention paid to security, scalability, reliablity, networking, storage, observability, and cost management options.... But this one is just for local use.


### Use Case
We'll ingest a dataset from Kaggle and process it with our platform, which some help from large language models. See more details [here](/UseCase.md)



## Architecture

![Platform Overview](images/data_platform_overview.png)

This version makes uses a *mostly* open stack comprised of:

<table>
    <tr>
        <th style="width:20%">Tool</th>
        <th style="width:50%">Description</th>
        <th style="width:30%">URLs</th>
    </tr>
    <tr>
        <td><a href="https://min.io/">MinIO</a></td>
        <td>An object storage solution that provides an S3-like experience, but with your data staying local.</td>
        <td><a href="http://localhost:9001/">http://localhost:9001/</a> (UI) <br> <a href="http://localhost:9000/">http://localhost:9000/</a> (API) <br> minio:minio123</td>
    </tr>
    <tr>
        <td><a href="https://airflow.apache.org/">Apache Airflow</a></td>
        <td>An orchestrator for our data pipelines</td>
        <td><a href="http://localhost:8081/">http://localhost:8081/</a> (UI)<br> airflow:airflow123</td>
    </tr>
    <tr>
        <td><a href="https://trino.io/">Trino</a></td>
        <td>Distributed query engine enabling us to query files stored in S3/Minio using SQL</td>
        <td><a href="http://localhost:8082/">http://localhost:8082/</a> (API)<br/><a href="http://localhost:8082/ui/">http://localhost:8082/ui/</a> (UI)<br>Authentication not enabled, just use 'trino' for username</td>
    </tr>
    <tr>
        <td><a href="https://jupyter.org/hub">JupyterHub</a></td>
        <td>Notebooks used to test out ideas</td>
      <td><a href="http://localhost:8083/">http://localhost:8083/</a> (UI)</td>
    </tr>
    <tr>
        <td><a href="https://datahubproject.io/">Datahub</a></td>
        <td>Serves as our metadata repository. GPT generated column descriptions, along with other technical metadata, would be visible in Datahub for users interested in understanding their data and how it relates to other parts of their organization.</td>
      <td><a href="http://localhost:8084/">http://localhost:8084/</a> (UI)<br>datahub:datahub</td>
    </tr>
    <tr>
        <td><a href="https://kafka.apache.org/">Apache Kafka</a></td>
        <td>Distributed event streaming platform. In our use case, profiling jobs write messages to Kafka topics, and are then processed by Datahub.</td>
        <td><a href="http://localhost:9090/">http://localhost:9090/</a> (Kafka UI) </td>
    </tr>
    <tr>
        <td><a href="https://cwiki.apache.org/confluence/display/hive/design">Apache Hive Metastore</a></td>
        <td>Hive acts as a central repository for metadata about our data lake. Our Spark jobs and Trino rely on Hive when querying or modifying tables.</td>
        <td></td>
    </tr>
    <tr>
        <td><a href="https://iceberg.apache.org/">Apache Iceberg</a></td>
        <td>A table format utilized by our Spark jobs to enable data stored in S3 (Minio) to be querable through engines like Trino or SparkSQL.</td>
        <td></td>
    </tr>
    <tr>
        <td><a href="https://spark.apache.org/">Apache Spark</a></td>
        <td>Used to process ingested data (e.g. clean/transform tasks), and to analyze with SparkSQL</td>
        <td></td>
    </tr>
    <tr>
        <td><a href="https://openai.com/">OpenAI GPT 3.5</a></td>
        <td>Used to generate descriptions for ingested columns. Selected for ease of use, but an OSS model like Mistral works just as well (you'll just need the hardware)</td>
        <td></td>
    </tr>
    <tr>
        <td><a href="https://www.python.org/">Python</a></td>
        <td>Primary language used in data pipelines</td>
        <td></td>
    </tr>


</table>

## Prerequisites

Before you start, ensure your host system (MacOS) has the following software installed:

- **Docker**: A platform for developing, shipping, and running applications inside isolated environments called containers.
- **Kind (Kubernetes in Docker)**: A tool for running local Kubernetes clusters using Docker container nodes.
- **Helm**: A package manager for Kubernetes, allowing you to define, install, and upgrade complex Kubernetes applications.
- **Python 3.8 or higher**: A powerful programming language, essential for running scripts and additional tools in this project.
- **Pip**: A package installer for Python, used to install Python packages.

### Install Commands for MacOS

1. **Install Docker:**

   ```bash
   brew cask install docker
   ```
2. **Install kubectl**
   ```bash
   brew install kubectl
   ```
2. **Install Kind:**

   ```bash
   brew install kind
   ```

3. **Install Helm:**

   ```bash
   brew install helm
   ```

4. **Install Python 3.8+:**

   ```bash
   brew install python@3.8
   ```

   Or setup a virtual environment for this project

5. **Install Pip:**

   Pip is included with Python 3.4 and later. You can ensure it's up to date with:

   ```bash
   python3 -m pip install --upgrade pip
   ```

## Quick Start

1. **Clone the Repository**
   
   ```bash
   git clone https://github.com/msantana09/data_platform.git
   cd data_platform
   ```

2. **Initialize .env files**

   The project comes with several template files (e.g. .env-template) containing the default credentials and configurations for for the various services.  The command below copies the default template files to .env files, which are ignored by git. You can then modify the .env files as needed.

   ````bash
   ./platform.sh init
   ````
3. **Install project dependencies**

   These are dependencies needed for local development, and for a few unit tests executed when Airflow is started.
   ```
   pip install -r requirements-dev.txt
   ```

4. **Configure use case credentials (Optional)**

   If you're planning on running the sample [use case](/UseCase.md), you will need to configure your Kaggle and OpenAI credentials

   - **Kaggle**: Update `AIRFLOW_CONN_KAGGLE_DEFAULT` in file `services/airflow/.env` with your [Kaggle](https://www.kaggle.com/) username and key
   - **OpenAI**: Update `OPENAI_API_KEY` in file `services/models/.env` with your [OpenAI](https://openai.com/)  key


5. **Launch the Platform**

   Use the `-h` flag to see all options:
   ````bash
   (.venv) ➜  data_platform git:(main) ✗ ./platform.sh -h
   Usage: ./platform.sh <action> [-c|--cluster <cluster_name>] [-d|--delete-data] [sub_scripts...]

   Options:
   <action>                      The action to perform (init|start|shutdown|recreate)
   -c, --cluster <cluster_name>  Set the cluster name (default: platform)
   -d, --delete-data             Delete data flag (default: false)
   -h, --help                    Display this help message
   [sub_scripts...]              Additional scripts to run (default: core). 
                                 Valid names include: 
                                    airflow, datahub, hive, jupyter, kafka, minio, models, spark, trino, 
                                    lakehouse ( minio, hive, trino ),
                                    core ( lakehouse + airflow + spark + kafka )
   ````
   
   Here are a few examples:
   ```bash
   # start airflow and MinIO
   ./platform.sh start airflow minio

   # start all the services for the use case:
   # core ( lakehouse ( minio, hive, trino ) + airflow + spark + kafka )
   # models
   # datahub
   ./platform.sh start core models datahub

   # shutdown only MinIO
   ./platform.sh shutdown minio

   # shutdown only Minio and delete persisted data (a reset)
   ./platform.sh shutdown minio -d

   # shutdown the entire cluster
   ./platform shutdown

   # shutdown the entire cluster, and delete persisted data for all services
   ./platform shutdown -d
   ```

    Once the desired services are up and running, you might be interested in seeings logs and other activities. Most of the applications are running within a Kubernetes cluster created with the [Kind](https://kind.sigs.k8s.io/) tool, which automatically updates the context in your terminal to the newly created cluster. Meaning you will be able to immediately run `kubectl` [commands](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) like:
    ```bash
    # list pods in the airflow namespace
    kubectl get pods -n airflow

    # list pods in all namespaces
    kubectl get pods -A
    
    # tail the logs of a given pod
    # e.g. kubectl logs airflow-web-66f94b5b94-pl8pg  -n airflow
    kubectl logs -f <pod name> -n <namespace>
    ```

# Additional Resources
- [Running Kafka on kubernetes for local development](https://dev.to/thegroo/running-kafka-on-kubernetes-for-local-development-2a54)
- [How to make a Helm chart in 10 minutes](https://opensource.com/article/20/5/helm-charts)
- [analytical_dp_with_sql](https://github.com/josephmachado/analytical_dp_with_sql/tree/main)