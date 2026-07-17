import sqlite3
import time
import os

DB_PATH = "C:/Users/WinsOft Computer/Documents/PharmacyData/pharmacy.db"

def force_sync_all():
    if not os.path.exists(DB_PATH):
        print(f"DB not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    now_ms = int(time.time() * 1000)

    try:
        cursor.execute("UPDATE customers SET updated_at = ?", (now_ms,))
        print(f"Updated {cursor.rowcount} customers.")

        cursor.execute("UPDATE daily_sales_sheets SET updated_at = ?", (now_ms,))
        print(f"Updated {cursor.rowcount} DSS records.")

        cursor.execute("UPDATE supplier_payments SET updated_at = ?", (now_ms,))
        print(f"Updated {cursor.rowcount} supplier payments.")

        cursor.execute("UPDATE suppliers SET updated_at = ?", (now_ms,))
        print(f"Updated {cursor.rowcount} suppliers.")

        conn.commit()
        print("Database timestamps updated successfully. Data will sync on next app launch or auto-sync interval.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    force_sync_all()
