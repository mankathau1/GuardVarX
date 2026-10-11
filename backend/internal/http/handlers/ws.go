package handlers

import (
	"net/http"

	"github.com/guardvarx/backend/internal/http/middleware"
	"github.com/guardvarx/backend/internal/websocket"
)

type WSHandler struct {
	hub *websocket.Hub
}

func NewWSHandler(hub *websocket.Hub) *WSHandler {
	return &WSHandler{hub: hub}
}

func (h *WSHandler) ServeWS(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		// Also allow token from query param ?token=
		token := r.URL.Query().Get("token")
		if token != "" {
			userID = "usr_token_sub"
		} else {
			userID = "usr_anonymous"
		}
	}

	h.hub.HandleConnection(w, r, userID)
}
