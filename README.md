# Ejercicio Práctico SRE: sre-infrastructure-exercise

Este repositorio contiene los scripts de automatización para el ejercicio práctico de SRE, adaptado para Google Cloud Platform (GCP) en lugar de AWS. El proyecto utiliza **Packer**, **Ansible** y **Terraform** para aprovisionar una infraestructura de aplicación web, incluyendo:

- Balanceador de carga HTTP
- Reglas de firewall
- Imagen personalizada de Compute Engine
- Cloud SQL (PostgreSQL)
- Cloud DNS

El proyecto excluye Terragrunt y EFS según los requisitos.

---

## 🎯 Objetivo

Automatizar el despliegue de los siguientes componentes en GCP:

- Balanceador de Carga HTTP (equivalente al ALB de AWS)
- Reglas de Firewall (equivalente a Security Groups)
- Imagen Personalizada (equivalente a AMI)
- Cloud SQL para PostgreSQL (equivalente a RDS)
- Cloud DNS (equivalente a Route 53)

---

## 📁 Estructura del Repositorio

```
sre-infrastructure-exercise/
├── ansible/
│   └── webapp.yml                # Playbook Ansible
├── packer/
│   └── webapp.json               # Plantilla Packer
├── terraform/
│   ├── main.tf                   # Infraestructura con Terraform
│   ├── variables.tf              # Variables
│   └── terraform.tfvars          # Valores de las variables
└── README.md
```

---

## 💻 Prerrequisitos Locales (Debian 12)

### Instala las herramientas necesarias

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl unzip

# gcloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install packer -y

# Ansible
sudo apt install ansible -y

# Terraform
sudo apt install terraform -y
```

### Verifica las versiones

```bash
gcloud --version
packer --version
ansible --version
terraform --version
```

---

## ☁️ Prerrequisitos en GCP

- Proyecto GCP llamado `sre-infrastructure-exercise`
- Cuenta de servicio con los roles:

  - compute.admin
  - cloudsql.admin
  - dns.admin
  - iam.serviceAccountUser

```bash
gcloud projects add-iam-policy-binding sre-infrastructure-exercise   --member="serviceAccount:<tu-email>"   --role="<rol>"
```

- Clave de cuenta de servicio:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/clave.json"
```

- APIs habilitadas:

```bash
gcloud services enable   compute.googleapis.com   sqladmin.googleapis.com   dns.googleapis.com   iam.googleapis.com   cloudresourcemanager.googleapis.com
```

---

## 🛠️ Configuración del Proyecto

### Clonar repositorio

```bash
git clone https://github.com/<tu-usuario>/sre-infrastructure-exercise.git
cd sre-infrastructure-exercise
```

### Crear imagen personalizada con Packer

```bash
cd packer
packer validate webapp.json
packer build webapp.json
```

### Actualizar configuración en Terraform

Edita `terraform/terraform.tfvars`:

```hcl
project_id = "sre-infrastructure-exercise"
image_name = "sre-webapp-1234567890"
```

Luego:

```bash
cd terraform
terraform init
terraform apply
```

---

## ✅ Pruebas

- **Load Balancer:** Accede al IP del recurso `google_compute_global_forwarding_rule`.
- **Cloud SQL:** Conéctate con:

```bash
gcloud sql connect sre-postgres --user=postgres
```

- **DNS:** Verifica que el dominio apunta correctamente.
- **Firewall:** Asegúrate de que los puertos 80 y 443 estén abiertos.

---

## 🧹 Limpieza (opcional)

```bash
cd terraform
terraform destroy

gcloud compute images delete sre-webapp-<timestamp> --project=sre-infrastructure-exercise
```

---

## 🧪 Solución de Problemas

### Packer

- Usa `PACKER_LOG=1` para más detalle.
- Asegúrate de tener `python3`, acceso SSH y que el playbook existe.

### Terraform

- Asegúrate de que todas las APIs estén habilitadas.
- Verifica el nombre de la imagen generada por Packer.

---

## 📌 Notas

- El dominio `app.example.com` es un marcador.
- Se utiliza la VPC por defecto de GCP.
- El playbook de Ansible instala Nginx simple.
- Terragrunt y EFS no están incluidos.

---

## 🚀 Entregable

Repositorio público:  
[https://github.com/<tu-usuario>/sre-infrastructure-exercise](https://github.com/<tu-usuario>/sre-infrastructure-exercise)