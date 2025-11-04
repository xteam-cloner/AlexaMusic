#!/bin/bash

# --- 0. Konfigurasi Awal ---
# Memuat variabel dari file .env (ini harus diisi!)
if [ -f .env ]; then
    echo "Memuat konfigurasi dari .env..."
    # Mengekspor variabel dari .env
    export $(grep -v '^#' .env | xargs)
else
    echo "ERROR: File .env tidak ditemukan. Pastikan sudah diisi."
    exit 1
fi

# Variabel konfigurasi Docker (tetap sama)
IMAGE_NAME="${IMAGE_NAME:-alexamusic:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-AlexaMusic_bot}"

# --- 1. Membangun Image Docker ---
echo "--- Membangun Image Docker: $IMAGE_NAME ---"
# Asumsi Anda berada di direktori root repository bot ini
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Proses 'docker build' gagal."
    exit 1
fi
echo "✅ Image Docker berhasil dibangun: $IMAGE_NAME"
echo ""

# --- 2. Menghapus Kontainer Lama (Jika Ada) ---
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "Menghapus kontainer lama ($CONTAINER_NAME)..."
    docker rm -f "$CONTAINER_NAME"
fi

# --- 3. Perintah Docker Run Utama ---
echo "--- Menjalankan kontainer $CONTAINER_NAME ---"

docker run -d \
  --restart=unless-stopped \
  --name "$CONTAINER_NAME" \
  \
  # Variabel Environment Wajib dan Opsional (disesuaikan dengan daftar Anda)
  -e API_ID="${API_ID}" \
  -e API_HASH="${API_HASH}" \
  -e BOT_TOKEN="${BOT_TOKEN}" \
  -e OWNER_ID="${OWNER_ID}" \
  -e STRING_SESSION="${STRING_SESSION}" \
  \
  # Variabel yang Namanya Disesuaikan
  -e MONGO_DB_URI="${MONGO_DB_URI}" \
  -e LOG_GROUP_ID="${LOG_GROUP_ID}" \
  \
  # Variabel Baru
  ${MUSIC_BOT_NAME:+-e MUSIC_BOT_NAME="${MUSIC_BOT_NAME}"} \
  ${COOKIES:+-e COOKIES="${COOKIES}"} \
  \
  "$IMAGE_NAME"

# --- 4. Status Kontainer ---
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Bot AnonXMusic berhasil dijalankan di background!"
    echo "Untuk melihat log real-time:"
    echo "docker logs -f $CONTAINER_NAME"
    echo ""
    docker ps -f "name=$CONTAINER_NAME"
else
    echo ""
    echo "❌ Terjadi kesalahan saat menjalankan Docker."
fi
