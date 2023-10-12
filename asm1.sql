
SET GLOBAL max_allowed_packet = 1073741824;
SET GLOBAL wait_timeout = 2147483 ;
SET sql_mode = '';
SET sql_mode = 'HIGH_NOT_PRECEDENCE';

-- YC1 Viết các truy vấn để cho thấy sự tăng trưởng về mặt số lượng trong website và đưa ra nhận xét

create temporary table ss_od_qt
select 
	year(website_sessions.created_at) as 'year',
	quarter(website_sessions.created_at) as 'quarter',
    count(website_sessions.website_session_id) as sessions,
    count(orders.order_id) as orders
from website_sessions
left join orders on website_sessions.website_session_id=orders.website_session_id
group by 1,2;

/*
Số lượng orders và sessions max vào quý 4 của năm 2014
Số lượng sessions và order có sự tăng trưởng qua từng quý và từng năm
Có sự gia tăng đột biến số lượng sessions và order ở quý 4 của các năm
*/

-- YC2 Viết các truy vấn để thể hiện hiện được hiệu quả hoạt động của công ty và đưa ra nhận xét

create temporary table od_p_ss_rv
select 
	year(website_sessions.created_at) as 'year',
	quarter(website_sessions.created_at) as 'quarter',
    -- count(distinct website_sessions.website_session_id) as sessions,
	-- count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as ss_od_cv_rt,
    sum(orders.items_purchased*orders.price_usd)/count(distinct orders.order_id) as rv_p_od,
    sum(orders.items_purchased*orders.price_usd)/count(distinct website_sessions.website_session_id) as rv_p_ss
from website_sessions
left join orders
on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

/*
Tỉ lệ chuyển đổi đơn hàng từ sessions cao nhất vào quý 1 năm 2015
Doanh thu cao nhất trên mỗi đơn hàng là gần 64,49 vào quý 3 năm 2014
Doanh thu cao nhất trên mỗi session là gần 5,3 vào quý 1 năm 2015
Tỉ lệ chuyển đổi sessions thành order tăng liên tục từ năm 2012 đến nữa đầu năm 2013,
	sau đó có sự suy giảm vào nữa cuối năm 2013 và đầu năm 2014,
	sau đó phục hồi hoàn toàn như trước thời gian thời gian suy giảm,
	sau đó giảm vào quý 3 năm 2014,
	và tăng trưởng trong thời gian còn lại
 Tỉ lệ sinh lời của order trong năm đầu tiên cố định ở 49.99 
	nhưng lại sự gia tăng lợi nhận từ mỗi session,
	trong thời gian còn lại có sự biến động không đồng nhất
*/

-- YC3 Viết truy vấn để hiển thị sự phát triển của các đối tượng khác nhau và đưa ra nhận xét

create temporary table sr_od
select 
	year(website_sessions.created_at) as 'year',
	quarter(website_sessions.created_at) as 'quarter',
    count(case when website_sessions.utm_source = 'gsearch' 
    and website_sessions.utm_campaign = 'nonbrand'
    and website_sessions.website_session_id = orders.website_session_id
    then orders.website_session_id
    else null end)
    as gs_nb_od,
	count(case when website_sessions.utm_source = 'bsearch' 
    and website_sessions.utm_campaign = 'nonbrand'
    and website_sessions.website_session_id = orders.website_session_id
    then orders.website_session_id
    else null end)
    as bs_nb_od,   
    count(case when website_sessions.utm_campaign = 'brand'
    and website_sessions.website_session_id = orders.website_session_id
    then orders.website_session_id
    else null end)
    as b_s_od,
    count(case when website_sessions.utm_source IS NULL
    and website_sessions.http_referer is not null
    and website_sessions.website_session_id = orders.website_session_id
    then orders.website_session_id
    else null end)
    as or_od,
    count(case when website_sessions.utm_source IS NULL
    and website_sessions.http_referer is null
    and website_sessions.website_session_id = orders.website_session_id
    then orders.website_session_id
    else null end)
    as dt_od
from website_sessions
left join orders on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

/*
Số lượng đơn hàng thông qua gsearch-nonbrand là cao nhất trong tất cả các loại hình
Số lượng đơn hàng thông qua gsearch-nonbrand và bsearch-nonbrand cao nhất vào quý 4 năm 2014
Số lượng đơn hàng thông qua các hình thức còn lại cao nhất vào quý 1 năm 2015
*/

-- YC4 Viết truy vấn để hiển thị tỷ lệ chuyển đổi phiên thành đơn đặt hàng cho các đối tượng đã viết ở yêu cầu 3 và đưa ra nhận xét

create temporary table cv_rt
select 
	sr_od.year, 
    sr_od.quarter,
    sr_od.gs_nb_od / 
    count(case when website_sessions.utm_source = 'gsearch' 
    and website_sessions.utm_campaign = 'nonbrand'
    then website_sessions.website_session_id
    else null end)
    as gs_nb_cv_rt,
    sr_od.bs_nb_od / 
    count(case when website_sessions.utm_source = 'bsearch' 
    and website_sessions.utm_campaign = 'nonbrand'
    then website_sessions.website_session_id
    else null end)
    as bs_nb_cv_rt,
    sr_od.b_s_od / 
    count(case when website_sessions.utm_campaign = 'brand'
    then website_sessions.website_session_id
    else null end)
    as b_s_cv_rt,
    sr_od.or_od /
    count(case when website_sessions.utm_source IS NULL
    and website_sessions.http_referer is not null
    then website_sessions.website_session_id
    else null end)
    as or_cv_rt,
    sr_od.dt_od /
    count(case when website_sessions.utm_source IS NULL
    and website_sessions.http_referer is null
    then website_sessions.website_session_id
    else null end)
    as dt_cv_rt
    
from sr_od
left join website_sessions on
	sr_od.year = year(website_sessions.created_at) 
    and sr_od.quarter = quarter(website_sessions.created_at)
group by 1,2
order by 1,2;

/*
Tỷ lệ chuyển đổi sessions thành đơn hàng cao nhất vào quý 1 năm 2015
*/

-- YC5 Viết truy vấn để thể hiện doanh thu và lợi nhuận theo sản phẩm, tổng doanh thu, tổng lợi nhuận của tất cả các sản phẩm

create temporary table rv_mg
select 
	year(order_items.created_at) as 'year',
	month(order_items.created_at) as 'month',
    sum(case when order_items.product_id='1'then order_items.price_usd else null end) as mf_rv,
    sum(case when order_items.product_id='1'then order_items.price_usd - order_items.cogs_usd else null end) as mf_mg,
    sum(case when order_items.product_id='2'then order_items.price_usd else null end) as lb_rv,
    sum(case when order_items.product_id='2'then order_items.price_usd - order_items.cogs_usd else null end) as lb_mg,
    sum(case when order_items.product_id='3'then order_items.price_usd else null end) as sb_rv,
    sum(case when order_items.product_id='3'then order_items.price_usd - order_items.cogs_usd else null end) as sb_mg,
    sum(case when order_items.product_id='4'then order_items.price_usd else null end) as mb_rv,
    sum(case when order_items.product_id='4'then order_items.price_usd - order_items.cogs_usd else null end) as mb_mg,
    sum(case when order_items.product_id='1' or order_items.product_id='2' or  order_items.product_id='3' or  order_items.product_id='4'then order_items.price_usd else null end) as tl_rv,
    sum(case when order_items.product_id='1' or order_items.product_id='2' or  order_items.product_id='3' or  order_items.product_id='4'then order_items.price_usd - order_items.cogs_usd else null end) as tl_mg
from order_items
group by 1,2
order by 1,2;
    
/*
Tổng doanh thu và lợi nhận cao nhất vào tháng 12 năm 2014
Doanh thu và lợi nhận của The Original Mr. Fuzzy cao nhất vào tháng 10 năm 2014
Doanh thu và lợi nhận của The Forever Love Bear cao nhất vào tháng 11 năm 2014
Doanh thu và lợi nhận của The Birthday Sugar Panda cao nhất vào tháng 2 năm 2015
Doanh thu và lợi nhận của The Birthday Sugar Panda cao nhất vào tháng 2 năm 2015
Doanh thu và lợi nhận của The Hudson River Mini bear cao nhất vào tháng 11 năm 2014
*/    
    
-- YC6 Viết truy vấn để tìm hiểu tác động của sản phẩm mới và đưa ra nhận xét

create temporary table ss_pd
select 
	created_at
    ,website_pageview_id
    ,website_session_id
    from website_pageviews
where pageview_url='/products';

select 
	year(a.created_at) as 'year'
    ,month(a.created_at) as 'month'
	,count(distinct a.website_pageview_id) as sessions_to_product_page
    ,count(distinct case when b.website_pageview_id > a.website_pageview_id 
				then a.website_session_id else Null end) as click_to_next
	,count(distinct case when b.website_pageview_id > a.website_pageview_id 
				then a.website_session_id else Null end)/count(distinct a.website_pageview_id) as clickthrough_rt
	,count(distinct case when b.website_pageview_id > a.website_pageview_id and b.pageview_url='/thank-you-for-your-order'
				then a.website_session_id else Null end) as orders
	,count(distinct case when b.website_pageview_id > a.website_pageview_id and b.pageview_url='/thank-you-for-your-order'
				then a.website_session_id else Null end) / count(distinct a.website_pageview_id) as products_to_order_rt
from ss_pd a
left join website_pageviews b on a.website_session_id=b.website_session_id 
group by 1,2;

/*
Số lượng đơn hàng cao nhất vào tháng 12 năm 2014
Tỷ lệ chuyển đổi đơn hàng khi vào trang product cao nhất vào tháng 12 năm 2014
Tỷ lệ click thêm trang web cao nhất vào tháng 3 năm 2015
*/

-- YC7 Viết truy vấn thể hiện mức độ hiệu quả của các cặp sản phẩm được bán kèm và đưa ra nhận xét

select 
primary_product_id,
count(distinct orders.order_id) as total_orders,
count(distinct case when order_items.product_id=1 and order_items.is_primary_item = 0 then orders.order_id else Null end)   as xsold_p1,
count(distinct case when order_items.product_id=2 and order_items.is_primary_item = 0 then orders.order_id else Null end)   as xsold_p2,
count(distinct case when order_items.product_id=3 and order_items.is_primary_item = 0 then orders.order_id else Null end)   as xsold_p3,
count(distinct case when order_items.product_id=4 and order_items.is_primary_item = 0 then orders.order_id else Null end)   as xsold_p4,
count(distinct case when order_items.product_id=1 and order_items.is_primary_item = 0 then orders.order_id else Null end)/count(distinct orders.order_id) as p1_xsell_rt,
count(distinct case when order_items.product_id=2 and order_items.is_primary_item = 0 then orders.order_id else Null end)/count(distinct orders.order_id) as p2_xsell_rt,
count(distinct case when order_items.product_id=3 and order_items.is_primary_item = 0 then orders.order_id else Null end)/count(distinct orders.order_id) as p3_xsell_rt,
count(distinct case when order_items.product_id=4 and order_items.is_primary_item = 0 then orders.order_id else Null end)/count(distinct orders.order_id) as p4_xsell_rt
from orders 
left join order_items
on orders.order_id = order_items.order_id
where orders.created_at>='2014-12-05'
group by orders.primary_product_id

/*
Số lượng đơn hàng có The Original Mr. Fuzzy là cao nhất
The Hudson River Mini bear là sản phẩm được mua kèm nhiều nhất
*/

-- YC8 Đưa ra một số nhận xét và các phân tích phía trên

/*
gsearch, nonbrand là hình thức đóng vai trò chủ đạo từ đó là có thể tiếp tục thúc đẩy hoặc phát triển đồng điều giữa các hình thức 
The Original Mr. Fuzzy là sản phẩm trọng điểm nên có chính sách lưu kho hợp lý
The Hudson River Mini bear là sản phẩm được bán kèm nhiêu nhất cũng nên chú ý về chính sách lưu kho
Những tháng 11 12 hàng năm là những tháng nên được trú trọng quãng bá vì có tỷ lệ chuyển đổi đơn hàng cao và doanh thu cao
*/