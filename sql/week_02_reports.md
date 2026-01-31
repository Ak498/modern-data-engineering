### Problem 1 — Before Optimization
(modern-data-engineering\performance\Week_02\PROBLEM1_BEFORE_PLAN.png)

The baseline execution plan performed a full table scan on the `sales` table.
Because no supporting index existed on the `status` filter, SQL Server scanned
the entire dataset before applying the window function.

Key characteristics:
- Table Scan on `sales` (~97% of total cost)
- Parallelism used to compensate for high IO
- Explicit sort required for ROW_NUMBER()
- Missing Index recommendation with high impact score

### Problem 1 — After Optimization (modern-data-engineering\performance\Week_02\PROBLEM1_AFTER_PLAN.png)

After adding a nonclustered index on `status` with covering columns,
SQL Server switched from a table scan to an index seek.

Observed improvements:
- Index Seek replaces Table Scan
- Filter on `status` applied at the storage engine level
- Sort cost reduced due to fewer input rows
- No missing index recommendations

Although a sort is still required for ROW_NUMBER(), the workload is
significantly smaller after early filtering.

Note: The index does not fully eliminate sorting because the ORDER BY
(date DESC, order_id DESC) is not aligned with the index key order.


### Problem 2 — Before Optimization
(modern-data-engineering\performance\Week_02\PROBLEM2_BEFORE_PLAN.png)

The initial approach used window functions and DISTINCT to emulate
COUNT(DISTINCT), resulting in a complex execution plan.

Observed issues:
- Multiple aggregation stages
- Increased memory grants
- Wide execution plan with many operators
- Missing index recommendation indicating inefficient access path 

### Problem 2 — After Optimization
(modern-data-engineering\performance\Week_02\PROBLEM2_AFTER_PLAN.png)

By rewriting the query to use a simple GROUP BY and adding a covering index,
the execution plan became significantly simpler.

Observed improvements:
- Index Seek replaces scan
- Single aggregation stage
- Reduced memory usage
- Lower estimated operator cost

This demonstrates that window functions are not always the best tool
when simpler aggregation preserves semantics.

Tradeoff: This approach sacrifices some flexibility in exchange for
substantially improved performance and readability.


### Problem 3 — Before Optimization (CROSS APPLY)
(modern-data-engineering\performance\Week_02\PROBLEM3_BEFORE_PLAN.png)

The initial approach used CROSS APPLY to retrieve the most recent
previous order per SKU.

Observed characteristics:
- Nested Loops join pattern
- Repeated index seeks per outer row
- Top-N Sort executed many times
- Index Spool introduced to mitigate repeated access

While this approach is readable and intuitive, it does not scale
well as the number of rows per SKU increases.
This pattern pushes work into repeated row-by-row operations,
which limits scalability for large datasets.

### Problem 3 — After Optimization (Window-Based Rewrite)
(modern-data-engineering\performance\Week_02\PROBLEM3_AFTER_PLAN.png)

The optimized approach rewrote the logic using window functions
over a deduplicated SKU-date set.

Observed improvements:
- Set-based processing replaces row-by-row access
- Single partitioned sort per SKU
- Reduced CPU overhead
- More stable execution behavior as data volume grows

This rewrite changes the logical grain to SKU-date, which avoids
false gaps caused by multiple orders on the same day.

Note:
CROSS APPLY can be efficient in SQL Server for selective lookups,
but in this case the window-based approach provided better
scalability and lower cumulative cost.





