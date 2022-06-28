





alter table prod_dimen add primary key (Prod_id)
alter table orders_dimen add primary key (Ord_id)
alter table cust_dimen add primary key (Cust_id)
alter table shipping_dimen add primary key (Ship_id)









alter table market_fact add foreign key(ord_id) references orders_dimen(Ord_id);
alter table market_fact add foreign key(prod_id) references prod_dimen(prod_id);
alter table market_fact add foreign key(ship_id) references shipping_dimen(ship_id);
alter table market_fact add foreign key(cust_id) references cust_dimen(cust_id);
select Order_Date,Ord_id from orders_dimen
order by Order_Date
select Product_Base_Margin from market_fact
select Ord_id,Prod_id,Sales,Discount,Order_Quantity,Product_Base_Margin
into sale_margin
from market_fact
select * from market_fact
alter table sale_margin add foreign key (Ord_id) references orders_dimen(Ord_id);
alter table sale_margin add foreign key (Prod_id) references prod_dimen(Prod_id);


--1. Question ****************************************************************

--Using the columns of “market_fact”, “cust_dimen”, “orders_dimen”,
--“prod_dimen”, “shipping_dimen”, Create a new table, named as
--“combined_table”. 


--- Product margin= (selling price – cost of product) / selling price.

select mf.*,cd.Customer_Name,cd.Customer_Segment,cd.Province,
	   cd.Region,sd.Order_ID,sd.Ship_Date,sd.Ship_Mode,
	   od.Order_Date,od.Order_Priority,pd.Product_Category,
	   pd.Product_Sub_Category
into combined_table
from  prod_dimen as pd,
	  market_fact as mf,
	  cust_dimen as cd,
	  orders_dimen as od,
	  shipping_dimen as sd
where pd.Prod_id = mf.Prod_id
	  and cd.Cust_id= mf.Cust_id
	  and od.Ord_id=mf.Ord_id
	  and sd.Ship_id= mf.Ship_id


select * from combined_table

--2.Question *******************************************

--Maksimum sipariþ sayýsýna sahip ilk 3 müþteriyi bulun.


select top 3 Cust_id, count(distinct Ord_id) Max_Count_Of_Orders
from combined_table
group by Cust_id
order by 2 desc



--3. Question *************************************************

--Kombine_tabloda, Sipariþ_Tarihi ve Sevk_Tarihi
--arasýndaki tarih farkýný içeren DaysTakenForDelivery
--olarak yeni bir sütun oluþturun.

ALTER TABLE combined_table
ADD DaysTakenForDelivery int




alter table combined_table 
insert into combined_table(DaysTakenForDelivery) values(
select datediff (day,Order_Date,Ship_Date) as DaysTakenForDelivery
from combined_table)

---
select Ord_id,DATEDIFF(day, Order_Date, Ship_Date) AS DaysTakenForDelivery
into combined_table02
from  combined_table

select *
from  combined_table02

select co.*,cco.DaysTakenForDelivery
into combined_table01
from combined_table as co, combined_table02 as cco
where co.Ord_id=cco.Ord_id

select *
from  combined_table01
--

alter table combined_table drop column DaysTakenForDelivery



alter table combined_table add DaysTakenForDelivery int

create table DaysTakenForDeliverys as
SELECT datediff (day,Order_Date,Ship_Date) as DaysTakenForDelivery
FROM combined_table

--4.Question *****************************************************


--Find the customer whose order took the maximum time to get delivered.
--Sipariþinin teslim edilmesi için maksimum süreyi alan müþteriyi bulun.

select top 1 Cust_id,Customer_Name,DaysTakenForDelivery
from combined_table01
order by DaysTakenForDelivery desc

--5.Question--*******************************************************

--Count the total number of unique customers in January and how many of them
--came back every month over the entire year in 2011

--Ocak ayýndaki toplam benzersiz müþteri sayýsýný ve 2011'de tüm yýl 
--boyunca her ay kaç tanesinin geri geldiðini sayýn.

select count(distinct Cust_id)
from combined_table01
where order_date between '2011-01-01' and '2011-01-31' 

--Yukarýda, January içerisindeki sipariþ veren müþteri sayýsýný unique olarak getirdim.


select distinct Cust_id
into JanCust
from  combined_table01
where order_date between '2011-01-01' and '2011-01-31' 

--yukarýda ilk çýktýyý bir tabloya dönüþtürdüm

select distinct month(CT.Order_Date) as ByMonth ,year(CT.Order_Date) as ByYear,
			count(CT.cust_id) over (partition by month(CT.Order_Date)) as CustByMonths
from combined_table01 CT,JanCust JC
where JC.Cust_id=CT.Cust_id and Order_Date between '2011-02-01' and '2011-12-31'

--Yukarýda, ocak ayýnda sipariþ veren müþterilerin 2011 in diðer aylarýndaki sipariþ durumu(aylara göre ayrý ayrý)

--6. Question--***********************************************

--Write a query to return for each user the time elapsed between the first
--purchasing and the third purchasing, in ascending order by Customer ID.

--Her kullanýcý için ilk satýn alma ile üçüncü satýn alma arasýnda geçen süreyi Müþteri Kimliðine göre artan sýrada döndürmek için bir sorgu yazýn.

create view ByDate_Tablo as
select distinct Order_Date,Customer_Name, dense_rank() over (partition by Customer_Name order by Customer_Name,Order_Date) ByDate
from combined_table01
order by Customer_Name

--Yukarýda, sipariþ tarihleri unique olacak þekilde, her müþterinin sipariþlerini kendi içinde sipariþ tarihine göre derecelendirdim. 


create view FirstOrder as
select ByDate,Customer_Name,Order_Date
from ByDate_Tablo
where ByDate like 1

order by Customer_Name

--Yukarýda, müþterilerin "birinci" sipariþlerini içeren tabloyu view yaptým.

create view ThirdOrder as
select ByDate,Customer_Name,Order_Date
from ByDate_Tablo
where ByDate like 3

order by Customer_Name


--Yukarýda, müþterilerin "üçüncü" sipariþlerini içeren tabloyu view yaptým.


select F_O.Customer_Name,DATEDIFF(day,F_O.Order_Date,T_O.Order_Date) Order_Time_Difference
from FirstOrder F_O, ThirdOrder T_O
where F_O.Customer_Name=T_O.Customer_Name
order by Order_Time_Difference

--Yukarýda create view yaptýðým sütunlardan customer_name'leri birebir eþleþecek þekilde üçüncü ve birinci sipariþlerin tarihlerinin farkýný gün olarak aldým 
--NOT: bazý kiþilerin üçüncü sipariþi yok


--7. Question--***************************

--Write a query that returns customers who purchased both product 11 and
--product 14, as well as the ratio of these products to the total number of
--products purchased by the customer.

--Hem 11. ürünü hem de 14. ürünü satýn alan müþterileri ve bu ürünlerin müþteri tarafýndan satýn alýnan
--toplam ürün sayýsýna oranýný veren bir sorgu yazýn.

create view Prod11 as
select Customer_Name,Prod_id
from combined_table01 
where Prod_id like 11

order by Customer_Name

--Yukarýda Prod_id 'si 11 olan "Customer" larý getirdim.


create view Prod14 as
select distinct Customer_Name,Prod_id
from combined_table01 
where Prod_id like 14

order by Customer_Name

--Yukarýda Prod_id ' si 14 olan "Customer" larý getirdim.


select P11.Customer_Name,P11.Prod_id,P14.Prod_id
from Prod11 P11,Prod14 P14
where P11.Customer_Name = P14.Customer_Name

--Yukarýda prod_id 'si hem 11 hemde 14 olan ürünleri satýn alan "Customer" larý getirdim.


create view Names1114 as
select P11.Customer_Name
from Prod11 P11,Prod14 P14
where P11.Customer_Name = P14.Customer_Name

--Yukarýda, prod_id si 11 ve 14 olanlarýn isimlerini aldým.

create view amount_of_11_14 as
select distinct N.Customer_Name, sum(CT.Order_Quantity) over (partition by N.Customer_Name) Count_by_Name_11_14
from combined_table01 CT,Names1114 N
where N.Customer_Name = CT.Customer_Name and CT.Prod_id in (11,14)

order by 1

--yukarýda, isimlerini aldýðým kiþilerin 11,14 nolu ürünlerinin toplam sayýsýný gruplandýrarak getirdim.



create view amount_of_all as
select distinct N.Customer_Name, sum(CT.Order_Quantity) over (partition by N.Customer_Name) Count_by_Name_total
from Names1114 N,combined_table01 CT
where N.Customer_Name=CT.Customer_Name

order by N.Customer_Name

--Yukarýda, 11 ve 14 nolu ürünleri alanlarýn bütün alýþveriþleri

select A.Customer_Name, (A.Count_by_Name_11_14*1.0) /(B.Count_by_Name_total*1.0)*100 ratio
from amount_of_11_14 A, amount_of_all B
where A.Customer_Name=B.Customer_Name
order by 1

--Yukarýda 11. ve 14. nolu ürünleri ayný anda alan kiþilerin, aldýðý bütün ürünlere yüzdelik oranýný buldum


--******************************Part 2**************************************

--Categorize customers based on their frequency of visits. The following steps
--will guide you. If you want, you can track your own way.


--1.Question*******************************

-- Create a “view” that keeps visit logs of customers on a monthly basis. (For
-- each log, three field is kept: Cust_id, Year, Month)

--Müþterilerin ziyaret günlüklerini aylýk olarak tutan bir "görünüm" oluþturun. (Ýçin
--her günlük, üç alan tutulur: Cust_id, Year, Month)
 
create view By_Order_Date as
select Cust_id,year(Order_Date) Order_Year,month(Order_Date) Order_Month
from combined_table01

order by 1,2,3


--2.Question*********************************

--Create a “view” that keeps the number of monthly visits by users. (Show
--separately all months from the beginning business)

--Kullanýcýlarýn aylýk ziyaretlerinin sayýsýný tutan bir "görünüm" oluþturun. (Göstermek
--iþin baþlangýcýndan itibaren tüm aylar ayrý ayrý)


select distinct Cust_id,year(Order_Date) Order_Year,month(Order_Date) Order_Month,
		count(month(Order_Date)) over (partition by Cust_id,month(Order_Date)) Number_Of_Monthly
from combined_table01
order by 1,2,3

--3.Question****************************************

--For each visit of customers, create the next month of the visit as a separate column.
--Müþterilerin her ziyareti için, ziyaretin bir sonraki ayýný ayrý bir sütun olarak oluþturun.

create view DistOrder as
select distinct Order_Date, Cust_id
from combined_table01
order by Cust_id


create view NextMonthVisit as
select Cust_id, Order_Date, lead(Order_Date,1) over (partition by Cust_id order by Cust_id) Next_Visit
from DistOrder

order by Cust_id


select Cust_id, Order_Date, lead(Order_Date,1) over (partition by Cust_id order by Cust_id) Next_Visit
into AboutNextVisit
from DistOrder
order by Cust_id


alter table AboutNextVisit
alter column Next_Visit nvarchar(250)


select *
from AboutNextVisit

select Cust_id,Order_Date, isnull(Next_Visit,'no visits in the next month')
from AboutNextVisit

--4.Question

--Calculate the monthly time gap between two consecutive visits by each customer.

--Her müþterinin birbirini takip eden iki ziyareti arasýndaki aylýk zaman aralýðýný hesaplayýn.

create view DistOrder as
select distinct Order_Date, Cust_id
from combined_table01
order by Cust_id


create view NextVisit as
select Cust_id, Order_Date, lead(Order_Date,1,Order_Date) over (partition by Cust_id order by Cust_id) Next_Visit
from DistOrder
order by Cust_id

select Cust_id, Order_Date, Next_Visit,DATEDIFF(month,Order_Date,Next_visit) as MonthDifference
from NextVisit

--5. Categorise customers using average time gaps. Choose the most fitted labeling model for you.
--For example:
--o Labeled as churn if the customer hasn't made another purchase in the
--months since they made their first purchase.
--o Labeled as regular if the customer has made a purchase every month.

--5. Ortalama zaman boþluklarýný kullanarak müþterileri kategorilere ayýrýn. Size en uygun etiketleme modelini seçin.
--Örneðin:
--o Müþteri þu anda baþka bir satýn alma iþlemi yapmadýysa, kayýp olarak etiketlenir.
--Ýlk satýn almalarýný yaptýklarýndan bu yana aylar geçti.
--o Müþteri her ay alýþveriþ yaptýysa, düzenli olarak etiketlenir.
--Vb.



create view DistOrder as
select distinct Order_Date, Cust_id
from combined_table01

--

create view NextVisit as
select Cust_id, Order_Date, lead(Order_Date,1,Order_Date) over (partition by Cust_id order by Cust_id) Next_Visit
from DistOrder

order by Cust_id

--


create view Day_Diff as
select Cust_id, Order_Date, Next_Visit,DATEDIFF(day,Order_Date,Next_visit) as DayDifference
from NextVisit

--

create view AvgTimeGaps as
select distinct Cust_id,avg(DayDifference) over (partition by Cust_id) Avg_Time_Gaps
from Day_Diff

order by Cust_id

--

select Cust_id,Avg_Time_Gaps,
	case 
		when Avg_Time_Gaps = 0 then 'LOSS'
		when Avg_Time_Gaps <= 31 then 'REGULAR'
		when Avg_Time_Gaps > 31 then 'RARE'
	end as ResultsPurchase
from AvgTimeGaps
order by Cust_id


--Month-Wise Retention Rate***************************************

create view Cust_By_Month as
select distinct Cust_id,year(Order_Date) Year_Wise,month(Order_Date) Month_Wise,count(*) over (partition by year(Order_Date),month(Order_Date)) Number_Of_Month_wise_Cust
from combined_table01

order by 1,2,3

--


select Cust_id,Year_Wise,Month_Wise,lead(month_Wise,1) over (partition by Cust_id order by Year_Wise, Month_Wise) Next_Month_Cust
into NextMonthCust
from Cust_By_Month

select *
from NextMonthCust



create view SameCustInNextMounth as
select  distinct Year_Wise,Month_Wise,count(*) over (partition by Year_Wise,Month_Wise) Same_Cust_Ýn_Next_Mounth
from NextMonthCust
where Next_Month_Cust is not null

order by 1

--Yukarýda, bir sonraki ayda tekrar alýþveriþ yapanlarýn toplam sayýsýný buldum(ay bazýnda).ve view'ledim

create view NumberofCustByMonth as
select distinct year(Order_Date) Order_Year, month(Order_Date) Order_Month,count(*) over (partition by year(Order_Date),month(Order_Date)) Number_of_Cust_By_Month
from combined_table01

order by 1,2
--Yukarýda, Bütün alýþveriþleri aylara göre getirdim.

create view RetentionCustRate as
select SC.Year_Wise,SC.Month_Wise,(SC.Same_Cust_Ýn_Next_Mounth*1.0 /NC.Number_of_Cust_By_Month)*100 Retention_Cust_Rate
from NumberofCustByMonth NC,SameCustInNextMounth SC
where NC.Order_Month=SC.Month_Wise and NC.Order_Year=SC.Year_Wise

order by 1,2

select Year_Wise,Month_Wise,format(Retention_Cust_Rate,'N2') RetentionCustRate_Sort
from RetentionCustRate
order by 1,2

--Yukarýda, aylara göre bir sonraki ayda tekrar alýþveriþ yapanlarýn, tüm alýþveriþ yapanlara oranýný "Yüzdelik" olarak buldum.
