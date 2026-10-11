package middleware

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

type TokenValidator interface {
	ValidateToken(ctx context.Context, tokenStr string) (string, string, error) // returns userID, role, error
}

type AuthMiddleware struct {
	validator     TokenValidator
	allowMockAuth bool
}

func NewAuthMiddleware(v TokenValidator, allowMock bool) *AuthMiddleware {
	return &AuthMiddleware{
		validator:     v,
		allowMockAuth: allowMock,
	}
}

func (a *AuthMiddleware) RequireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			writeAuthError(w, r, http.StatusUnauthorized, "MISSING_TOKEN", "Authorization bearer token is required")
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")

		// Allow mock tokens in dev/test when enabled
		if a.allowMockAuth && strings.HasPrefix(tokenStr, "mock_") {
			parts := strings.Split(tokenStr, "_")
			userID := "usr_mock_1"
			role := "STANDARD_USER"
			if len(parts) >= 2 {
				userID = parts[1]
			}
			if len(parts) >= 3 {
				role = parts[2]
			}
			ctx := context.WithValue(r.Context(), UserIDKey, userID)
			ctx = context.WithValue(ctx, UserRoleKey, role)
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}

		if a.validator == nil {
			writeAuthError(w, r, http.StatusUnauthorized, "AUTH_UNAVAILABLE", "Token validator is not configured")
			return
		}

		userID, role, err := a.validator.ValidateToken(r.Context(), tokenStr)
		if err != nil {
			writeAuthError(w, r, http.StatusUnauthorized, "INVALID_TOKEN", err.Error())
			return
		}

		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		ctx = context.WithValue(ctx, UserRoleKey, role)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func GetUserID(ctx context.Context) string {
	if val, ok := ctx.Value(UserIDKey).(string); ok {
		return val
	}
	return ""
}

func GetUserRole(ctx context.Context) string {
	if val, ok := ctx.Value(UserRoleKey).(string); ok {
		return val
	}
	return ""
}

func writeAuthError(w http.ResponseWriter, r *http.Request, status int, code, msg string) {
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error": map[string]any{
			"code":       code,
			"message":    msg,
			"request_id": GetRequestID(r.Context()),
		},
	})
}

// DefaultJwtValidator implements basic JWT token parsing
type DefaultJwtValidator struct {
	SecretKey []byte
}

func (d *DefaultJwtValidator) ValidateToken(ctx context.Context, tokenStr string) (string, string, error) {
	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
		return d.SecretKey, nil
	})
	if err != nil || !token.Valid {
		return "", "", err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "", jwt.ErrTokenInvalidClaims
	}

	sub, _ := claims["sub"].(string)
	role, _ := claims["role"].(string)
	if role == "" {
		role = "STANDARD_USER"
	}

	return sub, role, nil
}
