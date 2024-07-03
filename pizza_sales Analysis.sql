
-- Basic:
-- Retrieve the total number of orders placed.
SELECT
	COUNT(*) As total_orders
FROM orders;

-- Calculate the total revenue generated from pizza sales.
SELECT 
	ROUND(SUM(orders_details.quantity * pizzas.price),2) AS total_sales
FROM
	orders_details 
JOIN pizzas
ON pizzas.pizza_id= orders_details.pizza_id;

-- Identify the highest-priced pizza.
SELECT 
	pizza_types.name, 
	pizzas.price
FROM pizza_types 
JOIN pizzas
ON pizza_types.pizza_type_id= pizzas.pizza_type_id
ORDER BY pizzas.price DESC;

-- Identify the most common pizza size ordered.
SELECT 
	pizzas.size, 	
    COUNT(orders_details.order_details_id) AS pizza_count
FROM pizzas
JOIN orders_details
ON pizzas.pizza_id=orders_details.pizza_id
GROUP BY pizzas.size
ORDER BY pizza_count DESC;

-- List the top 5 most ordered pizza types along with their quantities.
SELECT 
	pizza_types.name, 
    SUM(orders_details.quantity) AS quantity
FROM
	orders_details 
JOIN pizzas
ON pizzas.pizza_id= orders_details.pizza_id
JOIN pizza_types 
ON pizza_types.pizza_type_id= pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5;

-- Intermediate:
-- Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
	pizza_types.category, 
    SUM(orders_details.quantity) AS quantity
FROM
	orders_details 
JOIN pizzas
ON pizzas.pizza_id= orders_details.pizza_id
JOIN pizza_types 
ON pizza_types.pizza_type_id= pizzas.pizza_type_id
GROUP BY pizza_types.category
ORDER BY quantity DESC;

-- Determine the distribution of orders by hour of the day.
SELECT 
	HOUR(order_time), 
    COUNT(order_id)
FROM orders
GROUP BY hour(order_time);

-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
	category,
    COUNT(name)
FROM pizza_types
GROUP BY category;
-- Group the orders by date and calculate the average number of pizzas ordered per day.
-- with subqueries
SELECT 
    ROUND(AVG(quantity), 0)
FROM
    (SELECT 
        order_date, SUM(quantity) AS quantity
    FROM
        orders o
    JOIN orders_details od ON o.order_id = od.order_id
    GROUP BY order_date) AS order_quantity;
-- With CTE    
    WITH DailyOrderQuantities AS (
    SELECT 
        o.order_date, 
        SUM(od.quantity) AS quantity
    FROM 
        orders o
    JOIN 
        orders_details od 
    ON 
        o.order_id = od.order_id
    GROUP BY 
        o.order_date
)
SELECT 
    ROUND(AVG(quantity), 0) AS average_quantity
FROM 
    DailyOrderQuantities;

-- Determine the top 3 most ordered pizza types based on revenue.
SELECT 
	pizza_types.name, 
    ROUND(SUM(orders_details.quantity * pizzas.price),2) AS revenue
FROM 
	orders_details 
JOIN pizzas
ON pizzas.pizza_id= orders_details.pizza_id
JOIN pizza_types
ON pizzas.pizza_type_id=pizza_types.pizza_type_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;

-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
	pizza_types.category, 
    ROUND(SUM(orders_details.quantity * pizzas.price)/(SELECT
    ROUND(SUM(orders_details.quantity * pizzas.price),2) AS total_sales
    
FROM 
	orders_details
    JOIN pizzas
    ON pizzas.pizza_id =orders_details.pizza_id)*100,2) as revenue

FROM pizza_types
JOIN pizzas
ON pizzas.pizza_type_id=pizza_types.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id=pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;

-- With CTE

-- Calculate the total sales from all orders first
WITH TotalSales AS (
    SELECT 
        ROUND(SUM(od.quantity * p.price), 2) AS total_sales
    FROM 
        orders_details od
        JOIN pizzas p ON p.pizza_id = od.pizza_id
)

-- Calculate the revenue share of each pizza category
SELECT 
    pt.category, 
    ROUND(SUM(od.quantity * p.price) / (SELECT total_sales FROM TotalSales) * 100, 2) AS revenue_percentage
FROM 
    pizza_types pt
    JOIN pizzas p ON p.pizza_type_id = pt.pizza_type_id
    JOIN orders_details od ON od.pizza_id = p.pizza_id
GROUP BY 
    pt.category
ORDER BY 
    revenue_percentage DESC;
    

-- Analyze the cumulative revenue generated over time.
SELECT 
	order_date, revenue,
    SUM(revenue) OVER(ORDER BY order_date) AS cum_revenue
FROM
(SELECT 
	orders.order_date,
	SUM(orders_details.quantity * pizzas.price) AS revenue
FROM orders_details
JOIN pizzas
ON orders_details.pizza_id =pizzas.pizza_id
JOIN orders
ON orders.order_id =orders_details.order_id
GROUP BY orders.order_date) AS sales;

-- WITH CTE
WITH RevenueByDate AS (
    SELECT 
        o.order_date,
        SUM(od.quantity * p.price) AS revenue
    FROM 
        orders_details od
        JOIN pizzas p ON od.pizza_id = p.pizza_id
        JOIN orders o ON o.order_id = od.order_id
    GROUP BY 
        o.order_date
)

SELECT 
    order_date,
    SUM(revenue) OVER (ORDER BY order_date) AS cum_revenue
FROM 
    RevenueByDate
ORDER BY 
    order_date;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT 
	category, 
    name, 
    revenue,
RANK() OVER(PARTITION BY category ORDER BY revenue DESC)AS rn
FROM
(SELECT 
	pizza_types.category, 
    pizza_types.name,
	SUM((orders_details.quantity) *pizzas.price) AS revenue
FROM
	pizza_types
JOIN pizzas
ON pizza_types.pizza_type_id=pizzas.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id=pizzas.pizza_id
GROUP BY pizza_types.category, pizza_types.name) AS a;

-- wITH cte
WITH RevenueCTE AS (
    SELECT 
        pt.category, 
        pt.name,
        SUM(od.quantity * p.price) AS revenue
    FROM 
        pizza_types pt
        JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN orders_details od ON od.pizza_id = p.pizza_id
    GROUP BY 
        pt.category, 
        pt.name
)

SELECT 
    category, 
    name, 
    revenue,
    RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
FROM 
    RevenueCTE
ORDER BY 
    category, rn;






