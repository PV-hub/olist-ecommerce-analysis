-- ===================================
-- Check 1: Primary key uniqueness
-- Why: duplicate keys would inflate revenue/order counts
-- Finding: ลองเช็คจำนวนทั้งวิธีนับธรรมดากับนับค่าที่เป็นยูนิคตาราง order id ใน order แล้วก็ order id กับ order item id ในตาราง order item ส่วนตารางของ order review ใช้ order id กับ review id ทั้ง3ตารางลองนับแล้วได้จำนวนแถวเท่ากันเพราะฉะนั้นไม่มี duplicate key ในแต่ละ table 
-- =========================================
SELECT COUNT(*) FROM `olist-portfolio-513515.olist.orders`
UNION ALL
SELECT COUNT(DISTINCT(order_id)) FROM `olist-portfolio-513515.olist.orders`
UNION ALL
SELECT COUNT(*) FROM `olist-portfolio-513515.olist.order_items`
UNION ALL
SELECT COUNT(DISTINCT(CONCAT(order_id,"-",order_item_id))) FROM `olist-portfolio-513515.olist.order_items`
UNION ALL
SELECT COUNT(*) FROM `olist-portfolio-513515.olist.order_reviews`
UNION ALL
SELECT COUNT(DISTINCT(CONCAT(order_id,"-",review_id))) FROM `olist-portfolio-513515.olist.order_reviews`

-- ===================================
-- Check 2: Missing Value / Null Check
-- Why: ป้องกันไม่ให้ผลวิเคราะห์ผิดพลาด เพราะถ้าไม่มีวันที่หรือหมวดหมู่ จะคำนวณแนวโน้มหรือแยกประเภทสินค้าไม่ได้
-- Finding: คอลัมน์วันที่ใน orders หายไป 610 แถว จากทั้งหมด 32,000 แถว (คิดเป็น ~1.9%) 
-- คอลัมน์หมวดหมู่ใน products หายไป ประมาณ 3,000 แถว จากทั้งหมด 100,000 แถว (คิดเป็น ~3%)
-- =========================================
SELECT COUNTIF(product_category_name IS NULL) FROM `olist-portfolio-513515.olist.products`
UNION ALL
SELECT COUNTIF(order_delivered_carrier_date IS NULL
OR order_approved_at IS NULL OR order_delivered_customer_date IS NULL
OR order_estimated_delivery_date IS NULL OR order_purchase_timestamp IS NULL) FROM `olist-portfolio-513515.olist.orders`

-- ===================================
-- Check 3: Usable Order Timestamp
-- Why: To find the consistency of the order in the period that we can use to analyze.
-- Finding: จากข้อมูลคอลัมน์ timestamp พบว่าเดือนที่เก่าที่สุดคือเดือน 9 ปี 2016 จนถึงเดือน 10 ปี 2018 แล้วตั้งแต่เดือน 9 ถึงเดือน 12 ปี 2016 มีจำนวน entry ของ data ที่น้อยเกินไป และเดือน 9 ถึงเดือน 10 ของปี 2018 ก็เช่นกัน จึงคิดว่าไม่สามารถนำมาใช้ วิเคราะห์ได้ เลยต้องใช้ข้อมูลที่สามารถวิเคราะห์ได้ตั้งแต่เดือน 1 ปี 2017 ถึงเดือน 8 ปี 2018 
-- =========================================
SELECT
  DATE_TRUNC(order_purchase_timestamp, MONTH) AS purchase_month,
  COUNT(order_id) AS total_orders
FROM
  `olist-portfolio-513515.olist.orders`
GROUP BY
  1
ORDER BY
  purchase_month DESC;

-- ===================================
-- Check 4: Calculating for revenue
-- Why: In order table, there are order status and we need to define which status can include to calculate for revenue.
-- Finding: จากทั้งหมด 8 สเตตัสที่มีอยู่ใน table order พบว่ามีแค่สถานะ delivered ก็คือส่งมอบแล้ว ซึ่งเป็นกระบวนการสุดท้ายที่ส่งมอบให้กับลูกค้า จึงจะเป็นสถานะเดียวที่สามารถนำมาคิดเป็นรายได้ได้ ส่วนอย่างอื่นจะเริ่มต้นตั้งแต่สร้างออเดอร์ไปจนถึงการขนส่งเพื่อส่งมอบ จึงยังไม่ถือว่าสิ้นสุดกระบวนการ
-- =========================================
SELECT
  order_status,
  COUNT(order_id)
FROM
  `olist-portfolio-513515.olist.orders`
GROUP BY
  1

