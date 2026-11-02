select *
from credit_deal.person;

select last_name, first_name, middle_name, date_of_birth, monthly_income
from credit_deal.person;

select last_name || ' ' || first_name || ' ' || coalesce(middle_name, '') as full_name,
       phone_number as phone
from credit_deal.person;

select distinct reg_region
from credit_deal.person
order by reg_region;

select name, base_rate, min_amount, max_amount, min_term_months, max_term_months
from credit_deal.loan_product;

select last_name, first_name, monthly_income
from credit_deal.person
where reg_region = 'Москва'
  and monthly_income > 150000
order by monthly_income desc;

select last_name, first_name, monthly_income
from credit_deal.person
order by monthly_income desc
limit 5;

select last_name, first_name, middle_name
from credit_deal.person
where last_name like 'С%';

select contract_number, signed_at, amount, status
from credit_deal.loan_contract
where status in ('in_default', 'restructured');

select application_number, submitted_at, requested_amount, status
from credit_deal.loan_application
where submitted_at between '2024-01-01' and '2024-12-31'
order by submitted_at;

select last_name, first_name, phone_number
from credit_deal.person
where email is null;

select name, base_rate
from credit_deal.loan_product
where end_date is null
order by base_rate;

select application_number, submitted_at, requested_amount, requested_term_months
from credit_deal.loan_application
where purpose = 'primary_market'
  and requested_amount >= 8000000
order by requested_amount desc;

select a.application_number, p.last_name, p.first_name,
       lp.name as product, a.requested_amount, a.status
from credit_deal.loan_application a
join credit_deal.person p        on p.id = a.borrower_id
join credit_deal.loan_product lp on lp.id = a.product_id
order by a.submitted_at;

select e.last_name, e.first_name, e.branch, jp.name as position, jp.department
from credit_deal.employee e
join credit_deal.job_position jp on jp.id = e.position_id
order by e.branch, e.last_name;

select c.contract_number, p.last_name, p.first_name,
       c.amount, c.interest_rate, bc.name as benefit
from credit_deal.loan_contract c
join credit_deal.application_decision d on d.id = c.decision_id
join credit_deal.loan_application a     on a.id = d.application_id
join credit_deal.person p               on p.id = a.borrower_id
left join credit_deal.benefit_category bc on bc.id = c.benefit_category_id
order by c.signed_at;

select d.doc_type, d.series, d.number, d.issue_date, d.verification_status
from credit_deal.document d
join credit_deal.person p on p.id = d.person_id
where p.last_name = 'Рогов'
order by d.provided_at;

select a.application_number,
       b.last_name  as borrower,
       cb.last_name as co_borrower,
       acb.relationship, acb.considered_income
from credit_deal.application_co_borrower acb
join credit_deal.loan_application a on a.id = acb.application_id
join credit_deal.person b           on b.id = a.borrower_id
join credit_deal.person cb          on cb.id = acb.co_borrower_id;

select c.contract_number, s.last_name as signer, cur.last_name as curator
from credit_deal.loan_contract c
join credit_deal.employee s        on s.id = c.signer_id
left join credit_deal.employee cur on cur.id = c.curator_id;

select r.cadastral_number, r.addr_locality, r.addr_street, r.addr_house,
       p.last_name, po.share, po.ownership_type
from credit_deal.property_ownership po
join credit_deal.person p      on p.id = po.person_id
join credit_deal.real_estate r on r.id = po.real_estate_id
order by r.cadastral_number;

select p.last_name, p.first_name
from credit_deal.person p
left join credit_deal.property_ownership po on po.person_id = p.id
where po.person_id is null;

select c.contract_number, si.payment_no, si.due_date,
       si.payment_amount, si.principal_amount, si.interest_amount
from credit_deal.schedule_item si
join credit_deal.schedule_version sv on sv.id = si.version_id and sv.is_current
join credit_deal.loan_contract c     on c.id = sv.contract_id
where si.due_date between '2026-11-01' and '2026-11-30'
order by si.due_date;

select c.contract_number, r.object_type, r.addr_locality, r.addr_street,
       pa.pledge_value, pa.encumbrance_registered_at
from credit_deal.pledge_agreement pa
join credit_deal.loan_contract c on c.id = pa.contract_id
join credit_deal.real_estate r   on r.id = pa.real_estate_id
order by c.contract_number;

select count(*)                     as persons,
       round(avg(monthly_income), 2) as avg_income,
       min(monthly_income)          as min_income,
       max(monthly_income)          as max_income
from credit_deal.person;

select count(*) as contracts, sum(amount) as total_amount, round(avg(interest_rate), 2) as avg_rate
from credit_deal.loan_contract;

select sum(balance) as total_balance
from credit_deal.loan_account
where closed_at is null;

select status, count(*) as applications
from credit_deal.loan_application
group by status
order by applications desc;

select extract(year from signed_at) as year, count(*) as contracts, sum(amount) as total_amount
from credit_deal.loan_contract
group by extract(year from signed_at)
order by year;

select submission_channel, count(*) as applications, round(avg(requested_amount), 2) as avg_amount
from credit_deal.loan_application
group by submission_channel
order by applications desc;

select branch, count(*) as employees
from credit_deal.employee
where is_active
group by branch;

select p.last_name, p.first_name, count(*) as applications
from credit_deal.loan_application a
join credit_deal.person p on p.id = a.borrower_id
group by p.id, p.last_name, p.first_name
having count(*) > 1;

select lp.name as product, count(*) as contracts, sum(c.amount) as total_amount
from credit_deal.loan_contract c
join credit_deal.application_decision d on d.id = c.decision_id
join credit_deal.loan_application a     on a.id = d.application_id
join credit_deal.loan_product lp        on lp.id = a.product_id
group by lp.name
having count(*) >= 2
order by contracts desc;

select doc_type,
       count(*)                                                as total,
       count(*) filter (where verification_status = 'verified') as verified
from credit_deal.document
group by doc_type
order by total desc;

select c.contract_number,
       count(*)                  as payments,
       sum(sa.principal_credited) as principal_paid,
       sum(sa.interest_credited)  as interest_paid
from credit_deal.schedule_allocation sa
join credit_deal.schedule_item si    on si.id = sa.schedule_item_id
join credit_deal.schedule_version sv on sv.id = si.version_id
join credit_deal.loan_contract c     on c.id = sv.contract_id
group by c.contract_number
order by c.contract_number;

select e.last_name,
       count(distinct ap.application_id)  as applications,
       count(*)                           as stage_assignments,
       string_agg(distinct ap.stage, ', ') as stages
from credit_deal.application_processing ap
join credit_deal.employee e on e.id = ap.employee_id
group by e.id, e.last_name
order by stage_assignments desc;

select c.status, count(*) as contracts, sum(la.balance) as balance
from credit_deal.loan_account la
join credit_deal.loan_contract c on c.id = la.contract_id
group by c.status;

select c.contract_number, count(*) as versions, max(sv.created_at) as last_change
from credit_deal.schedule_version sv
join credit_deal.loan_contract c on c.id = sv.contract_id
group by c.contract_number
having count(*) > 1;

select bc.name, count(c.id) as contracts, coalesce(sum(c.amount), 0) as total_amount
from credit_deal.benefit_category bc
left join credit_deal.loan_contract c on c.benefit_category_id = bc.id
group by bc.id, bc.name
order by contracts desc;

select last_name, first_name, monthly_income
from credit_deal.person
where monthly_income > (select avg(monthly_income) from credit_deal.person)
order by monthly_income desc;

select last_name, first_name
from credit_deal.person
where id in (select a.borrower_id
             from credit_deal.loan_application a
             join credit_deal.application_decision d on d.application_id = a.id
             join credit_deal.loan_contract c        on c.decision_id = d.id);

select application_number, submitted_at, status
from credit_deal.loan_application a
where not exists (select 1
                  from credit_deal.application_decision d
                  where d.application_id = a.id);

select a.application_number, d.decision_date, d.result, a.status
from credit_deal.application_decision d
join credit_deal.loan_application a on a.id = d.application_id
where d.result <> 'rejected'
  and not exists (select 1 from credit_deal.loan_contract c where c.decision_id = d.id);

select c.contract_number, lc.classified_at, lc.quality_category, lc.reserve_rate, lc.basis
from credit_deal.loan_classification lc
join credit_deal.loan_contract c on c.id = lc.contract_id
where lc.classified_at = (select max(x.classified_at)
                          from credit_deal.loan_classification x
                          where x.contract_id = lc.contract_id)
order by lc.quality_category desc, c.contract_number;

select c.contract_number, p.last_name,
       dq.occurred_at,
       dq.overdue_principal + dq.overdue_interest as overdue_debt,
       dq.penalty_amount, dq.overdue_days, dq.collection_status,
       e.last_name as collector
from credit_deal.delinquency dq
join credit_deal.schedule_item si       on si.id = dq.schedule_item_id
join credit_deal.schedule_version sv    on sv.id = si.version_id
join credit_deal.loan_contract c        on c.id = sv.contract_id
join credit_deal.application_decision d on d.id = c.decision_id
join credit_deal.loan_application a     on a.id = d.application_id
join credit_deal.person p               on p.id = a.borrower_id
left join credit_deal.employee e        on e.id = dq.collector_id
where dq.repaid_at is null
order by dq.overdue_days desc;

select count(*) as decisions,
       count(*) filter (where result = 'rejected') as rejected,
       round(100.0 * count(*) filter (where result = 'rejected') / count(*), 1) as rejected_pct
from credit_deal.application_decision;

select p.last_name, cr.bureau_name, cr.credit_score, cr.max_overdue_days,
       d.decision_number, d.result, d.reason
from credit_deal.credit_report cr
join credit_deal.person p                    on p.id = cr.person_id
left join credit_deal.application_decision d on d.id = cr.decision_id
where cr.is_stop_factor;

select c.contract_number, c.amount,
       sum(pa.pledge_value)                              as pledge_total,
       round(100.0 * c.amount / sum(pa.pledge_value), 1) as ltv_pct
from credit_deal.loan_contract c
join credit_deal.pledge_agreement pa on pa.contract_id = c.id
group by c.id, c.contract_number, c.amount
order by ltv_pct desc;

select to_char(operation_date, 'YYYY-MM') as month,
       count(*)    as operations,
       sum(amount) as received
from credit_deal.loan_operation
where status = 'posted'
  and operation_type <> 'disbursement'
  and operation_date >= '2026-01-01'
group by to_char(operation_date, 'YYYY-MM')
order by month;

select g.last_name as guarantor, c.contract_number,
       ga.liability_type, ga.liability_limit, ga.end_date
from credit_deal.guarantee_agreement ga
join credit_deal.person g        on g.id = ga.guarantor_id
join credit_deal.loan_contract c on c.id = ga.contract_id
order by c.contract_number;

select e.branch, c.contract_number, c.signed_at,
       row_number() over (partition by e.branch order by c.signed_at) as num_in_branch
from credit_deal.loan_contract c
join credit_deal.employee e on e.id = c.signer_id
order by e.branch, c.signed_at;

with paid as (
    select sv.contract_id, sum(sa.principal_credited + sa.interest_credited) as total_paid
    from credit_deal.schedule_allocation sa
    join credit_deal.schedule_item si    on si.id = sa.schedule_item_id
    join credit_deal.schedule_version sv on sv.id = si.version_id
    group by sv.contract_id
)
select c.contract_number, paid.total_paid
from paid
join credit_deal.loan_contract c on c.id = paid.contract_id
where paid.total_paid > (select avg(total_paid) from paid)
order by paid.total_paid desc;
