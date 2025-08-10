import json
import os

def generate_data():
    users = []
    statuses = ["shipped", "processing", "delivered", "cancelled"]

    for user_id, user_name, user_email in [
        (1, "Alice", "alice@example.com"),
        (2, "Bob", "bob@example.com")
    ]:
        orders = []
        base_order_id = user_id * 100
        for i in range(1, 51):
            product_name = f"High Quality and Durable Product Model Number {i:03d} for Everyday Use"
            order = {
                "order_id": base_order_id + i,
                "product": product_name,
                "amount": round(10 + i * 0.5 + (user_id * 1.1), 2),
                "status": statuses[i % len(statuses)]
            }
            orders.append(order)

        user = {
            "id": user_id,
            "name": user_name,
            "email": user_email,
            "orders": orders
        }
        users.append(user)

    return {"users": users}


data = generate_data()

# Get the current working directory (where you run the script)
project_root = os.getcwd()

# Compose the storage/app path inside your Laravel project
storage_path = os.path.join(project_root, 'storage', 'app')

# Make sure the directory exists
os.makedirs(storage_path, exist_ok=True)

# Full file path
file_path = os.path.join(storage_path, 'users_orders.json')

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"JSON data saved to {file_path}")