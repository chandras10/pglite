                                             Table "public.product"
   Column   |       Type        |                      Modifiers                       | Storage  | Description 
------------+-------------------+------------------------------------------------------+----------+-------------
 id         | integer           | not null default nextval('product_id_seq'::regclass) | plain    | 
 vendor     | character varying |                                                      | extended | 
 os_name    | character varying |                                                      | extended | 
 os_version | character varying |                                                      | extended | 
 revision   | character varying |                                                      | extended | 
 arch       | character varying |                                                      | extended | 
Indexes:
    "product_pkey" PRIMARY KEY, btree (id)
Referenced by:
    TABLE "vuln_product" CONSTRAINT "vuln_product_product_id_fkey" FOREIGN KEY (product_id) REFERENCES product(id)
Has OIDs: no

