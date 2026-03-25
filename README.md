# 🐾 Minip_DB_5786_6659_5932

This project is the **Veterinary and Health Management Department** module of a larger Zoo Management Database System.

---

### 📋 Shlav 1 — Phase 1: Database Design & Population

👉 [View the full Shlav 1 README](Shlav1/README_SHLAV1.md)


### 📋 Shlav 2 — Phase 2: Database Design & Population

👉 [View the full Shlav 2 README](Shlav2/README_SHLAV2.md)


### 📋 Shlav 3 — Phase 3: Database Design & Population

👉 [View the full Shlav 3 README](Shlav3/README_SHLAV3.md)


### 📋 Shlav 4 — Phase 4: Database Design & Population

👉 [View the full Shlav 4 README](Shlav4/README_SHLAV4.md)


### 📋 Shlav 5 — Phase 5: Database Design & Population

👉 [View the full Shlav 5 README](Shlav5/README_SHLAV5.md)






## 🚀 Quick Start

To run the application using Docker Compose:

```bash
# Start the database and build containers in detached mode
docker-compose up -d --build

# Stop the containers and remove volumes
docker-compose down -v
```

### 🔄 Database Restoration (Stage 3)
To reset the database to the Stage 3 baseline before starting Stage 4:

1. **Clean the database** (Run in pgAdmin Query Tool):
   ```sql
   DROP SCHEMA public CASCADE;
   CREATE SCHEMA public;
   ```

2. **Restore from backup** (Run in your host terminal):
   ```bash
   cmd /c "type .\Shlav3\backup3.backup | docker exec -i PostgreSQL_DB psql -U admin -d basnat"
   ```





### push the tag

```bash
git tag shlav5
git push origin shlav5
```