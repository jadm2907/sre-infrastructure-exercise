
```markdown
# Ejercicio Práctico SRE: sre-infrastructure-exercise

Este repositorio contiene los scripts de automatización para el ejercicio práctico de SRE, adaptado para Google Cloud Platform (GCP) en lugar de AWS. El proyecto utiliza **Packer**, **Ansible** y **Terraform** para aprovisionar una infraestructura de aplicación web, incluyendo un balanceador de carga HTTP, reglas de firewall, una imagen personalizada de Compute Engine, Cloud SQL (PostgreSQL) y Cloud DNS. El proyecto se llama `sre-infrastructure-exercise` y excluye **Terragrunt** y **EFS** según los requisitos.

---

## Objetivo

Automatizar el despliegue de los siguientes componentes en GCP:

- **Balanceador de Carga HTTP** (equivalente al Application Load Balancer de AWS).
- **Reglas de Firewall** (equivalente a Security Groups de AWS).
- **Imagen Personalizada** (equivalente a AMI de AWS, creada con Packer y Ansible).
- **Cloud SQL para PostgreSQL** (equivalente a RDS de AWS).
- **Cloud DNS** (equivalente a Route 53 Hosted Zone y Alias de AWS).

---

## Estructura del Repositorio

```

sre-infrastructure-exercise/
├── ansible/
│   └── webapp.yml                # Playbook de Ansible para configurar el servidor web
├── packer/
│   └── webapp.json               # Plantilla de Packer para crear la imagen personalizada
├── terraform/
│   ├── main.tf                   # Configuración de Terraform para la infraestructura
│   ├── variables.tf              # Variables de Terraform
│   └── terraform.tfvars          # Valores de las variables de Terraform
└── README.md                     # Este archivo

````

---

## Prerrequisitos

### Entorno Local (Debian 12)

Sistema operativo **Debian 12** instalado localmente.  
Herramientas necesarias:

- `gcloud SDK`: Para autenticación y gestión de GCP.  
- `Packer`: Para crear la imagen personalizada de Compute Engine.  
- `Ansible`: Para la gestión de configuraciones.  
- `Terraform`: Para aprovisionar la infraestructura.  
- `Git`: Para control de versiones.

#### Instala las herramientas:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl unzip

# Instalar gcloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Instalar Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install packer -y

# Instalar Ansible
sudo apt install ansible -y

# Instalar Terraform
sudo apt install terraform -y
````

#### Verifica las instalaciones:

```bash
gcloud --version
packer --version
ansible --version
terraform --version
```

---

### Prerrequisitos en GCP

* Una cuenta de GCP con un proyecto creado llamado **sre-infrastructure-exercise** (puedes usar el nivel gratuito o habilitar facturación).
* Una cuenta de servicio con los siguientes roles:

  * `roles/compute.admin`: Para recursos de Compute Engine.
  * `roles/cloudsql.admin`: Para Cloud SQL.
  * `roles/dns.admin`: Para Cloud DNS.
  * `roles/iam.serviceAccountUser`: Para que Packer use la cuenta de servicio.

#### Asigna los roles:

```bash
gcloud projects add-iam-policy-binding sre-infrastructure-exercise \
  --member="serviceAccount:<tu-cuenta-de-servicio-email>" \
  --role="<nombre-del-rol>"
```

* Una clave de cuenta de servicio (archivo JSON) descargada y configurada:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/tu-clave-de-cuenta-de-servicio.json"
```

#### APIs habilitadas:

* Compute Engine API (`compute.googleapis.com`)
* Cloud SQL Admin API (`sqladmin.googleapis.com`)
* Cloud DNS API (`dns.googleapis.com`)
* IAM API (`iam.googleapis.com`)
* Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`)

```bash
gcloud services enable \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  dns.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com
```

* Un dominio (ejemplo: `app.example.com`) registrado en Cloud DNS (opcional; reemplaza con tu propio dominio).

---

## Instrucciones de Configuración

### Clonar el Repositorio:

```bash
git clone https://github.com/<tu-usuario>/sre-infrastructure-exercise.git
cd sre-infrastructure-exercise
```

---

### Crear la Imagen Personalizada con Packer:

```bash
cd packer
packer validate webapp.json
packer build webapp.json
```

> Anota el nombre de la imagen generada (ejemplo: `sre-webapp-1234567890`) desde la salida de Packer.

---

### Actualizar la Configuración de Terraform:

Edita `terraform/terraform.tfvars`:

```hcl
project_id = "sre-infrastructure-exercise"
image_name = "sre-webapp-1234567890" # Reemplaza con el nombre real de la imagen
```

(Opcional) Edita directamente `terraform/main.tf` si no usas variables:

```hcl
disk {
  source_image = "projects/${var.project_id}/global/images/sre-webapp-1234567890"
}
```

Inicializa y aplica Terraform:

```bash
cd terraform
terraform init
terraform apply
```

---

## Probar la Infraestructura:

* **Balanceador de Carga:** Accede al IP del `google_compute_global_forwarding_rule` en un navegador para verificar que el servidor Nginx está funcionando.
* **Cloud SQL:** Conecta a la instancia de PostgreSQL:

```bash
gcloud sql connect sre-postgres --user=postgres
```

* **Cloud DNS:** Verifica que el registro DNS (`www.app.example.com`) resuelve al IP del balanceador de carga.
* **Reglas de Firewall:** Confirma que el tráfico HTTP/HTTPS (puertos 80, 443) está permitido:

```bash
gcloud compute firewall-rules list --project=sre-infrastructure-exercise
```

---

## Limpieza (Opcional):

Destruye los recursos de Terraform para evitar costos:

```bash
cd terraform
terraform destroy
```

Elimina la imagen personalizada si ya no es necesaria:

```bash
gcloud compute images delete sre-webapp-<timestamp> --project=sre-infrastructure-exercise
```

---

## Solución de Problemas

### Packer

* **Error:** `"Error executing Ansible: Non-zero exit status: exit status 2"`
  Soluciones:

  * Habilita registros detallados:

    ```bash
    PACKER_LOG=1 packer build webapp.json
    ```

  * Verifica que `python3` esté instalado en la instancia (incluido en `packer/webapp.json`).

  * Confirma que el archivo `ansible/webapp.yml` existe y es accesible.

  * Asegúrate de que la regla de firewall permite SSH (puerto 22):

    ```bash
    gcloud compute firewall-rules create allow-ssh \
      --project=sre-infrastructure-exercise \
      --allow=tcp:22 \
      --source-ranges=0.0.0.0/0
    ```

* **Imagen no creada:**
  Verifica la salida de Packer y revisa en GCP:

  ```bash
  gcloud compute images list --project=sre-infrastructure-exercise
  ```

---

### Terraform

* **Error:** `"API not enabled"`

  * Asegúrate de que todas las APIs requeridas estén habilitadas (ver sección de prerrequisitos).
  * Espera 1–5 minutos después de habilitarlas para que se propaguen.

* **Error:** `"Could not find image"`

  * Confirma que la imagen personalizada existe y que el nombre en `terraform.tfvars` o `main.tf` es correcto.
  * Usa el nombre exacto de la imagen generado por Packer (ejemplo: `sre-webapp-1234567890`).

---

### General

* **Permisos:**
  Asegúrate de que la cuenta de servicio tenga los roles necesarios (`roles/compute.admin`, `roles/cloudsql.admin`, `roles/dns.admin`).

* **Costos:**
  Usa instancias `e2-micro` y `db-f1-micro` para el nivel gratuito de GCP. Monitorea los costos en la Consola de GCP.

---

## Notas

* El dominio `app.example.com` es un marcador. Reemplázalo con un dominio que controles en Cloud DNS.
* La VPC predeterminada de GCP se usa, equivalente a la VPC predeterminada de AWS.
* **EFS** y **Terragrunt** se excluyen según los requisitos.
* El playbook de Ansible configura un servidor Nginx simple en la imagen personalizada.

---

## Entregable

Repositorio público en GitHub:
👉 [https://github.com/](https://github.com/)<tu-usuario>/sre-infrastructure-exercise

```

¿Te gustaría que lo genere como archivo `.md` para descargar o pegar directamente?
```
