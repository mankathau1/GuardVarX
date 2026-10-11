package websocket

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Configured via CORS
	},
}

type ClientMessage struct {
	Action  string `json:"action"` // "subscribe", "unsubscribe", "ping"
	Topic   string `json:"topic"`  // e.g. "incident:inc_123", "user:usr_456"
	Payload any    `json:"payload,omitempty"`
}

type ServerMessage struct {
	Event     string    `json:"event"`
	Topic     string    `json:"topic"`
	Payload   any       `json:"payload"`
	Timestamp time.Time `json:"timestamp"`
}

type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	send     chan []byte
	userID   string
	topics   map[string]bool
	mu       sync.Mutex
}

type Hub struct {
	mu         sync.RWMutex
	clients    map[*Client]bool
	topicRooms map[string]map[*Client]bool
	broadcast  chan ServerMessage
	register   chan *Client
	unregister chan *Client
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		topicRooms: make(map[string]map[*Client]bool),
		broadcast:  make(chan ServerMessage, 256),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				for topic := range client.topics {
					if room, exists := h.topicRooms[topic]; exists {
						delete(room, client)
						if len(room) == 0 {
							delete(h.topicRooms, topic)
						}
					}
				}
				close(client.send)
			}
			h.mu.Unlock()

		case msg := <-h.broadcast:
			h.mu.RLock()
			room, exists := h.topicRooms[msg.Topic]
			if exists {
				data, err := json.Marshal(msg)
				if err == nil {
					for client := range room {
						select {
						case client.send <- data:
						default:
							close(client.send)
							delete(h.clients, client)
							delete(room, client)
						}
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}

func (h *Hub) BroadcastToTopic(topic, event string, payload any) {
	h.broadcast <- ServerMessage{
		Event:     event,
		Topic:     topic,
		Payload:   payload,
		Timestamp: time.Now().UTC(),
	}
}

func (h *Hub) HandleConnection(w http.ResponseWriter, r *http.Request, userID string) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		slog.Error("WebSocket upgrade failed", "error", err)
		return
	}

	client := &Client{
		hub:    h,
		conn:   conn,
		send:   make(chan []byte, 64),
		userID: userID,
		topics: make(map[string]bool),
	}

	// Automatically subscribe user to personal channel
	userTopic := "user:" + userID
	client.topics[userTopic] = true

	h.register <- client

	h.mu.Lock()
	if h.topicRooms[userTopic] == nil {
		h.topicRooms[userTopic] = make(map[*Client]bool)
	}
	h.topicRooms[userTopic][client] = true
	h.mu.Unlock()

	go client.writePump()
	go client.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(4096)
	_ = c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		_ = c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			break
		}

		var req ClientMessage
		if err := json.Unmarshal(message, &req); err != nil {
			continue
		}

		switch req.Action {
		case "subscribe":
			if req.Topic != "" {
				c.mu.Lock()
				c.topics[req.Topic] = true
				c.mu.Unlock()

				c.hub.mu.Lock()
				if c.hub.topicRooms[req.Topic] == nil {
					c.hub.topicRooms[req.Topic] = make(map[*Client]bool)
				}
				c.hub.topicRooms[req.Topic][c] = true
				c.hub.mu.Unlock()
			}
		case "unsubscribe":
			if req.Topic != "" {
				c.mu.Lock()
				delete(c.topics, req.Topic)
				c.mu.Unlock()

				c.hub.mu.Lock()
				if room, ok := c.hub.topicRooms[req.Topic]; ok {
					delete(room, c)
				}
				c.hub.mu.Unlock()
			}
		case "ping":
			resp, _ := json.Marshal(map[string]string{"event": "pong"})
			c.send <- resp
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			_, _ = w.Write(message)
			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
