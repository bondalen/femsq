# §4.3 G-ip + `_2606` @507 (DEV-only)

Note: [26-1127-c2-o2-gip-2606-43.md](../../chats/chat-plan/notes/26-1127-c2-o2-gip-2606-43.md)

```bash
sqlcmd -S 10.7.0.3,1433 -U sa -P '…' -d FishEye_prod_noM6 -C -i 01_FIXTURE_seed_utpl_chain507.sql
sqlcmd … -i 02_GIP_compare_chain507.sql
sqlcmd … -i 03_EXEC_spMstrg_2606_chain507.sql
# откат: 99_ROLLBACK_fixture_chain507.sql
```
