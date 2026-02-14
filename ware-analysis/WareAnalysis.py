

import pandas as pd

# Read all 4 CSV files
df1 = pd.read_csv('February2_simplified.csv')
df2 = pd.read_csv('BigMomma.csv')
df3 = pd.read_csv('EvenBetterJanuary.csv')
df4 = pd.read_csv('JanMar_corrected.csv')

# Concatenate all dataframes vertically
combined_df = pd.concat([df1, df2, df3, df4], ignore_index=True)

# Save the combined dataframe to a new CSV file
combined_df.to_csv('all_orders_combined.csv', index=False)

# Display summary information
print(f"Successfully combined all files!")
print(f"Total rows: {len(combined_df)}")
print(f"Expected total: {82 + 227 + 116 + 61} = {82 + 227 + 116 + 61}")
print(f"\nColumns: {list(combined_df.columns)}")
print(f"\nFirst 5 rows of combined data:")
print(combined_df.head())
print(f"\nLast 5 rows of combined data:")
print(combined_df.tail())

### Merged Dataset ###
# Read the combined file
df = pd.read_csv('all_orders_combined.csv')

print(f"Total entries: {len(df)}")
print("\nBefore standardization - sample addresses:")
print(df['Shipping Address'].head(10))

# Convert all addresses to uppercase
df['Shipping Address'] = df['Shipping Address'].str.upper()

# Fix multiple spaces (replace with single space)
df['Shipping Address'] = df['Shipping Address'].str.replace(r'\s+', ' ', regex=True)

# Fix spacing around commas (remove spaces before, ensure one space after)
df['Shipping Address'] = df['Shipping Address'].str.replace(r'\s*,\s*', ', ', regex=True)

# Specific fixes for common patterns:
# 1. Standardize apartment/suite abbreviations
df['Shipping Address'] = df['Shipping Address'].str.replace(r'\bAPT\b', 'APT', regex=True)
df['Shipping Address'] = df['Shipping Address'].str.replace(r'\bSTE\b', 'STE', regex=True)
df['Shipping Address'] = df['Shipping Address'].str.replace(r'\bSUITE\b', 'STE', regex=True)

# 2. Fix the 3700 Beacon Ave addresses specifically
beacon_mask = df['Shipping Address'].str.contains('3700 BEACON AVE', na=False)
df.loc[beacon_mask, 'Shipping Address'] = df.loc[beacon_mask, 'Shipping Address'].str.replace(
    r'3700 BEACON AVE\s*(APT\s*140|A\s*140|140)',
    '3700 BEACON AVE APT 140',
    regex=True
)


# 4. Ensure all addresses have proper state abbreviation (CA not Ca)
df['Shipping Address'] = df['Shipping Address'].str.replace(r',\s*Ca\b', ', CA', regex=True, case=False)

# 5. Remove any trailing/leading whitespace
df['Shipping Address'] = df['Shipping Address'].str.strip()

# Save the standardized file
df.to_csv('all_orders_standardized.csv', index=False)

print("\nAfter standardization - sample addresses:")
print(df['Shipping Address'].head(10))

print("\nUnique addresses after standardization:")
unique_addresses = df['Shipping Address'].unique()
print(f"Total unique addresses: {len(unique_addresses)}")
for i, addr in enumerate(unique_addresses[:10]):
    print(f"  {i+1}. {addr}")

# Check if all addresses are now uppercase
all_uppercase = df['Shipping Address'].apply(lambda x: x == x.upper() if pd.notna(x) else True).all()
print(f"\nAll addresses uppercase: {all_uppercase}")



### Time for Analysis and graphs!!! ###
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

# Set up clean, professional style
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 14
plt.rcParams['axes.titlesize'] = 18
plt.rcParams['axes.labelsize'] = 14
plt.rcParams['xtick.labelsize'] = 12
plt.rcParams['ytick.labelsize'] = 12

# Read and clean data
df = pd.read_csv('all_orders_standardized.csv')
df['Order Date'] = pd.to_datetime(df['Order Date'])
df['Total Price'] = pd.to_numeric(df['Total Price'], errors='coerce')
df = df.dropna(subset=['Order Date', 'Total Price'])

# Remove future dates (December 2025 hasn't happened yet)
df = df[df['Order Date'] <= pd.Timestamp.now()]

# Remove rows with missing shipping addresses
df = df.dropna(subset=['Shipping Address'])

df['Category'] = df['Category'].fillna('Uncategorized')

# Chart 1: Total Money Spent - Simple Bar Chart
plt.figure(figsize=(10, 6))
total_spent = df['Total Price'].sum()
plt.bar(['Total Company Money Spent'], [total_spent], color='red', width=0.5)
plt.title('Total Amount Spent by Employee', fontsize=20, fontweight='bold', pad=20)
plt.ylabel('Amount ($)', fontsize=16)
plt.text(0, total_spent + 2000, f'${total_spent:,.0f}', ha='center', va='bottom',
         fontsize=24, fontweight='bold', color='red')
plt.ylim(0, total_spent * 1.15)
plt.grid(axis='y', alpha=0.3)
plt.tight_layout()
plt.savefig('1_total_spending.png', dpi=300, bbox_inches='tight')
plt.show()

# Chart 2: Monthly Spending - Line Chart
plt.figure(figsize=(14, 7))
df['YearMonth'] = df['Order Date'].dt.strftime('%b %Y')
monthly_data = df.groupby('YearMonth')['Total Price'].sum()
# Sort by actual date order
date_order = df.groupby('YearMonth')['Order Date'].min().sort_values()
monthly_data = monthly_data.reindex(date_order.index)
months = monthly_data.index.tolist()
amounts = monthly_data.values

plt.plot(months, amounts, marker='o', linewidth=4, markersize=10, color='red')
plt.title('Monthly Spending Pattern', fontsize=20, fontweight='bold', pad=20)
plt.xlabel('Month', fontsize=16)
plt.ylabel('Amount Spent ($)', fontsize=16)
plt.xticks(rotation=45)
plt.grid(True, alpha=0.3)

# Add value labels on points
for i, (month, amount) in enumerate(zip(months, amounts)):
    plt.text(i, amount + max(amounts)*0.02, f'${amount:,.0f}',
             ha='center', va='bottom', fontsize=11, fontweight='bold')

plt.tight_layout()
plt.savefig('2_monthly_spending.png', dpi=300, bbox_inches='tight')
plt.show()

# Chart 3: Top Categories - Simple Bar Chart
plt.figure(figsize=(12, 8))
top_categories = df.groupby('Category')['Total Price'].sum().sort_values(ascending=False).head(8)

bars = plt.bar(range(len(top_categories)), top_categories.values, color='darkred')
plt.title('Where the Money Went - Top Spending Categories', fontsize=20, fontweight='bold', pad=20)
plt.xlabel('Category', fontsize=16)
plt.ylabel('Total Amount ($)', fontsize=16)
plt.xticks(range(len(top_categories)), top_categories.index, rotation=45, ha='right')

# Add value labels on bars
for bar, value in zip(bars, top_categories.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + max(top_categories.values)*0.01,
             f'${value:,.0f}', ha='center', va='bottom', fontsize=12, fontweight='bold')

plt.grid(axis='y', alpha=0.3)
plt.tight_layout()
plt.savefig('3_top_categories.png', dpi=300, bbox_inches='tight')
plt.show()

# Chart 4: Large Orders - Simple Table Visualization
plt.figure(figsize=(14, 10))
large_orders = df[df['Total Price'] > 500].sort_values('Total Price', ascending=False).head(10)

# simple table plot
fig, ax = plt.subplots(figsize=(14, 8))
ax.axis('tight')
ax.axis('off')

# Prepare table data
table_data = []
for _, row in large_orders.iterrows():
    table_data.append([
        row['Order Date'].strftime('%b %d, %Y'),
        f"${row['Total Price']:,.0f}",
        row['Category'],
        row['Item Description'][:50] + '...' if len(str(row['Item Description'])) > 50 else row['Item Description']
    ])

# Create table
table = ax.table(cellText=table_data,
                colLabels=['Date', 'Amount', 'Category', 'Item Description'],
                cellLoc='left',
                loc='center',
                colWidths=[0.15, 0.15, 0.2, 0.5])

table.auto_set_font_size(False)
table.set_fontsize(11)
table.scale(1, 2)

# Style the table
for i in range(len(large_orders) + 1):
    for j in range(4):
        cell = table[(i, j)]
        if i == 0:  # Header row
            cell.set_facecolor('#d32f2f')
            cell.set_text_props(weight='bold', color='white')
        else:
            if j == 1:  # Amount column
                cell.set_text_props(weight='bold', color='red')
            cell.set_facecolor('#f5f5f5' if i % 2 == 0 else 'white')

plt.title('Largest Individual Orders (Over $500)', fontsize=20, fontweight='bold', pad=20)
plt.savefig('4_large_orders.png', dpi=300, bbox_inches='tight')
plt.show()

# Chart 5: Number of Orders Per Month - Bar Chart
plt.figure(figsize=(12, 7))
monthly_count = df.groupby('YearMonth').size()
monthly_count = monthly_count.reindex(date_order.index)
months = monthly_count.index.tolist()
counts = monthly_count.values

bars = plt.bar(months, counts, color='orange', alpha=0.8)
plt.title('Number of Orders Per Month', fontsize=20, fontweight='bold', pad=20)
plt.xlabel('Month', fontsize=16)
plt.ylabel('Number of Orders', fontsize=16)
plt.xticks(rotation=45)

# Add value labels
for bar, count in zip(bars, counts):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
             str(count), ha='center', va='bottom', fontsize=12, fontweight='bold')

plt.grid(axis='y', alpha=0.3)
plt.tight_layout()
plt.savefig('5_orders_per_month.png', dpi=300, bbox_inches='tight')
plt.show()

# Chart 6: Order Sizes - Simple Pie Chart
plt.figure(figsize=(10, 8))
order_ranges = pd.cut(df['Total Price'],
                     bins=[0, 50, 200, 500, 1000, float('inf')],
                     labels=['Under $50', '$50-$200', '$200-$500', '$500-$1,000', 'Over $1,000'])
order_counts = order_ranges.value_counts()

colors = ['lightgreen', 'yellow', 'orange', 'red', 'darkred']
wedges, texts, autotexts = plt.pie(order_counts.values,
                                  labels=order_counts.index,
                                  autopct='%1.1f%%',
                                  colors=colors,
                                  startangle=90,
                                  textprops={'fontsize': 12})

# Make percentage text bold
for autotext in autotexts:
    autotext.set_fontweight('bold')
    autotext.set_fontsize(14)

plt.title('Distribution of Order Sizes', fontsize=20, fontweight='bold', pad=20)
plt.axis('equal')
plt.savefig('6_order_sizes.png', dpi=300, bbox_inches='tight')
plt.show()

# Chart 7: Shipping Addresses - Simple Bar Chart
plt.figure(figsize=(12, 8))
address_totals = df.groupby('Shipping Address')['Total Price'].sum().sort_values(ascending=False)

# Shorten address names for display
short_addresses = []
for addr in address_totals.index:
    # Take first part of address
    parts = str(addr).split(',')
    short_addresses.append(parts[0][:25] + '...' if len(parts[0]) > 25 else parts[0])

bars = plt.bar(range(len(address_totals)), address_totals.values, color='purple', alpha=0.7)
plt.title('Total Spending by Shipping Address', fontsize=20, fontweight='bold', pad=20)
plt.xlabel('Shipping Address', fontsize=16)
plt.ylabel('Total Amount ($)', fontsize=16)
plt.xticks(range(len(address_totals)), short_addresses, rotation=45, ha='right')

# Add value labels
for bar, value in zip(bars, address_totals.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + max(address_totals.values)*0.01,
             f'${value:,.0f}', ha='center', va='bottom', fontsize=11, fontweight='bold')

plt.grid(axis='y', alpha=0.3)
plt.tight_layout()
plt.savefig('7_shipping_addresses.png', dpi=300, bbox_inches='tight')
plt.show()

# Chart 8: Summary Statistics - Simple Text Chart
fig, ax = plt.subplots(figsize=(10, 8))
ax.axis('off')

# Calculate key statistics
total_spent = df['Total Price'].sum()
total_orders = len(df)
avg_order = df['Total Price'].mean()
largest_order = df['Total Price'].max()
num_addresses = df['Shipping Address'].nunique()
date_range = f"{df['Order Date'].min().strftime('%b %Y')} - {df['Order Date'].max().strftime('%b %Y')}"

# Create summary text
summary_text = f"""
KEY FINDINGS - EMPLOYEE SPENDING INVESTIGATION

Time Period: {date_range}

TOTAL MONEY SPENT: ${total_spent:,.0f}

Total Number of Orders: {total_orders:,}

Average Order Amount: ${avg_order:.0f}

Largest Single Order: ${largest_order:,.0f}

Number of Different Shipping Addresses: {num_addresses}

Orders Over $500: {len(df[df['Total Price'] > 500])}

Orders Over $1,000: {len(df[df['Total Price'] > 1000])}
"""

ax.text(0.1, 0.9, summary_text, transform=ax.transAxes, fontsize=16,
        verticalalignment='top', fontfamily='monospace',
        bbox=dict(boxstyle='round', facecolor='lightgray', alpha=0.8))

plt.title('Investigation Summary', fontsize=24, fontweight='bold', pad=30)
plt.savefig('8_summary.png', dpi=300, bbox_inches='tight')
plt.show()

print("All charts have been saved as individual PNG files:")
print("1. 1_total_spending.png - Shows total amount spent")
print("2. 2_monthly_spending.png - Monthly spending pattern")
print("3. 3_top_categories.png - Where money was spent by category")
print("4. 4_large_orders.png - Table of largest orders")
print("5. 5_orders_per_month.png - Frequency of ordering")
print("6. 6_order_sizes.png - Distribution of order amounts")
print("7. 7_shipping_addresses.png - Spending by location")
print("8. 8_summary.png - Key statistics summary")
print("\nEach chart is simple, clear, and ready for presentation to management.")



# Read the CSV file
df = pd.read_csv('all_orders_standardized.csv')

# Select only the required columns and reorder them
df = df[['Quantity', 'Item Description', 'Unit Price', 'Total Price']]

# Calculate the sum of Total Price
total_sum = df['Total Price'].sum()

# Create a new row with the sum
sum_row = pd.DataFrame({
    'Quantity': [''],
    'Item Description': ['TOTAL'],
    'Unit Price': [''],
    'Total Price': [total_sum]
})

# Concatenate the original dataframe with the sum row
df = pd.concat([df, sum_row], ignore_index=True)

# Save to a new CSV file
df.to_csv('processed_orders.csv', index=False)


csv_text4 = """Quantity,Item Description,Total Price
35,"Laptop",12210.73
15,"Desktop Computer",8048.83
34,"Docking Station",6586.19
56,"Other Electronics",4239.97
10,"UPS/Battery Backup",4200.29
55,"Charger/Power Adapter",3478.85
23,"Printer Ink/Toner",3476.19
15,"Monitor",2851.03
34,"Keyboard",2295.82
20,"Screen Protector",1926.75
8,"Network Equipment",1744.39
6,"Printer",1517.84
17,"Printer Paper",1442.08
26,"HDMI Cable",963.94
2,"External Hard Drive",881.55
2,"Power Bank",728.93
14,"Power Strip/Surge Protector",688.85
4,"Ethernet Cable",427.88
1,"External SSD",399.99
1,"Shredder",284.18
2,"Webcam",260.29
1,"Adapter",183.34
1,"USB Flash Drive",139.96
1,"Server Rack",118.95
2,"USB Hub",110.22
1,"Speaker",86.66
3,"Batteries",59.09
3,"Cable Management",41.97
2,"Computer Cleaning Kit",40.94
3,"USB Cable",26.93
1,"Extension Cable",22.99
3,"Mouse",44.94
,Total,58336.57
"""

# Write to file
with open("Electronics.csv", "w", encoding="utf-8") as f:
    f.write(csv_text4)
