package middleware

import (
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

type IPRateLimiter struct {
	ips sync.Map
	rps rate.Limit
	bur int
}

type clientLimiter struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

func NewIPRateLimiter(rps float64, burst int) *IPRateLimiter {
	i := &IPRateLimiter{
		rps: rate.Limit(rps),
		bur: burst,
	}

	// Clean up stale IPs periodically
	go func() {
		for {
			time.Sleep(3 * time.Minute)
			now := time.Now()
			i.ips.Range(func(key, value any) bool {
				cl := value.(*clientLimiter)
				if now.Sub(cl.lastSeen) > 5*time.Minute {
					i.ips.Delete(key)
				}
				return true
			})
		}
	}()

	return i
}

func (i *IPRateLimiter) GetLimiter(ip string) *rate.Limiter {
	val, exists := i.ips.Load(ip)
	if exists {
		cl := val.(*clientLimiter)
		cl.lastSeen = time.Now()
		return cl.limiter
	}

	limiter := rate.NewLimiter(i.rps, i.bur)
	i.ips.Store(ip, &clientLimiter{
		limiter:  limiter,
		lastSeen: time.Now(),
	})
	return limiter
}

func (i *IPRateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := r.RemoteAddr
		limiter := i.GetLimiter(ip)

		if !limiter.Allow() {
			w.Header().Set("Content-Type", "application/problem+json")
			w.WriteHeader(http.StatusTooManyRequests)
			_ = json.NewEncoder(w).Encode(map[string]any{
				"error": map[string]any{
					"code":       "RATE_LIMIT_EXCEEDED",
					"message":    "Too many requests. Please slow down.",
					"request_id": GetRequestID(r.Context()),
				},
			})
			return
		}

		next.ServeHTTP(w, r)
	})
}
