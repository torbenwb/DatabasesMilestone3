/* Team 3 Milestone 2 Queries */
/* Vendor Queries */

-- 1
/* 	This query returns the fastest selling listings purchased in the last 30 days as well as the difference between
	list and purchase price. Vendors can use this information to determine which listings sell most quickly and
    how that relates to the purchase price of that listing.
*/
select 
	timestampdiff(day, AllClosedListings.date, Purchase.date) as Days_Listed,
    AllClosedListings.price as List_Price, 
    Purchase.price as Purchase_Price,
	Vehicle.*
from AllClosedListings 
join Purchase on AllClosedListings.listing_num = Purchase.listing_num
join Vehicle on AllClosedListings.vehicle_num = Vehicle.vehicle_num
where 
	Purchase.date > date_sub(curdate(), interval 30 day) and 
	Purchase.date < curdate() 
order by Days_Listed;

-- 2
/*
	This query returns all open listings where the list price is below the average purchase price 
    for that make in the same $10,000 price bracket and has lower mileage than the average mileage
    for that make.
*/

select 
	AllOpenListings.listing_num as 'Listing Num',
    AllOpenListings.price as 'List Price',
    t0.avgPurchasePrice as 'Make Average Purchase Price',
    Vendor.vendor_name as 'Vendor',
    Vehicle.make, Vehicle.model, Vehicle.year, Vehicle.mileage
from AllOpenListings join Vehicle on AllOpenListings.vehicle_num = Vehicle.vehicle_num
join (
	select 
		Vehicle.make,
		avg(Purchase.price) as avgPurchasePrice
	from AllClosedListings join Vehicle on AllClosedListings.vehicle_num = Vehicle.vehicle_num
	join Purchase on AllClosedListings.listing_num = Purchase.listing_num group by Vehicle.make
) as t0 on Vehicle.make = t0.make
join (
	select Vehicle.make,
		avg(Vehicle.mileage) as avgMileage
		from Vehicle group by Vehicle.make
) as t1 on Vehicle.make = t1.make
join Vendor on Vehicle.vendor_num = Vendor.vendor_num 
where AllOpenListings.price < t0.avgPurchasePrice 
and abs(AllOpenListings.price - t0.avgPurchasePrice) < 5000
and Vehicle.mileage <= t1.avgMileage;

-- 3
/* This query classifies the customers who have viewed vehicle listings on our website many times but didn't make any purchase. 
This data will help vendors/admins reach out protential customers with buying wills. */
SELECT DISTINCT
    u.user_num AS 'User num',
    CONCAT(u.first_name, ' ', u.last_name) AS 'Customer name',
    u.phone AS 'Phone',
    u.email AS 'Email',
    region_name AS Region,
    SUM(v.times_viewed) AS 'Total views',
    COUNT(v.listing_num) AS 'Vehicles viewed',
    MAX(v.last_view) AS 'Last view time'
FROM
    User u
        INNER JOIN
    View v ON u.user_num = v.user_num
        INNER JOIN
    Region r ON r.region_num = u.region_num
        LEFT JOIN
    Purchase p ON v.listing_num = p.listing_num
WHERE
    p.listing_num IS NULL
GROUP BY u.user_num
ORDER BY SUM(v.times_viewed) DESC
LIMIT 30;

-- 4
/* This query identifies the average, maximum and minimum days for vehicles sold from listing to purchasing, by vehicle body types. 
This data will help vendors know which types of vehicle are selling fast, which may lead to inventory and price optimaization strategies.*/

SELECT 
    v.body_type AS 'Vehicle body type',
    ROUND(AVG(Selling_days), 0) AS 'Average selling days',
    MAX(Selling_days) AS 'Maximum selling days',
    MIN(Selling_days) AS 'Minimum selling days'
FROM
    Vehicle v
        INNER JOIN
    Listing l ON v.vehicle_num = l.vehicle_num
        INNER JOIN
    (SELECT 
        TIMESTAMPDIFF(DAY, l.date, p.date) AS 'Selling_days',
            l.listing_num
    FROM
        Vehicle v
    INNER JOIN Listing l ON v.vehicle_num = l.vehicle_num
    INNER JOIN Purchase p ON l.listing_num = p.listing_num) sub ON sub.listing_num = l.listing_num
GROUP BY v.body_type
ORDER BY AVG(Selling_days);

-- 5
/* This query lists the top 10 sales person who have create the most revenue. 
This list also includes information regarding which vendor the sales person belongs to, their total listings, and listing-selling converting rate. */

SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS 'Sales person',
    ven.vendor_name AS 'Vendor',
    SUM(p.price) AS `Total sales`,
    (COUNT(l.listing_num)) AS 'Total listings',
    ROUND((COUNT(p.purchase_num)) / (COUNT(l.listing_num)) * 100,
            2) AS 'List-sell converting rate %'
FROM
    ((Vehicle v
    INNER JOIN Listing l ON ((v.vehicle_num = l.vehicle_num)))
    INNER JOIN Vendor ven ON ven.vendor_num = v.vendor_num
    INNER JOIN Employee e ON e.employee_num = l.employee_num
    INNER JOIN User u ON u.user_num = e.user_num
    LEFT JOIN Purchase p ON ((l.listing_num = p.listing_num)))
GROUP BY e.user_num , ven.vendor_name
ORDER BY SUM(p.price) DESC
LIMIT 10;

-- 6
/* This query lists the top 10 selling brands along with average selling price. 
This will help vendors and customers know the popular vehicle makes and refer to their business behaviors. */

SELECT 
    v.make AS `Brand`,
    COUNT(p.purchase_num) AS `Total sales`,
    FORMAT(AVG(p.price), 2) AS `Average price`
FROM
    Vehicle v
        INNER JOIN
    Listing l ON v.vehicle_num = l.vehicle_num
        INNER JOIN
    Purchase p ON l.listing_num = p.listing_num
GROUP BY v.make
ORDER BY COUNT(p.purchase_num) DESC
LIMIT 10;

-- 7
/* 	This query returns the most viewed open listings whose last view was in the last 30 days. 
	Vendors and system admin can use this information to guage recent customer interest.
*/
select 
	agg.Listing_Total_Views as Total_Views,
	AllOpenListings.listing_num,
    AllOpenListings.date,
    AllOpenListings.price,
    Region.region_name,
    Vendor.vendor_name,
    Vehicle.make, Vehicle.model, Vehicle.year, Vehicle.color, Vehicle.engine_type,
    Vehicle.vin, Vehicle.body_type, Vehicle.mileage, Vehicle.transmission, Vehicle.drive_type
from 
	AllOpenListings
join (
	select 
		AllOpenListings.listing_num,
		sum(View.times_viewed) as Listing_Total_Views
	from AllOpenListings 
		join View on AllOpenListings.listing_num = View.listing_num
	where 
		View.last_view > date_sub(curdate(), interval 30 day) and 
		View.last_view < curdate() 
	group by AllOpenListings.listing_num
	order by Listing_Total_Views desc
) as agg on AllOpenListings.listing_num = agg.listing_num
join Vehicle 
	on AllOpenListings.vehicle_num = Vehicle.vehicle_num
join Vendor
	on Vehicle.vendor_num = Vendor.vendor_num
join Region
	on AllOpenListings.region_num = Region.region_num;

/* Customer Queries */
-- 8 
/* The stored procedure CustomerSearch_Rating_Make_Price_Mileage searches open listings and filters
results by average vendor rating, vehicle make, max price and max mileage
*/
-- Vendor avg rating > 3, Make: Toyota, Max Price: 90,000, Max Mileage: 10,000
call CustomerSearch_Rating_Make_Price_Mileage(3, 'Toyota', 90000, 10000);
-- Vendor avg rating > 2, Make: Ford, Max Price: 90,000, Max Mileage: 1,000
call CustomerSearch_Rating_Make_Price_Mileage(2, 'Ford', 90000, 1000);

-- 9
/* The stored procedure GetPriceTrend_LastYear returns a month by month breakdown of the average monthly
price of listings that meet customer specifications for max price, max mileage, min year, and vehicle body type
*/
-- Price trend of listings over the last year: price < 90,000, mileage < 10,000, year after 2000, body type = Seden
call GetPriceTrend_LastYear(90000,10000,2000,'Seden');
-- Price trend of listings over the last year: price < 60,000, mileage < 5,000, year after 2010, body type = SUV
call GetPriceTrend_LastYear(60000,5000,2010,'SUV');

-- 10
/* 	This query returns the regions with the top 10 purchased models. This gives first time customers an idea of vehicles
    to purchase per region.
*/
    
select
	v.make as 'Brand',
    v.model as 'Model',
    r.region_name as 'Region',
    count(p.purchase_num) as 'Total Sales',
	format(avg(p.price), 2) as 'Average Price'
from Region r left join Listing l on r.region_num = l.region_num
join Vehicle v on l.vehicle_num = v.vehicle_num
join Purchase p on l.listing_num = p.listing_num
group by v.make, v.model, r.region_num
order by count(p.purchase_num) desc
limit 10;









































































