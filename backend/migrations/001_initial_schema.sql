-- GuardVarX Initial PostgreSQL Schema Migration
-- Migration: 001_initial_schema.sql
-- Description: Core tables for users, devices, trusted contacts, emergency incidents, 
-- safe walk sessions, proximity missions, community reports, and audit logging.

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    phone VARCHAR(32),
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    avatar_url TEXT,
    role VARCHAR(32) NOT NULL DEFAULT 'STANDARD_USER',
    emergency_pin_hash VARCHAR(255),
    duress_pin_hash VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

CREATE TABLE IF NOT EXISTS devices (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(128) NOT NULL,
    fcm_token TEXT NOT NULL,
    platform VARCHAR(32) NOT NULL DEFAULT 'android',
    model VARCHAR(100),
    os_version VARCHAR(50),
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_device UNIQUE (user_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);

CREATE TABLE IF NOT EXISTS trusted_contacts (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(32) NOT NULL,
    relationship VARCHAR(50),
    is_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    can_view_safe_walk BOOLEAN NOT NULL DEFAULT TRUE,
    can_receive_sos BOOLEAN NOT NULL DEFAULT TRUE,
    priority_order INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trusted_contacts_user_id ON trusted_contacts(user_id);

CREATE TABLE IF NOT EXISTS emergency_incidents (
    incident_id VARCHAR(64) PRIMARY KEY,
    idempotency_key VARCHAR(128) UNIQUE,
    sender_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    emergency_type VARCHAR(64) NOT NULL,
    message TEXT,
    status VARCHAR(64) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy_meters DOUBLE PRECISION,
    location_timestamp TIMESTAMPTZ NOT NULL,
    priority VARCHAR(32) NOT NULL DEFAULT 'HIGH',
    protocol_version INT NOT NULL DEFAULT 1,
    receipt_id VARCHAR(64) NOT NULL,
    cancelled_reason TEXT,
    cancelled_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emergency_sender_id ON emergency_incidents(sender_id);
CREATE INDEX IF NOT EXISTS idx_emergency_status ON emergency_incidents(status);
CREATE INDEX IF NOT EXISTS idx_emergency_created_at ON emergency_incidents(created_at);

CREATE TABLE IF NOT EXISTS incident_events (
    id VARCHAR(64) PRIMARY KEY,
    incident_id VARCHAR(64) NOT NULL REFERENCES emergency_incidents(incident_id) ON DELETE CASCADE,
    previous_status VARCHAR(64),
    new_status VARCHAR(64) NOT NULL,
    actor_id VARCHAR(64),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_incident_events_incident_id ON incident_events(incident_id);

CREATE TABLE IF NOT EXISTS delivery_acknowledgements (
    id VARCHAR(64) PRIMARY KEY,
    incident_id VARCHAR(64) NOT NULL REFERENCES emergency_incidents(incident_id) ON DELETE CASCADE,
    contact_id VARCHAR(64),
    recipient_phone VARCHAR(32),
    delivery_channel VARCHAR(32) NOT NULL,
    acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_delivery_ack_incident_id ON delivery_acknowledgements(incident_id);

CREATE TABLE IF NOT EXISTS safe_walk_sessions (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(32) NOT NULL,
    destination_name VARCHAR(255) NOT NULL,
    destination_latitude DOUBLE PRECISION NOT NULL,
    destination_longitude DOUBLE PRECISION NOT NULL,
    current_latitude DOUBLE PRECISION,
    current_longitude DOUBLE PRECISION,
    expected_duration_minutes INT NOT NULL,
    checkin_interval_minutes INT NOT NULL,
    last_checkin_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    next_checkin_due TIMESTAMPTZ NOT NULL,
    trusted_contact_ids TEXT[] DEFAULT '{}',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_safe_walk_user_id ON safe_walk_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_safe_walk_status ON safe_walk_sessions(status);

CREATE TABLE IF NOT EXISTS ephemeral_location_pings (
    id VARCHAR(64) PRIMARY KEY,
    session_or_incident_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy_meters DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ephemeral_loc_target ON ephemeral_location_pings(session_or_incident_id);
CREATE INDEX IF NOT EXISTS idx_ephemeral_loc_expires ON ephemeral_location_pings(expires_at);

CREATE TABLE IF NOT EXISTS responder_profiles (
    user_id VARCHAR(64) PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    verification_status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    skills TEXT[] DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    last_latitude DOUBLE PRECISION,
    last_longitude DOUBLE PRECISION,
    last_location_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS missions (
    id VARCHAR(64) PRIMARY KEY,
    incident_id VARCHAR(64) NOT NULL REFERENCES emergency_incidents(incident_id) ON DELETE CASCADE,
    responder_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(32) NOT NULL,
    eta_minutes INT,
    accepted_at TIMESTAMPTZ,
    arrived_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_missions_incident_id ON missions(incident_id);
CREATE INDEX IF NOT EXISTS idx_missions_responder_id ON missions(responder_id);

CREATE TABLE IF NOT EXISTS community_reports (
    id VARCHAR(64) PRIMARY KEY,
    author_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    category VARCHAR(64) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    latitude_fuzzed DOUBLE PRECISION NOT NULL,
    longitude_fuzzed DOUBLE PRECISION NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    upvotes INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_reports_created ON community_reports(created_at);

CREATE TABLE IF NOT EXISTS user_blocks (
    id VARCHAR(64) PRIMARY KEY,
    blocker_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_block UNIQUE(blocker_id, blocked_id)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(64) PRIMARY KEY,
    actor_id VARCHAR(64),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(64) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at);
