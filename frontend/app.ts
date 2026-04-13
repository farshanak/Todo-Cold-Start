type Todo = { id: number; title: string; done: boolean };

const API = "http://localhost:8000";

const list = document.getElementById("list") as HTMLUListElement;
const form = document.getElementById("new-form") as HTMLFormElement;
const input = document.getElementById("new-input") as HTMLInputElement;

async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  if (!res.ok) throw new Error(`${res.status}`);
  return res.json() as Promise<T>;
}

function render(todos: Todo[]): void {
  list.innerHTML = "";
  for (const t of todos) {
    const li = document.createElement("li");
    const cb = document.createElement("input");
    cb.type = "checkbox";
    cb.checked = t.done;
    cb.onchange = async () => {
      await api(`/todos/${t.id}`, { method: "PATCH" });
      await load();
    };
    const span = document.createElement("span");
    span.textContent = t.title;
    if (t.done) span.className = "done";
    const del = document.createElement("button");
    del.textContent = "x";
    del.onclick = async () => {
      await api(`/todos/${t.id}`, { method: "DELETE" });
      await load();
    };
    li.append(cb, span, del);
    list.append(li);
  }
}

async function load(): Promise<void> {
  render(await api<Todo[]>("/todos"));
}

form.onsubmit = async (e) => {
  e.preventDefault();
  const title = input.value.trim();
  if (!title) return;
  await api<Todo>("/todos", { method: "POST", body: JSON.stringify({ title }) });
  input.value = "";
  await load();
};

load();
