ALTER TABLE clean_orders      MODIFY customer_id VARCHAR(32) NOT NULL;
ALTER TABLE clean_order_items MODIFY order_id VARCHAR(32) NOT NULL,
                              MODIFY product_id VARCHAR(32) NOT NULL,
                              MODIFY seller_id VARCHAR(32) NOT NULL;
ALTER TABLE clean_payments    MODIFY order_id VARCHAR(32) NOT NULL;
ALTER TABLE clean_order_items ADD INDEX idx_oi_order (order_id);
ALTER TABLE clean_payments    ADD INDEX idx_pay_order (order_id);
ALTER TABLE clean_orders      ADD INDEX idx_o_customer (customer_id);
