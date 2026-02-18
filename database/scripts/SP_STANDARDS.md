## SP Transaction Standard (SQL Server 2012+)

Use this pattern in all business stored procedures:

1. `SET XACT_ABORT ON`
2. If `@@TRANCOUNT = 0`, start transaction and commit it at the end.
3. If there is an active transaction, use `SAVE TRANSACTION <name>`.
4. In `CATCH`:
   - If procedure started the transaction: `ROLLBACK TRAN`.
   - If transaction came from caller: `ROLLBACK TRANSACTION <savepoint>`.
5. Return clear errors with `RAISERROR`.

Why:
- Works on SQL Server 2012 and newer.
- Safe in nested calls.
- Guarantees rollback in business failures.

