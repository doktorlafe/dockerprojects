import base64
import os
import secrets
import sqlite3
import string
from datetime import datetime
from functools import wraps

from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from flask import Flask, flash, g, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash, generate_password_hash


app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", secrets.token_hex(32))
app.config["DATABASE_PATH"] = os.environ.get(
    "PASSWORDKEEP_DB_PATH", os.path.join(os.path.dirname(__file__), "data", "passwordkeep.db")
)

ACTIVE_SESSION_KEYS = {}
PBKDF2_ITERATIONS = 390000


def get_db():
    if "db" not in g:
        os.makedirs(os.path.dirname(app.config["DATABASE_PATH"]), exist_ok=True)
        g.db = sqlite3.connect(app.config["DATABASE_PATH"])
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(_error):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    db = get_db()
    db.executescript(
        """
        CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            site_name TEXT NOT NULL,
            site_url TEXT,
            username TEXT NOT NULL,
            encrypted_password TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        """
    )
    db.commit()


def get_settings():
    return get_db().execute("SELECT * FROM settings WHERE id = 1").fetchone()


def derive_key(master_password, salt_b64):
    salt = base64.b64decode(salt_b64)
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=PBKDF2_ITERATIONS,
    )
    key = base64.urlsafe_b64encode(kdf.derive(master_password.encode("utf-8")))
    return key.decode("utf-8")


def get_session_key():
    session_id = session.get("session_id")
    if not session_id:
        return None
    return ACTIVE_SESSION_KEYS.get(session_id)


def get_fernet():
    key = get_session_key()
    if not key:
        return None
    return Fernet(key.encode("utf-8"))


def encrypt_password(plain_text):
    fernet = get_fernet()
    if not fernet:
        raise RuntimeError("Missing active encryption key")
    return fernet.encrypt(plain_text.encode("utf-8")).decode("utf-8")


def decrypt_password(encrypted_value):
    fernet = get_fernet()
    if not fernet:
        raise RuntimeError("Missing active encryption key")
    try:
        return fernet.decrypt(encrypted_value.encode("utf-8")).decode("utf-8")
    except InvalidToken:
        return "Nelze dešifrovat"


def login_required(view):
    @wraps(view)
    def wrapped_view(**kwargs):
        if not session.get("authenticated") or not get_session_key():
            flash("Nejdřív se přihlas master heslem.", "warning")
            return redirect(url_for("login"))
        return view(**kwargs)

    return wrapped_view


def get_entry_or_404(entry_id):
    entry = get_db().execute("SELECT * FROM entries WHERE id = ?", (entry_id,)).fetchone()
    if entry is None:
        flash("Záznam nebyl nalezen.", "error")
        return None
    return entry


def generate_password(length=20):
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*()-_=+"
    return "".join(secrets.choice(alphabet) for _ in range(length))


@app.before_request
def ensure_initialized():
    init_db()


@app.route("/")
def index():
    if not get_settings():
        return redirect(url_for("setup"))
    if session.get("authenticated") and get_session_key():
        return redirect(url_for("dashboard"))
    return redirect(url_for("login"))


@app.route("/health")
def health():
    return {"status": "ok"}


@app.route("/setup", methods=["GET", "POST"])
def setup():
    if get_settings():
        return redirect(url_for("login"))

    if request.method == "POST":
        password = request.form.get("password", "")
        password_confirm = request.form.get("password_confirm", "")

        if len(password) < 12:
            flash("Master heslo musí mít alespoň 12 znaků.", "error")
        elif password != password_confirm:
            flash("Hesla se neshodují.", "error")
        else:
            salt = base64.b64encode(os.urandom(16)).decode("utf-8")
            password_hash = generate_password_hash(password)
            db = get_db()
            db.execute(
                "INSERT INTO settings (id, password_hash, salt, created_at) VALUES (1, ?, ?, ?)",
                (password_hash, salt, datetime.utcnow().isoformat()),
            )
            db.commit()
            flash("Master heslo bylo nastaveno. Přihlas se.", "success")
            return redirect(url_for("login"))

    return render_template("setup.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    settings = get_settings()
    if not settings:
        return redirect(url_for("setup"))

    if request.method == "POST":
        password = request.form.get("password", "")
        if not check_password_hash(settings["password_hash"], password):
            flash("Neplatné master heslo.", "error")
        else:
            session.clear()
            session_id = secrets.token_urlsafe(24)
            ACTIVE_SESSION_KEYS[session_id] = derive_key(password, settings["salt"])
            session["authenticated"] = True
            session["session_id"] = session_id
            flash("Přihlášení proběhlo úspěšně.", "success")
            return redirect(url_for("dashboard"))

    return render_template("login.html")


@app.route("/logout", methods=["POST"])
def logout():
    session_id = session.get("session_id")
    if session_id:
        ACTIVE_SESSION_KEYS.pop(session_id, None)
    session.clear()
    flash("Byl jsi odhlášen.", "success")
    return redirect(url_for("login"))


@app.route("/dashboard")
@login_required
def dashboard():
    search = request.args.get("search", "").strip()
    rows = get_db().execute(
        "SELECT * FROM entries ORDER BY site_name COLLATE NOCASE, username COLLATE NOCASE"
    ).fetchall()

    entries = []
    for row in rows:
        if search:
            haystack = " ".join([row["site_name"] or "", row["username"] or "", row["site_url"] or "", row["notes"] or ""]).lower()
            if search.lower() not in haystack:
                continue
        entry = dict(row)
        entry["plain_password"] = decrypt_password(row["encrypted_password"])
        entries.append(entry)

    return render_template("dashboard.html", entries=entries, search=search)


@app.route("/entries/new", methods=["GET", "POST"])
@login_required
def create_entry():
    generated_password = request.args.get("generate")
    if request.method == "POST":
        site_name = request.form.get("site_name", "").strip()
        site_url = request.form.get("site_url", "").strip()
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        notes = request.form.get("notes", "").strip()

        if not site_name or not username or not password:
            flash("Vyplň název služby, uživatelské jméno a heslo.", "error")
        else:
            now = datetime.utcnow().isoformat()
            get_db().execute(
                """
                INSERT INTO entries (site_name, site_url, username, encrypted_password, notes, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (site_name, site_url, username, encrypt_password(password), notes, now, now),
            )
            get_db().commit()
            flash("Záznam byl uložen.", "success")
            return redirect(url_for("dashboard"))

    return render_template(
        "entry_form.html",
        form_title="Nový záznam",
        submit_label="Uložit",
        entry=None,
        generated_password=generated_password or generate_password(),
    )


@app.route("/entries/<int:entry_id>/edit", methods=["GET", "POST"])
@login_required
def edit_entry(entry_id):
    entry = get_entry_or_404(entry_id)
    if entry is None:
        return redirect(url_for("dashboard"))

    entry_data = dict(entry)
    entry_data["plain_password"] = decrypt_password(entry["encrypted_password"])

    if request.method == "POST":
        site_name = request.form.get("site_name", "").strip()
        site_url = request.form.get("site_url", "").strip()
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        notes = request.form.get("notes", "").strip()

        if not site_name or not username or not password:
            flash("Vyplň název služby, uživatelské jméno a heslo.", "error")
        else:
            get_db().execute(
                """
                UPDATE entries
                SET site_name = ?, site_url = ?, username = ?, encrypted_password = ?, notes = ?, updated_at = ?
                WHERE id = ?
                """,
                (
                    site_name,
                    site_url,
                    username,
                    encrypt_password(password),
                    notes,
                    datetime.utcnow().isoformat(),
                    entry_id,
                ),
            )
            get_db().commit()
            flash("Záznam byl upraven.", "success")
            return redirect(url_for("dashboard"))

        entry_data = {
            **entry_data,
            "site_name": site_name,
            "site_url": site_url,
            "username": username,
            "notes": notes,
            "plain_password": password,
        }

    return render_template(
        "entry_form.html",
        form_title="Upravit záznam",
        submit_label="Uložit změny",
        entry=entry_data,
        generated_password=generate_password(),
    )


@app.route("/entries/<int:entry_id>/delete", methods=["POST"])
@login_required
def delete_entry(entry_id):
    entry = get_entry_or_404(entry_id)
    if entry is None:
        return redirect(url_for("dashboard"))

    get_db().execute("DELETE FROM entries WHERE id = ?", (entry_id,))
    get_db().commit()
    flash("Záznam byl smazán.", "success")
    return redirect(url_for("dashboard"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)