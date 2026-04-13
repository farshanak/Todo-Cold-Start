from itertools import count

from config import settings
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

class TodoIn(BaseModel):
    title: str

class Todo(BaseModel):
    id: int
    title: str
    done: bool = False

_ids = count(1)
_todos: dict[int, Todo] = {}

@app.get("/health")
def health() -> dict:
    return {"status": "ok"}

@app.get("/todos")
def list_todos() -> list[Todo]:
    return list(_todos.values())

@app.post("/todos")
def create_todo(body: TodoIn) -> Todo:
    todo = Todo(id=next(_ids), title=body.title)
    _todos[todo.id] = todo
    return todo

@app.patch("/todos/{todo_id}")
def toggle_todo(todo_id: int) -> Todo:
    todo = _todos.get(todo_id)
    if not todo:
        raise HTTPException(404)
    todo.done = not todo.done
    return todo

@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int) -> dict:
    if todo_id not in _todos:
        raise HTTPException(404)
    del _todos[todo_id]
    return {"ok": True}
