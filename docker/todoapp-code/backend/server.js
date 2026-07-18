const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Connexion PostgreSQL via variables d'environnement (jamais en dur)
const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  user: process.env.PGUSER || 'todo',
  password: process.env.PGPASSWORD || 'todo',
  database: process.env.PGDATABASE || 'tododb',
  port: process.env.PGPORT || 5432,
});

// Creation de la table au demarrage si elle n'existe pas (idempotent)
async function initDb() {
  const createTable = `
    CREATE TABLE IF NOT EXISTS todos (
      id SERIAL PRIMARY KEY,
      text TEXT NOT NULL,
      done BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `;
  let retries = 10;
  while (retries) {
    try {
      await pool.query(createTable);
      console.log('Base de donnees prete.');
      break;
    } catch (err) {
      console.log('En attente de la base de donnees...', err.message);
      retries -= 1;
      await new Promise((res) => setTimeout(res, 3000));
    }
  }
}

// Healthcheck (utile pour Docker/CI)
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Lister les taches
app.get('/api/todos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM todos ORDER BY id ASC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Creer une tache
app.post('/api/todos', async (req, res) => {
  const { text } = req.body;
  if (!text || !text.trim()) {
    return res.status(400).json({ error: 'Le texte de la tache est requis' });
  }
  try {
    const result = await pool.query(
      'INSERT INTO todos (text) VALUES ($1) RETURNING *',
      [text.trim()]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Basculer / modifier une tache
app.put('/api/todos/:id', async (req, res) => {
  const { id } = req.params;
  const { done } = req.body;
  try {
    const result = await pool.query(
      'UPDATE todos SET done = $1 WHERE id = $2 RETURNING *',
      [done, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tache non trouvee' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Supprimer une tache
app.delete('/api/todos/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM todos WHERE id = $1', [id]);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, async () => {
  console.log(`API backend demarree sur le port ${PORT}`);
  await initDb();
});
