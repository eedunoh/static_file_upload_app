from flask import Flask, request, render_template, jsonify, redirect, url_for, session, flash
import boto3
import os
import logging
from flask_session import Session
from config import Config
from utils import authenticate_user, register_user

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Secure session settings
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SECURE"] = False  # Set to True in production
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"
app.config["SESSION_TYPE"] = "filesystem"  # Persistent sessions with Flask-Session

# Initialize Flask-Session
Session(app)

# AWS S3 Configuration
S3_BUCKET = Config.S3_BUCKET
s3_client = boto3.client("s3", region_name="eu-north-1")  # Ensure region is set for S3

# Health check endpoint for ALB
@app.route("/health")
def health_check():
    return jsonify({"status": "healthy"}), 200  # ALB expects HTTP 200

@app.route("/")
def home():
    """Render home page if user is logged in, otherwise redirect to login."""
    if "username" in session:
        logger.info(f"User '{session['username']}' accessed the home page.")
        return render_template("home.html", username=session["username"])
    
    logger.info("Unauthorized access attempt to home page.")
    return redirect(url_for("login"))

@app.route("/upload", methods=["POST"])
def upload_file():
    """Upload a file to S3 and store the selected tag."""
    file = request.files.get("file")
    tag = request.form.get("tag")  # Get tag from user input

    if not file or not tag:
        return jsonify({"error": "File and tag are required"}), 400

    try:
        # Use the tag format expected by the Lambda function: 'sensitive=true'
        s3_client.upload_fileobj(
            file,
            S3_BUCKET,
            file.filename,
            ExtraArgs={"Tagging": f"sensitive={tag}"},  # Update to match Lambda's expected format. Get response app. tag = true or false
        )
        logger.info(f"File '{file.filename}' uploaded to S3 with tag 'sensitive={tag}'.")
        return jsonify({"message": "File uploaded successfully!"})
    except Exception as e:
        logger.error(f"Error uploading file: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/login", methods=["GET", "POST"])
def login():
    """Handle user login with AWS Cognito."""
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")

        if not username or not password:
            flash("Username and password are required.", "error")
            return redirect(url_for("login"))

        if authenticate_user(username, password):
            session["username"] = username
            session.modified = True  # Ensure session persistence
            logger.info(f"User '{username}' logged in successfully.")
            flash("Login successful!", "success")
            return redirect(url_for("home"))

        logger.warning(f"Failed login attempt for user '{username}'.")
        flash("Invalid credentials. Please try again.", "error")

    return render_template("login.html")

@app.route("/signup", methods=["GET", "POST"])
def signup():
    """Handle user registration with AWS Cognito."""
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        email = request.form.get("email")

        if not username or not password or not email:
            flash("All fields (username, password, email) are required.", "error")
            return redirect(url_for("signup"))

        if register_user(username, password, email):
            logger.info(f"New user '{username}' registered successfully.")
            flash("Signup successful! Please check your email for the verification link.", "success")
            return redirect(url_for("login"))

        logger.warning(f"Signup failed for user '{username}'.")
        flash("Signup failed. User may already exist or data is invalid.", "error")

    return render_template("signup.html")

@app.route("/logout", methods=["GET"])
def logout():
    session.clear()
    flash("You have been logged out.", "success")  # Optional flash message
    return redirect(url_for("login"))  # Redirect to login page

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80, debug=True)
