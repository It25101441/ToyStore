<%-- File: webapp/adminRegister.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Registration - ToyStore</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 2rem;
        }

        .register-container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 500px;
            animation: slideIn 0.5s ease;
        }

        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-50px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        h2 {
            text-align: center;
            color: #667eea;
            margin-bottom: 1rem;
        }

        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 1.5rem;
            font-size: 0.9rem;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        label {
            display: block;
            margin-bottom: 0.5rem;
            color: #333;
            font-weight: 500;
        }

        input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 1rem;
            transition: border-color 0.3s;
        }

        input:focus {
            outline: none;
            border-color: #667eea;
        }

        .password-hint {
            font-size: 0.75rem;
            color: #999;
            margin-top: 5px;
        }

        button {
            width: 100%;
            padding: 12px;
            background: #e53e3e;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 1rem;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.3s;
            margin-top: 1rem;
        }

        button:hover {
            background: #c53030;
        }

        .error {
            background: #fee;
            color: #c33;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
            border-left: 4px solid #e53e3e;
        }

        .success {
            background: #c6f6d5;
            color: #22543d;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
            border-left: 4px solid #38a169;
        }

        .info-box {
            background: #e6fffa;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            border-left: 4px solid #38b2ac;
            font-size: 0.85rem;
            color: #234e52;
        }

        .info-box strong {
            display: block;
            margin-bottom: 5px;
        }

        .login-link {
            text-align: center;
            margin-top: 1rem;
            font-size: 0.9rem;
        }

        .login-link a {
            color: #667eea;
            text-decoration: none;
        }

        .login-link a:hover {
            text-decoration: underline;
        }

        .back-link {
            text-align: center;
            margin-top: 0.5rem;
        }

        .back-link a {
            color: #999;
            text-decoration: none;
            font-size: 0.85rem;
        }

        .svg-icon {
            width: 24px;
            height: 24px;
            vertical-align: middle;
            margin-right: 8px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }
    </style>
</head>
<body>
    <div class="register-container">
        <h2>
            <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M12 2L15 9H22L16 14L19 21L12 17L5 21L8 14L2 9H9L12 2Z"/>
            </svg>
            Admin Registration
        </h2>
        <div class="subtitle">Create Administrator Account</div>

        <div class="info-box">
            <strong>
                <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                Important Information:
            </strong>
            This registration is for creating administrator accounts only. Admin accounts have full access to manage products, orders, and users. Please keep your credentials secure.
        </div>

        <% if (request.getAttribute("error") != null) { %>
            <div class="error">
                <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= request.getAttribute("error") %>
            </div>
        <% } %>

        <% if (request.getAttribute("success") != null) { %>
            <div class="success">
                <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20 6L9 17l-5-5"/>
                </svg>
                <%= request.getAttribute("success") %>
            </div>
        <% } %>

        <form action="adminRegister" method="post">
            <div class="form-group">
                <label>Full Name *</label>
                <input type="text" name="fullName" required>
            </div>

            <div class="form-group">
                <label>Username *</label>
                <input type="text" name="username" required>
            </div>

            <div class="form-group">
                <label>Email *</label>
                <input type="email" name="email" required>
            </div>

            <div class="form-group">
                <label>Password *</label>
                <input type="password" name="password" required>
                <div class="password-hint">Password will be encrypted using SHA-256 with salt before storing.</div>
            </div>

            <div class="form-group">
                <label>Confirm Password *</label>
                <input type="password" name="confirmPassword" required>
            </div>

            <button type="submit">Create Admin Account</button>
        </form>

        <div class="login-link">
            <a href="login">Already have an account? Login here</a>
        </div>
        <div class="back-link">
            <a href="index.jsp">
                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:4px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="19" y1="12" x2="5" y2="12"/>
                    <polyline points="12 19 5 12 12 5"/>
                </svg>
                Back to Home
            </a>
        </div>
    </div>
</body>
</html>