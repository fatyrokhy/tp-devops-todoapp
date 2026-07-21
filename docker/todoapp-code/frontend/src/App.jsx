import React, { useEffect, useState } from 'react';

// Toutes les requetes passent par /api (proxy Nginx cote serveur en prod,
// proxy Vite en dev local) -> jamais d'URL en dur vers le backend.
const API_URL = '/api/todos';

export default function App() {
  const [todos, setTodos] = useState([]);
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchTodos();
  }, []);

  async function fetchTodos() {
    try {
      setLoading(true);
      const res = await fetch(API_URL);
      if (!res.ok) throw new Error('Erreur lors du chargement des taches');
      const data = await res.json();
      setTodos(data);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function addTodo(e) {
    e.preventDefault();
    if (!text.trim()) return;
    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text }),
      });
      if (!res.ok) throw new Error("Erreur survenue  lors de l'ajout");
      const newTodo = await res.json();
      setTodos([...todos, newTodo]);
      setText('');
    } catch (err) {
      setError(err.message);
    }
  }

  async function toggleTodo(id, done) {
    try {
      const res = await fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ done: !done }),
      });
      if (!res.ok) throw new Error('Erreur lors de la mise a jour');
      const updated = await res.json();
      setTodos(todos.map((t) => (t.id === id ? updated : t)));
    } catch (err) {
      setError(err.message);
    }
  }

  async function deleteTodo(id) {
    try {
      const res = await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Erreur lors de la suppression');
      setTodos(todos.filter((t) => t.id !== id));
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="container">
      <h1>AMFAShop - Gestion des taches -</h1>

      <form onSubmit={addTodo} className="todo-form">
        <input
          type="text"
          placeholder="Nouvelle tache..."
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
        <button type="submit">Ajouter</button>
      </form>

      {error && <p className="error">Erreur : {error}</p>}
      {loading && <p>Chargement...</p>}

      <ul className="todo-list">
        {todos.map((todo) => (
          <li key={todo.id} className={todo.done ? 'done' : ''}>
            <span onClick={() => toggleTodo(todo.id, todo.done)}>
              {todo.text}
            </span>
            <button onClick={() => deleteTodo(todo.id)}>Supprimer</button>
          </li>
        ))}
      </ul>

      {!loading && todos.length === 0 && <p>Aucune tache enregistrer pour le moment.</p>}
    </div>
  );
}
