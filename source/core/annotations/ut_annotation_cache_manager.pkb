create or replace package body ut_annotation_cache_manager as
  /*
  utPLSQL - Version 3
  Copyright 2016 - 2018 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License"):
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */


  procedure delete_object_annotations(a_objects ut_annotation_objs_cache_info) is
  begin
    delete from ut_annotation_cache c
     where c.cache_id
        in (select i.cache_id
              from ut_annotation_cache_info i
              join table (a_objects) o
                on o.object_name = i.object_name
               and o.object_type = i.object_type
               and o.object_owner = i.object_owner
           );
  end;

  procedure update_cache(a_object ut_annotated_object) is
    l_cache_id       integer;
    l_current_schema varchar2(250) := ut_utils.ut_owner;
    l_parse_time     date := sysdate;
    pragma autonomous_transaction;
  begin
    update ut_annotation_cache_info i
       set i.parse_time = l_parse_time
     where (i.object_owner, i.object_name, i.object_type)
        in ((a_object.object_owner, a_object.object_name, a_object.object_type))
      returning cache_id into l_cache_id;
    if sql%rowcount = 0 then
      insert into ut_annotation_cache_info
             (cache_id, object_owner, object_name, object_type, parse_time)
      values (ut_annotation_cache_seq.nextval, a_object.object_owner, a_object.object_name, a_object.object_type, l_parse_time)
        returning cache_id into l_cache_id;

      update ut_annotation_cache_schema s
         set s.object_count = s.object_count + 1, s.max_parse_time = l_parse_time
       where s.object_type = a_object.object_type and s.object_owner = a_object.object_owner;
      if sql%rowcount = 0 then
        insert into ut_annotation_cache_schema s
               (object_owner, object_type, object_count, max_parse_time)
        values (a_object.object_owner, a_object.object_type, 1, l_parse_time);
      end if;
    end if;

    delete from ut_annotation_cache c
      where cache_id = l_cache_id;

    if a_object.annotations is not null and a_object.annotations.count > 0 then
--       begin
      insert into ut_annotation_cache
             (cache_id, annotation_position, annotation_name, annotation_text, subobject_name)
      select l_cache_id, a.position, a.name, a.text, a.subobject_name
        from table(a_object.annotations) a;
      --TODO - duplicate annotations found?? - should not happen, getting standalone annotations need to happen after procedure annotations were parsed
--       exception
--         when others then
--           dbms_output.put_line(xmltype(anydata.convertCollection(a_object.annotations)).getclobval);
--           raise;
--       end;
    end if;
    commit;
  end;


  procedure cleanup_cache(a_objects ut_annotation_objs_cache_info) is
    pragma autonomous_transaction;
  begin
    delete_object_annotations(a_objects);

    merge into ut_annotation_cache_info i
      using (select o.object_name, o.object_type, o.object_owner
               from table(a_objects) o ) o
         on (o.object_name = i.object_name
             and o.object_type = i.object_type
             and o.object_owner = i.object_owner)
     when matched then update set parse_time = sysdate
     when not matched then insert
           (cache_id, object_owner, object_name, object_type, parse_time)
     values (ut_annotation_cache_seq.nextval, o.object_owner, o.object_name, o.object_type, sysdate);

    commit;
  end;

  function get_cache_schema_info(a_object_owner varchar2, a_object_type varchar2) return t_cache_schema_info is
    l_result t_cache_schema_info;
  begin
    begin
      select *
        into l_result
        from ut_annotation_cache_schema s
       where s.object_type = a_object_type and s.object_owner = a_object_owner;
    exception
      when no_data_found then
        null;
    end;
    return l_result;
  end;

  procedure delete_cache(a_objects ut_annotation_objs_cache_info) is
    pragma autonomous_transaction;
  begin
    if a_objects is not null then
      delete_object_annotations(a_objects);

      delete from ut_annotation_cache_info i
       where exists(
               select 1 from table (a_objects) o
                where o.object_name = i.object_name
                  and o.object_type = i.object_type
                  and o.object_owner = i.object_owner
             );

      update ut_annotation_cache_schema s
         set s.object_count = s.object_count - cardinality(a_objects)
       where (s.object_type, s.object_owner)
          in (select o.object_type, o.object_owner from table(a_objects) o );

      commit;
    end if;
  end;

  function get_annotations_for_objects(a_cached_objects ut_annotation_objs_cache_info) return sys_refcursor is
    l_results     sys_refcursor;
  begin
    open l_results for
      select ut_annotated_object(
               o.object_owner, o.object_name, o.object_type,
               cast(
                 collect(
                   ut_annotation(
                     c.annotation_position, c.annotation_name, c.annotation_text, c.subobject_name
                   ) order by c.annotation_position
                 ) as ut_annotations
               )
             )
        from table(a_cached_objects) o
        join ut_annotation_cache_info i
          on o.object_owner = i.object_owner and o.object_name = i.object_name and o.object_type = i.object_type
        join ut_annotation_cache c on i.cache_id = c.cache_id
       group by o.object_owner, o.object_name, o.object_type;
    return l_results;
  end;

  procedure purge_cache(a_object_owner varchar2, a_object_type varchar2) is
    l_filter       varchar2(32767);
    l_cache_filter varchar2(32767);
    pragma autonomous_transaction;
  begin
    if a_object_owner is null and a_object_type is null then
      l_cache_filter := ':a_object_owner is null and :a_object_type is null';
      l_filter := l_cache_filter;
    else
      l_filter :=
      case when a_object_owner is null then ':a_object_owner is null' else 'object_owner = :a_object_owner' end || '
        and '||case when a_object_type is null then ':a_object_type is null' else 'object_type = :a_object_type' end;
      l_cache_filter := ' c.cache_id
           in (select i.cache_id
                 from ut_annotation_cache_info i
                where '|| l_filter || '
              )';
    end if;
    execute immediate '
      delete from ut_annotation_cache c
       where '||l_cache_filter
    using a_object_owner, a_object_type;

    execute immediate '
      delete from ut_annotation_cache_info i
       where ' || l_filter
    using a_object_owner, a_object_type;

    execute immediate '
      delete from ut_annotation_cache_schema s
       where ' || l_filter
    using a_object_owner, a_object_type;

    commit;
  end;

end ut_annotation_cache_manager;
/
