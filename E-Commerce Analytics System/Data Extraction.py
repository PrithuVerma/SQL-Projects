from faker import *
import random
import pandas as pd
import numpy as np

fake = Faker('en_IN')

INDIA_STATES_CITIES = {
    "Andhra Pradesh": ["Visakhapatnam", "Vijayawada", "Guntur"],
    "Arunachal Pradesh": ["Itanagar", "Naharlagun", "Pasighat"],
    "Assam": ["Guwahati", "Silchar", "Dibrugarh"],
    "Bihar": ["Patna", "Gaya", "Bhagalpur"],
    "Chhattisgarh": ["Raipur", "Bhilai", "Bilaspur"],
    "Goa": ["Panaji", "Margao", "Vasco da Gama"],
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara"],
    "Haryana": ["Gurugram", "Faridabad", "Panipat"],
    "Himachal Pradesh": ["Shimla", "Solan", "Dharamshala"],
    "Jharkhand": ["Ranchi", "Jamshedpur", "Dhanbad"],
    "Karnataka": ["Bengaluru", "Mysuru", "Mangaluru"],
    "Kerala": ["Thiruvananthapuram", "Kochi", "Kozhikode"],
    "Madhya Pradesh": ["Indore", "Bhopal", "Jabalpur"],
    "Maharashtra": ["Mumbai", "Pune", "Nagpur"],
    "Manipur": ["Imphal", "Thoubal", "Bishnupur"],
    "Meghalaya": ["Shillong", "Tura", "Jowai"],
    "Mizoram": ["Aizawl", "Lunglei", "Saiha"],
    "Nagaland": ["Kohima", "Dimapur", "Mokokchung"],
    "Odisha": ["Bhubaneswar", "Cuttack", "Rourkela"],
    "Punjab": ["Ludhiana", "Amritsar", "Jalandhar"],
    "Rajasthan": ["Jaipur", "Jodhpur", "Udaipur"],
    "Sikkim": ["Gangtok", "Namchi", "Gyalshing"],
    "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai"],
    "Telangana": ["Hyderabad", "Warangal", "Nizamabad"],
    "Tripura": ["Agartala", "Udaipur", "Dharmanagar"],
    "Uttar Pradesh": ["Lucknow", "Kanpur", "Noida"],
    "Uttarakhand": ["Dehradun", "Haridwar", "Haldwani"],
    "West Bengal": ["Kolkata", "Howrah", "Durgapur"]
}

customers = []
categories = []
products = []
orders = []
order_items = []
returns = []

#------CUSTOMER TABLE CREATION-------#
for i in range(5000):
    state = random.choice(list(INDIA_STATES_CITIES.keys()))
    city = random.choice(INDIA_STATES_CITIES[state])
    customers.append({
        'customer_id' : i+1,
        'name' : fake.name(),
        'email' : fake.email(),
        'signup_date' : fake.past_date(),
        "city": city,
        "state": state,
    })

customer_table = pd.DataFrame(customers)

#------CATEGORY TABLE CREATION-------#
CATEGORIES = ['Apparel/Fashion', 'Electronics', 'Beauty/Cosmetics', 
            'Home & Kitchen Furniture', 'Food & Beverages', 'Toys']

for i, name in enumerate(CATEGORIES):
    categories.append({
        "category_id": i + 1,
        "category_name": name
    })

category_table = pd.DataFrame(categories)
cat_id = category_table['category_id']

#------PRODUCT TABLE CREATION-------#
ecommerce_products = [
    "Smartphone","Laptop","Wireless earbuds","Bluetooth speaker","Smartwatch","Phone charger",
    "Power bank","Headphones","LED TV","Gaming mouse","Mechanical keyboard","External hard drive",
    "USB flash drive","Wi-Fi router","Printer","Running shoes","T-shirt","Jeans",
    "Backpack","Sunglasses","Wristwatch","Perfume","Skincare moisturizer","Shampoo",
    "Electric trimmer","Coffee maker","Water bottle","Office chair","Bedsheets","Kitchen storage containers"
]

for i in range(300):
    
    cost = round(random.uniform(100, 40000), 2)
    price = round(cost * random.uniform(1.1, 1.6), 2)

    products.append({
        'product_id': i + 1,
        'product_name': random.choice(ecommerce_products),
        'category_id': random.choice(cat_id),
        'price': price,
        'cost_price': cost,
        'stock_quantity': random.randint(1, 10)
    })
product_table = pd.DataFrame(products)

#------ORDERS TABLE CREATION-------#
cust_id = customer_table['customer_id']
for i in range(12000):
    
    orders.append({
        'order_id': i + 1,
        'customer_id': random.choice(cust_id),
        'order status': random.choice(['Delivered','In Transit','Canceled']),
        'payment_method' : random.choice(['Cash on Delivery','Net Banking', 'UPI','Loyalty Points']),
    })
order_table = pd.DataFrame(orders)

#------ORDER ITEMS TABLE CREATION-------#

order_id = order_table['order_id']
prod_id = product_table['product_id']
unit_price = round(product_table['price']/product_table['stock_quantity'],2)

for i in range(25000):
    
    order_items.append({
        'order_item_id': i + 1,
        'order_id' : order_id,
        'product_id' : prod_id,
        'unit_price' : unit_price,
    })
    
order_item_table = pd.DataFrame(order_items)
print(order_item_table)

#------RETURNS TABLE CREATION-------#

order_item_id = order_item_table['order_item_id']
refund_price = product_table['price']
for i in range(1500):
    
    returns.append({
        'return_id': i + 1,
        'order_item_id' : order_item_id,
        'return_date' : fake.date_between(start_date="-2m",end_date='+1w'),
        'refund_amount' : refund_price,
    })
    
return_table = pd.DataFrame(returns)

# -------- EXPORT TABLES TO CSV -------- #

# customer_table.to_csv("customers.csv", index=False)
# category_table.to_csv("categories.csv", index=False)
# product_table.to_csv("products.csv", index=False)
# order_table.to_csv("orders.csv", index=False)
# order_item_table.to_csv("order_items.csv", index=False)
# return_table.to_csv("returns.csv", index=False)

# print("All tables exported successfully.")
