from flask import Flask, request, jsonify, render_template, g
import sqlite3
import time
import pandas as pd
from datetime import datetime, timedelta
import json

# --- KONFIGURASI DATABASE ---
DB_PATH = 'flood_logs.db'

# --- KONFIGURASI LOGIKA ---
# Threshold Alert (Hanya untuk keperluan statistik/display di dashboard)
ALERT_THRESHOLD = 85 

app = Flask(
    __name__, 
    template_folder='templates',
    static_folder='static' # Pastikan folder statis disiapkan untuk CSS/JS jika ada
)

# --- FUNGSI DATABASE ---

def get_db():
    # Menggunakan g._database untuk koneksi thread-safe dalam konteks request Flask
    db = getattr(g, '_database', None)
    if db is None:
        # check_same_thread=False diperlukan jika Anda menggunakan thread selain request
        # Namun, karena threading dihapus, ini bisa diubah menjadi True (default)
        # Tapi tetap dipertahankan False agar lebih fleksibel jika ada penambahan thread di masa depan
        db = g._database = sqlite3.connect(DB_PATH, check_same_thread=False)
        db.row_factory = sqlite3.Row
    return db

def init_db():
    db = sqlite3.connect(DB_PATH, check_same_thread=False)
    db.row_factory = sqlite3.Row
    db.execute('''
    CREATE TABLE IF NOT EXISTS logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT,
        ts INTEGER,
        ts_iso TEXT,
        ultrasonic_cm REAL,
        level_percent INTEGER,
        water_level_percent INTEGER,
        final_level_percent INTEGER,
        sensor_status TEXT
    )
    ''')
    db.execute('CREATE INDEX IF NOT EXISTS idx_ts ON logs(ts)')
    db.execute('CREATE INDEX IF NOT EXISTS idx_device ON logs(device_id)')
    db.commit()
    db.close() # Tutup koneksi inisialisasi

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def insert_log(device_id, ts, ultrasonic_cm, level_percent, water_level_percent=None, final_level_percent=None, sensor_status=None):
    db = get_db()
    ts_iso = datetime.utcfromtimestamp(ts).isoformat()
    db.execute('''
        INSERT INTO logs (device_id, ts, ts_iso, ultrasonic_cm, level_percent, water_level_percent, final_level_percent, sensor_status) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', (device_id, ts, ts_iso, ultrasonic_cm, level_percent, water_level_percent, final_level_percent, sensor_status))
    db.commit()

def query_logs(limit=1000, device_id=None, hours=None):
    db = get_db()
    query = 'SELECT * FROM logs WHERE 1=1'
    params = []
    
    if device_id:
        query += ' AND device_id = ?'
        params.append(device_id)
    
    if hours:
        cutoff_ts = int((datetime.now() - timedelta(hours=hours)).timestamp())
        query += ' AND ts >= ?'
        params.append(cutoff_ts)
    
    query += ' ORDER BY ts DESC LIMIT ?'
    params.append(limit)
    
    cur = db.execute(query, params)
    rows = cur.fetchall()
    return [dict(r) for r in rows]

# --- ENDPOINTS FLASK ---

@app.route('/')
def index():
    # Tampilkan dashboard HTML Anda (pastikan file templates/dashboard.html tersedia)
    return render_template('dashboard.html')

@app.route('/data', methods=['POST'])
def receive_data():
    """Endpoint untuk menerima data JSON dari ESP32."""
    try:
        # Gunakan get_json(force=True) karena ESP32 tidak selalu mengirim Content-Type: application/json
        j = request.get_json(force=True)
        print(f"📨 Received JSON: {j}") 
    except Exception as e:
        print(f"JSON parse error: {e}")
        return jsonify({'ok': False, 'error': 'invalid json'}), 400

    # Extract data 
    device_id = j.get('device_id', 'unknown')
    # Gunakan time.time() server jika ESP32 tidak mengirim timestamp
    ts = int(time.time()) 
    ultrasonic_cm = float(j.get('ultrasonic_cm', -1))
    
    # Gunakan final_level_percent sebagai level_percent utama
    level_percent = j.get('final_level_percent', -1)
    level_percent = int(level_percent)
    
    water_level_percent = j.get('water_level_percent')
    final_level_percent = j.get('final_level_percent')
    sensor_status = j.get('sensor_status')
    
    # Validasi data
    if level_percent < 0 or level_percent > 100:
        print(f"❌ Invalid level_percent: {level_percent}")
        return jsonify({'ok': False, 'error': 'invalid level_percent'}), 400

    # Simpan ke database
    insert_log(device_id, ts, ultrasonic_cm, level_percent, water_level_percent, final_level_percent, sensor_status)
    
    print(f"✅ Data saved: {device_id} - {level_percent}% - {ultrasonic_cm}cm")
        
    return jsonify({'ok': True, 'received': {
        'device_id': device_id,
        'level_percent': level_percent,
        'ultrasonic_cm': ultrasonic_cm
    }}), 200

@app.route('/api/logs')
def api_logs():
    """Mengambil data log."""
    limit = int(request.args.get('limit', 1000))
    device_id = request.args.get('device_id')
    hours = request.args.get('hours', type=int)
    
    rows = query_logs(limit=limit, device_id=device_id, hours=hours)
    return jsonify(rows)

@app.route('/api/stats')
def api_stats():
    """Menghitung statistik dari log."""
    device_id = request.args.get('device_id')
    hours = request.args.get('hours', 24, type=int) # Default 24 jam
    
    rows = query_logs(limit=10000, device_id=device_id, hours=hours)
    if not rows:
        return jsonify({'ok': True, 'count': 0, 'data': {}})
    
    df = pd.DataFrame(rows)
    stats = {
        'count': len(df),
        'current': int(df.iloc[0]['level_percent']) if not df.empty else 0,
        'mean': float(df['level_percent'].mean()),
        'max': int(df['level_percent'].max()),
        'min': int(df['level_percent'].min()),
        'std': float(df['level_percent'].std()) if len(df) > 1 else 0.0
    }
    
    return jsonify({'ok': True, 'stats': stats})


# --- MAIN BLOCK ---

if __name__ == '__main__':
    # Pastikan database diinisialisasi sebelum server dijalankan
    init_db()
    
    print(f"Flood Detection Server started on http://0.0.0.0:5001")
    print(f"Listening for ESP32 POST requests on http://192.168.1.16:5001/data")
    
    # Jalankan aplikasi Flask, host 0.0.0.0 agar bisa diakses dari jaringan
    app.run(host='0.0.0.0', port=5001, debug=False)