class RebuildAllActivitiesToSystem < ActiveRecord::Migration
  def self.up
    return
    #Issue
    if Issue.count(:include => :activity, :conditions => "#{Issue.table_name}.activity_id IS NOT NULL AND #{TimeEntryActivity.table_name}.parent_id IS NOT NULL") > 0
      Issue.connection.execute("UPDATE #{Issue.table_name} i
INNER JOIN #{Enumeration.table_name} e ON e.id = i.activity_id
SET i.activity_id = e.parent_id
WHERE
	i.activity_id IN(
		SELECT
			e.id
		FROM
			#{Enumeration.table_name} e
		WHERE
			e.type = 'TimeEntryActivity'
		AND e.project_id IS NOT NULL
	);")
    end

    #TimeEntry
    if TimeEntry.count(:include => :activity, :conditions => "#{TimeEntry.table_name}.activity_id IS NOT NULL AND #{TimeEntryActivity.table_name}.parent_id IS NOT NULL") > 0
      TimeEntry.connection.execute("UPDATE #{TimeEntry.table_name} t
INNER JOIN #{Enumeration.table_name} e ON e.id = t.activity_id
SET t.activity_id = e.parent_id
WHERE
	t.activity_id IN(
		SELECT
			e.id
		FROM
			#{Enumeration.table_name} e
		WHERE
			e.type = 'TimeEntryActivity'
		AND e.project_id IS NOT NULL
	);")
    end

    #EasyMoneyRate (prasarnica schvalena by PP)
    begin
      #cleaning
      ActiveRecord::Base.connection.execute("DELETE emr
FROM #{EasyMoneyRate.table_name} emr
WHERE emr.entity_type = 'TimeEntryActivity' AND emr.entity_id NOT IN (SELECT e.id FROM #{Enumeration.table_name} e WHERE e.type = 'TimeEntryActivity');")
      
      ActiveRecord::Base.connection.execute("DELETE emr
FROM #{EasyMoneyRate.table_name} emr
INNER JOIN enumerations e ON e.id = emr.entity_id
WHERE emr.entity_type = 'TimeEntryActivity' AND emr.project_id != e.project_id;")

      ActiveRecord::Base.connection.execute("DELETE emr
FROM
	easy_money_rates emr
INNER JOIN(
	SELECT
		CASE
	WHEN emr1.unit_rate > emr2.unit_rate THEN
		emr2.emr_id
	WHEN emr1.unit_rate < emr2.unit_rate THEN
		emr1.emr_id
	WHEN emr1.unit_rate = emr2.unit_rate
	AND emr1.e_parent_id IS NULL THEN
		emr2.emr_id
	WHEN emr1.unit_rate = emr2.unit_rate
	AND emr2.e_parent_id IS NULL THEN
		emr1.emr_id
	ELSE
		NULL
	END id
	FROM
		(
			SELECT
				emr.id emr_id,
				emr.project_id emr_project_id,
				emr.rate_type_id,
				emr.entity_type,
				emr.unit_rate,
				e.id e_id,
				e.parent_id e_parent_id
			FROM
				easy_money_rates emr
			INNER JOIN enumerations e ON e.id = emr.entity_id
			WHERE
				emr.entity_type = 'TimeEntryActivity'
			AND e.project_id IS NULL
		)emr1
	INNER JOIN(
		SELECT
			emr.id emr_id,
			emr.project_id emr_project_id,
			emr.rate_type_id,
			emr.entity_type,
			emr.unit_rate,
			e.id e_id,
			e.parent_id e_parent_id
		FROM
			easy_money_rates emr
		INNER JOIN enumerations e ON e.id = emr.entity_id
		WHERE
			emr.entity_type = 'TimeEntryActivity'
		AND e.project_id IS NOT NULL
	)emr2 ON emr2.emr_project_id = emr1.emr_project_id
	AND emr2.rate_type_id = emr1.rate_type_id
	AND emr2.e_parent_id = emr1.e_id
)tmp ON tmp.id = emr.id
WHERE
	emr.project_id IS NOT NULL;")
    rescue
    end
    
    begin
      if EasyMoneyRate.count(:joins => "INNER JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{EasyMoneyRate.table_name}.entity_id", :conditions => "#{EasyMoneyRate.table_name}.entity_type = 'TimeEntryActivity' AND #{TimeEntryActivity.table_name}.parent_id IS NOT NULL") > 0
        EasyMoneyRate.connection.execute("UPDATE #{EasyMoneyRate.table_name} emr
INNER JOIN #{Enumeration.table_name} e ON e.id = emr.entity_id
SET emr.entity_id = e.parent_id
WHERE
	emr.entity_type = 'TimeEntryActivity'
AND emr.entity_id IN(
	SELECT
		e.id
	FROM
		#{Enumeration.table_name} e
	WHERE
		e.type = 'TimeEntryActivity'
	AND e.project_id IS NOT NULL
	);")
      end
    rescue
    end

    #CustomValue
    if CustomValue.count(:joins => "INNER JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{CustomValue.table_name}.customized_id", :conditions => "#{CustomValue.table_name}.customized_type = 'Enumeration' AND #{TimeEntryActivity.table_name}.parent_id IS NOT NULL") > 0
      CustomValue.connection.execute("DELETE cv
FROM
	#{CustomValue.table_name} cv
INNER JOIN #{Enumeration.table_name} e ON e.id = cv.customized_id
WHERE
	cv.customized_type = 'Enumeration'
AND e.project_id IS NOT NULL;")
    end

    #ProjectActivityRole
    if ProjectActivityRole.count(:select => "#{ProjectActivityRole.table_name}.project_id, #{ProjectActivityRole.table_name}.activity_id, #{ProjectActivityRole.table_name}.role_id", :include => :role_activity, :conditions => "#{ProjectActivityRole.table_name}.activity_id IS NOT NULL AND #{TimeEntryActivity.table_name}.parent_id IS NOT NULL") > 0
      ProjectActivityRole.connection.execute("UPDATE #{ProjectActivityRole.table_name} par
INNER JOIN #{Enumeration.table_name} e ON e.id = par.activity_id
SET par.activity_id = e.parent_id
WHERE
	par.activity_id IN(
		SELECT
			e.id
		FROM
			#{Enumeration.table_name} e
		WHERE
			e.type = 'TimeEntryActivity'
		AND e.project_id IS NOT NULL
	);")
    end
            
    #TimeEntryActivity
    if Enumeration.count(:conditions => "#{Enumeration.table_name}.type = 'TimeEntryActivity' AND #{Enumeration.table_name}.project_id IS NOT NULL") > 0
      Enumeration.connection.execute("DELETE
FROM #{Enumeration.table_name}
WHERE type = 'TimeEntryActivity' AND project_id IS NOT NULL;")
    end

  end

  def self.down
  end
end