from fastapi import FastAPI, Form, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
import json
import os

app = FastAPI()

REGISTRATION_FILE = "registrations.json"

# Ensure the file exists
if not os.path.exists(REGISTRATION_FILE):
    with open(REGISTRATION_FILE, "w") as f:
        json.dump([], f)


@app.get("/", response_class=HTMLResponse)
def registration_form():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Register</title>
        <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
        <style>
            body {
                font-family: 'Poppins', sans-serif;
                background-color: #f9f9f9;
                padding: 30px;
                text-align: center;
            }
            form {
                background: white;
                padding: 20px;
                display: inline-block;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0,0,0,0.1);
            }
            input {
                padding: 10px;
                margin: 10px;
                width: 250px;
                font-size: 16px;
            }
            button {
                padding: 10px 20px;
                background-color: #0db7ed;
                border: none;
                color: white;
                font-size: 16px;
                cursor: pointer;
                border-radius: 5px;
            }
            a {
                display: inline-block;
                margin-top: 20px;
                text-decoration: none;
                color: #0db7ed;
                font-weight: bold;
            }
        </style>
    </head>
    <body>
        <h1>Docker Tutorial - Register</h1>
        <form action="/register" method="post">
            <input type="text" name="name" placeholder="Your Name" required><br>
            <input type="email" name="email" placeholder="Your Email" required><br>
            <button type="submit">Register</button>
        </form>
        <br>
        <a href="/registrations">See Registrations</a>
    </body>
    </html>
    """


@app.post("/register", response_class=HTMLResponse)
def register_user(name: str = Form(...), email: str = Form(...)):
    with open(REGISTRATION_FILE, "r+") as f:
        data = json.load(f)
        data.append({"name": name, "email": email})
        f.seek(0)
        json.dump(data, f, indent=4)
    return f"""
    <html>
    <body style="font-family: Poppins, sans-serif; text-align: center;">
        <h2>Thank you for registering, {name}!</h2>
        <a href="/">Back to form</a> | <a href="/registrations">See Registrations</a>
    </body>
    </html>
    """


@app.get("/registrations", response_class=HTMLResponse)
def show_registrations():
    with open(REGISTRATION_FILE, "r") as f:
        registrations = json.load(f)

    list_items = "".join([f"<li>{r['name']} - {r['email']}</li>" for r in registrations])

    return f"""
    <html>
    <head>
        <title>Registrations</title>
        <style>
            body {{ font-family: 'Poppins', sans-serif; padding: 30px; }}
            ul {{ list-style: none; padding: 0; }}
            li {{ background: #eee; padding: 10px; margin: 5px 0; border-radius: 5px; }}
            a {{ text-decoration: none; color: #0db7ed; font-weight: bold; }}
        </style>
    </head>
    <body>
        <h2>Registered Users</h2>
        <ul>{list_items}</ul>
        <br>
        <a href="/">Back to Form</a>
    </body>
    </html>
    """
