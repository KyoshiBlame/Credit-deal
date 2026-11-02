drop schema if exists credit_deal cascade;
create schema credit_deal;

create table credit_deal.person (
    id               bigint generated always as identity primary key,
    last_name        varchar(100) not null,
    first_name       varchar(100) not null,
    middle_name      varchar(100),
    date_of_birth    date not null,
    inn              char(12) not null unique,
    snils            char(11) not null unique,
    reg_region       varchar(100) not null,
    reg_locality     varchar(100) not null,
    reg_street       varchar(100) not null,
    reg_house        varchar(10)  not null,
    reg_block        varchar(10),
    reg_apartment    varchar(10),
    phone_number     varchar(16),
    email            varchar(254),
    marital_status   varchar(20),
    dependents_count smallint not null default 0,
    employer         varchar(255),
    job_title        varchar(150),
    monthly_income   numeric(15,2),
    income_source    varchar(30),

    constraint chk_person_inn        check (inn ~ '^[0-9]{12}$'),
    constraint chk_person_snils      check (snils ~ '^[0-9]{11}$'),
    constraint chk_person_birth      check (date_of_birth > date '1900-01-01'),
    constraint chk_person_phone      check (phone_number ~ '^\+?[0-9]{10,15}$'),
    constraint chk_person_email      check (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    constraint chk_person_marital    check (marital_status in
        ('single', 'married', 'divorced', 'widowed')),
    constraint chk_person_dependents check (dependents_count >= 0),
    constraint chk_person_income     check (monthly_income >= 0),
    constraint chk_person_income_src check (income_source in
        ('salary', 'pension', 'business', 'self_employed', 'other'))
);

create table credit_deal.benefit_category (
    id           bigint generated always as identity primary key,
    name         varchar(150) not null unique,
    legal_basis  text not null,
    description  text not null
);

create table credit_deal.loan_product (
    id                  bigint generated always as identity primary key,
    name                varchar(150) not null unique,
    base_rate           numeric(7,4)  not null,
    min_amount          numeric(15,2) not null,
    max_amount          numeric(15,2) not null,
    min_term_months     smallint not null,
    max_term_months     smallint not null,
    min_down_payment    numeric(5,2)  not null,
    collateral_required boolean not null default true,
    start_date          date not null,
    end_date            date,

    constraint chk_product_rate     check (base_rate > 0),
    constraint chk_product_amount   check (min_amount > 0 and min_amount <= max_amount),
    constraint chk_product_term     check (min_term_months > 0 and min_term_months <= max_term_months),
    constraint chk_product_down_pay check (min_down_payment between 0 and 100),
    constraint chk_product_period   check (end_date is null or end_date >= start_date)
);

create table credit_deal.job_position (
    id                 bigint generated always as identity primary key,
    name               varchar(150) not null,
    department         varchar(150) not null,
    max_approval_limit numeric(15,2) not null default 0,
    can_sign_contracts boolean not null default false,

    constraint uq_position_name_dept unique (name, department),
    constraint chk_position_limit    check (max_approval_limit >= 0)
);

create table credit_deal.real_estate (
    id                bigint generated always as identity primary key,
    cadastral_number  varchar(40) not null unique,
    object_type       varchar(20) not null,
    addr_region       varchar(100) not null,
    addr_locality     varchar(100) not null,
    addr_street       varchar(100) not null,
    addr_house        varchar(10)  not null,
    addr_block        varchar(10),
    addr_apartment    varchar(10),
    total_area        numeric(8,2) not null,
    build_year        smallint,

    constraint chk_estate_cadastral check (cadastral_number ~ '^[0-9]{2}:[0-9]{2}:[0-9]{6,7}:[0-9]+$'),
    constraint chk_estate_type      check (object_type in
        ('apartment', 'house', 'room', 'townhouse', 'land_plot')),
    constraint chk_estate_area      check (total_area > 0),
    constraint chk_estate_year      check (build_year between 1800 and 2100)
);

create table credit_deal.employee (
    id                      bigint generated always as identity primary key,
    personnel_number        varchar(20) not null unique,
    last_name               varchar(100) not null,
    first_name              varchar(100) not null,
    middle_name             varchar(100),
    branch                  varchar(150) not null,
    poa_number              varchar(50),
    poa_issue_date          date,
    is_active               boolean not null default true,
    position_id             bigint not null references credit_deal.job_position(id),
    position_assigned_at    date not null,
    personal_approval_limit numeric(15,2),

    constraint chk_employee_limit check (personal_approval_limit >= 0),
    constraint chk_employee_poa   check ((poa_number is null) = (poa_issue_date is null))
);

create table credit_deal.borrower (
    person_id          bigint primary key references credit_deal.person(id),
    service_start_date date not null,
    is_payroll_client  boolean not null default false
);

create table credit_deal.co_borrower (
    person_id          bigint primary key references credit_deal.person(id),
    first_engaged_date date not null
);

create table credit_deal.guarantor (
    person_id          bigint primary key references credit_deal.person(id),
    first_engaged_date date not null,
    guarantee_limit    numeric(15,2),

    constraint chk_guarantor_limit check (guarantee_limit >= 0)
);

create table credit_deal.document (
    id                  bigint generated always as identity primary key,
    doc_type            varchar(30) not null,
    series              varchar(10),
    number              varchar(30) not null,
    issue_date          date not null,
    issued_by           varchar(255),
    expiry_date         date,
    verification_status varchar(20) not null default 'pending',
    person_id           bigint not null references credit_deal.person(id),
    provided_at         date not null,
    provision_method    varchar(20) not null,

    constraint chk_document_type   check (doc_type in
        ('passport', 'snils', 'income_statement', 'employment_record',
         'marriage_certificate', 'birth_certificate', 'benefit_certificate', 'other')),
    constraint chk_document_status check (verification_status in
        ('pending', 'verified', 'rejected')),
    constraint chk_document_method check (provision_method in
        ('in_branch', 'online', 'mail')),
    constraint chk_document_expiry check (expiry_date is null or expiry_date > issue_date)
);

create table credit_deal.product_benefit (
    product_id              bigint not null references credit_deal.loan_product(id),
    benefit_category_id     bigint not null references credit_deal.benefit_category(id),
    start_date              date not null,
    end_date                date,
    rate_discount           numeric(7,4) not null,
    max_amount_with_benefit numeric(15,2),

    primary key (product_id, benefit_category_id, start_date),
    constraint chk_pb_discount check (rate_discount > 0),
    constraint chk_pb_amount   check (max_amount_with_benefit > 0),
    constraint chk_pb_period   check (end_date is null or end_date >= start_date)
);

create table credit_deal.property_ownership (
    person_id      bigint not null references credit_deal.person(id),
    real_estate_id bigint not null references credit_deal.real_estate(id),
    share          numeric(5,4) not null,
    ownership_type varchar(20) not null,
    registered_at  date not null,

    primary key (person_id, real_estate_id),
    constraint chk_ownership_share check (share > 0 and share <= 1),
    constraint chk_ownership_type  check (ownership_type in
        ('individual', 'shared', 'joint'))
);

create table credit_deal.benefit_entitlement (
    document_id         bigint not null references credit_deal.document(id),
    benefit_category_id bigint not null references credit_deal.benefit_category(id),
    right_start_date    date not null,
    right_end_date      date,
    check_status        varchar(20) not null default 'pending',
    checked_at          date,

    primary key (document_id, benefit_category_id),
    constraint chk_entitlement_status check (check_status in
        ('pending', 'confirmed', 'rejected')),
    constraint chk_entitlement_period check (right_end_date is null or right_end_date >= right_start_date)
);

create table credit_deal.loan_application (
    id                    bigint generated always as identity primary key,
    application_number    varchar(30) not null unique,
    submitted_at          date not null,
    requested_amount      numeric(15,2) not null,
    requested_term_months smallint not null,
    purpose               varchar(30) not null,
    down_payment          numeric(15,2) not null default 0,
    collateral_offered    boolean not null,
    documents_complete    boolean not null default false,
    status                varchar(20) not null default 'submitted',
    product_id            bigint not null references credit_deal.loan_product(id),
    borrower_id           bigint not null references credit_deal.borrower(person_id),
    submission_channel    varchar(20) not null,

    constraint chk_app_amount  check (requested_amount > 0),
    constraint chk_app_term    check (requested_term_months > 0),
    constraint chk_app_down    check (down_payment >= 0),
    constraint chk_app_purpose check (purpose in
        ('primary_market', 'secondary_market', 'construction', 'refinancing')),
    constraint chk_app_status  check (status in
        ('submitted', 'in_review', 'approved', 'rejected', 'cancelled', 'contracted')),
    constraint chk_app_channel check (submission_channel in
        ('branch', 'online', 'mobile_app', 'partner'))
);

create table credit_deal.application_co_borrower (
    application_id    bigint not null references credit_deal.loan_application(id),
    co_borrower_id    bigint not null references credit_deal.co_borrower(person_id),
    relationship      varchar(20) not null,
    considered_income numeric(15,2) not null,
    income_share      numeric(5,4) not null,

    primary key (application_id, co_borrower_id),
    constraint chk_acb_relationship check (relationship in
        ('spouse', 'parent', 'child', 'sibling', 'other_relative', 'none')),
    constraint chk_acb_income       check (considered_income >= 0),
    constraint chk_acb_share        check (income_share between 0 and 1)
);

create table credit_deal.application_guarantor (
    application_id bigint not null references credit_deal.loan_application(id),
    guarantor_id   bigint not null references credit_deal.guarantor(person_id),
    proposed_limit numeric(15,2) not null,
    relationship   varchar(20) not null,

    primary key (application_id, guarantor_id),
    constraint chk_ag_limit        check (proposed_limit > 0),
    constraint chk_ag_relationship check (relationship in
        ('spouse', 'parent', 'child', 'sibling', 'other_relative', 'none'))
);

create table credit_deal.application_document (
    application_id bigint not null references credit_deal.loan_application(id),
    document_id    bigint not null references credit_deal.document(id),
    is_mandatory   boolean not null,
    included_at    date not null,

    primary key (application_id, document_id)
);

create table credit_deal.application_collateral (
    application_id        bigint not null references credit_deal.loan_application(id),
    real_estate_id        bigint not null references credit_deal.real_estate(id),
    valuation_date        date not null,
    market_value          numeric(15,2) not null,
    liquidation_value     numeric(15,2) not null,
    discount_ratio        numeric(5,4) not null,
    liquidity_category    varchar(10) not null,
    collateral_conclusion text,

    primary key (application_id, real_estate_id),
    constraint chk_ac_values    check (market_value > 0 and liquidation_value > 0
                                       and liquidation_value <= market_value),
    constraint chk_ac_discount  check (discount_ratio between 0 and 1),
    constraint chk_ac_liquidity check (liquidity_category in ('high', 'medium', 'low'))
);

create table credit_deal.application_processing (
    application_id bigint not null references credit_deal.loan_application(id),
    employee_id    bigint not null references credit_deal.employee(id),
    stage          varchar(20) not null,
    employee_role  varchar(20) not null,
    assigned_at    date not null,

    primary key (application_id, employee_id, stage),
    constraint chk_ap_stage check (stage in
        ('intake', 'verification', 'underwriting', 'collateral_review', 'legal_review', 'signing')),
    constraint chk_ap_role  check (employee_role in
        ('manager', 'verifier', 'underwriter', 'appraiser', 'lawyer'))
);

create table credit_deal.application_decision (
    id                   bigint generated always as identity primary key,
    decision_number      varchar(30) not null unique,
    decision_date        date not null,
    result               varchar(20) not null,
    approved_amount      numeric(15,2),
    approved_term_months smallint,
    approved_rate        numeric(7,4),
    dti_ratio            numeric(5,2),
    reason               text,
    application_id       bigint not null unique references credit_deal.loan_application(id),
    underwriter_id       bigint not null references credit_deal.employee(id),
    reviewed_at          date not null,
    underwriter_comment  text,

    constraint chk_decision_result check (result in
        ('approved', 'approved_reduced', 'rejected')),
    constraint chk_decision_terms  check (
        (result = 'rejected'
            and approved_amount is null and approved_term_months is null and approved_rate is null)
        or
        (result <> 'rejected'
            and approved_amount > 0 and approved_term_months > 0 and approved_rate > 0)
    ),
    constraint chk_decision_reason check (result = 'approved' or reason is not null),
    constraint chk_decision_dti    check (dti_ratio >= 0)
);

create table credit_deal.credit_report (
    id                     bigint generated always as identity primary key,
    bureau_name            varchar(150) not null,
    request_date           date not null,
    request_time           time not null,
    credit_score           smallint,
    active_loans_count     smallint not null default 0,
    monthly_payments_total numeric(15,2) not null default 0,
    has_overdue            boolean not null default false,
    max_overdue_days       integer not null default 0,
    person_id              bigint not null references credit_deal.person(id),
    consent_date           date not null,
    decision_id            bigint references credit_deal.application_decision(id),
    considered_payment     numeric(15,2),
    is_stop_factor         boolean,

    constraint chk_cr_score    check (credit_score >= 0),
    constraint chk_cr_loans    check (active_loans_count >= 0),
    constraint chk_cr_payments check (monthly_payments_total >= 0),
    constraint chk_cr_overdue  check (
        (has_overdue and max_overdue_days > 0) or (not has_overdue and max_overdue_days = 0)),
    constraint chk_cr_consent  check (consent_date <= request_date),
    constraint chk_cr_decision check (decision_id is not null
                                      or (considered_payment is null and is_stop_factor is null))
);

create table credit_deal.loan_contract (
    id                    bigint generated always as identity primary key,
    contract_number       varchar(30) not null unique,
    signed_at             date not null,
    amount                numeric(15,2) not null,
    term_months           smallint not null,
    interest_rate         numeric(7,4) not null,
    full_cost_rate        numeric(7,4) not null,
    end_date              date not null,
    status                varchar(20) not null default 'active',
    decision_id           bigint not null unique references credit_deal.application_decision(id),
    accepted_option       varchar(100) not null,
    accepted_at           date not null,
    signer_id             bigint not null references credit_deal.employee(id),
    signing_place         varchar(255) not null,
    curator_id            bigint references credit_deal.employee(id),
    curator_assigned_at   date,
    monitoring_status     varchar(20),
    benefit_category_id   bigint references credit_deal.benefit_category(id),
    applied_rate_discount numeric(7,4),

    constraint chk_contract_amount   check (amount > 0),
    constraint chk_contract_term     check (term_months > 0),
    constraint chk_contract_rate     check (interest_rate > 0 and full_cost_rate >= interest_rate),
    constraint chk_contract_dates    check (end_date > signed_at and accepted_at <= signed_at),
    constraint chk_contract_status   check (status in
        ('active', 'closed', 'early_closed', 'in_default', 'restructured')),
    constraint chk_contract_monitor  check (monitoring_status in ('normal', 'watch', 'problem')),
    constraint chk_contract_curator  check ((curator_id is null) = (curator_assigned_at is null)),
    constraint chk_contract_benefit  check ((benefit_category_id is null) = (applied_rate_discount is null)),
    constraint chk_contract_discount check (applied_rate_discount > 0)
);

create table credit_deal.guarantee_agreement (
    guarantor_id     bigint not null references credit_deal.guarantor(person_id),
    contract_id      bigint not null references credit_deal.loan_contract(id),
    agreement_number varchar(30) not null unique,
    agreement_date   date not null,
    liability_type   varchar(20) not null,
    liability_limit  numeric(15,2) not null,
    end_date         date,

    primary key (guarantor_id, contract_id),
    constraint chk_ga_type  check (liability_type in ('joint', 'subsidiary')),
    constraint chk_ga_limit check (liability_limit > 0),
    constraint chk_ga_dates check (end_date is null or end_date > agreement_date)
);

create table credit_deal.pledge_agreement (
    contract_id             bigint not null references credit_deal.loan_contract(id),
    real_estate_id          bigint not null references credit_deal.real_estate(id),
    agreement_number        varchar(30) not null unique,
    agreement_date          date not null,
    pledge_value            numeric(15,2) not null,
    encumbrance_registered_at date,
    insurance_policy_number varchar(50),
    insurance_end_date      date,

    primary key (contract_id, real_estate_id),
    constraint chk_pa_value check (pledge_value > 0)
);

create table credit_deal.loan_classification (
    contract_id      bigint not null references credit_deal.loan_contract(id),
    classified_at    date not null,
    quality_category smallint not null,
    reserve_rate     numeric(5,2) not null,
    basis            text not null,

    primary key (contract_id, classified_at),
    constraint chk_lc_category check (quality_category between 1 and 5),
    constraint chk_lc_reserve  check (reserve_rate between 0 and 100)
);

create table credit_deal.loan_account (
    id                   bigint generated always as identity primary key,
    account_number       char(20) not null unique,
    opened_at            date not null,
    closed_at            date,
    debit_account_number char(20) not null,
    balance              numeric(15,2) not null default 0,
    contract_id          bigint not null unique references credit_deal.loan_contract(id),

    constraint chk_la_number  check (account_number ~ '^[0-9]{20}$'),
    constraint chk_la_debit   check (debit_account_number ~ '^[0-9]{20}$'),
    constraint chk_la_dates   check (closed_at is null or closed_at >= opened_at),
    constraint chk_la_balance check (balance >= 0)
);

create table credit_deal.schedule_version (
    id          bigint generated always as identity primary key,
    contract_id bigint not null references credit_deal.loan_contract(id),
    version_no  smallint not null,
    created_at  date not null,
    reason      varchar(30) not null,
    is_current  boolean not null default false,

    constraint uq_sv_contract_version unique (contract_id, version_no),
    constraint chk_sv_version check (version_no > 0),
    constraint chk_sv_reason  check (reason in
        ('initial', 'early_repayment', 'restructuring', 'rate_change'))
);

create table credit_deal.schedule_item (
    id                  bigint generated always as identity primary key,
    version_id          bigint not null references credit_deal.schedule_version(id),
    payment_no          smallint not null,
    due_date            date not null,
    payment_amount      numeric(15,2) not null,
    principal_amount    numeric(15,2) not null,
    interest_amount     numeric(15,2) not null,
    remaining_principal numeric(15,2) not null,
    payment_status      varchar(20) not null default 'scheduled',

    constraint uq_si_version_payment unique (version_id, payment_no),
    constraint chk_si_payment_no check (payment_no > 0),
    constraint chk_si_amounts    check (principal_amount >= 0 and interest_amount >= 0
                                        and remaining_principal >= 0),
    constraint chk_si_sum        check (payment_amount = principal_amount + interest_amount),
    constraint chk_si_status     check (payment_status in
        ('scheduled', 'paid', 'partially_paid', 'overdue'))
);

create table credit_deal.loan_operation (
    id                   bigint generated always as identity primary key,
    operation_number     varchar(30) not null unique,
    operation_type       varchar(30) not null,
    operation_date       date not null,
    value_date           date not null,
    amount               numeric(15,2) not null,
    payment_method       varchar(20),
    status               varchar(20) not null default 'pending',
    account_id           bigint not null references credit_deal.loan_account(id),
    payer_id             bigint references credit_deal.person(id),
    payer_account_number char(20),
    processed_by_id      bigint references credit_deal.employee(id),
    check_result         varchar(20),
    checked_at           date,

    constraint chk_lo_type    check (operation_type in
        ('disbursement', 'scheduled_payment', 'early_repayment',
         'interest_accrual', 'penalty_accrual', 'overdue_repayment')),
    constraint chk_lo_amount  check (amount > 0),
    constraint chk_lo_method  check (payment_method in
        ('cash', 'transfer', 'auto_debit', 'payroll')),
    constraint chk_lo_status  check (status in ('pending', 'posted', 'rejected')),
    constraint chk_lo_payer   check (payer_account_number ~ '^[0-9]{20}$'),
    constraint chk_lo_check   check (check_result in ('approved', 'rejected')),
    constraint chk_lo_checker check (processed_by_id is not null
                                     or (check_result is null and checked_at is null))
);

create table credit_deal.delinquency (
    id                    bigint generated always as identity primary key,
    occurred_at           date not null,
    overdue_principal     numeric(15,2) not null default 0,
    overdue_interest      numeric(15,2) not null default 0,
    penalty_rate          numeric(7,4) not null,
    penalty_amount        numeric(15,2) not null default 0,
    penalty_calculated_at date,
    repaid_at             date,
    overdue_days          integer not null default 0,
    collection_status     varchar(20) not null default 'none',
    schedule_item_id      bigint not null references credit_deal.schedule_item(id),
    collector_id          bigint references credit_deal.employee(id),
    collection_measure    varchar(20),
    contact_date          date,
    contact_result        varchar(255),

    constraint chk_dq_amounts check (overdue_principal >= 0 and overdue_interest >= 0
                                     and overdue_principal + overdue_interest > 0),
    constraint chk_dq_penalty check (penalty_rate >= 0 and penalty_amount >= 0),
    constraint chk_dq_dates   check (repaid_at is null or repaid_at >= occurred_at),
    constraint chk_dq_days    check (overdue_days >= 0),
    constraint chk_dq_status  check (collection_status in
        ('none', 'soft', 'hard', 'legal', 'completed')),
    constraint chk_dq_measure check (collection_measure in
        ('call', 'sms', 'letter', 'visit', 'claim', 'lawsuit')),
    constraint chk_dq_collector check (collector_id is not null
        or (collection_measure is null and contact_date is null and contact_result is null))
);

create table credit_deal.schedule_allocation (
    schedule_item_id   bigint not null references credit_deal.schedule_item(id),
    operation_id       bigint not null references credit_deal.loan_operation(id),
    principal_credited numeric(15,2) not null default 0,
    interest_credited  numeric(15,2) not null default 0,
    credited_at        date not null,

    primary key (schedule_item_id, operation_id),
    constraint chk_sa_amounts check (principal_credited >= 0 and interest_credited >= 0
                                     and principal_credited + interest_credited > 0)
);

create table credit_deal.delinquency_allocation (
    operation_id     bigint not null references credit_deal.loan_operation(id),
    delinquency_id   bigint not null references credit_deal.delinquency(id),
    debt_credited    numeric(15,2) not null default 0,
    penalty_credited numeric(15,2) not null default 0,
    credited_at      date not null,

    primary key (operation_id, delinquency_id),
    constraint chk_da_amounts check (debt_credited >= 0 and penalty_credited >= 0
                                     and debt_credited + penalty_credited > 0)
);
