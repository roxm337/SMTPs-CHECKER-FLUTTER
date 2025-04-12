from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, HTMLResponse
from pydantic import BaseModel
from typing import List, Optional
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import concurrent.futures
import os
import time
from datetime import datetime

from fastapi.middleware.cors import CORSMiddleware
app = FastAPI(
    title="SMTP Checker API",
    description="API for checking SMTP server validity and sending test emails",
    version="1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only - restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class SMTPCredential(BaseModel):
    host: str
    port: int
    username: str
    password: str

class TestEmailRequest(BaseModel):
    smtp: SMTPCredential
    to_email: str
    from_email: Optional[str] = None

class BatchCheckRequest(BaseModel):
    smtp_list: List[SMTPCredential]
    test_email: Optional[str] = None
    threads: int = 10

# Results storage
if not os.path.exists('Result'):
    os.makedirs('Result')

# Helper functions
def check_smtp(smtp: SMTPCredential, test_email: Optional[str] = None):
    result = {
        "host": smtp.host,
        "port": smtp.port,
        "username": smtp.username,
        "valid": False,
        "email_sent": False,
        "error": None
    }

    try:
        # Test SMTP connection
        with smtplib.SMTP(smtp.host, smtp.port, timeout=10) as server:
            server.ehlo()
            server.starttls()
            server.login(smtp.username, smtp.password)
            result["valid"] = True

            # Send test email if requested
            if test_email:
                from_email = smtp.username if not test_email else smtp.username
                msg = MIMEMultipart()
                msg['Subject'] = f"SMTP Test - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
                msg['From'] = from_email
                msg['To'] = test_email
                msg.add_header('Content-Type', 'text/html')
                
                data = f"""
                <!DOCTYPE html>
                <html>
                <body>
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <h2 style="color: #0066cc;">SMTP Test Successful</h2>
                        <p>This email confirms that your SMTP server is working correctly.</p>
                        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-top: 20px;">
                            <p><strong>Host:</strong> {smtp.host}</p>
                            <p><strong>Port:</strong> {smtp.port}</p>
                            <p><strong>Username:</strong> {smtp.username}</p>
                            <p><strong>Test Time:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
                        </div>
                    </div>
                </body>
                </html>
                """
                
                msg.attach(MIMEText(data, 'html', 'utf-8'))
                server.sendmail(from_email, [test_email], msg.as_string())
                result["email_sent"] = True

    except Exception as e:
        result["error"] = str(e)

    return result

# API Endpoints
@app.post("/check-single", summary="Check a single SMTP server")
async def check_single_smtp(smtp: SMTPCredential):
    """Check if a single SMTP server is valid and can authenticate"""
    result = check_smtp(smtp)
    if result["valid"]:
        return JSONResponse(content=result)
    else:
        raise HTTPException(status_code=400, detail=result["error"])

@app.post("/send-test-email", summary="Send a test email through SMTP")
async def send_test_email(request: TestEmailRequest):
    """Send a test email through the specified SMTP server"""
    result = check_smtp(
        request.smtp,
        request.to_email
    )
    
    if not result["valid"]:
        raise HTTPException(status_code=400, detail="SMTP authentication failed")
    
    if not result["email_sent"]:
        raise HTTPException(status_code=400, detail="Email sending failed")
    
    return JSONResponse(content=result)

@app.post("/batch-check", summary="Check multiple SMTP servers")
async def batch_check(request: BatchCheckRequest):
    """Check multiple SMTP servers with configurable thread count"""
    results = {
        "valid": [],
        "invalid": [],
        "total": len(request.smtp_list),
        "valid_count": 0,
        "invalid_count": 0
    }

    def process_smtp(smtp):
        result = check_smtp(smtp, request.test_email)
        if result["valid"]:
            results["valid"].append(result)
            results["valid_count"] += 1
            # Save valid SMTP
            with open('Result/valid.txt', 'a+') as f:
                f.write(f"{smtp.host}|{smtp.port}|{smtp.username}|{smtp.password}\n")
        else:
            results["invalid"].append(result)
            results["invalid_count"] += 1
            # Save invalid SMTP
            with open('Result/invalid.txt', 'a+') as f:
                f.write(f"{smtp.host}|{smtp.port}|{smtp.username}|{smtp.password}\n")
        return result

    with concurrent.futures.ThreadPoolExecutor(max_workers=request.threads) as executor:
        executor.map(process_smtp, request.smtp_list)

    return JSONResponse(content=results)

@app.get("/", response_class=HTMLResponse)
async def root():
    return """
    <html>
        <head>
            <title>SMTP Checker API</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .container { max-width: 800px; margin: 0 auto; }
                .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
                .endpoints { margin-top: 30px; }
                .endpoint { background-color: #f9f9f9; padding: 15px; margin-bottom: 15px; border-radius: 5px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>SMTP Checker API</h1>
                    <p>API for checking SMTP server validity and sending test emails</p>
                </div>
                
                <div class="endpoints">
                    <h2>Available Endpoints:</h2>
                    
                    <div class="endpoint">
                        <h3>POST /check-single</h3>
                        <p>Check a single SMTP server</p>
                    </div>
                    
                    <div class="endpoint">
                        <h3>POST /send-test-email</h3>
                        <p>Send a test email through SMTP</p>
                    </div>
                    
                    <div class="endpoint">
                        <h3>POST /batch-check</h3>
                        <p>Check multiple SMTP servers with configurable thread count</p>
                    </div>
                </div>
            </div>
        </body>
    </html>
    """
@app.post("/mobile-check")
async def mobile_check(smtp: SMTPCredential):
    """Simplified endpoint for mobile apps"""
    result = check_smtp(smtp)
    return {
        "status": "success" if result["valid"] else "error",
        "data": result
    }

# Add to your existing FastAPI app
from typing import List

class BatchSMTPRequest(BaseModel):
    smtp_list: List[SMTPCredential]
    threads: int = 5

@app.post("/batch-check")
async def batch_check_smtp(request: BatchSMTPRequest):
    """Check multiple SMTP servers with configurable threads"""
    results = {"valid": [], "invalid": []}
    
    def check_single(smtp: SMTPCredential):
        result = check_smtp(smtp)
        if result["valid"]:
            results["valid"].append(result)
        else:
            results["invalid"].append(result)
        return result
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=request.threads) as executor:
        executor.map(check_single, request.smtp_list)
    
    return {
        "status": "completed",
        "valid_count": len(results["valid"]),
        "invalid_count": len(results["invalid"]),
        "results": results
    }