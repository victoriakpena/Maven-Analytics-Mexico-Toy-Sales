-- checking column names & schema for each table
Select
	*
From
	Information_Schema.Columns
Where
	Table_Name = N'inventory';


Select
	*
From
	Information_Schema.Columns
Where
	Table_Name = N'products';

Select
	*
From
	Information_Schema.Columns
Where
	Table_Name = N'sales';


Select
	*
From
	Information_Schema.Columns
Where
	Table_Name = N'stores';



-- fixing the data type for dates in the sales & stores tables 
Alter Table `Mexico_Toys`.`sales`
Add Column new_date DATE;
Update `Mexico_Toys`.`sales`
set new_date = str_to_date(Date, '%Y-%m-%d');


Select
	new_date
From
	`Mexico_Toys`.`sales`;


Alter Table `Mexico_Toys`.`stores`
Add Column new_store_open_date DATE;
Update `Mexico_Toys`.`stores`
set new_store_open_date = str_to_date(`store_open_date`, '%Y-%m-%d');


Select
	new_store_open_date
From
	Mexico_Toys.stores;



-- remove 'Maven Toys' from stores names to leave location only
Update 
	stores
Set 
	store_name=substring(store_name,12);


Select
	store_name
From
	stores;



-- Which product categories drive the biggest profits?
-- Toys & electronics have the highest two profits overall.
Select
	distinct product_category
From
	products;


Select
	products.product_category, sum((products.product_price-products.product_cost)*sales.units) as product_category_profit
From
	products
Join
	sales ON products.product_id=sales.product_id
Group by
	products.product_category
Order by 
	product_category_profit desc;



-- Is this the best profit category the same across all store locations?
-- No, these are the top sellers amongst the fifty stores: 26 toys, 19 electoronics, 2 games, 2 sports & outdoors, 1 arts & craft
Select
	count(distinct store_name)
From
	stores;


Select
	products.product_category, stores.store_name,
    sum((products.product_price-products.product_cost)*sales.units) as product_category_profit,
    row_number() over (partition by stores.store_name order by sum((products.product_price-products.product_cost)*sales.units) desc) as category_rank_by_store
From
	sales
Join
	products ON sales.product_id=products.product_id
Join
	stores ON sales.store_id=stores.store_id
Group by
	products.Product_Category, stores.store_name
Order by category_rank_by_store asc, products.product_category asc, product_category_profit desc;



-- Checking for overall profit trends by month across all stores
-- End of year (Oct-Dec) has the lowest overall profits, spring (March-May) has the highest overall profits
Select
	monthname(sales.new_date) as month, sum((products.product_price-products.product_cost)*sales.units) as profit_by_month
From
	sales
Join
	products ON sales.Product_ID=products.Product_ID
Group by
	month
Order by
	profit_by_month desc;



-- checking for top profiting category for each month
-- Electronics is best seller in Jan, Feb, Aug. Toys is best seller in all other months.
Select
	monthname(sales.new_date) as month, products.product_category,
    sum((products.product_price-products.product_cost)*sales.units) as product_category_profit,
    row_number() over (partition by monthname(sales.new_date) order by sum((products.product_price-products.product_cost)*sales.units) desc) as category_rank_by_month
From
	sales
Join
	products ON sales.product_id=products.product_id
Group by
	products.Product_Category, month
Order by 
category_rank_by_month asc, product_category_profit desc, month asc;



-- checking for best overall seller in each store location
-- electronics sells best in airports & commercial. toys sell best in downtown & residential
-- all locations have sports/outdoors as the lowest sellers. 
Select
	distinct store_location
From
	stores;


Select
	stores.store_location, products.product_category, 
    sum((products.product_price-products.product_cost)*sales.units) as category_profit,
    row_number() over (partition by stores.store_location order by sum((products.product_price-products.product_cost)*sales.units) desc) as category_rankings_by_location
From
	Sales
Join
	Products ON sales.product_id=products.product_id
Join
	Stores ON sales.store_id=stores.store_id
Group by
	stores.store_location, products.product_category
Order by
	category_rankings_by_location asc;



-- checking which product categories have the most stock on handler
-- arts & crafts has most stock, electronics has least stock
Select
	products.product_category, sum(inventory.stock_on_hand) as total_stock_on_hand
From
	products
Join
	inventory ON products.product_id=inventory.product_id
Group by
	products.product_category
Order by
	total_stock_on_hand desc;



-- checking if specific stores have low stock for the different categories
-- 35 stores have <50 units of electronics
Select
	min(stock_on_hand), max(stock_on_hand)
From 
	inventory;


Select
	stores.store_name, products.product_category, sum(inventory.stock_on_hand) as total_stock
From
	inventory
Join
	products on inventory.product_id=products.product_id
Join
	stores on stores.store_id=inventory.store_id
Group by
	products.product_category, stores.store_name
Having
	sum(inventory.stock_on_hand) < 50
Order by
	total_stock asc;



-- checking which stores are the most overall profiting
Select
	stores.store_name, sum((products.product_price-products.product_cost)*sales.units) as total_profits
From
	sales
Join
	products On products.product_id=sales.product_id
Join
	stores On stores.store_id=sales.store_id
Group by 
	stores.store_name
Order by total_profits desc;



-- checking to see which stores have out of stock (0) items
-- 37 distinict stores have at least 1 out of stock item.
Select
	stores.store_name, inventory.product_id, products.product_category, inventory.stock_on_hand
From
	inventory
Join
	products On products.product_id=inventory.product_id
Join
	stores On stores.store_id=inventory.store_id
Where
	inventory.stock_on_hand = 0
Order by
	stores.store_name asc, products.product_category asc;


Select
	count(distinct store_name) as stores_with_no_stock_items
From
	(
    Select
	stores.store_name, inventory.product_id, products.product_category, inventory.stock_on_hand
From
	inventory
Join
	products On products.product_id=inventory.product_id
Join
	stores On stores.store_id=inventory.store_id
Where
	inventory.stock_on_hand = 0) sub;



-- checking how much money the company has in inventory
-- 29,742 items are in stock & potential profits of $300,209.58 are tied up in inventory
Select
	sum(inventory.stock_on_hand) as total_stock,
    sum(products.product_cost*inventory.stock_on_hand) as money_tied_up_in_inventory
From
	inventory
Join
	products on inventory.product_id=products.product_id;



-- checking total overall profits for all locations
-- total profits of $4,014,029
Select
	 sum((products.product_price-products.product_cost)*sales.units) as total_profits
From 
	products
Join
	sales on sales.product_id=products.product_id;



-- checking total overall profits for each location
-- total profits of downtown: $2,248,728, commercial: $926,864, residential: $460,388, airport: $378,049
Select
	 sum((products.product_price-products.product_cost)*sales.units) as total_profits, stores.store_location
From 
	sales
Join
	products on sales.product_id=products.product_id
Join
	stores on sales.store_id=stores.store_id
Group by
	stores.store_location
Order by
	total_profits desc;



-- checking gross total revenue
-- gross total revenue: $14,444,572.35
Select
	round(sum(products.product_price*sales.units), 2) as gross_total_revenue
From
	sales
Join
	products on sales.product_id=products.product_id;



-- checking for total units sold
-- total units sold: 1,090,565 
Select
	sum(units) as total_units_sold
From
	sales;



-- checking total unique sales made
-- total unique sales: 829,262
Select
	count(sale_id) as total_unique_sales
From
sales;