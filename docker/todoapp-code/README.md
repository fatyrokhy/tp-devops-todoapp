# Todo App - MediShop (Front React + Back Node/Express + DB PostgreSQL)

## Structure

```
todoapp-code/
├── backend/          # API Node.js/Express (port 3000)
│   ├── server.js
│   ├── package.json
│   ├── Dockerfile
│   └── .env.example
├── frontend/          # React (Vite), servi par Nginx interne au conteneur (port 80)
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   └── nginx.conf
└── docker-compose.yml # UNIQUEMENT pour tester en local
```

## Ou placer ces dossiers dans ton projet TP

Dans ton dossier `tp-devops-todoapp`, tu as deja un dossier `docker/`.
Copie `backend/` et `frontend/` dedans :

```
tp-devops-todoapp/
├── terraform/
├── ansible/
├── docker/
│   ├── backend/
│   └── frontend/
└── .github/workflows/
```

## Tester en local avant de deployer sur AWS

Depuis le dossier contenant `docker-compose.yml` :

```bash
docker compose up --build
```

Puis ouvre http://localhost:8080 dans ton navigateur.
L'API est testable directement sur http://localhost:3000/api/todos

## Architecture reseau en production (rappel)

- Le conteneur **frontend** tourne sur l'instance Front, ecoute en interne
  sur le port 80, mappe par exemple sur le port hote 8080
  (`docker run -p 8080:80 ...`)
- Le **Nginx installe par Ansible sur l'hote Front** (pas celui du conteneur)
  fait le reverse proxy : il ecoute sur 80/443 (Internet) et redirige :
  - `/` vers `localhost:8080` (le conteneur frontend)
  - `/api` vers `<IP_PRIVEE_BACK>:3000` (le conteneur backend, sur l'autre instance)
- Le conteneur **backend** tourne sur l'instance Back, ecoute sur le port 3000,
  se connecte a PostgreSQL via les variables d'environnement (PGHOST=<IP_PRIVEE_DB>, etc.)
- Le conteneur **db** (image officielle `postgres:16-alpine`) tourne sur l'instance DB

## Variables sensibles

Aucun mot de passe n'est en dur dans le code ni dans les images Docker.
Tout passe par des variables d'environnement, injectees au moment du
`docker run` (ou via GitHub Secrets dans le pipeline CI/CD).
