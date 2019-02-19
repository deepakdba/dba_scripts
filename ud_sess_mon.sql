/* Alter system flush shared_pool
set lines 220 pages 50000 LONG 99999999 colsep " |" verify OFF 
col INST_ID hea "I" FOR 9
col SCHEMANAME for a25 hea "Schema" jus c
col "OPER" FOR a30 wor hea "Operation" jus c
col "SESS" FOR a20 wor hea "Session|Info" jus c
col "WT_EVENT" FOR a15 wor hea " Wait Event|#Wait Class" jus c
col "PARAM" FOR a15 wor hea "Wait Event|Parameters" jus c
col "SESS_ACTIVITY" FOR a20 wor hea "Start Time &|Wait Info" jus c
col "P_M_A" FOR a15 wor hea "Program|Module &|Action" jus c
col "MEM_CPU" FOR a15 wor hea "MEM(KB) and| CPU Time(ms)" jus c
col "PR_INFO" FOR a11 wor hea " SPID -|OPID" jus c
col "USR_INF" FOR a15 wor hea "User|Info" jus c
*/ 
ALTER SESSION SET nls_date_format='MONDD hh24miss';

SELECT /*+ Ordered */ S.schemaname ,S.inst_id 
       ,S.sql_id||': '||S.sql_hash_value||':'||S.sql_child_number||' => '||SUBSTR(SA.sql_text,1,400)        "OPER" 
       ,S.sid|| ','||S.serial#||DECODE(S.blocking_session, NULL,NULL,' Blocker: ' 
       ||S.blocking_session||'@'||S.blocking_instance||' :'||blocking_session_status)||' - '
       ||S.status||' for(s):'||s.last_call_et||' SQL_Exec(s): '||ROUND((sysdate-sql_exec_start)*86400,2)    "SESS" 
       ,'S_Time: '||logon_time||' LW(us):'||s.WAIT_TIME_MICRO||' TSLW(us):'||s.TIME_SINCE_LAST_WAIT_MICRO   "SESS_ACTIVITY" 
       ,S.event||' #Wt.class: '||S.wait_class|| DECODE(S.lockwait, NULL, NULL,' Lock Addr:'||S.lockwait)    "WT_EVENT"
       ,DECODE(S.p1text, NULL, NULL,S.p1text||':'||S.p1) 
       ||DECODE(S.p2text, NULL, NULL,', '||S.p2text||':'||S.p2) 
       ||DECODE(S.p3text, NULL, NULL,', '||S.p3text||':'||S.p3) 
       ||DECODE(S.row_wait_obj#, NULL, NULL,', Obj_ID:'||S.row_wait_obj#)                                   "PARAM" 
       ,S.program||' <> '||S.MODULE||' <> '||S.ACTION                                                       "P_M_A" 
       ,'PGA_USED(K): '|| ROUND(( P.pga_used_mem/1024 ), 2)|| ' PGA_ALLOC(K): '
       || ROUND(( P.pga_alloc_mem / 1024 ), 2)|| ' CPU_TIME(ms):'||ST.value * 10                            "MEM_CPU" 
       ,'SPID: '||P.spid||' :: OPID:'||P.pid                                                                "PR_INFO" 
       ,S.osuser||' @ '||S.machine||':'||S.terminal||' to '||S.schemaname||' @ '||S.service_name            "USR_INF"
       ,s.prev_sql_id||':'||s.plsql_entry_object_id||'-'||s.plsql_entry_subprogram_id                       "TOP_LVL"
       ,s.sql_trace||'::'||p.tracefile                                                                      "SESS_TRC"
  FROM gv$process P, gv$session S, gv$sqlarea SA, gv$sesstat ST
 WHERE P.addr        = S.paddr
   AND S.sid         = ST.sid
   AND S.sid        <> (SELECT sid FROM v$mystat WHERE rownum=1)
   AND S.inst_id     = SA.inst_id(+)
   AND P.inst_id     = S.inst_id
   AND ST.inst_id    = S.inst_id
   AND ST.statistic# = (SELECT statistic# FROM v$statname WHERE name = 'CPU used by this session')
   AND S.sql_address = SA.address(+)
   AND S.command    != 0
   --AND p.spid in (22887
   --AND S.module in ('plsql_code_typ_chngr')
   --and upper(s.program) like '%PL%'
   --AND (S.blocking_session IS NOT NULL or s.sid in (select blocking_session from v$session where blocking_session is not null))
 ORDER BY s.sql_exec_start;

--===========================================
-- SESS MON WITH DOP for each session
--===========================================
SELECT /*+ Ordered */ S.schemaname ,S.inst_id 
       ,S.sql_id||': '||S.sql_hash_value||':'||S.sql_child_number||' => '||SUBSTR(SA.sql_text,1,400)        "OPER" 
       ,S.sid|| ','||S.serial#||DECODE(S.blocking_session, NULL,NULL,' Blocker: ' 
       ||S.blocking_session||'@'||S.blocking_instance||' :'||blocking_session_status)||' - '
       ||S.status||' for(s):'||s.last_call_et||' SQL_Exec(s): '||ROUND((sysdate-sql_exec_start)*86400,2)    "SESS" 
       ,'S_Time: '||logon_time||' LW(us):'||s.WAIT_TIME_MICRO||' TSLW(us):'||s.TIME_SINCE_LAST_WAIT_MICRO   "SESS_ACTIVITY" 
       ,S.event||' #Wt.class: '||S.wait_class|| DECODE(S.lockwait, NULL, NULL,' Lock Addr:'||S.lockwait)    "WT_EVENT"
       ,DECODE(S.p1text, NULL, NULL,S.p1text||':'||S.p1) 
       ||DECODE(S.p2text, NULL, NULL,', '||S.p2text||':'||S.p2) 
       ||DECODE(S.p3text, NULL, NULL,', '||S.p3text||':'||S.p3) 
       ||DECODE(S.row_wait_obj#, NULL, NULL,', Obj_ID:'||S.row_wait_obj#)                                   "PARAM" 
       ,S.program||' <> '||S.MODULE||' <> '||S.ACTION                                                       "P_M_A" 
       ,'PGA_USED(K): '|| ROUND(( P.pga_used_mem/1024 ), 2)|| ' PGA_ALLOC(K): '
       || ROUND(( P.pga_alloc_mem / 1024 ), 2)|| ' CPU_TIME(ms):'||ST.value * 10                            "MEM_CPU" 
       ,'SPID: '||P.spid||' :: OPID:'||P.pid                                                                "PR_INFO" 
       ,S.osuser||' @ '||S.machine||':'||S.terminal||' to '||S.schemaname||' @ '||S.service_name            "USR_INF"
       ,s.prev_sql_id||':'||s.plsql_entry_object_id||'-'||s.plsql_entry_subprogram_id                       "TOP_LVL"
       ,s.sql_trace||'::'||p.tracefile                                                                      "SESS_TRC"
  FROM gv$process P, gv$session S, gv$sqlarea SA, gv$sesstat ST
 WHERE P.addr        = S.paddr
   AND S.sid         = ST.sid
   AND S.sid        <> (SELECT sid FROM v$mystat WHERE rownum=1)
   AND S.inst_id     = SA.inst_id(+)
   AND P.inst_id     = S.inst_id
   AND ST.inst_id    = S.inst_id
   AND ST.statistic# = (SELECT statistic# FROM v$statname WHERE name = 'CPU used by this session')
   AND S.sql_address = SA.address(+)
   --AND S.command    != 0
   and s.taddr='000000113CE30C80' 
   --AND s.sid in (518,647)
   --AND S.module in ('plsql_code_typ_chngr')
   --and upper(s.program) like '%PL%'
   --AND (S.blocking_session IS NOT NULL or s.sid in (select blocking_session from v$session where blocking_session is not null))
 ORDER BY s.sql_exec_start;
