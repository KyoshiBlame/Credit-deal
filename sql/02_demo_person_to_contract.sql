SET search_path TO credit_deal;

BEGIN;

INSERT INTO loan_product (name, base_rate, min_amount, max_amount,
                          min_term_months, max_term_months, min_down_payment,
                          collateral_required, start_date, end_date)
VALUES ('Демо: Семейная ипотека', 6.0000, 500000, 12000000,
        36, 360, 20.00, true, '2024-01-01', NULL);

INSERT INTO job_position (name, department, max_approval_limit, can_sign_contracts)
VALUES ('Демо: андеррайтер',           'Демо: отдел андеррайтинга',  15000000, false),
       ('Демо: кредитный специалист',  'Демо: розничный кредитный отдел', 0,   true);

INSERT INTO employee (personnel_number, last_name, first_name, middle_name, branch,
                      poa_number, poa_issue_date, is_active,
                      position_id, position_assigned_at, personal_approval_limit)
VALUES
    ('DEMO-UW-01', 'Орлова', 'Марина', 'Игоревна', 'Демо: центральный офис',
     NULL, NULL, true,
     (SELECT id FROM job_position
       WHERE name = 'Демо: андеррайтер' AND department = 'Демо: отдел андеррайтинга'),
     '2023-03-01', 12000000),
    ('DEMO-MG-01', 'Белов', 'Кирилл', 'Андреевич', 'Демо: центральный офис',
     'DEMO-Д-15', '2026-01-15', true,
     (SELECT id FROM job_position
       WHERE name = 'Демо: кредитный специалист' AND department = 'Демо: розничный кредитный отдел'),
     '2022-09-01', NULL);

INSERT INTO person (last_name, first_name, middle_name, date_of_birth, inn, snils,
                    reg_region, reg_locality, reg_street, reg_house, reg_block, reg_apartment,
                    phone_number, email, marital_status, dependents_count,
                    employer, job_title, monthly_income, income_source)
VALUES ('Сидоров', 'Андрей', 'Павлович', '1992-06-15', '549912345678', '99912345601',
        'Новосибирская область', 'Новосибирск', 'ул. Кирова', '48', NULL, '12',
        '+79131234567', 'sidorov.demo@mail.ru', 'married', 1,
        'ООО «Сибирские системы»', 'Инженер-программист', 180000.00, 'salary');

INSERT INTO borrower (person_id, service_start_date, is_payroll_client)
VALUES ((SELECT id FROM person WHERE inn = '549912345678'), '2026-11-02', false);

INSERT INTO document (doc_type, series, number, issue_date, issued_by, expiry_date,
                      verification_status, person_id, provided_at, provision_method)
VALUES
    ('passport', '5012', '345678', '2012-07-01',
     'ГУ МВД России по Новосибирской области', '2037-06-15',
     'verified', (SELECT id FROM person WHERE inn = '549912345678'), '2026-11-02', 'in_branch'),
    ('income_statement', NULL, 'DEMO-2НДФЛ-118', '2026-10-30',
     'ООО «Сибирские системы»', NULL,
     'verified', (SELECT id FROM person WHERE inn = '549912345678'), '2026-11-02', 'in_branch');

INSERT INTO loan_application (application_number, submitted_at, requested_amount,
                              requested_term_months, purpose, down_payment,
                              collateral_offered, documents_complete, status,
                              product_id, borrower_id, submission_channel)
VALUES ('DEMO-2026-0001', '2026-11-02', 6000000.00,
        240, 'primary_market', 1500000.00,
        true, true, 'submitted',
        (SELECT id FROM loan_product WHERE name = 'Демо: Семейная ипотека'),
        (SELECT id FROM person WHERE inn = '549912345678'),
        'branch');

INSERT INTO application_document (application_id, document_id, is_mandatory, included_at)
SELECT a.id, d.id, true, '2026-11-02'
FROM loan_application a
JOIN document d ON d.person_id = a.borrower_id
WHERE a.application_number = 'DEMO-2026-0001';

INSERT INTO real_estate (cadastral_number, object_type,
                         addr_region, addr_locality, addr_street, addr_house,
                         addr_block, addr_apartment, total_area, build_year)
VALUES ('54:99:0101234:567', 'apartment',
        'Новосибирская область', 'Новосибирск', 'ул. Галущака', '15',
        NULL, '87', 62.40, 2026);

INSERT INTO application_collateral (application_id, real_estate_id, valuation_date,
                                    market_value, liquidation_value, discount_ratio,
                                    liquidity_category, collateral_conclusion)
VALUES ((SELECT id FROM loan_application WHERE application_number = 'DEMO-2026-0001'),
        (SELECT id FROM real_estate WHERE cadastral_number = '54:99:0101234:567'),
        '2026-11-03', 7500000.00, 6375000.00, 0.1500, 'high',
        'Объект ликвиден, обременений нет, может быть принят в залог');

INSERT INTO application_processing (application_id, employee_id, stage, employee_role, assigned_at)
SELECT a.id, e.id, v.stage, v.role, v.assigned_at::date
FROM loan_application a
CROSS JOIN (VALUES ('DEMO-MG-01', 'intake',       'manager',     '2026-11-02'),
                   ('DEMO-UW-01', 'underwriting', 'underwriter', '2026-11-03'))
     AS v(personnel_number, stage, role, assigned_at)
JOIN employee e ON e.personnel_number = v.personnel_number
WHERE a.application_number = 'DEMO-2026-0001';

UPDATE loan_application
SET status = 'in_review'
WHERE application_number = 'DEMO-2026-0001';

INSERT INTO credit_report (bureau_name, request_date, request_time, credit_score,
                           active_loans_count, monthly_payments_total,
                           has_overdue, max_overdue_days,
                           person_id, consent_date,
                           decision_id, considered_payment, is_stop_factor)
VALUES ('НБКИ', '2026-11-03', '10:15:00', 780,
        1, 12000.00,
        false, 0,
        (SELECT id FROM person WHERE inn = '549912345678'), '2026-11-02',
        NULL, NULL, NULL);

INSERT INTO application_decision (decision_number, decision_date, result,
                                  approved_amount, approved_term_months, approved_rate,
                                  dti_ratio, reason,
                                  application_id, underwriter_id,
                                  reviewed_at, underwriter_comment)
VALUES ('DEMO-R-2026-0001', '2026-11-05', 'approved',
        6000000.00, 240, 6.0000,
        30.55, NULL,
        (SELECT id FROM loan_application WHERE application_number = 'DEMO-2026-0001'),
        (SELECT id FROM employee WHERE personnel_number = 'DEMO-UW-01'),
        '2026-11-05', 'Стабильный доход, кредитная история без просрочек');

UPDATE credit_report
SET decision_id        = (SELECT id FROM application_decision WHERE decision_number = 'DEMO-R-2026-0001'),
    considered_payment = 12000.00,
    is_stop_factor     = false
WHERE person_id = (SELECT id FROM person WHERE inn = '549912345678')
  AND bureau_name = 'НБКИ'
  AND request_date = '2026-11-03';

UPDATE loan_application
SET status = 'approved'
WHERE application_number = 'DEMO-2026-0001';

INSERT INTO loan_contract (contract_number, signed_at, amount, term_months,
                           interest_rate, full_cost_rate, end_date, status,
                           decision_id, accepted_option, accepted_at,
                           signer_id, signing_place,
                           curator_id, curator_assigned_at, monitoring_status,
                           benefit_category_id, applied_rate_discount)
VALUES ('DEMO-ИК-2026-0001', '2026-11-10', 6000000.00, 240,
        6.0000, 6.4120, '2046-11-10', 'active',
        (SELECT id FROM application_decision WHERE decision_number = 'DEMO-R-2026-0001'),
        'Аннуитетные платежи, 240 месяцев', '2026-11-08',
        (SELECT id FROM employee WHERE personnel_number = 'DEMO-MG-01'),
        'Новосибирск, офис банка',
        NULL, NULL, NULL,
        NULL, NULL);

UPDATE loan_application
SET status = 'contracted'
WHERE application_number = 'DEMO-2026-0001';

UPDATE loan_contract
SET curator_id          = (SELECT id FROM employee WHERE personnel_number = 'DEMO-MG-01'),
    curator_assigned_at = '2026-11-11',
    monitoring_status   = 'normal'
WHERE contract_number = 'DEMO-ИК-2026-0001';

INSERT INTO loan_account (account_number, opened_at, closed_at,
                          debit_account_number, balance, contract_id)
VALUES ('45507810990000000001', '2026-11-10', NULL,
        '40817810990000000001', 0,
        (SELECT id FROM loan_contract WHERE contract_number = 'DEMO-ИК-2026-0001'));

SELECT concat_ws(' ', p.last_name, p.first_name, p.middle_name) AS "Клиент",
       a.application_number                                   AS "Заявка",
       a.status                                               AS "Статус заявки",
       pr.name                                                AS "Программа",
       d.decision_number                                      AS "Решение",
       d.result                                               AS "Результат",
       concat_ws(' ', uw.last_name, uw.first_name)            AS "Андеррайтер",
       c.contract_number                                      AS "Договор",
       c.amount                                               AS "Сумма",
       c.interest_rate                                        AS "Ставка, %",
       concat_ws(' ', s.last_name, s.first_name)              AS "Подписал",
       la.account_number                                      AS "Ссудный счёт",
       re.cadastral_number                                    AS "Залог"
FROM loan_contract c
JOIN application_decision   d   ON d.id   = c.decision_id
JOIN loan_application       a   ON a.id   = d.application_id
JOIN person                 p   ON p.id   = a.borrower_id
JOIN loan_product           pr  ON pr.id  = a.product_id
JOIN employee               uw  ON uw.id  = d.underwriter_id
JOIN employee               s   ON s.id   = c.signer_id
JOIN loan_account           la  ON la.contract_id    = c.id
JOIN application_collateral ac  ON ac.application_id = a.id
JOIN real_estate            re  ON re.id  = ac.real_estate_id
WHERE c.contract_number = 'DEMO-ИК-2026-0001';
