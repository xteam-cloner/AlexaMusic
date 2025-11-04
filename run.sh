#!/bin/bash

# --- 0. Konfigurasi Awal ---
if [ -f .env ]; then
    echo "Memuat konfigurasi dari .env..."
    # Menggunakan 'source' untuk memuat variabel
    source .env
else
    echo "❌ ERROR: File .env tidak ditemukan. Pastikan sudah diisi."
    exit 1
fi

IMAGE_NAME="${IMAGE_NAME:-alexamusic:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-alexamusic_bot}"

# --- 1. Membangun Image Docker ---
echo "--- Membangun Image Docker: $IMAGE_NAME ---"
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

# --- 3. Perintah Docker Run Utama (Menggunakan Sintaks eval) ---
echo "--- Menjalankan kontainer $CONTAINER_NAME ---"

# Membangun string perintah docker run
DOCKER_RUN_CMD="docker run -d --restart=unless-stopped --name \"$CONTAINER_NAME\" "
DOCKER_RUN_CMD+="-e API_ID=\"${API_ID}\" "
DOCKER_RUN_CMD+="-e API_HASH=\"${API_HASH}\" "
DOCKER_RUN_CMD+="-e BOT_TOKEN=\"${BOT_TOKEN}\" "
DOCKER_RUN_CMD+="-e OWNER_ID=\"${OWNER_ID}\" "
DOCKER_RUN_CMD+="-e STRING_SESSION=\"${STRING_SESSION}\" "
DOCKER_RUN_CMD+="-e MONGO_DB_URI=\"${MONGO_DB_URI}\" "
DOCKER_RUN_CMD+="-e LOG_GROUP_ID=\"${LOG_GROUP_ID}\" "
DOCKER_RUN_CMD+="-e MUSIC_BOT_NAME=\"${MUSIC_BOT_NAME}\" "
DOCKER_RUN_CMD+="-e COOKIES=\"${COOKIES}\" "
DOCKER_RUN_CMD+="$IMAGE_NAME"

# Menjalankan perintah
eval $DOCKER_RUN_CMD

# --- 4. Status Kontainer ---
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Bot berhasil dijalankan di background!"
    echo "Untuk melihat log real-time:"
    echo "docker logs -f $CONTAINER_NAME"
    echo ""
    docker ps -f "name=$CONTAINER_NAME"
else
    echo ""
    echo "❌ Terjadi kesalahan saat menjalankan Docker. Cek apakah ada variabel yang kosong atau tidak terdefinisi."
fi
